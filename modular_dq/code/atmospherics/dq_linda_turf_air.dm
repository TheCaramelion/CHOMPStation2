// DQ-native LINDA bridge: persistent per-turf air for CHOMP /turf/simulated.
//
// LINDA's /turf/open subtype holds its mixture in `var/datum/gas_mixture/air`
// and /turf/open/return_air() returns it. CHOMP /turf/simulated DOESN'T
// inherit from /turf/open — so /turf/return_air() in LINDA_turf_tile.dm fires
// instead, which CREATES A NEW MIXTURE per call from initial_gas_mix. That
// makes turf air non-persistent: anything that adjusts gas via the returned
// mixture has zero effect on the actual turf.
//
// Bridge: add a persistent `air` var on /turf/simulated + lazy-init and an
// override of return_air. assume_air/remove_air also override to mutate the
// persistent mixture. This lets vents, scrubbers, fires, mob breathing, etc.
// observe and modify real per-turf state.
//
// LINDA's actual atmos simulation (SSair processing, hotspot expose, equalize)
// runs on /turf/open subtypes. CHOMP /turf/simulated doesn't get the full LINDA
// turf-graph treatment — it just exposes its persistent mixture for read/write
// by the CHOMP atmos machinery (vents, scrubbers, canisters, pipelines).

/turf/simulated
	var/datum/gas_mixture/air = null
	/// Whether atmos already attempted to lazy-init this turf's air. Stops
	/// repeat init churn for vacuum/space turfs that should stay empty.
	var/_atmos_lazyinit_done = FALSE

/turf/simulated/return_air()
	if(!air && !_atmos_lazyinit_done)
		_atmos_lazyinit_done = TRUE
		air = SSair.parse_gas_string(initial_gas_mix, /datum/gas_mixture/turf)
		if(air && (temperature != initial(temperature)))
			air.set_temperature(temperature)
	return air

/turf/simulated/assume_air(datum/gas_mixture/giver)
	if(!giver)
		return FALSE
	return_air() // lazy-init
	if(!air)
		return FALSE
	air.merge(giver)
	SSair.add_to_active(src)
	return TRUE

/turf/simulated/remove_air(amount)
	return_air() // lazy-init
	if(!air)
		return null
	var/datum/gas_mixture/removed = air.remove(amount)
	SSair.add_to_active(src)
	return removed


// === Hotspot bridge ===
//
// LINDA's hotspot system (/obj/effect/hotspot, T.active_hotspot, hotspot_expose)
// lives on /turf/open. CHOMP /turf/simulated doesn't inherit /turf/open, so the
// hundreds of CHOMP hotspot_expose() callers (igniters, candles, cigs, mines,
// flames, runes, doors burning, spell effects, anomalies) silently no-op.
//
// Bridge: replicate /turf/open's hotspot model on /turf/simulated, using our
// persistent return_air() mixture as the gas source.
/turf/simulated
	var/obj/effect/hotspot/active_hotspot
	/// LINDA tracks how long a hotspot has been on a tile so spreads decay.
	var/excited = FALSE
	/// Cooldown for hotspot fire-puff sound effect (read by /obj/effect/hotspot/Initialize).
	COOLDOWN_DECLARE(fire_puff_cooldown)

/turf/simulated/hotspot_expose(exposed_temperature, exposed_volume, soh = 0)
	if(exposed_temperature < TCMB)
		exposed_temperature = TCMB
	var/datum/gas_mixture/turf_air = return_air()
	if(!turf_air?.gases)
		return

	. = turf_air.gases[/datum/gas/oxygen]
	var/oxy = . ? .[MOLES] : 0
	if(oxy < 0.5)
		return
	. = turf_air.gases[/datum/gas/plasma]
	var/plas = . ? .[MOLES] : 0
	. = turf_air.gases[/datum/gas/tritium]
	var/trit = . ? .[MOLES] : 0
	. = turf_air.gases[/datum/gas/hydrogen]
	var/h2 = . ? .[MOLES] : 0
	. = turf_air.gases[/datum/gas/freon]
	var/freon = . ? .[MOLES] : 0

	if(active_hotspot)
		if(soh)
			if(plas > 0.5 || trit > 0.5 || h2 > 0.5)
				if(active_hotspot.temperature < exposed_temperature)
					active_hotspot.temperature = exposed_temperature
				if(active_hotspot.volume < exposed_volume)
					active_hotspot.volume = exposed_volume
			else if(freon > 0.5)
				if(active_hotspot.temperature > exposed_temperature)
					active_hotspot.temperature = exposed_temperature
				if(active_hotspot.volume < exposed_volume)
					active_hotspot.volume = exposed_volume
		return

	if(((exposed_temperature > PLASMA_MINIMUM_BURN_TEMPERATURE) && (plas > 0.5 || trit > 0.5 || h2 > 0.5)) || \
		((exposed_temperature < FREON_MAXIMUM_BURN_TEMPERATURE) && (freon > 0.5)))
		new /obj/effect/hotspot(src, exposed_volume * 25, exposed_temperature)
		SSair.add_to_active(src)


