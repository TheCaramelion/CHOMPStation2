/obj/screen/movable/ability_master/riftwalker
	name = "Riftwalker Abilities"
	icon = 'icons/mob/screen_spells.dmi'
	icon_state = "cult_spell_ready"
	ability_objects = list()
	showing = 0

	open_state = "const_door"
	closed_state = "const_grille"

	screen_loc = ui_spell_master

/obj/screen/movable/ability_master/riftwalker/update_abilities(forced = 0, mob/user)
	update_icon()
	if(user && user.client)
		if(!(src in user.client.screen))
			user.client.screen += src
	for(var/obj/screen/ability/ability in ability_objects)
		ability.update_icon(forced)

/obj/screen/ability/verb_based/riftwalker
	icon_state = "cult_spell_base"
	background_base_state = "cult"

/obj/screen/movable/ability_master/proc/add_riftwalker_ability(var/object_given, var/verb_given, var/name_given, var/ability_icon_given, var/arguments)
	if(!object_given)
		message_admins("ERROR: add_riftwalker_ability() was not given an object in its arguments.")
	if(!verb_given)
		message_admins("ERROR: add_riftwalker_ability() was not given a verb/proc in its arguments.")
	if(get_ability_by_proc_ref(verb_given))
		return // Duplicate
	var/obj/screen/ability/verb_based/riftwalker/A = new /obj/screen/ability/verb_based/riftwalker()
	A.ability_master = src
	A.object_used = object_given
	A.verb_to_call = verb_given
	A.ability_icon_state = ability_icon_given
	A.name = name_given
	if(arguments)
		A.arguments_to_use = arguments
	ability_objects.Add(A)
	if(my_mob.client)
		toggle_open(2)
