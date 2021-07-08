extends State

var Player
var Foes
var Terrain

export(NodePath) var inventory_path
onready var inventory = get_node(inventory_path)

func enter(_msg := {}) -> void:
	Foes = owner.Foes
	Terrain = owner.Terrain
	Player = owner.Player

func handle_input(_event: InputEvent) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_just_pressed("ui_down"): dir = Vector2(0,1)
	if Input.is_action_just_pressed("ui_up"): dir = Vector2(0,-1)
	if Input.is_action_just_pressed("ui_right"): dir = Vector2(1,0)
	if Input.is_action_just_pressed("ui_left"): dir = Vector2(-1,0)
	if dir == Vector2.ZERO: return
	var next_position = Player.terrain_position + dir
	# Don't account input if next position is a wall
	if Terrain.get_cellv(next_position) == 0: return
	var is_there_a_foe = check_for_foe(next_position)
	var exit = false
	if is_there_a_foe:
		# Attack this foe
		is_there_a_foe.hurt(50)
	else:
		# Just move
		Player.move(next_position)
		exit = check_ground()
	
	if !exit : state_machine.transition_to("FoeTurn")
	
func check_ground():
	var on_ground = owner.look_on_gound(Player.terrain_position)
	if !on_ground: return
	var obj_data = on_ground.obj.data
	match obj_data.type:
		"ground_object":
			if obj_data.name == "stairs":
				state_machine.transition_to("Idle")
				return true
		"item":
			inventory.addItem(obj_data)
			owner.pick_on_ground(on_ground)

func check_for_foe(at_position):
	for foe in Foes.get_children():
		if at_position == foe.terrain_position:
			return foe
	return null
