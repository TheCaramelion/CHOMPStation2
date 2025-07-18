/datum/power/changeling/digital_camoflague
	name = "Digital Camoflauge"
	desc = "We evolve the ability to distort our form and proprtions, defeating common altgorthms used to detect lifeforms on cameras."
	helptext = "We cannot be tracked by camera while using this skill.  However, humans looking at us will find us.. uncanny.  We must constantly expend chemicals to maintain our form like this."
	ability_icon_state = "ling_digital_camo"
	genomecost = 1
	allowduringlesserform = TRUE
	verbpath = /mob/proc/changeling_digitalcamo

//Prevents AIs tracking you but makes you easily detectable to the human-eye.
/mob/proc/changeling_digitalcamo()
	set category = "Changeling"
	set name = "Toggle Digital Camoflague"
	set desc = "The AI can no longer track us, but we will look different if examined.  Has a constant cost while active."

	var/datum/component/antag/changeling/changeling = changeling_power()
	if(!changeling)
		return 0

	var/mob/living/carbon/human/C = src
	if(C.digitalcamo)
		to_chat(C, span_notice("We return to normal."))
	else
		to_chat(C, span_notice("We distort our form to prevent AI-tracking."))
	C.digitalcamo = !C.digitalcamo

	spawn(0)
		while(C && C.digitalcamo && C.mind && changeling)
			changeling.chem_charges = max(changeling.chem_charges - 1, 0)
			sleep(40)

	feedback_add_details("changeling_powers","CAM")
	return 1
