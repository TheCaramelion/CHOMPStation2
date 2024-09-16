/datum/power/riftwalker
/datum/modifier/riftwalker_phase
	name = "Riftwalker Phasing"
	evasion = 100
/datum/modifier/riftwalker_phase_vision
	name = "Riftwalker Phase Vision"
	vision_flags = SEE_THRU

/mob/living/carbon/human/proc/riftwalker_ability_check()
	var/datum/species/riftwalker/RIFT = species

	if(!istype(RIFT))
		to_chat(src, "<span class='warning'>Only a riftwalker can use that!</span>")
		return FALSE

	if(cloaked)
		to_chat(src, "<span class='warning'>We can't do this while cloaked!</span>")
		return FALSE

	if(RIFT.state & RW_WEAKENED)
		to_chat(src, "<span class='warning'>A strange substance is keeping us here!</span>")
		return FALSE

	if(RIFT.state & RW_PETRIFIED)
		to_chat(src, "<span class='warning'>We can't do that in this state!</span>")
		return FALSE

	return TRUE


/mob/living/carbon/human/proc/rift_consume_blood(var/quantity)
	var/datum/species/riftwalker/RIFT = species

	if(RIFT.blood_infinite)
		return FALSE

	if(RIFT.blood_resource+quantity >= 0)
		riftwalker_adjust_blood(quantity)
		return FALSE
	else
		to_chat(src, "<span class='warning'>We don't have enough power to do this</span>")
		return TRUE

/mob/living/carbon/human/proc/riftwalker_adjust_blood(var/amount)
	var/datum/species/riftwalker/RIFT = species

	if(!istype(RIFT))
		return FALSE

	RIFT.blood_resource = clamp(RIFT.blood_resource+amount, RIFT.blood_min, RIFT.blood_max)

	return TRUE

// Sacrifice

/datum/power/riftwalker/sacrifice
	name = "Sacrifice"
	desc = "Sacrifice the living to gain power"
	verbpath = /mob/living/carbon/human/proc/sacrifice
	ability_icon_state = "wiz_disint_old"

/mob/living/carbon/human/proc/sacrifice()
	set name = "Sacrifice"
	set desc = "Sacrifice the livig to gain power"
	set category = "Abilities.Riftwalker"

	var/obj/item/weapon/grab/G = src.get_active_hand()
	var/datum/species/riftwalker/RIFT = species
	var/blood_gained = 50

	if(!(riftwalker_ability_check()))
		return

	if(!istype(G) && !istype(G, /mob/living/))
		to_chat(src, SPAN_WARNING("You must be grabbing a creature in your active hand to affect them."))
		return
	var/mob/living/T = G.affecting

	if(G.state != GRAB_NECK)
		to_chat(src, SPAN_WARNING("You must have a tighter grip to affect this creature."))
		return

	if(world.time - RIFT.sacrifice < 90 SECONDS)
		to_chat(src,SPAN_WARNING("You can't make a sacrifice so soon! You need to wait [round(((RIFT.sacrifice+90 SECONDS)-world.time)/10)] second\s!"))
		return

	if(do_after(src, 5 SECONDS, target = src, max_distance = 2))
		riftwalker_adjust_blood(blood_gained)
		T.gib()

// Visual stuff
/obj/effect/temp_visual/riftwalker
	randomdir = FALSE
	duration = 30
	icon = 'modular_chomp/icons/mob/species/riftwalker/riftwalker.dmi'

/obj/effect/temp_visual/riftwalker/phasein
	icon_state = "phasein"

/obj/effect/temp_visual/riftwalker/phaseout
	icon_state = "phaseout"

/obj/effect/temp_visual/riftwalker/bloodin
	icon_state = "bloodin"

/obj/effect/temp_visual/riftwalker/bloodout
	icon_state = "bloodout"

// Blood Jaunt
/datum/power/riftwalker/bloodjaunt
	name = "Bloodjaunt"
	desc = "Temporarily phase out of reality"
	verbpath = /mob/living/carbon/human/proc/bloodjaunt
	ability_icon_state = "rifwalker_jaunt"

