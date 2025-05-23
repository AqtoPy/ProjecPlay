extends Area2D
class_name InteractionZone

## Сигналы для взаимодействия
signal interaction_started(interactor)
signal interaction_finished(interactor)
signal availability_changed(can_interact)

## Настройки взаимодействия
@export_category("Interaction Settings")
@export var interaction_label: String = "Interact"  # Текст подсказки
@export var interaction_key: String = "interact"   # Клавиша действия
@export var show_label: bool = true                # Показывать ли подсказку
@export var multiple_interactions: bool = false    # Множественные взаимодействия
@export var cooldown: float = 0.5                 # Задержка между взаимодействиями

## Ссылки на узлы
@onready var label: Label = %Label
@onready var cooldown_timer: Timer = $CooldownTimer

## Внутренние переменные
var can_interact: bool = false:
    set(value):
        if can_interact != value:
            can_interact = value
            if show_label and label:
                label.visible = value
            availability_changed.emit(value)
            
var interactor: Node = null
var is_in_cooldown: bool = false

func _ready():
    # Настройка Label
    if label:
        label.text = interaction_label
        label.visible = false
    
    # Настройка таймера
    cooldown_timer.wait_time = cooldown
    cooldown_timer.timeout.connect(_on_cooldown_finished)
    
    # Подключаем сигналы
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node):
    if body.is_in_group("Player"):
        interactor = body
        can_interact = true

func _on_body_exited(body: Node):
    if body == interactor:
        can_interact = false
        interactor = null

func interaction():
    if !can_interact || is_in_cooldown:
        return
    
    # Вызываем взаимодействие у владельца
    if owner.has_method("interact"):
        interaction_started.emit(interactor)
        owner.interact(interactor)
        interaction_finished.emit(interactor)
    else:
        push_warning("Owner %s has no interact() method" % owner.name)
    
    # Запускаем кулдаун если нужно
    if !multiple_interactions:
        can_interact = false
        is_in_cooldown = true
        cooldown_timer.start()

func _on_cooldown_finished():
    is_in_cooldown = false
    if interactor and !can_interact:
        can_interact = true

func _input(event: InputEvent):
    if event.is_action_pressed(interaction_key) and can_interact and !is_in_cooldown:
        interaction()

## Вспомогательные методы
func enable_interaction():
    can_interact = true

func disable_interaction():
    can_interact = false

func set_interaction_label(new_text: String):
    interaction_label = new_text
    if label:
        label.text = new_text

func update_configuration():
    if label:
        label.visible = show_label and can_interact
        label.text = interaction_label
    cooldown_timer.wait_time = cooldown
