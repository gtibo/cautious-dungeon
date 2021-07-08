extends RigidBody2D
var size
func make_room(_pos,_size):
	position = _pos
	size = _size
	var s = RectangleShape2D.new()
	s.extents = size
	s.custom_solver_bias = 1
	$CollisionShape2D.shape = s
	
func _integrate_forces(state):
	rotation = 0
	state.transform = transform
