// Indestructible bedrock wall — the perimeter ring of procedural quarry
// layers. /turf/unsimulated/wall is dense, opacity 1, blocks_air; players
// can't mine it because it's not /turf/simulated/mineral so make_floor()
// doesn't apply. The "rock-alt" icon state is the darker rock variant in
// walls.dmi, distinguishing it from the lighter mineable cave walls.
/turf/unsimulated/wall/bedrock
	name = "bedrock"
	desc = "Solid, ancient stone. No pickaxe will scratch this."
	icon = 'icons/turf/walls.dmi'
	icon_state = "rock-alt"


// Cave wall subtype that renders as rocky ground (not sand) when carved.
//
// /turf/simulated/mineral's make_floor() toggles density/opacity in place
// without changing the type — the carved tile still reports as the same
// mineral subtype. The icon switches to whichever sand_icon_state the
// subtype defines, defaulting to "asteroid" (the sandy look).
//
// We want the quarry's carved tiles to look like rocky cave floor, not
// sand. Override sand_icon_path/state to the outdoors rock sprite.

/turf/simulated/mineral/cave/quarry
	sand_icon_path = 'icons/turf/outdoors.dmi'
	sand_icon_state = "rock"