/mob/living/carbon/human/proc/bloodjaunt()
	set name = "Blood Jaunt"
	set desc = "Temporarily phase out of reality"
	set category = "Abilities.Riftwalker"

	if((get_area(src).flags & PHASE_SHIELDED))
		to_chat(src, SPAN_WARNING("This area is preventing you from phasing!"))
		return FALSE

	if(ability_flags & AB_PHASE_SHIFTING)
		return FALSE

	var/datum/species/riftwalker/RIFT = species

	if(!riftwalker_ability_check())
		return FALSE

	else if(RIFT.state & RW_BLOODCRAWLING)
		to_chat(src, SPAN_WARNING("You are already trying to phase!"))
		return FALSE

	if(RIFT.state & RW_NAME_REVEALED)
		to_chat(src, SPAN_WARNING("Revealing our true name has left us weak... We need time to recover."))
		return FALSE

	riftwalker_bloodjaunt_out(src.loc)

	spawn(3 SECONDS)
		riftwalker_bloodjaunt_in(src.loc)
		Stun(1)

/mob/living/carbon/human/proc/riftwalker_bloodjaunt_in(var/turf/T)

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
		see_invisible_default = initial(see_invisible_default)
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		force_max_speed = initial(force_max_speed)
		can_pull_size = initial(can_pull_size)
		can_pull_mobs = initial(can_pull_mobs)
		hovering = initial(hovering)
		update_icon()

		// Cosmetics
		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/bloodin(src.loc)
		phaseanim.pixel_y = (src.size_multiplier - 1) * 16 // Pixel shift for the animation placement
		phaseanim.adjust_scale(src.size_multiplier, src.size_multiplier)
		alpha = 0

		if(can_be_drop_pred || can_be_drop_prey) //Toggleable in vore panel
			var/list/potentials = living_mobs(0)
			if(potentials.len)
				var/mob/living/target = pick(potentials)
				if(can_be_drop_pred && istype(target) && target.devourable && target.can_be_drop_prey && target.phase_vore && vore_selected && phase_vore)
					target.forceMove(vore_selected)
					to_chat(target, span_vwarning("\The [src] phases in around you, [vore_selected.vore_verb]ing you into their [vore_selected.name]!"))
					to_chat(src, span_vwarning("You phase around [target], [vore_selected.vore_verb]ing them into your [vore_selected.name]!"))
				else if(can_be_drop_prey && istype(target) && devourable && target.can_be_drop_pred && target.phase_vore && target.vore_selected && phase_vore)
					forceMove(target.vore_selected)
					to_chat(target, span_vwarning("\The [src] phases into you, [target.vore_selected.vore_verb]ing them into your [target.vore_selected.name]!"))
					to_chat(src, span_vwarning("You phase into [target], having them [target.vore_selected.vore_verb] you into their [target.vore_selected.name]!"))

		sleep(2 SECONDS)
		canmove = original_canmove
		alpha = initial(alpha)
		remove_modifiers_of_type(/datum/modifier/riftwalker_phase_vision)
		remove_modifiers_of_type(/datum/modifier/riftwalker_phase)

		ability_flags &= ~AB_PHASE_SHIFTING

/mob/living/carbon/human/proc/riftwalker_bloodjaunt_out(var/turf/T)

	if(!(ability_flags & AB_PHASE_SHIFTED))
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

		ability_flags |= AB_PHASE_SHIFTED
		ability_flags |= AB_PHASE_SHIFTING
		mouse_opacity = 0
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

		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/bloodout(src.loc)
		phaseanim.dir = dir
		alpha = 0
		add_modifier(/datum/modifier/shadekin_phase_vision)
		add_modifier(/datum/modifier/shadekin_phase) //CHOMPEdit - Shadekin probably shouldn't be hit while phasing
		sleep(5)
		invisibility = INVISIBILITY_SHADEKIN
		see_invisible = INVISIBILITY_SHADEKIN
		see_invisible_default = INVISIBILITY_SHADEKIN // CHOMPEdit - Allow seeing phased entities while phased.
		//cut_overlays()
		update_icon()
		alpha = 127

		canmove = original_canmove
		incorporeal_move = TRUE
		density = FALSE
		force_max_speed = TRUE
		ability_flags &= ~AB_PHASE_SHIFTING

// Bloodcrawl
/datum/power/riftwalker/bloodcrawl
	name = "Bloodcrawl (100)"
	desc = "Shift out of reality using blood as your conduit"
	verbpath = /mob/living/carbon/human/proc/bloodcrawl
	ability_icon_state = "const_shift"

