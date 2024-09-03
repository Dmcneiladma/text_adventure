extends Resource
class_name DiceRoller

enum DiceType {
	D4,
	D6,
	D8,
	D10,
	D12,
	D20,
	D100
}

static func roll(dice_type: DiceType, number_of_dice: int = 1, modifier: int = 0) -> int:
	var total = 0
	for i in range(number_of_dice):
		total += randi() % get_dice_sides(dice_type) + 1
	return total + modifier

static func get_dice_sides(dice_type: DiceType) -> int:
	match dice_type:
		DiceType.D4: return 4
		DiceType.D6: return 6
		DiceType.D8: return 8
		DiceType.D10: return 10
		DiceType.D12: return 12
		DiceType.D20: return 20
		DiceType.D100: return 100
		_: return 6  # Default to D6 if an invalid type is provided

static func get_dice_string(dice_type: DiceType, number_of_dice: int = 1, modifier: int = 0) -> String:
	var dice_string = str(number_of_dice) + "d" + str(get_dice_sides(dice_type))
	if modifier != 0:
		dice_string += " + " + str(modifier) if modifier > 0 else " - " + str(abs(modifier))
	return dice_string
