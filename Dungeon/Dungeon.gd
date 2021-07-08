extends Node2D
class_name Dungeon
signal finished_generation

var room_scene = preload("res://Dungeon/Room.tscn")
var ground_object_scene = preload("res://ground_object/ground_object.tscn")
var foe_scene = preload("res://Crawler/Foe/Foe.tscn")
export(Resource) var stairs_resource

# Dungeon
onready var Terrain : TileMap = $Terrain 
onready var Foes = $Foes
onready var Objects = $Objects
# Dungeon floor Setup
var tile_size = 16
var num_rooms = 6
var min_size = 4
var max_size = 8
var path # Path for room connections

export(NodePath) var Player_path 
onready var Player = get_node(Player_path)

export(Resource) var item_list
onready var known_items = item_list.known_items

# Store a reference for every objects present in the dungeon
var objects_on_ground : Dictionary

func _ready():
	Player.connect("health_changed",$UI,"update_health")
	$UI.Player = Player

func init_dungeon():
	randomize()
	objects_on_ground = {}
	for o in $Objects.get_children():
		o.queue_free()
	for f in $Foes.get_children():
		f.queue_free()
	for r in $Rooms.get_children():
		r.queue_free()
	make_rooms()

func build_floor():
	
	select_room()
	carve_terrain()
	Terrain.setup()
	populate()
	emit_signal("finished_generation")

# Destroy item on ground
# Useful if you want to make a crawler pick something
func pick_on_ground(on_ground):
	on_ground.obj.queue_free()
	objects_on_ground.erase(on_ground.key)
# Check for object on ground
# Return null if there is nothing in this position
func look_on_gound(on_position : Vector2):
	var name_str = "%s,%s" % [on_position.x, on_position.y]
	if !objects_on_ground.has(name_str): return null
	return {"key": name_str,"obj":objects_on_ground[name_str]}
	
func get_random_position():
	var is_valid = false
	var result
	while(!is_valid):
		var r = $Rooms.get_child(floor(randf() * $Rooms.get_child_count()))
		var r_x = r.size.x * rand_range(-1, 1) * .4
		var r_y = r.size.y * rand_range(-1, 1) * .4
		var map_position = Terrain.world_to_map(r.position + Vector2(r_x, r_y))
		result = {
			"to_map" : Terrain.world_to_map(r.position + Vector2(r_x, r_y)),
			"to_world" : map_position * Terrain.cell_size,
			"to_string" : "%s,%s" % [map_position.x, map_position.y]
		}
		if !objects_on_ground.has(result.to_string): is_valid = true
	return result

func place_object(object_position, object_data):
	var new_object = ground_object_scene.instance()
	new_object.setup(object_data)
	objects_on_ground[object_position.to_string] = new_object
	new_object.position = object_position.to_world
	$Objects.add_child(new_object)

func make_rooms():
	var radius = num_rooms*tile_size
	for i in range(num_rooms): 
		var a = randf() * PI * 2
		var r_r = randf() * radius
		var pos_x = cos(a) * r_r
		var pos_y = sin(a) * r_r
		var pos = Vector2(pos_x,pos_y)
		var r = room_scene.instance()
		var w = rand_range(min_size,max_size)
		var h = rand_range(min_size,max_size)
		r.make_room(pos,Vector2(w*tile_size,h*tile_size))
		$Rooms.add_child(r)
		r.connect("sleeping_state_changed",self,"room_settle")	

func populate():
	# Place Stairs in the dungeon
	place_object(get_random_position(), stairs_resource)
	# Place Items in the Dungeon
	for i in range(4):
		place_object(get_random_position(), known_items[floor(randf()*known_items.size())])
		
	for i in range(10):
		var foe = foe_scene.instance()
		var foe_start_pos = get_random_position()
		foe.setup(self, foe_start_pos.to_map)
		$Foes.add_child(foe)
	var player_start_pos = get_random_position()
	Player.setup(self, player_start_pos.to_map)
	
func room_settle():
	if check_if_settled(): build_floor()
			