/mob/living/carbon/human/proc/bloodcrawl()
	set name = "Bloodcrawl (100)"
	set desc = "Shift out of reality using blood as your conduit"
	set category = "Abilities.Riftwalker"

	var/ability_cost = 50
	var/turf/T = get_turf(src)
	if(!T)
		to_chat(src, SPAN_WARNING("You can't use that here!"))
		return FALSE
	if((get_area(src).flags & PHASE_SHIELDED))
		to_chat(src, SPAN_WARNING("This area is preventing you from phasing!"))
		return FALSE

	if(ability_flags & AB_PHASE_SHIFTING)
		return FALSE

	var/datum/species/riftwalker/RIFT = species

	if(!riftwalker_ability_check())
		return FALSE
	else if(RIFT.state & RW_BLOODCRAWLING)
		to_chat(src, SPAN_WARNING("You are already trying to phase!"))
		return FALSE

	else if(riftwalker_get_blood() < ability_cost && !(ability_flags & AB_PHASE_SHIFTED))
		to_chat(src, SPAN_WARNING("Not enough blood for that ability!"))
		return FALSE

	else if(locate(/obj/effect/decal/cleanable/blood/oil) in src.loc || locate(/obj/effect/decal/cleanable/blood/gibs/robot) in src.loc)
		to_chat(src, SPAN_WARNING("You need blood to shift between realities!"))
		return FALSE

	else if(!(locate(/obj/effect/decal/cleanable/blood) in src.loc))
		to_chat(src, SPAN_WARNING("You need blood to shift between realities!"))
		return FALSE

	if(RIFT.state & RW_NAME_REVEALED)
		to_chat(src, SPAN_WARNING("Revealing our true name has left us weak... We need time to recover."))
		return FALSE

	if(!T.CanPass(src, T) || loc != T)
		to_chat(src, SPAN_WARNING("You can't use that here!"))
		return FALSE

	if(!(ability_flags & AB_PHASE_SHIFTED))
		rift_consume_blood(ability_cost)
	playsound(src, 'sound/misc/demonlaugh.ogg', 50, 1)

	RIFT.state |= RW_BLOODCRAWLING
	if(ability_flags & AB_PHASE_SHIFTED)
		riftwalker_phase_in(T)
	else
		riftwalker_phase_out(T)
	RIFT.state &= ~RW_BLOODCRAWLING

/mob/living/carbon/human/proc/riftwalker_phase_in(var/turf/T)
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
		see_invisible_default = initial(see_invisible_default)
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		force_max_speed = initial(force_max_speed)
		can_pull_size = initial(can_pull_size)
		can_pull_mobs = initial(can_pull_mobs)
		hovering = initial(hovering)
		update_icon()

		// Cosmetics
		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/phasein(src.loc)
		phaseanim.pixel_y = (src.size_multiplier - 1) * 16 // Pixel shift for the animation placement
		phaseanim.adjust_scale(src.size_multiplier, src.size_multiplier)
		alpha = 0
		balloon_alert_visible("Phases in!")

		// Phase-in vore
		/* As a note, Riftwalkers have a longer animation so they
			can catch prey before the portal just goes away.
			And also because making the portal and stepping out of it
			with a full belly is pretty neat :)
		*/
		if(can_be_drop_pred || can_be_drop_prey) //Toggleable in vore panel
			var/list/potentials = living_mobs(0)
			if(potentials.len)
				var/mob/living/target = pick(potentials)
				if(can_be_drop_pred && istype(target) && target.devourable && target.can_be_drop_prey && target.phase_vore && vore_selected && phase_vore)
					target.forceMove(vore_selected)
					to_chat(target, span_vwarning("\The [src] phases in around you, [vore_selected.vore_verb]ing you into their [vore_selected.name]!"))
					to_chat(src, span_vwarning("You phase around [target], [vore_selected.vore_verb]ing them into your [vore_selected.name]!"))
				else if(can_be_drop_prey && istype(target) && devourable && target.can_be_drop_pred && target.phase_vore && target.vore_selected && phase_vore)
					forceMove(target.vore_selected)
					to_chat(target, span_vwarning("\The [src] phases into you, [target.vore_selected.vore_verb]ing them into your [target.vore_selected.name]!"))
					to_chat(src, span_warning("You phase into [target], having them [target.vore_selected.vore_verb] you into their [target.vore_selected.name]!"))

		sleep(3 SECONDS)
		Stun(1)
		canmove = original_canmove
		alpha = initial(alpha)
		remove_modifiers_of_type(/datum/modifier/riftwalker_phase_vision)
		remove_modifiers_of_type(/datum/modifier/riftwalker_phase)

		ability_flags &= ~AB_PHASE_SHIFTING

