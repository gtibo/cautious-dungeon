extends Crawler

var wished_position : Vector2
var held_item = null

func _ready():
	displayed_name = "Foe"
	# Disable cell on which the foe stands
	Terrain._set_state(terrain_position, false)
	connect("died",self,"on_death")

func on_death():
	Terrain._set_state(terrain_position, true)

func decide_move():
	# Decide what to do here
	# Use held item or move ?
	if(held_item && health <= 30 && held_item.category == "Potion"):
		# Heal itselfs if carrying a potion and health is low
		heal(20)
		held_item = null
	else:
		compute_move()

func compute_move():
	Terrain._set_state(terrain_position, true)
	wished_position = terrain_position
	var player_pos_to_map = Terrain.world_to_map(dungeon.Player.position)
	var path_finding = Terrain._get_path(
		terrain_position,
		player_pos_to_map)
	Terrain._set_state(terrain_position, false)
	if path_finding.size() <= 1: return
	var next_tile = path_finding[1]
	if next_tile == dungeon.Player.terrain_position: 
		dungeon.Player.hurt(10)
		return
	wished_position = next_tile
	
func check_move():
	if wished_position == terrain_position : return true
	for other_foe in dungeon.Foes.get_children():
		if other_foe == self: continue
		# If another foe want to move where i wish to move, I stay in place
		if other_foe.wished_position == wished_position:
			wished_position = terrain_position
			return false
	return true
