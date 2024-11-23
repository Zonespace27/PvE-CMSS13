/datum/ai_action/converse
	name = "Start Conversation"
	action_flags = ACTION_USING_MOUTH

/datum/ai_action/converse/get_weight(datum/human_ai_brain/brain)
	if(brain.in_combat || brain.in_conversation || (brain.tied_human.health < HEALTH_THRESHOLD_CRIT))
		return 0

	if(!prob(brain.conversation_start_prob))
		return 0

	return 5

/datum/ai_action/converse/trigger_action()
	. = ..()
	if(.)
		return .

	var/list/ai_nearby = list()
	for(var/mob/living/carbon/human/nearby_human in range(2, brain.tied_human))
		var/datum/human_ai_brain/other_brain = nearby_human.get_ai_brain()
		if(!other_brain || other_brain.in_combat || other_brain.in_conversation || (other_brain.tied_human.health < HEALTH_THRESHOLD_CRIT))
			continue

		ai_nearby += other_brain

	if(length(ai_nearby) <= 1)
		return ONGOING_ACTION_COMPLETED

	if(length(ai_nearby) > length(GLOB.human_ai_conversations))
		var/list/cut_down_ai_nearby = list()
		for(var/i in 1 to length(GLOB.human_ai_conversations))
			cut_down_ai_nearby += pick_n_take(ai_nearby)
		ai_nearby = cut_down_ai_nearby

	var/convo_type = pick(GLOB.human_ai_conversations[length(ai_nearby)])
	var/datum/human_ai_conversation/gotten_convo = new convo_type
	INVOKE_ASYNC(gotten_convo, TYPE_PROC_REF(/datum/human_ai_conversation, initiate_conversation), ai_nearby)
	return ONGOING_ACTION_COMPLETED

