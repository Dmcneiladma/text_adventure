extends Node

var current_room = null
var player = null
var replay_manager = null

@warning_ignore("shadowed_variable")
func initialize(starting_room, player, replay_manager) -> String:
	if starting_room == null or player == null or replay_manager == null:
		push_error("Starting room, player, or replay manager cannot be null")
		return "Initialization error"
	self.player = player
	self.replay_manager = replay_manager
	self.current_room = null  # Reset current room
	return change_room(starting_room)

func process_command(input: String) -> String:
	var words = input.split(" ", false)
	if words.size() == 0:
		return "Error: no words were parsed."
		
	var first_word = words[0].to_lower()
	var second_word = " "
	if words.size() > 1:
		second_word = words[1].to_lower()
		
	match first_word:
		"go" :
			return go(second_word)
		"take" :
			return take(second_word)
		"drop" :
			return drop(second_word)
		"inventory":
			return inventory()
		"use" :
			return use(second_word)
		"talk":
			return talk(second_word)
		"give":
			return give(second_word)
		"help" :
			return help()
		"save":
			return save_game()
		"load":
			return load_game()
		_:
			return "Unrecognized command- please try again."

func save_game() -> String:
	if replay_manager == null:
		push_error("Replay manager is not initialized")
		return "Save failed"
	replay_manager.save_game()
	return "Game saved successfully."

func load_game() -> String:
	if replay_manager == null:
		push_error("Replay manager is not initialized")
		return "Load failed"
	replay_manager.load_game()
	return "Game loaded successfully."

func go(second_word: String) -> String:
	if second_word == " ":
		return "Go where?"
		
	if current_room.exits.keys().has(second_word):
		var exit = current_room.exits[second_word]
		if exit.is_locked:
			return "The way %s is currently locked!" % second_word
		var change_response = change_room(exit.get_other_room(current_room))
		return "\n".join(PackedStringArray(["You go %s." % second_word, change_response]))
	else:
		return "This room has no exit in that direction!"

func take(second_word: String) -> String:
	if second_word == " ":
		return "Take what?"
	
	for item in current_room.items:
		if second_word.to_lower() == item.item_name.to_lower():
			current_room.remove_item(item)
			player.take_item(item)
			return "You take the " + item.item_name
	return "You don't see that in this room."

func drop(second_word: String) -> String:
	if second_word == " ":
		return "Drop what?"
	
	for item in player.inventory:
		if second_word.to_lower() == item.item_name.to_lower():
			current_room.add_item(item)
			player.drop_item(item)
			return "You drop the " + item.item_name

	return "You don't have that item."

func inventory() -> String:
	return player.get_inventory_list()

func use(second_word: String) -> String:
	if second_word == " ":
		return "Use what?"
	
	for item in player.inventory:
		if second_word.to_lower() == item.item_name.to_lower():
			match item.item_type:
				Types.ItemTypes.KEY:
					for exit in current_room.exits.values():
						if exit == item.use_value:
							exit.is_locked = false
							player.drop_item(item)
							return "You use %s to unlock a door to %s" % [item.item_name, exit.get_other_room(current_room).room_name]
					return "That item does not unlock any doors here."
				_:
					return "Error - tried to use an item with an invalid type."
	
	return "You don't have that item."

func talk(second_word: String) -> String:
	if second_word == "":
		return "Talk to who?"
	
	for npc in current_room.npcs:
		if second_word.to_lower() == npc.npc_name.to_lower():
			var dialog = npc.post_quest_dialog if npc.has_received_quest_item else npc.initial_dialog
			return npc.npc_name + ": \"" + dialog + "\""
	
	return "That person is not in this room."

func give(second_word: String) -> String:
	if second_word == " ":
		return "Give what?"

	var has_item = false
	for item in player.inventory:
		if second_word.to_lower() == item.item_name.to_lower():
			has_item = true

	if not has_item:
		return "You don't have that item."

	for npc in current_room.npcs:
		if npc.quest_item != null and second_word.to_lower() == npc.quest_item.item_name.to_lower():
			npc.has_received_quest_item = true
			if npc.quest_reward != null:
				var reward = npc.quest_reward
				if "is_locked" in reward:   #duck typing that could be part of quest script/node/resource
					reward.is_locked = false
				else:
					printerr("Warning - tried to have a quest reward that isn't implemented")
			for item in player.inventory:
				if second_word.to_lower() == item.item_name.to_lower():
					player.drop_item(item)
			return "You give the %s to the %s." % [second_word, npc.npc_name]

	return "Nobody here wants that."

func help() -> String:
	return "You can use these commands: go [location], take [item], use [item], drop [item], talk [npc], give [item], inventory, help, save, load"

func change_room(new_room: GameRoom) -> String:
	if new_room == null:
		push_error("New room cannot be null")
		return "Change room failed"
	current_room = new_room
	return new_room.get_full_description()
