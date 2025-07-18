/obj/machinery/appliance/cooker/fryer
	name = "deep fryer"
	desc = "Deep fried <i>everything</i>."
	icon_state = "fryer_off"
	can_cook_mobs = 1
	cook_type = "deep fried"
	on_icon = "fryer_on"
	off_icon = "fryer_off"
	food_color = "#FFAD33"
	cooked_sound = 'sound/machines/ding.ogg'
	var/datum/looping_sound/deep_fryer/fry_loop
	circuit = /obj/item/circuitboard/fryer
	appliancetype = FRYER
	active_power_usage = 12 KILOWATTS
	heating_power = 12 KILOWATTS

	light_y = 15

	min_temp = 140 + T0C	// Same as above, increasing this to just under 2x to make the % increase on efficiency not quite so painful as it would be at 80.
	optimal_temp = 400 + T0C // Increasing this to be 2x Oven to allow for a much higher/realistic frying temperatures. Doesn't really do anything but make heating the fryer take a bit longer.
	optimal_power = 0.95 // .35 higher than the default to give fryers faster cooking speed.

	idle_power_usage = 3.6 KILOWATTS
	// Power used to maintain temperature once it's heated.
	// Going with 25% of the active power. This is a somewhat arbitrary value.

	resistance = 2 KILOWATTS	// Approx. 2 minutes to heat up.

	max_contents = 2
	container_type = /obj/item/reagent_containers/cooking_container/fryer

	stat = POWEROFF // Starts turned off

	tgui_id = "CookingFryer"

	var/datum/reagents/oil
	var/optimal_oil = 9000 //90 litres of cooking oil

/obj/machinery/appliance/cooker/fryer/Initialize(mapload)
	. = ..()
	fry_loop = new(list(src), FALSE)

	oil = new/datum/reagents(optimal_oil * 1.25, src)
	var/variance = rand()*0.15
	// Fryer is always a little below full, but its usually negligible

	if(prob(20))
		// Sometimes the fryer will start with much less than full oil, significantly impacting efficiency until filled
		variance = rand()*0.5
	oil.add_reagent(REAGENT_ID_COOKINGOIL, optimal_oil*(1 - variance))

/obj/machinery/appliance/cooker/fryer/Destroy()
	QDEL_NULL(fry_loop)
	QDEL_NULL(oil)
	return ..()

/obj/machinery/appliance/cooker/fryer/examine(var/mob/user)
	. = ..()
	if(Adjacent(user))
		to_chat(user, "Oil Level: [oil.total_volume]/[optimal_oil]")

/obj/machinery/appliance/cooker/fryer/update_icon() // We add our own version of the proc to use the special fryer double-lights.
	cut_overlays()
	var/image/light
	if(use_power == 1 && !stat)
		light = image(icon, "fryer_light_idle")
	else if(use_power == 2 && !stat)
		light = image(icon, "fryer_light_preheating")
	else
		light = image(icon, "fryer_light_off")
	light.pixel_x = light_x
	light.pixel_y = light_y
	add_overlay(light)

/obj/machinery/appliance/cooker/fryer/heat_up()
	if (..())
		//Set temperature of oil reagent
		var/datum/reagent/nutriment/triglyceride/oil/OL = oil.get_master_reagent()
		if (OL && istype(OL))
			OL.data["temperature"] = temperature

/obj/machinery/appliance/cooker/fryer/equalize_temperature()
	if (..())
		//Set temperature of oil reagent
		var/datum/reagent/nutriment/triglyceride/oil/OL = oil.get_master_reagent()
		if (OL && istype(OL))
			OL.data["temperature"] = temperature

/obj/machinery/appliance/cooker/fryer/update_cooking_power()
	..()//In addition to parent temperature calculation
	//Fryer efficiency also drops when oil levels arent optimal
	var/oil_level = 0
	var/datum/reagent/nutriment/triglyceride/oil/OL = oil.get_master_reagent()
	if(OL && istype(OL))
		oil_level = OL.volume

	var/oil_efficiency = 0
	if(oil_level)
		oil_efficiency = oil_level / optimal_oil

		if(oil_efficiency > 1)
			//We're above optimal, efficiency goes down as we pass too much over it
			oil_efficiency = 1 - (oil_efficiency - 1)


	cooking_power *= oil_efficiency

