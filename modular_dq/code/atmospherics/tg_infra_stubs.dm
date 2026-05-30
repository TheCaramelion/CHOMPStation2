// Stubs for /tg/ infrastructure that the vendored LINDA atmos files (SSair,
// LINDA_*, reactions, gas_mixture) reference but CHOMP doesn't natively
// provide. CHOMP atmos MACHINERY is restored and lives in code/ATMOSPHERICS/
// and code/game/machinery/atmoalter/ — DO NOT add machinery stubs here.
//
// This file is the LINDA-vs-CHOMP shim layer only.

// === /tg/ subsystem flags ===
/datum/controller/subsystem
	var/ss_flags = 0


// === /tg/ atmos handbooks (called by SSair.Initialize) ===
/proc/atmos_handbooks_init()
	return


// === /tg/ SSblackbox telemetry — wired to CHOMP's feedback_add_details ===
/datum/controller/subsystem/blackbox
	var/sealed = FALSE

/datum/controller/subsystem/blackbox/proc/record_feedback(key_type, key_name, increment_by = 1, data = null)
	if(!GLOB.blackbox)
		return
	var/value = !isnull(data) ? "[data]" : "[increment_by]"
	feedback_add_details(key_name, "[key_type]:[value]")

var/global/datum/controller/subsystem/blackbox/SSblackbox = new()


// === /tg/ globals SSair expects ===
GLOBAL_LIST_EMPTY(active_turfs_startlist)
GLOBAL_LIST_INIT(contrast_colors, list("#ff0000", "#00ff00", "#0000ff", "#ffff00", "#00ffff", "#ff00ff"))


// === /tg/-specific vars on /obj/machinery and /obj/item ===
/obj/machinery
	var/atmos_processing = FALSE
	var/rebuilding = FALSE

/obj/item
	var/datum/gas_mixture/air_temporary


// === /tg/ hud + debug viz ===
/datum/hud
	var/atmos_debug_overlays

/obj/effect/abstract/atmos_aware

/obj/effect/overlay/atmos_excited
	icon = null
	mouse_opacity = 0


// === /datum/atmosphere (planet atmosphere descriptor) ===
/datum/atmosphere
	var/id
	var/base_gases
	var/gas_string = ""
	var/temperature = T20C

/datum/atmosphere/proc/return_gas_string()
	return ""


// === SSmapping multi-z helpers (CHOMP doesn't expose these as GLOB lists) ===
/datum/controller/subsystem/mapping
	var/list/z_list = list()
	var/max_plane_offset = 0
	var/list/multiz_levels = list()


// === Per-z-level metadata ===
/datum/space_level
	var/list/traits = list()


// === /tg/ atom flag bitfield ===
/atom/var/flags_1 = 0


// === /tg/'s per-turf atmos init (LINDA's SSair drives these) ===
/turf/var/requires_activation = FALSE
/turf/var/init_air = TRUE
/turf/proc/Initalize_Atmos(times_fired)
	return


// === /tg/ looping_sound extra vars (LINDA fire ambience uses these) ===
/datum/looping_sound
	var/falloff_distance = 0
	var/atom/parent


// === Heat→color helpers for fire visual gradient ===
/proc/heat2colour_r(temp)
	if(temp < 1000)
		return 64
	if(temp < 2500)
		return min(255, 64 + (temp - 1000) * 191 / 1500)
	return 255

/proc/heat2colour_g(temp)
	if(temp < 1500)
		return 32
	return min(200, 32 + (temp - 1500) * 168 / 2000)

/proc/heat2colour_b(temp)
	if(temp < 3000)
		return 0
	return min(150, (temp - 3000) * 150 / 1500)


// === /tg/ smoothing junction stubs ===
/atom/proc/setDir(new_dir)
	dir = new_dir

/atom
	var/smoothing_junction = 0

/atom/proc/set_smoothed_icon_state(new_junction)
	smoothing_junction = new_junction


// === SSair UI stubs ===
/datum/controller/subsystem/air/proc/ui_state(mob/user)
	return null

/datum/controller/subsystem/air/proc/ui_interact(mob/user, datum/tgui/ui)
	return

/datum/controller/subsystem/air/proc/ui_data(mob/user)
	return list()

/datum/controller/subsystem/air/proc/ui_act(action, list/params)
	return


// === /tg/ machinery atmos lifecycle hooks (LINDA SSair iterates these) ===
// CHOMP /obj/machinery has its own machine init; LINDA expects these on every
// machine. atmos_init is the post-init "wire up to pipenet" hook — CHOMP
// machinery uses build_network() instead. Stub both as no-ops at the base.
/obj/machinery/proc/get_rebuild_targets()
	return list()

// `atmos_init` already exists in CHOMP via _atmospherics_helpers.dm.


// === /atom/proc/CanZASPass — used by airlocks, doors, windows ===
// CHOMP machinery overrides this for their pass-through logic.
/atom/proc/CanZASPass(turf/T, is_zone)
	return TRUE


