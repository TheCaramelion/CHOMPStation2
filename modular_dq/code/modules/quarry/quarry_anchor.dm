// Surface delivery point for the escape rope.
//
// One of these is placed on the entrance .dmm. On Initialize it registers
// its turf as SSquarry.surface_anchor. When a player climbs an escape
// rope on any depth, they are forceMove'd to this turf.

/obj/effect/landmark/quarry_anchor
	name = "quarry surface anchor"
	desc = "The point where escape ropes deliver their riders."

/obj/effect/landmark/quarry_anchor/Initialize(mapload)
	. = ..()
	// SSquarry may or may not have its Initialize() called yet; either way
	// we set the var. If SSquarry inits later, it will find the landmark
	// via its own scan and confirm. Landmarks are atom-level, so the global
	// SS#name has been declared even if PreInit hasn't been called yet.
	SSquarry.surface_anchor = get_turf(src)
