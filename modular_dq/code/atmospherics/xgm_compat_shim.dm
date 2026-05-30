// XGM → LINDA compatibility shim.
//
// Gated under USE_LINDA_ATMOS. Provides forwarding procs on /datum/gas_mixture
// so a subset of CHOMP/XGM-style call sites continue to compile and run while
// per-site migration to LINDA's /datum/gas-typed API is in progress.
//
// SCOPE: proc-call call sites only. Var-access call sites (e.g. `mix.gas[GAS_O2]`)
// are NOT covered by this shim — BYOND does not support computed-property
// getters and adding a `var/list/gas` alias would either silently desync from
// LINDA's `gases` storage or pay per-access translation cost across every read.
// Those sites need per-call rewrite.
//
// EXTEND THIS FILE AS NEW XGM PROCS ARE DISCOVERED IN COMPILE ERRORS, not by
// rewriting LINDA's gas_mixture.dm directly (keeps the vendor diff minimal).

/datum/gas_mixture/proc/get_xgm_id_for_gas(gas_id_string)
	// Map XGM string ID → /datum/gas type path. Populated lazily on first call.
	// Built from initial(gas.id) on every /datum/gas subtype, matching CHOMP's
	// XGM ids ("oxygen", "nitrogen", "phoron", "carbon_dioxide", …).
	var/static/list/xgm_id_to_type
	if (isnull(xgm_id_to_type))
		xgm_id_to_type = list()
		for (var/datum/gas/gas_type as anything in subtypesof(/datum/gas))
			xgm_id_to_type[initial(gas_type.id)] = gas_type
	return xgm_id_to_type[gas_id_string]

// XGM: gas_mix.update_values() — recompute totals after mutating .gas[].
// LINDA: a no-op (auxmos auto-archives; total_moles is recomputed on read).
/datum/gas_mixture/proc/update_values()
	return

// XGM: gas_mix.update_nearby_tiles() — kick neighbor tiles into the SSair queue.
// LINDA: forward to /turf/proc/update_air_ref or equivalent if the mixture is
// turf-bound; otherwise no-op. (LINDA tracks turf activation differently.)
/datum/gas_mixture/proc/update_nearby_tiles()
	return

// adjust_gas is now defined natively by /tg/'s gas_mixture.dm (line 186) with
// signature `(gas, amount)` where `gas` is a /datum/gas type path. CHOMP callers
// pass XGM string ids ("oxygen", "phoron"). Override here to accept BOTH:
// - if arg is a string, look up the /datum/gas type via get_xgm_id_for_gas
// - if it's already a type path, pass through to /tg/'s impl
/datum/gas_mixture/adjust_gas(gas, amount, update = 1)
	if (istext(gas))
		var/datum/gas/gas_type = get_xgm_id_for_gas(gas)
		if (isnull(gas_type) || amount == 0)
			return
		ASSERT_GAS(gas_type, src)
		gases[gas_type][MOLES] += amount
		if(gases[gas_type][MOLES] <= 0)
			gases -= gas_type
		return
	// Type-path path — call /tg/'s native impl shape.
	if (amount == 0)
		return
	ASSERT_GAS(gas, src)
	gases[gas][MOLES] += amount
	if(gases[gas][MOLES] <= 0)
		gases -= gas

// XGM: add_thermal_energy(joules) — add heat at current heat_capacity.
// LINDA: temperature += joules / heat_capacity().
/datum/gas_mixture/proc/add_thermal_energy(joules)
	var/cap = heat_capacity()
	if (cap <= 0)
		return
	set_temperature((temperature * cap + joules) / cap)

// XGM: get_by_flag(flag) — sum moles of all gases matching a flag.
// LINDA does not have XGM's flag bitmask on /datum/gas; this returns 0 as a
// safe default. Per-site adapt to use LINDA's gas-type-specific accessors.
/datum/gas_mixture/proc/get_by_flag(flag)
	return 0

// XGM: remove_by_flag(flag, amount) — remove moles of flag-matching gases.
// LINDA equivalent is /datum/gas_mixture/proc/remove_by_flag (auxmos bind) for
// some flags; for others, no-op until per-site adaptation.
/datum/gas_mixture/proc/remove_by_flag_xgm(flag, amount)
	return null

