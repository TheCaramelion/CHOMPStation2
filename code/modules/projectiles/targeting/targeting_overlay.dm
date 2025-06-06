/obj/aiming_overlay
	name = ""
	desc = "Stick 'em up!"
	icon = 'icons/effects/Targeted.dmi'
	icon_state = "locking"
	anchored = TRUE
	density = FALSE
	opacity = 0
	plane = ABOVE_PLANE
	simulated = FALSE
	mouse_opacity = 0

	var/mob/living/aiming_at   // Who are we currently targeting, if anyone?
	var/obj/item/aiming_with   // What are we targeting with?
	var/mob/owner              // Who do we belong to?
	var/locked =    0          // Have we locked on?
	var/lock_time = 0          // When -will- we lock on?
	var/active =    0          // Is our owner intending to take hostages?
	var/target_permissions = 0 // Permission bitflags.

/obj/aiming_overlay/Initialize(mapload)
	. = ..()
	owner = loc
	if(!istype(owner))
		return INITIALIZE_HINT_QDEL
	moveToNullspace()
	verbs.Cut()

/obj/aiming_overlay/proc/toggle_permission(var/perm)

	if(target_permissions & perm)
		target_permissions &= ~perm
	else
		target_permissions |= perm

	// Update HUD icons.
	if(owner.gun_move_icon)
		if(!(target_permissions & TARGET_CAN_MOVE))
			owner.gun_move_icon.icon_state = "no_walk0"
			owner.gun_move_icon.name = "Allow Movement"
		else
			owner.gun_move_icon.icon_state = "no_walk1"
			owner.gun_move_icon.name = "Disallow Movement"

	if(owner.item_use_icon)
		if(!(target_permissions & TARGET_CAN_CLICK))
			owner.item_use_icon.icon_state = "no_item0"
			owner.item_use_icon.name = "Allow Item Use"
		else
			owner.item_use_icon.icon_state = "no_item1"
			owner.item_use_icon.name = "Disallow Item Use"

	if(owner.radio_use_icon)
		if(!(target_permissions & TARGET_CAN_RADIO))
			owner.radio_use_icon.icon_state = "no_radio0"
			owner.radio_use_icon.name = "Allow Radio Use"
		else
			owner.radio_use_icon.icon_state = "no_radio1"
			owner.radio_use_icon.name = "Disallow Radio Use"

	var/message = "no longer permitted to "
	var/use_span = "warning"
	if(target_permissions & perm)
		message = "now permitted to "
		use_span = "notice"

	switch(perm)
		if(TARGET_CAN_MOVE)
			message += "move"
		if(TARGET_CAN_CLICK)
			message += "use items"
		if(TARGET_CAN_RADIO)
			message += "use a radio"
		else
			return

	to_chat(owner, "<span class='[use_span]'>[aiming_at ? "The [aiming_at] is" : "Your targets are"] [message].</span>")
	if(aiming_at)
		to_chat(aiming_at, "<span class='[use_span]'>You are [message].</span>")

/obj/aiming_overlay/process()
	if(!owner)
		qdel(src)
		return
	..()
	update_aiming()

/obj/aiming_overlay/Destroy()
	if(aiming_at)
		aiming_at.aimed -= src
		aiming_at = null
	owner = null
	aiming_with = null
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/aiming_overlay/proc/update_aiming_deferred()
	set waitfor = 0
	sleep(0)
	update_aiming()

