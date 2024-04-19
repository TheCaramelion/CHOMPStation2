/datum/species/riftwalker
	name = SPECIES_RIFTWALKER
	name_plural = "Riftwalkers"
	blurb = "This is a Riftwalker. It is a large item."

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

	cold_level_1 = -1	//Immune to cold
	cold_level_2 = -1
	cold_level_3 = -1

	heat_level_1 = 850	//Resistant to heat
	heat_level_2 = 1000
	heat_level_3 = 1150

	flags = NO_SCAN | NO_MINOR_CUT | NO_INFECT
	spawn_flags = SPECIES_CAN_JOIN | SPECIES_IS_WHITELISTED | SPECIES_WHITELIST_SELECTABLE

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

	vision_flags = SEE_SELF | SEE_MOBS
	appearance_flags = HAS_HAIR_COLOR | HAS_LIPS | HAS_SKIN_COLOR | HAS_EYE_COLOR | HAS_UNDERWEAR

	move_trail = /obj/effect/decal/cleanable/blood/tracks/claw/riftwalker

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

	var/list/riftwalker_abilities = list (
		/datum/power/riftwalker/blood_burst,
		/datum/power/riftwalker/sizechange,
		/datum/power/riftwalker/demon_bite)
	var/list/riftwalker_abilities_datums = list()
	var/doing_phase = FALSE
	var/blood_spawn = 0
	var/size_amount = 100
	var/poison = "mindbreaker"
	var/poison_per_bite = 3

/datum/species/riftwalker/New()
	..()
	for(var/power in riftwalker_abilities)
		var/datum/power/riftwalker/riftpower = new power(src)
		riftwalker_abilities_datums.Add(riftpower)
