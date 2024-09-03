extends Resource
class_name Enemy

@export var enemy_name: String = "Enemy"
@export var health: int = 50
@export var max_health: int = 50
@export var damage_dice_type: DiceRoller.DiceType = DiceRoller.DiceType.D6
@export var damage_dice_count: int = 1
@export var damage_modifier: int = 0
@export var defense: int = 2
@export var agility: int = 5
@export var experience_reward: int = 10

@export var inventory: Array[Item] = []

class LootItem:
	var item: Item
	var drop_chance: float  # 0.0 to 1.0

	func _init(item_resource: Item, chance: float):
		item = item_resource
		drop_chance = chance

@export var loot_table_data: Array[String] = []

var loot_table: Array[LootItem] = []

func _init():
	update_loot_table()

func update_loot_table():
	loot_table.clear()
	for entry in loot_table_data:
		var parts = entry.split(",")
		if parts.size() == 2:
			var item_path = parts[0].strip_edges()
			var drop_chance = float(parts[1].strip_edges())
			var item = load(item_path)
			if item:
				loot_table.append(LootItem.new(item, drop_chance))

func take_damage(damage: int):
	var actual_damage = max(damage - defense, 1)
	health -= actual_damage
	if health < 0:
		health = 0
	return actual_damage

func is_alive() -> bool:
	return health > 0

func attack() -> int:
	return DiceRoller.roll(damage_dice_type, damage_dice_count, damage_modifier)

func heal(amount: int):
	health += amount
	if health > max_health:
		health = max_health

func choose_action() -> String:
	var roll = randi() % 100
	if roll < 70:
		return "attack"
	elif roll < 90:
		return "defend"
	else:
		return "use_potion" if has_healing_potion() else "attack"

func has_healing_potion() -> bool:
	return inventory.any(func(item): return item.item_type == Types.ItemTypes.POTION)

func use_healing_potion() -> int:
	for item in inventory:
		if item.item_type == Types.ItemTypes.POTION:
			var heal_amount = item.heal_amount
			inventory.erase(item)
			heal(heal_amount)
			return heal_amount
	return 0

func get_loot() -> Array[Item]:
	var dropped_loot = inventory.duplicate()
	for loot_item in loot_table:
		if randf() <= loot_item.drop_chance:
			dropped_loot.append(loot_item.item)
	inventory.clear()
	return dropped_loot

func defend():
	defense += 2

func get_save_data() -> Dictionary:
	return {
		"enemy_name": enemy_name,
		"health": health,
		"max_health": max_health,
		"damage_dice_type": damage_dice_type,
		"damage_dice_count": damage_dice_count,
		"damage_modifier": damage_modifier,
		"defense": defense,
		"agility": agility,
		"experience_reward": experience_reward,
		"loot_table_data": loot_table_data,
		"inventory": inventory.map(func(item): return item.get_save_data())
	}

func load_save_data(data: Dictionary):
	enemy_name = data["enemy_name"]
	health = data["health"]
	max_health = data["max_health"]
	damage_dice_type = data["damage_dice_type"]
	damage_dice_count = data["damage_dice_count"]
	damage_modifier = data["damage_modifier"]
	defense = data["defense"]
	agility = data["agility"]
	experience_reward = data["experience_reward"]
	loot_table_data = data["loot_table_data"]
	inventory = data["inventory"].map(func(item_data): 
		var item = load("res://items/" + item_data["item_name"] + ".tres")
		item.load_save_data(item_data)
		return item
	)
	update_loot_table()
