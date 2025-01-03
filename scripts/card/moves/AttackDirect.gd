class_name AttackDirect extends Move

@export var base_damage : int = 0

func execute(target: Card, attacker: Card):
	if (attacker.aggressive):
		target.hurt((base_damage * attacker.attackMultiplier) + attacker.attackBonus)
