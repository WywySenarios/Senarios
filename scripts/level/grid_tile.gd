extends Control

class_name GridTile

signal clicked(id: int, tile: Array[int])

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the lobby's signals (Lobby is an autoload so this will always be ready to connect)
	# Animation signals:
	Lobby.summon.connect(animationSummon)
	Lobby.attack.connect(animationAttack)
	Lobby.buff.connect(animationBuff)
	Lobby.debuff.connect(animationDebuff)
	Lobby.kill.connect(animationKill)
	Lobby.ability.connect(animationAbility)
	# END: Animation signals
	
	# prompt signals:
	clicked.connect(Lobby.respondToPrompt)
	# END: prompt signals


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#region Animations
# General validity checking strategy:
# check if this is really this card that is being killed:
# check if the target is a grid tile's Entity,
# check if the target's coordinates match up

func animationSummon(target: Array[int], _card: Card) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		$Card.card = _card
		$Card.faceup = true # hard override
		$Card.show()
		
		# whisper to the card what position it is on
		if _card is Entity:
			_card.location = target
		
		# add the card to the gridtile
		$Card.addCard(_card)
		Lobby.activeCards[target[0]][target[1]] = $"Card"
		
		print("A card has been summoned at ", target, " and I am: ", Lobby.myID) # TODO animations

func animationAttack(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if not Lobby.multiplayer.is_server() and target is Array[int]:
		target = Lobby.flipCoords(target)
	
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("A card at ", self.get_meta("id"), " has just been attacked!: ", statChange) # TODO animations, display HP change
		$Card.card.changeStats(statChange)

func animationBuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if not Lobby.multiplayer.is_server() and target is Array[int]:
		target = Lobby.flipCoords(target)
	
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("The card at ", self.get_meta("id"), " has received a buff!") # TODO animations
		$Card.card.changeStats(statChange)

func animationDebuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if not Lobby.multiplayer.is_server() and target is Array[int]:
		target = Lobby.flipCoords(target)
	
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("The card at ", self.get_meta("id"), " has received a debuff!") # TODO animations
		$Card.card.changeStats(statChange)

func animationKill(target: Variant) -> void:
	if not Lobby.multiplayer.is_server() and target is Array[int]:
		target = Lobby.flipCoords(target)
	
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		# TODO add an actual animation
		print("Oh no! The card at ", target, " has just perished!") # TODO animations
		$Card.hide()
		$Card.card = null
		Lobby.activeCards[target[0]][target[1]] = null # tell the server that this card is no longer existant

func animationAbility(target: Variant, ability: Ability) -> void:
	if not Lobby.multiplayer.is_server() and target is Array[int]:
		target = Lobby.flipCoords(target)
	
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		# TODO add an actual animation
		print("The card at ", self.get_meta("id"), " has activated their ability!") # TODO animations
		# TODO trigger ability
		$Card.hide()
#endregion



func onInputEvent(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 0 and event.pressed:
		clicked.emit(Lobby.myID, self.get_meta("id") as Array[int])
