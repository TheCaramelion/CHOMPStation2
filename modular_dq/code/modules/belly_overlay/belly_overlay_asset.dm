// Pre-built belly overlay assets.
//
// Each (DMI, icon_state) pair was rendered offline by
// tools/build_belly_apngs/build.py into either:
//   - a single-frame PNG (still icons), or
//   - an animated WebP (multi-frame icons; libwebp_anim).
//
// Naming convention: <safe-dmi-name>__<safe-state-name>.<png|webp>
// where safe-name is the source path with all non-alnum/[-._] chars
// replaced by "_", and ".dmi" stripped.
//
// At runtime we just look up the registered asset by name and ship the
// URL — no iconforge, no per-frame extraction, no JS animation timer.

GLOBAL_LIST_EMPTY(dq_belly_overlay_url_by_key)

/datum/asset/simple/belly_overlays
	keep_local_name = TRUE
	assets = list()

/datum/asset/simple/belly_overlays/New()
	// Discover every pre-built belly overlay file at boot.
	for(var/fname in flist("modular_dq/icons/belly_overlays/"))
		// flist returns "dir/" entries for subdirs; skip them.
		if(copytext(fname, length(fname)) == "/")
			continue
		assets[fname] = file("modular_dq/icons/belly_overlays/[fname]")
	..()

/// Builds the asset filename for a (dmi_path, state_name) lookup. Mirrors
/// the naming convention in tools/build_belly_apngs/build.py.
/proc/dq_belly_overlay_safe_filename(dmi_path, state_name, ext)
	var/safe_dmi = replacetext(replacetext(dmi_path, ".dmi", ""), "/", "_")
	safe_dmi = replacetext(replacetext(safe_dmi, " ", "_"), ".", "_")
	var/safe_state = replacetext(replacetext(state_name, "/", "_"), " ", "_")
	safe_state = replacetext(safe_state, ".", "_")
	return "[safe_dmi]__[safe_state].[ext]"

/// Returns the asset URL for a (dmi, state) pair, or null if no file exists.
/// Tries .webp first (animated) then .png (still). Result is cached.
/proc/dq_get_belly_overlay_url(icon/dmi, state)
	if(!dmi || !state)
		return null
	var/dmi_path = "[dmi]"
	var/cache_key = "[dmi_path]::[state]"
	if(cache_key in GLOB.dq_belly_overlay_url_by_key)
		return GLOB.dq_belly_overlay_url_by_key[cache_key]
	var/datum/asset/simple/belly_overlays/asset = get_asset_datum(/datum/asset/simple/belly_overlays)
	var/list/mappings = asset.get_url_mappings()
	var/url = null
	for(var/ext in list("webp", "png"))
		var/fname = dq_belly_overlay_safe_filename(dmi_path, state, ext)
		if(fname in mappings)
			url = mappings[fname]
			break
	GLOB.dq_belly_overlay_url_by_key[cache_key] = url
	return url

/// Send the belly overlay asset bundle to a client (idempotent — the
/// transport short-circuits when the client already has these files).
/proc/dq_send_belly_overlay_assets(client/C)
	if(!istype(C))
		return FALSE
	var/datum/asset/simple/belly_overlays/asset = get_asset_datum(/datum/asset/simple/belly_overlays)
	return asset.send(C)
