// Per-layer configuration for the deep quarry generator.
//
// Each /datum/quarry_layer_config describes one "biome" — what rock the
// layer is made of, how dense it is, what ores it has, what decorations
// scatter on the floor, and what hostile mobs spawn. SSquarry picks one
// config per generated layer using weighted depth bands declared on the
// config itself.
//
// A config is data-only. The generator reads its vars; it never executes.

/datum/quarry_layer_config
	// Cellular-automaton parameters. wall_density is the initial probability
	// a cell is a wall (0-100). Higher = more solid stone, smaller caves.
	// smoothing_iterations is how many CA passes refine the shape.
	var/wall_density = 50
	var/smoothing_iterations = 4

	// Turf type used for both walls and floors. The generator ChangeTurfs the
	// loaded substrate to this type before carving. Must be a subtype of
	// /turf/simulated/mineral so make_floor() / make_wall() work in place.
	var/turf/simulated/mineral/wall_turf = /turf/simulated/mineral/cave

	// Ore-bearing walls. ore_density is percent of wall tiles that carry
	// ore. ore_table is an associative list of ORE_X define -> weight; one
	// is picked per ore-bearing wall.
	var/ore_density = 6
	var/list/ore_table = list()

	// Decorations placed on floor tiles. decoration_density is percent of
	// floors that get a decoration. decoration_table is typepath -> weight.
	// Use only non-dense decorations unless you want obstacles.
	var/decoration_density = 2
	var/list/decoration_table = list()

	// Hostile mob spawn at gen time. mob_count is the approximate number
	// of mobs to spawn (not a percent). mob_table is mob typepath -> weight.
	var/mob_count = 0
	var/list/mob_table = list()

	// Depth weights. Keys are range strings, values are pickweight values.
	// Range syntax:
	//   "1-3"  inclusive band
	//   "5"    exact depth
	//   "7+"   open-ended downward (7, 8, 9, ...)
	// At selection time SSquarry queries each config for its weight at the
	// target depth, and pickweights across all non-zero-weight configs.
	var/list/depth_weights = list()


// Returns this config's selection weight at the given depth, or 0 if it
// does not apply. The first matching range key wins; ranges should not
// overlap within a single config.
/datum/quarry_layer_config/proc/weight_at(depth)
	for(var/key in depth_weights)
		if(range_contains(key, depth))
			return depth_weights[key]
	return 0


// Parse a range string and report whether it includes the given depth.
// Accepts "N", "N-M", or "N+". Unrecognized formats return FALSE.
/proc/range_contains(range_key, depth)
	if(!istext(range_key))
		return FALSE

	// "N+" form: open-ended downward.
	var/plus_pos = findtext(range_key, "+")
	if(plus_pos)
		var/min_str = copytext(range_key, 1, plus_pos)
		var/min_val = text2num(min_str)
		if(isnull(min_val))
			return FALSE
		return depth >= min_val

	// "N-M" form: inclusive band.
	var/dash_pos = findtext(range_key, "-")
	if(dash_pos)
		var/min_str = copytext(range_key, 1, dash_pos)
		var/max_str = copytext(range_key, dash_pos + 1)
		var/min_val = text2num(min_str)
		var/max_val = text2num(max_str)
		if(isnull(min_val) || isnull(max_val))
			return FALSE
		return depth >= min_val && depth <= max_val

	// "N" form: exact match.
	var/exact = text2num(range_key)
	if(isnull(exact))
		return FALSE
	return depth == exact
