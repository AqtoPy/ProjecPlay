extends Resource
class_name Quest

## Состояния квеста
enum QuestState {
    NOT_AVAILABLE,    # Квест еще не доступен
    AVAILABLE,        # Можно взять
    IN_PROGRESS,      # В процессе выполнения
    COMPLETED,        # Успешно завершен
    FAILED            # Провален
}

## Основная информация о квесте
@export_category("Quest Info")
@export var id: String = "quest_unique_id"          # Уникальный идентификатор
@export var title: String = "Название квеста"       # Отображаемое название
@export_multiline var description: String = ""      # Описание квеста
@export_multiline var completion_text: String = ""  # Текст при завершении
@export var icon: Texture2D                         # Иконка квеста
@export var sort_order: int = 0                     # Порядок сортировки в журнале

## Награды за квест
@export_category("Rewards")
@export var reward_money: int = 0                   # Денежная награда
@export var reward_exp: int = 0                     # Опыт за выполнение
@export var reward_items: Array[Item] = []           # Предметные награды
@export var unlock_triggers: Array[String] = []      # Триггеры, которые открываются

## Условия квеста
@export_category("Requirements")
@export var required_level: int = 0                 # Требуемый уровень
@export var required_triggers: Array[String] = []   # Необходимые триггеры
@export var required_quests: Array[Quest] = []      # Необходимые завершенные квесты
@export var required_items: Array[Item] = []        # Необходимые предметы

## Цели квеста
@export_category("Objectives")
@export var objectives: Array[QuestObjective] = []  # Список целей квеста

## Поведение квеста
@export_category("Behavior")
@export var auto_start: bool = false                # Начинается автоматически
@export var auto_complete: bool = false             # Завершается автоматически
@export var repeatable: bool = false                # Можно повторять
@export var time_limit: float = 0.0                 # Лимит времени (0 = нет лимита)
@export var fail_conditions: Array[String] = []     # Условия провала

## Текущее состояние
var state: QuestState = QuestState.NOT_AVAILABLE
var current_objectives: Array = []
var start_time: float = 0.0
var end_time: float = 0.0

## Инициализация квеста
func _init():
    if objectives.size() > 0:
        current_objectives = objectives.duplicate(true)

## Проверка доступности квеста
func is_available() -> bool:
    if state != QuestState.NOT_AVAILABLE:
        return state == QuestState.AVAILABLE
    
    # Проверяем требования
    for trigger in required_triggers:
        if not StoryManager.has_trigger(trigger):
            return false
    
    for quest in required_quests:
        if quest.state != QuestState.COMPLETED:
            return false
    
    for item in required_items:
        if not Inventory.has_item(item.id):
            return false
    
    return true

## Начать квест
func start_quest():
    if state != QuestState.AVAILABLE and state != QuestState.NOT_AVAILABLE:
        return false
    
    if not is_available():
        return false
    
    state = QuestState.IN_PROGRESS
    start_time = Time.get_unix_time_from_system()
    
    # Инициализация целей
    for objective in current_objectives:
        objective.reset()
    
    return true

## Проверить выполнение квеста
func check_completion() -> bool:
    if state != QuestState.IN_PROGRESS:
        return false
    
    # Проверяем условия провала
    for condition in fail_conditions:
        if StoryManager.has_trigger(condition):
            fail_quest()
            return false
    
    # Проверяем лимит времени
    if time_limit > 0 and Time.get_unix_time_from_system() - start_time > time_limit:
        fail_quest()
        return false
    
    # Проверяем выполнение целей
    for objective in current_objectives:
        if not objective.is_completed():
            return false
    
    # Все условия выполнены
    if auto_complete:
        complete_quest()
    
    return state == QuestState.COMPLETED

## Завершить квест
func complete_quest():
    if state != QuestState.IN_PROGRESS:
        return
    
    state = QuestState.COMPLETED
    end_time = Time.get_unix_time_from_system()
    
    # Применяем награды
    if reward_money > 0:
        Economy.add_money(reward_money)
    
    if reward_exp > 0:
        PlayerData.add_exp(reward_exp)
    
    for item in reward_items:
        Inventory.add_item(item.duplicate())
    
    for trigger in unlock_triggers:
        StoryManager.add_trigger(trigger)

## Провалить квест
func fail_quest():
    state = QuestState.FAILED
    end_time = Time.get_unix_time_from_system()

## Сбросить квест
func reset_quest():
    if not repeatable and state == QuestState.COMPLETED:
        return false
    
    state = QuestState.AVAILABLE
    current_objectives = objectives.duplicate(true)
    return true

## Обновить прогресс цели
func update_objective(objective_id: String, amount: int = 1) -> bool:
    if state != QuestState.IN_PROGRESS:
        return false
    
    for objective in current_objectives:
        if objective.id == objective_id:
            objective.update_progress(amount)
            return true
    
    return false

## Получить информацию о прогрессе
func get_progress() -> Dictionary:
    var completed = 0
    for objective in current_objectives:
        if objective.is_completed():
            completed += 1
    
    return {
        "total": current_objectives.size(),
        "completed": completed,
        "progress": float(completed) / float(current_objectives.size())
    }

## Получить описание целей
func get_objectives_text() -> String:
    var text = ""
    for objective in current_objectives:
        text += "- " + objective.get_status_text() + "\n"
    return text

## Сериализация для сохранения
func serialize() -> Dictionary:
    return {
        "id": id,
        "state": state,
        "start_time": start_time,
        "end_time": end_time,
        "objectives": current_objectives.map(func(o): return o.serialize())
    }

## Десериализация для загрузки
func deserialize(data: Dictionary):
    state = data.get("state", QuestState.NOT_AVAILABLE)
    start_time = data.get("start_time", 0.0)
    end_time = data.get("end_time", 0.0)
    
    if data.has("objectives"):
        for i in range(min(data["objectives"].size(), current_objectives.size())):
            current_objectives[i].deserialize(data["objectives"][i])
