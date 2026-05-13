// Kick off layer-1 pregeneration the moment the first client connects.
// Moving it here (vs SSquarry.Initialize) saves ~15-20 seconds of world
// init time. The pregen runs in the background while the player is still
// in the lobby and walking around; by the time they click the down-shaft,
// layer 1 is ready.
//
// ensure_pregen_started() is idempotent, so we can call it from every
// Login without worrying about duplicate work. Same goes for late joiners.

/mob/new_player/Login()
	. = ..()
	if(SSquarry)
		SSquarry.ensure_pregen_started()
