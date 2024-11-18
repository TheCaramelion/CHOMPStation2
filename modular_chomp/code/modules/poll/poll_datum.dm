/datum/poll
	// What are we asking
	var/question
	// If this poll is active or not
	var/active
	// The choices in it
	var/list/choices = list()
	// Associative list of [ckeys => choice]
	var/list/voted = list()

/datum/poll/New(var/_question, list/_choices)

	if(_question)
		question = _question
	if(_choices)
		choices = _choices

	active = TRUE

	if(!length(choices))
		CRASH("Attempted to start a poll with no choices!")

/datum/poll/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/poll/tgui_interact(mob/user, datum/tgui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PollPanel", "Poll")
		ui.open()

/datum/poll/tgui_data(mob/user)
	var/list/data = list()

	data["question"] = question
	data["choices"] = choices

	data["user_vote"] = null
	if(user.ckey in voted)
		data["user_vote"] = voted[user.ckey]

/datum/poll/tgui_act(action, list/params, datum/tgui/ui, datum/tgui_state/state)
	if(..())
		return

	. = TRUE

	switch(action)
		if("vote")
			if(params["target"] in choices)
				voted[usr.ckey] = params["target"]
			else
				message_admins("User [key_name_admin(usr)] spoofed a vote in the poll panel!")
