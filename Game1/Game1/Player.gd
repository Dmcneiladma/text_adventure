extends Node

var inventory: Array = []
@onready var game = get_node("/root/Game")

func take_item(item: Item):
	inventory.append(item)


func drop_item(item: Item):
	inventory.erase(item)


func get_inventory_list( ) -> String:
	if inventory.size() == 0:
		return "You don't have anything!."
	
	var item_string = ""
	for item in inventory:
		item_string += item.item_name + " "
	return "Inventory: " + item_string
