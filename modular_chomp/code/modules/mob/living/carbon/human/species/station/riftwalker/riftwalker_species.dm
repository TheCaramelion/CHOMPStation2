/datum/species/riftwalker
	name = SPECIES_RIFTWALKER
	name_plural = "Riftwalkers"
	blurb = "This is a Riftwalker. It is a large item."

	icobase = 'icons/mob/human_races/r_fox_vr.dmi'
	deform = 'icons/mob/human_races/r_def_fox.dmi'

	hud_type = /datum/hud_data/riftwalker

	language = LANGUAGE_DAEMON
	name_language = LANGUAGE_DAEMON
	species_language = LANGUAGE_DAEMON
	secondary_langs = list(LANGUAGE_DAEMON)
	num_alternate_languages = 3
	unarmed_types = list(/datum/unarmed_attack/stomp, /datum/unarmed_attack/kick, /datum/unarmed_attack/claws, /datum/unarmed_attack/bite/sharp)
	rarity_value = 15

	inherent_verbs = list(
		/mob/living/carbon/human/proc/bloodsuck,
		/mob/living/proc/shred_limb
	)

	default_emotes = list(
		/decl/emote/audible/rift_laugh
	)

	siemens_coefficient = 1
	darksight = 10

	slowdown = -0.5
	item_slowdown_mod = 0.5
	brute_mod = 1.2
	burn_mod = 0

	warning_low_pressure = 50
	hazard_low_pressure = -1

	warning_high_pressure = 300
	hazard_high_pressure = INFINITY

	cold_level_1 = 280 //Default 260 - Lower is better
	cold_level_2 = 220 //Default 200
	cold_level_3 = 130 //Default 120

	// Immune to HEAT

	heat_level_1 = 850 //Default 360 - Higher is better
	heat_level_2 = 100 //Default 400
	heat_level_3 = 1150 //Default 1000

	flags = NO_MINOR_CUT | NO_INFECT
	spawn_flags = SPECIES_CAN_JOIN | SPECIES_IS_WHITELISTED | SPECIES_WHITELIST_SELECTABLE

	vision_flags = SEE_SELF|SEE_MOBS
	appearance_flags = HAS_HAIR_COLOR | HAS_LIPS | HAS_SKIN_COLOR | HAS_EYE_COLOR

	flesh_color = "#FFC896"
	blood_color = "#A10808"
	base_color = "#f0f0f0"
	color_mult = 1

	reagent_tag = IS_RIFTWALKER

	speech_bubble_appearance = "ghost"

	genders = list(MALE, FEMALE, PLURAL, NEUTER)

	virus_immune = 1

	breath_type = null
	poison_type = null
	water_breather = TRUE

	move_trail = /obj/effect/decal/cleanable/blood/tracks/claw

	has_organ = list(
		O_HEART =		/obj/item/organ/internal/heart,
		O_VOICE = 		/obj/item/organ/internal/voicebox,
		O_LIVER =		/obj/item/organ/internal/liver,
		O_KIDNEYS =		/obj/item/organ/internal/kidneys,
		O_BRAIN =		/obj/item/organ/internal/brain,
		O_EYES =		/obj/item/organ/internal/eyes,
		O_STOMACH =		/obj/item/organ/internal/stomach,
		O_INTESTINE =	/obj/item/organ/internal/intestine
		)

	has_limbs = list(
		BP_TORSO =  list("path" = /obj/item/organ/external/chest),
		BP_GROIN =  list("path" = /obj/item/organ/external/groin),
		BP_HEAD =   list("path" = /obj/item/organ/external/head),
		BP_L_ARM =  list("path" = /obj/item/organ/external/arm),
		BP_R_ARM =  list("path" = /obj/item/organ/external/arm/right),
		BP_L_LEG =  list("path" = /obj/item/organ/external/leg),
		BP_R_LEG =  list("path" = /obj/item/organ/external/leg/right),
		BP_L_HAND = list("path" = /obj/item/organ/external/hand),
		BP_R_HAND = list("path" = /obj/item/organ/external/hand/right),
		BP_L_FOOT = list("path" = /obj/item/organ/external/foot),
		BP_R_FOOT = list("path" = /obj/item/organ/external/foot/right)
		)

	var/list/riftwalker_abilities = list(
		/datum/power/riftwalker/bloodjaunt,
		/datum/power/riftwalker/bloodcrawl,
		/datum/power/riftwalker/echo_image,
		/datum/power/riftwalker/bloodgate,
		/datum/power/riftwalker/possesion)

	var/list/riftwalker_ability_datums = list()

	var/blood_spawn = 0
	var/sacrifice = 0
	var/prey_size = 1
	var/poison = "mindbreaker"
	var/poison_per_bite = 3

	var/list/mob/living/carbon/human/mirrors = list()
	var/mob/living/carbon/human/real_body = null
	var/datum/species/species_holder = null

	var/blood_resource = 150
	var/blood_min = 0
	var/blood_max = 150
	var/blood_infinite = FALSE

	/*
	RW_BLOODGATE
	RW_WEAKENED
	RW_PETRIFIED
	RW_NAME_REVEALED
	RW_BLOODCRAWLING
	*/
	var/state = 0

