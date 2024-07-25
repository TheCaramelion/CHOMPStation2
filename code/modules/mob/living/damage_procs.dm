
/*
	apply_damage(a,b,c)
	args
	a:damage - How much damage to take
	b:damage_type - What type of damage to take, brute, burn
	c:def_zone - Where to take the damage if its brute or burn
	Returns
	standard 0 if fail
*/
/*
/mob/living/proc/apply_damage(var/damage = 0,var/damagetype = BRUTE, var/def_zone = null, var/blocked = 0, var/soaked = 0, var/used_weapon = null, var/sharp = FALSE, var/edge = FALSE, var/obj/used_weapon = null)
	if(Debug2)
		to_world_log("## DEBUG: apply_damage() was called on [src], with [damage] damage, and an armor value of [blocked].")
	if(!damage || (blocked >= 100))
		return 0
	for(var/datum/modifier/M in modifiers) //MODIFIER STUFF. It's best to do this RIGHT before armor is calculated, so it's done here! This is the 'forcefield' defence.
		if(damagetype == BRUTE && (!isnull(M.effective_brute_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_brute_resistance
			continue
		if((damagetype == BURN || damagetype == ELECTROCUTE)&& (!isnull(M.effective_fire_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_fire_resistance
			continue
		if(damagetype == TOX && (!isnull(M.effective_tox_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_tox_resistance
			continue
		if(damagetype == OXY && (!isnull(M.effective_oxy_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_oxy_resistance
			continue
		if(damagetype == CLONE && (!isnull(M.effective_clone_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_clone_resistance
			continue
		if(damagetype == HALLOSS && (!isnull(M.effective_hal_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			damage = damage * M.effective_hal_resistance
			continue
		if(damagetype == SEARING && (!isnull(M.effective_fire_resistance) || !isnull(M.effective_brute_resistance)))
			if(M.energy_based)
				M.energy_source.use(M.damage_cost * damage)
			var/damage_mitigation = 0//Used for dual calculations.
			if(!isnull(M.effective_fire_resistance))
				damage_mitigation += round((1/3)*damage * M.effective_fire_resistance)
			if(!isnull(M.effective_brute_resistance))
				damage_mitigation += round((2/3)*damage * M.effective_brute_resistance)
			damage -= damage_mitigation
			continue
		if(damagetype == BIOACID && (isSynthetic() && (!isnull(M.effective_fire_resistance))) || (!isSynthetic() && M.effective_tox_resistance))
			if(isSynthetic())
				damage = damage * M.effective_fire_resistance
			else
				damage = damage * M.effective_tox_resistance
			continue
	if(soaked)
		if(soaked >= round(damage*0.8))
			damage -= round(damage*0.8)
		else
			damage -= soaked

	var/initial_blocked = blocked

	blocked = (100-blocked)/100
	switch(damagetype)
		if(BRUTE)
			adjustBruteLoss(damage * blocked)
		if(BURN)
			if(COLD_RESISTANCE in mutations)
				damage = 0
			adjustFireLoss(damage * blocked)
		if(SEARING)
			apply_damage(round(damage / 3), BURN, def_zone, initial_blocked, soaked, used_weapon, sharp, edge)
			apply_damage(round(damage / 3 * 2), BRUTE, def_zone, initial_blocked, soaked, used_weapon, sharp, edge)
		if(TOX)
			adjustToxLoss(damage * blocked)
		if(OXY)
			adjustOxyLoss(damage * blocked)
		if(CLONE)
			adjustCloneLoss(damage * blocked)
		if(HALLOSS)
			adjustHalLoss(damage * blocked)
		if(ELECTROCUTE)
			electrocute_act(damage, used_weapon, 1.0, def_zone)
		if(BIOACID)
			if(isSynthetic())
				apply_damage(damage, BURN, def_zone, initial_blocked, soaked, used_weapon, sharp, edge)	// Handle it as normal burn.
			else
				adjustToxLoss(damage * blocked)
		if(ELECTROMAG)
			damage = damage * blocked
			switch(round(damage))
				if(91 to INFINITY)
					emp_act(1)
				if(76 to 90)
					if(prob(50))
						emp_act(1)
					else
						emp_act(2)
				if(61 to 75)
					emp_act(2)
				if(46 to 60)
					if(prob(50))
						emp_act(2)
					else
						emp_act(3)
				if(31 to 45)
					emp_act(3)
				if(16 to 30)
					if(prob(50))
						emp_act(3)
					else
						emp_act(4)
				if(0 to 15)
					emp_act(4)
	flash_weak_pain()
	updatehealth()
	return 1
*/

