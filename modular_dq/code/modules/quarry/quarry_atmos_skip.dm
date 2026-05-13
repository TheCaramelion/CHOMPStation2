// Path 2 atmos opt-out for quarry cave-layer turfs.
//
// Quarry layers are the bulk of the world by turf count, but the vast
// majority of those tiles are wall rock that no player ever stands on
// and that share a uniform atmosphere. Building a /datum/zone graph
// across all of them is pure waste: ~500 bytes per zone datum, plus a
// contents list entry per member turf, plus /connection_edge datums
// for every zone-to-zone air boundary, plus a tick-time cost for the
// equalization pass.
//
// Overriding update_air_properties() to early-return short-circuits
// the zone-graph build. return_air() still works — it falls through
// to the lazy per-turf /datum/gas_mixture path on the base /turf,
// which reads the initial gas vars and synthesises a mix on demand.
// So gas is still readable for any code that needs it (pressure
// checks, breathing); we just don't pay the zone-graph tax for tiles
// that no zone-altering event will ever touch.
//
// When a player mines a wall (make_floor on /turf/simulated/mineral),
// we restore the upstream behavior on the carved tile and call into
// the regular ZAS path, which builds a tiny zone for the carved
// neighborhood — merging into adjacent zones via SSair.connect if any
// already exist.

/turf/simulated/mineral/cave/quarry
	var/skip_zone_init = TRUE

/turf/simulated/mineral/cave/quarry/update_air_properties()
	if(skip_zone_init)
		return
	return ..()

/turf/simulated/mineral/cave/quarry/make_floor()
	if(skip_zone_init)
		skip_zone_init = FALSE
	return ..()
