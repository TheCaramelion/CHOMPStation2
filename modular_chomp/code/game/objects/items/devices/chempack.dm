/obj/item/chempack
	name = "Chem-Pack"
	desc = "A device that delivers chemicals through a beam system. Progress, my friend!"
	icon = 'icons/obj/defibrillator.dmi'
	icon_state = "defibunit"
	item_state = "defibunit"
	slot_flags = SLOT_BACK
	force = 5
	throwforce = 6
	preserve_item = 1
	w_class = ITEMSIZE_LARGE

	var/obj/item/chem_hose/hose
	var/volume = 300

	pickup_sound = 'sound/items/pickup/device.ogg'
	drop_sound = 'sound/items/drop/device.ogg'

	flags = NOREACT

/obj/item/chempack/Initialize()
	..()
	create_reagents(volume)
	if(ispath(hose))
		hose = new hose(src, src)
		hose.owner = src
	else
		hose = new(src, src)
		hose.owner = src

/obj/item/chempack/Destroy(force, ...)
	. = ..()
	QDEL_NULL(hose)

/obj/item/chempack/ui_action_click(mob/user, actiontype)
	toggle_hose()

/obj/item/chempack/attack_hand(mob/living/user)
	if(loc == user)
		toggle_hose()
	else
		..()

/obj/item/chempack/MouseDrop()
	if(ismob(src.loc))
		if(!CanMouseDrop(src))
			return FALSE
		var/mob/M = src.loc
		if(!M.unEquip(src))
			return FALSE
		src.add_fingerprint(usr)
		M.put_in_any_hand_if_possible(src)

/obj/item/chempack/attackby(obj/item/W, mob/user, params)
	if(W == hose)
		reattach_hose(user)
		return TRUE
	else if(istype(W, /obj/item/reagent_containers/glass))
		var/obj/item/reagent_containers/glass/G = W
		if(reagents.total_volume == volume)
			balloon_alert(user, "\The [src] is full!")
			return FALSE
		G.reagents.trans_to_holder(reagents, G.amount_per_transfer_from_this)
		return TRUE

/obj/item/chempack/verb/toggle_hose()
	set name = "Toggle Hose"
	set category = "Object"

	var/mob/living/carbon/human/user = usr
	if(!hose)
		to_chat(user, span_warning("The hose is missing!"))
		return FALSE

	if(hose.loc != src)
		reattach_hose(user)
		return TRUE

	if(!slot_check())
		to_chat(user, span_warning("You need to equip [src] before taking out \the [hose]"))
		return FALSE
	else
		if(!user.put_in_hands(hose))
			to_chat(user, span_warning("You need a free hand to hold the hose!"))
			return FALSE

/obj/item/chempack/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return FALSE

	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_back) == src)
		return TRUE
	if((slot_flags & SLOT_BELT) && M.get_equipped_item(slot_belt) == src)
		return TRUE
	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_s_store) == src)
		return TRUE
	if((slot_flags & SLOT_BELT) && M.get_equipped_item(slot_s_store) == src)
		return TRUE

	return FALSE

/obj/item/chempack/dropped(mob/user)
	..()
	reattach_hose()

/obj/item/chempack/proc/reattach_hose(mob/user)
	if(!hose) return

	if(ismob(hose.loc))
		var/mob/M = hose.loc
		if(M.drop_from_inventory(hose, src))
			to_chat(user, span_notice("\The [hose] snaps back into the [src]"))
	else
		hose.forceMove(src)

// Hose

/obj/item/chem_hose
	name = "Chem-Pack Hose"
	desc = "A hose, with a handle and a lever. Aim at patient!"
	icon = 'icons/obj/defibrillator.dmi'
	icon_state = "defibpaddles0"
	item_state = "defibpaddles0"
	force = 2
	throwforce = 6
	w_class = ITEMSIZE_LARGE

	var/firing = FALSE
	var/hose_range = 5
	var/obj/item/chempack/owner = null
	var/mob/living/carbon/human/patient = null
	var/wielded = FALSE
	var/quantity = 1
	var/datum/beam/heal_beam

/obj/item/chem_hose/update_held_icon()
	var/mob/living/M = loc
	if(istype(M) && M.item_is_in_hands(src) && !M.hands_are_full())
		wielded = TRUE
		name = "[initial(name)] (wielded)"
	else
		wielded = FALSE
		name = initial(name)
		STOP_PROCESSING(SSobj, src)
	..()

/obj/item/chem_hose/dropped(mob/user)
	..()
	if(owner)
		owner.reattach_hose(user)
	STOP_PROCESSING(SSobj, src)

/obj/item/chem_hose/proc/can_use(mob/user, mob/M)
	if(!wielded)
		to_chat(user, span_warning("You need to wield the hose with both hands!"))
		return FALSE
	return TRUE

/obj/item/chem_hose/afterattack(atom/target, mob/user, proximity_flag, click_parameters)

	if(heal_beam)
		QDEL_NULL(heal_beam)

	STOP_PROCESSING(SSobj, src)

	if(target == user || target == target)
		return

	if(get_dist(target, user) > hose_range)
		return FALSE

	if(ishuman(target))
		patient = target
		user.face_atom(patient)

		playsound(src, 'sound/ambience/startup.ogg', 50, 1)
		if(do_after(user, 2 SECONDS))
			heal_beam = user.Beam(target, icon_state = "medbeam", time = 999999, maxdistance = hose_range)
			START_PROCESSING(SSobj, src)

/obj/item/chem_hose/process()
	if(!owner || !patient)
		STOP_PROCESSING(SSobj, src)

	if(src.loc == owner)
		STOP_PROCESSING(SSobj, src)

	if(get_dist(patient, src) > hose_range)
		STOP_PROCESSING(SSobj, src)

	if(owner.reagents.total_volume > 0)
		owner.reagents.trans_to_mob(patient, quantity)
		if(prob(25))
			playsound(src, 'sound/machines/generator/generator_mid3.ogg', 10, 1, -2)