// XGM: update_graphic() — refresh the gas overlay rendering.
// LINDA: /datum/gas_mixture/proc/update_graphic is handled by /tg/'s
// gas overlay system; if a CHOMP turf calls it on a non-turf mixture, no-op.
/datum/gas_mixture/proc/update_graphic_xgm()
	return


// === /atom/movable and /turf level XGM-API stubs ===
//
// ZAS exposed atmos-touching procs as methods on /atom/movable (so any object
// can mark its surroundings as needing zone-graph rebuild). LINDA tracks turf
// activation via SSair queues, not per-atom calls. The stubs let CHOMP machinery
// (doors, blast doors, airlocks, embedded controllers) compile; the actual
// "kick the neighbor tiles" behavior comes from LINDA's adjacency rebuild
// triggered by turf changes.

// ZAS used this to invalidate the zone graph around a moved/changed atom.
// LINDA equivalent: rebuild the turf's atmos_adjacent_turfs (since the atom
// may now block or unblock atmos passage in a direction) and add it to active
// so a fresh share happens next SSair tick. Real impl, not a stub.
/atom/movable/proc/update_nearby_tiles(need_rebuild = 0)
	var/turf/T = get_turf(src)
	if(T && SSair?.initialized)
		T.air_update_turf(TRUE, FALSE)
	return TRUE

// ZAS: gas overlay refresh on a turf. LINDA does this through /turf/open/floor's
// gas overlay rendering (gas_visual_overlays list). Shim no-op until per-site adapt.
/turf/proc/update_graphic(list/graphic_add = null, list/graphic_remove = null)
	return

// ZAS: turf-level air_blocked test used by airflow code (which is gated out
// under LINDA). The few non-airflow callers want "can air pass through this
// turf right now?" — LINDA expects ATMOS_PASS_NO/_YES on the turf var directly.
// Shim returns FALSE (air not blocked) as a safe default.
/turf/proc/c_airblock(turf/T)
	return FALSE

// ZAS: SSair.air_blocked(T1, T2) — pair-wise blockage check. No LINDA equivalent;
// shim returns FALSE.
/datum/controller/subsystem/air/proc/air_blocked(turf/A, turf/B)
	return FALSE

// ZAS: SSair.mark_for_update(T) — schedule a turf for zone-graph rebuild.
// LINDA equivalent is SSair.add_to_active(T, 1). Shim forwards if available,
// else no-op.
/datum/controller/subsystem/air/proc/mark_for_update(turf/T)
	if (hascall(src, "add_to_active"))
		call(src, "add_to_active")(T, 1)
	return

// mark_zone_update deleted — 0 callers. Zones don't exist under LINDA.


// === XGM proc-on-mixture stubs that callers reach via local var unqualified ===

// CHOMP's `breathe()` accesses `breath.total_moles` as a VAR. LINDA exposes
// `total_moles()` as a PROC (since it's computed from gases[]). Adding a var
// would shadow the proc — instead, per-site rewrite is needed (breath.total_moles()).
// No shim possible. Documented for awareness in TG_UPSTREAM.md.

// CHOMP's life code reads `breath.gas[GAS_O2]` etc. as a VAR ACCESS. LINDA stores
// gases in `gases[/datum/gas/oxygen][MOLES]`. Cannot be shimmed via a property
// getter (BYOND has none). Per-site rewrite is needed.

// CHOMP's older code calls `assume_gas(gas_id, moles, temp)` on a TURF directly,
// expecting the turf's air to absorb it. Bridge to the persistent turf air via
// adjust_gas (xgm_compat_shim's adjust_gas accepts XGM string ids).
/turf/proc/assume_gas(gas_id, amount, temp)
	var/datum/gas_mixture/air = return_air()
	if(!air || amount <= 0)
		return FALSE
	air.adjust_gas(gas_id, amount)
	if(!isnull(temp) && temp > 0)
		// Weighted average temperature
		var/old_total = max(air.total_moles() - amount, 0)
		if(old_total > 0)
			air.set_temperature((air.temperature * old_total + temp * amount) / (old_total + amount))
		else
			air.set_temperature(temp)
	if(SSair)
		SSair.add_to_active(src)
	return TRUE

// return_air_for_internal_lifeform — /atom base + cryo cell override defined
// in code/game/machinery/cryo.dm:347. Don't redeclare here.


