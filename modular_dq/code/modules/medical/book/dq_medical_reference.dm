// DQ Medical Reference — TGUI book documenting the cascading-condition
// system. Four tabs:
//
//   Conditions — each condition's clinical picture, cures, what causes
//                it (mixed: causes + upstream conditions), and what it
//                leads to (forward links to downstream conditions and
//                organ-damage outcomes).
//   Symptoms   — symptom catalogue with audiences, scanner phrases,
//                examine lines, and the conditions they appear in.
//   Reagents   — every cure/contraindicated reagent grouped by use.
//   Causes     — every non-condition cause (damage events, organ-damage
//                thresholds, blood loss, infection thresholds) and what
//                each produces.
//
// We instantiate each condition / symptom subtype once at build time to
// read list-literal vars that DM's `initial()` can't see (cured_by,
// worsened_by, symptom_pool, patient_messages). The cause registry uses
// its own lazy-init from dq_causes_registry() in
// modular_dq/code/modules/medical/causes/_cause.dm.


/obj/item/book/dq_medical_reference
	name = "Doctor's Encyclopedia"
	desc = "A clinical reference covering every traceable cascading condition, its presentation, and pharmacological response."
	icon_state = "book7"
	title = "Doctor's Encyclopedia"
	author = "DQ Medical Authority"
	unique = TRUE
	libcategory = "Reference"
	special_handling = TRUE

/obj/item/book/dq_medical_reference/attack_self(mob/user)
	tgui_interact(user)

/obj/item/book/dq_medical_reference/tgui_state(mob/user)
	return GLOB.tgui_physical_state

/obj/item/book/dq_medical_reference/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DQMedicalBook", name)
		ui.open()

/obj/item/book/dq_medical_reference/tgui_data(mob/user)
	var/list/data = list()
	data["conditions"] = _dq_book_conditions()
	data["symptoms"]   = _dq_book_symptoms()
	data["reagents"]   = _dq_book_reagents()
	data["causes"]     = _dq_book_causes()
	data["surgeries"]  = _dq_book_surgeries()
	return data

// --- builders ------------------------------------------------------------

