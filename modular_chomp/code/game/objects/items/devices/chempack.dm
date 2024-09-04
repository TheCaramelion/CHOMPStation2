/obj/item/device/chempack_kit
	name = "chem-pack"
	desc = "A large tank that holds chemicals and a hose attachment, for quick appliance."
	slot_flags = SLOT_BACK
	w_class = ITEMSIZE_LARGE
	origin_tech = list(TECH_BIO = 6, TECH_POWER = 4)
	preserve_item = TRUE
	action_button_name = "Remove/Replace Hose"

	icon = 'icons/obj/defibrillator.dmi'
	icon_state = "defibunit"
	item_state = "defibunit"

	var/obj/item/weapon/chempack_hose/hose
	var/obj/item/weapon/reagent_containers/glass/beaker/beaker

/obj/item/device/chempack_kit/Initialize()
	..()
	if(ispath(hose))
		hose = new hose(src, src)
	else
		hose = new(src, src)

	beaker = new /obj/item/weapon/reagent_containers/glass/beaker/large(src)

/obj/item/device/chempack_kit/Destroy()
	. = ..()
	QDEL_NULL(hose)

/obj/item/device/chempack_kit/update_icon()

/obj/item/device/chempack_kit/ui_action_click()
	toggle_hose()

/obj/item/device/chempack_kit/attack_hand(mob/user)
	if(loc == user)
		toggle_hose()
	else
		..()

/obj/item/device/chempack_kit/MouseDrop()
	if(ismob(src.loc))
		if(!CanMouseDrop(src))
			return
		var/mob/M = src.loc
		if(!M.unEquip(src))
			return
		src.add_fingerprint(usr)
		M.put_in_any_hand_if_possible(src)

/obj/item/device/chempack_kit/attackby(obj/item/weapon/W, mob/user, params)
	if(W == hose)
		reattach_hose(user)
	else if(istype(W, /obj/item/weapon/reagent_containers/glass))
		if(beaker)
			to_chat(user, SPAN_NOTICE("\The [src] already has a beaker!"))
		else
			if(!user.unEquip(W))
				return
			W.forceMove(src)
			beaker = W
			to_chat(user, SPAN_NOTICE("You place the beaker in \the [src]"))
			update_icon()
	else
		return ..()

// Hose stuff

/obj/item/device/chempack_kit/verb/toggle_hose()
	set name = "Toggle Hose"
	set category = "Object"

	var/mob/living/carbon/human/user = usr
	if(!hose)
		to_chat(user, SPAN_WARNING("The hose is missing!"))
		return

	if(hose.loc != src)
		reattach_hose(user)
		return

	if(!slot_check())
		to_chat(user, SPAN_WARNING("You need to equip [src] before taking the [hose] out!"))
	else
		if(!user.put_in_hands(hose))
			to_chat(user, SPAN_WARNING("You need a free hand to hold the hose!"))
		update_icon()

/obj/item/device/chempack_kit/proc/slot_check()
	var/mob/M = loc
	if(!istype(M))
		return FALSE

	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_back) == src)
		return TRUE
	if((slot_flags & SLOT_BACK) && M.get_equipped_item(slot_s_store) == src)
		return TRUE

	return FALSE

/obj/item/device/chempack_kit/dropped(mob/user)
	..()
	reattach_hose(user)

/obj/item/device/chempack_kit/proc/reattach_hose(mob/user)
	if(!hose) return

	if(ismob(hose.loc))
		var/mob/M = hose.loc
		if(M.drop_from_inventory(hose, src))
			to_chat(user, SPAN_NOTICE("\The [hose] snap back to it's place!"))
	else
		hose.forceMove(src)

	update_icon()

/obj/item/weapon/chempack_hose
	name = "chem-Pack attachment"
	desc = "A hose attached to a tank stuffed with chemicals on your back. You have no idea if it will work."
	force = 2
	throwforce = 6
	w_class = ITEMSIZE_LARGE

	icon = 'icons/obj/defibrillator.dmi'
	icon_state = "defibpaddles"
	item_state = "defibpaddles"

	var/using = FALSE
	var/obj/item/device/chempack_kit/linked_kit
	var/mob/living/carbon/human/patient
	var/datum/beam/heal_beam

/obj/item/weapon/chempack_hose/New(newloc, obj/item/device/chempack_kit/chempack)
	linked_kit = chempack
	..(newloc)

/obj/item/weapon/chempack_hose/Destroy()
	if(linked_kit)
		if(linked_kit.hose == src)
			linked_kit.hose = null
			linked_kit.update_icon()
		linked_kit = null
	using = FALSE
	return ..()

/obj/item/weapon/chempack_hose/dropped(mob/user)
	..()
	if(linked_kit)
		linked_kit.reattach_hose(user)
	using = FALSE
	STOP_PROCESSING(SSobj, src)

/obj/item/weapon/chempack_hose/update_held_icon()
	var/mob/living/M = loc
	if(istype(M) && M.item_is_in_hands(src) && !M.hands_are_full())
		name = "[initial(name)] (wielded)"
	else
		name = initial(name)
	update_icon()
	..()

/obj/item/weapon/chempack_hose/proc/can_use(mob/user, mob/M)
	if(M.stat == DEAD)
		return FALSE
	/*
	if(!check_chems())
		return FALSE
	*/
	return TRUE

/obj/item/weapon/chempack_hose/afterattack(atom/target, mob/user, proximity_flag = 6)
	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target

	if(!can_use(user, H))
		return

	patient = H
	heal_beam = user.Beam(target, icon_state = "lightning9", time = 200, maxdistance = 6, beam_color = null)
	START_PROCESSING(SSobj, src)

/obj/item/weapon/chempack_hose/process()
	if(can_use())

	else
		STOP_PROCESSING(SSobj, src)
		heal_beam.End()
