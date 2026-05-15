// Damage-emergent organ-failure conditions.
//
// Each condition tracks a single organ. Multi-stage conditions
// (brain_damage, heart_damage) use the shared stage machinery on the
// base /datum/medical_issue/condition: the metric or organ-damage
// dispatcher picks the highest matching outcome tier each tick and
// applies it via _apply_stage().

// --- Liver -------------------------------------------------------------

/datum/medical_issue/condition/hepatic_failure
	name = "hepatic failure"
	category = "Organ failure"
	clinical_description = "The liver can no longer clear metabolites or regulate clotting. Toxins accumulate in the bloodstream."
	progression_rate = 0
	// Peridaxon repairs the underlying liver damage and the condition
	// clears once damage drops below threshold. Inaprovaline stabilises.
	cured_by = list(REAGENT_ID_PERIDAXON = 1.0, REAGENT_ID_DEXALINP = 0.4, REAGENT_ID_INAPROVALINE = 0.2)
	symptom_pool = list(
		/datum/medical_symptom/fatigue        = 90,
		/datum/medical_symptom/nausea         = 70,
		/datum/medical_symptom/confusion      = 60,
		/datum/medical_symptom/pallor         = 50,
	)
	min_symptoms = 2
	max_symptoms = 3
	// Toxin clearance failure. We stack toxloss while present; the
	// liver is the organ that processes most reagents, and that
	// processing breaks here.
	organ_damage_threshold = 0
	organ_damage_type = "tox"
	organ_damage_per_tick = 1.5


// --- Kidneys -----------------------------------------------------------

/datum/medical_issue/condition/renal_failure
	name = "renal failure"
	category = "Organ failure"
	clinical_description = "The kidneys have stopped clearing waste. Electrolytes drift and fluid balance fails."
	progression_rate = 0
	cured_by = list(REAGENT_ID_PERIDAXON = 1.0, REAGENT_ID_DEXALINP = 0.4, REAGENT_ID_INAPROVALINE = 0.2)
	symptom_pool = list(
		/datum/medical_symptom/fatigue        = 90,
		/datum/medical_symptom/nausea         = 60,
		/datum/medical_symptom/confusion      = 50,
		/datum/medical_symptom/pallor         = 50,
		/datum/medical_symptom/short_breath   = 40,
	)
	min_symptoms = 2
	max_symptoms = 3
	// Renal failure causes acidosis and electrolyte imbalance — we
	// model that as slow toxloss accumulation.
	organ_damage_threshold = 0
	organ_damage_type = "tox"
	organ_damage_per_tick = 1.0


// --- Eyes --------------------------------------------------------------

/datum/medical_issue/condition/ischemic_vision_loss
	name = "ischemic vision loss"
	category = "Eyes"
	clinical_description = "Loss of vision from the eyes being starved of blood for too long. Without rapid restoration of circulation, the loss becomes permanent."
	progression_rate = 0
	cured_by = list(REAGENT_ID_IMIDAZOLINE = 1.0, REAGENT_ID_DEXALINP = 0.3, REAGENT_ID_INAPROVALINE = 0.2)
	symptom_pool = list(
		/datum/medical_symptom/blurred_vision = 95,
		/datum/medical_symptom/confusion      = 30,
		/datum/medical_symptom/cloudy_eye     = 80,
	)
	min_symptoms = 2
	max_symptoms = 3


// --- Heart (staged: cardiogenic shock → cardiac arrest) ----------------
//
// Single condition. The dispatcher swaps between the Moderate stage
// (heart damaged but pumping) and the Critical stage (heart effectively
// stopped) based on the heart's damage % via the organ_damage cause's
// per-outcome thresholds.

