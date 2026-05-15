// /datum/medical_issue/condition — cascading medical condition.
//
// A condition is a /datum/medical_issue subtype that ticks severity up
// over time and can spawn child conditions (cascade) when it crosses a
// threshold. Treatments come from chems whose IDs are listed in
// `cured_by` and `worsened_by`. Player-observable presentation goes
// through `symptom_pool` — a weighted bag of /datum/medical_symptom subtypes
// from which a few are rolled active at any time.
//
// Conditions live in an organ's `medical_issues` list and tick from
// the organ's process() loop (every ~2s while in a mob).
//
// Resleeve clears all conditions. Death does not — bodies retain their
// conditions, which means recently-killed mobs that get revived inherit
// their pre-death medical state. That's intentional: revival isn't a
// reset, it's a window during which the doctor was able to stabilize
// before brain death. Resleeving a fresh body is the only true reset.
/datum/medical_issue/condition
	name = "condition"

	/// Internal severity counter, 0..CONDITION_SEVERITY_TERMINAL. Players
	/// never see this number; only the symptom presentation and band.
	var/severity = 0
	/// How fast severity grows per tick when not being cured. Multiplied
	/// by CONDITION_BASE_PROGRESSION.
	var/progression_rate = 1
	/// Severity gates that fire from this condition's progression are
	/// authored as /datum/dq_cause/severity_gate records in the causes
	/// module — see modular_dq/code/modules/medical/causes/causes.dm.
	/// tick_condition walks them via dq_severity_gates_from(type).

	/// reagent ID -> severity-decrease-per-tick. While any cured_by
	/// reagent is in the bloodstream, severity drops by that amount.
	var/list/cured_by
	/// reagent ID -> severity-increase-per-tick. Stacks with passive
	/// progression. Used for chems that are right for one condition
	/// but actively harmful for another.
	var/list/worsened_by

	/// Severity threshold above which the condition starts damaging
	/// organs. Below this, the condition is symptomatic but not yet
	/// destroying tissue. 0 to disable organ damage entirely.
	var/organ_damage_threshold = 0
	/// Damage type to apply: BRUTE / BURN / "internal" (for internal
	/// organ.take_damage) / "oxy" / "tox". A null value disables organ
	/// damage.
	var/organ_damage_type
	/// Peak damage applied per tick when severity = 100. Scales
	/// linearly from threshold up to 100: at severity == threshold the
	/// rate is 0, at severity == 100 it's organ_damage_per_tick.
	var/organ_damage_per_tick = 0
	/// Organ tags the damage applies to. Empty list = damage applies
	/// to affectedorgan. Use this to make a condition that *lives* on
	/// the torso but damages the lungs (e.g. tension pneumothorax).
	var/list/organ_damage_targets

	/// Damage-emergent conditions are now declared via
	/// /datum/dq_cause/organ_damage records in the causes module. The
	/// emergent dispatcher in modular_dq/code/modules/medical/emergent.dm
	/// reads from there.

	/// One-sentence textbook overview for the reference book. Just
	/// "what is this thing."
	var/clinical_description

	/// Reference-book category. The book groups conditions by category
	/// in its index — body system or system class.
	/// Examples: "Brain", "Chest", "Limbs", "Circulation", "Eyes",
	/// "Infection", "Skin".
	var/category = "General"
	/// Optional finer-grained grouping rendered as a grey subheader
	/// inside a category. Use for clusters that share a sub-theme,
	/// like "Acute radiation" inside the "Radiation" category. Null
	/// means the condition sits directly under its category header
	/// with no subgroup.
	var/subcategory

	/// list of (typepath_of_/datum/medical_symptom = weight_0_100)
	var/list/symptom_pool
	/// Lower bound on active symptoms drawn from the pool. 0 means
	/// the condition can present invisibly.
	var/min_symptoms = 1
	/// Upper bound on active symptoms at once.
	var/max_symptoms = 3
	/// Last severity band we rolled at, so we know when to reroll.
	var/last_reroll_band = -1
	/// /datum/medical_symptom instances currently presenting.
	var/list/active_symptoms

	/// Effects this condition applies to vital readings. Two ways to
	/// populate:
	///  - Static per-subtype: override `get_vital_effects()` to return
	///    a `var/static/list/` local — shared across all instances of
	///    the subtype, no per-instance allocation.
	///  - Dynamic per-instance: assign `vital_effects = list(...)` at
	///    runtime (used by staged conditions like burn_shock that
	///    recompute on tick). The base `get_vital_effects()` returns
	///    this var when set, so a subtype can use either strategy.
	/// Keys: "pulse_mod" / "temp_mod_c" / "bp_sys_mod" / "bp_dia_mod"
	/// / "o2_sat_mod" / "resp_mod".
	var/list/vital_effects

	/// Has a doctor diagnosed this with a body scanner? Patients can't
	/// see their own condition name until diagnosed; body scanners
	/// reveal it. Some conditions stay hidden until a related symptom
	/// (e.g., cascaded child) gives them away.
	var/diagnosed = FALSE

	/// Active stage id, or null for non-staged conditions. Set by the
	/// emergent dispatcher (for organ-damage / metric conditions) or
	/// by the condition's own tick logic (burn_shock). When changed,
	/// `_apply_stage(new_id)` swaps the symptom_pool / mechanical /
	/// vital tables to the matching entry in `get_stages()`.
	var/stage

	// Suppress the upstream auto-process pathway. /datum/medical_issue's
	// handle_effects() does damage and reagent-cure work that doesn't
	// fit the condition model; we override and do our own.
	damagestrength = 0
	cure_reagent = null
	reagent_strength = 0
	symptom_text = null
	symptom_affect = null

