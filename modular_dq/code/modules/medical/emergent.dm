// Damage-emergent conditions.
//
// Some conditions are observations of catastrophic organ failure —
// respiratory_failure isn't a separate thing from "lungs at >70%
// damage"; cardiac_arrest isn't separate from "heart >70%". These
// conditions auto-spawn when their target organ crosses a damage
// threshold and auto-clear when it falls back below.
//
// The rule data lives entirely in /datum/dq_cause/organ_damage records
// (see modular_dq/code/modules/medical/causes/causes.dm). This file
// just walks those causes each Life tick.

/mob/living/carbon/human/proc/dq_check_emergent_conditions()
	if(stat == DEAD)
		return
	for(var/datum/dq_cause/organ_damage/c as anything in dq_causes_of_kind("/datum/dq_cause/organ_damage"))
		var/obj/item/organ/O = _dq_resolve_organ_on(src, c.organ)
		if(!O || !O.max_damage)
			continue
		var/dmg_pct
		if(istype(O, /obj/item/organ/external))
			var/obj/item/organ/external/E = O
			dmg_pct = ((E.brute_dam + E.burn_dam) / O.max_damage) * 100
		else
			dmg_pct = (O.damage / O.max_damage) * 100
		_dq_apply_outcomes(O, c.produces, dmg_pct, c.threshold_pct)


/// Apply a list of /datum/dq_cause_outcome to the host organ, given
/// the current metric value (`metric`) and an optional cause-level
/// default threshold (`default_threshold`). Outcomes can map either:
///
///   (a) one condition_type per outcome (legacy, used when each
///       outcome is its own distinct condition), or
///   (b) several outcomes sharing one condition_type, where each
///       outcome carries a `tier` field — in which case the condition
///       supports stages and we pick the highest tier whose threshold
///       is met, applying that as the stage.
///
/// Either way: spawn the condition when at least one outcome's
/// threshold is met, set its severity continuously based on how far
/// past the lowest-threshold outcome we are, and cure when no outcome
/// is met.
/mob/living/carbon/human/proc/_dq_apply_outcomes(obj/item/organ/host, list/produces, metric, default_threshold)
	// Bucket outcomes by condition_type so staged conditions can pick
	// the highest tier that fits.
	var/list/by_type = list()
	for(var/datum/dq_cause_outcome/o as anything in produces)
		LAZYINITLIST(by_type[o.condition_type])
		by_type[o.condition_type] += o

	for(var/condition_type in by_type)
		var/list/outs = by_type[condition_type]
		// Find the lowest threshold (for severity scaling) and the
		// highest-tier outcome currently met.
		var/min_thresh = 200
		var/datum/dq_cause_outcome/active_outcome
		var/highest_thresh = -1
		for(var/datum/dq_cause_outcome/o as anything in outs)
			var/thresh = !isnull(o.threshold) ? o.threshold : default_threshold
			if(isnull(thresh))
				thresh = 0
			if(thresh < min_thresh)
				min_thresh = thresh
			if(metric >= thresh && thresh > highest_thresh)
				highest_thresh = thresh
				active_outcome = o

		// Find or remove an existing condition of this type.
		var/datum/medical_issue/condition/existing
		for(var/datum/medical_issue/condition/C in host.medical_issues)
			if(C.type == condition_type)
				existing = C
				break

		if(active_outcome)
			// Severity scales from the lowest-met-threshold to 100, so
			// healing pulls severity down naturally even within a single
			// stage band. Min_thresh is the floor, not active_outcome's
			// threshold, so the curve doesn't lurch at stage boundaries.
			var/span = max(1, 100 - min_thresh)
			var/target_severity = clamp((metric - min_thresh) / span * 100, 0, 100)
			if(existing)
				existing.severity = target_severity
				if(active_outcome.tier && active_outcome.tier != existing.stage)
					existing._apply_stage(active_outcome.tier)
			else
				var/datum/medical_issue/condition/N = new condition_type()
				N.owner = src
				N.affectedorgan = host
				N.severity = target_severity
				if(active_outcome.tier)
					N._apply_stage(active_outcome.tier)
				LAZYADD(host.medical_issues, N)
		else if(existing)
			existing.cure_issue()


/// Metric-driven conditions: walk every /datum/dq_cause/metric_threshold,
/// read the mob's scalar value, spawn / cure / update severity on the
/// host organ. Same continuous-severity pattern as organ_damage causes:
/// at threshold severity is 0, at the cause's `metric_max` (or a
/// per-cause default) severity is 100.
/mob/living/carbon/human/proc/dq_check_metric_conditions()
	if(stat == DEAD)
		return
	for(var/datum/dq_cause/metric_threshold/c as anything in dq_causes_of_kind("/datum/dq_cause/metric_threshold"))
		var/value = dq_get_metric(c.metric)
		var/obj/item/organ/host = _dq_resolve_organ_on(src, c.host_organ)
		if(!host)
			continue
		// For `<=` causes (cold exposure) we flip the metric so the
		// shared apply_outcomes helper still uses "value >= threshold"
		// internally. The thresholds in the cause are authored in the
		// flipped frame already (e.g. temp_below threshold = 20K below
		// normal).
		_dq_apply_outcomes(host, c.produces, value, 0)


