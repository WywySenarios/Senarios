extends Container

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

# Create a dummy tween so that nobody will complain about nulls
var dragTween: Tween = create_tween()


var isInInventory: bool = false

## @deprecated
var is_inside_droppable: bool = false
## @deprecated
## If the user wants to let go of the card, where should it be placed?
var body_ref: Node

var offset: Vector2
var initialPos: Vector2

var backsideImageRect
var frontsideImageRect
var card_headImageRect

## @experimental
func _ready() -> void:
	backsideImageRect = $"Contents/Backside"
	frontsideImageRect = $"Contents/Frontside"
	card_headImageRect = $"Contents/card_head"
	
	if (faceup):
		backsideImageRect.hide()
		frontsideImageRect.show()
		card_headImageRect.show()
	else:
		backsideImageRect.show()
		frontsideImageRect.hide()
		card_headImageRect.hide()
	
	card_headImageRect.texture = card.image
	
	# allow card dragging
	dragTween.pause()
	

## @experimental
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	if not in_deck and not dragTween.is_running() and Draggables.cardSelected == self:
		if Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() - offset

# changes the card from faceup to facedown, or vice versa
func flipOver() -> void:
	backsideImageRect = $"Contents/Backside"
	frontsideImageRect = $"Contents/Frontside"
	card_headImageRect = $"Contents/card_head"
	
	if (faceup):
		backsideImageRect.hide()
		frontsideImageRect.show()
		card_headImageRect.show()
		faceup = false
	else:
		backsideImageRect.show()
		frontsideImageRect.hide()
		card_headImageRect.hide()
		faceup = true


func _on_deck_maker_card_body_entered(body) -> void:
	if body.is_in_group("droppable"):
		is_inside_droppable = true
		body_ref = body


func _on_deck_maker_card_body_exitsed(body) -> void:
	if body.is_in_group("droppable"):
		is_inside_droppable = false

## handles card placement animations :D
func _on_card_placement() -> void:
	$Contents/Particles/placement.restart()
	$Contents/Particles/placement.emitting = true

func onMouseEntered() -> void:
	if isInInventory:
		Draggables.selectCard(self)


func onMouseExited() -> void:
	if isInInventory:
		Draggables.deselectCard(self)


func onGUIInput(event: InputEvent) -> void:
	# a valid input is ONLY:
	# a click or click release,
	# left click type,
	# if the drag tween is not running (i.e. the card is not returning to its original position or being placed right now)
	# if the card is available to drag
	# the card is in the inventory (eligible to be dragged)
	# the card is yours
	if event is InputEventMouseButton and event.button_index == 1 and not dragTween.is_running() and Draggables.cardSelected == self and isInInventory and get_parent().isMyInventory:
		if event.button_mask == 1 and not Draggables.is_dragging: # press down
			initialPos = global_position
			Draggables.startDragging()
			offset = get_global_mouse_position() - global_position
		else: # release
			place.emit(self)
			
			dragTween = get_tree().create_tween()
			if is_inside_droppable:
				dragTween.tween_property(self, "position", body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
				
			else:
				dragTween.tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)
			
			Draggables.stopDragging()
			dragTween.tween_callback($AnimationPlayer.play.bind("Deselect"))

func onMouseEnteredInventory() -> void:
	if isInInventory:
		$AnimationPlayer.play("Select")


func onMouseExitedInventory() -> void:
	if isInInventory:
		$AnimationPlayer.play("Deselect")
