# enemy_npc.gd
extends CharacterBody2D

@export var story_related: bool = true
@export var required_triggers: Array[String] # Когда появляется
@export var dialogue_defeated: Dialogue
@export var dialogue_aggressive: Dialogue

var is_defeated: bool = false

func interact():
    if StoryManager.check_triggers(required_triggers):
        if is_defeated:
            DialogueManager.show_dialogue(dialogue_defeated)
        else:
            DialogueManager.show_dialogue(dialogue_aggressive)
            start_battle()
