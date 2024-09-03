extends Node

func _ready() -> void:
	setup_rooms()

func setup_rooms():
	$StartingShed.connect_exit_unlocked("west", $BackOfInn)

	$BackOfInn.connect_exit_unlocked("path", $VillageSquare)

	$VillageSquare.connect_exit_unlocked("east", $InnDoor)
	$VillageSquare.connect_exit_unlocked("north", $Gate)
	$VillageSquare.connect_exit_unlocked("west", $Field)
	
	var sword = load_item("TrainingSword")
	$Field.add_item(sword)

	$InnDoor.connect_exit_unlocked("inside", $InnInside)
	
	var innkeeper = load_npc("InnKeeper")
	$InnInside.add_npc(innkeeper)
	$InnInside.connect_exit_unlocked("south", $InnKitchen)
	$InnInside.connect_exit_unlocked("room", $InnRoom)
	
	var kitchen_exit = $InnKitchen.connect_exit_locked("south", $BackOfInn, "door")
	var key = load_item("InnKitchenKey")
	key.unlocks = kitchen_exit
	$InnKitchen.add_item(key)

	# Set up the gate exit and guard quest
	var gate_exit = $Gate.connect_exit_locked("forest", $Forest, "gate")
	
	var guard_quest_reward = QuestReward.new()
	guard_quest_reward.add_reward(QuestReward.RewardType.UNLOCK_EXIT, gate_exit)
	guard_quest_reward.add_reward(QuestReward.RewardType.GIVE_ITEM, load_item("Longsword"))
	
	var guard = load_npc("Guard")
	guard.quest_item = sword  # Set the quest item to be the training sword
	guard.quest_reward = guard_quest_reward
	$Gate.add_npc(guard)

	# Add an enemy to a room
	var goblin = load_enemy("Goblin")
	$Forest.add_enemy(goblin)

	# Add a healing potion to the Starting Shed
	var healing_potion = load_item("HealingPotion")
	$StartingShed.add_item(healing_potion)

func load_item(item_name: String):
	return load("res://items/" + item_name + ".tres")

func load_npc(npc_name: String):
	return load("res://npcs/" + npc_name + ".tres")

func load_enemy(enemy_name: String):
	return load("res://enemies/" + enemy_name + ".tres")

func reset_rooms():
	for room in get_children():
		room.reset()
	setup_rooms()


func get_save_data() -> Dictionary:
	var rooms_data = {}
	for room in get_children():
		rooms_data[room.name] = room.get_save_data()
	return rooms_data

func load_save_data(data: Dictionary):
	for room_name in data.keys():
		var room = get_node(room_name)
		if room:
			room.load_save_data(data[room_name])
