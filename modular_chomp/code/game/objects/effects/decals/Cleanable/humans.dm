// Riftwalkers! Strong with blood, not with oil.
/obj/effect/decal/cleanable/gibs/Crossed(mob/living/carbon/human/perp)
	if(istype(perp.species, /datum/species/riftwalker))
		var/datum/species/riftwalker/RIFT = perp.species
		RIFT.state &= ~RW_WEAKENED
	..()

/obj/effect/decal/cleanable/gibs/robot/Crossed(mob/living/carbon/human/perp)
	if(istype(perp.species, /datum/species/riftwalker))
		return
	..()

/obj/effect/decal/cleanable/blood/Crossed(mob/living/carbon/human/perp)
	if(istype(perp.species, /datum/species/riftwalker))
		var/datum/species/riftwalker/RIFT = perp.species
		RIFT.state &= ~RW_WEAKENED
	..()

/obj/effect/decal/cleanable/blood/robot/Crossed(mob/living/carbon/human/perp)
	if(istype(perp.species, /datum/species/riftwalker))
		return
	..()