/obj/item/book/dq_medical_reference/proc/_dq_book_conditions()
	var/list/out = list()
	for(var/T in subtypesof(/datum/medical_issue/condition))
		var/datum/medical_issue/condition/proto = new T()
		var/list/entry = list()
		entry["id"]              = "[T]"
		entry["name"]            = proto.name
		entry["category"]        = proto.category || "General"
		entry["subcategory"]     = proto.subcategory
		entry["description"]     = proto.clinical_description || ""
		entry["progression"]     = dq_describe_progression(proto.progression_rate)

		// Cures and worsens.
		var/list/cures = list()
		if(proto.cured_by)
			for(var/id in proto.cured_by)
				cures += list(list(
					"id"   = id,
					"name" = dq_reagent_display_name(id),
					"band" = dq_describe_cure_strength(proto.cured_by[id]),
				))
		entry["cures"] = cures

		var/list/worsens = list()
		if(proto.worsened_by)
			for(var/id in proto.worsened_by)
				worsens += list(list(
					"id"   = id,
					"name" = dq_reagent_display_name(id),
					"band" = dq_describe_worsen_strength(proto.worsened_by[id]),
				))
		entry["worsens"] = worsens

		// Caused by: every cause whose `produces` lists this type. The
		// entries name the cause's display name and id — the book links
		// these to the Causes tab.
		var/list/caused_by = list()
		for(var/datum/dq_cause/c as anything in dq_causes_producing(T))
			caused_by += list(_dq_cause_link(c))
		entry["caused_by"] = caused_by

		// Complications: forward links from this condition, grouped by
		// the cause they flow through. Two cause kinds contribute:
		//   - severity_gate causes whose source is this condition,
		//   - organ_damage causes watching an organ this condition
		//     damages.
		// Each entry shape: {cause_id, cause_name, conditions:[...]} so
		// the book can render the cause as a clickable section label
		// with the produced conditions as inline buttons.
		// Build (cause_id, cause_name, conditions[]) entries. Multiple
		// outcomes on a single cause that point at the same condition
		// (different stages of the same emergent) collapse into one
		// link — we dedupe by condition typepath. We also skip any
		// outcome that points at THIS condition (self-loop: e.g.
		// "Heart damage" complications would otherwise list "Heart
		// damage" itself because the heart_damage condition damages
		// the heart which the same cause watches).
		var/list/complications = list()
		for(var/datum/dq_cause/severity_gate/g as anything in dq_severity_gates_from(T))
			var/list/produced = list()
			var/list/seen = list()
			for(var/datum/dq_cause_outcome/o as anything in g.produces)
				if(o.condition_type == T)
					continue
				if(seen["[o.condition_type]"])
					continue
				seen["[o.condition_type]"] = TRUE
				produced += list(list(
					"id"   = "[o.condition_type]",
					"name" = _dq_condition_name(o.condition_type),
				))
			if(length(produced))
				complications += list(list(
					"cause_id"   = "[g.type]",
					"cause_name" = g.name,
					"conditions" = produced,
				))
		if(proto.organ_damage_type && proto.organ_damage_per_tick)
			var/list/target_organs = proto.organ_damage_targets?.Copy() || list()
			for(var/datum/dq_cause/organ_damage/od as anything in dq_causes_of_kind("/datum/dq_cause/organ_damage"))
				if(length(target_organs) && !(od.organ in target_organs))
					continue
				var/list/produced = list()
				var/list/seen = list()
				for(var/datum/dq_cause_outcome/o as anything in od.produces)
					if(o.condition_type == T)
						continue
					if(seen["[o.condition_type]"])
						continue
					seen["[o.condition_type]"] = TRUE
					produced += list(list(
						"id"   = "[o.condition_type]",
						"name" = _dq_condition_name(o.condition_type),
					))
				if(length(produced))
					complications += list(list(
						"cause_id"   = "[od.type]",
						"cause_name" = od.name,
						"conditions" = produced,
					))
		entry["complications"] = complications

		// Surgeries that treat this condition. The book renders each as
		// a clickable link to the Surgery tab.
		var/list/surgeries_treating = list()
		for(var/ST in subtypesof(/datum/dq_surgery))
			var/datum/dq_surgery/sp = new ST()
			if(sp.treats && (T in sp.treats))
				surgeries_treating += list(list(
					"id"   = "[ST]",
					"name" = sp.name,
				))
			qdel(sp)
		entry["surgeries"] = surgeries_treating

		// Staged conditions emit one entry per stage with that stage's
		// data; non-staged conditions emit a single anonymous "stage"
		// containing the default symptom_pool. The TGUI side renders
		// one section per stage.
		var/list/stages = proto.get_stages()
		var/list/stages_out = list()
		if(stages)
			for(var/stage_id in stages)
				var/list/sd = stages[stage_id]
				stages_out += list(_dq_emit_stage(stage_id, sd["name"], sd["description"], sd["symptom_pool"], sd["mechanical_effects"], sd["vital_effects"]))
		else
			stages_out += list(_dq_emit_stage(null, null, null, proto.symptom_pool, proto.mechanical_effects, proto.get_vital_effects()))
		entry["stages"] = stages_out
		// Keep entry["symptoms"] for back-compat: union of all stages'
		// symptoms so a casual reader sees what the condition can show.
		var/list/union_symptoms = list()
		var/list/seen_symptoms = list()
		for(var/list/sout in stages_out)
			for(var/list/s in sout["symptoms"])
				if(seen_symptoms[s["id"]])
					continue
				seen_symptoms[s["id"]] = TRUE
				union_symptoms += list(s)
		entry["symptoms"] = union_symptoms

		qdel(proto)
		out += list(entry)
	return out


/// Build one stage entry for the book: id, name (override), description,
/// symptom list with frequency bands, mechanical effects, vital effects.
/proc/_dq_emit_stage(stage_id, stage_name, stage_desc, list/symptom_pool, list/mechanical_effects, list/vital_effects)
	var/list/syms = list()
	if(symptom_pool)
		for(var/sym_path in symptom_pool)
			var/datum/medical_symptom/S = new sym_path()
			syms += list(list(
				"id"        = "[sym_path]",
				"name"      = S.name,
				"frequency" = dq_describe_symptom_frequency(symptom_pool[sym_path]),
			))
			qdel(S)
	var/list/mech = list()
	if(mechanical_effects)
		for(var/k in mechanical_effects)
			mech += list(list("key" = k, "value" = "[mechanical_effects[k]]"))
	var/list/vit = list()
	if(vital_effects)
		for(var/k in vital_effects)
			vit += list(list("key" = k, "value" = "[vital_effects[k]]"))
	return list(
		"id"                = stage_id,
		"name"              = stage_name,
		"description"       = stage_desc,
		"symptoms"          = syms,
		"mechanical_effects" = mech,
		"vital_effects"     = vit,
	)


