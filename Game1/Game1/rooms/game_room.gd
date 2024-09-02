@tool
extends PanelContainer
class_name GameRoom


@export var room_name : String = "Room Name" : set = set_room_name
@export_multiline var room_description : String = "This is the description." : set = set_room_description

var exits: Dictionary = {}
var npcs : Array = []
var items: Array = []


func set_room_name(new_name: String):
	$MarginContainer/Rows/RoomName.text = new_name
	room_name = new_name


func set_room_description(new_descrtiption: String):
	$MarginContainer/Rows/RoomDescription.text = new_descrtiption
	room_description = new_descrtiption


func add_npc(npc: NPC):
	npcs.append(npc)

func remove_npc(npc: NPC):
	npcs.erase(npc)


func add_item(item: Item):
	items.append(item)

func remove_item(item: Item):
	items.erase(item)


func get_full_description() -> String:
	var full_description = PackedStringArray([get_room_description()])
	
	var npc_description = get_npc_description()
	if npc_description != "":
		full_description.append(npc_description)
	
	var item_description = get_item_description()
	if item_description != "":
		full_description.append(item_description)
		
	full_description.append(get_exit_description())
	
	var full_description_string = "\n".join(full_description)
	return full_description_string


func get_room_description() -> String:
	return "You are now in: " + room_name + ". It is " + room_description + ". "


func get_npc_description() -> String:
	if npcs.size() == 0:
		return ""
	
	var npc_string = ""
	for npc in npcs:
		npc_string += npc.npc_name + " "
	return "NPCs: " + npc_string


func get_item_description() -> String:
	if items.size() == 0:
		return ""
	
	var item_string = ""
	for item in items:
		item_string += item.item_name + " "
	return "Items: " + item_string


func get_exit_description() -> String:
	return "Exits: " + ", ".join(PackedStringArray(exits.keys()))


func connect_exit_unlocked(direction: String, room, room_2_override_name = "null"):
	return _connect_exit(direction, room, false,room_2_override_name)


func connect_exit_locked(direction: String, room, room_2_override_name = "null"):
	return _connect_exit(direction, room, true,room_2_override_name)


func _connect_exit(direction: String, room: GameRoom, is_locked: bool = false, room_2_override_name = "null"):
	var exit = Exit.new()
	exit.room_1 = self
	exit.room_2 = room
	exit.is_locked = is_locked
	exits[direction] = exit
	
	if room_2_override_name != "null":
		room.exits[room_2_override_name] = exit
	else:
		match direction:
			"west":
				room.exits["east"] = exit
			"east":
				room.exits["west"] = exit
			"north":
				room.exits["south"] = exit
			"south":
				room.exits["north"] = exit
			"path":
				room.exits["path"] = exit
			"inside":
				room.exits["outside"] = exit
			"outside":
				room.exits["intside"] = exit
			"portal":
				room.exits["portal"] = exit
			"room":
				room.exits["adventure"] = exit
			"adventure":
				room.exits["room"] = exit
			_:
				printerr("Tried to connect invalid direction: %s" % direction)

	return exit


func reset():
	exits.clear()
	npcs.clear()
	items.clear()