/datum/medical_issue/condition/heart_damage
	name = "heart damage"
	category = "Circulation"
	clinical_description = "Injury to the heart itself. As the pump's output falls, perfusion suffers; when pump function collapses outright, cardiac arrest follows."
	progression_rate = 0
	cured_by = list(REAGENT_ID_PERIDAXON = 1.0, REAGENT_ID_INAPROVALINE = 0.8)
	worsened_by = list(REAGENT_ID_HYPERZINE = 1.0)
	// Worsens the heart while present; in the Critical stage rapidly.
	organ_damage_threshold = 0
	organ_damage_type = "internal"
	organ_damage_per_tick = 1.5
	organ_damage_targets = list(O_HEART)

/datum/medical_issue/condition/heart_damage/get_stages()
	var/static/list/S = list(
		"Moderate" = list(
			"name" = "cardiogenic shock",
			"description" = "The heart is failing to pump effectively. Tissue perfusion drops despite adequate blood volume.",
			"symptom_pool" = list(
				/datum/medical_symptom/chest_pain_crushing = 70,
				/datum/medical_symptom/short_breath        = 80,
				/datum/medical_symptom/pallor              = 70,
				/datum/medical_symptom/palpitations        = 50,
				/datum/medical_symptom/cyanosis            = 40,
			),
			"min_symptoms" = 2,
			"max_symptoms" = 4,
			"vital_effects" = list("bp_sys_mod" = -20, "bp_dia_mod" = -10, "o2_sat_mod" = -8),
		),
		"Critical" = list(
			"name" = "cardiac arrest",
			"description" = "The heart has stopped pumping effectively. Without intervention, irreversible brain injury follows within minutes.",
			"symptom_pool" = list(
				/datum/medical_symptom/chest_pain_crushing = 90,
				/datum/medical_symptom/cyanosis            = 60,
				/datum/medical_symptom/palpitations        = 60,
				/datum/medical_symptom/short_breath        = 70,
			),
			"min_symptoms" = 2,
			"max_symptoms" = 4,
			"vital_effects" = list("pulse_mod" = -30, "bp_sys_mod" = -50, "o2_sat_mod" = -10),
		),
	)
	return S


// --- Brain (staged: significant → critical) ----------------------------

/datum/medical_issue/condition/brain_damage
	name = "brain damage"
	category = "Brain"
	clinical_description = "Injury to brain tissue. Mild loss of cognition starts well before severe neurological collapse; advanced damage threatens herniation."
	progression_rate = 0
	cured_by = list(REAGENT_ID_ALKYSINE = 0.4)

/datum/medical_issue/condition/brain_damage/get_stages()
	var/static/list/S = list(
		"Significant" = list(
			"name" = "anoxic brain injury",
			"description" = "Brain tissue starved of oxygen long enough to show neurological deficits — confusion, slowed cognition, impaired vision. Alkysine can repair the underlying damage.",
			"symptom_pool" = list(
				/datum/medical_symptom/confusion            = 80,
				/datum/medical_symptom/blurred_vision       = 60,
				/datum/medical_symptom/dizziness            = 70,
				/datum/medical_symptom/unsteady_gait        = 60,
				/datum/medical_symptom/pupillary_asymmetry  = 50,
			),
			"min_symptoms" = 2,
			"max_symptoms" = 4,
		),
		"Critical" = list(
			"name" = "brain herniation",
			"description" = "Cranial pressure has displaced brain tissue past the structures that contain it. Past this point, neurological function does not return.",
			"symptom_pool" = list(
				/datum/medical_symptom/confusion      = 90,
				/datum/medical_symptom/blurred_vision = 80,
				/datum/medical_symptom/dizziness      = 80,
				/datum/medical_symptom/pallor         = 60,
			),
			"min_symptoms" = 2,
			"max_symptoms" = 4,
			"mechanical_effects" = list(
				"slowdown" = 2.5,
				"accuracy_penalty" = 60,
				"drop_held_prob" = 10,
				"block_typing" = TRUE,
				"blocked_verbs" = list("Surgery"),
				"spontaneous_emotes" = list("collapse", "groan"),
				"spontaneous_emote_prob" = 8,
			),
			"vital_effects" = list("pulse_mod" = -20, "bp_sys_mod" = -30, "o2_sat_mod" = -10),
		),
	)
	return S
