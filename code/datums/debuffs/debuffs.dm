/datum/status_effect/incapacitating
	tick_interval = -1
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	remove_on_fullheal = TRUE
	heal_flag_necessary = HEAL_CC_STATUS
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	return ..()

/datum/status_effect/incapacitating/on_apply()
	if(needs_update_stat ||issilicon(owner))
		owner.update_stat()
	return TRUE

/datum/status_effect/incapacitating/on_remove()
	if(needs_update_stat || issilicon(owner))
		owner.update_stat()

	return ..()

/datum/status_effect/incapacitating/weakened
	id = "weakened"

/datum/status_effect/incapacitating/weakened/on_apply()
	. = ..()
	if(!.)
		return
	owner.add_traits(list())
