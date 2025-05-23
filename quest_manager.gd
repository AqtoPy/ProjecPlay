# quest_manager.gd
extends Node

var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []

func add_quest(quest: Quest):
    if not active_quests.has(quest) and not completed_quests.has(quest):
        active_quests.append(quest)
        quest.state = Quest.QuestState.IN_PROGRESS
        quest_added.emit(quest)

func complete_quest(quest: Quest):
    if active_quests.erase(quest):
        quest.state = Quest.QuestState.COMPLETED
        completed_quests.append(quest)
        Economy.add_money(quest.reward_money)
        quest_completed.emit(quest)