/mob/living/carbon/human/proc/riftwalker_phase_out(var/turf/T)
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
		balloon_alert_visible("Phases out!")
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

		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/phaseout(src.loc)
		phaseanim.pixel_y = (src.size_multiplier - 1) * 16 // Pixel shift for the animation placement
		phaseanim.adjust_scale(src.size_multiplier, src.size_multiplier)
		alpha = 0
		add_modifier(/datum/modifier/riftwalker_phase_vision)
		add_modifier(/datum/modifier/riftwalker_phase)
		sleep(3 SECONDS)
		invisibility = INVISIBILITY_SHADEKIN
		see_invisible = INVISIBILITY_SHADEKIN
		see_invisible_default = INVISIBILITY_SHADEKIN
		update_icon()
		alpha = 127

		canmove = original_canmove
		incorporeal_move = TRUE
		density = FALSE
		force_max_speed = TRUE
		ability_flags &= ~AB_PHASE_SHIFTING

// Bloodburst

/mob/living/carbon/human/proc/blood_burst()
	set name = "Blood burst (10)"
	set desc = "Spawn bloody remains from your past hunts."
	set category = "Abilities.Riftwalker"

	var/turf/T = get_turf(src)
	var/datum/species/riftwalker/RIFT = species

	if(!(riftwalker_ability_check()))
		return

	if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, SPAN_WARNING("You must be in the physical world to create blood!"))
		return FALSE

	if(world.time - RIFT.blood_spawn < 150 SECONDS)
		to_chat(src, SPAN_WARNING("You can't create blood so soon! You need to wait [round(((RIFT.blood_spawn+150 SECONDS)-world.time)/10)] second\s!"))
		return FALSE

	if(rift_consume_blood(-10))
		return

	new /obj/effect/gibspawner/generic(T)

	playsound(src.loc, 'sound/effects/blobattack.ogg', 50, 1)

	RIFT.blood_spawn = world.time

// Size change

