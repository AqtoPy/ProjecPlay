extends Node

signal quest_added(quest)
signal quest_progress(quest)
signal quest_completed(quest)
signal quest_failed(quest)

var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []
var failed_quests: Array[Quest] = []

func add_quest(quest: Quest):
    if is_quest_active(quest) or is_quest_completed(quest):
        return
    
    active_quests.append(quest)
    quest.state = Quest.QuestState.IN_PROGRESS
    quest_added.emit(quest)
    check_quest_triggers()

func complete_quest(quest_id: String):
    var quest = get_quest_by_id(quest_id)
    if quest and active_quests.has(quest):
        active_quests.erase(quest)
        quest.state = Quest.QuestState.COMPLETED
        completed_quests.append(quest)
        
        # Выдача наград
        Economy.add_money(quest.reward_money)
        for item in quest.reward_items:
            Inventory.add_item(item)
        
        quest_completed.emit(quest)
        check_quest_triggers()

func fail_quest(quest_id: String):
    var quest = get_quest_by_id(quest_id)
    if quest and active_quests.has(quest):
        active_quests.erase(quest)
        quest.state = Quest.QuestState.FAILED
        failed_quests.append(quest)
        quest_failed.emit(quest)

func check_quest_triggers():
    for quest in active_quests:
        # Проверка условий провала
        for trigger in quest.fail_triggers:
            if StoryManager.triggers.has(trigger):
                fail_quest(quest.id)
                return
        
        # Проверка условий завершения
        var all_completed = true
        for trigger in quest.completion_triggers:
            if not StoryManager.triggers.has(trigger):
                all_completed = false
                break
        
        if all_completed:
            complete_quest(quest.id)

func is_quest_active(quest: Quest) -> bool:
    return active_quests.has(quest)

func is_quest_completed(quest: Quest) -> bool:
    return completed_quests.has(quest)

func get_quest_by_id(quest_id: String) -> Quest:
    for quest in active_quests + completed_quests + failed_quests:
        if quest.id == quest_id:
            return quest
    return null

func save_quests() -> Dictionary:
    return {
        "active": active_quests.map(func(q): return q.resource_path),
        "completed": completed_quests.map(func(q): return q.resource_path),
        "failed": failed_quests.map(func(q): return q.resource_path)
    }

func load_quests(data: Dictionary):
    active_quests = _load_quest_array(data.get("active", []))
    completed_quests = _load_quest_array(data.get("completed", []))
    failed_quests = _load_quest_array(data.get("failed", []))

func _load_quest_array(paths: Array) -> Array[Quest]:
    var result: Array[Quest] = []
    for path in paths:
        var quest = load(path) as Quest
        if quest:
            result.append(quest)
    return result
