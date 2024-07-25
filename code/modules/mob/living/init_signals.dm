/mob/living/proc/register_init_signals()
	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_WEAKENED), PROC_REF(on_weakened_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_WEAKENED), PROC_REF(on_weakened_trait_loss))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_STUNNED), PROC_REF(on_stunned_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_STUNNED), PROC_REF(on_stunned_trait_loss))

	RegisterSignal(src, SIGNAL_ADDTRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_gain))
	RegisterSignal(src, SIGNAL_REMOVETRAIT(TRAIT_KNOCKEDOUT), PROC_REF(on_knockedout_trait_loss))

/mob/living/proc/on_weakened_trait_gain(datum/source)
	SIGNAL_HANDLER
	if(stat <= WEAKENED)
		set_stat(WEAKENED)

/mob/living/proc/on_weakened_trait_loss(datum/source)
	SIGNAL_HANDLER
	if(stat <= WEAKENED)
		update_stat()

/mob/living/proc/on_stunned_trait_gain(datum/source)
	SIGNAL_HANDLER
	if(stat <= STUNNED)
		set_stat(STUNNED)

/mob/living/proc/on_stunned_trait_loss(datum/source)
	SIGNAL_HANDLER
	if(stat <= STUNNED)
		update_stat()

/mob/living/proc/on_knockedout_trait_gain(datum/source)
	SIGNAL_HANDLER
	if(stat <= UNCONSCIOUS)
		set_stat(UNCONSCIOUS)

/mob/living/proc/on_knockedout_trait_loss(datum/source)
	SIGNAL_HANDLER
	if(stat <= UNCONSCIOUS)
		update_stat()
