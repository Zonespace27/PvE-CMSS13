/datum/human_ai_brain
	var/turf/sniper_home
	var/sniper_dir = SOUTH

/datum/ai_action/sniper_nest
	name = "Sniper Nest"
	action_flags = ACTION_USING_LEGS
	var/initial_view

/datum/ai_action/sniper_nest/get_weight(datum/human_ai_brain/brain)
	if(!brain.sniper_home)
		return 0

	if(brain.current_cover)
		return 0

	if(!brain.primary_weapon)
		return 0

	return 12

/datum/ai_action/sniper_nest/New(datum/human_ai_brain/brain)
	. = ..()
	if(brain)
		initial_view = brain.view_distance

/datum/ai_action/sniper_nest/Destroy(force, ...)
	brain.view_distance = initial_view
	return ..()

/datum/ai_action/sniper_nest/trigger_action()
	if(brain.current_cover || !brain.primary_weapon)
		return ONGOING_ACTION_COMPLETED

	var/turf/sniper_home = brain.sniper_home
	if(QDELETED(sniper_home))
		return ONGOING_ACTION_COMPLETED

	if(get_dist(sniper_home, brain.tied_human) > 0)
		if(!brain.move_to_next_turf(sniper_home))
			return ONGOING_ACTION_COMPLETED

	brain.view_distance = 30
	brain.tied_human.face_dir(brain.sniper_dir)
	return ONGOING_ACTION_UNFINISHED


/datum/admins/proc/create_human_ai_sniper()
	set name = "Create Human AI Sniper"
	set category = "Game Master.HumanAI"

	var/static/list/sniper_equipment_presets = list(
		/datum/equipment_preset/clf/sniper::name = /datum/equipment_preset/clf/sniper
	)

	if(!check_rights(R_DEBUG))
		return

	if(tgui_input_list(usr, "Press Enter to select the home turf of the sniper.", "Home Turf", list("Enter", "Cancel")) != "Enter")
		return

	var/turf/home_turf = get_turf(usr)
	var/turf/target_turf

	while(TRUE)
		if(tgui_input_list(usr, "Press Enter to select the center of the sniper's overwatch. This must be within 30 tiles and not be blocked.", "Target Turf", list("Enter", "Cancel")) == "Enter")
			var/turf/maybe_target_turf = get_turf(usr)
			if(get_dist(home_turf, maybe_target_turf) > 30)
				to_chat(usr, SPAN_WARNING("This turf is too far away. Max range 30, attempted range [get_dist(home_turf, target_turf)]."))
				continue

			if(locate(/turf/closed) in get_line(home_turf, maybe_target_turf))
				to_chat(usr, SPAN_WARNING("A wall is located between the home and target turf."))
				continue
			target_turf = maybe_target_turf
		break

	if(!home_turf || !target_turf)
		return

	var/mob/living/carbon/human/ai_human = new()
	var/datum/component/human_ai/ai_comp = ai_human.AddComponent(/datum/component/human_ai)
	var/chosen_equipment_name = tgui_input_list(usr, "Select sniper equipment.", "Sniper Equipment", sniper_equipment_presets)
	if(!chosen_equipment_name)
		qdel(ai_human)
		return
	arm_equipment(ai_human, sniper_equipment_presets[chosen_equipment_name], TRUE)

	ai_human.forceMove(home_turf)
	ai_comp.ai_brain.sniper_home = home_turf
	ai_comp.ai_brain.sniper_dir = get_dir(home_turf, target_turf)

	to_chat(usr, SPAN_NOTICE("Sniper has been created."))

