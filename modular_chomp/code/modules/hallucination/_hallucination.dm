/**
 * # Hallucination datum
 *
 * Handles effects of a hallucination on a living mob
 * Created and triggered bia the [cause hallucination proc][/mob/living/proc/cause_hallucination]
 */
/datum/hallucination
	// What is this hallucination's weight in the random hallucination pool
	var/random_hallucination_weight
	// Who's your next highest abstract parent type
	var/abstract_hallucination_parent = /datum/hallucination
	// Extra info about the hallucination displayed in the log
	var/feedback_details = ""
	// The mob we're targetting
	var/mob/living/hallucinator

/datum/hallucination/New(mob/living/hallucinator)
	if(!isliving(hallucinator))
		stack_trace("[type] was created without a hallucination mob.")
		qdel(src)
		return

	src.hallucinator = hallucinator
	RegisterSignal(hallucinator, COMSIG_PARENT_QDELETING, PROC_REF(target_deleting))
	GLOB.all_ongoing_hallucinations += src

/// Signal proc for [COMSIG_QDELETING], if the mob hallucinating us is deletes, we should delete too.
/datum/hallucination/proc/target_deleting()
	SIGNAL_HANDLER

	qdel(src)

/datum/hallucination/proc/start()
	SHOULD_CALL_PARENT(FALSE)
	stack_trace("[type] didn't implement any hallucinations effects in start.")

/datum/hallucination/Destroy()
	if(hallucinator)
		UnregisterSignal(hallucinator, COMSIG_PARENT_QDELETING)
		hallucinator = null

	GLOB.all_ongoing_hallucinations -= src
	return ..()

/datum/hallucination/proc/random_far_turf()
	var/first_offset = pick(-8, -7, -6, -5, 5, 6, 7, 8)
	var/second_offset = rand(-8, 8)
	var/x_offset
	var/y_offset
	if(prob(50))
		x_offset = first_offset
		y_offset = second_offset
	else
		x_offset = second_offset
		y_offset = first_offset

	return locate(hallucinator.x + x_offset, hallucinator.y + y_offset, hallucinator.z)

/datum/hallucination/proc/random_player()
	var/list/possible_fakes = list()
	for(var/datum/mind/possible_fake as anything in get_player_minds())
