extends Button

@export var quest: Quest:
    set(value):
        quest = value
        update_button_appearance()

var is_available: bool = false
var is_completed: bool = false

@onready var timer: Timer = $Timer
@onready var sound_effect: AudioStreamPlayer = $AcceptSound

func _ready():
    mouse_entered.connect(_on_mouse_entered)
    pressed.connect(_on_pressed)
    update_button_appearance()

func update_button_appearance():
    if not quest:
        return
    
    # Проверяем условия квеста
    is_available = true
    for trigger in quest.required_triggers:
        if not StoryManager.triggers.has(trigger):
            is_available = false
            break
    
    is_completed = QuestManager.is_quest_completed(quest)
    
    # Настраиваем внешний вид
    text = quest.title
    hint_tooltip = quest.description + "\n\nНаграда: " + str(quest.reward_money) + " монет"
    
    if is_completed:
        disabled = true
        modulate = Color.DARK_GREEN
        hint_tooltip += "\n\n(Завершено)"
    elif is_available:
        disabled = false
        modulate = Color.WHITE
        hint_tooltip += "\n\n(Доступно)"
    else:
        disabled = true
        modulate = Color.DARK_GRAY
        hint_tooltip += "\n\n(Недоступно)"

func _on_mouse_entered():
    if not disabled:
        var tween = create_tween()
        tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_pressed():
    if not is_available or is_completed:
        return
    
    sound_effect.play()
    QuestManager.add_quest(quest)
    
    # Анимация принятия
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.GREEN, 0.2)
    tween.tween_property(self, "rect_scale", Vector2(1.1, 1.1), 0.1)
    tween.tween_property(self, "rect_scale", Vector2(1.0, 1.0), 0.1)
    tween.tween_callback(queue_free)

func _on_timer_timeout():
    update_button_appearance()
