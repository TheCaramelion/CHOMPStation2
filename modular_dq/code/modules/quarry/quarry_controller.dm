// Subsystem that owns the dynamic deep-quarry layers.
//
// Lifecycle of a layer:
//   ensure_layer(N) -> allocates a fresh Z, loads the empty stone template
//   onto it, runs the cave generator, places a descent ladder on a random
//   floor tile, returns the /datum/quarry_layer record.
//   unload_layer(N) -> qdels everything on the Z and turfs it to space.
//
// "Same depth, same layer" is emergent: ensure_layer is idempotent on
// loaded layers, so concurrent or staggered descents to depth N all land
// on whatever layer is currently loaded at depth N. If none exists, the
// caller generates a fresh one.
//
// Procedural layers are 256x256, matching the surface station's size. The
// substrate template (deep_quarry_layer.dmm) covers the full Z with a
// 1-tile bedrock perimeter and a mineable cave interior. The cave gen
// operates on the full 256x256 — generation takes 30-60s per layer with
// per-cell yields, but pregeneration after each descent keeps the next
// layer ready in advance.
#define QUARRY_LAYER_SIZE 256

SUBSYSTEM_DEF(quarry)
	name = "Deep Quarry"
	wait = 30 SECONDS
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	// Indexed by "[depth]" string key.
	var/list/layers = list()

	// Per-depth re-entrancy guard: set to depth while ensure_layer is generating.
	var/list/generating = list()

	// Surface tile that escape ropes deliver to. Populated either by a
	// /obj/effect/landmark/quarry_anchor self-registering, or by our
	// Initialize() scanning for one as a fallback.
	var/turf/surface_anchor = null

	// All concrete /datum/quarry_layer_config instances. Built once at
	// Initialize from subtypesof(); select_config picks across them.
	var/list/configs = list()

	// The freight elevator. One per round, owned by SSquarry. Created at
	// Initialize before the surface map's landmarks scan for it.
	var/datum/quarry_elevator/elevator

	// The deepest depth a player has ever set foot on this round. Monotonic.
	// Used by deepest_elevator_stop() for the surface elevator's
	// "send to depth N" target. Starts at 1 so the elevator always has
	// at least depth 1 as a destination — layer 1 is pregenerated at init
	// regardless of whether anyone has visited it.
	var/deepest_visited = 1

/datum/controller/subsystem/quarry/Initialize()
	// Create the elevator before scanning the map. Landmarks on the entrance
	// map register their bays/doors with the elevator during their own
	// Initialize, and that may run before or after SSquarry depending on
	// init order — both directions are covered by us doing a fallback scan
	// at the end of this proc.
	elevator = new

	// Find the surface anchor if a landmark didn't self-register first.
	if(!isturf(surface_anchor))
		for(var/obj/effect/landmark/quarry_anchor/L in world)
			surface_anchor = get_turf(L)
			break
	if(!isturf(surface_anchor))
		log_game("SSquarry: no surface_anchor found at init; escape ropes will fail.")

	// Fallback scan for the elevator anchor: if the landmark's Initialize ran
	// before SSquarry's, our elevator.surface_bay would have been written
	// against a nil elevator. Re-do it here so it lands correctly.
	if(!length(elevator.surface_bay))
		for(var/obj/effect/landmark/quarry_elevator_anchor/A in world)
			var/turf/center = get_turf(A)
			if(!isturf(center))
				continue
			var/list/bay = list()
			for(var/dy in -1 to 1)
				for(var/dx in -1 to 1)
					var/turf/T = locate(center.x + dx, center.y + dy, center.z)
					if(isturf(T))
						bay += T
			elevator.surface_bay = bay
			var/list/surface_doors = list()
			for(var/turf/T as anything in bay)
				for(var/dir in GLOB.cardinal)
					var/turf/neighbor = get_step(T, dir)
					for(var/obj/machinery/door/airlock/lift/D in neighbor)
						if(!(D in surface_doors))
							surface_doors += D
			elevator.doors["0"] = surface_doors
			break
	if(!length(elevator.surface_bay))
		log_game("SSquarry: no elevator surface anchor found; elevator will be inert.")
	else
		// Car starts on the surface. Open the doors so players can board.
		elevator.open_doors_at(0)

	// Instantiate all layer configs.
	for(var/cfg_type in subtypesof(/datum/quarry_layer_config))
		configs += new cfg_type
	if(!length(configs))
		log_game("SSquarry: no /datum/quarry_layer_config subtypes found; layers will fail to generate.")

	// Carve cave network into the surface map around the hand-authored
	// rooms. The .dmm fills the area outside the room with mineable cave
	// walls; this gen punches walkable passages through them and tags
	// some walls as ore-bearing. The room/elevator structure (stonebricks,
	// concrete, elevator walls/floor) is non-mineral so it's left alone.
	generate_surface()

	// Layer 1 is NOT pregenerated here — that work (~15s for 256x256) is
	// deferred to the first client Login, which kicks off a background
	// spawn. By the time a player walks to the down-shaft, layer 1 is
	// ready. See ensure_pregen_started() and the /mob/new_player/Login
	// hook in modular_dq/code/modules/quarry/quarry_pregen_hook.dm.

	// One-shot memory profile dump. Wait a few seconds for the world to
	// settle (atoms, atmos, lighting all finished initializing), then
	// count types and log to game.log.
	spawn(50)	// 5 seconds
		quarry_profile_atoms()

	return SS_INIT_SUCCESS

