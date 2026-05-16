// Quarry layer persistence.
//
// When the last player leaves a quarry layer, instead of hard-deleting the
// z and rebuilding from procgen on next entry, we serialize the z to a .dmm
// file under data/quarry_snapshots/ keyed by depth. The next time a player
// descends to that depth we LoadMaps the snapshot back, re-cache elevator
// references, and spawn fresh mobs from the layer's config.
//
// Why depth-keyed and not seed-keyed: this fork's quarry treats "depth N"
// as a single semantic location for a round — every player who descends to
// N lands on the same z. Two snapshots at the same depth would never both
// be wanted, so depth is a stable enough key.
//
// What survives a snapshot/restore round-trip:
//   - All turfs (mined-out tiles, ChangeTurf'd elevator floor / walls /
//     doors, ore-bearing wall states).
//   - All non-mob movable atoms (dropped loot, decorations, scaffolds,
//     flags, the descent ladder, the escape rope, the elevator panels).
//
// What does NOT survive (re-spawned from the layer config on restore):
//   - Hostile mobs. Any /mob/living on the z is qdel'd before SaveMaps so
//     the snapshot only contains static contents. After LoadMaps we walk
//     the layer config's mob_table and spawn fresh mobs on random floor
//     tiles, identical to the first-time generation pass. Mobs carry too
//     much per-instance state (AI controllers, signal subscriptions,
//     active targets) to round-trip cleanly via SaveMaps; cheaper to
//     respawn than to chase the bugs.

#define QUARRY_SNAPSHOT_DIR "data/quarry_snapshots/"

// Snapshot file path for a given depth.
/proc/_quarry_snapshot_path(depth)
	return "[QUARRY_SNAPSHOT_DIR][depth].dmm"


// Strip mobs from the z, then SaveMaps it to disk. Caller must guarantee
// no players are on the z (the elevator-bay clear in unload_layer handles
// the only common edge case where a body could linger). Returns TRUE on
// success.
/datum/controller/subsystem/quarry/proc/snapshot_layer(depth, z)
	if(!isnum(depth) || !isnum(z) || z < 1)
		return FALSE
	// Strip mobs first. Includes both AI hostile spawns and any leftover
	// player corpses that somehow remained — last-player-leaves should
	// have already cleared minds, but be defensive.
	for(var/mob/M in block(locate(1, 1, z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, z)))
		if(istype(M, /mob/observer))
			continue
		qdel(M)

	if(!fexists(QUARRY_SNAPSHOT_DIR))
		// world.SaveMaps writes through fcopy_rsc semantics; it expects
		// the directory to exist. text2file with an empty payload is the
		// idiomatic mkdir-equivalent in DM.
		text2file("", "[QUARRY_SNAPSHOT_DIR].keep")

	var/path = _quarry_snapshot_path(depth)
	// Wipe any prior snapshot so we don't merge with stale state.
	if(fexists(path))
		fdel(path)

	world.SaveMaps(path, 1, 1, z, QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, z)
	if(!fexists(path))
		log_game("SSquarry: snapshot for depth [depth] failed to write to [path]")
		return FALSE
	log_game("SSquarry: snapshot for depth [depth] written to [path] ([length(file2text(path))] bytes)")
	return TRUE


// Returns TRUE if a snapshot exists on disk for this depth.
/datum/controller/subsystem/quarry/proc/has_snapshot(depth)
	return fexists(_quarry_snapshot_path(depth))


