// DQ atmos / LINDA migration tests.
//
// Validates the ZAS→LINDA engine swap with CHOMP machinery on top:
//   1. verdigris.dll loaded — Rust auxmos lib responds to call_ext
//   2. gas_mixture procs work — adjust_gas, total_moles, return_pressure roundtrip
//   3. /turf/simulated/air persistence — dq_linda_turf_air bridge keeps moles
//      across return_air() calls (without it CHOMP machinery would mutate
//      throwaway copies and the world wouldn't atmos)
//   4. CHOMP canister presets — /obj/machinery/portable_atmospherics/canister/X
//      types initialize with their preset gas content
//   5. SSair init — gas singleton metadata reached Rust via auxtools_atmos_init

/// Verifies that verdigris.dll is actually loaded — verdigris_version() should
/// return a non-empty string. If empty, the Rust library failed to load and
/// the rest of LINDA is running on /tg/'s pure-DM gas_mixture impl.
/datum/unit_test/dq_verdigris_loaded

/datum/unit_test/dq_verdigris_loaded/Run()
	var/version = verdigris_version()
	TEST_ASSERT_NOTNULL(version, "verdigris_version() returned null — DLL did not load")
	TEST_ASSERT(length("[version]") > 0, "verdigris_version() returned empty — call_ext failed")
	var/features = verdigris_features()
	TEST_ASSERT_NOTNULL(features, "verdigris_features() returned null")
	// Log to test output so we can see the version in CI logs.
	log_test("Verdigris loaded: [version] | features: [features]")


/// Verifies a gas_mixture round-trips through LINDA's gas_mixture API.
/// Builds via adjust_gas (XGM-compat shim accepting type path), reads back via
/// total_moles() (proc) and return_pressure() (auxmos byondapi bind or DM).
/datum/unit_test/dq_gas_mixture_rust_roundtrip

/datum/unit_test/dq_gas_mixture_rust_roundtrip/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	TEST_ASSERT_NOTNULL(mix, "Failed to allocate gas_mixture")

	mix.adjust_gas(/datum/gas/oxygen, MOLES_O2STANDARD)
	mix.adjust_gas(/datum/gas/nitrogen, MOLES_N2STANDARD)
	mix.temperature = T20C

	var/total = mix.total_moles()
	TEST_ASSERT(total > 0, "total_moles() returned 0 after adjust_gas: [total]")
	TEST_ASSERT(abs(total - (MOLES_O2STANDARD + MOLES_N2STANDARD)) < 0.01, \
		"total_moles() = [total], expected ~[MOLES_O2STANDARD + MOLES_N2STANDARD]")

	var/pressure = mix.return_pressure()
	TEST_ASSERT(abs(pressure - ONE_ATMOSPHERE) < 5, \
		"return_pressure() = [pressure], expected ~[ONE_ATMOSPHERE]")

	var/temp = mix.return_temperature()
	TEST_ASSERT_EQUAL(temp, T20C, "return_temperature() drifted: [temp] vs [T20C]")


/// Verifies the /turf/simulated/air persistence bridge (dq_linda_turf_air.dm).
/// Without it, every T.return_air() call returns a NEW throwaway mixture and
/// CHOMP atmos machinery would silently fail. This test mutates a turf's air
/// and checks the mutation persists across a second return_air() call.
/datum/unit_test/dq_turf_air_persistence

/datum/unit_test/dq_turf_air_persistence/Run()
	var/turf/simulated/T = null
	for(var/turf/simulated/sim_turf in world)
		if(sim_turf.return_air())
			T = sim_turf
			break
	TEST_ASSERT_NOTNULL(T, "No simulated turf with air available for persistence test")

	var/datum/gas_mixture/air = T.return_air()
	TEST_ASSERT_NOTNULL(air, "return_air() returned null on simulated turf")
	var/initial_total = air.total_moles()

	// Mutate via adjust_gas. If the bridge is missing, the mutation lands on
	// a throwaway and a second return_air() shows initial_total again.
	air.adjust_gas(/datum/gas/oxygen, 50)

	var/datum/gas_mixture/air2 = T.return_air()
	TEST_ASSERT(air2 == air, \
		"return_air() returned a different mixture object on second call — bridge missing!")
	var/total_after = air2.total_moles()
	TEST_ASSERT(total_after > initial_total, \
		"Turf air did not persist: initial=[initial_total], after add=[total_after]")


