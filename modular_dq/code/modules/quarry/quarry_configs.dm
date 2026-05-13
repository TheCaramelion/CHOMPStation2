// Concrete quarry layer configs. Each declares one "biome" and what depth
// bands it appears in. SSquarry uses pickweight across all configs whose
// weight_at(depth) returns non-zero.

// Surface: the entrance map's biome. Tight cave network packed around the
// hand-authored station rooms. Common ores only. No mobs, no decorations
// (the station is supposed to feel like a base, not a wilderness). Only
// applies at depth 0; never picked for procedural layers.
/datum/quarry_layer_config/surface
	wall_density = 55
	smoothing_iterations = 4
	wall_turf = /turf/simulated/mineral/cave/quarry

	ore_density = 7
	ore_table = list(
		ORE_HEMATITE = 60,
		ORE_CARBON = 40,
		ORE_COPPER = 30,
		ORE_TIN = 20,
		ORE_QUARTZ = 15,
	)

	decoration_density = 0
	decoration_table = list()

	mob_count = 0
	mob_table = list()

	depth_weights = list(
		"0" = 100,
	)


// Shallows: light cave-stone, plentiful common ores, scattered mushrooms,
// no hostile mobs. Welcoming starter biome.
/datum/quarry_layer_config/shallows
	wall_density = 45
	smoothing_iterations = 4
	wall_turf = /turf/simulated/mineral/cave/quarry

	ore_density = 8
	ore_table = list(
		ORE_HEMATITE = 60,
		ORE_COPPER = 40,
		ORE_TIN = 30,
		ORE_CARBON = 30,
		ORE_QUARTZ = 15,
		ORE_BAUXITE = 10,
	)

	decoration_density = 3
	decoration_table = list(
		/obj/structure/flora/mushroom = 80,
		/obj/structure/flora/rocks1 = 20,
		/obj/structure/flora/rocks2 = 20,
	)

	mob_count = 0
	mob_table = list()

	depth_weights = list(
		"1-3" = 100,
		"4-5" = 30,
	)


// Midmines: denser stone, mid-tier ores, a few rats and bats. The middle
// of the quarry — serious work but survivable.
/datum/quarry_layer_config/midmines
	wall_density = 55
	smoothing_iterations = 4
	wall_turf = /turf/simulated/mineral/cave/quarry

	ore_density = 10
	ore_table = list(
		ORE_HEMATITE = 30,
		ORE_COPPER = 20,
		ORE_SILVER = 30,
		ORE_GOLD = 25,
		ORE_URANIUM = 20,
		ORE_RUTILE = 15,
		ORE_BAUXITE = 10,
		ORE_LEAD = 10,
	)

	decoration_density = 2
	decoration_table = list(
		/obj/structure/flora/smallbould = 40,
		/obj/structure/flora/bboulder1 = 30,
		/obj/structure/flora/bboulder2 = 30,
		/obj/structure/flora/mushroom = 30,
	)

	mob_count = 2
	mob_table = list(
		/mob/living/simple_mob/animal/passive/mouse/rat = 60,
		/mob/living/simple_mob/vore/bat = 40,
		/mob/living/simple_mob/vore/aggressive/rat = 20,
	)

	depth_weights = list(
		"4-7" = 100,
		"8-10" = 40,
	)


// Deeps: very dense rock, rare and high-value ores, real hostile mobs.
// The reward-and-risk band — bring a weapon.
/datum/quarry_layer_config/deeps
	wall_density = 62
	smoothing_iterations = 5
	wall_turf = /turf/simulated/mineral/cave/quarry

	ore_density = 14
	ore_table = list(
		ORE_GOLD = 25,
		ORE_PLATINUM = 25,
		ORE_PHORON = 25,
		ORE_DIAMOND = 15,
		ORE_VERDANTIUM = 8,
		ORE_PAINITE = 5,
		ORE_VOPAL = 3,
		ORE_URANIUM = 20,
	)

	decoration_density = 2
	decoration_table = list(
		/obj/structure/flora/bboulder1 = 50,
		/obj/structure/flora/bboulder2 = 50,
		/obj/structure/flora/smallbould = 30,
	)

	mob_count = 4
	mob_table = list(
		/mob/living/simple_mob/vore/aggressive/rat = 50,
		/mob/living/simple_mob/animal/giant_spider/tunneler/cave = 40,
		/mob/living/simple_mob/vore/oregrub = 30,
		/mob/living/simple_mob/vore/stalker = 15,
	)

	depth_weights = list(
		"8+" = 100,
	)