/obj/item/book/dq_medical_reference/proc/_dq_book_symptoms()
	var/list/condition_index = list()
	for(var/CT in subtypesof(/datum/medical_issue/condition))
		var/datum/medical_issue/condition/cproto = new CT()
		if(cproto.symptom_pool)
			for(var/sym_path in cproto.symptom_pool)
				LAZYINITLIST(condition_index[sym_path])
				condition_index[sym_path] += list(list(
					"id"        = "[CT]",
					"name"      = cproto.name,
					"frequency" = dq_describe_symptom_frequency(cproto.symptom_pool[sym_path]),
				))
		qdel(cproto)

	var/list/out = list()
	for(var/T in subtypesof(/datum/medical_symptom))
		var/datum/medical_symptom/proto = new T()
		var/list/entry = list()
		entry["id"]          = "[T]"
		entry["name"]        = proto.name
		entry["category"]    = proto.category || "Subjective"
		entry["subcategory"] = proto.subcategory

		var/list/aud = list()
		if(proto.audiences & SYMPTOM_AUDIENCE_PATIENT)
			aud += "patient"
		if(proto.audiences & SYMPTOM_AUDIENCE_PUBLIC)
			aud += "public"
		if(proto.audiences & SYMPTOM_AUDIENCE_SCANNER)
			aud += "scanner"
		entry["audiences"]            = aud
		entry["clinical_description"] = proto.clinical_description || ""
		entry["patient_messages"]     = proto.get_patient_messages()?.Copy() || list()
		entry["public_emotes"]        = proto.get_public_emotes()?.Copy() || list()
		entry["scanner_phrase"]       = proto.scanner_phrase || ""
		entry["seen_in"]              = condition_index[T] || list()
		qdel(proto)
		out += list(entry)
	return out


/obj/item/book/dq_medical_reference/proc/_dq_book_reagents()
	var/list/by_id = list()
	for(var/T in subtypesof(/datum/medical_issue/condition))
		var/datum/medical_issue/condition/proto = new T()
		if(proto.cured_by)
			for(var/id in proto.cured_by)
				LAZYINITLIST(by_id[id])
				LAZYINITLIST(by_id[id]["cures"])
				by_id[id]["cures"] += list(list(
					"id"   = "[T]",
					"name" = proto.name,
					"band" = dq_describe_cure_strength(proto.cured_by[id]),
				))
		if(proto.worsened_by)
			for(var/id in proto.worsened_by)
				LAZYINITLIST(by_id[id])
				LAZYINITLIST(by_id[id]["worsens"])
				by_id[id]["worsens"] += list(list(
					"id"   = "[T]",
					"name" = proto.name,
					"band" = dq_describe_worsen_strength(proto.worsened_by[id]),
				))
		qdel(proto)

	var/list/out = list()
	for(var/id in by_id)
		var/list/entry = list()
		entry["id"]          = id
		entry["name"]        = dq_reagent_display_name(id)
		entry["category"]    = dq_reagent_category(id)
		entry["description"] = dq_reagent_description(id)
		entry["cures"]       = by_id[id]["cures"] || list()
		entry["worsens"]     = by_id[id]["worsens"] || list()
		out += list(entry)
	return out


/// Reference-book category for a reagent id. We don't have access to
/// the original authoring (these are upstream reagent datums), so the
/// book carries its own small table mapping the reagents the DQ medical
/// system actually uses. Unknown ids fall back to "Other".
///   Curative   — fixes the root cause (bicaridaze, alkysine, kelotane,
///                spaceacillin, dexalin-plus, dermaline, ...).
///   Stabilizer — buys time, slows the slide (inaprovaline, dexalin,
///                tricordrazine, myelamine, ...).
///   Stimulant  — body-mod boosters; almost always contraindicated for
///                medical conditions (hyperzine).
/proc/dq_reagent_category(reagent_id)
	var/static/list/cat
	if(!cat)
		cat = list(
			REAGENT_ID_BICARIDINE     = "Curative",
			REAGENT_ID_BICARIDAZE     = "Curative",
			REAGENT_ID_ALKYSINE       = "Organ repair",
			REAGENT_ID_IMIDAZOLINE    = "Organ repair",
			REAGENT_ID_PERIDAXON      = "Organ repair",
			REAGENT_ID_OSTEODAXON     = "Organ repair",
			REAGENT_ID_KELOTANE       = "Curative",
			REAGENT_ID_DERMALINE      = "Curative",
			REAGENT_ID_SPACEACILLIN   = "Curative",
			REAGENT_ID_DEXALINP       = "Curative",
			REAGENT_ID_ANTITOXIN      = "Curative",
			REAGENT_ID_TRICORDRAZINE  = "Stabilizer",
			REAGENT_ID_INAPROVALINE   = "Stabilizer",
			REAGENT_ID_DEXALIN        = "Stabilizer",
			REAGENT_ID_NUTRIMENT      = "Stabilizer",
			REAGENT_ID_IRON           = "Stabilizer",
			REAGENT_ID_HYPERZINE      = "Stimulant",
			REAGENT_ID_HYRONALIN      = "Curative",
			REAGENT_ID_ARITHRAZINE    = "Curative",
			REAGENT_ID_RYETALYN       = "Curative",
		)
	return cat[reagent_id] || "Other"


