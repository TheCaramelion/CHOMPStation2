// Symptom library — starter set for trauma / burn / infection conditions.
// New symptoms live alongside these; one symptom per stanza for grep-ability.
//
// The `patient_messages` and `public_emotes` lists live in per-subtype
// procs rather than instance vars. Each returns a `var/static/list/`
// local, so the message data is allocated exactly once per subtype on
// first read and shared across every active instance. The base class
// returns null for both, so a symptom that never speaks to the patient
// or public allocates no list at all. See _symptom.dm.

// --- Pain ---

/datum/medical_symptom/sharp_pain
	name = "sharp pain"
	category = "Observable"
	clinical_description = "Sudden, localized pain at the site of injury; intensifies with motion."
	examine_line = "They wince whenever they shift their weight."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	patient_message_chance = 7
	public_emote_chance = 4

/datum/medical_symptom/sharp_pain/get_patient_messages()
	var/static/list/L = list(
		"A sharp pain stabs through your body.",
		"Your injury flares with pain.",
	)
	return L

/datum/medical_symptom/sharp_pain/get_public_emotes()
	var/static/list/L = list("winces in pain", "grimaces")
	return L


/datum/medical_symptom/throbbing_pain
	name = "throbbing pain"
	category = "Subjective"
	clinical_description = "Deep, rhythmic pain synchronised with the cardiac cycle."
	audiences = SYMPTOM_AUDIENCE_PATIENT
	patient_message_chance = 5

/datum/medical_symptom/throbbing_pain/get_patient_messages()
	var/static/list/L = list(
		"A deep, throbbing pain pulses inside you.",
		"Your injury throbs with each heartbeat.",
	)
	return L


/datum/medical_symptom/chest_pain_crushing
	name = "crushing chest pain"
	category = "Observable"
	clinical_description = "Severe substernal pressure, often radiating; a hallmark of cardiac distress."
	examine_line = "They are clutching their chest in obvious distress."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	patient_message_chance = 8
	public_emote_chance = 5

/datum/medical_symptom/chest_pain_crushing/get_patient_messages()
	var/static/list/L = list(
		"A crushing pressure builds in your chest.",
		"Your chest feels like it's being squeezed in a vice.",
	)
	return L

/datum/medical_symptom/chest_pain_crushing/get_public_emotes()
	var/static/list/L = list("clutches their chest", "grimaces and clutches at their chest")
	return L


// --- Patient-only sensations ---

/datum/medical_symptom/headache
	name = "headache"
	category = "Subjective"
	clinical_description = "Diffuse cranial pain, frequently retro-orbital."
	audiences = SYMPTOM_AUDIENCE_PATIENT
	patient_message_chance = 5

/datum/medical_symptom/headache/get_patient_messages()
	var/static/list/L = list(
		"A dull headache builds behind your eyes.",
		"Your head throbs.",
	)
	return L


/datum/medical_symptom/dizziness
	name = "dizziness"
	category = "Subjective"
	clinical_description = "Transient loss of equilibrium and spatial orientation."
	audiences = SYMPTOM_AUDIENCE_PATIENT
	patient_message_chance = 5

/datum/medical_symptom/dizziness/get_patient_messages()
	var/static/list/L = list(
		"The room sways for a moment.",
		"You feel briefly lightheaded.",
		"Your balance feels off.",
	)
	return L


/datum/medical_symptom/blurred_vision
	name = "blurred vision"
	category = "Subjective"
	clinical_description = "Reduced visual acuity, particularly at the periphery."
	audiences = SYMPTOM_AUDIENCE_PATIENT

/datum/medical_symptom/blurred_vision/get_patient_messages()
	var/static/list/L = list(
		"Your vision blurs at the edges.",
		"It's hard to focus your eyes.",
	)
	return L


/datum/medical_symptom/internal_pressure
	name = "internal pressure"
	category = "Subjective"
	clinical_description = "Vague visceral pressure without clear localisation; commonly precedes overt hemorrhage."
	audiences = SYMPTOM_AUDIENCE_PATIENT
	patient_message_chance = 3

/datum/medical_symptom/internal_pressure/get_patient_messages()
	var/static/list/L = list(
		"You feel an odd pressure deep inside.",
		"Something doesn't feel right.",
	)
	return L


/datum/medical_symptom/abdominal_tenderness
	name = "abdominal tenderness"
	category = "Diagnosable"
	clinical_description = "Pain on palpation of the abdomen; suggests inflammation or internal hemorrhage."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_SCANNER
	patient_message_chance = 3
	scanner_phrase = "abdominal tenderness on palpation"

