// DQAdd — Flavor text editor. Manages the 9 body-part flavor slots (general/head/face/eyes/
// torso/arms/hands/legs/feet) plus the robot module flavor map.

/datum/preference_editor/flavor
	key = "flavor"
	category = "identity"
	group = "flavor"
	sort_order = 50
	display_name = "Flavor Text"
	pref_keys = list("flavor_texts", "flavour_texts_robot")

/datum/preference_editor/flavor/build_ui_data(datum/preferences/preferences)
	return list(
		"flavor_texts" = preferences.read_preference(/datum/preference/flavor_texts) || list(),
		"flavour_texts_robot" = preferences.read_preference(/datum/preference/flavour_texts_robot) || list(),
	)

/datum/preference_editor/flavor/build_ui_static_data(datum/preferences/preferences)
	return list(
		"flavor_zones" = list("general", "head", "face", "eyes", "torso", "arms", "hands", "legs", "feet"),
		"robot_modules" = GLOB.robot_module_types,
	)

/datum/preference_editor/flavor/handle_action(datum/preferences/preferences, action, list/params, mob/user)
	switch(action)
		if("set_flavor")
			var/list/flavor = preferences.read_preference(/datum/preference/flavor_texts) || list()
			flavor[params["zone"]] = strip_html_simple(params["text"])
			preferences.update_preference_by_type(/datum/preference/flavor_texts, flavor)
			return PREF_UPDATE_ACCEPTED
		if("set_robot_flavor")
			var/list/robot_flavor = preferences.read_preference(/datum/preference/flavour_texts_robot) || list()
			robot_flavor[params["module"]] = strip_html_simple(params["text"])
			preferences.update_preference_by_type(/datum/preference/flavour_texts_robot, robot_flavor)
			return PREF_UPDATE_ACCEPTED
	return PREF_UPDATE_UNCHANGED
