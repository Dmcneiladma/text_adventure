extends Resource
class_name Exit

@export var is_locked: bool = false
@export var lock_name: String = ""  # Name of the lock, e.g., "gate", "door"
var room1: GameRoom = null
var room2: GameRoom = null

func connect_rooms(from_room: GameRoom, to_room: GameRoom):
	room1 = from_room
	room2 = to_room

func get_other_room(current_room: GameRoom) -> GameRoom:
	if current_room == room1:
		return room2
	elif current_room == room2:
		return room1
	else:
		push_error("Tried to get other room from an unconnected room")
		return null

func lock():
	is_locked = true

func unlock():
	is_locked = false

func is_passable() -> bool:
	return not is_locked

func get_lock_description() -> String:
	if is_locked and lock_name != "":
		return "The " + lock_name + " is locked."
	elif is_locked:
		return "It's locked."
	return ""
