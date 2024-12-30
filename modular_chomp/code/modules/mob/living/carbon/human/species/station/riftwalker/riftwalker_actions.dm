/datum/action/innate/riftwalker
	name = "Base Riftwalker Action"
	check_flags = AB_CHECK_CONSCIOUS
	overlay_icon = 'icons/effects/effects.dmi'

	var/cooldown_timer = null
	var/cost = 0

/datum/action/innate/riftwalker/IsAvailable()
	if(cooldown_timer)
		return FALSE

	var/mob/living/carbon/human/H = owner

	if(H.ability_flags & AB_PHASE_SHIFTED)
		return FALSE

	var/datum/species/riftwalker/RIFT = H.species

	if(RIFT.blood_resource < cost)
		return FALSE

	return TRUE

/datum/action/innate/riftwalker/proc/reset_timer()
	cooldown_timer = null
	owner.update_mob_action_buttons()

/datum/action/innate/riftwalker/proc/consume_blood(var/amount)
	var/mob/living/carbon/human/H = owner
	var/datum/species/riftwalker/RIFT = H.species

	RIFT.adjust_blood(-amount)

/datum/action/innate/riftwalker/sacrifice
	name = "Sacrifice"
	var/gained = 50

/datum/action/innate/riftwalker/sacrifice/Activate()
	var/mob/living/carbon/human/H = owner

	if(!IsAvailable())
		return

	var/obj/item/grab/G = H.get_active_hand()

	if(!istype(G) && !istype(G, /mob/living/))
		to_chat(owner, span_warning("You must be grabbing a creature in your active hand to affect them."))
		return

	var/mob/living/T = G.affecting

	if(G.state != GRAB_NECK)
		to_chat(owner, span_warning("You must have a tighter grip to affect this creature."))
		return

	var/datum/species/riftwalker/RIFT = H.species

	if(do_after(owner, 5 SECONDS, target = owner, max_distance = 2))
		RIFT.adjust_blood(gained)
		T.gib()

		cooldown_timer = addtimer(CALLBACK(src, PROC_REF(reset_timer)), 90 SECONDS)

/datum/action/innate/riftwalker/bloodburst
	name = "Blood Burst (10)"
	cost = 10

/datum/action/innate/riftwalker/bloodburst/Activate()
	if(!IsAvailable())
		return

	consume_blood(cost)

	new /obj/effect/gibspawner/generic(get_turf(owner))

	playsound(owner, 'sound/effects/blobattack.ogg', 50, 1)

	owner.update_mob_action_buttons()
	cooldown_timer = addtimer(CALLBACK(src, PROC_REF(reset_timer)), 150 SECONDS)

/datum/action/innate/riftwalker/temporal_cloak
	name = "Temporal Cloak (20)"
	cost = 20

/datum/action/innate/riftwalker/temporal_cloak/Trigger(trigger_flags)
	. = ..()
	if(!IsAvailable())
		return

	if(!active)
		consume_blood(cost)

/datum/action/innate/riftwalker/temporal_cloak/Activate()
	owner.cloak()
	active = TRUE

	addtimer(CALLBACK(src, PROC_REF(reset_cloak)), 30 SECONDS)

/datum/action/innate/riftwalker/temporal_cloak/proc/reset_cloak()
	if(active)
		Deactivate()

/datum/action/innate/riftwalker/temporal_cloak/Deactivate()
	owner.uncloak()
	active = FALSE

/datum/action/innate/riftwalker/bloodcrawl
	name = "Blood Crawl (100)"
	cost = 100
	var/original_canmove

/datum/action/innate/riftwalker/bloodcrawl/IsAvailable()
	if(cooldown_timer)
		return FALSE

	var/mob/living/carbon/human/H = owner
	var/datum/species/riftwalker/RIFT = H.species

	if((RIFT.blood_resource < cost && !(H.ability_flags & AB_PHASE_SHIFTED)))
		return FALSE

	var/area/A = get_area(H)

	if(A.flag_check(PHASE_SHIELDED))
		return FALSE

	if(locate(/obj/effect/decal/cleanable/blood/oil) in H.loc || locate(/obj/effect/decal/cleanable/blood/gibs/robot) in H.loc)
		return FALSE

	if(!(locate(/obj/effect/decal/cleanable/blood) in H.loc || locate(/obj/effect/decal/cleanable/blood/gibs) in H.loc))
		return FALSE

	return TRUE

