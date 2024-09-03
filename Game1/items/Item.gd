extends Resource
class_name Item

@export var item_name: String = "Item"
@export var item_type: Types.ItemTypes
@export var use_value_string: String = ""

# For weapons
@export var damage_dice_type: DiceRoller.DiceType = DiceRoller.DiceType.D6
@export var damage_dice_count: int = 1
@export var damage_modifier: int = 0

# For potions
@export var heal_amount: int = 0

# For keys
@export var unlocks: Resource  # This will be an Exit resource

var use_value: Variant

func _init():
	update_use_value()

func update_use_value():
	match item_type:
		Types.ItemTypes.CONSUMABLE:
			use_value = use_value_string
		Types.ItemTypes.KEY:
			use_value = unlocks
		_:
			use_value = null

func get_damage_string() -> String:
	if item_type == Types.ItemTypes.WEAPON:
		return DiceRoller.get_dice_string(damage_dice_type, damage_dice_count, damage_modifier)
	return "0"

func roll_damage() -> int:
	if item_type == Types.ItemTypes.WEAPON:
		return DiceRoller.roll(damage_dice_type, damage_dice_count, damage_modifier)
	return 0
