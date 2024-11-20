/datum/element/waddling
	var/waddle_z
	var/waddle_min
	var/waddle_max
	var/waddle_time

/datum/element/waddling/Attach(datum/target, waddle_z = 0.5, waddle_min = -8, waddle_max = 8, waddle_time = 2)
	. = ..()
	if(!ismovable(target))
		return ELEMENT_INCOMPATIBLE

	src.waddle_z = waddle_z
	src.waddle_min = waddle_min
	src.waddle_max = waddle_max
	src.waddle_time = waddle_time

	RegisterSignal(target, COMSIG_MOVABLE_MOVED, PROC_REF(Waddle))

/datum/element/waddling/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, COMSIG_MOVABLE_MOVED)

/datum/element/waddling/proc/Waddle(atom/movable/moved)
	SIGNAL_HANDLER

	if(isliving(moved))
		var/mob/living/M = moved

		if(M.buckled || M.throwing || M.lying || M.is_incorporeal())
			return

	waddling_animation(moved)

/datum/element/waddling/proc/waddling_animation(atom/movable/target)
	var/waddle_min_total = waddle_min
	var/waddle_max_total = waddle_max
	var/waddle_time_total = waddle_max
	var/waddle_z_total = waddle_z

	if(isliving(target))
		var/mob/living/waddler = target

		if(waddler.confused)
			waddle_min_total -= 4
			waddle_max_total += 4
		if(waddler.druggy)
			waddle_min_total -= 8
			waddle_max_total += 8
			waddle_time_total += 1
		if(waddler.drowsyness)
			waddle_min_total += 4
			waddle_max_total += 16
			waddle_time_total += 3
		if(waddler.hallucination)
			waddle_min_total -= 10
			waddle_max_total += 10
			waddle_time_total -= 1
		for(var/datum/reagent/R in target.reagents.reagent_list)
			if(R.id in tachycardics)
				waddle_z_total += 3

	var/prev_pixel_z = target.pixel_z
	animate(target, pixel_z = target.pixel_z + waddle_z_total, time = 0)
	var/prev_transform = target.transform
	animate(pixel_z = prev_pixel_z, transform = turn(target.transform, pick(waddle_min_total, 0, waddle_max_total)), time = waddle_time_total)
	animate(transform = prev_transform, time = 0)
