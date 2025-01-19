class_name Special extends Card

## NOT SUPPORTED OR USED
@export var charges : int = 1
## NOT SUPPORTED OR USED
@export var chargeRegen : int = 0
## NOT SUPPORTED OR USED
## @experimental
@export var sacrificial : String
## NOT SUPPORTED OR USED
@export var abilities : Array[Ability]

func execute(target: Variant) -> Variant:
	charges -= 1
	return move.execute(target, self)

func serialize() -> Dictionary:
	var output: Dictionary =  {
		"subtype": "Special",
		"content": {
			"charges": charges,
			"chargeRegen": chargeRegen,
			"sacrificial": sacrificial,
			# CRITICAL does not work as expected due to references being weird
			"abilities": abilities,
		}
	}
	
	# do NOT override the above data
	var superClassSerialization = super.serialize()
	output.merge(superClassSerialization, false)
	output.content.merge(superClassSerialization.content, false)
	return output

func deserialize(_object: Dictionary) -> void:
	
	if _object.content.has("charges") and _object.content.charges != charges:
		charges = _object.content.charges
		# TODO emit signal
	
	if _object.content.has("chargeRegen") and _object.content.chargeRegen != chargeRegen:
		chargeRegen = _object.content.chargeRegen
		# TODO emit signal
		
	if _object.content.has("sacrificial") and _object.content.sacrificial != sacrificial:
		sacrificial = _object.content.sacrificial
		# TODO emit signal
	
	# TODO abilities
	
	super.deserialize(_object)
