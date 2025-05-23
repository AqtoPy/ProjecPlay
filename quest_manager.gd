extends Node
class_name QuestManager

## Сигналы менеджера квестов
signal quest_added(quest)                # Когда квест добавлен
signal quest_started(quest)              # Когда квест начат
signal quest_progress(quest, objective)  # Прогресс по цели
signal quest_completed(quest)            # Когда квест завершен
signal quest_failed(quest)               # Когда квест провален
signal quest_updated                     # Любое изменение состояния

## Настройки
@export var save_enabled: bool = true
@export var auto_check_interval: float = 1.0

## Текущие квесты
var available_quests: Array[Quest] = []    # Доступные для взятия
var active_quests: Array[Quest] = []       # Активные квесты
var completed_quests: Array[Quest] = []    # Завершенные квесты
var failed_quests: Array[Quest] = []       # Проваленные квесты

## Служебные переменные
var _timer: Timer

func _ready():
    # Настройка таймера для автоматической проверки
    _timer = Timer.new()
    _timer.wait_time = auto_check_interval
    _timer.timeout.connect(_check_quests_progress)
    add_child(_timer)
    _timer.start()
    
    # Загрузка сохраненных квестов
    if save_enabled:
        load_quests()

## Основные методы ==============================================

## Добавить новый квест в систему
func add_quest(quest: Quest) -> bool:
    if has_quest(quest.id):
        push_warning("Quest %s already exists" % quest.id)
        return false
    
    available_quests.append(quest)
    quest.state = Quest.QuestState.AVAILABLE
    
    if quest.auto_start:
        return start_quest(quest.id)
    
    quest_added.emit(quest)
    quest_updated.emit()
    return true