// Idempotent: starts pregen of layer 1 in the background if it isn't
// already loaded or being generated. Cheap to call multiple times.
/datum/controller/subsystem/quarry/proc/ensure_pregen_started()
	if(layers["1"]?.loaded || generating["1"])
		return
	spawn(0)
		ensure_layer(1)

// Run the surface-biome cave generator on Z=1. Selected config has
// depth_weights = {"0": 100} so it picks deterministically.
/datum/controller/subsystem/quarry/proc/generate_surface()
	var/datum/quarry_layer_config/cfg = select_config(0)
	if(!cfg)
		log_game("SSquarry: no surface config; skipping surface gen")
		return

	// The surface .dmm's "b" tile is already /turf/simulated/mineral/cave/quarry,
	// matching the default config wall_turf. No ChangeTurf pass needed.
	new /datum/random_map/automata/cave_system/quarry(cfg, 1, 1, 1, world.maxx, world.maxy)

	// Place ores. Collect wall candidates once, then pick N at random.
	// Faster than iterating + prob() because we skip the iteration overhead
	// on the ~95% of tiles that wouldn't get ore anyway.
	if(cfg.ore_density > 0 && length(cfg.ore_table))
		var/list/walls = list()
		for(var/turf/simulated/mineral/T in block(locate(1, 1, 1), locate(world.maxx, world.maxy, 1)))
			if(T.density && !T.mineral && !T.ignore_mapgen && !T.ignore_oregen)
				walls += T
		place_ores_in(walls, cfg)

// Place ores on a random subset of the given wall list. count is computed
// from cfg.ore_density as a percentage of the wall list size; we then pick
// that many tiles directly via random sampling rather than iterating the
// full list and rolling prob() per cell.
/datum/controller/subsystem/quarry/proc/place_ores_in(list/walls, datum/quarry_layer_config/cfg)
	if(!length(walls) || !cfg.ore_density || !length(cfg.ore_table))
		return
	var/count = round(length(walls) * cfg.ore_density / 100)
	if(count <= 0)
		return
	var/list/pool = walls.Copy()
	for(var/i in 1 to count)
		if(!length(pool))
			break
		var/idx = rand(1, length(pool))
		var/turf/simulated/mineral/T = pool[idx]
		pool.Cut(idx, idx + 1)
		if(T.mineral || T.ignore_mapgen || T.ignore_oregen)
			continue
		var/mineral_name = pickweight(cfg.ore_table)
		if(mineral_name && (mineral_name in GLOB.ore_data))
			T.mineral = GLOB.ore_data[mineral_name]
			T.UpdateMineral()

// Elevator stops are at depths 1, 6, 11, 16, ... (the sequence 1 + 5k).
// Returns the deepest stop <= deepest_visited, or null if no depth has
// been visited yet. The surface panel uses this as its "send to N" target.
/datum/controller/subsystem/quarry/proc/deepest_elevator_stop()
	if(deepest_visited < 1)
		return null
	return 1 + 5 * round((deepest_visited - 1) / 5)

// Returns a /datum/quarry_layer_config picked weighted-randomly from all
// configs whose weight_at(depth) is non-zero. Returns null if none apply.
/datum/controller/subsystem/quarry/proc/select_config(depth)
	var/list/weighted = list()
	for(var/datum/quarry_layer_config/cfg in configs)
		var/w = cfg.weight_at(depth)
		if(w > 0)
			weighted[cfg] = w
	if(!length(weighted))
		return null
	return pickweight(weighted)

/datum/controller/subsystem/quarry/fire()
	unload_empty_layers()

