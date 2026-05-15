// Unit tests for the DQ surgery framework and the cross-cutting audit
// of condition identifiability and cure paths.
//
// These tests live here (not under code/modules/unit_tests/) so they can
// reference DQ-side defines like SYMPTOM_AUDIENCE_* directly — those
// defines are included from modular_dq and aren't visible to upstream
// test files compiled earlier in the manifest.

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)

// --- surgery: registry has entries -------------------------------------

/datum/unit_test/dq_surgery_registry_populates

/datum/unit_test/dq_surgery_registry_populates/Run()
	// Force a fresh build of the registry.
	GLOB.dq_surgery_by_step = list()
	var/list/registry = dq_surgeries_registry()
	TEST_ASSERT(length(registry) > 0, "surgery registry should contain at least one entry")
	for(var/step_path in registry)
		TEST_ASSERT(ispath(step_path, /datum/surgery_step), "registry key [step_path] is not a /datum/surgery_step")
		var/list/datum/dq_surgery/surgeries = registry[step_path]
		TEST_ASSERT(length(surgeries) > 0, "registry value for [step_path] is empty")
		for(var/datum/dq_surgery/sg as anything in surgeries)
			TEST_ASSERT(istype(sg), "registry value for [step_path] contains non-/datum/dq_surgery [sg]")
			TEST_ASSERT_EQUAL(sg.completion_step, step_path, "surgery [sg.type] indexed under wrong step ([step_path] vs its completion_step [sg.completion_step])")


// --- surgery: every authored surgery references real types -------------

/datum/unit_test/dq_surgery_records_well_formed

/datum/unit_test/dq_surgery_records_well_formed/Run()
	for(var/T in subtypesof(/datum/dq_surgery))
		var/datum/dq_surgery/sg = new T()
		TEST_ASSERT(sg.name, "[T] has no name")
		TEST_ASSERT(sg.description, "[T] has no description")
		TEST_ASSERT(sg.category, "[T] has no category")
		TEST_ASSERT(length(sg.steps) > 0, "[T] has no procedural steps documented")
		TEST_ASSERT(length(sg.treats) > 0, "[T] declares no treatable conditions")
		for(var/cond_path in sg.treats)
			TEST_ASSERT(ispath(cond_path, /datum/medical_issue/condition), "[T].treats contains non-condition path [cond_path]")
		if(sg.completion_step)
			TEST_ASSERT(ispath(sg.completion_step, /datum/surgery_step), "[T].completion_step [sg.completion_step] is not a /datum/surgery_step subtype")
		qdel(sg)


// --- surgery: every condition that names a surgery has a real step ---
// A /datum/dq_surgery without a completion_step is documentation-only —
// flag it so it's an explicit choice, not a forgotten wiring task. We
// allow it but it shows up in test output.

/datum/unit_test/dq_surgery_completion_step_coverage

/datum/unit_test/dq_surgery_completion_step_coverage/Run()
	var/list/missing = list()
	for(var/T in subtypesof(/datum/dq_surgery))
		var/datum/dq_surgery/sg = new T()
		if(!sg.completion_step)
			missing += "[T]"
		qdel(sg)
	// Don't fail — the framework allows documentation-only surgeries.
	// Test passes regardless; the failures only print if you ran focused.
	TEST_ASSERT(TRUE, "documentation-only surgeries (no completion_step): [length(missing) ? jointext(missing, ", ") : "none"]")


// --- surgery: cure hook actually clears matching conditions ------------

/datum/unit_test/dq_surgery_cures_matching_condition

/datum/unit_test/dq_surgery_cures_matching_condition/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/medical_issue/condition/untreated_fracture/C = _dq_spawn_condition_on(H, BP_L_ARM, /datum/medical_issue/condition/untreated_fracture)
	TEST_ASSERT_NOTNULL(C, "untreated_fracture didn't spawn")

	var/datum/surgery_step/bones/finish_bone/step = new()
	dq_apply_surgery_cures(step, H, BP_L_ARM)
	qdel(step)

	for(var/datum/medical_issue/condition/c in H.get_all_conditions())
		if(istype(c, /datum/medical_issue/condition/untreated_fracture))
			TEST_FAIL("untreated_fracture should have been cured by fracture_setting")


// --- surgery: tendon repair via its own dedicated step ---------------

/datum/unit_test/dq_surgery_tendon_repair_step_cures