/obj/machinery/appliance/cooker/fryer/update_icon()
	if(!stat)
		..()
		if(cooking == TRUE)
			icon_state = on_icon
			if(fry_loop)
				fry_loop.start(src)
		else
			icon_state = off_icon
			if(fry_loop)
				fry_loop.stop(src)
	else
		icon_state = off_icon
		if(fry_loop)
			fry_loop.stop(src)
	..()

//Fryer gradually infuses any cooked food with oil. Moar calories
//This causes a slow drop in oil levels, encouraging refill after extended use
/obj/machinery/appliance/cooker/fryer/do_cooking_tick(var/datum/cooking_item/CI)
	if(..() && (CI.oil < CI.max_oil) && prob(20))
		var/datum/reagents/buffer = new /datum/reagents(2)
		oil.trans_to_holder(buffer, min(0.5, CI.max_oil - CI.oil))
		CI.oil += buffer.total_volume
		CI.container.soak_reagent(buffer)


//To solve any odd logic problems with results having oil as part of their compiletime ingredients.
//Upon finishing a recipe the fryer will analyse any oils in the result, and replace them with our oil
//As well as capping the total to the max oil
/obj/machinery/appliance/cooker/fryer/finish_cooking(var/datum/cooking_item/CI)
	..()
	var/total_oil = 0
	var/total_our_oil = 0
	var/total_removed = 0
	var/datum/reagent/our_oil = oil.get_master_reagent()

	for (var/obj/item/I in CI.container)
		if (I.reagents && I.reagents.total_volume)
			for (var/datum/reagent/R in I.reagents.reagent_list)
				if (istype(R, /datum/reagent/nutriment/triglyceride/oil))
					total_oil += R.volume
					if (R.id != our_oil.id)
						total_removed += R.volume
						I.reagents.remove_reagent(R.id, R.volume)
					else
						total_our_oil += R.volume


	if (total_removed > 0 || total_oil != CI.max_oil)
		total_oil = min(total_oil, CI.max_oil)

		if (total_our_oil < total_oil)
			//If we have less than the combined total, then top up from our reservoir
			var/datum/reagents/buffer = new /datum/reagents(INFINITY)
			oil.trans_to_holder(buffer, total_oil - total_our_oil)
			CI.container.soak_reagent(buffer)
		else if (total_our_oil > total_oil)

			//If we have more than the maximum allowed then we delete some.
			//This could only happen if one of the objects spawns with the same type of oil as ours
			var/portion = 1 - (total_oil / total_our_oil) //find the percentage to remove
			for (var/obj/item/I in CI.container)
				if (I.reagents && I.reagents.total_volume)
					for (var/datum/reagent/R in I.reagents.reagent_list)
						if (R.id == our_oil.id)
							I.reagents.remove_reagent(R.id, R.volume*portion)

