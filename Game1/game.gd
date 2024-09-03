extends Control

const Response = preload("res://input/response.tscn")
const InputResponse = preload("res://input/InputResponse.tscn")
const ReplayManager = preload("res://ReplayManager.gd")
const CombatManager = preload("res://CombatManager.gd")

@export var max_lines_remembered := 30

@onready var command_processor = %CommandProcessor
@onready var history_rows = %HistoryRows
@onready var scroll = %Scroll
@onready var scrollbar = scroll.get_v_scroll_bar()
@onready var room_manager = $RoomManager
@onready var player = $Player

var replay_manager = ReplayManager.new()
var in_combat: bool = false

func _ready() -> void:
	if not command_processor or not history_rows or not scroll or not scrollbar or not room_manager or not player:
		push_error("One or more required nodes are not found")
		return

	scrollbar.changed.connect(Callable(self, "handle_scrollbar_changed"))
	replay_manager.connect("replay_input", Callable(self, "_on_replay_input"))
	replay_manager.connect("reset_game", Callable(self, "_on_reset_game"))
	
	replay_manager.initialize(command_processor)
	
	command_processor.combat_manager.connect("combat_state_changed", Callable(self, "_on_combat_state_changed"))
	command_processor.combat_manager.connect("combat_ended", Callable(self, "_on_combat_ended"))
	
	initialize_game()

func handle_scrollbar_changed():
	scroll.scroll_vertical = scrollbar.max_value

func _on_input_text_submitted(new_text: String) -> void:
	if new_text.is_empty():
		return

	var input_response = InputResponse.instantiate()
	var response = command_processor.process_command(new_text)
	
	input_response.set_text(new_text, response)
	add_response_to_game(input_response)

	if not command_processor.combat_manager.is_combat_active():
		# Save successful input only when not in combat
		replay_manager.add_input(new_text)

func create_response(response_text: String):
	var response = Response.instantiate()
	response.text = response_text
	add_response_to_game(response)

func add_response_to_game(response: Control):
	history_rows.add_child(response)
	delete_history_beyond_limit()

func delete_history_beyond_limit():
	if history_rows.get_child_count() > max_lines_remembered:
		var rows_to_forget = history_rows.get_child_count() - max_lines_remembered
		for i in range(rows_to_forget):
			history_rows.get_child(i).queue_free()

func _on_replay_input(input: String, response: String):
	create_response(" > " + input)
	create_response(response)

func _on_reset_game():
	initialize_game()

func initialize_game():
	# Clear history rows
	for child in history_rows.get_children():
		child.queue_free()
	
	# Reset player state
	player.reset()

	# Reset room states
	room_manager.reset_rooms()

	# Initialize game
	create_response("Welcome to the retro text adventure! You can type 'help' to see available commands.")
	var starting_room_response = command_processor.initialize(room_manager.get_node("StartingShed"), player, replay_manager)
	create_response(starting_room_response)

func _on_combat_state_changed(state, message):
	match state:
		CombatManager.CombatState.PLAYER_TURN:
			if message:
				create_response(message)
		CombatManager.CombatState.ENEMY_TURN:
			if message:
				create_response(message)
		CombatManager.CombatState.ENDED:
			in_combat = false
			create_response(message)

func _on_combat_ended(result):
	match result:
		"escape":
			var previous_room = command_processor.combat_manager.previous_room
			var response = command_processor.change_room(previous_room)
			create_response("You escaped back to " + previous_room.room_name + ".")
			create_response(response)
		"victory":
			var enemy = command_processor.combat_manager.enemy
			player.gain_experience(enemy.experience_reward)
			var loot = enemy.get_loot()
			for item in loot:
				command_processor.current_room.add_item(item)
				create_response("The " + enemy.enemy_name + " dropped: " + item.item_name)
			command_processor.current_room.remove_enemy()
			create_response("You defeated the " + enemy.enemy_name + "!")
		"defeat":
			create_response("Game Over! You have been defeated.")
			# Implement game over logic here (e.g., restart game or load last save)


func save_game():
	var save_data = {
		"command_processor": command_processor.get_save_data(),
		"player": player.get_save_data(),
		"room_manager": room_manager.get_save_data()
	}
	var file = FileAccess.open("user://save_game.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		create_response("Game saved successfully.")
	else:
		push_error("Failed to open save file for writing")
		create_response("Failed to save the game.")

func load_game():
	var file = FileAccess.open("user://save_game.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		room_manager.load_save_data(save_data["room_manager"])
		player.load_save_data(save_data["player"])
		command_processor.load_save_data(save_data["command_processor"], room_manager)
		create_response("Game loaded successfully.")
		create_response(command_processor.current_room.get_full_description())
	else:
		push_error("Failed to open save file for reading")
		create_response("Failed to load the game.")
