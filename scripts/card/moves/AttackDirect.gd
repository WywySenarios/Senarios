class_name AttackDirect extends Move

@export var base_damage : int = 0

func execute(target, parent):
	if (parent.aggressive):
		target.hurt((base_damage * parent.attackMultiplier) + parent.attackBonus)