/// Verifies CHOMP canister presets initialize with their declared gas content.
/datum/unit_test/dq_chomp_canister_presets_have_gas

/datum/unit_test/dq_chomp_canister_presets_have_gas/Run()
	for(var/canister_type in list(
		/obj/machinery/portable_atmospherics/canister/oxygen,
		/obj/machinery/portable_atmospherics/canister/nitrogen,
		/obj/machinery/portable_atmospherics/canister/phoron,
		/obj/machinery/portable_atmospherics/canister/carbon_dioxide,
		/obj/machinery/portable_atmospherics/canister/air,
	))
		var/obj/machinery/portable_atmospherics/canister/C = new canister_type(locate(1, 1, 1))
		TEST_ASSERT_NOTNULL(C, "[canister_type]: failed to construct")
		TEST_ASSERT_NOTNULL(C.air_contents, "[canister_type]: air_contents not allocated")
		var/moles = C.air_contents.total_moles()
		TEST_ASSERT(moles > 1, "[canister_type]: starting moles too low ([moles])")
		var/pressure = C.air_contents.return_pressure()
		TEST_ASSERT(pressure > ONE_ATMOSPHERE, \
			"[canister_type]: pressure too low ([pressure] kPa) — canister should be pressurized")
		qdel(C)


/// Verifies SSair successfully called auxtools_atmos_init at boot — that gas
/// reaction singletons were instantiated. If auxtools_atmos_init crashed,
/// gas_reactions would be empty and burn() / equalize() would fail at runtime.
/datum/unit_test/dq_ssair_initialized

/datum/unit_test/dq_ssair_initialized/Run()
	TEST_ASSERT_NOTNULL(SSair, "SSair is null — subsystem failed to initialize")
	TEST_ASSERT(SSair.initialized, "SSair did not finish Initialize()")
	TEST_ASSERT_NOTNULL(SSair.gas_reactions, "SSair.gas_reactions list is null")
	TEST_ASSERT(length(SSair.gas_reactions) > 0, \
		"SSair.gas_reactions is empty — gas_mixture reactions wouldn't fire")


/// Verifies GLOB.gas_data was populated at construction from /datum/gas
/// subtypes. CHOMP atmos analyzer, supply demand events, hydroponics, bomb
/// tester, and engineering announcements all read GLOB.gas_data.name[gas_id]
/// to render gas-aware UI. If empty, every label would show as "null".
/datum/unit_test/dq_gas_data_populated

/datum/unit_test/dq_gas_data_populated/Run()
	TEST_ASSERT_NOTNULL(GLOB.gas_data, "GLOB.gas_data is null")
	TEST_ASSERT_NOTNULL(GLOB.gas_data.name, "GLOB.gas_data.name list is null")
	TEST_ASSERT(length(GLOB.gas_data.name) >= 5, \
		"GLOB.gas_data.name only has [length(GLOB.gas_data.name)] entries")
	// Spot-check core gas IDs CHOMP UI strings depend on.
	for(var/gas_id in list(GAS_O2, GAS_N2, GAS_CO2, GAS_PHORON, GAS_N2O))
		TEST_ASSERT(!isnull(GLOB.gas_data.name[gas_id]), \
			"GLOB.gas_data.name\[[gas_id]\] is null — atmos analyzer/UI will display null")
		TEST_ASSERT(GLOB.gas_data.specific_heat[gas_id] > 0, \
			"GLOB.gas_data.specific_heat\[[gas_id]\] is 0 — scrubber power calc would NaN")