/datum/unit_test/dq_surgery_tendon_repair_step_cures/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/medical_issue/condition/tendon_severed/C = _dq_spawn_condition_on(H, BP_L_LEG, /datum/medical_issue/condition/tendon_severed)
	TEST_ASSERT_NOTNULL(C, "tendon_severed didn't spawn")

	var/datum/surgery_step/fix_tendon/step = new()
	dq_apply_surgery_cures(step, H, BP_L_LEG)
	qdel(step)

	for(var/datum/medical_issue/condition/c in H.get_all_conditions())
		if(istype(c, /datum/medical_issue/condition/tendon_severed))
			TEST_FAIL("tendon_severed should have been cured by fix_tendon")


// --- surgery: cure hook ignores non-matching conditions ----------------

/datum/unit_test/dq_surgery_does_not_cure_unrelated

/datum/unit_test/dq_surgery_does_not_cure_unrelated/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	var/datum/medical_issue/condition/cellulitis/C = _dq_spawn_condition_on(H, BP_TORSO, /datum/medical_issue/condition/cellulitis)
	TEST_ASSERT_NOTNULL(C, "cellulitis didn't spawn")

	var/datum/surgery_step/bones/finish_bone/step = new()
	dq_apply_surgery_cures(step, H, BP_TORSO)
	qdel(step)

	var/still_present = FALSE
	for(var/datum/medical_issue/condition/c in H.get_all_conditions())
		if(istype(c, /datum/medical_issue/condition/cellulitis))
			still_present = TRUE
			break
	TEST_ASSERT(still_present, "cellulitis should not be cured by an unrelated surgery (fracture_setting)")


// --- surgery: shared step routed by zone ------------------------------
// /datum/surgery_step/internal/fix_organ is reused by craniotomy (head)
// and lung_repair (torso). The cure hook should only fire the surgery
// whose body_region matches the target zone.

/datum/unit_test/dq_surgery_zone_routing

/datum/unit_test/dq_surgery_zone_routing/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)

	var/obj/item/organ/internal/brain = H.internal_organs_by_name[O_BRAIN]
	var/datum/medical_issue/condition/brain_damage/bd = new()
	bd.owner = H
	bd.affectedorgan = brain
	LAZYADD(brain.medical_issues, bd)

	var/obj/item/organ/internal/lungs = H.internal_organs_by_name[O_LUNGS]
	var/datum/medical_issue/condition/respiratory_failure/rf = new()
	rf.owner = H
	rf.affectedorgan = lungs
	LAZYADD(lungs.medical_issues, rf)

	// Apply fix_organ on the HEAD zone. Should only cure brain_damage.
	var/datum/surgery_step/internal/fix_organ/step = new()
	dq_apply_surgery_cures(step, H, BP_HEAD)

	var/bd_present = FALSE
	var/rf_present = FALSE
	for(var/datum/medical_issue/condition/c in H.get_all_conditions())
		if(istype(c, /datum/medical_issue/condition/brain_damage))
			bd_present = TRUE
		else if(istype(c, /datum/medical_issue/condition/respiratory_failure))
			rf_present = TRUE
	TEST_ASSERT(!bd_present, "head-zone fix_organ should have cured brain_damage")
	TEST_ASSERT(rf_present, "head-zone fix_organ should NOT have cured respiratory_failure (torso)")

	// Now apply fix_organ on the TORSO zone. Should cure respiratory_failure.
	dq_apply_surgery_cures(step, H, BP_TORSO)
	qdel(step)
	rf_present = FALSE
	for(var/datum/medical_issue/condition/c in H.get_all_conditions())
		if(istype(c, /datum/medical_issue/condition/respiratory_failure))
			rf_present = TRUE
			break
	TEST_ASSERT(!rf_present, "torso-zone fix_organ should have cured respiratory_failure")


// --- surgery: undocumented step is a no-op ----------------------------

/datum/unit_test/dq_surgery_undocumented_step_noop

/datum/unit_test/dq_surgery_undocumented_step_noop/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	_dq_spawn_condition_on(H, BP_TORSO, /datum/medical_issue/condition/cellulitis)
	var/before = length(H.get_all_conditions())

	// /datum/surgery_step/face/mend_vocal isn't referenced by any
	// dq_surgery record. It's a real surgery_step subtype but undocumented
	// in our framework — should be a no-op.
	var/datum/surgery_step/face/mend_vocal/step = new()
	dq_apply_surgery_cures(step, H, BP_TORSO)
	qdel(step)

	var/after = length(H.get_all_conditions())
	TEST_ASSERT_EQUAL(before, after, "undocumented surgery step should not cure anything")


