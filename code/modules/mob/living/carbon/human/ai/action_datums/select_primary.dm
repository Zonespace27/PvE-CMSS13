/datum/ai_action/select_primary
	name = "Select Primary"
	action_flags = ACTION_USING_HANDS

/datum/ai_action/select_primary/get_weight(datum/human_ai_brain/brain)
	if(!brain.tried_reload)
		return 0

	if(brain.primary_weapon?.ai_can_use(brain.tied_human, brain))
		return 0

	return 12

/datum/ai_action/select_primary/Destroy(force, ...)
	return ..()

/datum/ai_action/select_primary/trigger_action()
	. = ..()
	UNLINT(decide_primary_weapon())
	return ONGOING_ACTION_COMPLETED

/datum/ai_action/select_primary/proc/decide_primary_weapon()
	var/obj/item/weapon/gun/best_secondary
	var/datum/firearm_appraisal/best_secondary_appraisal
	for(var/obj/item/weapon/gun/secondary as anything in brain.secondary_weapons)
		if(!secondary.ai_can_use(brain.tied_human, brain))
			continue

		if(!best_secondary)
			best_secondary = secondary
			best_secondary_appraisal = get_firearm_appraisal(best_secondary)
			continue

		var/datum/firearm_appraisal/this_appraisal = get_firearm_appraisal(secondary)
		if(this_appraisal.primary_weight > best_secondary_appraisal.primary_weight)
			best_secondary = secondary
			best_secondary_appraisal = this_appraisal
			continue

	if(!best_secondary)
		return

	if(brain.primary_weapon in brain.tied_human.get_hands())
		var/possible_storage_loc = brain.storage_has_room(brain.primary_weapon)
		if((brain.primary_weapon.flags_equip_slot & SLOT_BACK) && !brain.tied_human.back)
			brain.tied_human.equip_to_slot(brain.primary_weapon, WEAR_BACK, TRUE)
		else if(!brain.tied_human.s_store && brain.tied_human.wear_suit && ((brain.primary_weapon.flags_equip_slot & SLOT_SUIT_STORE) || is_type_in_list(brain.primary_weapon, brain.tied_human.wear_suit.allowed)))
			brain.tied_human.equip_to_slot(brain.primary_weapon, WEAR_J_STORE, TRUE)
		else if(possible_storage_loc)
			brain.store_item(brain.primary_weapon, possible_storage_loc)

	brain.add_secondary_weapon(brain.primary_weapon)
	brain.set_primary_weapon(best_secondary)
	brain.tried_reload = FALSE
	return best_secondary