/// Verifies gas_mixture.gas_ids() returns XGM string ids for every gas in the
/// mixture. CHOMP scrub_gas/filter_gas iterate via this proc; if it returns
/// an empty list, every scrubber/filter silently no-ops.
/datum/unit_test/dq_gas_ids_lists_present_gases

/datum/unit_test/dq_gas_ids_lists_present_gases/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.adjust_gas(/datum/gas/oxygen, 10)
	mix.adjust_gas(/datum/gas/carbon_dioxide, 5)
	mix.adjust_gas(/datum/gas/plasma, 2)

	var/list/ids = mix.gas_ids()
	TEST_ASSERT_NOTNULL(ids, "gas_ids() returned null")
	TEST_ASSERT_EQUAL(length(ids), 3, "gas_ids() length [length(ids)], expected 3")
	TEST_ASSERT(GAS_O2 in ids, "gas_ids() missing GAS_O2 ([GAS_O2]); has: [json_encode(ids)]")
	TEST_ASSERT(GAS_CO2 in ids, "gas_ids() missing GAS_CO2 ([GAS_CO2])")
	TEST_ASSERT(GAS_PHORON in ids, "gas_ids() missing GAS_PHORON ([GAS_PHORON]) — should map to plasma since #define wins")


/// Verifies plasma combustion reaction fires when given oxygen + plasma + heat.
/// The vendored /tg/ plasmafire reaction consumes plasma+O2 above
/// PLASMA_MINIMUM_BURN_TEMPERATURE and produces CO2 + water_vapor.
/datum/unit_test/dq_plasmafire_reaction_consumes_plasma

/datum/unit_test/dq_plasmafire_reaction_consumes_plasma/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.adjust_gas(/datum/gas/plasma, 50)
	mix.adjust_gas(/datum/gas/oxygen, 200) // plenty of oxidizer
	mix.set_temperature(PLASMA_MINIMUM_BURN_TEMPERATURE + 200)

	var/initial_plasma = mix.get_moles(/datum/gas/plasma)
	var/initial_o2 = mix.get_moles(/datum/gas/oxygen)
	var/initial_co2 = mix.get_moles(/datum/gas/carbon_dioxide)
	TEST_ASSERT(initial_plasma > 0, "plasma not added: [initial_plasma]")

	mix.react(null)

	var/post_plasma = mix.get_moles(/datum/gas/plasma)
	var/post_o2 = mix.get_moles(/datum/gas/oxygen)
	var/post_co2 = mix.get_moles(/datum/gas/carbon_dioxide)
	TEST_ASSERT(post_plasma < initial_plasma, \
		"plasma did not burn: [initial_plasma] → [post_plasma]")
	TEST_ASSERT(post_o2 < initial_o2, \
		"oxygen did not deplete: [initial_o2] → [post_o2]")
	TEST_ASSERT(post_co2 > initial_co2, \
		"CO2 not produced: [initial_co2] → [post_co2]")
	TEST_ASSERT(mix.temperature > PLASMA_MINIMUM_BURN_TEMPERATURE + 200, \
		"temperature did not rise from exothermic reaction: [mix.temperature]")


/// Verifies scrub_gas() helper actually transfers gas. Without the gas_ids()
/// migration this proc no-op'd because it iterated `source.gas` (empty).
/datum/unit_test/dq_scrub_gas_removes_target