/mob/living/proc/apply_damages(var/brute = 0, var/burn = 0, var/tox = 0, var/oxy = 0, var/clone = 0, var/halloss = 0, var/def_zone = null, var/blocked = 0)
	if(blocked >= 100)
		return 0
	// INSERT MODIFIER CODE HERE... But no, really, only two things in the game use it, quad and viruses. The former is admin-only and the latter wouldn't be affected logically, but would if shield code was inerted here. If you really want, you can copy&paste the above and modify it to adjust brute/burn/etc. I do not advise this however.
	if(brute)	apply_damage(brute, BRUTE, def_zone, blocked)
	if(burn)	apply_damage(burn, BURN, def_zone, blocked)
	if(tox)		apply_damage(tox, TOX, def_zone, blocked)
	if(oxy)		apply_damage(oxy, OXY, def_zone, blocked)
	if(clone)	apply_damage(clone, CLONE, def_zone, blocked)
	if(halloss) apply_damage(halloss, HALLOSS, def_zone, blocked)
	return 1



/mob/living/proc/apply_effect(var/effect = 0,var/effecttype = STUN, var/blocked = 0, var/check_protection = 1)
	if(Debug2)
		to_world_log("## DEBUG: apply_effect() was called.  The type of effect is [effecttype].  Blocked by [blocked].")
	if(!effect || (blocked >= 100))
		return 0
	blocked = (100-blocked)/100

	switch(effecttype)
		if(STUN)
			Stun(effect * blocked)
		if(WEAKEN)
			Weaken(effect * blocked)
		if(PARALYZE)
			Paralyse(effect * blocked)
		if(AGONY)
			halloss += max((effect * blocked), 0) // Useful for objects that cause "subdual" damage. PAIN!
		if(IRRADIATE)
		/*
			var/rad_protection = check_protection ? getarmor(null, "rad")/100 : 0
			radiation += max((1-rad_protection)*effect/(blocked+1),0)//Rads auto check armor
		*/
			var/rad_protection = getarmor(null, "rad")
			rad_protection = (100-rad_protection)/100
			radiation += max((effect * rad_protection), 0)
		if(STUTTER)
			if(status_flags & CANSTUN) // stun is usually associated with stutter
				stuttering = max(stuttering,(effect * blocked))
		if(EYE_BLUR)
			eye_blurry = max(eye_blurry,(effect * blocked))
		if(DROWSY)
			drowsyness = max(drowsyness,(effect * blocked))
	updatehealth()
	return 1

/**
 * Applies damage to this mob.
 *
 * Sends [COMSIG_MOB_APPLY_DAMAGE]
 *
 * Arguuments:
 * * damage - Amount of damage
 * * damagetype - What type of damage to do. one of [BRUTE], [BURN], [TOX], [OXY], [STAMINA], [BRAIN].
 * * def_zone - What body zone is being hit. Or a reference to what bodypart is being hit.
 * * blocked - Percent modifier to damage. 100 = 100% less damage dealt, 50% = 50% less damage dealt.
 * * forced - "Force" exactly the damage dealt. This means it skips damage modifier from blocked.
 * * spread_damage - For carbons, spreads the damage across all bodyparts rather than just the targeted zone.
 * * wound_bonus - Bonus modifier for wound chance.
 * * bare_wound_bonus - Bonus modifier for wound chance on bare skin.
 * * sharpness - Sharpness of the weapon.
 * * attack_direction - Direction of the attack from the attacker to [src].
 * * attacking_item - Item that is attacking [src].
 *
 * Returns the amount of damage dealt.
 */
