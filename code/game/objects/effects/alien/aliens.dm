/* Alien Effects!
 * Contains:
 *		effect/alien
 *		Weeds
 *		Acid
 */

/*
 * effect/alien
 */
/obj/effect/alien
	name = "alien thing"
	desc = "there's something alien about this"
	icon = 'icons/mob/alien.dmi'

/*
 * Weeds
 */
#define NODERANGE 3
#define WEED_NORTH_EDGING "north"
#define WEED_SOUTH_EDGING "south"
#define WEED_EAST_EDGING "east"
#define WEED_WEST_EDGING "west"
#define WEED_NODE_GLOW "glow"
#define WEED_NODE_BASE "nodebase"

/obj/effect/alien/weeds
	name = "growth"
	desc = "Weird organic growth."
	icon_state = "weeds"
	anchored = TRUE
	density = FALSE
	unacidable = TRUE
	plane = TURF_PLANE
	layer = ABOVE_TURF_LAYER
	var/delete_me

	var/health = 15
	var/obj/effect/alien/weeds/node/linked_node = null
	var/static/list/weedImageCache

/obj/effect/alien/weeds/Initialize(mapload, var/node, var/newcolor)
	. = ..()
	if(isspace(loc) || delete_me)
		return INITIALIZE_HINT_QDEL

	linked_node = node
//	if(newcolor)
//		color = newcolor // CHOMPedit: No coloration.

	if(icon_state == "weeds")
		icon_state = pick("weeds", "weeds1", "weeds2", "weeds3", "weeds4", "weeds5", "weeds6", "weeds7", "weeds8", "weeds9", "weeds10", "weeds11", "weeds12", "weeds13", "weeds14", "weeds15") // CHOMPedit: More icons variants.

	fullUpdateWeedOverlays()

/obj/effect/alien/weeds/Destroy()
	var/turf/T = get_turf(src)
	// To not mess up the overlay updates.
	loc = null

	for (var/obj/effect/alien/weeds/W in range(1,T))
		W.updateWeedOverlays()

	linked_node = null
	return ..()

/obj/effect/alien/weeds/node
	icon_state = "weednode"
	name = "glowing growth"
	desc = "Weird glowing organic growth."
	layer = ABOVE_TURF_LAYER+0.01
	light_range = NODERANGE
	light_on = TRUE
	light_color = "#673972"

	var/node_range = NODERANGE
//	var/set_color = "#321D37" // CHOMPedit:  Removing coloration.

/obj/effect/alien/weeds/node/Initialize(mapload, var/node, var/newcolor)
	. = ..()

	for(var/obj/effect/alien/weeds/existing in loc)
		if(existing == src)
			continue
		else
			if(!(existing.flags & ATOM_INITIALIZED))
				existing.delete_me = TRUE
				continue
			qdel(existing)

	linked_node = src

//	if(newcolor)
//		set_color = newcolor
//	if(set_color)
//		color = set_color // CHOMPedit: Removing coloration.

	START_PROCESSING(SSobj, src) // Only the node processes in a subsystem, the rest are process()'d by the node

/obj/effect/alien/weeds/node/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/alien/weeds/proc/updateWeedOverlays()
	cut_overlays()

	if(!weedImageCache)
		weedImageCache = list()
		weedImageCache[WEED_NORTH_EDGING] = image('icons/mob/alien.dmi', "weeds_side_n", layer=2.11, pixel_y = -32)
		weedImageCache[WEED_SOUTH_EDGING] = image('icons/mob/alien.dmi', "weeds_side_s", layer=2.11, pixel_y = 32)
		weedImageCache[WEED_EAST_EDGING] = image('icons/mob/alien.dmi', "weeds_side_e", layer=2.11, pixel_x = -32)
		weedImageCache[WEED_WEST_EDGING] = image('icons/mob/alien.dmi', "weeds_side_w", layer=2.11, pixel_x = 32)

	var/turf/N = get_step(src, NORTH)
	var/turf/S = get_step(src, SOUTH)
	var/turf/E = get_step(src, EAST)
	var/turf/W = get_step(src, WEST)
	if(istype(N, /turf/simulated/floor) && !locate(/obj/effect/alien) in N.contents)
		add_overlay(weedImageCache[WEED_SOUTH_EDGING])
	if(istype(S, /turf/simulated/floor) && !locate(/obj/effect/alien) in S.contents)
		add_overlay(weedImageCache[WEED_NORTH_EDGING])
	if(istype(E, /turf/simulated/floor) && !locate(/obj/effect/alien) in E.contents)
		add_overlay(weedImageCache[WEED_WEST_EDGING])
	if(istype(W, /turf/simulated/floor) && !locate(/obj/effect/alien) in W.contents)
		add_overlay(weedImageCache[WEED_EAST_EDGING])

/obj/effect/alien/weeds/proc/fullUpdateWeedOverlays()
	for (var/obj/effect/alien/weeds/W in range(1,src))
		W.updateWeedOverlays()

	return

