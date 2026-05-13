/mob/Login()
	. = ..()

	// DQEdit — viewing_alternate_appearances moved to /datum/component/alt_appearances_viewer
	var/list/viewing = dq_get_viewing_alt_appearances(src)
	if(viewing && viewing.len)
		for(var/datum/alternate_appearance/AA in viewing)
			AA.display_to(list(src))

	var/atom/movable/screen/plane_master/augmented/aug = plane_holder.plane_masters[VIS_AUGMENTED]
	aug.apply()
