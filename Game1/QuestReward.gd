extends Resource
class_name QuestReward

enum RewardType {
	UNLOCK_EXIT,
	GIVE_ITEM,
	CUSTOM
}

@export var rewards: Dictionary = {}
@export var custom_function: String = ""  # For custom reward functions

func add_reward(reward_type: RewardType, reward_value: Resource):
	if not rewards.has(reward_type):
		rewards[reward_type] = []
	rewards[reward_type].append(reward_value)

func apply_rewards(player, current_room) -> String:
	var result = []
	for reward_type in rewards.keys():
		for reward_value in rewards[reward_type]:
			match reward_type:
				RewardType.UNLOCK_EXIT:
					if reward_value is Exit:
						reward_value.unlock()
						result.append("The " + reward_value.lock_name + " has been unlocked!")
				RewardType.GIVE_ITEM:
					if reward_value is Item:
						player.take_item(reward_value)
						result.append("You received " + reward_value.item_name + "!")
				RewardType.CUSTOM:
					if custom_function != "":
						result.append(current_room.get_parent().call(custom_function, player))
	
	if result.is_empty():
		return "No rewards applied."
	else:
		return "\n".join(result)
