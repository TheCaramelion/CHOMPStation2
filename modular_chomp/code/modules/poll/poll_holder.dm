/datum/poll_holder
	// Our polls!
	var/list/datum/poll/polls = list()

/datum/poll_holder/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/poll_holder/tgui_interact(mob/user, datum/tgui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PollHolder", "Poll Panel")
		ui.open()

/datum/poll_holder/tgui_data(mob/user)
	var/list/data = list()

	data["polls"] = polls
