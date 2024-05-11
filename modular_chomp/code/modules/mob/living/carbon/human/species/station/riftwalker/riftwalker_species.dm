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

	flags =  NO_SCAN | NO_MINOR_CUT | NO_INFECT
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

	move_trail = /obj/effect/decal/cleanable/blood/tracks/claw/riftwalker
	digi_allowed = TRUE

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
		/datum/power/riftwalker/sacrifice,
		/datum/power/riftwalker/bloodjaunt,
		/datum/power/riftwalker/bloodcrawl,
		/datum/power/riftwalker/temporal_cloak,
		/datum/power/riftwalker/echo_image,
		/datum/power/riftwalker/bloodgate,
		/datum/power/riftwalker/possesion)

	var/list/riftwalker_ability_datums = list()

	var/blood_spawn = 0
	var/sacrifice = 0
	var/prey_size = 1
	var/poison = "mindbreaker"
	var/poison_per_bite = 3
	var/shift_time = 30 SECONDS

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
	add_riftwalker_abilities(H)

/datum/species/riftwalker/proc/add_riftwalker_abilities(var/mob/living/carbon/human/H)
	if(!H.ability_master || !istype(H.ability_master, /obj/screen/movable/ability_master/riftwalker))
		H.ability_master = null
		H.ability_master = new /obj/screen/movable/ability_master/riftwalker(H)
	for(var/datum/power/riftwalker/P in riftwalker_ability_datums)
		if(!(P.verbpath in H.verbs))
			add_verb(H,P.verbpath)
			H.ability_master.add_riftwalker_ability(
				object_given = H,
				verb_given = P.verbpath,
				name_given = P.name,
				ability_icon_given = P.ability_icon_state,
				arguments = list()
			)
	add_verb(H,/mob/living/carbon/human/proc/blood_burst)
	add_verb(H,/mob/living/carbon/human/proc/sizechange)
	add_verb(H,/mob/living/carbon/human/proc/choose_prey_size)
	add_verb(H,/mob/living/carbon/human/proc/choose_poison)
	add_verb(H,/mob/living/carbon/human/proc/echo_talk)
	add_verb(H,/mob/living/carbon/human/proc/demon_bite)

/datum/species/riftwalker/proc/remove_riftwalker_abilities(var/mob/living/carbon/human/H)
	if(H.ability_master || istype(H.ability_master, /obj/screen/movable/ability_master/riftwalker))
		qdel(H.ability_master)
		H.ability_master = null
	for(var/datum/power/riftwalker/P in riftwalker_ability_datums)
		if(P.verbpath in H.verbs)
			remove_verb(H, P.verbpath)
	remove_verb(H,/mob/living/carbon/human/proc/blood_burst)
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

	var/temp_diff = body_temperature - H.bodytemperature
	if(temp_diff >= 50)
		if(blood_resource > 0)
			H.riftwalker_adjust_blood(-5)
		else if(H.nutrition)
			H.adjust_nutrition(-10)
		else
			H.adjustFireLoss(2)

	if(world.time < H.l_move_time + 3 MINUTES && blood_resource == 0 && H.nutrition == 0)
		petrify_riftwalker(H)

/datum/species/riftwalker/handle_death(mob/living/carbon/human/H)
	if(real_body)
		var/mob/living/carbon/human/new_body = new /mob/living/carbon/human(H)
		var/client/user_client = H.client

		to_chat(src, "<span class='notice'>With your old vessel destroyed, you start to gather the needed energy to burst back to your original form...</span>")

		user_client.prefs.copy_to(new_body)
		if(src.real_body.dna)
			src.real_body.dna.ResetUIFrom(new_body)
			src.real_body.sync_organ_dna()

		H.mind.transfer_to(new_body)
		qdel(src.real_body)

		spawn(10 SECONDS)
			H.gib()
	else
		petrify_riftwalker(H)
		state |= RW_PETRIFIED
	return TRUE

/datum/species/riftwalker/proc/petrify_riftwalker(mob/living/carbon/human/H)
	playsound(H.loc, 'sound/misc/demondeath.ogg')
	/*	Yeah this is uh- Not good.
	 *	But somehow ghosting and reentering the body makes it work?
	*	So for now I'll leave this here
	*/
	if(H.client)
		var/mob/observer/dead/ghost = H.client.mob
		ghost = H.ghostize(1)
		ghost.reenter_corpse()

	// H._AddComponent(/datum/component/gargoyle)
	var/datum/component/gargoyle/comp = H.GetComponent(/datum/component/gargoyle)
	new /obj/structure/gargoyle(H.loc, H, "statue", "bloodstone", "petrifies", "#E62013", TRUE, TRUE)

	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_transformation)
	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_pause)
	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_checkenergy)
	comp?.cooldown = INFINITY

	remove_riftwalker_abilities(H)

	add_verb(H,/mob/living/carbon/human/proc/riftwalker_statue_sacrifice)
	add_verb(H,/mob/living/carbon/human/proc/riftwalker_surrender)

	spawn(5 MINUTES)
	if(state & RW_PETRIFIED)
		H.riftwalker_surrender()