/datum/action/innate/riftwalker/bloodcrawl/Activate()

	if(!ishuman(owner))
		return

	consume_blood(cost)

	var/mob/living/carbon/human/H = owner

	if(!(H.ability_flags & AB_PHASE_SHIFTED))
		H.forceMove(get_turf(H))
		original_canmove = H.canmove
		H.SetStunned(0)
		H.SetWeakened(0)
		if(H.buckled)
			H.buckled.unbuckle_mob()
		if(H.pulledby)
			H.pulledby.stop_pulling()
		H.stop_pulling()
		H.canmove = FALSE

		H.ability_flags |= AB_PHASE_SHIFTED
		H.ability_flags |= AB_PHASE_SHIFTING
		H.mouse_opacity = FALSE
		H.name = H.get_visible_name()

		if(H.l_hand)
			H.unEquip(H.l_hand)
		if(H.r_hand)
			H.unEquip(H.r_hand)
		if(H.back)
			H.unEquip(H.back)

		H.can_pull_size = 0
		H.can_pull_mobs = MOB_PULL_NONE
		H.hovering = TRUE

		for(var/obj/belly/B as anything in H.vore_organs)
			B.escapable = FALSE

		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/bloodout(H.loc)
		phaseanim.dir = H.dir
		H.alpha = 0
		H.add_modifier(/datum/modifier/riftwalker_phase_vision)
		H.add_modifier(/datum/modifier/riftwalker_phase)

		addtimer(CALLBACK(src, PROC_REF(finish_phaseout)), 1 SECONDS)

/datum/action/innate/riftwalker/bloodcrawl/proc/finish_phaseout()

	var/mob/living/carbon/human/H = owner

	H.invisibility = INVISIBILITY_SHADEKIN
	H.see_invisible = INVISIBILITY_SHADEKIN
	H.see_invisible_default = INVISIBILITY_SHADEKIN

	H.update_icon()
	H.alpha = 127

	H.canmove = original_canmove
	H.incorporeal_move = TRUE
	H.density = FALSE
	H.force_max_speed = TRUE
	H.ability_flags &= ~AB_PHASE_SHIFTING

	active = TRUE

/datum/action/innate/riftwalker/bloodcrawl/Deactivate()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/H = owner

	if(H.ability_flags & AB_PHASE_SHIFTED)

		H.forceMove(get_turf(H))
		original_canmove = H.canmove
		H.SetStunned(0)
		H.SetWeakened(0)
		if(H.buckled)
			H.buckled.unbuckle_mob()
		if(H.pulledby)
			H.pulledby.stop_pulling()
		H.stop_pulling()
		H.canmove = FALSE

		H.ability_flags &= ~AB_PHASE_SHIFTED
		H.ability_flags |= AB_PHASE_SHIFTING
		H.mouse_opacity = TRUE
		H.name = H.get_visible_name()

		for(var/obj/belly/B as anything in H.vore_organs)
			B.escapable = initial(B.escapable)

		H.invisibility = initial(H.invisibility)
		H.see_invisible = initial(H.see_invisible)
		H.see_invisible_default = initial(H.see_invisible_default)
		H.incorporeal_move = initial(H.incorporeal_move)
		H.density = initial(H.density)
		H.force_max_speed = initial(H.force_max_speed)
		H.force_max_speed = initial(H.force_max_speed)
		H.can_pull_size = initial(H.can_pull_size)
		H.can_pull_mobs = initial(H.can_pull_mobs)
		H.hovering = initial(H.hovering)

		H.update_icon()

		var/obj/effect/temp_visual/riftwalker/phasein/phaseanim = new /obj/effect/temp_visual/riftwalker/bloodin(H.loc)
		phaseanim.pixel_y = (H.size_multiplier - 1)
		phaseanim.adjust_scale(H.size_multiplier, H.size_multiplier)
		H.alpha = 0

		if(H.can_be_drop_pred || H.can_be_drop_prey)
			var/list/potentials = H.living_mobs(0)
			if(potentials.len)
				var/mob/living/target = pick(potentials)
				if(H.can_be_drop_pred && istype(target) && target.devourable && target.can_be_drop_prey && target.phase_vore && H.vore_selected && H.phase_vore)
					target.forceMove(H.vore_selected)
					to_chat(target, span_vwarning("\The [src] phases in around you, [H.vore_selected.vore_verb]ing you into their [H.vore_selected.name]!"))
					to_chat(H, span_vwarning("You phase in around [target], [H.vore_selected.vore_verb]ing them into your [H.vore_selected.name]!"))
				else if(H.can_be_drop_prey && istype(target) && H.devourable && target.can_be_drop_pred && target.phase_vore && target.vore_selected && H.phase_vore)
					H.forceMove(target)
					to_chat(target, span_vwarning("\The [src] phases in around you, [target.vore_selected.vore_verb]ing you into their [target.vore_selected.name]!"))
					to_chat(H, span_vwarning("You phase in around [target], [target.vore_selected.vore_verb]ing them into your [target.vore_selected.name]!"))

		addtimer(CALLBACK(src, PROC_REF(finish_phasein)), 1 SECONDS)

/datum/action/innate/riftwalker/bloodcrawl/proc/finish_phasein()

	var/mob/living/carbon/human/H = owner

	H.canmove = original_canmove
	H.alpha = initial(H.alpha)
	H.remove_a_modifier_of_type(/datum/modifier/riftwalker_phase_vision)
	H.remove_a_modifier_of_type(/datum/modifier/riftwalker_phase)

	H.ability_flags &= ~AB_PHASE_SHIFTING

	active = FALSE

/datum/action/innate/riftwalker/bloodcrawl/bloodjaunt
	name = "Blood Jaunt (50)"
	cost = 50

