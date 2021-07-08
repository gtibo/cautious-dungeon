extends CanvasLayer
var Player
export(NodePath) var inventory_path
onready var inventory = get_node(inventory_path)

func update_health():
	$VBoxContainer/Health.value = Player.health

func _on_Inventory_inventory_changed():
	# This is dumb, but will be fixed later :')
	for child in $VBoxContainer/InventoryList.get_children():
		child.queue_free()
	for key in inventory.inventory:
		var count = inventory.inventory[key]
		var btn = Button.new()
		btn.connect("pressed", inventory, "use",[key])
		btn.text = "%s - %s" % [key, count]
		$VBoxContainer/InventoryList.add_child(btn)
