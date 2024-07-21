/decl/hierarchy/outfit/job/frontierdefense
	hierarchy_type = /decl/hierarchy/outfit/job/frontierdefense
	glasses = /obj/item/clothing/glasses/sunglasses/sechud
	l_ear = /obj/item/device/radio/headset/headset_ntfd
	gloves = /obj/item/clothing/gloves/black
	shoes = /obj/item/clothing/shoes/boots/jackboots
	backpack = /obj/item/weapon/storage/backpack/security
	satchel_one = /obj/item/weapon/storage/backpack/satchel/sec
	backpack_contents = list(/obj/item/weapon/handcuffs = 1)
	messenger_bag = /obj/item/weapon/storage/backpack/messenger/sec
	sports_bag = /obj/item/weapon/storage/backpack/sport/sec

/decl/hierarchy/outfit/job/frontierdefense/commander
	name = OUTFIT_JOB_NAME("NTFD Commander")
	l_ear = /obj/item/device/radio/headset/heads/commander
	uniform = /obj/item/clothing/under/rank/head_of_security
	id_type = /obj/item/weapon/card/id/ntfd/commander
	pda_type = /obj/item/device/pda/heads/hos

/decl/hierarchy/outfit/job/frontierdefense/lieutenantcomm
	name = OUTFIT_JOB_NAME("NTFD Lieutenant Commander")
	uniform = /obj/item/clothing/under/rank/warden
	l_pocket = /obj/item/device/flash
	id_type = /obj/item/weapon/card/id/ntfd/lieutenantcomm
	pda_type = /obj/item/device/pda/warden

/decl/hierarchy/outfit/job/frontierdefense/detective
	name = OUTFIT_JOB_NAME("Detective")
	head = /obj/item/clothing/head/det
	uniform = /obj/item/clothing/under/det
	suit = /obj/item/clothing/suit/storage/det_trench
	l_pocket = /obj/item/weapon/flame/lighter/zippo
	shoes = /obj/item/clothing/shoes/laceup
	r_hand = /obj/item/weapon/storage/briefcase/crimekit
	id_type = /obj/item/weapon/card/id/ntfd/detective
	pda_type = /obj/item/device/pda/detective
	backpack = /obj/item/weapon/storage/backpack
	satchel_one = /obj/item/weapon/storage/backpack/satchel/norm
	backpack_contents = list(/obj/item/weapon/storage/box/evidence = 1)
	gloves = /obj/item/clothing/gloves/forensic

/decl/hierarchy/outfit/job/frontierdefense/ensign
	name = OUTFIT_JOB_NAME("Ensign")
	uniform = /obj/item/clothing/under/rank/security
	l_pocket = /obj/item/device/flash
	id_type = /obj/item/weapon/card/id/ntfd/ensign
	pda_type = /obj/item/device/pda/security
