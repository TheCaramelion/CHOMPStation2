/mob/living/silicon/robot/Login()
	..()
	regenerate_icons()
	update_hud()

	show_laws(0)

	// Override the DreamSeeker macro with the borg version!
	client.set_hotkeys_macro("borgmacro", "borghotkeymode")
	// DQEdit — force hotkey mode; non-hotkey disabled in this fork.
	winset(client, null, "mainwindow.macro=borghotkeymode;hotkey_toggle.is-checked=true;mapwindow.map.focus=true")

	repick_laws()

	// Forces synths to select an icon relevant to their module
	pick_module()

	plane_holder.set_vis(VIS_AUGMENTED, TRUE)
