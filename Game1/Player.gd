extends Node

var inventory: Array = []
var health: int = 100
var max_health: int = 100
var equipped_weapon: Item = null
var defense: int = 0
var experience: int = 0
var level: int = 1

func take_item(item: Item):
	inventory.append(item)
	if item.item_type == Types.ItemTypes.WEAPON and equipped_weapon == null:
		equip_weapon(item)

func drop_item(item: Item):
	inventory.erase(item)
	if item == equipped_weapon:
		equipped_weapon = null

func get_inventory_list() -> String:
	if inventory.size() == 0:
		return "You don't have anything!"
	
	var item_string = ""
	for item in inventory:
		item_string += item.item_name + " "
	return "Inventory: " + item_string

func reset():
	inventory.clear()
	health = max_health
	equipped_weapon = null
	defense = 0

func equip_weapon(weapon: Item):
	if weapon.item_type == Types.ItemTypes.WEAPON:
		equipped_weapon = weapon
		return "You equipped " + weapon.item_name
	return "You can't equip that."

func attack() -> int:
	return equipped_weapon.damage if equipped_weapon else 1

func take_damage(damage: int) -> int:
	var actual_damage = max(damage - defense, 0)
	health -= actual_damage
	if health < 0:
		health = 0
	defense = 0  # Reset defense after taking damage
	return actual_damage

func defend():
	defense += 5

func use_potion(potion: Item) -> int:
	if potion.item_type != Types.ItemTypes.POTION:
		return 0
	var heal_amount = min(potion.heal_amount, max_health - health)
	health += heal_amount
	inventory.erase(potion)
	return heal_amount

func gain_experience(amount: int):
	experience += amount
	check_level_up()

func check_level_up():
	var experience_needed = level * 100  # Simple level up formula
	if experience >= experience_needed:
		level_up()

func level_up():
	level += 1
	max_health += 10
	health = max_health
	# You can add more stat increases here
	print("Congratulations! You've reached level " + str(level))

func is_alive() -> bool:
	return health > 0