/datum/medical_symptom/abdominal_tenderness/get_patient_messages()
	var/static/list/L = list(
		"Your belly feels tender when you move.",
	)
	return L


/datum/medical_symptom/chills
	name = "chills"
	category = "Observable"
	clinical_description = "Involuntary shivering and a subjective sensation of cold."
	examine_line = "They are visibly shivering."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	public_emote_chance = 3

/datum/medical_symptom/chills/get_patient_messages()
	var/static/list/L = list(
		"A cold shiver runs through you.",
		"You feel a sudden chill.",
	)
	return L

/datum/medical_symptom/chills/get_public_emotes()
	var/static/list/L = list("shivers")
	return L


/datum/medical_symptom/fever_sensation
	name = "feverish sensation"
	category = "Observable"
	clinical_description = "Warmth across the body and flushed skin, often without measurable core temperature change."
	examine_line = "Their face is flushed and beaded with sweat."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	public_emote_chance = 2

/datum/medical_symptom/fever_sensation/get_patient_messages()
	var/static/list/L = list(
		"You feel uncomfortably warm.",
		"Your skin feels flushed.",
	)
	return L

/datum/medical_symptom/fever_sensation/get_public_emotes()
	var/static/list/L = list("looks flushed", "wipes their brow")
	return L


/datum/medical_symptom/nausea
	name = "nausea"
	category = "Subjective"
	clinical_description = "Urge to vomit; frequently autonomic rather than gastric in origin."
	audiences = SYMPTOM_AUDIENCE_PATIENT

/datum/medical_symptom/nausea/get_patient_messages()
	var/static/list/L = list(
		"You feel queasy.",
		"Your stomach turns.",
	)
	return L


/datum/medical_symptom/fatigue
	name = "fatigue"
	category = "Subjective"
	clinical_description = "Generalised loss of stamina and concentration disproportionate to recent exertion."
	audiences = SYMPTOM_AUDIENCE_PATIENT

/datum/medical_symptom/fatigue/get_patient_messages()
	var/static/list/L = list(
		"You feel inexplicably tired.",
		"It's getting hard to stay alert.",
	)
	return L


// --- Public + scanner (visible signs) ---

/datum/medical_symptom/pallor
	name = "pallor"
	category = "Observable"
	clinical_description = "Pale complexion from reduced peripheral perfusion; visible in mucous membranes."
	examine_line = "They look unnaturally pale."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "abnormally pale skin"

/datum/medical_symptom/pallor/get_public_emotes()
	var/static/list/L = list("looks pale")
	return L


/datum/medical_symptom/cyanosis
	name = "cyanosis"
	category = "Observable"
	clinical_description = "Bluish discolouration of the lips and extremities indicating impaired oxygenation."
	examine_line = "Their lips and fingertips have a bluish tinge."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "cyanosis of the lips and extremities"

/datum/medical_symptom/cyanosis/get_public_emotes()
	var/static/list/L = list("has a faint blue tinge to their lips")
	return L


// --- Multi-channel ---

/datum/medical_symptom/short_breath
	name = "shortness of breath"
	category = "Observable"
	clinical_description = "Subjective sense of inadequate ventilation accompanied by tachypnea."
	examine_line = "Their breathing is quick and shallow."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 4
	scanner_phrase = "elevated respiratory rate"

/datum/medical_symptom/short_breath/get_patient_messages()
	var/static/list/L = list(
		"You're having trouble catching your breath.",
		"Each breath feels harder than the last.",
	)
	return L

/datum/medical_symptom/short_breath/get_public_emotes()
	var/static/list/L = list("breathes heavily")
	return L


/datum/medical_symptom/confusion
	name = "confusion"
	category = "Observable"
	clinical_description = "Disorientation, slowed cognition, and impaired short-term memory."
	examine_line = "They look disoriented, their gaze unfocused."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	public_emote_chance = 2

/datum/medical_symptom/confusion/get_patient_messages()
	var/static/list/L = list(
		"You can't remember what you were just doing.",
		"Your thoughts feel scattered.",
	)
	return L

/datum/medical_symptom/confusion/get_public_emotes()
	var/static/list/L = list("looks confused", "stares blankly")
	return L


/datum/medical_symptom/palpitations
	name = "palpitations"
	category = "Diagnosable"
	clinical_description = "Awareness of irregular or forceful cardiac contractions."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_SCANNER
	scanner_phrase = "irregular cardiac rhythm"

/datum/medical_symptom/palpitations/get_patient_messages()
	var/static/list/L = list(
		"Your heart skips a beat.",
		"Your chest flutters strangely.",
	)
	return L


// --- Respiratory ---