// hotspot perform_exposure override: /tg/'s implementation hard-types
// `location = loc as /turf/open` and returns FALSE if not /turf/open, which
// kills the hotspot during Initialize on /turf/simulated. Override to be
// type-agnostic — works for /turf/open or /turf/simulated as long as the
// turf has an `air` mixture (both do, via dq_linda_turf_air bridge above).
/obj/effect/hotspot/perform_exposure()
	var/turf/location = loc
	var/datum/gas_mixture/loc_air = null
	if(istype(location, /turf/open))
		var/turf/open/open_loc = location
		loc_air = open_loc.air
	else if(istype(location, /turf/simulated))
		var/turf/simulated/sim_loc = location
		loc_air = sim_loc.return_air()
	if(!loc_air)
		return FALSE

	var/datum/gas_mixture/reference

	// Replicate /turf/open active_hotspot replacement logic, but on a turf-typed var.
	var/obj/effect/hotspot/existing
	if(istype(location, /turf/open))
		var/turf/open/open_loc2 = location
		existing = open_loc2.active_hotspot
	else if(istype(location, /turf/simulated))
		var/turf/simulated/sim_loc2 = location
		existing = sim_loc2.active_hotspot

	if(existing && existing != src)
		if(existing.just_spawned)
			return FALSE
		if(!QDELETED(existing))
			qdel(existing)
	if(istype(location, /turf/open))
		var/turf/open/open_loc3 = location
		open_loc3.active_hotspot = src
	else if(istype(location, /turf/simulated))
		var/turf/simulated/sim_loc3 = location
		sim_loc3.active_hotspot = src

	bypassing = !just_spawned && (volume > CELL_VOLUME * 0.95)

	if(bypassing || cold_fire)
		reference = loc_air
	else
		var/datum/gas_mixture/affected = loc_air.remove_ratio(volume / loc_air.volume)
		if(affected)
			reference = affected
			affected.temperature = temperature
			affected.react(src)
			if(istype(location, /turf/open))
				var/turf/open/open_loc4 = location
				open_loc4.assume_air(affected)
			else if(istype(location, /turf/simulated))
				var/turf/simulated/sim_loc4 = location
				sim_loc4.assume_air(affected)

	if(reference)
		volume = 0
		var/list/cached_results = reference.reaction_results
		for(var/reaction in SSair.hotspot_reactions)
			volume += cached_results[reaction] * FIRE_GROWTH_RATE
		temperature = reference.temperature

	if(cold_fire)
		return TRUE

	for(var/A in location)
		var/atom/AT = A
		if(!QDELETED(AT) && AT != src)
			AT.fire_act(temperature, volume)
	return TRUE


// CHOMP lingering-fire bridge — same pattern as xgm_compat_shim's /turf/open
// overrides, but for /turf/simulated.

/turf/simulated/lingering_fire()
	return active_hotspot

/turf/simulated/feed_lingering_fire(intensity = 1)
	var/temp = T0C + 300 * max(0.1, intensity)
	hotspot_expose(temp, CELL_VOLUME * 0.5, soh = TRUE)
	SSair.add_to_active(src)

/turf/simulated/create_fire(temp = T0C + 300)
	hotspot_expose(temp, CELL_VOLUME, soh = FALSE)
	SSair.add_to_active(src)
