/datum/power/changeling/mimicvoice
	name = "Mimic Voice"
	desc = "We shape our vocal glands to sound like a desired voice."
	helptext = "Will turn your voice into the name that you enter. We must constantly expend chemicals to maintain our form like this"
	ability_icon_state = "ling_mimic_voice"
	genomecost = 1
	verbpath = /mob/proc/changeling_mimicvoice

// Fake Voice

/mob/proc/changeling_mimicvoice()
	set category = "Changeling"
	set name = "Mimic Voice"
	set desc = "Shape our vocal glands to form a voice of someone we choose. We cannot regenerate chemicals when mimicing."


	var/datum/component/antag/changeling/changeling = changeling_power()
	if(!changeling)	return

	if(changeling.mimicing)
		changeling.mimicing = ""
		to_chat(src, span_notice("We return our vocal glands to their original location."))
		return

	var/mimic_voice = sanitize(tgui_input_text(src, "Enter a name to mimic.", "Mimic Voice", null, MAX_NAME_LEN), MAX_NAME_LEN)
	if(!mimic_voice)
		return

	changeling.mimicing = mimic_voice

	to_chat(src, span_notice("We shape our glands to take the voice of <b>[mimic_voice]</b>, this will stop us from regenerating chemicals while active."))
	to_chat(src, span_notice("Use this power again to return to our original voice and reproduce chemicals again."))

	feedback_add_details("changeling_powers","MV")

	spawn(0)
		while(src && src.mind && changeling && changeling.mimicing)
			changeling.chem_charges = max(changeling.chem_charges - 1, 0)
			sleep(40)
		if(src && src.mind && changeling)
			changeling.mimicing = ""
