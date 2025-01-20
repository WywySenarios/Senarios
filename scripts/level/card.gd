extends Control


#region Card Information & State Variables
@export var card : Card
## Does the card start faceup when the scene is first drawn?
@export var faceup : bool

## Is this card currently in the player's deck (i.e. it is not on the screen)
var in_deck: bool = false

var isInInventory: bool = false
#endregion

## This signal triggers when there is an attempt to place this card.
signal place(card_ref)

#region Temporary/Runtime Variables
# Create a dummy tween so that nobody will complain about nulls
var dragTween: Tween = create_tween()

## @deprecated
var is_inside_droppable: bool = false
## @deprecated
## If the user wants to let go of the card, where should it be placed?
var body_ref: Node

var offset: Vector2
var initialPos: Vector2
#endregion

#region Child Nodes
var backsideImageRect
var frontsideImageRect
var card_headImageRect
#endregion

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
	
	# display animations and what not related to adding the card
	# this is a fallback to others not calling addCard (old code did not have addCard, they just set the card attribute)
	if card != null:
		addCard(card)
	
	
	# allow card dragging
	dragTween.pause()


## Adds a Card object and displays the correct stats relating to that card.
## Setter for "card" attribute.
## returns true if the card is valid and has been set.
## Do not attempt to set the card to null. Use removeCard() function.
func addCard(_card: Card) -> bool:
	if _card == null:
		return false
	
	# set the card attribute
	card = _card
	
	# set card image
	card_headImageRect.texture = card.image
	
	# TODO stats
	if card is Entity:
		card.changeHealth.connect(changeHealth)
		# TODO change move signal
		changeHealth()
		changeAttack()
	return true

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


#region In Inventory Functions
## handles card placement animations :D
func _on_card_placement() -> void:
	$Contents/Particles/placement.restart()
	$Contents/Particles/placement.emitting = true


func onGUIInput(event: InputEvent) -> void:
	# a valid input is ONLY:
	# a click or click release,
	# left click type,
	if event is InputEventMouseButton and event.button_index == 1:
		# a valid drag for card placement is,
		# if the drag tween is not running (i.e. the card is not returning to its original position or being placed right now)
		# if the card is available to drag
		# the card is in the inventory (eligible to be dragged)
		# the card is yours
		# the card is in the scene tree
		var tree = get_tree()
		if not dragTween.is_running() and Draggables.cardSelected == self and isInInventory and get_parent().isMyInventory and tree != null:
			if event.button_mask == 1 and not Draggables.is_dragging: # press down
				initialPos = global_position
				Draggables.startDragging()
				offset = get_global_mouse_position() - global_position
			else: # release
				place.emit(self)
				
				# avoid weird bugs during the frames after the card is placed
				dragTween = tree.create_tween()
				if is_inside_droppable:
					dragTween.tween_property(self, "position", body_ref.position, 0.2).set_ease(Tween.EASE_OUT)
					
				else:
					dragTween.tween_property(self, "global_position", initialPos, 0.2).set_ease(Tween.EASE_OUT)
				
				Draggables.stopDragging()
				dragTween.tween_callback($AnimationPlayer.play.bind("Deselect"))
		# a valid focus event is: (always at this stage :D)
		#else:

func onMouseEntered() -> void:
	# if it's my card and it's in my inventory,
	if isInInventory and faceup and not Input.is_action_pressed("click"):
		Draggables.selectCard(self)
		$AnimationPlayer.play("Select")
	
	Global.focuseCard(self)


func onMouseExited() -> void:
	# if it's my card and it's in my inventory and I'm not clickign right now,
	if isInInventory and faceup and not Input.is_action_pressed("click"): # and not Input.is_action_pressed("click")
		Draggables.deselectCard(self)
		$AnimationPlayer.play("Deselect")
	
	Global.unfocusCard(self)

#endregion

func execute(target: Variant) -> Dictionary:
	return card.execute(target)
	

#region Stat Updates
## Called when the HP of the child card should be updated (does not necessarily change the value)
func changeHealth(_card: Entity = card, oldHealth: int = -1) -> void:
	if faceup:
		$"Contents/HP Container".show()
		$"Contents/HP Container/HP".text = str(_card.health)
	else:
		$"Contents/HP Container".hide()

## Called when the attack of the chilid card should be updated (does not necessarily change the value)
func changeAttack(_card: Card = card, oldAttack: int = -1) -> void:
	if faceup and card.move != null:
		match card.move.getType():
			"AttackDirect":
				$"Contents/Attack Container".show()
				$"Contents/Attack Container/Attack".text = str(_card.move.base_damage)
			_:
				$"Contents/Attack Container".hide()
	else:
		$"Contents/Attack Container".hide()

#endregion