/datum/medical_issue/condition/handle_effects()
	if(!owner || !affectedorgan)
		return
	if(!(affectedorgan in owner.organs) && !(affectedorgan in owner.internal_organs))
		return
	tick_condition()

/// Returns the vital-effects table for this condition. Subtypes with
/// fixed effects should override to return a `var/static/list/` so the
/// list is shared across all instances. The base implementation falls
/// back to the per-instance `vital_effects` var, which only gets used
/// by stage-driven conditions (burn_shock) that mutate it on tick.
/datum/medical_issue/condition/proc/get_vital_effects()
	return vital_effects

/// Per-stage table for multi-stage conditions. Override on subtypes
/// that have stages; return a `var/static/list/` of stage-id -> entry,
/// where each entry is a list with keys:
///   "name"               — display name when this stage is active
///   "description"        — optional clinical-description override
///   "symptom_pool"       — symptom typepath -> weight
///   "min_symptoms"       — optional lower bound (defaults to instance value)
///   "max_symptoms"       — optional upper bound
///   "mechanical_effects" — slowdown / accuracy_penalty / etc
///   "vital_effects"      — pulse_mod / bp_sys_mod / etc
/// The book reads this map to render per-stage subsections. The
/// emergent dispatcher reads it to validate which stage_id values
/// the condition supports. Null = condition has no stages.
/datum/medical_issue/condition/proc/get_stages()
	return null

/// Swap the per-instance vars to the named stage's entry. Called when
/// the dispatcher or the condition's own tick decides the stage has
/// changed. Forces a symptom reroll on the next tick so the new pool
/// gets used.
/datum/medical_issue/condition/proc/_apply_stage(new_stage)
	if(new_stage == stage)
		return
	var/list/stages = get_stages()
	if(!stages || !stages[new_stage])
		return
	stage = new_stage
	var/list/entry = stages[new_stage]
	if(entry["name"])
		name = entry["name"]
	symptom_pool = entry["symptom_pool"]
	if(!isnull(entry["min_symptoms"]))
		min_symptoms = entry["min_symptoms"]
	if(!isnull(entry["max_symptoms"]))
		max_symptoms = entry["max_symptoms"]
	mechanical_effects = entry["mechanical_effects"]
	vital_effects = entry["vital_effects"]
	last_reroll_band = -1  // force symptom reroll on next tick