/datum/species/riftwalker/New()
	..()
	for(var/power in riftwalker_abilities)
		var/datum/power/riftwalker/RIFT = new power(src)
		riftwalker_ability_datums.Add(RIFT)

/datum/species/riftwalker/get_bodytype()
	return SPECIES_RIFTWALKER

/datum/species/riftwalker/add_inherent_verbs(var/mob/living/carbon/human/H)
	..()
	// add_riftwalker_abilities(H)

	add_verb(H,/mob/living/carbon/human/proc/echo_talk)

	var/datum/action/innate/riftwalker/sacrifice/sacrifice = new()
	var/datum/action/innate/riftwalker/bloodburst/bloodburst = new()
	var/datum/action/innate/riftwalker/temporal_cloak/cloak = new()
	var/datum/action/innate/riftwalker/bloodcrawl/bloodcrawl = new()
	var/datum/action/innate/riftwalker/bloodcrawl/bloodjaunt/jaunt = new()
	var/datum/action/innate/riftwalker/echo_image/echo = new()

	sacrifice.Grant(H)
	bloodburst.Grant(H)
	cloak.Grant(H)
	bloodcrawl.Grant(H)
	jaunt.Grant(H)
	echo.Grant(H)

/datum/species/riftwalker/proc/add_riftwalker_abilities(var/mob/living/carbon/human/H)
	for(var/datum/power/riftwalker/P in riftwalker_ability_datums)
		if(!(P.verbpath in H.verbs))
			add_verb(H,P.verbpath)
	add_verb(H,/mob/living/carbon/human/proc/sizechange)
	add_verb(H,/mob/living/carbon/human/proc/choose_prey_size)
	add_verb(H,/mob/living/carbon/human/proc/choose_poison)
	add_verb(H,/mob/living/carbon/human/proc/echo_talk)
	add_verb(H,/mob/living/carbon/human/proc/demon_bite)

/datum/species/riftwalker/proc/remove_riftwalker_abilities(var/mob/living/carbon/human/H)
	for(var/datum/power/riftwalker/P in riftwalker_ability_datums)
		if(P.verbpath in H.verbs)
			remove_verb(H, P.verbpath)
	remove_verb(H,/mob/living/carbon/human/proc/sizechange)
	remove_verb(H,/mob/living/carbon/human/proc/choose_prey_size)
	remove_verb(H,/mob/living/carbon/human/proc/choose_poison)
	remove_verb(H,/mob/living/carbon/human/proc/echo_talk)
	remove_verb(H,/mob/living/carbon/human/proc/demon_bite)

/datum/species/riftwalker/handle_environment_special(var/mob/living/carbon/human/H)

	if(H.radiation)
		var/rad_damage = 0 - H.radiation
		H.radiation = rad_damage
		H.adjustFireLoss((rad_damage))
		H.adjustBruteLoss((rad_damage))
		H.adjustToxLoss((rad_damage))
		H.adjustCloneLoss((rad_damage))
		H.heal_organ_damage(rad_damage,0)
		H.adjust_nutrition(-rad_damage)
		H.add_chemical_effect(CE_ANTIBIOTIC, ANTIBIO_NORM)
		for(var/obj/item/organ/I in H.internal_organs)
			if(I.robotic >= ORGAN_ROBOT)
				continue
			if(I.damage > 0)
				I.damage = max(I.damage - 0.1, 0)
			if(I.damage <= 5 && I.organ_tag == O_EYES)
				H.sdisabilities %= ~BLIND
		for(var/obj/item/organ/external/O in H.organs)
			if(O.status & ORGAN_BROKEN)
				O.mend_fracture()
			for(var/datum/wound/W in O.wounds)
				if(W.bleeding())
					W.damage = max(W.damage - rad_damage, 0)
					if(W.damage <= 0)
						O.wounds -= W
				if(W.internal)
					W.damage = max(W.damage - rad_damage, 0)
					if(W.damage <= 0)
						O.wounds -= W
		if(prob(5))
			H.restore_all_organs()

	var/temp_diff = body_temperature - H.bodytemperature
	if(temp_diff >= 50)
		if(blood_resource > 0)
			H.riftwalker_adjust_blood(-5)
		else if(H.nutrition)
			H.adjust_nutrition(-10)
		else
			H.adjustFireLoss(2)

	for(var/obj/belly/belly in H)
		for(var/mob/living/carbon/human/prey in belly)
			H.riftwalker_adjust_blood(1)
		for(var/mob/living/silicon/prey in belly)
			H.riftwalker_adjust_blood(1)

	if(world.time < H.l_move_time + 3 MINUTES && blood_resource == 0 && H.nutrition == 0)
		petrify_riftwalker(H)
		state |= RW_PETRIFIED

