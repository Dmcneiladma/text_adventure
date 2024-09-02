extends Node

var player
var enemy
var is_player_turn: bool = true
var combat_active: bool = false

func start_combat(player_ref, enemy_ref):
	player = player_ref
	enemy = enemy_ref
	is_player_turn = true
	combat_active = true
	return "Combat started with " + enemy.enemy_name + "!"

func player_action(action: String) -> String:
	if not combat_active:
		return "There's no active combat."

	if not is_player_turn:
		return "It's not your turn!"

	var result = ""
	match action:
		"attack":
			var damage = player.attack()
			var actual_damage = enemy.take_damage(damage)
			result = "You attack the " + enemy.enemy_name + " for " + str(actual_damage) + " damage."
		"defend":
			player.defend()
			result = "You take a defensive stance."
		_:
			return "Invalid action. Choose 'attack' or 'defend'."

	if not enemy.is_alive():
		combat_active = false
		var loot = enemy.get_loot()
		var loot_message = handle_loot(loot)
		player.gain_experience(enemy.experience_reward)
		return result + " The " + enemy.enemy_name + " has been defeated!\n" + loot_message

	is_player_turn = false
	return result + "\n" + enemy_turn()

func handle_loot(loot: Array[Item]) -> String:
	if loot.is_empty():
		return "The enemy dropped nothing."
	
	var loot_message = "The enemy dropped: "
	for item in loot:
		player.take_item(item)
		loot_message += item.item_name + ", "
	
	return loot_message.trim_suffix(", ")

func player_used_item():
	is_player_turn = false
	enemy_turn()

func enemy_turn() -> String:
	if not combat_active:
		return "There's no active combat."

	var action = enemy.choose_action()
	var result = ""

	match action:
		"attack":
			var damage = enemy.attack()
			var actual_damage = player.take_damage(damage)
			result = enemy.enemy_name + " attacks you for " + str(actual_damage) + " damage."
		"defend":
			enemy.defense += 2
			result = enemy.enemy_name + " takes a defensive stance."
		"heal":
			var heal_amount = min(10, enemy.max_health - enemy.health)
			enemy.heal(heal_amount)
			result = enemy.enemy_name + " heals for " + str(heal_amount) + " health."

	if not player.is_alive():
		combat_active = false
		return result + " You have been defeated!"

	is_player_turn = true
	return result

func get_combat_status() -> String:
	if not combat_active:
		return "No active combat."
	return "Player Health: " + str(player.health) + "/" + str(player.max_health) + "\n" + \
		   enemy.enemy_name + " Health: " + str(enemy.health) + "/" + str(enemy.max_health)

func is_combat_over() -> bool:
	return not combat_active

func end_combat():
	combat_active = false
	enemy = null
