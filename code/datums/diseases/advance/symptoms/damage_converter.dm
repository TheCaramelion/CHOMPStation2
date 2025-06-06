/*
//////////////////////////////////////

Damage Converter

	Little bit hidden.
	Lowers resistance tremendously.
	Decreases stage speed tremendously.
	Reduced transmittablity
	Intense Level.

Bonus
	Slowly converts brute/fire damage to toxin.

//////////////////////////////////////
*/

/datum/symptom/damage_converter
	name = "Toxic Compensation"
	stealth = 1
	resistance = -4
	stage_speed = -4
	transmission = -2
	level = 4
	severity = 0

/datum/symptom/damage_converter/Activate(datum/disease/advance/A)
	..()
	if(prob(SYMPTOM_ACTIVATION_PROB * 10))
		var/mob/living/M = A.affected_mob
		switch(A.stage)
			if(4, 5)
				Convert(M)
	return

/datum/symptom/damage_converter/proc/Convert(mob/living/M)

	var/get_damage = rand(1, 2)

	if(ishuman(M))
		var/mob/living/carbon/human/H = M

		var/list/parts = H.get_damaged_organs(TRUE, TRUE)

		if(!length(parts))
			return
		var/healed = 0
		for(var/obj/item/organ/external/E in parts)
			healed += min(E.brute_dam, get_damage) + min(E.burn_dam, get_damage)
			E.heal_damage(get_damage, get_damage, 0, 0)
		M.adjustToxLoss(healed)

	else
		if(M.getFireLoss() > 0 || M.getBruteLoss() > 0)
			M.adjustFireLoss(-get_damage)
			M.adjustBruteLoss(-get_damage)
			M.adjustToxLoss(get_damage)
		else
			return
	return TRUE
