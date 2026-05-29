// DQAdd — Trait list constraints. Strip any trait that's no longer valid for the current
// species or synth/meatbag flags.

/datum/preference_constraint/traits_species_filter
	triggers = list("pos_traits", "neu_traits", "neg_traits", "species", "dirty_synth", "gross_meatbag")
	affects = list("pos_traits", "neu_traits", "neg_traits")

/datum/preference_constraint/traits_species_filter/apply(datum/preferences/preferences, changed_key, old_value, new_value)
	prune_traits(preferences, /datum/preference/pos_traits, GLOB.positive_traits, GLOB.everyone_traits_positive)
	prune_traits(preferences, /datum/preference/neu_traits, GLOB.neutral_traits, GLOB.everyone_traits_neutral)
	prune_traits(preferences, /datum/preference/neg_traits, GLOB.negative_traits, GLOB.everyone_traits_negative)

/datum/preference_constraint/traits_species_filter/proc/prune_traits(datum/preferences/preferences, list_type, list/whitelist, list/everyone_whitelist)
	var/list/list_value = preferences.read_preference(list_type)
	if(!islist(list_value))
		return
	// Mutate a Copy() so update_preference_by_type sees a distinct reference and treats
	// it as a write (recently_updated_keys + save_batch_dirty), not a same-ref no-op that
	// would silently drop the prune on the next save flush.
	list_value = list_value.Copy()
	var/changed = FALSE
	var/pref_species = preferences.read_preference(/datum/preference/choiced/species)
	var/synth = preferences.read_preference(/datum/preference/toggle/human/dirty_synth)
	var/meat = preferences.read_preference(/datum/preference/toggle/human/gross_meatbag)
	for(var/datum/trait/path as anything in list_value.Copy())
		if(!(path in whitelist))
			list_value -= path
			changed = TRUE
			continue
		if(pref_species != SPECIES_CUSTOM && !(path in everyone_whitelist))
			list_value -= path
			changed = TRUE
			continue
		var/take_flags = initial(path.can_take)
		if((synth && !(take_flags & SYNTHETICS)) || (meat && !(take_flags & ORGANICS)))
			list_value -= path
			changed = TRUE
	if(changed)
		preferences.update_preference_by_type(list_type, list_value)


/datum/preference_constraint/synth_flag_from_organs
	triggers = list("organ_data")
	affects = list("dirty_synth", "gross_meatbag")

/datum/preference_constraint/synth_flag_from_organs/apply(datum/preferences/preferences, changed_key, old_value, new_value)
	var/list/organ_data = preferences.read_preference(/datum/preference/organ_data)
	if(organ_data && organ_data[O_BRAIN])
		preferences.update_preference_by_type(/datum/preference/toggle/human/dirty_synth, 1)
		preferences.update_preference_by_type(/datum/preference/toggle/human/gross_meatbag, 0)
	else
		preferences.update_preference_by_type(/datum/preference/toggle/human/gross_meatbag, 1)
		preferences.update_preference_by_type(/datum/preference/toggle/human/dirty_synth, 0)


/datum/preference_constraint/trait_budget_reset
	triggers = list("species", "traits_cheating")
	affects = list("starting_trait_points", "max_traits")

/datum/preference_constraint/trait_budget_reset/apply(datum/preferences/preferences, changed_key, old_value, new_value)
	if(preferences.read_preference(/datum/preference/numeric/human/traits_cheating))
		return // admin-cheating prefs persist their custom budget
	var/datum/species/S = GLOB.all_species[preferences.read_preference(/datum/preference/choiced/species)]
	preferences.update_preference_by_type(
		/datum/preference/numeric/human/starting_trait_points,
		S ? S.trait_points : 0,
	)
	preferences.update_preference_by_type(/datum/preference/numeric/human/max_traits, MAX_SPECIES_TRAITS)
