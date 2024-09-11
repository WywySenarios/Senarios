class_name Entity extends Card

@export var health : float = 1
@export var hpr : float = 0
@export var shield : float = 0
var attackMultiplier # multiplicative
var attackBonus # linear---added after attack multiplier

var defenseMultiplier # divides damage done to the current card
var defenseBonus # linear---danage reduction after defense multiplier
@export var aggressive : bool = true
var statusEffects # status effects that currently apply to this card
@export var currentMove : int = 0 # current move that is selected (index of "moves" array)
@export var moves : Array[Move]
@export var abilities : Array[Ability]

func hurt(damage):
	damage /= defenseMultiplier
	if (damage > defenseBonus):
		health -= damage - defenseBonus
	# if the above if statement is not true, the damage is 0, either to start or because of damage reduction.

func execute(target):
	moves[currentMove].execute(target, self)
