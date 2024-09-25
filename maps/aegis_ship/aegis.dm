#if !defined(USING_MAP_DATUM)

	#include "aegis_defines.dm"
	#include "aegis_areas.dm"

	#if !AWAY_MISSION_TEST
		#include "aegis-1.dmm"

	#endif

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Aegis

#endif
