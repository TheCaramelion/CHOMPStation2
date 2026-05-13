// The descent ladder used both on the surface entrance map and on every
// procedural quarry layer. Always allows down-traversal; up-traversal is
// disabled because the quarry is strictly one-way (escape ropes handle
// return-to-surface separately).
//
// The descent destination is the next layer's escape rope, NOT its own
// down-ladder. The player arrives on the rope and must find the next
// layer's down-ladder by exploring. target_down is set to a rope object
// (not a ladder), which works because vanilla climb only uses
// get_turf(target_down) for the forceMove — duck typing is good here.
//
// SSquarry pregenerates one layer ahead of the player. The very first
// descent's destination is built at world init; every subsequent descent
// kicks off generation of the next layer in the background while the
// player is climbing into the current one.
//
// After a successful descent, the destination layer is marked as
// ever_occupied (exempting it from the periodic empty-sweep until a
// visitor leaves), and if the source layer is a procedural depth (>= 1)
// and has no remaining occupants, the source is unloaded.

/obj/structure/ladder/quarry_descent
	name = "deep shaft"
	desc = "A shaft cut straight down into the stone. You can climb deeper, but you won't be coming back."
	allowed_directions = DOWN

	// 0 = surface entrance; 1+ = procedural depth.
	var/depth = 0

// Skip the upstream Initialize's attempt_connection() — we pair ladders
// manually in SSquarry.generate_layer.
/obj/structure/ladder/quarry_descent/attempt_connection()
	return

// Vanilla /obj/structure/ladder/Destroy tries to clear target_down.target_up
// and target_up.target_down. Our target_down points at a quarry_rope, which
// does not have those vars (rope is /obj/structure, not /obj/structure/ladder).
// Null both targets ourselves before calling parent so it has nothing to do.
/obj/structure/ladder/quarry_descent/Destroy()
	target_down = null
	target_up = null
	return ..()

/obj/structure/ladder/quarry_descent/attack_hand(mob/M)
	if(!M.may_climb_ladders(src))
		return

	var/datum/quarry_layer/next_layer = SSquarry.ensure_layer(depth + 1)
	if(!next_layer)
		to_chat(M, span_warning("The shaft below is collapsed. Try again in a moment."))
		return

	// Aim at the next layer's escape rope so the player arrives on it.
	target_down = next_layer.arrival_rope
	if(!target_down)
		to_chat(M, span_warning("The shaft below is collapsed. Try again in a moment."))
		return

	var/source_z = z
	var/source_depth = depth
	var/dest_depth = depth + 1

	. = ..()

	// If the climb didn't actually move them off this z, treat it as a no-op:
	// they cancelled the do_after, were blocked at the destination, etc.
	if(M.z == source_z)
		return

	// Mark the destination as having seen a real visitor and start the
	// pregeneration of the next layer in the background. spawn(0) so the
	// generator runs across many ticks without delaying this proc.
	next_layer.ever_occupied = TRUE
	if(dest_depth > SSquarry.deepest_visited)
		SSquarry.deepest_visited = dest_depth
	spawn(0)
		SSquarry.ensure_layer(dest_depth + 1)

	// Unload the source if it was a procedural layer and is now empty.
	if(source_depth >= 1 && SSquarry.is_layer_empty(source_z))
		SSquarry.unload_layer(source_depth)