/datum/medical_issue/condition/proc/tick_condition()
	// Reagent effects: cures lower, worsens raise. Each reagent's
	// contribution is its declared per-tick number; we just sum them.
	var/delta = CONDITION_BASE_PROGRESSION * progression_rate
	if(cured_by)
		for(var/id in cured_by)
			if(owner.reagents?.has_reagent(id) || owner.bloodstr?.has_reagent(id))
				delta -= cured_by[id]
	if(worsened_by)
		for(var/id in worsened_by)
			if(owner.reagents?.has_reagent(id) || owner.bloodstr?.has_reagent(id))
				delta += worsened_by[id]
	// Severity-driven acceleration: conditions snowball as they progress.
	// 1× at severity 0, 2× at 50, 3× at 100. Cures still scale too —
	// late-stage conditions are harder (not impossible) to drag back.
	delta *= (1 + severity / 50)
	// Damage-driven acceleration: a 60-damage stab should rack up
	// internal_hemorrhage faster than a 5-damage one. Each condition
	// declares what "damage" means for it (brute on this organ, burn
	// across all organs, blood volume below threshold, etc).
	delta *= damage_scaling()
	severity = clamp(severity + delta, 0, CONDITION_SEVERITY_TERMINAL)

	// Cure: dropped back to zero.
	if(severity <= 0)
		cure_issue()
		return

	// Roll/reroll symptoms when crossing a band boundary.
	var/band = round(severity / CONDITION_SYMPTOM_REROLL_STEP)
	if(band != last_reroll_band)
		last_reroll_band = band
		roll_symptoms()

	// Re-present active symptoms (drip messages / emote chances).
	for(var/datum/medical_symptom/S as anything in active_symptoms)
		S.tick(owner, src)

	// Apply stochastic mechanical effects (drop items, spontaneous
	// emotes). Continuous effects (slowdown, accuracy) are queried by
	// upstream code via dq_mechanical_value().
	tick_mechanical_effects()

	// Severity-gate causes: walk every /datum/dq_cause/severity_gate
	// whose source is this condition's type. Each gate rolls every
	// tick we're at or above its threshold until each outcome is
	// already present on the relevant organ (idempotent spawning
	// stops the re-roll naturally).
	for(var/datum/dq_cause/severity_gate/gate as anything in dq_severity_gates_from(type))
		if(severity < gate.threshold)
			continue
		for(var/datum/dq_cause_outcome/o as anything in gate.produces)
			if(!o.preconditions_met(affectedorgan))
				continue
			if(_dq_outcome_already_present(o.condition_type))
				continue
			if(!prob(o.chance))
				continue
			spawn_child_condition(o.condition_type)

	// Organ damage. Once severity climbs past the per-condition
	// threshold, the condition starts physically destroying the host
	// organ (or another organ; see organ_damage_targets). When that
	// damage drives a vital organ to its max, upstream `organ/die()`
	// triggers `owner.death()` — that's the actual cause of death in
	// the cascading-condition system. There's no separate "terminal
	// flag → die" path: death emerges from organ failure, the same as
	// it does for any other source of damage.
	if(organ_damage_type && severity >= organ_damage_threshold)
		_apply_organ_damage()

/// Picks a fresh `active_symptoms` set from `symptom_pool`. Each entry
/// is rolled against its weight; the count is clamped to [min,max].
/datum/medical_issue/condition/proc/roll_symptoms()
	var/list/old = active_symptoms?.Copy() || list()
	active_symptoms = list()
	if(!symptom_pool)
		return
	var/list/picked = list()
	for(var/type in symptom_pool)
		if(prob(symptom_pool[type]))
			picked += type
	while(length(picked) < min_symptoms && length(picked) < length(symptom_pool))
		// Force-include from leftovers, weighted.
		var/list/leftovers = list()
		for(var/type in symptom_pool)
			if(!(type in picked))
				leftovers[type] = symptom_pool[type]
		if(!length(leftovers))
			break
		picked += pickweight(leftovers)
	while(length(picked) > max_symptoms)
		picked.Cut(rand(1, length(picked)), rand(1, length(picked)) + 1)
	// Instantiate.
	for(var/type in picked)
		var/datum/medical_symptom/S = new type()
		S.source_condition = src
		active_symptoms += S
		S.on_present(owner, src)
	// Stop ones that left.
	for(var/datum/medical_symptom/old_s as anything in old)
		var/found = FALSE
		for(var/datum/medical_symptom/new_s as anything in active_symptoms)
			if(new_s.type == old_s.type)
				found = TRUE
				break
		if(!found)
			old_s.on_resolve(owner, src)

/// Is `typepath` already present on this condition's spawn target?
/datum/medical_issue/condition/proc/_dq_outcome_already_present(typepath)
	var/obj/item/organ/target = pick_spawn_target(typepath)
	if(!target)
		return FALSE
	for(var/datum/medical_issue/condition/existing in target.medical_issues)
		if(existing.type == typepath)
			return TRUE
	return FALSE

/// Spawn a child condition produced by a severity-gate cause. Targets
/// the same organ by default; subtypes can override pick_spawn_target.
/datum/medical_issue/condition/proc/spawn_child_condition(typepath)
	if(!ispath(typepath, /datum/medical_issue/condition))
		return
	var/obj/item/organ/target_organ = pick_spawn_target(typepath)
	if(!target_organ)
		return
	for(var/datum/medical_issue/condition/existing in target_organ.medical_issues)
		if(existing.type == typepath)
			return
	var/datum/medical_issue/condition/C = new typepath()
	C.owner = owner
	C.affectedorgan = target_organ
	LAZYADD(target_organ.medical_issues, C)