/datum/unit_test/dq_scrub_gas_removes_target/Run()
	var/datum/gas_mixture/source = new(CELL_VOLUME)
	source.adjust_gas(/datum/gas/oxygen, 80)
	source.adjust_gas(/datum/gas/carbon_dioxide, 50)
	source.set_temperature(T20C)

	var/datum/gas_mixture/sink = new(CELL_VOLUME)
	sink.set_temperature(T20C)

	var/before_source_co2 = source.get_moles(/datum/gas/carbon_dioxide)
	var/before_source_o2 = source.get_moles(/datum/gas/oxygen)

	// Scrub only CO2 (string-id keyed list, like vent_scrubber.dm's scrubbing_gas).
	var/power = scrub_gas(null, list(GAS_CO2), source, sink, 100, null)
	TEST_ASSERT(power >= 0, "scrub_gas returned [power] — no transfer happened; gas_ids() bridge broken")

	var/after_source_co2 = source.get_moles(/datum/gas/carbon_dioxide)
	var/after_source_o2 = source.get_moles(/datum/gas/oxygen)
	var/sink_co2 = sink.get_moles(/datum/gas/carbon_dioxide)
	TEST_ASSERT(after_source_co2 < before_source_co2, \
		"CO2 not removed from source: [before_source_co2] → [after_source_co2]")
	TEST_ASSERT(sink_co2 > 0, "CO2 not deposited into sink: [sink_co2]")
	TEST_ASSERT_EQUAL(after_source_o2, before_source_o2, \
		"O2 should be untouched by CO2-only scrub: [before_source_o2] → [after_source_o2]")


/// Verifies canister.release() transfers gas from canister to its turf air.
/// Exercises portable_atmospherics + the /turf/simulated/air bridge end-to-end.
/datum/unit_test/dq_canister_release_to_turf

/datum/unit_test/dq_canister_release_to_turf/Run()
	var/turf/simulated/T = null
	for(var/turf/simulated/sim_turf in world)
		if(sim_turf.return_air())
			T = sim_turf
			break
	TEST_ASSERT_NOTNULL(T, "no simulated turf with air for canister test")

	var/obj/machinery/portable_atmospherics/canister/oxygen/C = new(T)
	TEST_ASSERT_NOTNULL(C, "failed to construct canister")
	TEST_ASSERT_NOTNULL(C.air_contents, "canister air_contents null")

	var/initial_canister_o2 = C.air_contents.get_moles(/datum/gas/oxygen)
	TEST_ASSERT(initial_canister_o2 > 100, \
		"oxygen canister starting moles too low: [initial_canister_o2]")

	var/datum/gas_mixture/turf_air = T.return_air()
	var/initial_turf_o2 = turf_air.get_moles(/datum/gas/oxygen)

	// Open the canister to release.
	C.valve_open = TRUE
	C.release_pressure = 1000 // high release for fast transfer
	// Drive the canister's release loop directly. process() (not process_atmos())
	// is what runs the valve transfer in CHOMP's portable_atmospherics machinery.
	for(var/i in 1 to 10)
		C.process()

	var/final_canister_o2 = C.air_contents.get_moles(/datum/gas/oxygen)
	var/final_turf_o2 = T.return_air().get_moles(/datum/gas/oxygen)
	TEST_ASSERT(final_canister_o2 < initial_canister_o2, \
		"canister O2 didn't drop: [initial_canister_o2] → [final_canister_o2]")
	TEST_ASSERT(final_turf_o2 > initial_turf_o2, \
		"turf O2 didn't rise after canister release: [initial_turf_o2] → [final_turf_o2]")

	qdel(C)


/// Verifies that hotspot_expose() on a turf with combustible gas creates an
/// /obj/effect/hotspot. The LINDA hotspot system is what represents on-tile
/// fires after the ZAS /obj/fire layer was retired.
/datum/unit_test/dq_hotspot_expose_creates_fire