/obj/aiming_overlay/proc/update_aiming()

	if(!owner)
		qdel(src)
		return

	if(!aiming_at)
		cancel_aiming()
		return

	if(!locked && lock_time <= world.time)
		locked = 1
		to_chat(owner, span_notice("You are locked onto your target."))
		to_chat(aiming_at, span_danger("The gun is trained on you!"))
		update_icon()

	var/cancel_aim = 1

	var/mob/living/carbon/human/H = owner
	if(!(aiming_with in owner) || (istype(H) && !H.item_is_in_hands(aiming_with)))
		to_chat(owner, span_warning("You must keep hold of your weapon!"))
	else if(owner.eye_blind)
		to_chat(owner, span_warning("You are blind and cannot see your target!"))
	else if(!aiming_at || !istype(aiming_at.loc, /turf))
		to_chat(owner, span_warning("You have lost sight of your target!"))
	else if(owner.incapacitated() || owner.lying || owner.restrained())
		to_chat(owner, span_warning("You must be conscious and standing to keep track of your target!"))
	else if(aiming_at.alpha <= 50 || (aiming_at.invisibility > owner.see_invisible))
		to_chat(owner, span_warning("Your target has become invisible!"))
	else if(get_dist(get_turf(owner), get_turf(aiming_at)) > 7) // !(owner in viewers(aiming_at, 7))
		to_chat(owner, span_warning("Your target is too far away to track!"))
	else
		cancel_aim = 0

	forceMove(get_turf(aiming_at))

	if(cancel_aim)
		cancel_aiming()
		return

	if(!owner.incapacitated() && owner.client)
		spawn(0)
			owner.set_dir(get_dir(get_turf(owner), get_turf(src)))

/obj/aiming_overlay/proc/aim_at(var/mob/target, var/obj/thing)

	if(!owner)
		return

	if(owner.incapacitated())
		to_chat(owner, span_warning("You cannot aim a gun in your current state."))
		return
	if(owner.lying)
		to_chat(owner, span_warning("You cannot aim a gun while prone."))
		return
	if(owner.restrained())
		to_chat(owner, span_warning("You cannot aim a gun while handcuffed."))
		return
	if(target.alpha <= 50)
		to_chat(owner, span_warning("You cannot aim at something you cannot see."))
		return

	if(aiming_at)
		if(aiming_at == target)
			return
		aiming_at.aimed -= src
		owner.visible_message(span_danger("\The [owner] turns \the [thing] on \the [target]!"))
	else
		owner.visible_message(span_danger("\The [owner] aims \the [thing] at \the [target]!"))
	log_and_message_admins("aimed \a [thing] at [key_name(target)].")

	if(owner.client)
		owner.client.add_gun_icons()
	to_chat(target, span_danger("You now have a gun pointed at you. No sudden moves!"))
	to_chat(target, span_critical("If you fail to comply with your assailant, you accept the consequences of your actions."))
	aiming_with = thing
	aiming_at = target
	if(istype(aiming_with, /obj/item/gun))
		playsound(owner, 'sound/weapons/targeton.ogg', 50,1)
	forceMove(get_turf(target))
	START_PROCESSING(SSobj, src)

	aiming_at.aimed |= src
	toggle_active(1)
	locked = 0
	update_icon()
	lock_time = world.time + 25

/obj/aiming_overlay/update_icon()
	if(locked)
		icon_state = "locked"
	else
		icon_state = "locking"

/obj/aiming_overlay/proc/toggle_active(var/force_state = null)
	if(!isnull(force_state))
		if(active == force_state)
			return
		active = force_state
	else
		active = !active

	if(!active)
		cancel_aiming()

	if(owner.client)
		if(active)
			to_chat(owner, span_notice("You will now aim rather than fire."))
			owner.client.add_gun_icons()
		else
			to_chat(owner, span_notice("You will no longer aim rather than fire."))
			owner.client.remove_gun_icons()
		owner.gun_setting_icon?.icon_state = "gun[active]"

/obj/aiming_overlay/proc/cancel_aiming(var/no_message = 0)
	if(!aiming_with || !aiming_at)
		return
	if(istype(aiming_with, /obj/item/gun))
		playsound(owner, 'sound/weapons/targetoff.ogg', 50,1)
	if(!no_message)
		owner.visible_message(span_infoplain(span_bold("\The [owner]") + " lowers \the [aiming_with]."))

	aiming_with = null
	aiming_at.aimed -= src
	aiming_at = null
	loc = null
	STOP_PROCESSING(SSobj, src)
