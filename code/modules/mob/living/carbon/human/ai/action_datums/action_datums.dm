GLOBAL_LIST_INIT_TYPED(AI_actions, /datum/ai_action, setup_ai_actions())

/proc/setup_ai_actions()
	var/list/action_list = list()
	for(var/action in subtypesof(/datum/ai_action))
		var/datum/ai_action/A = new action
		action_list[A.type] = A
	return action_list


/datum/ai_action
	var/name
	var/datum/human_ai_brain/brain
	var/action_flags = null
	var/order = FALSE // REDUNDANT DELETE DELETE REMOVE EXTERMINATE

/datum/ai_action/proc/get_weight(datum/human_ai_brain/brain)
	return 0

/datum/ai_action/proc/get_conflicts(datum/human_ai_brain/brain)
	RETURN_TYPE(/list)
	. = list()

	if(!action_flags)
		return

	for(var/action_type as anything in GLOB.AI_actions)
		if(GLOB.AI_actions[action_type].action_flags & action_flags)
			. += action_type

/datum/ai_action/New(datum/human_ai_brain/brain)
	. = ..()
	src.brain = brain

/datum/ai_action/Destroy(force, ...)
	brain = null
	return ..()

/datum/ai_action/proc/trigger_action()
	//SHOULD_NOT_SLEEP(TRUE) make all loop actions ASYNC for the sake of parralel use
	return ONGOING_ACTION_COMPLETED