/obj/item/book/dq_medical_reference/proc/_dq_book_causes()
	var/list/out = list()
	for(var/datum/dq_cause/c as anything in dq_causes_registry())
		var/list/entry = list()
		entry["id"]          = "[c.type]"
		entry["name"]        = c.name
		entry["category"]    = c.category || "Trauma"
		entry["subcategory"] = c.subcategory
		entry["description"] = c.description
		entry["kind"]        = _dq_cause_kind(c)
		var/list/produces_out = list()
		for(var/datum/dq_cause_outcome/o as anything in c.produces)
			var/list/po = list()
			po["id"]   = "[o.condition_type]"
			po["name"] = _dq_condition_name(o.condition_type)
			po["band"] = dq_describe_cascade_chance(o.chance)
			po["tier"] = o.tier  // present for organ-damage tiered causes
			po["requires_present"] = o.requires_present ? _dq_condition_name(o.requires_present) : null
			po["requires_absent"]  = o.requires_absent ? _dq_condition_name(o.requires_absent) : null
			produces_out += list(po)
		entry["produces"] = produces_out
		out += list(entry)
	return out


/obj/item/book/dq_medical_reference/proc/_dq_book_surgeries()
	var/list/out = list()
	for(var/T in subtypesof(/datum/dq_surgery))
		var/datum/dq_surgery/proto = new T()
		var/list/entry = list()
		entry["id"]          = "[T]"
		entry["name"]        = proto.name
		entry["category"]    = proto.category || "Trauma"
		entry["subcategory"] = proto.subcategory
		entry["description"] = proto.description
		entry["body_region"] = proto.body_region
		entry["steps"]       = proto.steps?.Copy() || list()
		entry["tools"]       = proto.tools?.Copy() || list()
		var/list/treats = list()
		if(proto.treats)
			for(var/condition_type in proto.treats)
				treats += list(list(
					"id"   = "[condition_type]",
					"name" = _dq_condition_name(condition_type),
				))
		entry["treats"] = treats
		qdel(proto)
		out += list(entry)
	return out


// --- small helpers -------------------------------------------------------

/proc/_dq_cause_kind(datum/dq_cause/c)
	if(istype(c, /datum/dq_cause/damage_event))
		return "damage"
	if(istype(c, /datum/dq_cause/organ_damage))
		return "organ damage"
	if(istype(c, /datum/dq_cause/severity_gate))
		return "progression"
	if(istype(c, /datum/dq_cause/blood_loss))
		return "blood loss"
	if(istype(c, /datum/dq_cause/germ_level))
		return "infection"
	return "cause"

/proc/_dq_cause_link(datum/dq_cause/c)
	return list("id" = "[c.type]", "name" = c.name, "kind" = _dq_cause_kind(c))

/proc/_dq_condition_name(typepath)
	if(!ispath(typepath, /datum/medical_issue/condition))
		return "[typepath]"
	var/datum/medical_issue/condition/proto = new typepath()
	. = proto.name
	qdel(proto)


// --- qualitative-band translators ----------------------------------------

/proc/dq_describe_progression(rate)
	if(rate < -0.05)
		return "self-resolving"
	if(rate <= 0.05)
		return "stable until treated"
	if(rate < 1.0)
		return "slow progression"
	if(rate < 2.0)
		return "steady progression"
	return "rapid progression"

/proc/dq_describe_cure_strength(per_tick)
	if(per_tick >= 1.0)
		return "strong"
	if(per_tick >= 0.4)
		return "moderate"
	return "mild"

/proc/dq_describe_worsen_strength(per_tick)
	if(per_tick >= 1.0)
		return "severe aggravation"
	if(per_tick >= 0.4)
		return "moderate aggravation"
	return "mild aggravation"

/proc/dq_describe_cascade_chance(pct)
	if(pct >= 70)
		return "very likely"
	if(pct >= 40)
		return "likely"
	if(pct >= 20)
		return "uncommon"
	return "rare"

/proc/dq_describe_symptom_frequency(weight)
	if(weight >= 80)
		return "almost always present"
	if(weight >= 50)
		return "often present"
	if(weight >= 25)
		return "sometimes present"
	return "rarely present"

/proc/dq_reagent_display_name(reagent_id)
	if(!SSchemistry?.chemical_reagents)
		return reagent_id
	var/datum/reagent/R = SSchemistry.chemical_reagents[reagent_id]
	if(R?.name)
		return R.name
	return reagent_id

/proc/dq_reagent_description(reagent_id)
	if(!SSchemistry?.chemical_reagents)
		return ""
	var/datum/reagent/R = SSchemistry.chemical_reagents[reagent_id]
	return R?.description || ""