/datum/medical_symptom/wet_cough
	name = "wet cough"
	category = "Observable"
	clinical_description = "Productive cough with audible fluid; suggests pulmonary contusion or fluid accumulation."
	examine_line = "They cough wetly into their hand, leaving a damp smear."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 5
	scanner_phrase = "productive cough with fluid"

/datum/medical_symptom/wet_cough/get_patient_messages()
	var/static/list/L = list(
		"You cough up something wet.",
		"You taste copper in your mouth.",
	)
	return L

/datum/medical_symptom/wet_cough/get_public_emotes()
	var/static/list/L = list("coughs wetly")
	return L


/datum/medical_symptom/wheeze
	name = "wheezing"
	category = "Observable"
	clinical_description = "High-pitched musical sound on expiration from narrowed airways."
	examine_line = "Every breath comes with a faint whistle."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 4
	scanner_phrase = "audible wheeze on auscultation"

/datum/medical_symptom/wheeze/get_patient_messages()
	var/static/list/L = list(
		"Each breath comes with a whistling sound.",
	)
	return L

/datum/medical_symptom/wheeze/get_public_emotes()
	var/static/list/L = list("wheezes")
	return L


/datum/medical_symptom/labored_breathing
	name = "labored breathing"
	category = "Observable"
	clinical_description = "Visible use of accessory respiratory muscles; each breath requires conscious effort."
	examine_line = "They are visibly struggling for each breath."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 5
	scanner_phrase = "severely labored respiration"

/datum/medical_symptom/labored_breathing/get_patient_messages()
	var/static/list/L = list(
		"You're working hard for every breath.",
		"Each inhale takes effort.",
	)
	return L

/datum/medical_symptom/labored_breathing/get_public_emotes()
	var/static/list/L = list("gasps", "struggles to breathe")
	return L


/datum/medical_symptom/sharp_chest_pain
	name = "sharp chest pain"
	category = "Observable"
	clinical_description = "Pleuritic chest pain worsened by inspiration; suggestive of pneumothorax or rib fracture."
	examine_line = "They wince sharply each time they inhale."
	audiences = SYMPTOM_AUDIENCE_PATIENT | SYMPTOM_AUDIENCE_PUBLIC
	patient_message_chance = 7
	public_emote_chance = 3

/datum/medical_symptom/sharp_chest_pain/get_patient_messages()
	var/static/list/L = list(
		"A sharp pain shoots through your chest with each breath.",
		"Your chest feels like it's being stabbed.",
	)
	return L

/datum/medical_symptom/sharp_chest_pain/get_public_emotes()
	var/static/list/L = list("winces while breathing")
	return L


// --- Limb-specific ---

/datum/medical_symptom/bleeding_visible
	name = "external bleeding"
	category = "Observable"
	clinical_description = "Active blood loss from an external wound; the rate indicates vessel involvement."
	examine_line = "They are bleeding heavily."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 3
	scanner_phrase = "active external blood loss"

/datum/medical_symptom/bleeding_visible/get_public_emotes()
	var/static/list/L = list("bleeds heavily")
	return L


/datum/medical_symptom/numbness_arm
	name = "numb arm"
	category = "Subjective"
	clinical_description = "Loss of sensation in the affected arm and hand; reduced fine-motor function."
	audiences = SYMPTOM_AUDIENCE_PATIENT

/datum/medical_symptom/numbness_arm/get_patient_messages()
	var/static/list/L = list(
		"Your arm feels numb and useless.",
		"You can barely feel your fingers.",
	)
	return L


/datum/medical_symptom/numbness_leg
	name = "numb leg"
	category = "Subjective"
	clinical_description = "Loss of sensation in the affected leg and foot; reduced proprioception."
	audiences = SYMPTOM_AUDIENCE_PATIENT

/datum/medical_symptom/numbness_leg/get_patient_messages()
	var/static/list/L = list(
		"Your leg feels numb and dead.",
		"You can barely feel where your foot ends.",
	)
	return L


/datum/medical_symptom/burning_limb
	name = "burning limb"
	category = "Subjective"
	clinical_description = "Deep, persistent burning sensation in the affected limb without visible cause."
	audiences = SYMPTOM_AUDIENCE_PATIENT
	patient_message_chance = 6

/datum/medical_symptom/burning_limb/get_patient_messages()
	var/static/list/L = list(
		"Your limb feels like it's on fire from the inside.",
		"There's an unbearable burning sensation deep in the tissue.",
	)
	return L


/datum/medical_symptom/jaundice
	name = "jaundice"
	category = "Observable"
	clinical_description = "Yellow tinge to the skin and the whites of the eyes from accumulated metabolic byproducts the liver can no longer clear."
	examine_line = "There's a faint yellow cast to their skin."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "icterus on inspection"