// Sweep occupied-but-now-empty layers and unload them.
// Layers that have never been entered (pregenerated, awaiting a visitor)
// are skipped — they are not "abandoned," they are "unused yet." Called
// periodically as a backstop and on demand by the escape rope.
/datum/controller/subsystem/quarry/proc/unload_empty_layers()
	// Snapshot the keys: unload_layer can mutate the list (cascade unload
	// of pregenerated descendants).
	var/list/keys = layers.Copy()
	for(var/key in keys)
		var/datum/quarry_layer/L = layers[key]
		if(!L?.loaded || !L.ever_occupied)
			continue
		if(is_layer_empty(L.z))
			unload_layer(L.depth)

/datum/controller/subsystem/quarry/proc/get_layer(depth)
	return layers["[depth]"]

// Returns the /datum/quarry_layer for the given depth, creating + generating
// it if it does not currently exist or has been unloaded.
//
// Idempotent and safe to call from multiple ladder-click handlers. If a
// concurrent caller is already generating this depth, this caller waits
// up to ~10 seconds for the result.
/datum/controller/subsystem/quarry/proc/ensure_layer(depth)
	var/key = "[depth]"
	var/datum/quarry_layer/existing = layers[key]
	if(existing?.loaded)
		return existing

	// Wait out a concurrent generation.
	if(generating[key])
		for(var/i in 1 to 50)
			sleep(2)
			existing = layers[key]
			if(existing?.loaded)
				return existing
			if(!generating[key])
				break

	// Re-check after the wait.
	existing = layers[key]
	if(existing?.loaded)
		return existing

	generating[key] = TRUE
	var/datum/quarry_layer/L = generate_layer(depth)
	generating -= key

	if(L)
		layers[key] = L
	return L

// Allocates a Z, loads the empty stone template, applies a biome config,
// runs the cave generator, marks ores, scatters decorations, spawns mobs,
// and places the escape ladder and the down-ladder. Returns the layer
// record on success, null on failure.
/datum/controller/subsystem/quarry/proc/generate_layer(depth)
	var/datum/quarry_layer_config/cfg = select_config(depth)
	if(!cfg)
		log_game("SSquarry: no applicable config for depth [depth]; refusing to generate")
		return null

	var/datum/map_template/quarry_layer/template = new
	if(!template.load_new_z())
		log_game("SSquarry: failed to load_new_z for depth [depth]")
		return null

	var/new_z = world.maxz

	// The substrate is already /turf/simulated/mineral/cave/quarry, matching
	// the default config wall_turf. No ChangeTurf pass needed. If a config
	// ever wants a non-default wall_turf, re-add a conditional pass here.

	// Carve the cave. The generator subtype reads density / iterations from
	// the config; passing seed=null leaves priority_process unset so the
	// per-cell apply loop yields after every turf and the server stays
	// responsive. The generating[key] re-entrancy guard above prevents
	// concurrent runs at the same depth, so we don't need priority_process
	// for safety.
	new /datum/random_map/automata/cave_system/quarry(cfg, 1, 1, new_z, QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE)

	// Bucket tiles for the placement passes that follow.
	var/list/floor_candidates = list()
	var/list/wall_candidates = list()
	for(var/turf/simulated/mineral/T in block(locate(1, 1, new_z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, new_z)))
		if(T.density)
			wall_candidates += T
		else
			floor_candidates += T
	if(length(floor_candidates) < 2)
		log_game("SSquarry: generator produced fewer than 2 floor tiles at depth [depth]")
		return null

	// Carve the elevator FIRST. It picks a 5x5 footprint and forces tiles
	// regardless of cave shape, so it'd happily overwrite a rope or ladder
	// placed earlier. Doing carving first means the rope/ladder/decoration
	// passes below see a floor_candidates list with the elevator's
	// footprint already excluded.
	var/list/bay_tiles = carve_elevator_room(new_z, depth, floor_candidates, wall_candidates)
	if(!length(bay_tiles))
		log_game("SSquarry: failed to carve elevator room at depth [depth]")
		return null
	elevator.layer_bays["[depth]"] = bay_tiles

	// Ore placement: percent of walls become ore-bearing, ore type picked
	// per tile from the config's weighted table.
	if(cfg.ore_density > 0 && length(cfg.ore_table))
		place_ores_in(wall_candidates, cfg)

	if(length(floor_candidates) < 2)
		log_game("SSquarry: too few floor tiles remain after elevator carve at depth [depth]")
		return null

	// Pick the two structural tiles before decorations and mobs, so a
	// decoration doesn't end up on top of the rope or descent ladder.
	var/turf/rope_tile = pick(floor_candidates)
	floor_candidates -= rope_tile
	var/turf/ladder_tile = pick(floor_candidates)
	floor_candidates -= ladder_tile

	var/obj/structure/quarry_rope/rope = new(rope_tile)
	var/obj/structure/ladder/quarry_descent/down_ladder = new(ladder_tile)

	// Decoration placement: percent of remaining floor tiles get a deco.
	if(cfg.decoration_density > 0 && length(cfg.decoration_table))
		for(var/turf/T as anything in floor_candidates)
			if(!prob(cfg.decoration_density))
				continue
			var/deco_type = pickweight(cfg.decoration_table)
			if(deco_type)
				new deco_type(T)

	// Hostile mob spawn: mob_count random floor tiles each get one mob.
	if(cfg.mob_count > 0 && length(cfg.mob_table))
		var/spawned = 0
		var/list/spawn_candidates = floor_candidates.Copy()
		while(spawned < cfg.mob_count && length(spawn_candidates))
			var/turf/T = pick(spawn_candidates)
			spawn_candidates -= T
			var/mob_type = pickweight(cfg.mob_table)
			if(mob_type)
				new mob_type(T)
			spawned++

	var/datum/quarry_layer/L = new(depth)
	L.z = new_z
	L.loaded = TRUE
	L.config = cfg
	L.down_ladder = down_ladder
	L.arrival_rope = rope
	down_ladder.depth = depth
	return L

