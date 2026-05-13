// Per-state PNG extractor for belly overlays.
// Calls rustg_iconforge_generate_headless to render a single icon_state from
// a DMI file as a flat PNG, registers it with the asset transport, and
// returns the URL. Results are cached by (dmi, state) so each combination is
// only generated once per round.

GLOBAL_LIST_EMPTY(dq_belly_state_urls)
GLOBAL_LIST_EMPTY(dq_belly_state_frames)
GLOBAL_LIST_EMPTY(dq_belly_state_delays)
GLOBAL_LIST_EMPTY(dq_belly_dmi_meta_cache)
#define DQ_BELLY_MAX_FRAMES 16

/// Returns the cached parsed DMI metadata for a path. Lazy.
/proc/dq_get_dmi_meta(dmi_path)
	if(!dmi_path)
		return null
	var/cached = GLOB.dq_belly_dmi_meta_cache[dmi_path]
	if(cached)
		return cached
	var/list/meta = rustg_dmi_read_metadata(dmi_path)
	if(!istype(meta))
		return null
	GLOB.dq_belly_dmi_meta_cache[dmi_path] = meta
	return meta

/// Returns the parsed state metadata list for a given (dmi_path, state),
/// or null if the state isn't in this DMI. Caller can read "delays" and
/// "rewind" off the result.
/proc/dq_get_state_meta(dmi_path, state)
	var/list/meta = dq_get_dmi_meta(dmi_path)
	if(!meta)
		return null
	for(var/list/sd in meta["states"])
		if(sd["name"] == state)
			return sd
	return null

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
				"dir" = SOUTH,
				"frame" = 1,
				"transform" = list(),
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

/// Returns a list of frames for an animated icon_state, where each entry
/// is list("url" = "...", "delay_ms" = number). Falls back to a single
/// frame with a default delay when the state has no animation metadata.
/// Cached per (dmi, state).
///
/// When the state's DMI metadata has rewind = TRUE, the returned sequence
/// is a ping-pong of the underlying frames: forward then backward minus
/// the endpoints (e.g. frames 1,2,3 with rewind become 1,2,3,2). That way
/// the client can just loop the list naively and get correct playback.
/proc/dq_get_belly_state_frames(icon/dmi, state)
	if(!dmi || !state)
		return list()
	var/dmi_path = "[dmi]"
	var/cache_key = "[dmi_path]::[state]"
	if(GLOB.dq_belly_state_frames[cache_key])
		return GLOB.dq_belly_state_frames[cache_key]
	var/list/state_meta = dq_get_state_meta(dmi_path, state)
	// rust_g's dmi_read_metadata uses the field name "delay" (singular),
	// not "delays" as the rust_g.dm comment claims.
	var/list/delays = state_meta?["delay"]
	var/rewind = state_meta?["rewind"] ? TRUE : FALSE
	// Frame count: trust the DMI metadata if we have it; otherwise probe
	// up to DQ_BELLY_MAX_FRAMES and dedupe via md5.
	var/frame_count = delays ? length(delays) : DQ_BELLY_MAX_FRAMES
	// Raw (forward-only) frames. We'll synthesize the ping-pong at the end.
	var/list/raw = list()
	var/safe_dmi = replacetext(replacetext(dmi_path, "/", "_"), ".", "_")
	var/safe_state = replacetext(replacetext(state, "/", "_"), " ", "_")
	var/cache_dir = "data/dq_belly"
	if(!fexists("[cache_dir]/.keep"))
		rustg_file_write("", "[cache_dir]/.keep")
	var/last_hash = null
	for(var/frame_num in 1 to frame_count)
		var/png_path = "data/dq_belly/[safe_dmi]_[safe_state]_f[frame_num].png"
		var/asset_name = "dq_belly_[safe_dmi]_[safe_state]_f[frame_num].png"
		if(!fexists(png_path))
			var/list/sprites = list(
				"out" = list(
					"icon_file" = dmi_path,
					"icon_state" = state,
					"dir" = SOUTH,
					"frame" = frame_num,
					"transform" = list(),
				)
			)
			var/list/result = rustg_iconforge_generate_headless(png_path, json_encode(sprites), "1")
			if(!result || result["error"])
				break
		if(!fexists(png_path))
			break
		// When we're probing without metadata, stop on a duplicate frame.
		if(!delays)
			var/hash = rustg_hash_file(RUSTG_HASH_MD5, png_path)
			if(hash == last_hash)
				break
			last_hash = hash
		var/datum/asset_cache_item/ACI = SSassets.transport.register_asset(asset_name, fcopy_rsc(png_path))
		if(!istype(ACI))
			break
		var/url = SSassets.transport.get_asset_url(asset_name, ACI)
		// DMI delays are deciseconds; convert to ms. Default to 100ms if
		// metadata is missing or this index is out of bounds.
		var/delay_ds = (delays && frame_num <= length(delays)) ? delays[frame_num] : 1
		raw += list(list("url" = url, "delay_ms" = round(delay_ds * 100)))
		// Yield to the master controller every few frames so a long
		// animation (e.g. intestine2's 320-frame loop) doesn't block the
		// tick. We CHECK_TICK every frame because each iconforge call can
		// be ~10ms.
		CHECK_TICK
	// Synthesize ping-pong for rewind states. We append raw[N-1] down to
	// raw[2] (1-indexed), skipping the endpoints so the loop doesn't stall.
	var/list/frames = raw.Copy()
	if(rewind && length(raw) > 2)
		for(var/i = length(raw) - 1 to 2 step -1)
			frames += list(raw[i])
	GLOB.dq_belly_state_frames[cache_key] = frames
	return frames

/// Sends every registered belly-state asset to a given client. Cheap if the
/// client already has them cached. Returns TRUE if any asset was sent.
/proc/dq_send_belly_state_assets(client/C)
	if(!istype(C))
		return FALSE
	var/list/names = list()
	for(var/key in GLOB.dq_belly_state_urls)
		var/list/parts = splittext(key, "::")
		if(length(parts) != 2)
			continue
		var/safe_dmi = replacetext(replacetext(parts[1], "/", "_"), ".", "_")
		var/safe_state = replacetext(replacetext(parts[2], "/", "_"), " ", "_")
		names += "dq_belly_[safe_dmi]_[safe_state].png"
	for(var/key in GLOB.dq_belly_state_frames)
		var/list/parts = splittext(key, "::")
		if(length(parts) != 2)
			continue
		var/safe_dmi = replacetext(replacetext(parts[1], "/", "_"), ".", "_")
		var/safe_state = replacetext(replacetext(parts[2], "/", "_"), " ", "_")
		var/list/frames = GLOB.dq_belly_state_frames[key]
		for(var/i in 1 to length(frames))
			names += "dq_belly_[safe_dmi]_[safe_state]_f[i].png"
	if(!length(names))
		return FALSE
	return SSassets.transport.send_assets(C, names)
