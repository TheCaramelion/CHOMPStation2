/datum/quarry_layer
	var/depth = 0
	var/z = 0
	var/loaded = FALSE
	// Set TRUE when a player has actually arrived on this layer. Pregenerated
	// layers stay FALSE until first arrival, which exempts them from the
	// periodic empty-layer sweep that would otherwise unload them before use.
	var/ever_occupied = FALSE
	// The down-ladder a future descent will spawn on top of when generating
	// the next layer. Players arriving here arrive on arrival_rope, not here.
	var/obj/structure/ladder/quarry_descent/down_ladder
	// The escape rope on this layer. Descents target this so the player
	// arrives on the rope. Click the rope to return to the surface.
	var/obj/structure/quarry_rope/arrival_rope
	// The biome config that generated this layer. Kept for diagnostics and
	// future features that may want to inspect a layer's flavor at runtime.
	var/datum/quarry_layer_config/config

/datum/quarry_layer/New(_depth)
	depth = _depth
