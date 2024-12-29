extends Control

var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func changeEnergy(id: int, oldEnergy: int):
	if id == Lobby.myID:
		print("Player: ", self, " gained ", player.energy - oldEnergy, " energy")
		$Energy.text = "Energy: " + str(player.energy)

func changeHealth(id: int, oldHealth: int):
	if id == Lobby.myID:
		print("Player ", self, " gained ", player.health - oldHealth, " health")
		$Health.text = player.health