## Начать квест
func start_quest(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        push_error("Quest %s not found" % quest_id)
        return false
    
    if quest.state != Quest.QuestState.AVAILABLE:
        push_warning("Quest %s is not available" % quest_id)
        return false
    
    if not quest.is_available():
        push_warning("Quest %s requirements not met" % quest_id)
        return false
    
    # Удаляем из доступных и добавляем в активные
    available_quests.erase(quest)
    active_quests.append(quest)
    
    # Меняем состояние
    quest.start_quest()
    
    # Оповещаем систему
    quest_started.emit(quest)
    quest_updated.emit()
    
    if save_enabled:
        save_quests()
    
    return true

## Завершить квест
func complete_quest(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        push_error("Quest %s not found" % quest_id)
        return false
    
    if quest.state != Quest.QuestState.IN_PROGRESS:
        push_warning("Quest %s is not in progress" % quest_id)
        return false
    
    # Проверяем выполнение всех целей
    if not quest.check_completion():
        return false
    
    # Меняем списки
    active_quests.erase(quest)
    completed_quests.append(quest)
    
    # Вызываем завершение
    quest.complete_quest()
    
    # Оповещаем систему
    quest_completed.emit(quest)
    quest_updated.emit()
    
    if save_enabled:
        save_quests()
    
    return true

## Провалить квест
func fail_quest(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        push_error("Quest %s not found" % quest_id)
        return false
    
    if quest.state != Quest.QuestState.IN_PROGRESS:
        push_warning("Quest %s is not in progress" % quest_id)
        return false
    
    # Меняем списки
    active_quests.erase(quest)
    failed_quests.append(quest)
    
    # Вызываем провал
    quest.fail_quest()
    
    # Оповещаем систему
    quest_failed.emit(quest)
    quest_updated.emit()
    
    if save_enabled:
        save_quests()
    
    return true

## Обновить прогресс цели
func update_objective(quest_id: String, objective_id: String, amount: int = 1) -> bool:
    var quest = get_quest(quest_id)
    if not quest:
        push_error("Quest %s not found" % quest_id)
        return false
    
    if quest.state != Quest.QuestState.IN_PROGRESS:
        push_warning("Quest %s is not in progress" % quest_id)
        return false
    
    var success = quest.update_objective(objective_id, amount)
    if success:
        quest_progress.emit(quest, quest.get_objective(objective_id))
        quest_updated.emit()
        
        if save_enabled:
            save_quests()
        
        # Автоматическая проверка завершения
        _check_quest_completion(quest)
    
    return success

## Методы проверки ==============================================

## Проверить наличие квеста
func has_quest(quest_id: String) -> bool:
    return get_quest(quest_id) != null

## Получить квест по ID
func get_quest(quest_id: String) -> Quest:
    for quest in available_quests + active_quests + completed_quests + failed_quests:
        if quest.id == quest_id:
            return quest
    return null

## Проверить активен ли квест
func is_quest_active(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    return quest != null && quest.state == Quest.QuestState.IN_PROGRESS

## Проверить завершен ли квест
func is_quest_completed(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    return quest != null && quest.state == Quest.QuestState.COMPLETED

## Проверить провален ли квест
func is_quest_failed(quest_id: String) -> bool:
    var quest = get_quest(quest_id)
    return quest != null && quest.state == Quest.QuestState.FAILED

## Получить прогресс по квесту
func get_quest_progress(quest_id: String) -> Dictionary:
    var quest = get_quest(quest_id)
    if quest:
        return quest.get_progress()
    return {"total": 0, "completed": 0, "progress": 0.0}

## Внутренние методы ============================================

func _check_quests_progress():
    for quest in active_quests:
        _check_quest_completion(quest)
        _check_quest_failure(quest)

func _check_quest_completion(quest: Quest):
    if quest.check_completion():
        complete_quest(quest.id)

func _check_quest_failure(quest: Quest):
    # Проверяем условия провала
    for condition in quest.fail_conditions:
        if StoryManager.has_trigger(condition):
            fail_quest(quest.id)
            return
    
    # Проверяем лимит времени
    if quest.time_limit > 0 and Time.get_unix_time_from_system() - quest.start_time > quest.time_limit:
        fail_quest(quest.id)

## Система сохранения ==========================================

func save_quests():
    var save_data = {
        "available": _serialize_quests(available_quests),
        "active": _serialize_quests(active_quests),
        "completed": _serialize_quests(completed_quests),
        "failed": _serialize_quests(failed_quests)
    }
    
    SaveManager.set_data("quests", save_data)

func load_quests():
    var save_data = SaveManager.get_data("quests", {})
    
    available_quests = _deserialize_quests(save_data.get("available", []))
    active_quests = _deserialize_quests(save_data.get("active", []))
    completed_quests = _deserialize_quests(save_data.get("completed", []))
    failed_quests = _deserialize_quests(save_data.get("failed", []))
    
    # Обновляем состояния
    for quest in available_quests:
        quest.state = Quest.QuestState.AVAILABLE
    for quest in active_quests:
        quest.state = Quest.QuestState.IN_PROGRESS
    for quest in completed_quests:
        quest.state = Quest.QuestState.COMPLETED
    for quest in failed_quests:
        quest.state = Quest.QuestState.FAILED
    
    quest_updated.emit()

func _serialize_quests(quests: Array[Quest]) -> Array:
    return quests.map(func(q): return q.serialize())

func _deserialize_quests(data: Array) -> Array[Quest]:
    var result: Array[Quest] = []
    for item in data:
        var quest = load(item["resource_path"]) as Quest
        if quest:
            quest.deserialize(item)
            result.append(quest)
    return result

## Вспомогательные методы ======================================

## Получить все активные квесты
func get_active_quests() -> Array[Quest]:
    return active_quests.duplicate()

## Получить все доступные квесты
func get_available_quests() -> Array[Quest]:
    return available_quests.duplicate()

## Получить все завершенные квесты
func get_completed_quests() -> Array[Quest]:
    return completed_quests.duplicate()

## Получить все проваленные квесты
func get_failed_quests() -> Array[Quest]:
    return failed_quests.duplicate()

## Сбросить все квесты
func reset_all_quests():
    available_quests.clear()
    active_quests.clear()
    completed_quests.clear()
    failed_quests.clear()
    quest_updated.emit()
