extends Camera2D

var dragging = false
var screen_size = get_viewport_rect().size
var start_pos = position
var start_mouse_pos = Vector2.ZERO
var end_mouse_pos = Vector2.ZERO

func _ready():
		pass
		#reprocess_screen_size()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#end_mouse_pos = get_global_mouse_position()
	#
	#if dragging:
		#if Input.is_action_just_released("click"):
			#dragging = false
			#print("start: " + str(start_mouse_pos) + "\nend: " + str(end_mouse_pos) + "\n")
	#elif Input.is_action_just_pressed("click"):
		#if (start_mouse_pos == Vector2.ZERO):
			#start_mouse_pos = get_global_mouse_position()
			#start_pos = position
		#dragging = true
		#
	#if not (start_pos - position).is_equal_approx(start_mouse_pos - end_mouse_pos):
		#position.move_toward(start_pos + (start_mouse_pos - end_mouse_pos), delta*100)
		#print(position)
	#else:
		#start_pos = Vector2.ZERO
		#start_mouse_pos = Vector2.ZERO
