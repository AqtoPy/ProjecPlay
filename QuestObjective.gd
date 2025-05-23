extends Resource
class_name QuestObjective

@export var id: String = "objective_id"
@export var description: String = "Описание цели"
@export var required_amount: int = 1
@export var hidden: bool = false
@export var completion_trigger: String = ""

var current_amount: int = 0

func is_completed() -> bool:
    return current_amount >= required_amount

func update_progress(amount: int = 1):
    current_amount = min(current_amount + amount, required_amount)
    if is_completed() and completion_trigger:
        StoryManager.add_trigger(completion_trigger)

func reset():
    current_amount = 0

func get_status_text() -> String:
    if hidden and not is_completed():
        return "???"
    if required_amount > 1:
        return "%s (%d/%d)" % [description, current_amount, required_amount]
    return description + (" ✓" if is_completed() else "")

func serialize() -> Dictionary:
    return {
        "id": id,
        "current_amount": current_amount
    }

func deserialize(data: Dictionary):
    current_amount = data.get("current_amount", 0)
