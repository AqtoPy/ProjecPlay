extends Resource
class_name Dialogue

# Основная информация о диалоге
@export_category("Dialogue Info")
@export var id: String = "unique_id"  # Уникальный идентификатор
@export var texture: Texture2D  # Портрет говорящего
@export var name: String = "NPC"  # Имя персонажа
@export_multiline var dialogue_text: String = "..."  # Текст реплики

# Настройки отображения
@export var text_speed: float = 0.05  # Скорость появления текста (сек/символ)
@export var voice_sound: AudioStream  # Звук голоса
@export var animations: Array[String] = []  # Анимации для этого диалога

# Ветвление диалога
@export_category("Dialogue Options")
@export var options: Array[Dialogue] = []  # Варианты ответов
@export var random_options: bool = false  # Показывать варианты в случайном порядке
@export var option_conditions: Array[String] = []  # Условия для показа вариантов

# Влияние на игру
@export_category("Game Effects")
@export var triggers: Array[String] = []  # Триггеры, которые активируются
@export var removes_triggers: Array[String] = []  # Триггеры для удаления
@export var required_triggers: Array[String] = []  # Требуемые триггеры для показа

# Квестовая система
@export_category("Quest Interaction")
@export var starts_quest: Quest  # Квест, который начинается
@export var completes_quest: Quest  # Квест, который завершается
@export var quest_progress: Dictionary = {}  # {quest_id: "objective_id"}

# Система предметов
@export_category("Item Interaction")
@export var gives_items: Array[Item] = []  # Предметы для выдачи
@export var requires_items: Array[Item] = []  # Требуемые предметы
@export var removes_items: Array[Item] = []  # Предметы для удаления

# Настройки NPC
@export_category("NPC Behavior")
@export var changes_npc_state: String = ""  # Новое состояние NPC
@export var npc_animation: String = ""  # Анимация NPC после диалога
@export var ends_conversation: bool = false  # Завершает ли диалог

# Методы для проверки условий
func is_available() -> bool:
    # Проверяем триггеры
    for trigger in required_triggers:
        if not StoryManager.has_trigger(trigger):
            return false
    
    # Проверяем предметы
    for item in requires_items:
        if not Inventory.has_item(item.id):
            return false
    
    return true

func apply_effects():
    # Применяем триггеры
    for trigger in triggers:
        StoryManager.add_trigger(trigger)
    
    for trigger in removes_triggers:
        StoryManager.remove_trigger(trigger)
    
    # Квесты
    if starts_quest:
        QuestManager.add_quest(starts_quest)
    
    if completes_quest:
        QuestManager.complete_quest(completes_quest.id)
    
    for quest_id in quest_progress:
        QuestManager.progress_quest(quest_id, quest_progress[quest_id])
    
    # Предметы
    for item in gives_items:
        Inventory.add_item(item)
    
    for item in removes_items:
        Inventory.remove_item(item.id)
    
    # Возвращаем изменения для NPC
    var npc_changes = {
        "new_state": changes_npc_state,
        "animation": npc_animation,
        "ends_conversation": ends_conversation
    }
    
    return npc_changes

# Метод для получения доступных вариантов ответа
func get_available_options() -> Array[Dialogue]:
    var available = []
    
    for i in range(options.size()):
        if option_conditions.size() > i:
            if not StoryManager.has_trigger(option_conditions[i]):
                continue
        if options[i].is_available():
            available.append(options[i])
    
    if random_options:
        available.shuffle()
    
    return available

# Метод для проверки, есть ли у диалога видимые варианты
func has_visible_options() -> bool:
    if options.size() == 0:
        return false
    
    if option_conditions.size() == 0:
        return true
    
    for i in range(options.size()):
        if option_conditions.size() > i:
            if not StoryManager.has_trigger(option_conditions[i]):
                continue
        if options[i].is_available():
            return true
    
    return false
