extends Resource
class_name NPC


@export var npc_name = "NPC Name"

@export_multiline var initial_dialog : String
@export_multiline var post_quest_dialog : String

@export var quest_item : Item

var has_received_quest_item := false
