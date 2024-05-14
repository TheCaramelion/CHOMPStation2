// De-Phase

/mob/living/carbon/human/proc/riftwalker_dephase(var/turf/T = null, atom/dephaser)

	var/datum/species/riftwalker/RIFT = species

	if(!T)
		T = get_turf(src)

	if(!istype(RIFT) || RIFT.state & RW_BLOODCRAWLING || !T.CanPass(src, T) || loc != T || !(ability_flags & AB_PHASE_SHIFTED))
		return FALSE

	if(dephaser)
		log_admin("[key_name_admin(src)] was stunned out of phase at [T.x],[T.y],[T.z] by [dephaser.name], last touched by [dephaser.fingerprintslast].")
		message_admins("[key_name_admin(src)] was stunned out of phase at [T.x],[T.y],[T.z] by [dephaser.name], last touched by [dephaser.fingerprintslast]. (<A HREF='?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[T.x];Y=[T.y];Z=[T.z]'>JMP</a>)", 1)

	riftwalker_phase_out(T)

	src.Weaken(3)

// Petrify related stuff

/datum/species/riftwalker/proc/petrify_riftwalker(mob/living/carbon/human/H)
	/*	Yeah this is uh- Not good.
	 *	But somehow ghosting and reentering the body makes it work?
	*	So for now I'll leave this here
	*/
	if(H.client)
		var/mob/observer/dead/ghost = H.client.mob
		ghost = H.ghostize(1)
		ghost.reenter_corpse()
	new /obj/structure/gargoyle(H.loc, H, "statue", "bloodstone", "petrifies", "#E62013", TRUE, TRUE)

	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_transformation)
	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_pause)
	remove_verb(H,/mob/living/carbon/human/proc/gargoyle_checkenergy)

	remove_riftwalker_abilities(H)

	add_verb(H,/mob/living/carbon/human/proc/riftwalker_statue_sacrifice)
	add_verb(H,/mob/living/carbon/human/proc/riftwalker_surrender)

	spawn(5 MINUTES)
	if(state & RW_PETRIFIED)
		H.riftwalker_surrender()

/mob/living/carbon/human/proc/riftwalker_statue_sacrifice()
	set name = "Statue Sacrifice"
	set category = "Abilities.Riftwalker"
	set desc = "Sacrifice a nearby entity to regain your power"

	var/datum/species/riftwalker/RIFT = species

	var/obj/structure/gargoyle/statue = src.loc
	var/mob/living/sacrifices = statue.living_mobs(2, TRUE)

	var/mob/living/chosen_one = tgui_input_list(usr, "Choose a victim", "Sacrifice", sacrifices)

	if(!chosen_one)
		to_chat(src, "<span class='warning'>There is no living beings nearby</span>")
		return
	else
		statue.Beam(chosen_one, icon_state = "blood", time = 30 SECONDS, maxdistance=3)
		if(do_after(src, 30 SECONDS, chosen_one, FALSE, TRUE, INCAPACITATION_NONE, TRUE, 2, FALSE))
			chosen_one.gib()
			remove_verb(src,/mob/living/carbon/human/proc/riftwalker_statue_sacrifice)
			remove_verb(src,/mob/living/carbon/human/proc/riftwalker_surrender)
			RIFT.add_riftwalker_abilities(src)
			RIFT.state &= ~RW_PETRIFIED
			halloss = 0
			bruteloss = bruteloss/2
			toxloss = toxloss/2
			fireloss = fireloss/2
			cloneloss = cloneloss/2
			vessel.add_reagent("blood", RIFT.blood_volume - vessel.total_volume)
			for(var/obj/item/organ/external/bp in src.organs)
				bp.bandage()
				bp.disinfect()

			BITRESET(src.hud_updateflag, HEALTH_HUD)
			BITRESET(src.hud_updateflag, STATUS_HUD)
			BITRESET(src.hud_updateflag, LIFE_HUD)

			riftwalker_adjust_blood(100)
			adjust_nutrition(250)

			sleep(5 SECONDS)
			statue.unpetrify(FALSE, TRUE)

/mob/living/carbon/human/proc/riftwalker_surrender()
	set name = "Statue Surrender"
	set category = "Abilities.Riftwalker"
	set desc = "Surrender and give in..."

	var/obj/structure/gargoyle/statue = src.loc
	var/obj/effect/decal/cleanable/ash/dust = new /obj/effect/decal/cleanable/ash(statue.loc)
	var/datum/species/riftwalker/RIFT = species

	dust.color = "#E62013"
	dust.name = "bloodstone dust"

	remove_verb(src,/mob/living/carbon/human/proc/riftwalker_statue_sacrifice)
	remove_verb(src,/mob/living/carbon/human/proc/riftwalker_surrender)
	RIFT.add_riftwalker_abilities(src)

	for(var/obj/item/I in src)
		src.drop_from_inventory(I, statue.loc)

	var/mob/living/dominated_brain/db = locate(/mob/living/dominated_brain/) in src.contents

	if(db)
		riftwalker_release()

	RIFT.handle_death()

	balloon_alert_visible("Crumbles into dust...")
	statue.Destroy()

// Found out the real name? DESTROY them

/mob/living/carbon/human/check_mentioned(message)
	if(get_species() == SPECIES_RIFTWALKER)
		if(findtext(message, nickname))
			riftwalker_cripple()
	..()

/mob/living/carbon/human/proc/riftwalker_cripple()
	var/datum/species/riftwalker/RIFT = species

	to_chat(src, "<span class='warning'>Your true name has been found; Your powers are temporarily limited by this.</span>")
	riftwalker_dephase()
	if(cloaked)
		uncloak()
	RIFT.state |= RW_NAME_REVEALED

	spawn(5 MINUTES)
		RIFT.state &= ~RW_NAME_REVEALED

// Many things breaks Rift cloaks

/mob/living/carbon/human/attack_hand(mob/user)
	break_cloak()
	. = ..()

/mob/living/carbon/human/hitby(atom/movable/AM, speed)
	break_cloak()
	. = ..()

/mob/living/carbon/human/bullet_act(obj/item/projectile/P, def_zone)
	break_cloak()
	. = ..()

/mob/living/carbon/human/hit_with_weapon(obj/item/I, mob/living/user, effective_force, hit_zone)
	break_cloak()
	. = ..()

/mob/living/carbon/human/standard_weapon_hit_effects(obj/item/I, mob/living/user, effective_force, blocked, soaked, hit_zone)
	break_cloak()
	. = ..()
