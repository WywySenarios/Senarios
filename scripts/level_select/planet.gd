extends Node2D

@export var attributes : celestial_body = celestial_body.new()
var doubleclicking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.sprite_frames = attributes.idle_animation
	$Sprite.scale = attributes.size / attributes.idle_animation.get_frame_texture("default", 0).get_size()
	
	$Button.size = attributes.size
	
	#$Sprite.sprite_frames = attributes.image
	#$Sprite.scale = attributes.size / attributes.image.get_size()
	
	
	$Button.position = -attributes.size * 0.5
	
	add_to_group("celestial bodies")
	add_to_group("planets")


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func is_in_view(camera_pos, camera_view_size):
	var pos_difference = position - camera_pos
	if ((abs(pos_difference.x) > camera_view_size.x + attributes.size.x / 2) || (abs(pos_difference.y) > camera_view_size.y + attributes.size.y / 2)):
		hide()
	else:
		show()
	#print(position - camera_pos)


func _on_timer_timeout():
	doubleclicking = false

func _on_button_button_down():
	if doubleclicking:
		get_parent().focus(self)
	else:
		doubleclicking = true
		# 500ms delay max to be considered a double-click (standard for windows computers)
		$Timer.start(0.5)
