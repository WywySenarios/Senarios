class_name Special extends Card

@export var charges : int = 1
## NOT SUPPORTED OR USED
@export var chargeRegen : int = 0
## NOT SUPPORTED OR USED
## @experimental
@export var sacrificial : String
@export var move : Move
## NOT SUPPORTED OR USED
@export var abilities : Array[Ability]

func execute(target: Variant):
	move.execute(target, self)
	
	charges -= 1
