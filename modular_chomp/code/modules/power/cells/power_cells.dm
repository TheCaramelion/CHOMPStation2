/*
 * Crap
 */
/obj/item/cell/crap
	name = "\improper rechargable AA battery"
	desc = "You can't top the plasma top." //TOTALLY TRADEMARK INFRINGEMENT
	origin_tech = list(TECH_POWER = 0)
	icon_state = "crap"
	charge = 500
	maxcharge = 500
	matter = list(MAT_STEEL = 700, MAT_GLASS = 40)

/obj/item/cell/crap/empty
	charge = 0

/*
 * Robot
 */
/obj/item/cell/robot_station
	name = "standard robot power cell"
	charge = 7500
	maxcharge = 7500

/*
 * Syndicate
 */
/obj/item/cell/robot_syndi
	name = "syndicate robot power cell"
	description_fluff = "Almost as good as a hyper."
	icon_state = "b_sup" //We don't want roboticists confuse it with a low standard cell
	charge = 25000
	maxcharge = 25000

/*
 * Security Borg
 */
/obj/item/cell/secborg
	name = "security borg rechargable D battery"
	origin_tech = list(TECH_POWER = 0)
	icon_state = "secborg"
	charge = 2400
	maxcharge = 2400	//who the hell thought 6 shots was enough for a dogborg taser?
	matter = list(MAT_STEEL = 700, MAT_GLASS = 40)

/obj/item/cell/secborg/empty
	charge = 0

/*
 * APC
 */
/obj/item/cell/apc
	name = "heavy-duty power cell"
	origin_tech = list(TECH_POWER = 1)
	icon_state = "apc"
	charge = 5000
	maxcharge = 5000
	matter = list(MAT_STEEL = 700, MAT_GLASS = 50)

/*
 * High
 */
/obj/item/cell/high
	name = "high-capacity power cell"
	origin_tech = list(TECH_POWER = 2)
	icon_state = "b_hi"
	charge = 10000
	maxcharge = 10000
	matter = list(MAT_STEEL = 700, MAT_GLASS = 60)

/obj/item/cell/high/empty
	charge = 0

/*
 * Super
 */
/obj/item/cell/super
	name = "super-capacity power cell"
	origin_tech = list(TECH_POWER = 5)
	icon_state = "b_sup"
	charge = 20000
	maxcharge = 20000
	matter = list(MAT_STEEL = 700, MAT_GLASS = 70)

/obj/item/cell/super/empty
	charge = 0

/*
 * Hyper
 */
/obj/item/cell/hyper
	name = "hyper-capacity power cell"
	origin_tech = list(TECH_POWER = 6)
	icon_state = "b_hy"
	charge = 30000
	maxcharge = 30000
	matter = list(MAT_STEEL = 700, MAT_GLASS = 80)

/obj/item/cell/hyper/empty
	charge = 0

/*
 * Giga
 */
/obj/item/cell/giga
	name = "giga-capacity power cell"
	origin_tech = list(TECH_POWER = 8)
	icon_state = "meb_b_hi"
	charge = 40000
	maxcharge = 40000
	matter = list(MAT_STEEL = 1000, MAT_GLASS = 100)

/obj/item/cell/giga/empty
	charge = 0
/*
 * Mecha
 */
/obj/item/cell/mech
	name = "mecha power cell"
	icon_state = "exs_s"
	charge = 15000
	maxcharge = 15000
	matter = list(MAT_STEEL = 800, MAT_GLASS = 60)

/obj/item/cell/mech/high
	name = "high-capacity mecha power cell"
	origin_tech = list(TECH_POWER = 3)
	icon_state = "exs_m"
	charge = 20000
	maxcharge = 20000
	matter = list(MAT_STEEL = 800, MAT_GLASS = 80)

/obj/item/cell/mech/super
	name = "super-capacity mecha power cell"
	origin_tech = list(TECH_POWER = 6)
	icon_state = "exs_l"
	charge = 25000
	maxcharge = 25000
	matter = list(MAT_STEEL = 800, MAT_GLASS = 100)

/*
 * Infinite
 */
/obj/item/cell/infinite
	name = "infinite-capacity power cell!"
	icon_state = "infinite_b"
	origin_tech =  null
	charge = 30000
	maxcharge = 30000 //determines how badly mobs get shocked
	matter = list(MAT_STEEL = 700, MAT_GLASS = 80)

/obj/item/cell/infinite/check_charge()
	return 1

/obj/item/cell/infinite/use()
	return 1

/*
 * Potato
 */
/obj/item/cell/potato
	name = "potato battery"
	desc = "A rechargable starch based power cell."
	origin_tech = list(TECH_POWER = 0)
	icon_state = "potato"
	charge = 100
	maxcharge = 300
	minor_fault = 1

/*
 * Slime
 */
/obj/item/cell/slime
	name = "charged slime core"
	desc = "A yellow slime core infused with phoron, it crackles with power."
	origin_tech = list(TECH_POWER = 4, TECH_BIO = 5)
	icon = 'icons/mob/slimes.dmi' //'icons/obj/harvest.dmi'
	icon_state = "yellow slime extract" //"potato_battery"
	description_info = "This 'cell' holds a max charge of 20k and self recharges over time."
	charge = 20000
	maxcharge = 20000
	charge_amount = 500 // 2.5%.
	matter = null
	self_recharge = TRUE
	standard_overlays = FALSE

/*
 * Emergency Light
 */
/obj/item/cell/emergency_light
	name = "miniature power cell"
	desc = "A tiny power cell with a very low power capacity. Used in light fixtures to power them in the event of an outage."
	charge = 360
	maxcharge = 360 //Emergency lights use 0.2 W per tick, meaning ~30 minutes of emergency power from a cell
	matter = list(MAT_GLASS = 20)
	icon_state = "em_light"
	w_class = ITEMSIZE_TINY

/obj/item/cell/emergency_light/Initialize(mapload)
	. = ..()
	var/area/A = get_area(src)
	if(!A.lightswitch || !A.light_power)
		charge = 0 //For naturally depowered areas, we start with no power

/*
 * Backup Battery
 *
 * Not actually a cell, but if people look for it, they'll probably look near other cells
 */
/obj/item/fbp_backup_cell
	name = "backup battery"
	desc = "A small one-time-use chemical battery for synthetic crew when they are low on power in emergency situations."
	icon = 'icons/obj/power_cells.dmi'
	icon_state = "backup"
	w_class = ITEMSIZE_SMALL
	var/amount = 100
	var/used = FALSE

/obj/item/fbp_backup_cell/Initialize(mapload)
	. = ..()
	add_overlay("[icon_state]_100")

/obj/item/fbp_backup_cell/attack(mob/living/M as mob, mob/user as mob)
	if(!used && ishuman(M))
		var/mob/living/carbon/human/H = M
		if(H.isSynthetic())
			if(H.nutrition <= amount)
				use(user,H)
			else
				to_chat(user,span_warning("The difference in potential is too great. [user == M ? "You have" : "[H] has"] too much charge to use such a small battery."))
		else if(M == user)
			to_chat(user,span_warning("You lick the cell, and your tongue tingles slightly."))
		else
			to_chat(user,span_warning("This cell is meant for use on humanoid synthetics only."))

	. = ..()

/obj/item/fbp_backup_cell/proc/use(var/mob/living/user, var/mob/living/target)
	if(used)
		return
	used = TRUE
	desc += " This one has already been used."
	cut_overlays()
	target.adjust_nutrition(amount)
	user.custom_emote(message = "connects \the [src] to [user == target ? "their" : "[target]'s"] charging port, expending it.")
