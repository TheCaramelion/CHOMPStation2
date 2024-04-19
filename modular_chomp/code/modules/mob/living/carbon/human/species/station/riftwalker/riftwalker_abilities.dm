/datum/power/riftwalker
/datum/power/riftwalker/bloodcrawl
	name = "Bloodcrawl"
	desc = "Shift out of reality using blood as your conduit"
	verbpath = /mob/living/carbon/human/proc/bloodcrawl

/datum/power/riftwalker/blood_burst
	name = "Blood Burst"
	desc = "Spawn bloody remains from your past hunts."
	verbpath = /mob/living/carbon/human/proc/blood_burst

/datum/power/riftwalker/sizechange
	name = "Shrink/Grow Prey"
	desc = "Shrink/Grow someone nearby using redspace power"
	verbpath = /mob/living/carbon/human/proc/sizechange

/datum/power/riftwalker/demon_bite
	name = "Poisonous Bite"
	desc = "Inject poison into your grabbed prey."
	verbpath = /mob/living/carbon/human/proc/demon_bite

/datum/power/riftwalker/choose_prey_size
	name = "Choose Prey Size"
	desc = "Choose your prey size"
	verbpath = /mob/living/carbon/human/proc/choose_prey_size

/mob/living/carbon/human/proc/riftwalker_abilty_check()
	var/datum/species/riftwalker/RIFT = species
	if(!istype(RIFT))
		to_chat(src, "<span class='warning'>Only a riftwalker can use that!</span>")
		return FALSE

// BLOODCRAWLING

// Visual stuff
/obj/effect/temp_visual/riftwalker
	randomdir = FALSE
	duration = 30
	icon = 'icons/mob/demon_vr.dmi'

/obj/effect/temp_visual/riftwalker/phasein
	icon_state = "phasein"

/obj/effect/temp_visual/riftwalker/phaseout
	icon_state = "phaseout"

// Actual bloodcrawl
/mob/living/carbon/human/proc/bloodcrawl()
	set name = "Bloodcrawl"
	set desc = "Shift out of reality using blood as your conduit"
	set category = "Abilities.Riftwalker"

	var/turf/T = get_turf(src)
	var/datum/species/riftwalker/RIFT = species

	if(RIFT.doing_phase)
		to_chat(src, "<span class='warning'>You are already trying to phase!</span>")
		return FALSE

	else if(!(locate(/obj/effect/decal/cleanable/blood) in src.loc))
		to_chat(src,"<span class='warning'>You need blood to shift between realities!</span>")
		return FALSE

	else if(!T.CanPass(src, T) || loc != T)
		to_chat(src,"<span class='warning'>You can't use that here!</span>")
		return FALSE

	playsound(src, 'sound/misc/demonlaugh.ogg', 50, 1)

	RIFT.doing_phase = TRUE

	if(ability_flags & AB_PHASE_SHIFTED)
		bloodcrawl_in(T)
	else
		bloodcrawl_out(T)
	RIFT.doing_phase = FALSE

/mob/living/carbon/human/proc/bloodcrawl_in(var/turf/T)
	if(ability_flags & AB_PHASE_SHIFTED)

		// pre-change
		forceMove(T)
		var/original_canmove = canmove
		SetStunned(0)
		SetWeakened(0)
		if(buckled)
			buckled.unbuckle_mob()
		if(pulledby)
			pulledby.stop_pulling()
		stop_pulling()
		canmove = FALSE

		// change
		ability_flags &= ~AB_PHASE_SHIFTED
		ability_flags |= AB_PHASE_SHIFTING
		mouse_opacity = 1
		name = get_visible_name()
		for(var/obj/belly/B as anything in vore_organs)
			B.escapable = initial(B.escapable)

		invisibility = initial(invisibility)
		see_invisible = initial(see_invisible)
		see_invisible_default = initial(see_invisible_default) // CHOMPEdit - Allow seeing phased entities while phased.
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		force_max_speed = initial(force_max_speed)
		can_pull_size = initial(can_pull_size)
		can_pull_mobs = initial(can_pull_mobs)
		hovering = initial(hovering)
		update_icon()

		// Cosmetics
		new /obj/effect/temp_visual/riftwalker/phasein(src.loc)
		alpha = 0
		custom_emote(1,"phases in!")

		// Phase-in vore
		if(can_be_drop_pred || can_be_drop_prey) //Toggleable in vore panel
			var/list/potentials = living_mobs(0)
			if(potentials.len)
				var/mob/living/target = pick(potentials)
				if(can_be_drop_pred && istype(target) && target.devourable && target.can_be_drop_prey && target.phase_vore && vore_selected && phase_vore)
					target.forceMove(vore_selected)
					to_chat(target, "<span class='vwarning'>\The [src] phases in around you, [vore_selected.vore_verb]ing you into their [vore_selected.name]!</span>")
					to_chat(src, "<span class='vwarning'>You phase around [target], [vore_selected.vore_verb]ing them into your [vore_selected.name]!</span>")
				else if(can_be_drop_prey && istype(target) && devourable && target.can_be_drop_pred && target.phase_vore && target.vore_selected && phase_vore)
					forceMove(target.vore_selected)
					to_chat(target, "<span class='vwarning'>\The [src] phases into you, [target.vore_selected.vore_verb]ing them into your [target.vore_selected.name]!</span>")
					to_chat(src, "<span class='vwarning'>You phase into [target], having them [target.vore_selected.vore_verb] you into their [target.vore_selected.name]!</span>")

		sleep(30)
		canmove = original_canmove
		alpha = initial(alpha)

		ability_flags &= ~AB_PHASE_SHIFTING

