extends Node

signal combat_state_changed(state, message)
signal combat_ended(result)

enum CombatState {INACTIVE, PLAYER_TURN, ENEMY_TURN, ENDED}

var player
var enemy
var current_state: CombatState = CombatState.INACTIVE
var turn_count: int = 0
var previous_room: GameRoom = null

func start_combat(player_ref, enemy_ref, prev_room: GameRoom):
	player = player_ref
	enemy = enemy_ref
	previous_room = prev_room
	current_state = CombatState.PLAYER_TURN
	turn_count = 0
	emit_signal("combat_state_changed", current_state, "Combat started with " + enemy.enemy_name + "!\n\n" + get_combat_status() + "\n\nWhat will you do?")

func process_action(action: String) -> String:
	match current_state:
		CombatState.PLAYER_TURN:
			var player_result = process_player_action(action)
			if current_state == CombatState.ENEMY_TURN:
				var enemy_result = process_enemy_turn()
				return player_result + "\n\n" + enemy_result
			return player_result
		CombatState.ENEMY_TURN:
			return process_enemy_turn()
		_:
			return "No active combat."

func process_player_action(action: String) -> String:
	var result = ""
	match action:
		"attack":
			result = perform_attack(player, enemy)
		"defend":
			result = perform_defend(player)
		"use_item":
			result = "Item use not implemented yet."
		"escape":
			result = attempt_escape(player)
		_:
			return "Invalid action. Choose 'attack', 'defend', 'use_item', or 'escape'."

	if not enemy.is_alive():
		change_state(CombatState.ENDED, "victory")
		emit_signal("combat_ended", "victory")
		return result + "\n\nYou have defeated the " + enemy.enemy_name + "!"

	change_state(CombatState.ENEMY_TURN)
	return result + "\n\n" + get_combat_status()

func process_enemy_turn() -> String:
	var action = enemy.choose_action()
	var result = enemy.enemy_name + "'s turn: "

	match action:
		"attack":
			result += perform_attack(enemy, player)
		"defend":
			result += perform_defend(enemy)
		"use_potion":
			result += perform_heal(enemy)

	if not player.is_alive():
		change_state(CombatState.ENDED, "defeat")
		emit_signal("combat_ended", "defeat")
		return result + "\n\nYou have been defeated!"

	change_state(CombatState.PLAYER_TURN)
	turn_count += 1
	return result + "\n\n" + get_combat_status() + "\n\nWhat will you do?"

func perform_attack(attacker, defender) -> String:
	var damage = attacker.attack()
	var actual_damage = defender.take_damage(damage)
	var attack_string = attacker.enemy_name + " attacks " + defender.enemy_name
	
	if attacker == player and player.equipped_weapon:
		attack_string += " with " + player.equipped_weapon.item_name + " (" + player.equipped_weapon.get_damage_string() + ")"
	elif attacker == enemy:
		attack_string += " (" + DiceRoller.get_dice_string(enemy.damage_dice_type, enemy.damage_dice_count, enemy.damage_modifier) + ")"
	
	attack_string += " for " + str(actual_damage) + " damage."
	return attack_string

func perform_defend(character) -> String:
	character.defend()
	return character.enemy_name + " takes a defensive stance."

func perform_heal(character) -> String:
	var heal_amount = character.use_healing_potion()
	return character.enemy_name + " uses a healing potion and recovers " + str(heal_amount) + " health."

func attempt_escape(character) -> String:
	var escape_chance = 0.3 + (0.1 * turn_count)  # Escape chance increases each turn
	if randf() < escape_chance:
		change_state(CombatState.ENDED, "escape")
		emit_signal("combat_ended", "escape")
		return character.enemy_name + " successfully escaped from combat!"
	else:
		return character.enemy_name + " failed to escape!"

func get_combat_status() -> String:
	if current_state == CombatState.INACTIVE:
		return "No active combat."
	return "Combat Status:\n" + \
		   "Player Health: " + str(player.health) + "/" + str(player.max_health) + "\n" + \
		   enemy.enemy_name + " Health: " + str(enemy.health) + "/" + str(enemy.max_health)

func change_state(new_state: CombatState, result: String = ""):
	current_state = new_state
	emit_signal("combat_state_changed", current_state, result)

func is_combat_active() -> bool:
	return current_state != CombatState.INACTIVE and current_state != CombatState.ENDED

func get_save_data() -> Dictionary:
	return {
		"current_state": current_state,
		"turn_count": turn_count,
		"previous_room": previous_room.room_name if previous_room else "",
		"enemy": enemy.get_save_data() if enemy else null
	}

func load_save_data(data: Dictionary, room_manager: Node):
	current_state = data["current_state"]
	turn_count = data["turn_count"]
	previous_room = room_manager.get_node(data["previous_room"]) if data["previous_room"] != "" else null
	if data["enemy"]:
		enemy = load("res://enemies/" + data["enemy"]["enemy_name"] + ".tres")
		enemy.load_save_data(data["enemy"])
