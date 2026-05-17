// New-player guide ("wiki") for Deep Quarry, surfaced from the lobby's
// "Guide" button. The guide is a browse() popup with an index page that
// links to per-topic pages. All content lives in this file as one
// associative list — easy to edit.
//
// Navigation works via the standard BYOND browser Topic() roundtrip:
// links use href="?src=\ref[user];guide_topic=KEY" and Topic() on
// /mob/new_player routes guide_topic back here.

GLOBAL_LIST_INIT(quarry_guide_topics, list(
	"welcome" = list(
		"title" ="Welcome to Deep Quarry",
		"body" = {"
			<p>This is <b>Deep Quarry</b>, a freight-and-mining outpost cut
			into living stone. You are a worker. There is rock around you and
			more rock below; some of it has metal in it; some of it has worse
			things in it. Get rich, or get out.</p>

			<p>This guide is the only thing you'll find around here that
			isn't dust or dangerous. Read the topics on the left. The
			important one is <i>The Elevator</i> — it's how you get in,
			how you get out, and how you go deeper.</p>

			<p>When you're ready, close this window and click <b>Join Game</b>
			in the lobby.</p>
		"},
	),

	"layout" = list(
		"title" ="The Quarry",
		"body" = {"
			<p>You spawn inside the central <b>station room</b>. It has
			plasteel walls, tile floor, a power grid (the SMES and APC are
			in the corners), and lights. This is the only safe spot on the
			surface.</p>

			<p>Outside the room is a procedurally-generated <b>cave
			network</b>. The walls are mineable cave-rock. Some walls hold
			ore. You walk through carved tunnels and mine the rest.</p>

			<p>The room's south wall connects directly to the <b>freight
			elevator</b>. Three lift doors open into a 3×3 cargo bay. From
			there you can descend to the deep quarry.</p>
		"},
	),

	"mining" = list(
		"title" ="Mining",
		"body" = {"
			<p>Find a pickaxe (or any digging tool — improvise if you must).
			Click on a wall of cave-rock. The wall breaks; if it was an ore
			deposit, ore items drop on the floor.</p>

			<p>Ores you'll find on the surface: <b>hematite</b> (iron),
			<b>carbon</b> (coal), <b>copper</b>, <b>tin</b>, <b>quartz</b>.
			Deeper layers have rarer materials — silver, gold, uranium,
			platinum, phoron, diamond, painite.</p>

			<p>Carry ore in your hands or a bag. To preserve it across runs,
			load it into the elevator and send the elevator up — anything in
			the bay travels with the lift.</p>
		"},
	),

	"elevator" = list(
		"title" ="The Elevator",
		"body" = {"
			<p>One freight elevator services the whole quarry. It has a
			3×3 cargo bay at every depth, and it's the <b>only</b> way in
			or out — there are no ladders, no ropes, no shortcuts.</p>

			<p><b>Inside the bay</b>, the south wall has a control panel.
			On a layer, clicking it sends the elevator back up to the
			surface. On the surface, you get two options: go to the
			<i>deepest depth you've already visited</i>, or <i>descend
			one deeper than you've ever been</i> (which generates the new
			layer the first time you do it).</p>

			<p><b>Outside the bay</b>, the NW-corner wall has a call panel.
			Click it to summon the elevator to that floor if it's parked
			elsewhere. The interior dispatch panel auto-calls if needed.</p>

			<p>Loading cargo: drop items on the bay floor, then send. Items
			that aren't anchored ride with the car. The station's structure
			(panels, lights, doors) stays put.</p>
		"},
	),

	"descending" = list(
		"title" ="Descending Deeper",
		"body" = {"
			<p>Every descent past your previous deepest point uses the
			elevator's <i>descend deeper</i> button. Pressing it generates
			the next layer on the spot and sends the elevator down to it.
			This is the only way to push the round's depth watermark
			forward.</p>

			<p>Layers are <b>persistent within a round</b>. The first time
			you visit depth N, a fresh cave is generated. When the last
			player leaves it, the layer's state is snapshotted to disk.
			The next time someone visits depth N — even hours later — the
			snapshot is restored: same mined-out tiles, same dropped loot,
			same scaffolds. Hostile mobs are re-spawned because their
			internal state doesn't round-trip cleanly.</p>

			<p>Ore you've sent up the elevator stays with you regardless
			of what happens to the layer.</p>
		"},
	),

	"coop" = list(
		"title" ="Coop",
		"body" = {"
			<p>Multiple players can share a single quarry instance. The
			rule is simple: <b>at any given depth, everyone visiting that
			depth is on the same layer.</b> If you and a friend both
			descend to layer 5, you meet up there.</p>

			<p>If you join a round late and want to find friends who've
			already gone deep: just descend to the same depth they're on.
			Intermediate layers will be freshly generated as you pass
			through them, but you'll arrive on the existing layer at their
			depth.</p>

			<p>If a player disconnects mid-run, their body counts as
			\"occupying\" the layer — the layer won't unload until they
			either reconnect or are removed.</p>
		"},
	),

	"dangers" = list(
		"title" ="Dangers",
		"body" = {"
			<p><b>Pitch dark.</b> Deep-quarry layers have no ambient light.
			You'll see only the tile you're standing on unless you carry a
			light source (flashlight, helmet lamp, glowing object). The
			elevator bay has its own light fixture.</p>

			<p><b>Mobs.</b> Procedural layers at depth 4 and below may
			spawn hostile fauna — rats, bats, spiders, oregrubs, stalkers.
			Density increases with depth. Bring a weapon if you're going
			past depth 6.</p>

			<p><b>No round-end shuttle.</b> The Deep Quarry round doesn't
			currently have a working evac mechanic. The round either ends
			by admin command or by overrun.</p>
		"},
	),
))


// Returns a sorted list of (key, title) tuples for the index page. Sort
// is just the canonical reading order; defined here so adding a topic to
// the global list is enough — no manual menu update needed elsewhere.
/proc/quarry_guide_order()
	return list(
		"welcome", "layout", "mining", "elevator",
		"descending", "coop", "dangers",
	)


// Renders the index page HTML for a user. Topic links route back via
// the user's Topic() — the new_player handler reads guide_topic and
// shows that page.
/proc/quarry_guide_render_index(mob/user)
	var/dat = "<html><head><title>Deep Quarry Guide</title>"
	dat += "<style>body{font-family:Verdana,sans-serif;font-size:11px;padding:8px;color:#222;background:#f4f1e8}h1{margin-top:0;color:#553}h2{color:#553;border-bottom:1px solid #bba;padding-bottom:2px}a{color:#a44;text-decoration:none}a:hover{text-decoration:underline}.topic{padding:4px 0}.back{margin-top:18px;font-size:10px}</style></head><body>"
	dat += "<h1>Deep Quarry — Field Guide</h1>"
	dat += "<p>Pick a topic to read about it.</p>"
	for(var/key in quarry_guide_order())
		var/list/entry = GLOB.quarry_guide_topics[key]
		if(!entry)
			continue
		dat += "<div class='topic'>&bull; <a href='?src=\ref[user];guide_topic=[key]'>[entry["title"]]</a></div>"
	dat += "</body></html>"
	return dat


// Renders a specific topic page with a back-link to the index.
/proc/quarry_guide_render_topic(mob/user, key)
	var/list/entry = GLOB.quarry_guide_topics[key]
	if(!entry)
		return quarry_guide_render_index(user)
	var/dat = "<html><head><title>Deep Quarry Guide — [entry["title"]]</title>"
	dat += "<style>body{font-family:Verdana,sans-serif;font-size:11px;padding:8px;color:#222;background:#f4f1e8}h2{margin-top:0;color:#553}p{line-height:1.4}a{color:#a44;text-decoration:none}a:hover{text-decoration:underline}.back{margin-top:18px;font-size:10px}</style></head><body>"
	dat += "<h2>[entry["title"]]</h2>"
	dat += entry["body"]
	dat += "<div class='back'>&larr; <a href='?src=\ref[user];guide_topic=__index'>Back to topics</a></div>"
	dat += "</body></html>"
	return dat


// Open the guide for a user, optionally pre-pointed at a key.
/proc/quarry_guide_open(mob/user, key = "__index")
	if(!user?.client)
		return
	var/dat
	if(key == "__index")
		dat = quarry_guide_render_index(user)
	else
		dat = quarry_guide_render_topic(user, key)
	var/datum/browser/popup = new(user, "quarry_guide", "Deep Quarry Guide", 520, 520, user)
	popup.set_content(dat)
	popup.open()