/datum/species/riftwalker/handle_death(mob/living/carbon/human/H)
	//if(state & RW_POSSESING)
	//	return TRUE
	if(state & RW_PETRIFIED)
		var/list/floors = list()
		for(var/turf/unsimulated/floor/dark/floor in get_area_turfs(/area/shadekin))
			floors.Add(floor)
		if(!LAZYLEN(floors))
			log_and_message_admins("[H] died outside of redspace, but there was no valid floos to teleport to.")
			return

		H.drop_both_hands()
		blood_resource = 0
		state |= RW_RSRECOVERY

		H.adjustFireLoss(-(H.getFireLoss() * 0.75))
		H.adjustBruteLoss(-(H.getBruteLoss() * 0.75))
		H.adjustToxLoss(-(H.getToxLoss() * 0.75))
		H.adjustCloneLoss(-(H.getCloneLoss() * 0.75))
		H.germ_level = 0
		H.restore_blood()
		H.restore_all_organs()
		H.nutrition = 0
		H.invisibility = INVISIBILITY_SHADEKIN
		BITRESET(H.hud_updateflag, HEALTH_HUD)
		BITRESET(H.hud_updateflag, STATUS_HUD)
		BITRESET(H.hud_updateflag, LIFE_HUD)

		if(istype(H.loc, /obj/belly))
			var/obj/belly/belly = H.loc
			add_attack_logs(belly.owner, H, "Digested in [lowertext(belly.name)]")
			to_chat(belly.owner, span_notice("You feel that [H] suddenly hardens, then crumble down to dust within your [belly.name]"))
			H.forceMove(pick(floors))
			if(H.ability_flags & AB_PHASE_SHIFTED)
				H.riftwalker_phase_in()
			H.invisibility = initial(H.invisibility)
			belly.owner.update_fullness()
			H.clear_fullscreen("belly")
			if(H.hud_used)
				if(!H.hud_used.hud_shown)
					H.toggle_hud_vis()
			H.stop_sound_channel(CHANNEL_PREYLOOP)
			H.muffled = FALSE
			H.forced_psay = FALSE

			var/obj/effect/decal/cleanable/ash/dust = new /obj/effect/decal/cleanable/ash(H.loc)

			dust.color = "#E62013"
			dust.name = "bloodstone dust"

			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon/human, riftwalker_recover)), 5 MINUTES)
		else

			H.forceMove(pick(floors))
			if(H.ability_flags & AB_PHASE_SHIFTED)
				H.riftwalker_phase_out()
			H.invisibility = initial(H.invisibility)

			addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon/human, riftwalker_recover)), 5 MINUTES)
		H.add_modifier(/datum/modifier/redspace_recovery, 1 MINUTE)

	if(real_body)
		playsound(H, pick(get_species_sound(get_gendered_sound(species_holder))["death"]), H.species.death_volume, 1, 20, volume_channel = VOLUME_CHANNEL_DEATH_SOUNDS)
		var/mob/living/carbon/human/new_body = new /mob/living/carbon/human(H)
		var/client/user_client = H.client

		to_chat(H, span_notice("With your old vessel destroyed, you start to gather the needed energy to burst back to your original form..."))

		user_client.prefs.copy_to(new_body)
		if(src.real_body.dna)
			src.real_body.dna.ResetUIFrom(new_body)
			src.real_body.sync_organ_dna()

		H.mind.transfer_to(new_body)
		H.species = species_holder
		qdel(src.real_body)

		spawn(10 SECONDS)
			H.gib()
	else
		H.drop_both_hands()
		petrify_riftwalker(H)
		state |= RW_PETRIFIED
	return TRUE

/datum/modifier/redspace_recovery
	name = "Redspace Recovery"
	pain_immunity = 1

/datum/modifier/redspace_recovery/tick()
	if(istype(src.holder, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = src.holder
		H.add_chemical_effect(CE_BLOODRESTORE, 1)

		if(istype(get_area(H), /area/shadekin)) // Change this to whatever redspace area is later
			if(!src.pain_immunity)
				src.pain_immunity = 1
			H.adjustFireLoss((-0.25))
			H.adjustBruteLoss((-0.25))
			H.adjustToxLoss((-0.25))
			H.heal_organ_damage(3, 0)
			H.add_chemical_effect(CE_ANTIBIOTIC, ANTIBIO_SUPER)
			for(var/obj/item/organ/I in H.internal_organs)
				if(I.robotic >= ORGAN_ROBOT)
					continue
				if(I.damage > 0)
					I.damage = max(I.damage - 0.25, 0)
				if(I.damage <= 5 && I.organ_tag == O_EYES)
					H.sdisabilities &= ~BLIND
			for(var/obj/item/organ/external/O in H.organs)
				if(O.status & ORGAN_BROKEN)
					O.mend_fracture()
				for(var/datum/wound/W in O.wounds)
					if(W.bleeding())
						W.damage = max(W.damage - 3, 0)
						if(W.damage <= 0)
							O.wounds -= W
					if(W.internal)
						W.damage = max(W.damage - 3, 0)
						if(W.damage <= 0)
							O.wounds -= W

/datum/species/riftwalker/proc/adjust_blood(amount)
	blood_resource = clamp(blood_resource+amount, blood_min, blood_max)
	return TRUE
