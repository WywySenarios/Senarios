extends Node2D

@export var card : Card
## Does the card start faceup when the scene is first drawn?
@export var faceup : bool

## This signal triggers when there is an attempt to place this card.
signal place(card_ref)

## Is this card currently in the player's deck (i.e. it is not on the screen)
var in_deck: bool = false
## May this card currently be dragged by the user?
## Intended to be actively changed during runtime.
var draggable: bool = false
## @deprecated
var is_inside_droppable: bool = false
## @deprecated
## If the user wants to let go of the card, where should it be placed?
var body_ref: Node

var offset: Vector2
var initialPos: Vector2

## @experimental
func _ready() -> void:
	if (faceup):
		$Frontside.show()
	else:
		$Frontside.hide()
	
	$card_head.texture = card.image

## @experimental
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if draggable and not in_deck:
		if Input.is_action_just_pressed("click"):
			initialPos = global_position
			Draggables.startDragging()
			offset = get_global_mouse_position() - global_position
		elif Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() - offset
		elif Input.is_action_just_released("click"):
			Draggables.stopDragging()
			place.emit(self)
			
			#if is_inside_droppable:
				#get_tree().create_tween().tween_property(self, "position", body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
				#
			#else:
				#get_tree().create_tween().tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)

# changes the card from faceup to facedown, or vice versa
func flipOver() -> void:
	if (faceup):
		faceup = false
		$Frontside.hide()
	else:
		faceup = true
		$Frontside.show()

func _on_deck_maker_card_mouse_entered() -> void:
	if not Draggables.is_dragging:
		draggable = true
		scale = Vector2(scale.x * 1.05, scale.y * 1.05) # responsive UI


func _on_deck_maker_card_mouse_exited() -> void:
	if not Draggables.is_dragging:
		draggable = false
		scale = Vector2(scale.x / 1.05, scale.y / 1.05) # responsive UI


func _on_deck_maker_card_body_entered(body) -> void:
	if body.is_in_group("droppable"):
		is_inside_droppable = true
		body_ref = body


func _on_deck_maker_card_body_exited(body) -> void:
	if body.is_in_group("droppable"):
		is_inside_droppable = false
