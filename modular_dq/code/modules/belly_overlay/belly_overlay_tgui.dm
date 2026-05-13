// TGUI belly overlay — Stage 1.
// One datum per (prey mob). Owns the `mapwindow.belly_overlay` BROWSER
// child element on that client and the TGUI window inside it.
//
// Stage 1 contract: a single full-viewport <img> of one belly DMI. No
// per-icon-state extraction yet, no compositing, no dynamic layers.
// Just demonstrates the asset round-trip and skin-anchored placement
// when called from vore_fx() in parallel with the existing renderer.

/datum/belly_overlay_tgui
	var/mob/owner
	var/datum/tgui/active_ui
	var/list/state = list()

/datum/belly_overlay_tgui/New(mob/M)
	owner = M

/datum/belly_overlay_tgui/Destroy(force)
	if(owner?.client)
		winset(owner.client, "mapwindow.belly_overlay", "is-visible=false")
	owner = null
	active_ui = null
	return ..()

/datum/belly_overlay_tgui/tgui_state(mob/user)
	return GLOB.tgui_always_state

/datum/belly_overlay_tgui/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/simple/belly_overlay_test))

/datum/belly_overlay_tgui/tgui_data(mob/user)
	return state

/datum/belly_overlay_tgui/tgui_close(mob/user)
	hide()

/datum/belly_overlay_tgui/proc/open_window()
	if(!owner?.client)
		return
	var/client/C = owner.client
	winset(C, "mapwindow.belly_overlay", "is-visible=true")
	if(!active_ui)
		var/datum/tgui_window/win = new(C, "mapwindow.belly_overlay")
		active_ui = new /datum/tgui(owner, src, "BellyOverlay", "Belly Overlay", null, null, null, win)
		active_ui.open()

/datum/belly_overlay_tgui/proc/show(obj/belly/B, mob/prey)
	if(!owner?.client)
		return
	var/list/layers = list()
	if(B && B.belly_fullscreen)
		var/datum/belly_overlays/lookup_path = text2path("/datum/belly_overlays/[lowertext(B.belly_fullscreen)]")
		var/icon/dmi = lookup_path ? initial(lookup_path.belly_icon) : null
		if(dmi)
			var/alpha = B.belly_fullscreen_alpha
			if(prey)
				alpha = min(alpha, prey.max_voreoverlay_alpha)
			var/list/states = list(
				list(B.belly_fullscreen,            B.belly_fullscreen_color),
				list("[B.belly_fullscreen]-2",      B.belly_fullscreen_color2),
				list("[B.belly_fullscreen]-3",      B.belly_fullscreen_color3),
				list("[B.belly_fullscreen]-4",      B.belly_fullscreen_color4),
			)
			for(var/list/pair in states)
				var/icon_state = pair[1]
				var/color = pair[2]
				var/url = dq_get_belly_state_url(dmi, icon_state)
				if(url)
					layers += list(list(
						"url"    = url,
						"color"  = color || "#ffffff",
						"alpha"  = alpha,
						"pixelY" = 0,
					))
			// Dynamic mush/liquid layers from bubbles.dmi. See belly_obj_vfx.dm
			// for the original computation; we mirror it here so the TGUI side
			// stays purely declarative. liquidbelly_visuals is on /mob/living.
			var/mob/living/lp = prey
			if(istype(lp) && B.show_liquids && lp.liquidbelly_visuals)
				var/icon/bubbles = 'icons/mob/vore_fullscreens/bubbles.dmi'
				// Main mush layer when there's content and a mush overlay is enabled.
				if(B.mush_overlay && (B.owner?.nutrition > 0 || B.max_mush == 0 || B.min_mush > 0 \
						|| (LAZYLEN(B.contents) * B.item_mush_val) > 0))
					var/mush_content = B.owner ? (B.owner.nutrition + LAZYLEN(B.contents) * B.item_mush_val) : 0
					var/mush_alpha = min(B.mush_alpha, prey.max_voreoverlay_alpha)
					var/pixel_y = -450 + (450 / max(B.max_mush, 1) * max(min(B.max_mush, mush_content), 1))
					if(pixel_y < -450 + (450 / 100 * B.min_mush))
						pixel_y = -450 + (450 / 100 * B.min_mush)
					var/mush_url = dq_get_belly_state_url(bubbles, "mush")
					if(mush_url)
						layers += list(list(
							"url"    = mush_url,
							"color"  = B.mush_color || "#ffffff",
							"alpha"  = mush_alpha,
							"pixelY" = pixel_y,
						))
				// Liquid bubbles layer when there's reagent volume.
				if(B.liquid_overlay && B.reagents?.total_volume)
					var/liquid_state = (B.digest_mode == DM_HOLD && B.item_digest_mode == IM_HOLD) ? "calm" : "bubbles"
					var/liquid_alpha = max(150, min(B.custom_max_volume, 255)) - (255 - alpha)
					if(B.custom_reagentalpha)
						liquid_alpha = B.custom_reagentalpha
					var/liquid_color = B.custom_reagentcolor || B.reagentcolor
					var/pixel_y = -450 + min((450 / max(B.custom_max_volume, 1) * B.reagents.total_volume), 450 / 100 * B.max_liquid_level)
					var/liquid_url = dq_get_belly_state_url(bubbles, liquid_state)
					if(liquid_url)
						layers += list(list(
							"url"    = liquid_url,
							"color"  = liquid_color || "#ffffff",
							"alpha"  = liquid_alpha,
							"pixelY" = pixel_y,
						))
			dq_send_belly_state_assets(owner.client)
	state = list(
		"visible" = length(layers) > 0,
		"layers"  = layers,
	)
	open_window()
	if(active_ui)
		active_ui.send_update()

