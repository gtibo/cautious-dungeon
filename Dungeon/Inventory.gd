extends Node


export(Resource) var item_list
onready var known_items = item_list.known_items
var known_items_dict = {}
func _ready():
	for item in known_items:
		known_items_dict[item.name] = item

var inventory = {}

export(NodePath) var Player_path 
onready var Player = get_node(Player_path)

signal inventory_changed

func addItem(item_data):
	if inventory.has(item_data.name):
		inventory[item_data.name] += 1
	else:
		inventory[item_data.name] = 1
	emit_signal("inventory_changed")

func removeItem(item_name):
	if !inventory.has(item_name):
		return
	inventory[item_name] -= 1
	if inventory[item_name] == 0:
		inventory.erase(item_name)
	emit_signal("inventory_changed")

func use(item_name):
	if !inventory.has(item_name):
		return
	var obj_data = known_items_dict[item_name]
	
	match obj_data.category:
		"Potion":
			Player.heal(20)
			removeItem(item_name)
