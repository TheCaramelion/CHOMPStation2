/datum/recipe/generalschicken
	appliance = FRYER
	reagents = list(REAGENT_ID_CAPSAICIN = 2, REAGENT_ID_SUGAR = 2, REAGENT_ID_BATTER = 10)
	items = list(
		/obj/item/reagent_containers/food/snacks/meat,
		/obj/item/reagent_containers/food/snacks/meat
	)
	result = /obj/item/reagent_containers/food/snacks/generalschicken

/datum/recipe/chickenwings
	appliance = FRYER
	reagents = list(REAGENT_ID_CAPSAICIN = 5, REAGENT_ID_BATTER = 10)
	items = list(
		/obj/item/reagent_containers/food/snacks/meat,
		/obj/item/reagent_containers/food/snacks/meat,
		/obj/item/reagent_containers/food/snacks/meat,
		/obj/item/reagent_containers/food/snacks/meat
	)
	result = /obj/item/storage/box/wings //This is kinda like the donut box.

/datum/recipe/locust
	appliance = FRYER
	reagents = list(REAGENT_ID_SODIUMCHLORIDE = 1)
	items = list(
		/obj/item/reagent_containers/food/snacks/locust
	)
	result = /obj/item/reagent_containers/food/snacks/locust_cooked
