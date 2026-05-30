/datum/mind
	var/vore_death = FALSE	// Was our last gasp a gurgle?
	var/show_in_directory
	var/directory_tag
	var/directory_erptag
	var/directory_ad
	var/vore_prey_eaten = 0
	var/vantag_preference = VANTAG_NONE
	var/directory_gendertag
	var/directory_sexualitytag

/mob/living/mind_initialize()
	. = ..()
	if (client?.prefs)
		// DQEdit — directory tags migrated from legacy /datum/preferences vars
		// to /datum/preference subtypes.
		mind.show_in_directory = client.prefs.read_preference(/datum/preference/toggle/human/show_in_directory)
		mind.directory_tag = client.prefs.read_preference(/datum/preference/choiced/human/directory_tag)
		mind.directory_erptag = client.prefs.read_preference(/datum/preference/choiced/human/directory_erptag)
		mind.directory_ad = client.prefs.read_preference(/datum/preference/text/human/directory_ad)
		mind.vantag_preference = client.prefs.read_preference(/datum/preference/choiced/human/vantag_preference)
		mind.directory_gendertag = client.prefs.read_preference(/datum/preference/choiced/human/directory_gendertag)
		mind.directory_sexualitytag = client.prefs.read_preference(/datum/preference/choiced/human/directory_sexualitytag)