/datum/belly_overlay_tgui/proc/hide()
	state = list("visible" = FALSE)
	if(owner?.client)
		winset(owner.client, "mapwindow.belly_overlay", "is-visible=false")
	if(active_ui)
		active_ui.close()
		active_ui = null

// Helper: get or lazily create the overlay datum for a mob.
/proc/get_belly_overlay_tgui(mob/M)
	if(!M)
		return null
	if(!M.belly_overlay_tgui)
		M.belly_overlay_tgui = new /datum/belly_overlay_tgui(M)
	return M.belly_overlay_tgui

// Per-mob storage for the overlay datum.
/mob
	var/datum/belly_overlay_tgui/belly_overlay_tgui

/mob/Destroy()
	if(belly_overlay_tgui)
		qdel(belly_overlay_tgui)
		belly_overlay_tgui = null
	return ..()

// Debug verb so the human can open the overlay on themselves.
// Builds a 4-layer composited test using VBO_belly9 icon_states with
// distinct tint colors so we can visually verify compositing fidelity.
/client/verb/dq_test_belly_overlay()
	set name = "DQ Test Belly Overlay"
	set category = "OOC"
	set desc = "Open the proof-of-concept TGUI belly overlay."
	if(!mob)
		return
	var/datum/belly_overlay_tgui/poc = get_belly_overlay_tgui(mob)
	var/icon/test_dmi = 'icons/mob/vore_fullscreens/VBO_belly9.dmi'
	var/list/layers = list()
	var/list/states = list(
		list("belly",   "#883333"),
		list("belly-2", "#338833"),
		list("belly-3", "#333388"),
		list("belly-4", "#888833"),
	)
	for(var/list/pair in states)
		var/url = dq_get_belly_state_url(test_dmi, pair[1])
		if(url)
			layers += list(list(
				"url"   = url,
				"color" = pair[2],
				"alpha" = 200,
			))
	dq_send_belly_state_assets(src)
	poc.state = list("visible" = length(layers) > 0, "layers" = layers)
	poc.open_window()
	if(poc.active_ui)
		poc.active_ui.send_update()