/datum/medical_issue/condition/proc/pick_spawn_target(child_typepath)
	return affectedorgan

/// Apply organ damage proportional to how far above
/// `organ_damage_threshold` the condition's severity is. Scales
/// linearly: 0 damage at threshold, `organ_damage_per_tick` at 100.
/// Damages every organ named in `organ_damage_targets`, or the
/// affectedorgan if that list is empty. The "type" string selects
/// which damage API to call.
/datum/medical_issue/condition/proc/_apply_organ_damage()
	if(!owner || !organ_damage_type || !organ_damage_per_tick)
		return
	var/span = CONDITION_SEVERITY_TERMINAL - organ_damage_threshold
	if(span <= 0)
		return
	var/scale = clamp((severity - organ_damage_threshold) / span, 0, 1)
	var/amount = organ_damage_per_tick * scale
	if(amount <= 0)
		return

	// Mob-wide damage types — apply directly to the owner.
	if(organ_damage_type == "oxy")
		owner.adjustOxyLoss(amount)
		return
	if(organ_damage_type == "tox")
		owner.adjustToxLoss(amount)
		return

	// Per-organ damage. Build the target list.
	var/list/targets = list()
	if(length(organ_damage_targets))
		for(var/tag in organ_damage_targets)
			var/obj/item/organ/O = _resolve_organ(tag)
			if(O)
				targets += O
	else if(affectedorgan)
		targets += affectedorgan

	for(var/obj/item/organ/O as anything in targets)
		if(istype(O, /obj/item/organ/external))
			var/obj/item/organ/external/E = O
			if(organ_damage_type == BURN)
				E.take_damage(0, amount, sharp = FALSE, edge = FALSE)
			else // BRUTE / default
				E.take_damage(amount, 0, sharp = FALSE, edge = FALSE)
		else
			O.take_damage(amount)

/// Resolve an organ tag to the correct organ on the owner. Tries
/// external first, then internal by name.
/datum/medical_issue/condition/proc/_resolve_organ(tag)
	if(!owner)
		return null
	var/mob/living/carbon/human/H = owner
	var/obj/item/organ/O = H.get_organ(tag)
	if(O)
		return O
	if(H.internal_organs_by_name)
		return H.internal_organs_by_name[tag]
	return null

/datum/medical_issue/condition/proc/cleared_on_resleeve()
	return TRUE

/// Multiplier applied to per-tick severity delta based on how badly hurt
/// the patient is RIGHT NOW. Base returns 1.0 (no scaling). Override on
/// conditions that should accelerate with underlying damage:
///
///   - bleeders consult blood_volume (lower = faster shock)
///   - burns consult cumulative burn_dam (more burns = faster burn_shock)
///   - blunt/sharp conditions consult their organ's brute_dam
///
/// The convention is to return a multiplier in roughly [0.5, 3.0].
/// Returning <1 lets a treated/stable patient's condition slow naturally;
/// returning >1 makes a severely-injured patient's condition race.
/datum/medical_issue/condition/proc/damage_scaling()
	return 1.0

/// Helper: maps a `value` in range [low_val, high_val] to a multiplier
/// in [low_mult, high_mult] with clamping. Used by damage_scaling()
/// overrides to keep the math obvious.
/proc/dq_damage_scale(value, low_val, high_val, low_mult, high_mult)
	if(high_val <= low_val)
		return low_mult
	var/t = clamp((value - low_val) / (high_val - low_val), 0, 1)
	return low_mult + (high_mult - low_mult) * t

/datum/medical_issue/condition/cure_issue()
	for(var/datum/medical_symptom/S as anything in active_symptoms)
		S.on_resolve(owner, src)
	active_symptoms = null
	..()

// Lookup helper: walk all organs of a mob, gather conditions.
/mob/living/carbon/human/proc/get_all_conditions()
	. = list()
	if(organs)
		for(var/obj/item/organ/O as anything in organs)
			if(!O?.medical_issues)
				continue
			for(var/datum/medical_issue/condition/C in O.medical_issues)
				. += C
	if(internal_organs)
		for(var/obj/item/organ/O as anything in internal_organs)
			if(!O?.medical_issues)
				continue
			for(var/datum/medical_issue/condition/C in O.medical_issues)
				. += C
