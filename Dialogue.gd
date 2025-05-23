# dialogue.gd
extends Resource
class_name Dialogue

@export_category("Information")
@export var texture: Texture2D
@export var name: String
@export_multiline var dialogue: String

@export_category("Linking Nodes")
@export var path_option: String
@export var options: Array[Dialogue]
@export var triggers: Array[String] # Новое поле для триггеров сюжета

@export_category("Quest")
@export var quest: Quest
@export var completes_quest: bool = false # Завершает квест при выборе
