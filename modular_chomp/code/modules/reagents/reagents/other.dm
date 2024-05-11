/datum/reagent/space_cleaner/affect_touch(var/mob/living/carbon/M, var/alien, var/removed)
	..()
	if(alien == IS_RIFTWALKER)
		var/datum/species/riftwalker/RIFT = M.species
		RIFT.weakened = TRUE
