// DQ-migrated: trait-budget composite prefs + blood_color.

/datum/preference/color/human/blood_color
	savefile_key = "blood_color"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/color/human/blood_color/create_default_value()
	return "#A10808"

/datum/preference/color/human/blood_color/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/numeric/human/starting_trait_points
	savefile_key = "starting_trait_points"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE
	minimum = 0
	maximum = 10000
	widget = PREF_WIDGET_HIDDEN  // accumulated trait-point pool, managed by the trait picker

/datum/preference/numeric/human/starting_trait_points/create_default_value()
	return 0

/datum/preference/numeric/human/starting_trait_points/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/numeric/human/max_traits
	savefile_key = "max_traits"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE
	minimum = 0
	maximum = 100
	widget = PREF_WIDGET_HIDDEN  // computed cap, managed by the trait picker

/datum/preference/numeric/human/max_traits/create_default_value()
	return MAX_SPECIES_TRAITS

/datum/preference/numeric/human/max_traits/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/numeric/human/traits_cheating
	savefile_key = "traits_cheating"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	can_randomize = FALSE
	minimum = 0
	maximum = 1
	widget = PREF_WIDGET_HIDDEN  // unlock-cheats flag, set by the trait picker


/datum/preference/numeric/human/traits_cheating/create_default_value()
	return 0

/datum/preference/numeric/human/traits_cheating/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/pos_traits
	savefile_key = "pos_traits"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/pos_traits/create_default_value()
	return list()

/datum/preference/pos_traits/pref_deserialize(input, datum/preferences/preferences)
	if(!islist(input))
		return list()
	return input

/datum/preference/pos_traits/pref_serialize(input)
	if(!islist(input))
		return list()
	return check_list_copy(input)

/datum/preference/pos_traits/is_valid(value)
	return islist(value)

/datum/preference/pos_traits/apply_to_human(mob/living/carbon/human/target, value)
	return
/datum/preference/pos_traits/apply_to_living(mob/living/target, value)
	return
/datum/preference/pos_traits/apply_to_silicon(mob/living/silicon/target, value)
	return
/datum/preference/pos_traits/apply_to_animal(mob/living/simple_mob/target, value)
	return


/datum/preference/neu_traits
	savefile_key = "neu_traits"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/neu_traits/create_default_value()
	return list()

/datum/preference/neu_traits/pref_deserialize(input, datum/preferences/preferences)
	if(!islist(input))
		return list()
	return input

/datum/preference/neu_traits/pref_serialize(input)
	if(!islist(input))
		return list()
	return check_list_copy(input)

/datum/preference/neu_traits/is_valid(value)
	return islist(value)

/datum/preference/neu_traits/apply_to_human(mob/living/carbon/human/target, value)
	return
/datum/preference/neu_traits/apply_to_living(mob/living/target, value)
	return
/datum/preference/neu_traits/apply_to_silicon(mob/living/silicon/target, value)
	return
/datum/preference/neu_traits/apply_to_animal(mob/living/simple_mob/target, value)
	return


/datum/preference/neg_traits
	savefile_key = "neg_traits"
	savefile_identifier = PREFERENCE_CHARACTER
	category = PREFERENCE_CATEGORY_MANUALLY_RENDERED
	can_randomize = FALSE

/datum/preference/neg_traits/create_default_value()
	return list()

/datum/preference/neg_traits/pref_deserialize(input, datum/preferences/preferences)
	if(!islist(input))
		return list()
	return input

/datum/preference/neg_traits/pref_serialize(input)
	if(!islist(input))
		return list()
	return check_list_copy(input)

/datum/preference/neg_traits/is_valid(value)
	return islist(value)

/datum/preference/neg_traits/apply_to_human(mob/living/carbon/human/target, value)
	return
/datum/preference/neg_traits/apply_to_living(mob/living/target, value)
	return
/datum/preference/neg_traits/apply_to_silicon(mob/living/silicon/target, value)
	return
/datum/preference/neg_traits/apply_to_animal(mob/living/simple_mob/target, value)
	return