// === GLOB.gas_data stub ===
// XGM exposes a /datum/xgm_gas_data global with `.name`, `.specific_heat`,
// `.molar_mass`, `.gases` lists keyed by XGM string gas id. CHOMP callers
// (gas analyzer, bomb tester, supply demand, hydroponics, atmos events,
// internal wiki) all read these to display gas info.
//
// Populate from LINDA's /datum/gas subtypes at construction so the same
// XGM-shaped lookups now resolve to LINDA gas metadata.

/datum/xgm_gas_data
	var/list/name = list()
	var/list/specific_heat = list()
	var/list/molar_mass = list()
	var/list/gases = list()
	var/list/tile_overlay = list()
	var/list/molar_specific_volume = list()

/datum/xgm_gas_data/New()
	. = ..()
	for(var/datum/gas/g as anything in subtypesof(/datum/gas))
		var/gas_id = initial(g.id)
		if(!gas_id)
			continue
		name[gas_id] = initial(g.name)
		specific_heat[gas_id] = initial(g.specific_heat)
		molar_mass[gas_id] = initial(g.specific_heat) * 0.05 // crude approximation; LINDA doesn't track molar mass
		gases[gas_id] = g
		molar_specific_volume[gas_id] = 0.001

GLOBAL_DATUM_INIT(gas_data, /datum/xgm_gas_data, new())


// === /datum/gas_mixture proc shims for XGM-style callers ===

// XGM: adjust_gas_temp(gas_id, moles, temp) — add moles + their heat contribution.
// Direct LINDA-shape impl: weighted thermal energy = (old_moles * old_temp + new_moles * new_temp) / total.
/datum/gas_mixture/proc/adjust_gas_temp(gas_id, moles, temp, update = 1)
	if (moles <= 0)
		return
	var/datum/gas/gas_type = get_xgm_id_for_gas(gas_id)
	if (isnull(gas_type))
		return
	var/old_total = total_moles()
	ASSERT_GAS(gas_type, src)
	gases[gas_type][MOLES] += moles
	if (old_total > 0)
		temperature = (temperature * old_total + temp * moles) / (old_total + moles)
	else
		temperature = temp

// XGM: specific_entropy() — used by old phoron decompression code (now gated).
// Stub returns a small constant so any straggling caller doesn't divide-by-zero.
/datum/gas_mixture/proc/specific_entropy()
	return 0.1

// XGM: specific_entropy_gas(gas_id) — same.
/datum/gas_mixture/proc/specific_entropy_gas(gas_id)
	return 0.1

// XGM: remove_volume(removed_volume) — remove a fraction by volume. LINDA
// equivalent is /datum/gas_mixture/proc/remove(amount) where amount is moles.
// Approximate: remove fraction = removed_volume / volume.
/datum/gas_mixture/proc/remove_volume(removed_volume)
	if (volume <= 0)
		return null
	return remove_ratio(min(1, removed_volume / volume))


// === /tg/-side macros that vendor relies on ===

// IS_FINITE and GET_TURF_PLANE_OFFSET moved to modular_dq/code/__defines/atmospherics.dm
// so they're in scope when vendored /tg/ atmos files reference them.


// === Stub globals/datums for /tg/ machinery that we vendored but didn't include ===

// GLOB.electrolyzer_reactions defined once in tg_infra_stubs.dm.


// === Additional XGM compat shims for restored CHOMP atmos machinery ===

// XGM gas_mixture had a `group_multiplier` var that pipenets used to amplify
// the gas content of a shared pipe network. LINDA doesn't have this concept —
// pipenets share via merge/share calls directly. Default 1 (no amplification)
// so CHOMP code that reads `mix.group_multiplier` works.
/datum/gas_mixture/var/group_multiplier = 1

// XGM .gas[] — the dict of "gas_id_string" → moles. LINDA stores moles in
// gases[/datum/gas/type][MOLES]. We can't unify these in one var since BYOND
// has no computed-property getters. Instead:
//   - .gas[GAS_X] reads return 0 (the var is an empty list).
//   - Use LINDA_GAS_AMT(mix, GAS_X) for moles reads.
//   - Use mix.adjust_gas(GAS_X, delta) for writes (xgm_compat shim handles both
//     strings and type paths).
//   - For ITERATION over the mixture's present gases (used by scrubbers,
//     filters, air alarms, atmos analyzers, supply demand), use gas_ids()
//     which derives a fresh list of XGM string ids from gases[].
//
// Keep .gas declared so legacy reads compile to "0"; iteration sites have been
// migrated to gas_ids() per-call.
/datum/gas_mixture/var/list/gas = list()

