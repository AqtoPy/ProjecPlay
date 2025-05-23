# quest.gd
extends Resource
class_name Quest

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED, FAILED }

@export var id: String
@export var title: String
@export_multiline var description: String
@export var reward_money: int
@export var reward_items: Array[Item]  # Теперь ошибки не будет
@export var required_triggers: Array[String]
@export var fail_triggers: Array[String]
