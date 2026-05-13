// Control panel for the quarry freight elevator.
//
// Two roles, distinguished by is_call_panel:
//   - Interior (is_call_panel = FALSE): inside the bay. Sends the elevator
//     to the surface (from a layer) or to the deepest visited stop (from
//     the surface). Requires the car to actually be on this floor.
//   - Exterior (is_call_panel = TRUE): outside the bay, mounted on a wall.
//     Summons the elevator to this floor. Does nothing if the car is
//     already here.

/obj/structure/quarry_elevator_panel
	name = "elevator control panel"
	desc = "An old industrial control panel for the freight elevator. The buttons stick a little."
	icon = 'icons/obj/turbolift.dmi'
	icon_state = "button"
	density = FALSE
	anchored = TRUE
	plane = MOB_PLANE
	light_range = 2
	light_power = 0.6

	// The depth this panel is on. Set at placement.
	var/depth = 0

	// TRUE for exterior call buttons (summon here); FALSE for interior
	// send buttons (dispatch this car).
	var/is_call_panel = FALSE

/obj/structure/quarry_elevator_panel/Initialize(mapload)
	. = ..()
	if(SSquarry?.elevator)
		SSquarry.elevator.panels += src

/obj/structure/quarry_elevator_panel/Destroy()
	if(SSquarry?.elevator)
		SSquarry.elevator.panels -= src
	return ..()

/obj/structure/quarry_elevator_panel/attack_hand(mob/user)
	if(!user.Adjacent(src))
		to_chat(user, span_warning("You need to be next to \the [src]."))
		return
	if(user.incapacitated())
		return

	var/datum/quarry_elevator/E = SSquarry?.elevator
	if(!E)
		to_chat(user, span_warning("\The [src] is dead. No power, no link."))
		return

	if(E.traveling)
		to_chat(user, span_warning("The elevator is in transit. Wait."))
		return

	if(is_call_panel)
		// Exterior call panel: summon the car here.
		if(E.current_depth == depth)
			to_chat(user, span_notice("The elevator is already here."))
			return
		var/confirm = tgui_alert(user, "The elevator is at [E.current_depth == 0 ? "the surface" : "depth [E.current_depth]"]. Call it here?", "Elevator", list("Call", "Cancel"))
		if(confirm != "Call" || E.traveling || E.current_depth == depth)
			return
		E.travel_to(depth)
		return

	// Interior dispatch panel. Sends the contents of THIS bay (the one the
	// player is standing in) to the destination — no auto-call needed,
	// because we override the car's current_depth to our floor first.
	var/target
	var/prompt
	if(depth == 0)
		target = SSquarry.deepest_elevator_stop()
		if(!target)
			to_chat(user, span_warning("There is no destination below. The shaft echoes."))
			return
		prompt = "Send the elevator to depth [target]?"
	else
		target = 0
		prompt = "Send the elevator back up to the surface?"

	var/confirm = tgui_alert(user, prompt, "Elevator", list("Send", "Cancel"))
	if(confirm != "Send" || E.traveling)
		return

	E.dispatch_from(depth, target)
