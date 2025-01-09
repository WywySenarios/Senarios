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
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#region Animations
func animationSummon(target: Array[int], _card: Card):
	$Card.card = _card
	$Card.faceup = true # hard override

func animationAttack(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool):
	pass

func animationBuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool):
	pass

func animationDebuff(target: Variant, source: Variant, statChange: Dictionary, directAttack: bool):
	pass

func animationKill(target: Variant):
	# check if this is really this card that is being killed
	if typeof(target) == TYPE_ARRAY && target = self.get_meta("ID")
	pass

func animationAbility(target: Variant, ability: Ability):
	pass
#endregion
