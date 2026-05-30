// DQEdit — AUTOHISS_* defines promoted to code/__defines/preferences.dm so they're shared
// with /datum/preference/text/human/autohiss.apply_to_human().

/mob/living/carbon/human/Login()
	..()
	update_hud()
	// VOREStation Add
	if(client.prefs) // Safety, just in case so we don't runtime.
		// DQEdit Start — migrated autohiss to /datum/preference
		switch(client.prefs.read_preference(/datum/preference/text/human/autohiss))
			if("Full")
				client.autohiss_mode = AUTOHISS_FULL
			if("Basic")
				client.autohiss_mode = AUTOHISS_BASIC
			if("Off")
				client.autohiss_mode = AUTOHISS_OFF
			else
				client.autohiss_mode = AUTOHISS_FULL
		// DQEdit End
		consider_birthday()
	// VOREStation Add
	if(species) species.handle_login_special(src)
	return