/// Read a named scalar metric off the mob for metric_threshold causes.
/// Centralised so adding a new metric kind only requires one edit.
/mob/living/carbon/human/proc/dq_get_metric(metric_name)
	switch(metric_name)
		if("radiation")
			return radiation
		if("accumulated_rads")
			return accumulated_rads
		if("toxloss")
			return getToxLoss()
		if("temp_above")
			// Kelvin above 310.15 (37°C).
			return max(0, bodytemperature - 310.15)
		if("temp_below")
			// Kelvin below 310.15 (37°C).
			return max(0, 310.15 - bodytemperature)
		if("cloneloss")
			return getCloneLoss()
	return 0


/// Ischemic damage: sustained oxyloss damages organs beyond just the
/// brain. Upstream already converts oxyloss to brain damage; we extend
/// that to liver / kidneys / heart so prolonged shock causes the
/// secondary-failure modes real medicine cares about (acute kidney
/// injury, shock liver, cardiogenic shock from poor coronary perfusion).
///
/// Threshold mirrors the upstream "oxyloss >= 30% of max health" gate
/// the brain damage path uses, so all three organ paths start together.
/// Rates are deliberately slow: organs accumulate damage only over
/// minutes of unresolved hypoxia, not seconds.
#define DQ_ISCHEMIA_OXY_THRESHOLD_PCT 0.30
/mob/living/carbon/human/proc/dq_check_ischemic_damage()
	if(stat == DEAD)
		return
	var/oxy = getOxyLoss()
	var/max_hp = getMaxHealth()
	if(max_hp <= 0)
		return
	if(oxy < (max_hp * DQ_ISCHEMIA_OXY_THRESHOLD_PCT))
		return
	// Damage scales with how far past threshold we are: at threshold,
	// minimum rate; at 2× threshold (60% of max_hp in oxyloss),
	// maximum rate.
	var/excess = (oxy - max_hp * DQ_ISCHEMIA_OXY_THRESHOLD_PCT) / (max_hp * DQ_ISCHEMIA_OXY_THRESHOLD_PCT)
	var/scale = clamp(excess, 0, 1)
	// Per-tick damage to non-brain organs from sustained hypoxia.
	// Brain still takes the heaviest hit (via upstream conversion at
	// 0.015 × oxyloss). These are lower. Rates reflect each organ's
	// real-medicine ischemic sensitivity:
	//   kidneys > liver > eyes > heart > lungs
	for(var/tag in list(O_LIVER, O_KIDNEYS, O_HEART, O_EYES, O_LUNGS))
		var/obj/item/organ/internal/O = internal_organs_by_name?[tag]
		if(!O)
			continue
		if(O.robotic >= ORGAN_ROBOT)
			continue
		var/per_tick
		switch(tag)
			if(O_KIDNEYS) per_tick = 0.4 + 0.6 * scale  // most ischemia-sensitive
			if(O_LIVER)   per_tick = 0.3 + 0.5 * scale
			if(O_EYES)    per_tick = 0.2 + 0.4 * scale  // retinal ischemia
			if(O_HEART)   per_tick = 0.2 + 0.4 * scale
			if(O_LUNGS)   per_tick = 0.1 + 0.2 * scale  // small to avoid runaway feedback
		if(prob(60))  // not every tick; smooths the curve
			O.take_damage(per_tick, silent = TRUE)

	// Gut ischemia: damaged intestine risks bacterial translocation.
	// Rather than damage the intestine outward, we raise its germ_level
	// — which feeds the existing wound_infection bridge already in
	// /obj/item/organ/process() via dq_bridge_germ_to_condition(). This
	// is the path real medicine warns about: prolonged shock → gut
	// translocation → systemic infection.
	if(scale > 0)
		var/obj/item/organ/internal/intestine/gut = internal_organs_by_name?[O_INTESTINE]
		if(gut && gut.robotic < ORGAN_ROBOT)
			gut.adjust_germ_level(round(1 + 3 * scale))


/// Resolve an organ tag to the right organ on a human. Tries external
/// (BP_*) first, then internal (O_*).
/proc/_dq_resolve_organ_on(mob/living/carbon/human/H, tag)
	if(!H)
		return null
	var/obj/item/organ/O = H.get_organ(tag)
	if(O)
		return O
	if(H.internal_organs_by_name)
		return H.internal_organs_by_name[tag]
	return null