/mob/living/proc/apply_damage(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	blocked = 0,
	forced = FALSE,
	spread_damage = FALSE,
	wound_bonus = 0,
	bare_wound_bonus = 0,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
)
	SHOULD_CALL_PARENT(TRUE)
	var/damage_amount = damage
	if(!forced)
		damage_amount *= ((100 - blocked) / 100)
		damage_amount *= get_incoming_damage_modifier(damage_amount, damagetype, def_zone, sharpness, attack_direction, attacking_item)
	if(damage_amount <= 0)
		return 0

	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE, damage_amount, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item)

	var/damage_dealt = 0
	switch(damagetype)
		if(BRUTE)
			if(isbodypart(def_zone))
				var/obj/item/organ/external/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				/*
				if(actual_hit.receive_damage(
					brute = damage_amount,
					burn = 0,
					forced = forced,
					wound_bonus = wound_bonus,
					bare_wound_bonus = bare_wound_bonus,
					sharpness = sharpness,
					attack_direction = attack_direction,
					damage_source = attacking_item,
				))
				*/
				damage_dealt = actual_hit.get_damage() - delta // Unfortunately bodypart receive_damage doesn't return damage dealt so we do it manually
			else
				damage_dealt = -1 * adjustBruteLoss(damage_amount, forced = forced)
		if(BURN)
			if(isbodypart(def_zone))
				var/obj/item/organ/external/actual_hit = def_zone
				var/delta = actual_hit.get_damage()
				/*
				if(actual_hit.receive_damage(
					brute = 0,
					burn = damage_amount,
					forced = forced,
					wound_bonus = wound_bonus,
					bare_wound_bonus = bare_wound_bonus,
					sharpness = sharpness,
					attack_direction = attack_direction,
					damage_source = attacking_item,
				))
				*/
				damage_dealt = actual_hit.get_damage() - delta // See above
			else
				damage_dealt = -1 * adjustFireLoss(damage_amount, forced = forced)
		if(TOX)
			damage_dealt = -1 * adjustToxLoss(damage_amount, forced = forced)
		if(OXY)
			damage_dealt = -1 * adjustOxyLoss(damage_amount, forced = forced)

	SEND_SIGNAL(src, COMSIG_MOB_AFTER_APPLY_DAMAGE, damage_dealt, damagetype, def_zone, blocked, wound_bonus, bare_wound_bonus, sharpness, attack_direction, attacking_item)
	return damage_dealt

/**
 * Used in tandem with [/mob/living/proc/apply_damage] to calculate modifier applied into incoming damage
 */
/mob/living/proc/get_incoming_damage_modifier(
	damage = 0,
	damagetype = BRUTE,
	def_zone = null,
	sharpness = NONE,
	attack_direction = null,
	attacking_item,
)
	SHOULD_CALL_PARENT(TRUE)
	SHOULD_BE_PURE(TRUE)

	var/list/damage_mods = list()
	SEND_SIGNAL(src, COMSIG_MOB_APPLY_DAMAGE_MODIFIERS, damage_mods, damage, damagetype, def_zone, sharpness, attack_direction, attacking_item)

	var/final_mod = 1
	for(var/new_mod in damage_mods)
		final_mod *= new_mod
	return final_mod


/mob/living/proc/apply_effects(effect = 0, effecttype = EFFECT_STUN, blocked = 0)
	var/hit_percent = (100-blocked)/100
	if(!effect || (hit_percent <= 0))
		return FALSE
	switch(effecttype)
		if(EFFECT_WEAKEN)
			Weaken(effect * hit_percent)
		if(EFFECT_STUN)
			Stun(effect * hit_percent)
		if(EFFECT_PARALYZE)
			Paralyse(effect * hit_percent)

	return TRUE

/mob/living/proc/can_adjust_oxy_loss(amount, forced, required_byotype, required_respiration_type)
	if(!forced)
		if(status_flags & GODMODE)
			return FALSE
		if(required_respiration_type)
			var/obj/item/organ/internal/lungs/affected_lungs = get_organ_by_type(/obj/item/organ/internal/lungs)
			if(isnull(affected_lungs))
				if(!(mob_respiration_type & required_respiration_type))
					return FALSE
			else
				if(!(affected_lungs.respiration_type & required_respiration_type))
					return FALSE
	if(SEND_SIGNAL(src, COMSIG_LIVING_ADJUST_OXY_DAMAGE, OXY, amount, forced) & COMPONENT_IGNORE_CHANGE)
		return FALSE
	return TRUE

/mob/living/proc/adjustOxyLoss(amount, updating_health = TRUE, forced = FALSE, required_byotype = ALL, required_respiration_type = ALL)
	if(!can_adjust_oxy_loss(amount, forced, required_byotype, required_respiration_type))
		return 0
	. = oxyloss
	oxyloss = clamp((oxyloss + amount), 0, maxHealth * 2)
	. -= oxyloss
	if(!.)
		return FALSE
	if(updating_health)
		updatehealth()
