extends State

var Player
var Foes
var Terrain

func enter(_msg := {}) -> void:
	Foes = owner.Foes
	Terrain = owner.Terrain
	Player = owner.Player
	move_foes()
	state_machine.transition_to("PlayerTurn")

func move_foes():
	
	var active_foes = []
	
	for foe in Foes.get_children():
		if foe.is_queued_for_deletion(): continue
		active_foes.append(foe)
	
	for foe in active_foes:
		foe.decide_move()
	var all_settled = false
	while(!all_settled):
		all_settled = true
		for foe in active_foes:
			var settled = foe.check_move()
			if !settled : all_settled = false
	for foe in active_foes:
		if foe.terrain_position != foe.wished_position:
			Terrain._set_state(foe.terrain_position, true)
			foe.move(foe.wished_position)
			Terrain._set_state(foe.terrain_position, false)
		# check ground if nothing is held
		if foe.held_item == null:
			var obj_on_ground = owner.look_on_gound(foe.terrain_position)
			if obj_on_ground && obj_on_ground.obj.data.type == "item":
				foe.held_item = obj_on_ground.obj.data
				owner.pick_on_ground(obj_on_ground)
