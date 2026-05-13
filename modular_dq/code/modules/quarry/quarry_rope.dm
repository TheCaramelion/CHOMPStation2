// The escape ladder placed on every procedural quarry layer.
//
// A player arriving on a layer arrives on top of this ladder (the descent
// ladder's target_down is the escape ladder, not the layer's own deeper
// shaft). To return to the surface, they click the ladder, confirm the
// prompt, and are teleported to SSquarry.surface_anchor on the entrance
// map.
//
// After teleport, an on-demand layer sweep is triggered so any procedural
// layers the player just abandoned can be unloaded immediately rather
// than waiting for the 30-second periodic backstop.

/obj/structure/quarry_rope
	name = "escape ladder"
	desc = "A worn ladder bolted to the rock, leading straight up. Climbing it would take you all the way back to the surface."
	icon = 'icons/obj/structures/multiz.dmi'
	// "ladder10" is the up-only ladder sprite (UP bit set, DOWN bit clear).
	icon_state = "ladder10"
	density = FALSE
	opacity = 0
	anchored = TRUE
	unacidable = TRUE
	light_range = 2
	light_power = 0.8

/obj/structure/quarry_rope/attack_hand(mob/M)
	if(!M.Adjacent(src))
		to_chat(M, span_warning("You need to be next to \the [src] to start climbing."))
		return
	if(M.incapacitated())
		to_chat(M, span_warning("You can't climb in this state."))
		return

	var/choice = tgui_alert(M, "Climb back to the surface? You won't be coming back down without finding another shaft.", "Escape Ladder", list("Climb", "Cancel"))
	if(choice != "Climb")
		return
	if(QDELETED(src) || QDELETED(M) || !M.Adjacent(src))
		return

	var/turf/anchor = SSquarry.surface_anchor
	if(!isturf(anchor))
		to_chat(M, span_warning("The ladder shudders and grips refuse to hold. Something is wrong with the surface."))
		log_game("SSquarry: escape ladder use failed, surface_anchor is [anchor]")
		return

	M.visible_message(
		span_infoplain(span_bold("\The [M]") + " starts climbing the ladder upward!"),
		span_info("You start climbing the ladder, and it carries you up faster than you'd expect."),
		span_info("You hear the rapid creaking of an old ladder under load.")
	)

	if(!do_after(M, 2 SECONDS, target = src))
		return
	if(QDELETED(M) || !isturf(SSquarry.surface_anchor))
		return

	M.forceMove(SSquarry.surface_anchor)

	// Sweep procedural layers; anything empty unloads now.
	SSquarry.unload_empty_layers()

	// Prime a fresh layer 1 in the background so the next descent from the
	// surface is instant. The sweep above likely unloaded the previously
	// pregenerated layer 1 (and any chain above it) as orphans, so we have
	// to re-prime.
	spawn(0)
		SSquarry.ensure_layer(1)
