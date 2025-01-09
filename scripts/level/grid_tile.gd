extends Control

class_name GridTile

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
		
		print("A card has just been summoned at ", self.get_meta("id")) # TODO animations

func animationAttack(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("A card at ", self.get_meta("id"), " has just been attacked!: ", statChange) # TODO animations, display HP change
		$Card.card.changeStats(statChange)

func animationBuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("The card at ", self.get_meta("id"), " has received a buff!") # TODO animations
		$Card.card.changeStats(statChange)

func animationDebuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		print("The card at ", self.get_meta("id"), " has received a debuff!") # TODO animations
		$Card.card.changeStats(statChange)

func animationKill(target: Variant) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		# TODO add an actual animation
		print("Oh no! The card at ", self.get_meta("id"), " has just perished!") # TODO animations
		$Card.hide()
		$Card.card = null

func animationAbility(target: Variant, ability: Ability) -> void:
	if typeof(target) == TYPE_ARRAY && target == self.get_meta("id"):
		# TODO add an actual animation
		print("The card at ", self.get_meta("id"), " has activated their ability!") # TODO animations
		# TODO trigger ability
		$Card.hide()
#endregion