// Return a list of XGM string ids for every /datum/gas type currently present
// in this mixture. Used as the migration target for `for(var/g in mix.gas)`
// and `filtering & mix.gas` sites that depended on XGM's string-keyed gas dict.
/datum/gas_mixture/proc/gas_ids()
	. = list()
	if(!gases)
		return
	for(var/datum/gas/g as anything in gases)
		. += initial(g.id)

// XGM adjust_multi(g1, n1, g2, n2, ...) — variadic gas adjustment helper.
// Already declared in tg_infra_stubs at one point; live here now.
/datum/gas_mixture/proc/adjust_multi(...)
	var/list/L = args
	var/i = 1
	while(i < length(L))
		adjust_gas(L[i], L[i + 1])
		i += 2

// XGM exposed return_pressure/return_temperature on /obj/item/tank as methods
// that forwarded to air_contents.*. LINDA gas_mixture has these as procs.
/obj/item/tank/proc/return_pressure()
	if(air_contents)
		return air_contents.return_pressure()
	return 0

/obj/item/tank/proc/return_temperature()
	if(air_contents)
		return air_contents.temperature
	return 0

// XGM share_ratio(other, ratio) — LINDA's share() takes a coefficient.
/datum/gas_mixture/proc/share_ratio(datum/gas_mixture/sharer, ratio)
	if(!sharer)
		return
	share(sharer, 4, 4)

// XGM remove_by_flag(flag, amount) — no LINDA equivalent without flag system.
/datum/gas_mixture/proc/remove_by_flag(flag, amount)
	return null


// Real biohazard-protection checks used by nanogoop floors and stardogs to
// decide whether a human's worn gear blocks dermal contact attacks. A suit /
// head item with permeability_coefficient ≤ 0.1 is considered sealed.
/mob/living/carbon/human/proc/pl_suit_protected()
	var/obj/item/clothing/C = wear_suit
	if(istype(C) && C.permeability_coefficient <= 0.1)
		return TRUE
	return FALSE

/mob/living/carbon/human/proc/pl_head_protected()
	var/obj/item/clothing/C = head
	if(istype(C) && C.permeability_coefficient <= 0.1)
		return TRUE
	return FALSE

// Still referenced by life.dm (item-contamination check) and vore custom
// items (modkit eligibility). Real var, not a stub — set to 1 when an item
// gets phoron/foreign goo on it. No callers SET it yet (ZAS contamination
// machinery wasn't ported), so it stays at 0 — but the var has to exist.
/atom/var/contaminated = 0
GLOBAL_VAR_INIT(contamination_overlay, null)


// lingering_fire/feed_lingering_fire/create_fire moved to
// modular_dq/code/atmospherics/dq_linda_turf_air.dm where the rest of the
// /turf/open atmos hooks live. Base /turf no-ops added here for callers that
// hold an untyped /turf reference (walls, space-as-typed).
/turf/proc/lingering_fire()
	return null
/turf/proc/feed_lingering_fire(intensity = 1)
	return
/turf/proc/create_fire(temp = T0C + 300)
	return


// === GLOB.vsc.plc.CONTAMINATION_LOSS — old config-loaded constant ===
/datum/contamination_settings_stub
	var/CONTAMINATION_LOSS = 0

/datum/vsc_stub
	var/datum/contamination_settings_stub/plc = new
	var/airflow_delay = 0
/datum/vsc_stub/New()
	plc = new()
GLOBAL_DATUM_INIT(vsc, /datum/vsc_stub, new())


// === /datum/xgm_gas_data flags/overlay_limit (read from life.dm) ===
/datum/xgm_gas_data/var/list/flags = list()
/datum/xgm_gas_data/var/list/overlay_limit = list()

// /datum/decl/xgm_gas — base type for code/defines/gases.dm decls. Original
// declaration was in deleted code/modules/xgm/xgm_gas_data.dm. Re-add the base
// type so subtype definitions resolve their var defaults.
/datum/decl/xgm_gas
	var/id = ""
	var/name = ""
	var/specific_heat = 0
	var/molar_mass = 0
	var/overlay_limit = 0
	var/tile_overlay = null
	var/flags = 0
	var/condensation_temperature = 0
	var/condensation_product = null
	var/condensation_energy = 0
	var/burn_product = null
	var/burn_product_energy = 0