/mob/living/carbon/human/proc/bloodcrawl_out(var/turf/T)
	if(!(ability_flags & AB_PHASE_SHIFTED))
		// pre-change
		forceMove(T)
		var/original_canmove = canmove
		SetStunned(0)
		SetWeakened(0)
		if(buckled)
			buckled.unbuckle_mob()
		if(pulledby)
			pulledby.stop_pulling()
		stop_pulling()
		canmove = FALSE

		// change
		ability_flags |= AB_PHASE_SHIFTED
		ability_flags |= AB_PHASE_SHIFTING
		mouse_opacity = 0
		custom_emote(1,"phases out!")
		name = get_visible_name()

		if(l_hand)
			unEquip(l_hand)
		if(r_hand)
			unEquip(r_hand)
		if(back)
			unEquip(back)

		can_pull_size = 0
		can_pull_mobs = MOB_PULL_NONE
		hovering = TRUE

		for(var/obj/belly/B as anything in vore_organs)
			B.escapable = FALSE

		new /obj/effect/temp_visual/riftwalker/phaseout(src.loc)
		alpha = 0
		sleep(30)
		invisibility = INVISIBILITY_LEVEL_TWO
		update_icon()
		alpha = 127

		canmove = original_canmove
		incorporeal_move = TRUE
		density = FALSE
		force_max_speed = TRUE
		ability_flags &= ~AB_PHASE_SHIFTING

/mob/living/carbon/human/proc/blood_burst()
	set name = "Blood burst"
	set desc = "Spawn bloody remains from your past hunts."
	set category = "Abilities.Riftwalker"

	var/turf/T = get_turf(src)
	var/datum/species/riftwalker/RIFT = species

	if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src,"<span class='warning'>You must be in the physical world to create blood!</span>")
		return FALSE

	if(world.time - RIFT.blood_spawn < 1500)
		to_chat(src,"<span class='warning'>You can't create blood so soon! You need to wait [round(((RIFT.blood_spawn+1500)-world.time)/10)] second\s!</span>")
		return FALSE


	new /obj/effect/gibspawner/generic(T)

	playsound(src.loc, 'sound/effects/blobattack.ogg', 50, 1)

	RIFT.blood_spawn = world.time

	return

/mob/living/carbon/human/proc/sizechange()
	set name = "Shrink/Grow Prey"
	set category = "Abilities.Riftwalker"
	set desc = "Shrink/Grow someone nearby using redspace power"
	set popup_menu = FALSE

	var/obj/item/weapon/grab/G = src.get_active_hand()
	var/datum/species/riftwalker/RIFT = species

	if(!istype(G))
		to_chat(src, "<span class='warning'>You must be grabbing a creature in your active hand to affect them.</span>")
		return
	var/mob/living/carbon/human/T = G.affecting
	if(!istype(T))
		to_chat(src, "<span class='warning'>\The [T] is not able to be affected.</span>")
		return

	if(G.state != GRAB_NECK)
		to_chat(src, "<span class='warning'>You must have a tighter grip to affect this creature.</span>")
		return

	if(!checkClickCooldown() || incapacitated(INCAPACITATION_ALL))
		return

	T.resize(RIFT.prey_size)
	visible_message("<span class='warning'>[src] shrinks [T]!</span>","<span class='notice'>You shrink [T].</span>")

/mob/living/carbon/human/proc/demon_bite()
	set name = "Poisonous Bite"
	set category = "Abilities.Riftwalker"
	set desc = "Inject poison into your grabbed prey."

	var/obj/item/weapon/grab/G = src.get_active_hand()
	var/datum/species/riftwalker/RIFT = species

	if(!istype(G))
		to_chat(src, "<span class='warning'>You must be grabbing a creature in your active hand to affect them.</span>")
		return
	var/mob/living/carbon/human/T = G.affecting
	if(!istype(T))
		to_chat(src, "<span class='warning'>\The [T] is not able to be affected.</span>")
		return

	if(G.state != GRAB_NECK)
		to_chat(src, "<span class='warning'>You must have a tighter grip to affect this creature.</span>")
		return

	if(!checkClickCooldown() || incapacitated(INCAPACITATION_ALL))
		return

	T.reagents.add_reagent(RIFT.poison_type, RIFT.poison_per_bite)
	visible_message("<span class='warning'>[src] bites [T]!</span>","<span class='notice'>You bite [T].</span>")

/mob/living/carbon/human/proc/choose_prey_size()
	set name = "Choose Prey Size"
	set category = "Abilities.Riftwalker"
	set desc = "Choose your prey size"

	var/datum/species/riftwalker/RIFT = species

	var/size_select = tgui_input_number(usr, "Put the desired size (25-200%), (1-600%) in dormitory areas.", "Set Size", size_set_to * 100, 600, 1)
	if(!size_select)
		return
	RIFT.prey_size = clamp((size_select/100), RESIZE_MINIMUM_DORMS, RESIZE_MAXIMUM_DORMS)
	balloon_alert(usr, "Prey size set to [size_select]")
	if(RIFT.prey_size < RESIZE_MINIMUM || RIFT.prey_size > RESIZE_MAXIMUM)
		to_chat(usr, "<span class='notice'>Note: Resizing limited to 25-200% automatically while outside dormatory areas.</span>")