/mob/living/carbon/human/proc/sizechange()
	set name = "Shrink/Grow Prey"
	set category = "Abilities.Riftwalker"
	set desc = "Shrink/Grow someone nearby using redspace power"

	var/obj/item/weapon/grab/G = src.get_active_hand()
	var/datum/species/riftwalker/RIFT = species

	if(!(riftwalker_ability_check()))
		return

	if(!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a creature in your active hand to affect them."))
		return
	var/mob/living/carbon/human/T = G.affecting
	if(!istype(T))
		to_chat(src, SPAN_WARNING("\The [T] is not able to be affected."))
		return

	if(G.state != GRAB_NECK)
		to_chat(src, SPAN_WARNING("You must have a tighter grip to affect this creature."))
		return

	if(!checkClickCooldown() || incapacitated(INCAPACITATION_ALL))
		return

	playsound(src.loc, 'sound/effects/EMPulse.ogg', 50, 1)

	T.resize(RIFT.prey_size)
	visible_message(SPAN_WARNING("[src] shrinks [T]!"), SPAN_NOTICE("You shrink [T]."))

/mob/living/carbon/human/proc/choose_prey_size()
	set name = "Choose Prey Size"
	set category = "Abilities.Riftwalker"
	set desc = "Choose your prey size"

	var/datum/species/riftwalker/RIFT = species

	var/size_select = tgui_input_number(usr, "Put the desired size (25-200%), (1-600%) in dormitory areas.", "Set Size", RIFT.prey_size * 100, 600, 1)
	if(!size_select)
		return

	RIFT.prey_size = clamp((size_select/100), RESIZE_MINIMUM_DORMS, RESIZE_MAXIMUM_DORMS)
	balloon_alert(usr, "Prey size set to [size_select]")
	if(RIFT.prey_size < RESIZE_MINIMUM || RIFT.prey_size > RESIZE_MAXIMUM)
		to_chat(usr, SPAN_NOTICE("Note: Resizing limited to 25-200% automatically while outside dormatory areas."))

// Demon Bite

/mob/living/carbon/human/proc/demon_bite()
	set name = "Poisonous Bite (10)"
	set category = "Abilities.Riftwalker"
	set desc = "Inject poison into your grabbed prey."

	var/obj/item/weapon/grab/G = src.get_active_hand()
	var/datum/species/riftwalker/RIFT = species

	if(!(riftwalker_ability_check()))
		return

	if(!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a creature in your active hand to affect them."))
		return
	var/mob/living/carbon/human/T = G.affecting

	if(!istype(T) || T.isSynthetic())
		to_chat(src, SPAN_WARNING("\The [T] is not able to be bitten."))
		return

	if(G.state != GRAB_NECK)
		to_chat(src, SPAN_WARNING("You must have a tighter grip to affect this creature."))
		return

	if(!checkClickCooldown() || incapacitated(INCAPACITATION_ALL))
		return

	if(rift_consume_blood(-10))
		return

	if(do_after(usr, 1.5 SECONDS, target = usr))
		T.bloodstr.add_reagent(RIFT.poison, RIFT.poison_per_bite)
		visible_message(SPAN_WARNING("[src] bites [T]!"), SPAN_NOTICE("You bite [T]."))

/mob/living/carbon/human/proc/choose_poison()
	set name = "Choose Poison"
	set category = "Abilities.Riftwalker"
	set desc = "Pick your poison!"

	var/datum/species/riftwalker/RIFT = species
	var/poisons = list()

	poisons["Mindbreaker"] = "mindbreaker"
	poisons["Aphrodisiac"] = "succubi_aphrodisiac"
	poisons["Numbing"] = "numbenzyme"
	poisons["Paralyzing"] = "succubi_paralize"

	var/poison_choice = tgui_input_list(usr, "Pick your poison", "Poisons", poisons)

	if(!poison_choice)
		return

	balloon_alert(usr, "[poison_choice] selected")
	RIFT.poison = poisons[poison_choice]

// Temporal Cloak

/datum/power/riftwalker/temporal_cloak
	name = "Temporal Cloak (20)"
	desc = "Become temporarily cloaked"
	verbpath = /mob/living/carbon/human/proc/temporal_cloak
	ability_icon_state = "const_ambush"

/mob/living/carbon/human/proc/temporal_cloak()
	set name = "Temporal Cloak (20)"
	set category = "Abilities.Riftwalker"
	set desc = "Become temporarily cloaked"

	var/datum/species/riftwalker/RIFT = species

	if(!(riftwalker_ability_check()))
		return

	if(ability_flags & AB_PHASE_SHIFTED)
		balloon_alert(usr, "We can't do this while phased")
	else
		do_cloak()

		spawn(RIFT.shift_time)
			if(cloaked)
				uncloak()

/mob/living/carbon/human/proc/do_cloak()
	if(cloaked)
		uncloak()
	else
		if(!rift_consume_blood(-20))
			cloak()

// Echo Image
/datum/power/riftwalker/echo_image
	name = "Echo Image (50)"
	desc = "Create a weak copy of yourself"
	verbpath = /mob/living/carbon/human/proc/echo_image
	ability_icon_state = "const_harvest"

/mob/living/carbon/human/proc/echo_image()
	set name = "Echo Image (50)"
	set desc = "Create a weak copy of yourself"
	set category = "Abilities.Riftwalker"

	var/datum/species/riftwalker/RIFT = species

	if(!(riftwalker_ability_check()))
		return

	if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, SPAN_WARNING("You can't use that while phase shifted!"))
		return FALSE

	if(rift_consume_blood(-50))
		return

	var/client/rw_client = src.client
	var/mob/living/carbon/human/dummy/mirror = get_mannequin(rw_client)

	mirror = new(loc)
	rw_client.prefs.copy_to(mirror)

	RIFT.mirrors += mirror

	spawn(5 MINUTES)
		mirror.visible_emote("turns into ashes.")
		new /obj/effect/decal/cleanable/ash(mirror.loc)
		RIFT.mirrors -= mirror
		mirror.Destroy()

/mob/living/carbon/human/proc/echo_talk()
	set name = "Echo Talk"
	set desc = "Talk through your mirrors"
	set category = "Abilities.Riftwalker"

	var/datum/species/riftwalker/RIFT = species

	if(isemptylist(RIFT.mirrors))
		to_chat(src, SPAN_WARNING("We don't have any mirrors to talk throught</span>"))

	var/message = tgui_input_text(src, "Speak through our mirrors", "Echo Talk")

	for(var/mob/mirror in RIFT.mirrors)
		mirror.say(message)

// Bloodgate
/datum/power/riftwalker/bloodgate
	name = "Bloodgate (100)"
	desc = "Open the way to a redspace pocket"
	verbpath = /mob/living/carbon/human/proc/bloodgate
	ability_icon_state = "const_knock"

/mob/living/carbon/human/proc/bloodgate()
	set name = "Bloodgate (100)"
	set desc = "Open the way to a redspace pocket"
	set category = "Abilities.Riftwalker"

	var/template_id = "dark_portal"
	var/datum/map_template/shelter/template

	if(!(riftwalker_ability_check()))
		return

	var/datum/species/riftwalker/RIFT = species

	if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, SPAN_WARNING("You can't use that while phase shifted!"))
		return FALSE
	else if(RIFT.state & RW_BLOODGATE)
		to_chat(src, SPAN_WARNING("You have already made a portal to redspace"))

	if(rift_consume_blood(-100))
		return

	if(!template)
		template = SSmapping.shelter_templates[template_id]
		if(!template)
			throw EXCEPTION("Shelter template ([template_id]) not found!")
			return FALSE

	var/turf/deploy_location = get_turf(src)
	var/status = template.check_deploy(deploy_location)

	switch(status)
		if(SHELTER_DEPLOY_BAD_AREA)
			to_chat(src, SPAN_WARNING("A portal to redspace won't work on this area"))

		if(SHELTER_DEPLOY_BAD_TURFS, SHELTER_DEPLOY_ANCHORED_OBJECTS)
			var/width = template.width
			var/height = template.height
			to_chat(src, SPAN_WARNING("There is not enough open area for a tunnel to redspace to form! You need to clear a [width]x[height] area!"))

	if(status != SHELTER_DEPLOY_ALLOWED)
		return FALSE

	var/turf/T = deploy_location
	var/datum/effect/effect/system/smoke_spread/smoke = new /datum/effect/effect/system/smoke_spread()
	smoke.attach(T)
	smoke.set_up(10, 0, T)
	smoke.start()

	src.visible_message(SPAN_NOTICE("[src] begins condensating the nearby corruption around themselves."))
	if(do_after(src, 600))
		src.visible_message(SPAN_NOTICE("[src] finishes condensating the nearby corruption around themselves, creating a portal."))

		log_and_message_admins("[key_name_admin(src)] created a portal to redspace at [get_area(T)]")
		template.annihilate_plants(deploy_location)
		template.load(deploy_location, centered = TRUE)
		template.update_lighting(deploy_location)
		RIFT.state |= RW_BLOODGATE
		return TRUE
	else
		return FALSE

