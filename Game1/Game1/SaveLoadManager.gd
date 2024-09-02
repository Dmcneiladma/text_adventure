extends Node

const SAVE_FILE_PATH = "user://savegame.save"

var command_processor: Node
var picked_up_items = []

func _ready():
	# No need to initialize room mapping if using node names directly
	pass

func save_game() -> String:
	var save_data = {
		"current_room": command_processor.current_room.name,
		"player_inventory": [],
		"npc_states": {},
		"room_states": {},
		"picked_up_items": picked_up_items
	}
	
	# Save player inventory
	for item in command_processor.player.inventory:
		save_data["player_inventory"].append(item.resource_path)
		if item.resource_path not in picked_up_items:
			picked_up_items.append(item.resource_path)
	
	# Save NPC states
	for room in get_tree().get_nodes_in_group("rooms"):
		for npc in room.npcs:
			save_data["npc_states"][npc.npc_name] = {
				"has_received_quest_item": npc.has_received_quest_item,
				"room": room.name
			}
	
	# Save room states
	for room in get_tree().get_nodes_in_group("rooms"):
		var room_data = {
			"items": [],
			"npcs": [],
			"locked_exits": {}
		}
		for item in room.items:
			if not command_processor.player.inventory.has(item):
				room_data["items"].append(item.resource_path)
		for npc in room.npcs:
			room_data["npcs"].append(npc.npc_name)
		for direction in room.exits.keys():
			if room.exits[direction].is_locked:
				room_data["locked_exits"][direction] = true
		save_data["room_states"][room.name] = room_data
	
	# Save the data to a file
	var save_game = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	save_game.store_line(JSON.stringify(save_data))
	save_game.close()
	
	return "Game saved successfully."

func load_game() -> String:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return "No saved game found."
	
	var save_game = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var json_string = save_game.get_line()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return "Failed to parse saved game data."
	
	var save_data = json.get_data()
	
	command_processor.change_room(get_room_by_name(save_data["current_room"]))
	
	command_processor.player.inventory.clear()
	for item_path in save_data["player_inventory"]:
		var item = load(item_path)
		if item:
			command_processor.player.take_item(item)
	
	# Ensure picked_up_items is correctly accessed
	if save_data.has("picked_up_items"):
		picked_up_items = save_data["picked_up_items"]
	else:
		picked_up_items = []
	
	for npc_name in save_data["npc_states"].keys():
		var npc_data = save_data["npc_states"][npc_name]
		var npc = get_npc_by_name(npc_name)
		if npc:
			npc.has_received_quest_item = npc_data["has_received_quest_item"]
			move_npc_to_room(npc, get_room_by_name(npc_data["room"]))
	
	for room_name in save_data["room_states"].keys():
		var room_data = save_data["room_states"][room_name]
		var room = get_room_by_name(room_name)
		if room:
			room.items.clear()  # Clear existing items in the room
			for item_path in room_data["items"]:
				if item_path not in picked_up_items:
					var item = load(item_path)
					if item:
						room.add_item(item)
			
			room.npcs.clear()  # Clear existing NPCs in the room
			for npc_name in room_data["npcs"]:
				var npc = get_npc_by_name(npc_name)
				if npc:
					room.npcs.append(npc)
			
			for direction in room_data["locked_exits"].keys():
				if room.exits.has(direction):
					room.exits[direction].is_locked = true
	
	return "Game loaded successfully."

func get_room_by_name(room_name: String) -> Node:
	return get_node("/root/Game/RoomManager/" + room_name)

func get_npc_by_name(npc_name: String) -> Node:
	for room in get_tree().get_nodes_in_group("rooms"):
		for npc in room.npcs:
			if npc.npc_name == npc_name:
				return npc
	return null

func move_npc_to_room(npc: Node, new_room: Node):
	for room in get_tree().get_nodes_in_group("rooms"):
		if npc in room.npcs:
			room.npcs.erase(npc)
			break
	new_room.npcs.append(npc)
