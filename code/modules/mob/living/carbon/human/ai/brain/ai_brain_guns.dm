/datum/human_ai_brain
	var/obj/item/weapon/gun/primary_weapon
	//var/obj/item/weapon/primary_melee
	/// Appraisal datum
	var/datum/firearm_appraisal/gun_data
	/// If we've tried to reload (and failed) with our current inventory
	var/tried_reload = FALSE
	/// Cooldown for if we've fired too many rounds in a burst (for recoil)
	COOLDOWN_DECLARE(fire_overload_cooldown)

/datum/human_ai_brain/proc/should_reload()
	if(!primary_weapon)
		return FALSE

	if(primary_weapon.in_chamber)
		return FALSE

	if(!primary_weapon.current_mag)
		return TRUE

	if(primary_weapon.current_mag.current_rounds > 0)
		return FALSE

	return TRUE

/datum/human_ai_brain/proc/unholster_primary()
	if(tied_human.l_hand == primary_weapon || tied_human.r_hand == primary_weapon)
		return

	if(tied_human.get_active_hand())
		tied_human.drop_held_item(tied_human.get_active_hand())

	tied_human.u_equip(primary_weapon)
	tied_human.put_in_active_hand(primary_weapon)
	sleep(max(primary_weapon.wield_delay, short_action_delay * action_delay_mult))
	primary_weapon?.wield(tied_human)

/datum/human_ai_brain/proc/holster_primary()
	if(tied_human.s_store || (tied_human.l_hand != primary_weapon && tied_human.r_hand != primary_weapon))
		return

	tied_human.equip_to_slot_if_possible(primary_weapon, WEAR_J_STORE, TRUE)
