/obj/item/clothing/head/helmet/space/rig/ert
	light_overlay = "helmet_light_dual"
	camera_networks = list(NETWORK_ERT)

/obj/item/rig/ert
	name = "ERT-C hardsuit control module"
	desc = "A suit worn by the commander of an Emergency Response Team. Has blue highlights. Armoured and space ready."
	suit_type = "ERT commander"
	icon_state = "ert_commander_rig"

	helm_type = /obj/item/clothing/head/helmet/space/rig/ert

	req_access = list(access_cent_specops)
	siemens_coefficient= 0.5

	armor = list(melee = 60, bullet = 50, laser = 30,energy = 15, bomb = 30, bio = 100, rad = 100)
	allowed = list(POCKET_GENERIC, POCKET_EMERGENCY, POCKET_ALL_TANKS, POCKET_SUIT_REGULATORS, POCKET_ENGINEERING, POCKET_CE, POCKET_SECURITY, POCKET_MEDICAL, POCKET_HEAVYTOOLS, POCKET_BAYSUIT)

	initial_modules = list(
		/obj/item/rig_module/ai_container,
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/datajack,
		)

/obj/item/rig/ert/engineer
	name = "ERT-E suit control module"
	desc = "A suit worn by the engineering division of an Emergency Response Team. Has orange highlights. Armoured and space ready."
	suit_type = "ERT engineer"
	icon_state = "ert_engineer_rig"
	armor = list(melee = 60, bullet = 50, laser = 30,energy = 15, bomb = 30, bio = 100, rad = 100)
	glove_type = /obj/item/clothing/gloves/gauntlets/rig/eva

	initial_modules = list(
		/obj/item/rig_module/ai_container,
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/device/plasmacutter,
		/obj/item/rig_module/device/rcd
		)

/obj/item/rig/ert/medical
	name = "ERT-M suit control module"
	desc = "A suit worn by the medical division of an Emergency Response Team. Has white highlights. Armoured and space ready."
	suit_type = "ERT medic"
	icon_state = "ert_medical_rig"

	initial_modules = list(
		/obj/item/rig_module/ai_container,
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/device/healthscanner,
		/obj/item/rig_module/chem_dispenser/injector/advanced
		)

/obj/item/rig/ert/security
	name = "ERT-S suit control module"
	desc = "A suit worn by the security division of an Emergency Response Team. Has red highlights. Armoured and space ready."
	suit_type = "ERT security"
	icon_state = "ert_security_rig"

	initial_modules = list(
		/obj/item/rig_module/ai_container,
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/grenade_launcher,
		/obj/item/rig_module/mounted/egun,
		)

/obj/item/rig/ert/assetprotection
	name = "Heavy Asset Protection suit control module"
	desc = "A heavy suit worn by the highest level of Asset Protection, don't mess with the person wearing this. Armoured and space ready."
	suit_type = "heavy asset protection"
	icon_state = "asset_protection_rig"
	armor = list(melee = 80, bullet = 70, laser = 60, energy = 15, bomb = 80, bio = 100, rad = 60)
	siemens_coefficient= 0.3
	glove_type = /obj/item/clothing/gloves/gauntlets/rig/eva
	//CHOMPEdit Begin
	rigsuit_max_pressure = 20 * ONE_ATMOSPHERE
	rigsuit_min_pressure = 0
	max_heat_protection_temperature = FIRE_HELMET_MAX_HEAT_PROTECTION_TEMPERATURE
	//CHOMPEdit End

	initial_modules = list(
		/obj/item/rig_module/ai_container,
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/grenade_launcher,
		/obj/item/rig_module/vision/multi,
		/obj/item/rig_module/mounted/egun,
		/obj/item/rig_module/chem_dispenser/injector,
		/obj/item/rig_module/device/plasmacutter,
		/obj/item/rig_module/device/rcd,
		/obj/item/rig_module/datajack
		)

/obj/item/rig/ert/janitor
	name = "ERT-J suit control module"
	desc = "A suit worn by the janitorial division of an Emergency Response Team. Has purple highlights. Armoured and space ready."
	suit_type = "ERT janitor"
	icon_state = "ert_janitor_rig"

	initial_modules = list(
		/obj/item/rig_module/maneuvering_jets,
		/obj/item/rig_module/cleaner_launcher,
		)
