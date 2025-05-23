extends CanvasLayer

# Сигналы
signal dialogue_started(speaker)
signal dialogue_ended()
signal option_selected(option)
signal text_typed(character)

# Настройки
@export_category("Settings")
@export var text_speed: float = 0.05  # Секунд на символ
@export var auto_advance_delay: float = 2.0  # Автопродолжение диалога
@export var skip_confirmation: bool = false  # Подтверждение выхода

# Ресурсы
@export_category("Resources")
@export var option_button_scene: PackedScene
@export var quest_button_scene: PackedScene
@export var default_portrait: Texture2D

# Ссылки на узлы
@onready var dialogue_box: Panel = $DialogueBox
@onready var portrait: TextureRect = $DialogueBox/MarginContainer/HBoxContainer/Portrait
@onready var speaker_label: Label = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready var dialogue_label: RichTextLabel = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/DialogueLabel
@onready var options_container: VBoxContainer = $DialogueBox/MarginContainer/HBoxContainer/VBoxContainer/Options
@onready var type_sound: AudioStreamPlayer = $TypeSound
@onready var advance_timer: Timer = $AdvanceTimer
@onready var text_timer: Timer = $TextTimer

# Переменные
var current_dialogue: Dialogue
var current_speaker: Node = null
var typing: bool = false
var current_options: Array = []
var dialogue_history: Array = []

func _ready():
    hide_dialogue()
    advance_timer.wait_time = auto_advance_delay
    text_timer.wait_time = text_speed

func start_dialogue(speaker: Node, dialogue: Dialogue):
    if dialogue_box.visible:
        return
    
    current_speaker = speaker
    current_dialogue = dialogue
    dialogue_history.clear()
    
    update_dialogue_ui()
    show_dialogue()
    emit_signal("dialogue_started", speaker)
    
    if dialogue.voice_sound:
        type_sound.stream = dialogue.voice_sound
    
    process_dialogue_effects(dialogue)

func update_dialogue_ui():
    # Обновляем портрет и имя
    portrait.texture = current_dialogue.texture if current_dialogue.texture else default_portrait
    speaker_label.text = current_dialogue.name
    
    # Очищаем предыдущие варианты
    for child in options_container.get_children():
        child.queue_free()
    
    # Показываем текст диалога
    dialogue_label.visible_ratio = 0
    dialogue_label.text = current_dialogue.dialogue_text
    start_typing_animation()
    
    # Добавляем варианты ответа
    current_options = current_dialogue.get_available_options()
    add_dialogue_options(current_options)
    
    # Добавляем квестовые кнопки если есть
    if current_dialogue.starts_quest and !QuestManager.is_quest_active_or_completed(current_dialogue.starts_quest):
        add_quest_button(current_dialogue.starts_quest)

func start_typing_animation():
    typing = true
    dialogue_label.visible_ratio = 0
    text_timer.start()

func complete_typing():
    typing = false
    dialogue_label.visible_ratio = 1
    text_timer.stop()
    
    # Автопродолжение если нет вариантов
    if current_options.size() == 0 and !current_dialogue.has_visible_options():
        advance_timer.start()

func add_dialogue_options(options: Array[Dialogue]):
    for option in options:
        var button = option_button_scene.instantiate()
        button.text = option.path_option if option.path_option else option.dialogue_text
        button.pressed.connect(_on_option_selected.bind(option))
        options_container.add_child(button)

func add_quest_button(quest: Quest):
    var button = quest_button_scene.instantiate()
    button.quest = quest
    button.pressed.connect(_on_quest_accepted.bind(quest))
    options_container.add_child(button)

func process_dialogue_effects(dialogue: Dialogue):
    # Применяем эффекты диалога
    var npc_changes = dialogue.apply_effects()
    
    # Обновляем NPC если нужно
    if current_speaker and current_speaker.has_method("update_state"):
        current_speaker.update_state(npc_changes)
    
    # Завершаем диалог если нужно
    if npc_changes.get("ends_conversation", false):
        end_dialogue()

func _on_option_selected(option: Dialogue):
    emit_signal("option_selected", option)
    dialogue_history.append(current_dialogue)
    current_dialogue = option
    update_dialogue_ui()

func _on_quest_accepted(quest: Quest):
    QuestManager.add_quest(quest)
    options_container.get_children()[-1].queue_free()  # Удаляем кнопку квеста

func _on_TextTimer_timeout():
    if typing:
        dialogue_label.visible_ratio += 1.0 / float(dialogue_label.text.length())
        
        if dialogue_label.visible_ratio >= 1.0:
            complete_typing()
        elif type_sound and !type_sound.playing:
            type_sound.play()

func _on_AdvanceTimer_timeout():
    if current_options.size() == 0 and !typing:
        next_dialogue()

func next_dialogue():
    if current_dialogue.options.size() > 0:
        # Выбираем первый доступный вариант
        for option in current_dialogue.options:
            if option.is_available():
                _on_option_selected(option)
                return
    
    end_dialogue()

func show_dialogue():
    dialogue_box.show()
    get_tree().paused = true  # Опционально

func hide_dialogue():
    dialogue_box.hide()
    get_tree().paused = false

func end_dialogue():
    emit_signal("dialogue_ended")
    hide_dialogue()
    current_speaker = null
    current_dialogue = null

func _input(event):
    if !dialogue_box.visible:
        return
    
    if event.is_action_pressed("ui_accept"):
        if typing:
            complete_typing()
            advance_timer.stop()
        else:
            next_dialogue()
    
    if event.is_action_pressed("ui_cancel") and skip_confirmation:
        show_skip_confirmation()

func show_skip_confirmation():
    # Реализуйте окно подтверждения при необходимости
    end_dialogue()

# Вспомогательные функции
func is_dialogue_active() -> bool:
    return dialogue_box.visible

func get_current_speaker() -> Node:
    return current_speaker

func get_dialogue_history() -> Array:
    return dialogue_history