/datum/unit_test/dq_hotspot_expose_creates_fire/Run()
	var/turf/simulated/T = null
	for(var/turf/simulated/sim_turf in world)
		if(sim_turf.return_air())
			T = sim_turf
			break
	TEST_ASSERT_NOTNULL(T, "no simulated turf for hotspot test")

	// Wipe any preexisting hotspot from earlier tests.
	if(T.active_hotspot)
		qdel(T.active_hotspot)
		T.active_hotspot = null

	// Stock the turf with plasma + oxygen so hotspot can sustain.
	var/datum/gas_mixture/air = T.return_air()
	air.adjust_gas(/datum/gas/plasma, 20)
	air.adjust_gas(/datum/gas/oxygen, 50)
	air.set_temperature(PLASMA_MINIMUM_BURN_TEMPERATURE + 300)

	TEST_ASSERT(isnull(T.active_hotspot), "test setup: hotspot already exists pre-expose")

	T.hotspot_expose(PLASMA_MINIMUM_BURN_TEMPERATURE + 300, CELL_VOLUME, soh = TRUE)

	TEST_ASSERT_NOTNULL(T.active_hotspot, "active_hotspot not created after hotspot_expose")
	TEST_ASSERT(istype(T.active_hotspot, /obj/effect/hotspot), \
		"active_hotspot wrong type: [T.active_hotspot.type]")

	if(T.active_hotspot)
		qdel(T.active_hotspot)
		T.active_hotspot = null


/// Verifies a human's handle_breath cycle consumes O2 and produces CO2 against
/// a LINDA gas_mixture. This is the full mob breath integration path:
/// life.dm uses LINDA_GAS_AMT / adjust_gas_temp through the xgm_compat_shim.
/datum/unit_test/dq_human_breath_cycle

/datum/unit_test/dq_human_breath_cycle/Run()
	var/mob/living/carbon/human/H = allocate(/mob/living/carbon/human)
	TEST_ASSERT_NOTNULL(H, "couldn't allocate test human")
	TEST_ASSERT_NOTNULL(H.species, "test human has no species")

	// Build a standard-atmosphere breath mixture.
	var/datum/gas_mixture/breath = new(BREATH_VOLUME)
	breath.adjust_gas(/datum/gas/oxygen, MOLES_O2STANDARD)
	breath.adjust_gas(/datum/gas/nitrogen, MOLES_N2STANDARD)
	breath.set_temperature(T20C)

	var/initial_o2 = breath.get_moles(/datum/gas/oxygen)
	var/initial_co2 = breath.get_moles(/datum/gas/carbon_dioxide)

	H.handle_breath(breath)

	var/final_o2 = breath.get_moles(/datum/gas/oxygen)
	var/final_co2 = breath.get_moles(/datum/gas/carbon_dioxide)

	TEST_ASSERT(final_o2 < initial_o2, \
		"breath O2 didn't drop: [initial_o2] → [final_o2] — human handle_breath didn't consume oxygen")
	TEST_ASSERT(final_co2 > initial_co2, \
		"breath CO2 didn't rise: [initial_co2] → [final_co2] — human handle_breath didn't exhale CO2")


/// Verifies atmosanalyzer_scan returns lines with real gas names. This was
/// broken pre-fix because GLOB.gas_data.name was empty and `for(g in mix.gas)`
/// iterated an empty list — analyzers would say "Pressure: 100 kPa" with no
/// gas breakdown. Now both should work.
/datum/unit_test/dq_atmos_analyzer_lists_gases

/datum/unit_test/dq_atmos_analyzer_lists_gases/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.adjust_gas(/datum/gas/oxygen, MOLES_O2STANDARD)
	mix.adjust_gas(/datum/gas/nitrogen, MOLES_N2STANDARD)
	mix.set_temperature(T20C)

	var/list/result = atmosanalyzer_scan(null, mix, null)
	TEST_ASSERT_NOTNULL(result, "atmosanalyzer_scan returned null")
	TEST_ASSERT(length(result) >= 3, "expected ≥3 result lines, got [length(result)]")

	var/has_o2_line = FALSE
	var/has_n2_line = FALSE
	var/has_pressure_line = FALSE
	for(var/line in result)
		if(findtext(line, "Oxygen"))
			has_o2_line = TRUE
		if(findtext(line, "Nitrogen"))
			has_n2_line = TRUE
		if(findtext(line, "Pressure"))
			has_pressure_line = TRUE
	TEST_ASSERT(has_pressure_line, "analyzer missing 'Pressure' line: [json_encode(result)]")
	TEST_ASSERT(has_o2_line, "analyzer missing 'Oxygen' line: [json_encode(result)]")
	TEST_ASSERT(has_n2_line, "analyzer missing 'Nitrogen' line: [json_encode(result)]")


