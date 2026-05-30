// xgm_total_moles compat helper tests.
//
// Verifies the helper proc that bridges XGM's `mix.total_moles` (var) and
// LINDA's `mix.total_moles()` (proc) for CHOMP callers that need to compile
// in both atmos engines. See modular_dq/code/__defines/atmospherics.dm.
//
// Run with: bin/test.cmd (or whatever invokes dm.exe with -DUNIT_TESTS).

/datum/unit_test/xgm_total_moles_helper

/datum/unit_test/xgm_total_moles_helper/Run()
	// 1. Helper handles null safely.
	TEST_ASSERT_EQUAL(xgm_total_moles(null), 0, "null mixture should return 0 moles")

	// 2. Helper returns 0 for an empty mixture.
	var/datum/gas_mixture/empty_mix = new(CELL_VOLUME)
	TEST_ASSERT_NOTNULL(empty_mix, "should construct an empty gas_mixture")
	TEST_ASSERT_EQUAL(xgm_total_moles(empty_mix), 0, "empty mixture has 0 total moles")

	// 3. Helper returns the actual molar sum after adding gas.
	#ifdef USE_LINDA_ATMOS
	// LINDA path — adjust_moles takes /datum/gas type path; we keep the test
	// engine-agnostic by going through the LINDA_GAS_ADJUST macro which
	// delegates to adjust_gas(id_str, delta) via the compat shim.
	LINDA_GAS_ADJUST(empty_mix, "oxygen", 5)
	#else
	// XGM path — adjust_gas with the GAS_O2 string constant.
	empty_mix.adjust_gas(GAS_O2, 5)
	empty_mix.update_values()
	#endif
	TEST_ASSERT_EQUAL(xgm_total_moles(empty_mix), 5, "after adding 5 moles, total should be 5")

	// 4. Sum is additive across multiple gases.
	#ifdef USE_LINDA_ATMOS
	LINDA_GAS_ADJUST(empty_mix, "nitrogen", 3)
	#else
	empty_mix.adjust_gas(GAS_N2, 3)
	empty_mix.update_values()
	#endif
	TEST_ASSERT_EQUAL(xgm_total_moles(empty_mix), 8, "5 + 3 = 8 total moles")