// NB: This is not actually called by a processing subsystem, it's called by the node processing
/obj/effect/alien/weeds/process()
	set background = 1
	var/turf/U = get_turf(src)

	if(isspace(U))
		qdel(src)
		return

	if(!linked_node)
		return

	if(get_dist(linked_node, src) > linked_node.node_range)
		return

	for(var/dirn in GLOB.cardinal)
		var/turf/T1 = get_turf(src)
		var/turf/T2 = get_step(src, dirn)

		if(!istype(T2) || locate(/obj/effect/alien/weeds) in T2 || istype(T2.loc, /area/arrival) || isspace(T2))
			continue

		if(T1.c_airblock(T2) == BLOCKED)
			continue

		new /obj/effect/alien/weeds(T2, linked_node) // CHOMPedit: No coloration.

/obj/effect/alien/weeds/node/process()
	set background = 1
	. = ..()

	var/list/nearby_weeds = list()
	for(var/obj/effect/alien/weeds/W in orange(node_range, src))
		nearby_weeds |= W

	for(var/obj/effect/alien/weeds/W as anything in nearby_weeds)

		if(!W.linked_node)
			W.linked_node = src

//		W.color = W.linked_node.set_color // CHOMPedit: No coloration.

		if(prob(max(10, 60 - (5 * nearby_weeds.len))))
			W.process()

/obj/effect/alien/weeds/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if (prob(50))
				qdel(src)
		if(3.0)
			if (prob(5))
				qdel(src)
	return

/obj/effect/alien/weeds/attackby(var/obj/item/W, var/mob/user)
	user.setClickCooldown(user.get_attack_speed(W))
	if(LAZYLEN(W.attack_verb))
		visible_message(span_danger("\The [src] have been [pick(W.attack_verb)] with \the [W][(user ? " by [user]." : ".")]"))
	else
		visible_message(span_danger("\The [src] have been attacked with \the [W][(user ? " by [user]." : ".")]"))

	var/damage = W.force / 4.0

	if(W.has_tool_quality(TOOL_WELDER))
		var/obj/item/weldingtool/WT = W.get_welder()

		if(WT.remove_fuel(0, user))
			damage = 15
			playsound(src, 'sound/items/Welder.ogg', 100, 1)

	health -= damage
	healthcheck()

/obj/effect/alien/weeds/attack_generic(var/mob/user, var/damage, var/attack_verb)
	visible_message(span_danger("[user] [attack_verb] the [src]!"))
	user.do_attack_animation(src)
	health -= damage
	healthcheck()
	return

/obj/effect/alien/weeds/take_damage(var/damage)
	health -= damage
	healthcheck()
	return

/obj/effect/alien/weeds/proc/healthcheck()
	if(health <= 0)
		qdel(src)


/obj/effect/alien/weeds/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature > 300 + T0C)
		health -= 5
		healthcheck()

// CHOMPedit start - Smaller-ranged nodes for Xenomorph Hybrids, node/weed deletion.
/obj/effect/alien/weeds/attack_hand(mob/user as mob)
	usr.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	if (HULK in usr.mutations)
		visible_message(span_warning("[usr] destroys the [name]!"))
		health = 0
	else

		// Aliens can get straight through these.
		if(istype(usr,/mob/living/carbon))
			if(user.a_intent == I_HURT)
				var/mob/living/carbon/M = usr
				if(locate(/obj/item/organ/internal/xenos/hivenode) in M.internal_organs)
					visible_message (span_warning("[usr] strokes the [name] and it melts away!"), 1)
					health = 0
					healthcheck()
					return
	healthcheck()
	return

/obj/effect/alien/weeds/node/weak
	light_range = 2
	node_range = 1
// CHOMPedit end.

#undef NODERANGE
#undef WEED_NORTH_EDGING
#undef WEED_SOUTH_EDGING
#undef WEED_EAST_EDGING
#undef WEED_WEST_EDGING
#undef WEED_NODE_GLOW
#undef WEED_NODE_BASE

/*
 * Acid
 */
/obj/effect/alien/acid
	name = "acid"
	desc = "Burbling corrossive stuff. I wouldn't want to touch it."
	icon_state = "acid"

	density = FALSE
	opacity = 0
	anchored = TRUE

	var/atom/target
	var/ticks = 0
	var/target_strength = 0

/obj/effect/alien/acid/Initialize(mapload, target)
	. = ..()
	src.target = target

	if(isturf(target)) // Turf take twice as long to take down.
		target_strength = 8
	else
		target_strength = 4
	tick()

/obj/effect/alien/acid/proc/tick()
	if(!target)
		qdel(src)

	ticks += 1
	if(ticks >= target_strength)

		for(var/mob/O in hearers(src, null))
			O.show_message(span_alium("[src.target] collapses under its own weight into a puddle of goop and undigested debris!"), 1)

		if(iswall(target))
			var/turf/simulated/wall/W = target
			W.dismantle_wall()
		else if(isfloor(target))
			var/turf/simulated/floor/T = target
			T.ex_act(1)
		else if(isobj(target))
			qdel(target)
		qdel(src)
		return

	switch(target_strength - ticks)
		if(6)
			visible_message(span_alium("[src.target] is holding up against the acid!"))
		if(4)
			visible_message(span_alium("[src.target]\s structure is being melted by the acid!"))
		if(2)
			visible_message(span_alium("[src.target] is struggling to withstand the acid!"))
		if(0 to 1)
			visible_message(span_alium("[src.target] begins to crumble under the acid!"))
	spawn(rand(150, 200)) tick()

//Xenomorph Effect egg removed, replaced with Structure Egg.
