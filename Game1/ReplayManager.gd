extends Node

var command_processor = null
var input_history: Array = []
var is_replaying = false

func initialize(cmd_processor):
	if cmd_processor == null:
		push_error("Command processor cannot be null")
		return
	self.command_processor = cmd_processor

func save_game():
	var file = FileAccess.open("user://save_game.save", FileAccess.WRITE)
	if file:
		file.store_var(input_history)
		file.close()
	else:
		push_error("Failed to open save file for writing")

func load_game():
	var file = FileAccess.open("user://save_game.save", FileAccess.READ)
	if file:
		input_history = file.get_var()
		file.close()
		reset_game_state()
		replay_inputs()
	else:
		push_error("Failed to open save file for reading")

func add_input(input: String):
	if not is_replaying:
		input_history.append(input)
		save_game()

func replay_inputs():
	is_replaying = true
	for input in input_history:
		if input.strip_edges().to_lower() in ["save", "load"]:
			continue
		var response = command_processor.process_command(input)
		emit_signal("replay_input", input, response)
	is_replaying = false

func reset_game_state():
	emit_signal("reset_game")

signal replay_input(input: String, response: String)
signal reset_game()
