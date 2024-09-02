extends Resource
class_name Enemy

@export var enemy_name: String = "Enemy"
@export var health: int = 50
@export var max_health: int = 50
@export var damage: int = 5
@export var defense: int = 2
@export var agility: int = 5
@export var experience_reward: int = 10

class LootItem:
	var item: Item
	var drop_chance: float  # 0.0 to 1.0

	func _init(item_resource: Item, chance: float):
		item = item_resource
		drop_chance = chance

# We'll use an array of strings to store the loot table data
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
	return damage

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
		return "heal"

func get_loot() -> Array[Item]:
	var dropped_loot: Array[Item] = []
	for loot_item in loot_table:
		if randf() <= loot_item.drop_chance:
			dropped_loot.append(loot_item.item)
	return dropped_loot
