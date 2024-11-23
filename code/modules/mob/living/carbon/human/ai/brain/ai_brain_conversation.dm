GLOBAL_LIST_INIT(human_ai_conversations, initialize_human_ai_conversations())
GLOBAL_LIST_EMPTY(active_human_ai_conversations)

/proc/initialize_human_ai_conversations()
	var/list/return_list = list()
	for(var/subtype_convo in subtypesof(/datum/human_ai_conversation)) // init not working
		var/datum/human_ai_conversation/new_convo = subtype_convo
		if(new_convo::amount_ai_involved > length(return_list))
			return_list.len = new_convo::amount_ai_involved
			for(var/i in length(return_list) + 1 to new_convo::amount_ai_involved)
				return_list[i] = list()
		return_list[new_convo::amount_ai_involved] += new_convo
	return return_list

// Not singletons.
/datum/human_ai_conversation
	var/amount_ai_involved = 2
	/// The time is how long to delay after saying something
	var/list/conversation_data = list(
		"P1 Message 1",
		"D 25",
		"P2 Message 2",
	)

/datum/human_ai_conversation/New()
	. = ..()
	GLOB.active_human_ai_conversations += src

/datum/human_ai_conversation/Destroy(force, ...)
	GLOB.active_human_ai_conversations -= src
	return ..()

/datum/human_ai_conversation/hello
	amount_ai_involved = 2
	conversation_data = list(
		"P1 Hello.",
		"D 16",
		"P2 Hello.",
		"D 25",
		"P1 How are you doing?",
		"D 25",
		"P2 I'm doing well, how are you?",
		"D 15",
		"P1 I'm doin' pretty alright.",
	)

/datum/human_ai_conversation/proc/initiate_conversation(list/brains_involved)
	if(!length(brains_involved))
		return

	for(var/datum/human_ai_brain/brain as anything in brains_involved)
		brain.in_conversation = TRUE

	for(var/string in conversation_data)
		switch(string[1])
			if("P")
				var/ai_index = text2num(string[2]) // doesn't currently support indexes >9, but can be fixed if that ever comes up, somehow
				var/datum/human_ai_brain/brain = brains_involved[ai_index]
				if(should_interrupt_conversation(brain))
					for(var/datum/human_ai_brain/other_brain as anything in brains_involved)
						other_brain.in_conversation = FALSE
					qdel(src)
					return

				for(var/datum/human_ai_brain/other_brain as anything in brains_involved)
					if(brain == other_brain)
						continue
					other_brain.tied_human.setDir(get_cardinal_dir(other_brain.tied_human, brain.tied_human))

				brain.tied_human.say(copytext(string, 4))
			if("D")
				sleep(text2num(copytext(string, 3)))

	for(var/datum/human_ai_brain/other_brain as anything in brains_involved)
		other_brain.in_conversation = FALSE

/datum/human_ai_conversation/proc/should_interrupt_conversation(datum/human_ai_brain/brain)
	return (brain.in_combat || !brain.in_conversation || (brain.tied_human.health < HEALTH_THRESHOLD_CRIT))

/datum/human_ai_brain
	var/in_conversation = FALSE
	var/conversation_start_prob = 0.15 // at 5 chances / sec, this'll mean we hit the equivalent of a 50% chance of a conversation at ~460 chances, which would take ~92 seconds
