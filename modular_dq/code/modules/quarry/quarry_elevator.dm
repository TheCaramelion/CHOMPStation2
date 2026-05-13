// The deep quarry's freight elevator.
//
// One physical car. At any moment the car is parked at exactly one floor:
// the surface (depth 0), or a procedural layer (depth >= 1). The car never
// physically traverses a Z-level. Instead, its "current location" tracks
// which 3×3 floor area is the cargo bay; on a trip, the contents of those
// 9 tiles teleport (forceMove) to the destination's 9 tiles. From the
// player's perspective: doors close, 5 seconds elapse, doors open at the
// new floor.
//
// Persistence: items left inside the car travel with it. Items left on
// the surface bay or any layer's bay STAY THERE until the car returns,
// because they were on the room floor, not in the car. (Mechanically, the
// car IS the room — but only one room at a time is "the car." See
// occupied_pad below.)

#define QUARRY_ELEVATOR_TRAVEL_TIME 5 SECONDS
#define QUARRY_ELEVATOR_BAY_SIZE 3

/datum/quarry_elevator
	// Where the car is currently parked. 0 = surface, 1+ = layer depth.
	var/current_depth = 0
	// True during the transit window; blocks new trips.
	var/traveling = FALSE

	// The 9-tile cargo bay on the surface map. Cached at world init from
	// the /obj/effect/landmark/quarry_elevator_anchor placement.
	var/list/surface_bay = list()

	// Bays on procedural layers, keyed by depth string. Populated when each
	// layer generates.
	var/list/layer_bays = list()

	// All control panels that point at this elevator. Indexed for state
	// updates after travel.
	var/list/panels = list()

	// Doors on every bay, indexed by depth string. Two doors per bay if the
	// generator placed two; only one in v1.
	var/list/doors = list()

// Returns the 9 turfs currently acting as the car's cargo bay.
/datum/quarry_elevator/proc/occupied_pad()
	if(current_depth == 0)
		return surface_bay
	return layer_bays["[current_depth]"]

// Returns the 9 turfs of a specified depth's bay, regardless of where the
// car currently is. Used by the carving generator and the travel proc.
/datum/quarry_elevator/proc/bay_at(depth)
	if(depth == 0)
		return surface_bay
	return layer_bays["[depth]"]

// Dispatch the car from origin_depth to target_depth. Used by interior
// panels: they pass their own depth as origin so the player's bay is the
// origin regardless of where current_depth thinks the car is. This is
// more permissive than the "real" travel_to since it skips the
// current_depth check.
/datum/quarry_elevator/proc/dispatch_from(origin_depth, target_depth)
	if(traveling)
		return FALSE
	if(origin_depth == target_depth)
		return FALSE
	current_depth = origin_depth
	return travel_to(target_depth)

// Send the car to target_depth. Closes doors at the origin, waits the
// travel time, teleports cargo bay contents, opens doors at the
// destination. Returns TRUE on dispatch, FALSE if rejected (already
// traveling, or invalid destination).
/datum/quarry_elevator/proc/travel_to(target_depth)
	if(traveling)
		return FALSE
	if(target_depth == current_depth)
		return FALSE
	var/list/origin_bay = occupied_pad()
	var/list/dest_bay = bay_at(target_depth)
	if(!length(origin_bay) || !length(dest_bay))
		return FALSE
	if(length(origin_bay) != length(dest_bay))
		log_game("SSquarry elevator: bay size mismatch origin=[length(origin_bay)] dest=[length(dest_bay)]")
		return FALSE

	traveling = TRUE
	announce_to_bay(origin_bay, span_warning("The elevator doors slide closed."))
	close_doors_at(current_depth)

	sleep(QUARRY_ELEVATOR_TRAVEL_TIME)

	// Move cargo from origin to corresponding destination tile. Skip anchored
	// atoms — the elevator's own structure (panels, lights, doors, cables)
	// is anchored and belongs to the room, not the car. Also skip observers.
	// Both bay lists are kept in matched order (top-left to bottom-right).
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

	current_depth = target_depth
	open_doors_at(target_depth)
	announce_to_bay(dest_bay, span_info("The elevator doors slide open."))
	traveling = FALSE
	return TRUE

/datum/quarry_elevator/proc/announce_to_bay(list/turfs, msg)
	for(var/turf/T as anything in turfs)
		for(var/mob/M in T)
			to_chat(M, msg)

/datum/quarry_elevator/proc/close_doors_at(depth)
	// Note: airlock close is overridden in two places. The active override
	// (airlock_control.dm) has signature close(forced, ignore_safties, ...).
	// Pass forced positionally.
	for(var/obj/machinery/door/airlock/lift/D in doors["[depth]"])
		spawn(0)
			D.close(1)

/datum/quarry_elevator/proc/open_doors_at(depth)
	// Note: airlock open is overridden in two places. The active override
	// (airlock_control.dm) has signature open(surpress_send) — NOT
	// open(forced=0). Passing positionally, the value falls through ..()
	// to /obj/machinery/door/open's forced parameter, which bypasses the
	// power check we need to bypass (the quarry rooms become powered only
	// after the APC is online).
	for(var/obj/machinery/door/airlock/lift/D in doors["[depth]"])
		spawn(0)
			D.open(1)
