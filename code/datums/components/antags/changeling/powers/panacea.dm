/datum/power/changeling/panacea
	name = "Anatomic Panacea"
	desc = "Expels impurifications from our form; curing diseases, removing toxins, chemicals, radiation, and resetting our genetic code completely."
	helptext = "Can be used while unconscious.  This will also purge any reagents inside ourselves, both harmful and beneficial."
	enhancedtext = "We heal more toxins."
	ability_icon_state = "ling_anatomic_panacea"
	genomecost = 1
	verbpath = /mob/proc/changeling_panacea

//Heals the things that the other regenerative abilities don't.
/mob/proc/changeling_panacea()
	set category = "Changeling"
	set name = "Anatomic Panacea (20)"
	set desc = "Clense ourselves of impurities."

	var/datum/component/antag/changeling/changeling = changeling_power(20,0,100,UNCONSCIOUS)
	if(!changeling)
		return 0
	changeling.chem_charges -= 20

	to_chat(src, span_notice("We cleanse impurities from our form."))

	var/mob/living/carbon/human/C = src

	C.radiation = 0
	C.sdisabilities = 0
	C.disabilities = 0
	C.reagents.clear_reagents()
	C.ingested.clear_reagents()


	var/heal_amount = 5
	if(changeling.recursive_enhancement)
		heal_amount = heal_amount * 2
		to_chat(src, span_notice("We will heal much faster."))

	//TODO: Replace with a modifier.
	for(var/i = 0, i<10,i++)
		if(C)
			C.adjustToxLoss(-heal_amount)
			sleep(10)

	for(var/obj/item/organ/external/E in C.organs)
		var/obj/item/organ/external/G = E
		if(G.germ_level)
			var/germ_heal = heal_amount * 100
			G.germ_level = min(0, G.germ_level - germ_heal)

	for(var/obj/item/organ/internal/I in C.internal_organs)
		var/obj/item/organ/internal/G = I
		if(G.germ_level)
			var/germ_heal = heal_amount * 100
			G.germ_level = min(0, G.germ_level - germ_heal)

	feedback_add_details("changeling_powers","AP")
	return 1
