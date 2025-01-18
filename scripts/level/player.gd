extends Control

var player: Player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.attack.connect(animationAttack)

func addPlayer(_player: Player) -> bool:
	if player == null:
		player = _player
		player.healthChanged.connect(changeHealth)
		return true
	else:
		return false

#region Animations
func animationKill(destination: Variant):
	# if this player is being attacked,
	pass

func animationAttack(target: Variant, _cause: Variant, statChange: Dictionary, directAttack: bool):
	# if this player is being attacked,
	if not target is int or target != player.playerNumber:
		return
	
	if statChange.has("health"):
		player.changeStats(target, _cause, statChange, directAttack)


## change energy animation
func changeEnergy(id: int, oldEnergy: int):
	if Lobby.playerNumbers[id] == player.playerNumber:
		print("Player: ", self, " gained ", player.energy - oldEnergy, " energy")
		$Energy.text = "Energy: " + str(player.energy)

## changeHealth animation
func changeHealth(playerNumber: int, oldHealth: int):
	if playerNumber == player.playerNumber:
		print("Player ", self, " gained ", player.health - oldHealth, " health")
		$Health.text = "Health: " + str(player.health)
#endregion Animations
