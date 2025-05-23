# QuestButton.gd
extends Button

@export var quest: Quest:
    set(value):
        quest = value
        update_button()

var is_available: bool = true

func _ready():
    pressed.connect(_on_pressed)
    update_button()

func update_button():
    if not quest:
        return
        
    text = quest.title
    hint_tooltip = quest.description
    
    # Проверяем доступность квеста
    is_available = true
    for trigger in quest.required_triggers:
        if not GameManager.story_manager.triggers.has(trigger):
            is_available = false
            break
            
    disabled = not is_available
    modulate = Color.WHITE if is_available else Color.GRAY

func _on_pressed():
    if not is_available or not quest:
        return
        
    # Добавляем квест через менеджер
    GameManager.quest_manager.add_quest(quest)
    
    # Обновляем диалоговую систему
    if GameManager.dialogue_manager.current_speaker:
        GameManager.dialogue_manager.reset_options()
        GameManager.dialogue_manager.show_dialogue()
    
    # Можно добавить звук или анимацию
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.GREEN, 0.3)
    tween.tween_property(self, "modulate", Color.WHITE, 0.3)
    
    # Отключаем кнопку после принятия
    queue_free()