// Allocate a fresh z and LoadMaps the snapshot onto it. Re-caches elevator
// bay tiles and door references for the depth. Re-spawns mobs from the
// layer config on random floor tiles. Returns the new /datum/quarry_layer
// on success, null on failure (caller should fall back to generate_layer).
/datum/controller/subsystem/quarry/proc/restore_layer(depth)
	var/path = _quarry_snapshot_path(depth)
	if(!fexists(path))
		return null

	var/datum/quarry_layer_config/cfg = select_config(depth)
	if(!cfg)
		log_game("SSquarry: no applicable config for depth [depth]; refusing to restore")
		return null

	// Allocate a fresh z. Walk world.maxz up by 1, then LoadMaps onto it.
	world.maxz++
	var/new_z = world.maxz

	if(!world.LoadMaps(path, 1, 1, new_z))
		log_game("SSquarry: LoadMaps failed for depth [depth] from [path]")
		return null

	// Re-find the structures that the SS caches references to. The bay
	// tiles aren't tagged on disk, but the elevator doors and panels are
	// — find the doors and reconstruct the 3x3 bay around them.
	var/list/bay = _quarry_recache_elevator(new_z, depth)
	if(!length(bay))
		log_game("SSquarry: restore for depth [depth] could not re-locate elevator bay; the snapshot may be corrupt")
		return null

	// Re-find the descent ladder and arrival rope. They were saved as
	// regular objs so they round-tripped, just need to grab the references
	// for the layer record so unload paths work.
	var/obj/structure/ladder/quarry_descent/down_ladder = null
	var/obj/structure/quarry_rope/arrival_rope = null
	for(var/obj/structure/ladder/quarry_descent/L in block(locate(1, 1, new_z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, new_z)))
		down_ladder = L
		break
	for(var/obj/structure/quarry_rope/R in block(locate(1, 1, new_z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, new_z)))
		arrival_rope = R
		break

	// Re-spawn hostile mobs on a fresh random sample of floor tiles.
	// Snapshot deliberately stripped them; this matches first-time
	// generation behaviour so a returning player doesn't walk into an
	// empty layer.
	if(cfg.mob_count > 0 && length(cfg.mob_table))
		var/list/floor_candidates = list()
		for(var/turf/simulated/floor/T in block(locate(1, 1, new_z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, new_z)))
			// Don't spawn on the elevator bay or on tiles already hosting
			// content (the rope tile, the ladder tile, decorations).
			if(T in bay)
				continue
			if(length(T.contents))
				continue
			floor_candidates += T
		var/spawned = 0
		while(spawned < cfg.mob_count && length(floor_candidates))
			var/turf/T = pick(floor_candidates)
			floor_candidates -= T
			var/mob_type = pickweight(cfg.mob_table)
			if(mob_type)
				new mob_type(T)
			spawned++

	var/datum/quarry_layer/L = new(depth)
	L.z = new_z
	L.loaded = TRUE
	L.config = cfg
	L.down_ladder = down_ladder
	L.arrival_rope = arrival_rope
	if(down_ladder)
		down_ladder.depth = depth
	// A restored layer is by definition one a player has visited (it only
	// got snapshotted because someone left it). Mark it occupied so the
	// empty-sweep treats it correctly.
	L.ever_occupied = TRUE
	log_game("SSquarry: restored depth [depth] from snapshot onto z [new_z]")
	return L


// Re-locate the elevator bay on a freshly-loaded z by finding its doors,
// then reconstructing the 3x3 floor block south of them. Re-caches the
// bay and door lists into SSquarry.elevator. Returns the bay tile list
// in row-major order on success, empty list on failure.
/datum/controller/subsystem/quarry/proc/_quarry_recache_elevator(z, depth)
	var/list/lift_doors = list()
	for(var/obj/machinery/door/airlock/lift/D in block(locate(1, 1, z), locate(QUARRY_LAYER_SIZE, QUARRY_LAYER_SIZE, z)))
		lift_doors += D
	if(!length(lift_doors))
		return list()

	// The three doors are co-linear on the north edge of the bay. Find
	// the door at the centre of that line; the bay is the 3x3 block one
	// tile south of it.
	sortTim(lift_doors, GLOBAL_PROC_REF(cmp_atom_x_asc))
	var/obj/machinery/door/airlock/lift/center_door = lift_doors[round(length(lift_doors) / 2) + 1]
	if(!center_door)
		return list()
	var/turf/center_door_tile = get_turf(center_door)
	if(!isturf(center_door_tile))
		return list()

	var/cx = center_door_tile.x
	var/cy = center_door_tile.y - 2  // bay centre is two tiles south of the centre door

	var/list/bay = list()
	for(var/dy in -1 to 1)
		for(var/dx in -1 to 1)
			var/turf/T = locate(cx + dx, cy + dy, z)
			if(isturf(T))
				bay += T
	if(length(bay) != 9)
		return list()

	if(!elevator)
		return list()
	elevator.layer_bays["[depth]"] = bay
	elevator.doors["[depth]"] = lift_doors
	return bay


// Comparator: sort atoms by ascending x. Used by the elevator-recache to
// pick the centre door from a co-linear row.
/proc/cmp_atom_x_asc(atom/a, atom/b)
	return a.x - b.x


#undef QUARRY_SNAPSHOT_DIR
