// Per-state PNG extractor for belly overlays.
// Calls rustg_iconforge_generate_headless to render a single icon_state from
// a DMI file as a flat PNG, registers it with the asset transport, and
// returns the URL. Results are cached by (dmi, state) so each combination is
// only generated once per round.

GLOBAL_LIST_EMPTY(dq_belly_state_urls)

/// Returns a URL for the given (dmi, state) combination, generating the PNG
/// on first call. Returns null on failure (rustg error, missing state, etc).
/proc/dq_get_belly_state_url(icon/dmi, state)
	if(!dmi || !state)
		return null
	var/dmi_path = "[dmi]"
	var/cache_key = "[dmi_path]::[state]"
	if(GLOB.dq_belly_state_urls[cache_key])
		return GLOB.dq_belly_state_urls[cache_key]
	// rustg only accepts safe alnum/underscore output paths.
	var/safe_dmi = replacetext(replacetext(dmi_path, "/", "_"), ".", "_")
	var/safe_state = replacetext(replacetext(state, "/", "_"), " ", "_")
	var/png_path = "data/dq_belly/[safe_dmi]_[safe_state].png"
	var/asset_name = "dq_belly_[safe_dmi]_[safe_state].png"
	if(!fexists(png_path))
		// Ensure output dir exists.
		var/dir = "data/dq_belly"
		if(!fexists("[dir]/.keep"))
			rustg_file_write("", "[dir]/.keep")
		var/list/sprites = list(
			"out" = list(
				"icon_file" = dmi_path,
				"icon_state" = state,
			)
		)
		var/list/result = rustg_iconforge_generate_headless(png_path, json_encode(sprites), "1")
		if(!result || result["error"])
			log_asset("dq_get_belly_state_url: iconforge failed for [dmi_path]/[state]: [result?["error"]]")
			return null
	if(!fexists(png_path))
		log_asset("dq_get_belly_state_url: iconforge did not produce [png_path]")
		return null
	// Register the file in the rsc + asset transport, get a URL.
	var/datum/asset_cache_item/ACI = SSassets.transport.register_asset(asset_name, fcopy_rsc(png_path))
	if(!istype(ACI))
		log_asset("dq_get_belly_state_url: register_asset failed for [asset_name]")
		return null
	var/url = SSassets.transport.get_asset_url(asset_name, ACI)
	GLOB.dq_belly_state_urls[cache_key] = url
	return url

/// Sends every registered belly-state asset to a given client. Cheap if the
/// client already has them cached. Returns TRUE if any asset was sent.
/proc/dq_send_belly_state_assets(client/C)
	if(!istype(C))
		return FALSE
	var/list/names = list()
	for(var/key in GLOB.dq_belly_state_urls)
		// Recover the asset_name from the cache_key we built earlier.
		var/list/parts = splittext(key, "::")
		if(length(parts) != 2)
			continue
		var/safe_dmi = replacetext(replacetext(parts[1], "/", "_"), ".", "_")
		var/safe_state = replacetext(replacetext(parts[2], "/", "_"), " ", "_")
		names += "dq_belly_[safe_dmi]_[safe_state].png"
	if(!length(names))
		return FALSE
	return SSassets.transport.send_assets(C, names)