// /turf/var/zone — CHOMP /datum/pipeline (code/ATMOSPHERICS/datum_pipeline.dm)
// branches on `target.zone` and reads zone.air for venting calculations. ZAS
// zones don't exist under LINDA; we keep zone declared as a typed-null var so
// static-type-checked reads (`target.zone.air.X`) compile. zone stays null at
// runtime so the branches that check `target.zone` never fire — pipelines fall
// through to the /turf branch, which does its work via return_air()/assume_air()
// against the LINDA-bridged turf mixture.
// /turf.zone + /datum/zone + SSair.zones/active_zones/tiles_to_update + RebootZAS
// + recurse_zone — all removed. Live callers (datum_pipeline.dm, diagnostics.dm,
// mapping.dm) have been rewritten to use LINDA's turf.air / active_turfs /
// excited_groups directly.
//
// pl_effects still has callers in toxins.dm — phoron exposure contamination
// cycle. ZAS-only feature; reagent code calls it on every life tick. No-op
// until we either port the contamination system or rip the callers out of
// toxins.dm.
/mob/living/proc/pl_effects()
	return

// CHOMP datum_pipeline.dm references member.air_temporary.multiply during gas
// rebalancing in the merge step. LINDA gas_mixture has multiply as a byondapi
// binding; keep the DM fallback declared so compile-time resolution finds it.
/datum/gas_mixture/proc/multiply(num_val)
	if(num_val == 1 || !gases)
		return
	for(var/datum/gas/g as anything in gases)
		gases[g][MOLES] *= num_val

// pipeline_expansion still overridden by CHOMP pipe_base.dm:60 onward — it's
// a real /tg/ proc that CHOMP pipe subtypes use to enumerate their network
// neighbors. The base no-op is the canonical declaration; subtypes provide
// the real return value.
/obj/machinery/atmospherics/proc/pipeline_expansion(datum/pipeline/net)
	return list()

/datum/pipeline/var/building = FALSE


// /obj/fire — was the ZAS fire effect. LINDA uses /obj/effect/hotspot now.
// Stub the path so CHOMP code that references /obj/fire (closet contents,
// fusion core field, fire alarm) compiles. At runtime, fire is /obj/effect/hotspot.
/obj/fire
	name = "fire (deprecated)"
	icon = 'icons/effects/fire.dmi'
	icon_state = "1"
	anchored = TRUE
	mouse_opacity = 0


// /datum/connection_edge + equalize_gases + /datum/gas_mixture/multiply deleted
// — 0 callers in the live build.

// gas_thruster XGM procs — get_mass (sum of moles × molar mass) and
// check_combustability (true if mix can burn).
/datum/gas_mixture/proc/get_mass()
	// Rough mass — sum each gas's moles × molar mass from gas_data lookup.
	. = 0
	for(var/datum/gas/g as anything in gases)
		var/molar_mass = initial(g.specific_heat) * 0.05  // crude approximation
		. += gases[g][MOLES] * molar_mass

/datum/gas_mixture/proc/check_combustability()
	if(!gases)
		return FALSE
	// Combustable if there's oxidizer + fuel.
	var/oxy = gases[/datum/gas/oxygen] ? gases[/datum/gas/oxygen][MOLES] : 0
	if(oxy < 0.5)
		return FALSE
	var/fuel = 0
	for(var/datum/gas/g as anything in gases)
		if(g == /datum/gas/plasma || g == /datum/gas/tritium || g == /datum/gas/hydrogen)
			fuel += gases[g][MOLES]
	return fuel >= 0.5

// /turf.connections + /datum/zas_connection_holder deleted — 0 callers.


// /datum/pipe_icon_manager + get_atmos_icon is now defined in CHOMP's
// _atmos_setup.dm. No stub needed.


// xgm_total_moles helper lives in modular_dq/code/__defines/atmospherics.dm
// (always-included, ifdef-branched) so the same callsite compiles in both
// XGM and LINDA builds.


// LINDA_GAS_AMT and LINDA_GAS_ADJUST macros are defined in
// modular_dq/code/__defines/atmospherics.dm (loaded early so they're in
// scope when CHOMP-source callsites that the rewrite script touched are
// preprocessed). This shim provides the runtime support procs they call.
