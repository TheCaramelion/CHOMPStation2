/obj/item/assembly/gluetrap
	name = "glue trap"
	desc = "A devious sticky trap for catching small critters."
	icon = 'icons/obj/assemblies/new_assemblies.dmi'
	icon_state = "mousetrap"
	matter = list(MAT_PLASTIC = 100)
	buckle_lying = TRUE
	max_buckled_mobs = 3
	var/armed = FALSE

/obj/item/assembly/gluetrap/update_icon()
	if(armed)
		icon_state = "mousetraparmed"
	else
		icon_state = "mousetrap"
	if(holder)
		holder.update_icon()

/obj/item/assembly/gluetrap/attack_self(var/mob/living/user)
	if(!armed)
		to_chat(user, span_notice("You arm [src]."))

	armed = !armed
	can_buckle = !can_buckle
	update_icon()
	playsound(user, 'sound/weapons/handcuffs.ogg', 30, 1, -3)

/obj/item/assembly/gluetrap/Crossed(var/atom/movable/AM)
	if(AM.is_incorporeal())
		return
	if(armed)
		if(ismob(AM))
			var/mob/sticked = AM
			if(ismouse(sticked) || (sticked.size_multiplier >= RESIZE_TINY - 1 && sticked.size_multiplier <= RESIZE_SMALL) && !sticked.buckled)
				to_chat(sticked, span_danger("You get stuck to the [src]!"))
				playsound(src, 'sound/rakshasa/Decay2.ogg', 100, 1)
				buckle_mob(sticked)
				sticked.stop_pulling()
				sticked.Stun(5)
				layer = MOB_LAYER - 0.2
			else if(sticked.size_multiplier <= RESIZE_A_NORMALSMALL)
				sticked.Weaken(2)
				to_chat(sticked, span_danger("You get stuck to the [src] momentarily!"))
	..()

/obj/item/assembly/gluetrap/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	user.setClickCooldown(user.get_attack_speed())
	to_chat(user, span_notice("You tug and strain against the sticky substance..."))

	if(do_after(user, 20 SECONDS, src, incapacitation_flags = INCAPACITATION_DEFAULT & ~(INCAPACITATION_RESTRAINED | INCAPACITATION_BUCKLED_FULLY)))
		if(!has_buckled_mobs())
			return
		to_chat(user, span_notice("You tug free of the tacky, rubber strands!"))
		unbuckle_mob(buckled_mob)

/obj/item/assembly/gluetrap/attack_hand(var/mob/living/user)
	if(buckled_mobs)
		var/target = tgui_input_list(user, "Who would you like to peel free?", "Peel", buckled_mobs)
		if(target && do_after(user, 5 SECONDS))
			user.attempt_to_scoop(target)
		return
	..()
