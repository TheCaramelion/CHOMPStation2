// Previously known as Head of Security
/datum/job/commander
	title = "NTFD Commander"
	flag = HOS
	departments_managed = list(DEPARTMENT_FRONTIERDEFENSE)
	departments = list(DEPARTMENT_FRONTIERDEFENSE, DEPARTMENT_COMMAND)
	sorting_order = 2
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the Site Manager"
	selection_color = "#e09b34"
	req_admin_notify = 1
	economic_modifier = 10
	access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_armory,
			            access_forensics_lockers, access_morgue, access_maint_tunnels, access_all_personal_lockers,
			            access_research, access_engine, access_mining, access_medical, access_construction, access_mailsorting,
			            access_heads, access_hos, access_RC_announce, access_keycard_auth, access_gateway, access_external_airlocks)
	minimal_access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_armory,
			            access_forensics_lockers, access_morgue, access_maint_tunnels, access_all_personal_lockers,
			            access_research, access_engine, access_mining, access_medical, access_construction, access_mailsorting,
			            access_heads, access_hos, access_RC_announce, access_keycard_auth, access_gateway, access_external_airlocks)
	minimum_character_age = 25
	min_age_by_species = list(SPECIES_HUMAN_VATBORN = 14)
	minimal_player_age = 14
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	ideal_character_age = 50
	ideal_age_by_species = list(SPECIES_HUMAN_VATBORN = 20)
	banned_job_species = list(SPECIES_TESHARI, SPECIES_DIONA, SPECIES_PROMETHEAN, SPECIES_ZADDAT, "digital", SPECIES_UNATHI, "mechanical")

	outfit_type = /decl/hierarchy/outfit/job/security/hos
	job_description = "The NTFD Commander manages the NTFD Department, keeping the station safe and making sure the rules are followed. They are expected to \
						keep the other Department Heads, and the rest of the crew, aware of developing situations that may be a threat. If necessary, the Commander may \
						perform the duties of absent NTFD roles, such as distributing gear from the Armory."
	alt_titles = list("NTFD Chief" = /datum/alt_title/ntfd_chief)

/datum/alt_title/ntfd_chief
	title = "NTFD Chief"

/datum/job/hos/equip(var/mob/living/carbon/human/H)
	. = ..()
	if(.)
		H.implant_loyalty(src)

/datum/job/lieutenant_commander
	title = "NTFD Lieutenant Commander"
	flag = WARDEN
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	sorting_order = 1
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the NTFD Commander"
	selection_color = "#d88c1c"
	economic_modifier = 5
	access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_armory, access_maint_tunnels, access_morgue, access_external_airlocks)
	minimal_access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_armory, access_maint_tunnels, access_external_airlocks)
	minimal_player_age = 5
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	banned_job_species = list(SPECIES_ZADDAT, SPECIES_PROMETHEAN, SPECIES_TESHARI, SPECIES_DIONA)

	outfit_type = /decl/hierarchy/outfit/job/security/warden
	job_description = "The NTFD Lieutenant Commander watches over the physical NTFD Department, making sure the Brig and Armoury are secure and in order at all times. They oversee \
						prisoners that have been processed and brigged, and are responsible for their well being. The NTFD Lieutenant Commander is also in charge of distributing \
						Armoury gear in a crisis, and retrieving it when the crisis has passed. In an emergency, the NTFD Lieutenant Commander may be called upon to direct the \
						NTFD Department as a whole."
	alt_titles = list("Master at Arms" = /datum/alt_title/master_at_arms)

/datum/alt_title/master_at_arms
	title = "Master at Arms"

/datum/job/ntfd_detective
	title = "NTFD Detective Constable"
	flag = DETECTIVE
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the NTFD Commander"
	selection_color = "#d88c1c"
	access = list(access_explorer, access_security, access_sec_doors, access_forensics_lockers, access_morgue, access_maint_tunnels, access_eva, access_external_airlocks, access_brig) //Vorestation edit - access_brig
	minimal_access = list(access_explorer, access_security, access_sec_doors, access_forensics_lockers, access_morgue, access_maint_tunnels, access_eva, access_external_airlocks)
	economic_modifier = 5
	minimal_player_age = 3
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	banned_job_species = list(SPECIES_ZADDAT, SPECIES_PROMETHEAN, SPECIES_DIONA)

	outfit_type = /decl/hierarchy/outfit/job/security/detective
	job_description = "A Detective works to help NTFD find criminals who have not properly been identified, through interviews and forensic work. \
						For crimes only witnessed after the fact, or those with no survivors, they attempt to piece together what they can from pure evidence."
	alt_titles = list()

