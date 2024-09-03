@tool
extends PanelContainer
class_name GameRoom

@export var room_name : String = "Room Name" : set = set_room_name
@export_multiline var room_description : String = "This is the description." : set = set_room_description
@export_multiline var exit_description : String = "" : set = set_exit_description

var exits: Dictionary = {}
var npcs : Array = []
var items: Array = []
var enemy: Enemy = null

func set_room_name(new_name: String):
	$MarginContainer/Rows/RoomName.text = new_name
	room_name = new_name

func set_room_description(new_description: String):
	$MarginContainer/Rows/RoomDescription.text = new_description
	room_description = new_description

func set_exit_description(new_exit_description: String):
	$MarginContainer/Rows/ExitDescription.text = new_exit_description
	exit_description = new_exit_description

func add_npc(npc: NPC):
	npcs.append(npc)

func remove_npc(npc: NPC):
	npcs.erase(npc)

func add_item(item: Item):
	items.append(item)

func remove_item(item: Item):
	items.erase(item)

func add_enemy(new_enemy: Enemy):
	enemy = new_enemy

func remove_enemy():
	enemy = null

func has_enemy() -> bool:
	return enemy != null

func get_enemy() -> Enemy:
	return enemy

func get_room_description() -> String:
	return room_description

func get_npc_description() -> String:
	if npcs.size() == 0:
		return ""
	var npc_names = npcs.map(func(npc): return npc.npc_name)
	return "You see: " + ", ".join(npc_names)

func get_item_description() -> String:
	if items.size() == 0:
		return ""
	var item_names = items.map(func(item): return item.item_name)
	return "You see: " + ", ".join(item_names)

func get_exit_description() -> String:
	if exits.size() == 0:
		return "There are no exits."
	
	var exit_descriptions = []
	for direction in exits:
		var exit = exits[direction]
		var other_room = exit.get_other_room(self)
		var description = other_room.exit_description.strip_edges()
		if description == "":
			description = other_room.room_name
		var exit_desc = direction + ": " + description
		if exit.is_locked:
			exit_desc += " (" + exit.get_lock_description() + ")"
		exit_descriptions.append(exit_desc)
	
	return "Exits:\n" + "\n".join(exit_descriptions)

func get_full_description() -> String:
	var full_description = PackedStringArray([get_room_description()])
	
	var npc_description = get_npc_description()
	if npc_description != "":
		full_description.append(npc_description)
	
	var item_description = get_item_description()
	if item_description != "":
		full_description.append(item_description)
		
	full_description.append(get_exit_description())
	
	if has_enemy():
		full_description.append("There's a " + enemy.enemy_name + " here!")
	
	var full_description_string = "\n".join(full_description)
	return full_description_string

func reset():
	exits.clear()
	npcs.clear()
	items.clear()
	enemy = null

func connect_exit_unlocked(direction: String, room: GameRoom) -> Exit:
	var exit = Exit.new()
	exit.connect_rooms(self, room)
	exits[direction] = exit
	
	set_reverse_exit(direction, room, exit)

	return exit

func connect_exit_locked(direction: String, room: GameRoom, lock_name: String = "") -> Exit:
	var exit = Exit.new()
	exit.connect_rooms(self, room)
	exit.is_locked = true
	exit.lock_name = lock_name
	exits[direction] = exit
	
	set_reverse_exit(direction, room, exit)

	return exit

func set_reverse_exit(direction: String, room: GameRoom, exit: Exit):
	match direction:
		"north":
			room.exits["south"] = exit
		"south":
			room.exits["north"] = exit
		"east":
			room.exits["west"] = exit
		"west":
			room.exits["east"] = exit
		"path":
			room.exits["path"] = exit
		"inside":
			room.exits["outside"] = exit
		"outside":
			room.exits["inside"] = exit
		"portal":
			room.exits["portal"] = exit
		"room":
			room.exits["adventure"] = exit
		"adventure":
			room.exits["room"] = exit
		"forest":
			room.exits["gate"] = exit
		"gate":
			room.exits["forest"] = exit
		_:
			printerr("Tried to connect invalid direction: %s" % direction)

	return exit


func get_save_data() -> Dictionary:
	return {
		"room_name": room_name,
		"room_description": room_description,
		"exit_description": exit_description,
		"exits": exits.keys(),
		"npcs": npcs.map(func(npc): return npc.npc_name),
		"items": items.map(func(item): return item.item_name),
		"enemy": enemy.enemy_name if enemy else ""  # Changed null to an empty string
	}

func load_save_data(data: Dictionary):
	room_name = data["room_name"]
	room_description = data["room_description"]
	exit_description = data["exit_description"]
	
	npcs.clear()
	for npc_name in data["npcs"]:
		npcs.append(load("res://npcs/" + npc_name + ".tres"))
	
	items.clear()
	for item_name in data["items"]:
		items.append(load("res://items/" + item_name + ".tres"))
	
	if data["enemy"] != "":
		enemy = load("res://enemies/" + data["enemy"] + ".tres")
	else:
		enemy = null
