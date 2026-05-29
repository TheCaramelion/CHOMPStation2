GLOBAL_LIST_EMPTY_TYPED(loadout_categories, /datum/loadout_category)
GLOBAL_LIST_EMPTY_TYPED(gear_datums, /datum/gear)

/datum/loadout_category
	var/category = ""
	var/list/gear = list()

/datum/loadout_category/New(cat)
	category = cat
	..()

/hook/startup/proc/populate_gear_list()

	//create a list of gear datums to sort
	for(var/datum/gear/G as anything in subtypesof(/datum/gear))
		if(initial(G.type_category) == G)
			continue
		var/use_name = initial(G.display_name)
		var/use_category = initial(G.sort_category)

		if(!use_name)
			log_world("## ERROR Loadout - Missing display name: [G]")
			continue
		if(isnull(initial(G.cost)))
			log_world("## ERROR Loadout - Missing cost: [G]")
			continue
		if(!initial(G.path))
			log_world("## ERROR Loadout - Missing path definition: [G]")
			continue

		if(!GLOB.loadout_categories[use_category])
			GLOB.loadout_categories[use_category] = new /datum/loadout_category(use_category)
		var/datum/loadout_category/LC = GLOB.loadout_categories[use_category]
		GLOB.gear_datums[use_name] = new G
		LC.gear[use_name] = GLOB.gear_datums[use_name]

	return 1

// DQEdit — /datum/category_item/player_setup_item/loadout/loadout (the Bay loadout tab)
// deleted. /datum/preference_editor/loadout owns the new UI.

/datum/gear
	var/display_name       //Name/index. Must be unique.
	var/description        //Description of this gear. If left blank will default to the description of the pathed item.
	var/path               //Path to item.
	var/variant            // DQAdd — variant key for consolidated parent types
	var/cost = 1           //Number of points used. Items in general cost 1 point, storage/armor/gloves/special use costs 2 points.
	var/slot               //Slot to equip to.
	var/list/allowed_roles //Roles that can spawn with this item.
	var/show_roles = TRUE	//Show the role restrictions on this item?
	var/whitelisted        //Term to check the whitelist for..
	var/sort_category = "General"
	var/list/gear_tweaks = list() //List of datums which will alter the item after it has been spawned.
	var/exploitable = 0		//Does it go on the exploitable information list?
	var/type_category = null
	var/list/ckeywhitelist	//restricted based on these ckeys?
	var/list/character_name	//restricted to these character names?

/datum/gear/New()
	..()
	if(!description)
		var/obj/O = path
		description = initial(O.desc)
	// DQEdit — gear_tweak_free_matrix_recolor swapped for gear_tweak_unified_recolor,
	// which packs tint / palette-swap / matrix into one mode-selectable tweak (see
	// modular_dq/code/datums/gear/gear_tweak_recolor.dm).
	gear_tweaks = list(GLOB.gear_tweak_free_name, GLOB.gear_tweak_free_desc, GLOB.gear_tweak_item_tf_spawn, GLOB.gear_tweak_unified_recolor, GLOB.gear_tweak_free_digestable)

/datum/gear_data
	var/path
	var/location

/datum/gear_data/New(path, location)
	src.path = path
	src.location = location

/datum/gear/proc/spawn_item(location, metadata)
	var/datum/gear_data/gd = new(path, location)
	// DQEdit — propagate variant from gear to gear_data so tweaks can override it.
	gd.variant = variant
	// DQEdit — key metadata by 1-based gear_tweaks index instead of `"[gt]"` (the datum's
	// runtime text rep), so values persist across server restarts. The DQ loadout editor
	// also writes by index.
	if(length(gear_tweaks) && metadata)
		for(var/i in 1 to length(gear_tweaks))
			var/datum/gear_tweak/gt = gear_tweaks[i]
			gt.tweak_gear_data(metadata["[i]"], gd)
	// DQEdit — spawn via helper to apply variant.
	var/item = spawn_with_variant(gd.path, gd.location, gd.variant)
	if(length(gear_tweaks) && metadata)
		for(var/i in 1 to length(gear_tweaks))
			var/datum/gear_tweak/gt = gear_tweaks[i]
			gt.tweak_item(item, metadata["[i]"])
	var/mob/M = location
	if(istype(M) && exploitable) //Update exploitable info records for the mob without creating a duplicate object at their feet.
		M.amend_exploitable(item)
	return item
