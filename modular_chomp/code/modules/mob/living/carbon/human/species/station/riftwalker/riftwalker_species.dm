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
	unarmed_types = list(/datum/unarmed_attack/stomp, /datum/unarmed_attack/kick, /datum/unarmed_attack/claws/strong, /datum/unarmed_attack/bite/sharp/numbing)
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

	cold_level_1 = -1
	cold_level_2 = -1
	cold_level_3 = -1

	heat_level_1 = 850
	heat_level_2 = 1000
	heat_level_3 = 1150

	spawn_flags = SPECIES_CAN_JOIN

	appearance_flags = HAS_HAIR_COLOR | HAS_LIPS | HAS_SKIN_COLOR | HAS_EYE_COLOR | HAS_UNDERWEAR

	flesh_color = "#FFC896"
	blood_color = "#A10808"
	base_color = "#f0f0f0"
	color_mult = 1

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
		/datum/power/riftwalker/riftwalker_phase,
		/datum/power/riftwalker/bloodcrawl,
		/datum/power/riftwalker/blood_burst,
		/datum/power/riftwalker/sizechange,
		/datum/power/riftwalker/demon_bite)

	var/list/riftwalker_ability_datums = list()

	var/doing_phase = FALSE
	var/doing_bloodcrawl = FALSE
	var/blood_spawn = 0
	var/prey_size = 1
	var/poison = "mindbreaker"
	var/poison_per_bite = 3
	var/shift_time = 30 SECONDS

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
	add_verb(H,/mob/living/carbon/human/proc/choose_prey_size)
	add_verb(H,/mob/living/carbon/human/proc/choose_poison)
