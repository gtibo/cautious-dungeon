extends State

func enter(_msg := {}) -> void:

	_generate()
# Dungeon Generation step
func _generate():
	owner.init_dungeon()

func _on_Dungeon_finished_generation():
	state_machine.transition_to("PlayerTurn")
