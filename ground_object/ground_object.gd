extends Sprite
var data

func setup(item_data):
	data = item_data
func _ready():
	texture = data.icon