/datum/medical_symptom/jaundice/get_public_emotes()
	var/static/list/L = list("looks faintly yellow")
	return L


// --- Diagnostic markers --- scanner-visible findings for conditions
// whose subjective symptoms would otherwise be invisible to medics.

/datum/medical_symptom/absent_reflex
	name = "absent reflex"
	category = "Diagnosable"
	clinical_description = "The limb fails to respond to reflex testing; the affected peripheral nerve is no longer conducting normally."
	audiences = SYMPTOM_AUDIENCE_SCANNER
	scanner_phrase = "no reflex response in affected limb; suspected peripheral nerve damage"


/datum/medical_symptom/cold_mottled_skin
	name = "cold, mottled skin"
	category = "Observable"
	clinical_description = "Patches of grey-purple discoloration over the affected tissue, cold to the touch. The tissue underneath has died."
	examine_line = "Their skin is patchy and grey in places, cool to the touch."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "discoloured, devitalised tissue; necrosis confirmed"

/datum/medical_symptom/cold_mottled_skin/get_public_emotes()
	var/static/list/L = list("has a patch of skin that looks grey and lifeless")
	return L


/datum/medical_symptom/radiation_reading
	name = "elevated radiation reading"
	category = "Diagnosable"
	clinical_description = "The patient's body is registering above-background ionising radiation. Tissue damage will follow if exposure continues."
	audiences = SYMPTOM_AUDIENCE_SCANNER
	scanner_phrase = "elevated radiation signature in patient tissue"


/datum/medical_symptom/genetic_instability
	name = "genetic instability"
	category = "Diagnosable"
	clinical_description = "The patient's chromosomes are fragmenting. The genome is no longer transcribing cleanly; mitotically active tissues will degrade first."
	audiences = SYMPTOM_AUDIENCE_SCANNER
	scanner_phrase = "chromosomal damage detected in nucleated cells"


// --- More observable signs to improve identifiability for partially-
// visible conditions (concussion, ischemic_vision_loss, subdural_hematoma,
// brain_damage Significant, tendon_severed).

/datum/medical_symptom/unsteady_gait
	name = "unsteady gait"
	category = "Observable"
	clinical_description = "The patient sways or stumbles when standing or walking; balance and proprioception are impaired."
	examine_line = "They look unsteady on their feet."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 3
	scanner_phrase = "ataxia on motor examination"

/datum/medical_symptom/unsteady_gait/get_public_emotes()
	var/static/list/L = list("sways unsteadily", "stumbles slightly")
	return L


/datum/medical_symptom/pupillary_asymmetry
	name = "uneven pupils"
	category = "Observable"
	clinical_description = "The patient's pupils are unequal in size. A reliable sign of raised intracranial pressure or focal brain injury."
	examine_line = "Their pupils don't look quite the same size."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 1
	scanner_phrase = "anisocoria; suspected intracranial pathology"

/datum/medical_symptom/pupillary_asymmetry/get_public_emotes()
	var/static/list/L = list("blinks slowly, one pupil noticeably larger than the other")
	return L


/datum/medical_symptom/cloudy_eye
	name = "cloudy eye"
	category = "Observable"
	clinical_description = "The lens or retina is visibly damaged; the eye looks dull and unresponsive to light."
	examine_line = "Their eye looks oddly cloudy."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "loss of retinal definition; vision compromised"

/datum/medical_symptom/cloudy_eye/get_public_emotes()
	var/static/list/L = list("squints, one eye unfocused")
	return L


/datum/medical_symptom/limb_weakness
	name = "limb weakness"
	category = "Observable"
	clinical_description = "The patient can't fully extend or grip with the affected limb; motor control on one side is reduced."
	examine_line = "Their limb hangs limply."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 3
	scanner_phrase = "motor weakness in affected limb"

/datum/medical_symptom/limb_weakness/get_public_emotes()
	var/static/list/L = list("can't quite grip with their affected hand", "drags their leg slightly")
	return L


/datum/medical_symptom/skin_burns_minor
	name = "early radiation burns"
	category = "Observable"
	clinical_description = "Patchy erythema and skin breakdown — an early dermal sign of radiation exposure that precedes overt sickness."
	examine_line = "Their skin shows red, raw patches in places."
	audiences = SYMPTOM_AUDIENCE_PUBLIC | SYMPTOM_AUDIENCE_SCANNER
	public_emote_chance = 2
	scanner_phrase = "dermal radiation injury; early burns visible"

/datum/medical_symptom/skin_burns_minor/get_public_emotes()
	var/static/list/L = list("has red, raw patches of skin")
	return L
