/obj/structure/table/rack
	icon = 'icons/obj/objects_vr.dmi'

/obj/structure/table/rack/steel
	color = "#666666"

/obj/structure/table/rack/steel/Initialize(mapload)
	material = get_material_by_name(MAT_STEEL)
	. = ..()

/obj/structure/table/rack/shelf
	name = "shelving"
	desc = "Some nice metal shelves."
	icon_state = "shelf"

/obj/structure/table/rack/shelf/steel
	color = "#666666"

/obj/structure/table/rack/shelf/steel/Initialize(mapload)
	material = get_material_by_name(MAT_STEEL)
	. = ..()

// SOMEONE should add cool overlay stuff to this
/obj/structure/table/rack/gun_rack
	name = "gun rack"
	desc = "Seems like you could prop up some rifles here."
	icon_state = "gunrack"

/obj/structure/table/rack/gun_rack/steel
	color = "#666666"

/obj/structure/table/rack/gun_rack/steel/Initialize(mapload)
	material = get_material_by_name(MAT_STEEL)
	. = ..()

/obj/structure/table/rack/wood
	color = "#A1662F"

/obj/structure/table/rack/wood/Initialize(mapload)
	material = get_material_by_name(MAT_WOOD)
	. = ..()

/obj/structure/table/rack/shelf/wood
	color = "#A1662F"

/obj/structure/table/rack/shelf/wood/Initialize(mapload)
	material = get_material_by_name(MAT_WOOD)
	. = ..()
