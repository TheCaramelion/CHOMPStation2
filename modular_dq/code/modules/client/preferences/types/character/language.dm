// DQ-migrated: language scalar prefs.
// alternate_languages/language_prefixes/language_custom_keys remain
// as monolithic lists for now (composite data — separate refactor).

/datum/preference/numeric/human/extra_languages
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "extra_languages"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	minimum = 0
	maximum = 10

/datum/preference/numeric/human/extra_languages/create_default_value()
	return 0

/datum/preference/numeric/human/extra_languages/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/text/human/preferred_language
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "preflang"   // disk-key match for existing savefiles
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE
	maximum_value_length = MAX_NAME_LEN

/datum/preference/text/human/preferred_language/create_default_value()
	return "common"

/datum/preference/text/human/preferred_language/get_pref_choices(datum/preferences/preferences)
	if(!GLOB.all_languages)
		return null
	// GLOB.all_languages is keyed by name (strings) — a typed-for filters every entry.
	// Iterate keys directly, look up the language datum, skip non-datum/inactive entries.
	var/list/out = list()
	for(var/key in GLOB.all_languages)
		var/datum/language/L = GLOB.all_languages[key]
		if(!istype(L))
			continue
		out += L.name
	return out

/datum/preference/text/human/preferred_language/apply_to_human(mob/living/carbon/human/target, value)
	return


/datum/preference/color/human/runechat_color
	category = PREFERENCE_CATEGORY_NON_CONTEXTUAL
	savefile_key = "runechat_color"
	savefile_identifier = PREFERENCE_CHARACTER
	can_randomize = FALSE

/datum/preference/color/human/runechat_color/create_default_value()
	return COLOR_BLACK

/datum/preference/color/human/runechat_color/apply_to_human(mob/living/carbon/human/target, value)
	return