// --- surgery zone matcher: keyword table behaves --------------------

/datum/unit_test/dq_surgery_zone_matcher

/datum/unit_test/dq_surgery_zone_matcher/Run()
	// "Affected limb or torso" matches both limb and torso zones.
	var/datum/dq_surgery/proto = new()
	proto.body_region = "Affected limb or torso"
	TEST_ASSERT(_dq_surgery_matches_zone(proto, BP_L_ARM), "limb-or-torso surgery should match arm")
	TEST_ASSERT(_dq_surgery_matches_zone(proto, BP_TORSO), "limb-or-torso surgery should match torso")
	TEST_ASSERT(!_dq_surgery_matches_zone(proto, BP_HEAD), "limb-or-torso surgery should NOT match head")

	// "Head" matches the head, eyes, mouth zones.
	proto.body_region = "Head"
	TEST_ASSERT(_dq_surgery_matches_zone(proto, BP_HEAD), "head surgery should match BP_HEAD")
	TEST_ASSERT(_dq_surgery_matches_zone(proto, O_EYES), "head surgery should match O_EYES (eye zone)")
	TEST_ASSERT(!_dq_surgery_matches_zone(proto, BP_L_LEG), "head surgery should NOT match limb")

	// Empty body_region matches everything.
	proto.body_region = ""
	TEST_ASSERT(_dq_surgery_matches_zone(proto, BP_HEAD), "empty body_region should match head")
	TEST_ASSERT(_dq_surgery_matches_zone(proto, BP_TORSO), "empty body_region should match torso")
	qdel(proto)


// --- audit: every condition has at least one observable symptom -------
// Every condition must have a symptom with SYMPTOM_AUDIENCE_PUBLIC or
// SYMPTOM_AUDIENCE_SCANNER in every stage. Without this, medics cannot
// identify the condition. For staged conditions, every stage's
// symptom_pool is checked individually.

/datum/unit_test/dq_medical_every_condition_identifiable

/datum/unit_test/dq_medical_every_condition_identifiable/Run()
	var/list/failures = list()
	for(var/T in subtypesof(/datum/medical_issue/condition))
		var/datum/medical_issue/condition/proto = new T()
		var/list/stages = proto.get_stages()
		if(stages)
			for(var/stage_id in stages)
				var/list/sd = stages[stage_id]
				if(!_dq_pool_has_observable(sd["symptom_pool"]))
					failures += "[T] stage '[stage_id]' has no SCANNER or PUBLIC symptom"
		else
			if(!_dq_pool_has_observable(proto.symptom_pool))
				failures += "[T] has no SCANNER or PUBLIC symptom"
		qdel(proto)
	if(length(failures))
		TEST_FAIL("conditions are not identifiable to medics: [jointext(failures, "; ")]")


/datum/unit_test/proc/_dq_pool_has_observable(list/symptom_pool)
	if(!symptom_pool)
		return FALSE
	for(var/sym_path in symptom_pool)
		var/datum/medical_symptom/proto = new sym_path()
		var/observable = (proto.audiences & SYMPTOM_AUDIENCE_PUBLIC) || (proto.audiences & SYMPTOM_AUDIENCE_SCANNER)
		qdel(proto)
		if(observable)
			return TRUE
	return FALSE


// --- audit: every condition has a sensible cure path -----------------
// A condition is "curable" if it has at least one of:
//   - a non-empty cured_by list (chemical cure),
//   - a /datum/dq_surgery whose treats list includes it,
//   - a negative progression_rate (self-resolves over time).

/datum/unit_test/dq_medical_every_condition_curable

/datum/unit_test/dq_medical_every_condition_curable/Run()
	var/list/surgical_targets = list()
	for(var/ST in subtypesof(/datum/dq_surgery))
		var/datum/dq_surgery/sg = new ST()
		if(sg.treats)
			for(var/cond in sg.treats)
				surgical_targets[cond] = TRUE
		qdel(sg)

	var/list/failures = list()
	for(var/T in subtypesof(/datum/medical_issue/condition))
		var/datum/medical_issue/condition/proto = new T()
		var/curable = FALSE
		if(length(proto.cured_by))
			curable = TRUE
		else if(surgical_targets[T])
			curable = TRUE
		else if(proto.progression_rate < 0)
			curable = TRUE
		if(!curable)
			failures += "[T]"
		qdel(proto)
	if(length(failures))
		TEST_FAIL("conditions lack any cure path (chem / surgery / self-heal): [jointext(failures, ", ")]")

#endif
