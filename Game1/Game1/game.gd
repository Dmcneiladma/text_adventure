extends Control

const Response = preload("res://input/response.tscn")
const InputResponse = preload("res://input/InputResponse.tscn")
const ReplayManager = preload("res://ReplayManager.gd")

@export var max_lines_remembered := 30

@onready var command_processor = %CommandProcessor
@onready var history_rows = %HistoryRows
@onready var scroll = %Scroll
@onready var scrollbar = scroll.get_v_scroll_bar()
@onready var room_manager = $RoomManager  # Make sure this path is correct
@onready var player = $Player

var replay_manager = ReplayManager.new()

func _ready() -> void:
	if not command_processor or not history_rows or not scroll or not scrollbar or not room_manager or not player:
		push_error("One or more required nodes are not found")
		return

	scrollbar.changed.connect(Callable(self, "handle_scrollbar_changed"))
	replay_manager.connect("replay_input", Callable(self, "_on_replay_input"))
	replay_manager.connect("reset_game", Callable(self, "_on_reset_game"))
	
	replay_manager.initialize(command_processor)
	
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

	# Save successful input
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