/// Verifies gas_mixture.merge() (auxmos byondapi-bound) preserves total moles
/// across mixtures. Pipenet share/merge depends on this being correct.
/datum/unit_test/dq_gas_mixture_merge_conserves_moles

/datum/unit_test/dq_gas_mixture_merge_conserves_moles/Run()
	var/datum/gas_mixture/A = new(CELL_VOLUME)
	A.adjust_gas(/datum/gas/oxygen, 50)
	A.adjust_gas(/datum/gas/nitrogen, 100)
	A.set_temperature(T20C)
	var/a_moles = A.total_moles()

	var/datum/gas_mixture/B = new(CELL_VOLUME)
	B.adjust_gas(/datum/gas/carbon_dioxide, 30)
	B.set_temperature(T20C)
	var/b_moles = B.total_moles()

	A.merge(B)

	var/combined = A.total_moles()
	TEST_ASSERT(abs(combined - (a_moles + b_moles)) < 0.01, \
		"merge moles wrong: [a_moles] + [b_moles] != [combined]")
	TEST_ASSERT(A.get_moles(/datum/gas/carbon_dioxide) > 0, \
		"merge didn't bring CO2 from B into A")


/// Verifies gas_mixture.remove(amount) takes the specified moles and returns
/// a new mixture with those moles. Canister release + remove_volume() rely on
/// this.
/datum/unit_test/dq_gas_mixture_remove_takes_moles

/datum/unit_test/dq_gas_mixture_remove_takes_moles/Run()
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.adjust_gas(/datum/gas/oxygen, 200)
	mix.set_temperature(T20C)

	var/initial = mix.total_moles()
	var/datum/gas_mixture/removed = mix.remove(50)

	TEST_ASSERT_NOTNULL(removed, "remove() returned null")
	var/after = mix.total_moles()
	var/removed_amt = removed.total_moles()
	TEST_ASSERT(abs(after - (initial - 50)) < 0.5, \
		"source moles wrong after remove: expected [initial - 50], got [after]")
	TEST_ASSERT(abs(removed_amt - 50) < 0.5, \
		"removed amount wrong: expected 50, got [removed_amt]")


/// Verifies the CHOMP /turf/proc/feed_lingering_fire bridge spawns a hotspot
/// when fed sufficient fuel intensity. Floor acts and CHOMP gameplay code call
/// this — if the bridge no-ops, lingering fires just don't exist.
/datum/unit_test/dq_lingering_fire_bridge

/datum/unit_test/dq_lingering_fire_bridge/Run()
	var/turf/simulated/T = null
	for(var/turf/simulated/sim_turf in world)
		if(sim_turf.return_air())
			T = sim_turf
			break
	TEST_ASSERT_NOTNULL(T, "no simulated turf for lingering fire test")

	if(T.active_hotspot)
		qdel(T.active_hotspot)
		T.active_hotspot = null

	// Stock with fuel + oxidizer.
	var/datum/gas_mixture/air = T.return_air()
	air.adjust_gas(/datum/gas/plasma, 30)
	air.adjust_gas(/datum/gas/oxygen, 80)
	air.set_temperature(T20C)

	T.feed_lingering_fire(2.0)

	TEST_ASSERT_NOTNULL(T.active_hotspot, "feed_lingering_fire didn't spawn an active_hotspot")
	TEST_ASSERT_NOTNULL(T.lingering_fire(), "lingering_fire() returns null despite active_hotspot")

	if(T.active_hotspot)
		qdel(T.active_hotspot)
		T.active_hotspot = null