// Possesion

/datum/power/riftwalker/possesion
	name = "Possesion"
	desc = "Posses your target and take their appearance"
	verbpath = /mob/living/carbon/human/proc/possesion
	ability_icon_state = "ling_transform"

/mob/living/carbon/human/proc/possesion()
	set name = "Posses"
	set category = "Abilities.Riftwalker"
	set desc = "Posses your prey's body"

	var/obj/item/weapon/grab/G = src.get_active_hand()

	if(!(riftwalker_ability_check()))
		return

	if(!istype(G))
		to_chat(src, SPAN_WARNING("You must be grabbing a creature in your active hand to affect them."))
		return
	var/mob/living/carbon/human/M = G.affecting

	if(M.stat == DEAD)
		to_chat(src, SPAN_WARNING("\The [M]'s blood doesn't flow, we can't posses this creature."))
		return

	if(M.isSynthetic())
		to_chat(src, SPAN_WARNING("\The [M] is a bloodless creature. We can't posses them."))
		return

	if(tgui_alert(src, "You selected [M] to attempt to posses. Are you sure?", "Posses Prey",list("No","Yes")) != "Yes")
		return

	log_admin("[key_name_admin(src)] offered posses on [M] ([M.ckey]).")
	to_chat(src, "<span class='warning'>Attempting to possess \the [M]'s body...</span>")

	if(M.ckey)
		if(tgui_alert(M, "\The [src] has elected to posses you. Is this something you will allow to happen?", "Allow Possesing",list("No","Yes")) != "Yes")
			to_chat(src, SPAN_WARNING("\The [M] has declined your possessing attempt."))
			return

		if(tgui_alert(M, "Are you sure? This might be difficult to come back from.", "Allow Possesing",list("No","Yes")) != "Yes")
			to_chat(src, SPAN_WARNING("\The [M] has declined your possessing attempt."))
			return

	var/mob/living/dominated_brain/db = new /mob/living/dominated_brain(M, src, M.name, M)
	var/datum/mind/user_mind = src.mind
	var/datum/mind/victim_mind = M.mind
	var/datum/species/old_species = M.species

	remove_verb(db,/mob/living/dominated_brain/proc/resist_control)

	db.ckey = db.prey_ckey

	log_admin("[db] ([db.ckey]) has agreed to [src]'s possesion, and no longer occupies their original body.")

	var/datum/species/riftwalker/RIFT = species
	var/datum/species/riftwalker/new_rift = RIFT.produceCopy(M.dna.species_traits, M)

	new_rift.hud = old_species.hud
	new_rift.hud_type = old_species.hud_type

	new_rift.species_holder = old_species
	new_rift.name = old_species.name
	new_rift.add_riftwalker_abilities(M)
	new_rift.blood_resource = RIFT.blood_resource

	add_verb(M,/mob/living/carbon/human/proc/riftwalker_release)

	if(new_rift.real_body)
		new_rift.real_body = RIFT.real_body
		qdel(RIFT.real_body)
	else
		new_rift.real_body = new /mob/living/carbon/human

	gib()
	if(victim_mind)
		victim_mind.transfer_to(db)
	user_mind.transfer_to(M)