/datum/action/innate/riftwalker/bloodcrawl/bloodjaunt/finish_phaseout()
	. = ..()

	addtimer(CALLBACK(src, PROC_REF(Deactivate)), 3 SECONDS)

/datum/action/innate/riftwalker/echo_image
	name = "Echo Image (50)"
	cost = 50

/datum/action/innate/riftwalker/echo_image/Activate()

	var/client/rw_client = owner.client
	var/mob/living/carbon/human/dummy/mirror = get_mannequin(rw_client)
	var/mob/living/carbon/human/H = owner
	var/datum/species/riftwalker/RIFT = H.species

	mirror = new(owner.loc)
	rw_client.prefs.copy_to(mirror)

	RIFT.mirrors += mirror

	addtimer(CALLBACK(src, PROC_REF(destroy_echo), mirror), 5 MINUTES)

/datum/action/innate/riftwalker/echo_image/proc/destroy_echo(var/mob/living/mirror)
	mirror.visible_emote("turns into ashes.")
	new /obj/effect/decal/cleanable/ash(mirror.loc)

	var/mob/living/carbon/human/H = owner
	var/datum/species/riftwalker/RIFT = H.species

	RIFT.mirrors -= mirror
	mirror.Destroy()

/datum/action/innate/riftwalker/possession
	name = "Possession"

/datum/action/innate/riftwalker/possession/Activate()
	var/mob/living/carbon/human/H = owner

	if(!IsAvailable())
		return

	var/obj/item/grab/G = H.get_active_hand()

	if(!istype(G))
		to_chat(H, span_warning("You must be grabbing a creature in your active hand to affect them."))
		return

	var/mob/living/carbon/human/T = G.affecting

	if(T.stat == DEAD)
		to_chat(H, span_warning("You cannot possess a dead creature."))
		return

	if(T.isSynthetic())
		to_chat(H, span_warning("You cannot possess a synthetic creature."))
		return

	if(tgui_alert(H, "You selected to possess [T]. Are you sure you want to proceed?", "Posses Prey", list("No", "Yes")) != "Yes")
		return

	log_admin("[key_name_admin(H)] offered posses on [T] ([T.ckey]).")
	to_chat(H, span_warning("Attempting to posses [T]'s body..."))

	if(T.ckey)
		if(tgui_alert(T, "[H] has elected to posses you. Is this something you are okay with?", "Possession Alert", list("No", "Yes")) != "Yes")
			to_chat(H, span_warning("[T] declined your possessing attempt."))
			return

		if(tgui_alert(T, "Are you sure? This might be difficult to come back from.", "Possession Alert", list("No", "Yes")) != "Yes")
			to_chat(H, span_warning("[T] declined your possessing attempt."))
			return

	var/mob/living/dominated_brain/db = new /mob/living/dominated_brain(T, H, T.name, T)
	var/datum/mind/user_mind = H.mind
	var/datum/mind/victim_mind = T.mind
	var/datum/species/old_species = T.species

	remove_verb(db, /mob/living/dominated_brain/proc/resist_control)

	db.ckey = db.prey_ckey

	log_admin("[db] ([db.ckey]) has agreed to [T]'s possesion, and no longer occupies their original body.")

	var/datum/species/riftwalker/RIFT = H.species
	var/datum/species/riftwalker/new_rift = RIFT.produceCopy(T.dna.species_traits, T)

	new_rift.hud = old_species.hud
	new_rift.hud_type = old_species.hud_type

	new_rift.species_holder = old_species
	new_rift.name = old_species.name
	new_rift.add_riftwalker_abilities(T)
	new_rift.blood_resource = RIFT.blood_resource

	add_verb(T, /mob/living/carbon/human/proc/riftwalker_release)

	if(new_rift.real_body)
		new_rift.real_body = RIFT.real_body
		qdel(RIFT.real_body)
	else
		new_rift.real_body = new /mob/living/carbon/human

	H.gib()
	if(victim_mind)
		victim_mind.transfer_to(db)
	user_mind.transfer_to(T)

/datum/action/innate/riftwalker/release_posses
	name = "Release vessel"

/datum/action/innate/riftwalker/release_posses/Activate()

	var/mob/living/carbon/human/H = owner
	var/datum/species/riftwalker/RIFT = H.species

	var/mob/living/dominated_brain/db
	var/mob/living/carbon/human/new_body = new /mob/living/carbon/human(H.loc)

	for(var/I in H.contents)
		if(istype(I, /mob/living/dominated_brain))
			db = I

	H.client.prefs.copy_to(new_body)
	if(RIFT.real_body.dna)
		RIFT.real_body.dna.ResetUIFrom(RIFT.real_body)
		RIFT.real_body.sync_organ_dna()

	RIFT.remove_riftwalker_abilities()

	H.species = RIFT.species_holder

	H.mind.transfer_to(new_body)

	if(db)
		db.mind.transfer_to(H)
	else
		log_admin("[key_name_admin(RIFT.real_body)] released [key_name_admin(H)], but there was no mind to place back")

	qdel(RIFT.real_body)
	qdel(db)