// Carves a 3x3 elevator room out of the cave at a random valid location.
// Returns the 3x3 bay tiles in row-major order (matching surface bay).
// Mutates floor_candidates and wall_candidates in place to remove any
// tiles that the elevator footprint or approach corridor consumed.
/datum/controller/subsystem/quarry/proc/carve_elevator_room(z, depth, list/floor_candidates, list/wall_candidates)
	// Pick center such that the 5x5 fits and a 3-tile-deep approach
	// corridor north of the door fits inside the map.
	var/cx = rand(3, QUARRY_LAYER_SIZE - 2)
	var/cy = rand(3, QUARRY_LAYER_SIZE - 5)

	// Wall ring: perimeter of 5x5 centered on (cx, cy). The full north
	// edge (3 wall tiles at dy=2) becomes three lift airlocks, matching
	// the 3-door entry on the surface.
	for(var/dx in -2 to 2)
		for(var/dy in -2 to 2)
			var/tx = cx + dx
			var/ty = cy + dy
			// Skip the interior (3x3).
			if(abs(dx) <= 1 && abs(dy) <= 1)
				continue
			var/turf/T = locate(tx, ty, z)
			if(!isturf(T))
				continue
			floor_candidates -= T
			wall_candidates -= T
			// North row's 3 interior columns get doors; the two NW/NE
			// corners stay as walls.
			if(abs(dx) <= 1 && dy == 2)
				T = T.ChangeTurf(/turf/simulated/floor/tiled/dark)
				new /obj/machinery/door/airlock/lift(T)
				continue
			T.ChangeTurf(/turf/simulated/wall/elevator)

	// Interior 3x3: force dark tiled floor, collect into bay list in
	// row-major order (top row first, x ascending).
	var/list/bay = list()
	for(var/dy in -1 to 1)
		for(var/dx in -1 to 1)
			var/turf/T = locate(cx + dx, cy + dy, z)
			if(!isturf(T))
				continue
			floor_candidates -= T
			wall_candidates -= T
			T = T.ChangeTurf(/turf/simulated/floor/tiled/dark)
			bay += T

	if(length(bay) != 9)
		return list()

	// Carve a 3-tile-deep approach corridor north of the door so the
	// elevator is reachable without immediately needing a pickaxe. The
	// corridor is (cx-1..cx+1, cy+3..cy+5), plus an extra single tile at
	// (cx-2, cy+3) for the exterior call-button on the NW corner wall.
	for(var/dx in -1 to 1)
		for(var/dy in 3 to 5)
			var/turf/T = locate(cx + dx, cy + dy, z)
			if(!isturf(T))
				continue
			if(istype(T, /turf/simulated/mineral))
				var/turf/simulated/mineral/M = T
				if(M.density)
					M.make_floor()
				floor_candidates -= M
				wall_candidates -= M

	// Extra tile at (cx-2, cy+3) so the NW-corner exterior call button is
	// reachable. The button mounts visually onto the wall at (cx-2, cy+2)
	// (the elevator's NW corner wall).
	var/turf/exterior_panel_tile = locate(cx - 2, cy + 3, z)
	if(istype(exterior_panel_tile, /turf/simulated/mineral))
		var/turf/simulated/mineral/M = exterior_panel_tile
		if(M.density)
			M.make_floor()
		floor_candidates -= M
		wall_candidates -= M

	// Find the three doors we just placed; cache them in elevator.doors.
	var/list/this_layer_doors = list()
	for(var/dx in -1 to 1)
		var/turf/door_tile = locate(cx + dx, cy + 2, z)
		for(var/obj/machinery/door/airlock/lift/D in door_tile)
			this_layer_doors += D
	elevator.doors["[depth]"] = this_layer_doors

	// Interior call button on the elevator's south wall, reachable from
	// inside the bay. Used to send the elevator to the surface. Same tile
	// also gets a south-facing light fixture (visually pinned to the
	// south wall) to match the surface elevator's lighting.
	var/turf/south_panel_tile = locate(cx, cy - 1, z)
	if(isturf(south_panel_tile))
		var/obj/structure/quarry_elevator_panel/interior = new(south_panel_tile)
		interior.depth = depth
		interior.dir = SOUTH
		interior.pixel_y = -24
		var/obj/machinery/light/L = new(south_panel_tile)
		L.dir = SOUTH

	// Exterior call button on the NW corner wall, reachable from the
	// corridor outside the elevator. Used to summon the elevator here when
	// it's parked elsewhere.
	if(isturf(exterior_panel_tile))
		var/obj/structure/quarry_elevator_panel/exterior = new(exterior_panel_tile)
		exterior.depth = depth
		exterior.dir = SOUTH
		exterior.pixel_y = -24
		exterior.is_call_panel = TRUE

	return bay
