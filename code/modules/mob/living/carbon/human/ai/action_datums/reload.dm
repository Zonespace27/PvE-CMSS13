/datum/ai_action/reload
	name = "Reload"
	action_flags = ACTION_USING_HANDS
	var/currently_reloading

/datum/ai_action/reload/get_weight(datum/human_ai_brain/brain)
	if(brain.tried_reload)
		return 0

	if(brain.gun_data?.disposable)
		return 0

	if(!brain.should_reload())
		return 0

	return 15

/datum/ai_action/reload/Destroy(force, ...)
	currently_reloading = FALSE
	return ..()

/datum/ai_action/reload/trigger_action()
	if(currently_reloading)
		return ONGOING_ACTION_UNFINISHED

	var/obj/item/weapon/gun/primary_weapon = brain.primary_weapon
	if(!primary_weapon || brain.tried_reload || !brain.should_reload())
		return ONGOING_ACTION_COMPLETED

	reload()

/datum/ai_action/reload/proc/reload()
	set waitfor = FALSE

	currently_reloading = TRUE

	/// Find ammo
	var/obj/item/ammo_magazine/mag = primary_ammo_search()
	if(!mag)
		brain.ongoing_actions -= src
		brain.tried_reload = TRUE
		qdel(src)
		return

	var/short_action_delay = brain.short_action_delay
	var/micro_action_delay = brain.micro_action_delay
	var/action_delay_mult = brain.action_delay_mult

	var/obj/item/weapon/gun/primary_weapon = brain.primary_weapon
	var/mob/living/carbon/human/tied_human = brain.tied_human

	/// Reload sequence
	brain.unholster_primary()
	brain.ensure_primary_hand(primary_weapon)
	primary_weapon.unwield(tied_human)
	sleep(short_action_delay * action_delay_mult)

	if(!(primary_weapon?.flags_gun_features & GUN_INTERNAL_MAG) && primary_weapon?.current_mag)
		primary_weapon?.unload(tied_human, FALSE, TRUE, FALSE)
	tied_human.swap_hand()
	sleep(micro_action_delay * action_delay_mult)

	brain.equip_item_from_equipment_map(HUMAN_AI_AMMUNITION, mag)
	sleep(short_action_delay * action_delay_mult)

	if(istype(mag, /obj/item/ammo_magazine/handful))
		for(var/i in 1 to mag.current_rounds)
			primary_weapon?.attackby(mag, tied_human)
			sleep(micro_action_delay * action_delay_mult)
		if(!QDELETED(mag) && (mag.current_rounds > 0))
			var/storage_slot = brain.storage_has_room(mag)
			if(storage_slot)
				brain.store_item(mag, storage_slot, HUMAN_AI_AMMUNITION)
			else
				tied_human.drop_held_item(mag)
	else
		primary_weapon?.attackby(mag, tied_human)
	sleep(short_action_delay * action_delay_mult)

	tied_human.swap_hand()
	primary_weapon?.wield(tied_human)

	currently_reloading = FALSE

/datum/ai_action/reload/proc/primary_ammo_search()
	for(var/obj/item/ammo_magazine/mag as anything in brain.equipment_map[HUMAN_AI_AMMUNITION])
		if(istype(brain.primary_weapon, mag.gun_type) && mag.ai_can_use(brain.tied_human, src))
			return mag
