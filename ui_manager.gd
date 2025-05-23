# ui_manager.gd
extends CanvasLayer

@onready var chapter_label: Label = $ChapterLabel
@onready var money_label: Label = $MoneyLabel
@onready var quest_panel: Panel = $QuestPanel

func _ready():
    StoryManager.chapter_changed.connect(update_chapter)
    Economy.money_changed.connect(update_money)
    QuestManager.quest_added.connect(add_quest_ui)

func update_chapter(new_chapter: String):
    chapter_label.text = new_chapter
    
func update_money(amount: int):
    money_label.text = "Деньги: %d" % amount
    
func add_quest_ui(quest: Quest):
    var quest_ui = preload("res://ui/quest.tscn").instantiate()
    quest_ui.setup(quest)
    quest_panel.add_child(quest_ui)