// The Z-index itself is not reclaimed (BYOND limitation).
//
// Cascade rule: if the next-deeper layer exists, is loaded, and has never
// been entered, it is also unloaded. A never-occupied layer is a
// pregenerated speculation that no longer has a viable player path —
// reaching it requires descending from this layer, which no longer exists.
// The cascade is recursive; in practice it only ever steps once because
// pregen is one-ahead, but the loop is cheap and survives future changes.
/datum/controller/subsystem/quarry/proc/unload_layer(depth)
	var/key = "[depth]"
	var/datum/quarry_layer/L = layers[key]
	if(!L?.loaded)
		return

	// If the elevator is currently parked at this depth, recall its bay
	// contents to the surface before we wipe the Z. This preserves the
	// "persistent progress" promise — items the player left in the lift
	// don't get qdel'd along with the layer.
	if(elevator && elevator.current_depth == depth && !elevator.traveling)
		var/list/origin_bay = elevator.bay_at(depth)
		var/list/dest_bay = elevator.bay_at(0)
		if(length(origin_bay) == length(dest_bay))
			for(var/i in 1 to length(origin_bay))
				var/turf/src_t = origin_bay[i]
				var/turf/dst_t = dest_bay[i]
				if(!isturf(src_t) || !isturf(dst_t))
					continue
				for(var/atom/movable/AM in src_t)
					if(istype(AM, /mob/observer))
						continue
					if(AM.anchored)
						continue
					AM.forceMove(dst_t)
		elevator.current_depth = 0

	// Drop the layer's bay reference. The doors get qdel'd along with the Z
	// below, so just clear the list.
	if(elevator)
		elevator.layer_bays -= key
		elevator.doors -= key

	var/quarry_z = L.z
	for(var/turf/T in block(locate(1, 1, quarry_z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, quarry_z)))
		for(var/atom/movable/AM in T)
			if(istype(AM, /mob/observer))
				continue
			qdel(AM)
		T.ChangeTurf(/turf/space)

	L.loaded = FALSE
	L.z = 0
	L.down_ladder = null
	L.arrival_rope = null
	layers -= key

	// Cascade-unload any pregenerated descendant that is now orphaned.
	var/datum/quarry_layer/next = layers["[depth + 1]"]
	if(next?.loaded && !next.ever_occupied)
		unload_layer(depth + 1)

// Empty iff no /mob/living with an active mind (live client OR temporarily
// disconnected body) is on the Z. Bodies of disconnected players keep the
// layer loaded so players can reconnect.
/datum/controller/subsystem/quarry/proc/is_layer_empty(z)
	for(var/mob/living/M in GLOB.living_mob_list)
		if(M.z != z)
			continue
		if(M.mind)
			return FALSE
	return TRUE
