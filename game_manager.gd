# game_manager.gd
extends Node

# Автозагружаемые системы
var economy: Node
var quest_manager: Node
var story_manager: Node
var dialogue_manager: Node

# Состояние игры
var game_started: bool = false
var player_data: Dictionary = {}

func _ready():
    # Инициализация подсистем
    initialize_managers()
    
    # Тестовые данные (можно удалить)
    test_setup()
    
    # Сигналы
    setup_connections()

func initialize_managers():
    economy = preload("res://autoload/economy.gd").new()
    add_child(economy)
    economy.name = "Economy"
    
    quest_manager = preload("res://autoload/quest_manager.gd").new()
    add_child(quest_manager)
    quest_manager.name = "QuestManager"
    
    story_manager = preload("res://autoload/story_manager.gd").new()
    add_child(story_manager)
    story_manager.name = "StoryManager"
    
    dialogue_manager = preload("res://autoload/dialogue_manager.gd").new()
    add_child(dialogue_manager)
    dialogue_manager.name = "DialogueManager"

func setup_connections():
    quest_manager.quest_completed.connect(_on_quest_completed)
    story_manager.chapter_changed.connect(_on_chapter_changed)

func test_setup():
    # Для тестирования
    economy.money = 100
    story_manager.current_chapter = "Глава 1: Пробуждение"
    player_data = {
        "outfits": {
            "hat": "none",
            "eyes": "default"
        },
        "inventory": []
    }

func save_game():
    var save_data = {
        "money": economy.money,
        "chapter": story_manager.current_chapter,
        "triggers": story_manager.triggers,
        "quests": {
            "active": quest_manager.active_quests.map(func(q): return q.id),
            "completed": quest_manager.completed_quests.map(func(q): return q.id)
        },
        "player": player_data
    }
    return save_data

func load_game(data: Dictionary):
    economy.money = data.get("money", 0)
    story_manager.current_chapter = data.get("chapter", "Глава 1")
    story_manager.triggers = data.get("triggers", {})
    player_data = data.get("player", {})

func _on_quest_completed(quest: Quest):
    print("Квест завершен: ", quest.title)
    economy.add_money(quest.reward_money)

func _on_chapter_changed(new_chapter: String):
    print("Текущая глава: ", new_chapter)