/obj/machinery/appliance/cooker/fryer/cook_mob(var/mob/living/victim, var/mob/user)

	if(!istype(victim))
		return

	// user.visible_message(span_danger("\The [user] starts pushing \the [victim] into \the [src]!"))

	//Removed delay on this action in favour of a cooldown after it
	//If you can lure someone close to the fryer and grab them then you deserve success.
	//And a delay on this kind of niche action just ensures it never happens
	//Cooldown ensures it can't be spammed to instakill someone
	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN*3)

	fry_loop.start(src)

	if(!do_mob(user, victim, 20))
		cooking = FALSE
		icon_state = off_icon
		fry_loop.stop(src)
		return

	if(!victim || !victim.Adjacent(user))
		to_chat(user, span_danger("Your victim slipped free!"))
		cooking = FALSE
		icon_state = off_icon
		fry_loop.stop(src)
		return

	var/damage = rand(7,13) // Though this damage seems reduced, some hot oil is transferred to the victim and will burn them for a while after

	var/datum/reagent/nutriment/triglyceride/oil/OL = oil.get_master_reagent()
	damage *= OL.heatdamage(victim)

	var/obj/item/organ/external/E
	var/nopain
	if(ishuman(victim) && user.zone_sel.selecting != BP_GROIN && user.zone_sel.selecting != BP_TORSO)
		var/mob/living/carbon/human/H = victim
		E = H.get_organ(user.zone_sel.selecting)
		if(!E || E.data.get_species_flags() & NO_PAIN)
			nopain = 2
		else if(E.robotic >= ORGAN_ROBOT)
			nopain = 1

	user.visible_message(span_danger("\The [user] shoves \the [victim][E ? "'s [E.name]" : ""] into \the [src]!"))
	if (damage > 0)
		if(E)
			if(E.children && E.children.len)
				for(var/obj/item/organ/external/child in E.children)
					if(nopain && nopain < 2 && !(child.robotic >= ORGAN_ROBOT))
						nopain = 0
					child.take_damage(0, damage)
					damage -= (damage*0.5)//IF someone's arm is plunged in, the hand should take most of it
			E.take_damage(0, damage)
		else
			victim.apply_damage(damage, BURN, user.zone_sel.selecting)

		if(!nopain)
			to_chat(victim, span_danger("Agony consumes you as searing hot oil scorches your [E ? E.name : "flesh"] horribly!"))
			victim.emote("scream")
		else
			to_chat(victim, span_danger("Searing hot oil scorches your [E ? E.name : "flesh"]!"))

		user.attack_log += text("\[[time_stamp()]\] [span_red("Has [cook_type] \the [victim] ([victim.ckey]) in \a [src]")]")
		victim.attack_log += text("\[[time_stamp()]\] [span_orange("Has been [cook_type] in \a [src] by [user.name] ([user.ckey])")]")
		msg_admin_attack("[key_name_admin(user)] [cook_type] \the [victim] ([victim.ckey]) in \a [src]. (<A href='byond://?_src_=holder;[HrefToken()];adminplayerobservecoodjump=1;X=[user.x];Y=[user.y];Z=[user.z]'>JMP</a>)")

	//Coat the victim in some oil
	oil.trans_to(victim, 40)

	fry_loop.stop()

/obj/machinery/appliance/cooker/fryer/attackby(var/obj/item/I, var/mob/user)
	if(default_deconstruction_screwdriver(user, I)) //CHOMPedit - Allows for deconstruction
		return
	if(default_deconstruction_crowbar(user, I))
		return
	if(default_part_replacement(user, I))
		return
	if(istype(I, /obj/item/reagent_containers/glass) && I.reagents)
		if (I.reagents.total_volume <= 0 && oil)
			//Its empty, handle scooping some hot oil out of the fryer
			oil.trans_to(I, I.reagents.maximum_volume)
			user.visible_message(span_filter_notice("[user] scoops some oil out of \the [src]."), span_notice("You scoop some oil out of \the [src]."))
			return 1
		else
	//It contains stuff, handle pouring any oil into the fryer
	//Possibly in future allow pouring non-oil reagents in, in  order to sabotage it and poison food.
	//That would really require coding some sort of filter or better replacement mechanism first
	//So for now, restrict to oil only
			var/amount = 0
			for (var/datum/reagent/R in I.reagents.reagent_list)
				if (istype(R, /datum/reagent/nutriment/triglyceride/oil))
					var/delta = oil.get_free_space()
					delta = min(delta, R.volume)
					oil.add_reagent(R.id, delta)
					I.reagents.remove_reagent(R.id, delta)
					amount += delta
			if (amount > 0)
				user.visible_message(span_filter_notice("[user] pours some oil into \the [src]."), span_notice("You pour [amount]u of oil into \the [src]."), span_notice("You hear something viscous being poured into a metal container."))
				return 1
	//If neither of the above returned, then call parent as normal
	..()