func carve_terrain():
	# Create tilemap from generated rooms and path :)
	Terrain.clear()
	var full_rect = Rect2()
	for room in $Rooms.get_children():
		if room.is_queued_for_deletion(): continue
		var r = Rect2(room.position-room.size,room.size*2)
		full_rect = full_rect.merge(r)
	
	var topleft = Terrain.world_to_map(full_rect.position)
	var bottomright = Terrain.world_to_map(full_rect.end)
	
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			Terrain.set_cell(x, y, 0)
	# Carve rooms :)
	var corridors = []
	for room in $Rooms.get_children():
		if room.is_queued_for_deletion(): continue
		var s = (room.size / tile_size).floor()
		var ul = (room.position / tile_size).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range(2, s.y * 2 - 1):
				Terrain.set_cell(ul.x + x, ul.y + y, 1)
		# Carve corridor :)
		var p = path.get_closest_point(room.position)
		for conn in path.get_point_connections(p):
			if conn in corridors: continue
			var start = Terrain.world_to_map(path.get_point_position(p))
			var end = Terrain.world_to_map(path.get_point_position(conn))
			carve_corridor(start, end)
		corridors.append(p)
	Terrain.update_bitmask_region()

func carve_corridor(start, end):
	var x_diff = sign(end.x - start.x)
	var y_diff = sign(end.y - start.y)
	if x_diff == 0: x_diff = round(randf()) * 2 - 1
	if y_diff == 0: y_diff = round(randf()) * 2 - 1
	
	var x_y = start
	var y_x = end
	if (randi()>0.5):
		x_y = end
		y_x = start
	
	for x in range(start.x, end.x, x_diff):
		Terrain.set_cell(x, x_y.y, 1)
	for y in range(start.y, end.y, y_diff):
		Terrain.set_cell(y_x.x, y, 1)
	
func select_room():
	var mean_w = 0
	var mean_h = 0
	for r in $Rooms.get_children():
		mean_w += r.size.x
		mean_h += r.size.y
	mean_w /= $Rooms.get_child_count() 
	mean_h /= $Rooms.get_child_count()
	var room_positions = []
	for r in $Rooms.get_children():
		if (r.size.x < mean_w  && r.size.y < mean_h):
			r.queue_free()
			$Rooms.remove_child(r)
		else:
			r.call_deferred("set","mode",RigidBody2D.MODE_STATIC)
			room_positions.append(r.position)
	# Delaunay
	var triangles = Geometry.triangulate_delaunay_2d(room_positions)
	var coordinates = []
	for i in range(0, triangles.size(), 3):
	  coordinates.append([
		room_positions[triangles[i]],
		room_positions[triangles[i + 1]],
		room_positions[triangles[i + 2]]
	  ])

	# Minimum spanning tree :)
	path = find_mst(room_positions)
	# But now the dungeon is linear :(
	# But we also want the dungeon to loop 
	for i in range(0, triangles.size(), 3):
		for side in range(0,3):
			if randf() > 0.3: continue
			var v0 = triangles[i + side]
			var v1 = triangles[i+ (side + 1) % 3]
			#print(i + side, " ", i+ (side + 1)% 3 )
			var p0 = room_positions[v0]
			var p1 = room_positions[v1]
			# Skip if already connected :)
			#if path.are_points_connected(v0,v1): continue
			var closest_v0 = path.get_closest_point(p0)
			var closest_v1 = path.get_closest_point(p1)
			path.connect_points(closest_v0,closest_v1)

func find_mst(positions):
	positions = positions.duplicate()
	var new_path = AStar2D.new()
	new_path.add_point(new_path.get_available_point_id(), positions.pop_front())
	while positions:
		var min_dist = INF # Minimum distance so far
		var min_p = null # Position of that node
		var p = null
		for p1 in new_path.get_points():
			p1 = new_path.get_point_position(p1)
			for p2 in positions:
				if p1.distance_to(p2) < min_dist:
					min_dist = p1.distance_to(p2)
					min_p = p2
					p = p1
		var n = new_path.get_available_point_id()
		new_path.add_point(n,min_p)
		new_path.connect_points(new_path.get_closest_point(p),n)
		positions.erase(min_p)
	return new_path

func check_if_settled():
	for r in $Rooms.get_children():
		if !r.sleeping: return false
	return true