/datum/job/ensign
	title = "NTFD Ensign"
	flag = OFFICER
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 4
	spawn_positions = 4
	supervisors = "the NTFD Commander"
	selection_color = "#d88c1c"
	economic_modifier = 5
	access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_maint_tunnels, access_morgue, access_external_airlocks)
	minimal_access = list(access_explorer, access_security, access_eva, access_sec_doors, access_brig, access_maint_tunnels, access_external_airlocks)
	minimal_player_age = 3
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	banned_job_species = list(SPECIES_ZADDAT, SPECIES_TESHARI, SPECIES_DIONA)

	outfit_type = /decl/hierarchy/outfit/job/security/officer
	job_description = "An Ensign is concerned with maintaining the safety and security of the station as a whole, dealing with external threats and \
						apprehending criminals. An Ensign is responsible for the health, safety, and processing of any prisoner they arrest. \
						No one is above the Law, not NTFD or Command."
	min_age_by_species = list(SPECIES_PROMETHEAN = 3)

/datum/job/lieutenant
	title = "NTFD Lieutenant"
	flag = PATHFINDER
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	departments_managed = list(DEPARTMENT_FRONTIERDEFENSE)
	sorting_order = 1
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the NTFD Commander and the Research Director"
	selection_color = "#d88c1c"
	economic_modifier = 8
	minimal_player_age = 7
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	dept_time_required = 20
	access = list(access_eva, access_maint_tunnels, access_external_airlocks, access_pilot, access_explorer, access_gateway, access_pathfinder, access_RC_announce)
	minimal_access = list(access_eva, access_maint_tunnels, access_external_airlocks, access_pilot, access_explorer, access_gateway, access_pathfinder, access_RC_announce)
	outfit_type = /decl/hierarchy/outfit/job/pathfinder
	job_description = "The NTFD Lieutenant's job is to lead and manage expeditions, and is the primary authority on all off-station expeditions."

	alt_titles = list("NTFD Forward Operation Lead" = /datum/alt_title/operation_lead, "NTFD Operations Manager" = /datum/alt_title/operations_manager, "NTFD Lieutenant Junior Grade" = /datum/alt_title/lieutenant_junior)

/datum/alt_title/operation_lead
	title = "NTFD Forward Operation Lead"

/datum/alt_title/operations_manager
	title = "NTFD Operations Manager"

/datum/alt_title/lieutenant_junior
	title = "NTFD Lieutenant Junior"

/datum/job/ntfd_crewman
	title = "NTFD Crewman"
	flag = EXPLORER
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 3
	spawn_positions = 3
	supervisors = "the NTFD Lieutenant"
	selection_color = "#d88c1c"
	economic_modifier = 6
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	access = list(access_explorer, access_external_airlocks, access_eva)
	minimal_access = list(access_explorer, access_external_airlocks, access_eva)
	outfit_type = /decl/hierarchy/outfit/job/explorer2
	job_description = "A NTFD Crewman searches for interesting things, and returns them to the station."
	alt_titles =  list("NTFD Crewman Recruit" = /datum/alt_title/crewman_recruit, "NTFD Crewman Apprentice" = /datum/alt_title/crewman_apprentice)

/datum/alt_title/crewman_recruit
	title = "NTFD Crewman Recruit"

/datum/alt_title/crewman_apprentice
	title = "NTFD Crewman Apprentice"

/datum/job/pilot
	title = "NTFD Pilot"
	flag = PILOT
	departments = list(DEPARTMENT_FRONTIERDEFENSE)
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 5
	spawn_positions = 5
	supervisors = "the NTFD Lieutenant"
	selection_color = "#d88c1c"
	economic_modifier = 5
	minimal_player_age = 3
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	access = list(access_pilot, access_external_airlocks, access_eva,access_explorer)
	minimal_access = list(access_pilot, access_external_airlocks, access_eva,access_explorer)
	outfit_type = /decl/hierarchy/outfit/job/pilot
	job_description = "A NTFD Pilot flies the various shuttles in the Vir System."
	alt_titles = list("NTFD Co-Pilot" = /datum/alt_title/ntfd_co_pilot, "NTFD Navigator" = /datum/alt_title/ntfd_navigator, " NTFD Helmsman" = /datum/alt_title/ntfd_helmsman)

/datum/alt_title/ntfd_co_pilot
	title = "NTFD Co-Pilot"
	title_blurb = "A Co-Pilot is there primarily to assist main pilot as well as learn from them"

/datum/alt_title/ntfd_navigator
	title = "NTFD Navigator"

/datum/alt_title/ntfd_helmsman
	title = "NTFD Helmsman"

/datum/job/ntfd_sar
	title = "NTFD Field Medic"
	flag = SAR
	departments = list(DEPARTMENT_FRONTIERDEFENSE, DEPARTMENT_MEDICAL)
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Lieutenant"
	selection_color = "#d88c1c"
	economic_modifier = 6
	minimal_player_age = 3
	pto_type = PTO_FRONTIERDEFENSE
	disallow_jobhop = TRUE
	access = list(access_medical, access_medical_equip, access_morgue, access_eva, access_maint_tunnels, access_external_airlocks,access_explorer)
	minimal_access = list(access_medical, access_medical_equip, access_morgue,access_explorer)
	outfit_type = /decl/hierarchy/outfit/job/medical/sar
	job_description = "A NTFD Field medic works as the field doctor of expedition teams."
