/datum/unarmed_attack/claws/riftwalker
	attack_name = "riftwalker claws"
	attack_verb = list("slashed", "gored", "clawed", "stabbed")
	damage = 10
	shredding = 1

/datum/unarmed_attack/claws/riftwalker/apply_effects(var/mob/living/carbon/human/user, var/mob/living/carbon/human/target, var/armour, var/attack_damage, var/zone)
	..()

	var/datum/species/riftwalker/RIFT = user

	if(prob(5))
		target.reagents.add_reagent(RIFT.poison, 3)
