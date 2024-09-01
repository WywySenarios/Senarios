extends CharacterBody2D

@export var focus_time : float = 500 / 1000 # animation time to focus in s
@export var KEYSPEED : int = 250
@export var zoom_factor : float = 1.0

# maybe 0.01 is better?
@export var movement_deadzone : float = 0.05 # percentage of screen size

var screen_size

var dragging = false
var moving_time = 0
var mouse_prev_pos
var deadzone_length

var zoom_velocity
var zooming_time = 0
var zoom_target

var focused = false

signal zoom(factor)
signal screen_size_update()
signal update_activity(pos, max_distance)

func _ready():
	reprocess_screen_size()

func reprocess_screen_size():
	screen_size = $Camera.get_viewport_rect().size
	$HUD.reprocess_screen_size(screen_size)
	
	# rescale backgrounds to fit
	screen_size_update.emit()
	deadzone_length = screen_size.length() * (movement_deadzone / 100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if zooming_time > 0:
		change_zoom(zoom_velocity * delta)
		zooming_time -= delta
		
		if (zooming_time <= 0):
			set_zoom(zoom_target)
	elif Input.is_action_just_released("scroll_up"):
		change_zoom(1)
		# update valid nodes
		get_parent().view_changed()
	elif Input.is_action_just_released("scroll_down"):
		change_zoom(-1)
		# update valid nodes
		get_parent().view_changed()
	
	# dragging code
	if moving_time > 0:
		moving_time -= delta
		move_and_slide()
		
		if (moving_time < 0): # correct for overshoots & end mvoement
			position += velocity * moving_time
			# update valid nodes
			get_parent().view_changed()
	elif Input.is_action_just_pressed("click"):
		velocity = Vector2.ZERO
		#mouse_pos_difference += position - (get_global_mouse_position() - screen_size * 0.5)
		mouse_prev_pos = position - get_global_mouse_position()
		dragging = true
	elif dragging:
		# change = final - initial
		var pos_diff = (position - get_global_mouse_position() - mouse_prev_pos)
		if pos_diff.length() > deadzone_length:
			# IDK why the *0.5 works (I know it cancels out some weird toggling between two positions thing but IDK why 0.5 precisely makes the dragging not janky ("smooth")
			position += pos_diff * 0.5
			unfocus()
		
		mouse_prev_pos = position - get_global_mouse_position()
		
		if Input.is_action_just_released("click"):
			dragging = false
			#print("start: " + str(start_mouse_pos) + "\nend: " + str(end_mouse_pos) + "\n")
	else:
		velocity = Vector2.ZERO
		
		# START - keyboard code
		if Input.is_anything_pressed():
			if Input.is_action_pressed("up"):
				velocity.y = -KEYSPEED
			
			if Input.is_action_pressed("down"):
				velocity.y = KEYSPEED
			
			if Input.is_action_pressed("right"):
				velocity.x = KEYSPEED
				
			if Input.is_action_pressed("left"):
				velocity.x = -KEYSPEED
		
		if (velocity != Vector2.ZERO):
			move_and_slide()
			
			unfocus() # update HUD
			get_parent().view_changed() # update valid nodes
		# END - keyboard code

func slide_to(pos):
	moving_time = focus_time
	velocity = (pos - position)
	velocity /= moving_time
	
func zoom_to(target_scroll_factor):
	zoom_target = target_scroll_factor
	zooming_time = focus_time
	zoom_velocity = target_scroll_factor - zoom_factor
	zoom_velocity /= zooming_time

func change_zoom(factor):
	zoom_factor += factor
	$Camera.zoom *= pow(0.95, -factor)
	$HUD.scale =Vector2(1,1) / $Camera.zoom
	
	zoom.emit(zoom_factor)

func set_zoom(factor):
	zoom_factor = factor
	$Camera.zoom = Vector2(1,1) * pow(0.95, -zoom_factor)
	$HUD.scale =Vector2(1,1) / $Camera.zoom
	
	zoom.emit(zoom_factor)

func focus(node):
	unfocus()
	slide_to(node.position)
	zoom_to(get_parent().satelite_visibility_zoom_factor)
	$HUD.focus(node)
	
	focused = true

func unfocus():
	if focused:
		$HUD.unfocus()
		focused = false
