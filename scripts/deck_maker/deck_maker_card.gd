extends Node2D

@export var card : Card
var in_deck = false
var draggable = false
var is_inside_droppable = false
var body_ref
var faceup = true

var offset: Vector2
var initialPos: Vector2

func _ready():
	$card_head.texture = card.image

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if draggable and not in_deck:
		if Input.is_action_just_pressed("click"):
			initialPos = global_position
			Draggables.startDragging()
			offset = get_global_mouse_position() - global_position
		elif Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released("click"):
			Draggables.stopDragging()
			
			if is_inside_droppable:
				get_tree().create_tween().tween_property(self, "position", body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
				
			else:
				get_tree().create_tween().tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)

# changes the card from faceup to facedown, or vice versa
func flipOver():
	if (faceup):
		faceup = false
		$Frontside.visible = false
	else:
		faceup = true
		$Frontside.visible = true

func _on_deck_maker_card_mouse_entered():
	if not Draggables.is_dragging:
		draggable = true
		scale = Vector2(1.05, 1.05)


func _on_deck_maker_card_mouse_exited():
	if not Draggables.is_dragging:
		draggable = false
		scale = Vector2(1, 1)


func _on_deck_maker_card_body_entered(body):
	if body.is_in_group("droppable"):
		is_inside_droppable = true
		body_ref = body


func _on_deck_maker_card_body_exited(body):
	if body.is_in_group("droppable"):
		is_inside_droppable = false
