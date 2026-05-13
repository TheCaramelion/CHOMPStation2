// Asset that ships a single belly DMI to the client as a raw resource.
// Shipped on demand, not at boot, so DreamDaemon does not decode the PNG
// into PixBitsShared. The TGUI side just renders it as an <img>.
/datum/asset/simple/belly_overlay_test
	assets = list(
		"belly_overlay_test.dmi" = 'icons/mob/vore_fullscreens/VBO_belly9.dmi',
	)
