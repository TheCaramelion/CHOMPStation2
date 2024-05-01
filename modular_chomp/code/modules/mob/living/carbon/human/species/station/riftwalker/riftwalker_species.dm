/datum/species/riftwalker
	name = SPECIES_RIFTWALKER
	name_plural = "Riftwalkers"
	blurb = "This is a Riftwalker. It is a large item."

	icobase = 'icons/mob/human_races/r_fox_vr.dmi'
	deform = 'icons/mob/human_races/r_def_fox.dmi'

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

	siemens_coefficient = 1
	darksight = 10

	slowdown = -0.5
	item_slowdown_mod = 0.5
	brute_mod = 0.7
	burn_mod = 1.2

	warning_low_pressure = 50
	hazard_low_pressure = -1

	warning_high_pressure = 300
	hazard_high_pressure = INFINITY

	cold_level_1 = 280 //Default 260 - Lower is better
	cold_level_2 = 220 //Default 200
	cold_level_3 = 130 //Default 120

	breath_cold_level_1 = 260	//Default 240 - Lower is better
	breath_cold_level_2 = 200	//Default 180
	breath_cold_level_3 = 120	//Default 100

	heat_level_1 = 420 //Default 360 - Higher is better
	heat_level_2 = 480 //Default 400
	heat_level_3 = 1100 //Default 1000

	breath_heat_level_1 = 450	//Default 380 - Higher is better
	breath_heat_level_2 = 530	//Default 450
	breath_heat_level_3 = 1400	//Default 1250

	flags =  NO_SCAN | NO_MINOR_CUT | NO_INFECT
	spawn_flags = SPECIES_CAN_JOIN | SPECIES_IS_WHITELISTED | SPECIES_WHITELIST_SELECTABLE

	appearance_flags = HAS_HAIR_COLOR | HAS_LIPS | HAS_SKIN_COLOR | HAS_EYE_COLOR | HAS_UNDERWEAR

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
		//datum/power/riftwalker/bloodjaunt,
		/datum/power/riftwalker/bloodcrawl,
		/datum/power/riftwalker/temporal_cloak,
		/datum/power/riftwalker/echo_image,
		/datum/power/riftwalker/bloodgate,
		/datum/power/riftwalker/possesion)

	var/list/riftwalker_ability_datums = list()

	var/doing_bloodcrawl = FALSE
	var/blood_spawn = 0
	var/sacrifice = 0
	var/prey_size = 1
	var/poison = "mindbreaker"
	var/poison_per_bite = 3
	var/shift_time = 30 SECONDS
	var/weakened = FALSE

	var/list/mob/living/carbon/human/mirrors = list()
	var/mob/living/carbon/human/real_body = null
	var/datum/species/species_holder = null

	var/blood_resource = 150
	var/blood_min = 0
	var/blood_max = 150
	var/blood_infinite = FALSE

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
	remove_verb(H,/mob/living/carbon/human/proc/sizechange)
	remove_verb(H,/mob/living/carbon/human/proc/choose_prey_size)
	remove_verb(H,/mob/living/carbon/human/proc/choose_poison)
	remove_verb(H,/mob/living/carbon/human/proc/echo_talk)
	remove_verb(H,/mob/living/carbon/human/proc/demon_bite)

/datum/species/riftwalker/handle_death(mob/living/carbon/human/H)
	if(real_body)
		var/mob/living/carbon/human/new_body = new /mob/living/carbon/human(H)
		var/client/user_client = H.client

		to_chat(src, "With your old vessel destroyed, you start to gather the needed energy to burst back to your original form...")

		user_client.prefs.copy_to(new_body)
		if(src.real_body.dna)
			src.real_body.dna.ResetUIFrom(new_body)
			src.real_body.sync_organ_dna()

		H.mind.transfer_to(new_body)
		qdel(src.real_body)

		spawn(10 SECONDS)
			H.gib()
	else
		return
