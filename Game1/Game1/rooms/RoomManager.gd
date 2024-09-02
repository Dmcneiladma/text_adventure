extends Node
class_name RoomManager

var save_load_manager: Node

func _ready() -> void:
	save_load_manager = get_node_or_null("/root/Game/SaveLoadManager")
	if save_load_manager == null:
		push_error("SaveLoadManager node not found!")
		return

	$StartingShed.connect_exit_unlocked("west", $BackOfInn)
	$BackOfInn.connect_exit_unlocked("path", $VillageSquare)
	$VillageSquare.connect_exit_unlocked("east", $InnDoor)
	$VillageSquare.connect_exit_unlocked("north", $Gate)
	$VillageSquare.connect_exit_unlocked("west", $Field)
	
	add_item_to_room("TrainingSword", $Field)

	$InnDoor.connect_exit_unlocked("inside", $InnInside)
	
	var innkeeper = load_npc("InnKeeper")
	$InnInside.add_npc(innkeeper)
	$InnInside.connect_exit_unlocked("south", $InnKitchen)
	$InnInside.connect_exit_unlocked("room", $InnRoom)
	
	var exit = $InnKitchen.connect_exit_locked("south", $BackOfInn)
	var key = load_item("InnKitchenKey")
	key.use_value = exit
	add_item_to_room("InnKitchenKey", $InnKitchen)
	
	exit = $Gate.connect_exit_locked("forest", $Forest, "gate")
	var guard = load_npc("Guard")
	$Gate.add_npc(guard)
	guard.quest_reward = exit

func add_item_to_room(item_name: String, room: Node):
	if save_load_manager == null:
		push_error("SaveLoadManager node not found!")
		return

	var item_path = "res://items/" + item_name + ".tres"
	if item_path not in save_load_manager.picked_up_items:
		var item = load(item_path)
		if item:
			room.add_item(item)

func load_item(item_name: String):
	return load("res://items/" + item_name + ".tres")

func load_npc(npc_name: String):
	return load("res://npcs/" + npc_name + ".tres")
