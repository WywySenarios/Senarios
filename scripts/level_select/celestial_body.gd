extends Resource
class_name celestial_body

@export var name : String
@export var size : Vector2 = Vector2(400, 400)
@export var object_type : String = "planet"
@export var image : CompressedTexture2D
@export var idle_animation : SpriteFrames
@export var missions: Array[mission] = []