/mob/living/carbon/human/proc/riftwalker_release()
	set name = "Release vessel"
	set category = "Abilities.Riftwalker"
	set desc = "Release your prey's body"

	var/datum/species/riftwalker/RIFT = species

	var/mob/living/dominated_brain/db
	var/mob/living/carbon/human/new_body = new /mob/living/carbon/human(src.loc)

	for(var/I in contents)
		if(istype(I, /mob/living/dominated_brain))
			db = I

	src.client.prefs.copy_to(new_body)
	if(RIFT.real_body.dna)
		RIFT.real_body.dna.ResetUIFrom(RIFT.real_body)
		RIFT.real_body.sync_organ_dna()

	RIFT.remove_riftwalker_abilities(src)

	species = RIFT.species_holder

	src.mind.transfer_to(new_body)

	if(db)
		db.mind.transfer_to(src)
	else
		log_admin("[key_name_admin(RIFT.real_body)] released [key_name_admin(src)], but there was no mind to place back.")

	qdel(RIFT.real_body)
	qdel(db)

	remove_verb(src, /mob/living/carbon/human/proc/riftwalker_release)

// Spawn disguise
/*
/mob/living/carbon/human/proc/spawn_disguise()

	var/selecting = FALSE

	if(selecting)
		return

	var/datum/preferences/pref = preferences_datums[ckey]
	var/savefile/S = new /savefile(pref.path)
	if(!S)
		error("Somehow misssing savefile path?! [pref.path]")

	var/charname
	var/charnickname
	var/list/charlist = list()

	for(var/i = 1, i <= CONFIG_GET(number/character_slots), i++)
		S.cd = "/character[i]"
		S["real_name"] >> charname
		S["nickname"] >> charnickname
		if(!charname)
			continue
		charlist["[charname][nickname ? " ([nickname])" : ""]"] = i

	selecting = TRUE
	var/choice = tgui_input_list(usr, "Select a character", "Select disguise", charlist)
	selecting = FALSE

	if(!choice)
		return

	var/slotnum = charlist[choice]
	if(!slotnum)
		error("Player picked [choice] slot to spawn as, but that wasn't one we sent.")

	var/mob/living/carbon/human/disguise

	disguise = new(loc)
*/
