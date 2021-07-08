extends Node2D
class_name Crawler

var terrain_position: Vector2
# As a reference to the terrain
var dungeon
var Terrain : TileMap
var displayed_name = "Crawler"
var max_health = 100
var health = max_health

signal died
signal health_changed

func setup(_dungeon, _position):
	dungeon = _dungeon
	Terrain = dungeon.Terrain
	terrain_position = _position
	position = terrain_position * Terrain.cell_size

func move(to_position : Vector2):
	$AnimationPlayer.play("Walk")
	terrain_position = to_position
	position = to_position * Terrain.cell_size

func hurt(amount):
	$AnimationPlayer.play("Hurt")
	health -= amount
	emit_signal("health_changed")
	if health <= 0: 
		emit_signal("died")
		queue_free()

func heal(amount):
	health += amount
	emit_signal("health_changed")
	if health > max_health: health = max_health