// === /turf/proc/apply_fire_protection — /tg/ flame-retardant flag ===
/turf/proc/apply_fire_protection()
	return


// === /tg/ gas analyzer formatters (used by analyze_gases) ===
/proc/get_gas_mixture_default_scan_data(datum/gas_mixture/air)
	return null


// === /datum/gas_mixture/proc/get_thermal_energy_change ===
/datum/gas_mixture/proc/get_thermal_energy_change(new_temperature)
	return heat_capacity() * (new_temperature - temperature)


// === GLOB.electrolyzer_reactions + /datum/electrolyzer_reaction ===
GLOBAL_LIST_EMPTY(electrolyzer_reactions)

/datum/electrolyzer_reaction

/datum/electrolyzer_reaction/proc/reaction_check(datum/gas_mixture/air_mixture, electrolyzer_args)
	return FALSE

/datum/electrolyzer_reaction/proc/react(datum/gas_mixture/air_mixture, working_power, electrolyzer_args)
	return


// atmosanalyzer_scan + analyze_gases live in code/_helpers/atmospherics.dm.
/proc/analyze_gases(obj/source, mob/user)
	if(!source || !user)
		return
	var/datum/gas_mixture/air = isturf(source) ? source.return_air() : (source.loc?.return_air())
	if(!air)
		to_chat(user, span_warning("No atmospheric readings available."))
		return
	for(var/line in atmosanalyzer_scan(source, air, user))
		to_chat(user, line)


// === /atom/movable move_resist + force defines ===
/atom/movable
	var/move_resist = 100

#define MOVE_FORCE_DEFAULT 50
#define MOVE_FORCE_PUSH_RATIO 1
#define MOVE_FORCE_FORCEPUSH_RATIO 1


// === Multi-z helpers ===
#define GET_Z_PLANE_OFFSET(z) 0
#define cardinals cardinal

GLOBAL_LIST_INIT(cardinals_multiz, list(NORTH, SOUTH, EAST, WEST, UP, DOWN))
GLOBAL_LIST_INIT(diagonals_multiz, list(NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST, UP|NORTH, UP|SOUTH, UP|EAST, UP|WEST, DOWN|NORTH, DOWN|SOUTH, DOWN|EAST, DOWN|WEST))

/proc/get_step_multiz(atom/source, direction)
	if(direction == UP)
		return GetAbove(source)
	if(direction == DOWN)
		return GetBelow(source)
	return get_step(source, direction)

/proc/get_dir_multiz(atom/source, atom/target)
	if(!source || !target)
		return 0
	if(source.z != target.z)
		return source.z < target.z ? UP : DOWN
	return get_dir(source, target)


// === /turf zAir / atmos_expose hooks LINDA expects ===
/turf/proc/zAirIn(direction, turf/source)
	return TRUE

/turf/proc/zAirOut(direction, turf/source)
	return TRUE

/turf/proc/atmos_expose(datum/gas_mixture/air, temperature)
	return

/turf/proc/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return FALSE

/turf/proc/check_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return FALSE

/turf/proc/return_analyzable_air()
	return return_air()

/turf/proc/Melt()
	return


// === LINDA reaction-output stubs (CHOMP doesn't have these /tg/ types) ===
/datum/component/wet_floor
	var/highest_strength = 0

#define TURF_WET_PERMAFROST 1

/turf/proc/water_vapor_gas_act()
	if(istype(src, /turf/space) || istype(src, /turf/simulated/open))
		return FALSE
	if(istype(src, /turf/simulated))
		var/turf/simulated/S = src
		if(hascall(S, "wet_floor"))
			S.wet_floor()
	return TRUE

/turf/proc/freeze_turf()
	return

/turf/proc/fire_nuclear_particle()
	if(SSradiation)
		SSradiation.irradiate(src, 50)
	return

/proc/isgroundlessturf(turf/T)
	return istype(T, /turf/space) || istype(T, /turf/simulated/open)

/proc/isnoslipturf(turf/T)
	if(!T)
		return FALSE
	return TRUE

/proc/visible_hallucination_pulse(atom/center, range, hallucination_amount, duration)
	if(!center || !range)
		return
	for(var/mob/living/carbon/human/H in range(range, center))
		if(H.species && (H.species.flags & (NO_POISON | IS_PLANT | NO_HALLUCINATION)))
			continue
		H.hallucination = max(H.hallucination, (hallucination_amount || 10))
	return

/proc/do_foam(amount, location, type)
	if(!location || !amount)
		return
	for(var/i in 1 to min(amount, 10))
		new /obj/effect/effect/foam(get_turf(location))
	return

/obj/item/stack/sheet/hot_ice
	name = "hot ice (stub)"

/datum/effect_system/fluid_spread/foam/metal/resin/halon

/datum/effect_system/fluid_spread/foam

// /atom hook for per-tick atmos processing (LINDA iteration).
/atom/proc/process_atmos(seconds_per_tick)
	return

/atom/proc/process_exposure(datum/gas_mixture/air, exposed_temperature)
	return
