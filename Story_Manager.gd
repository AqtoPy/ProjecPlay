# story_manager.gd
extends Node

var current_chapter: String = "Глава 1: Начало"
var triggers: Dictionary = {} # Состояние сюжетных флагов

signal chapter_changed(new_chapter)

func set_chapter(new_chapter: String):
    current_chapter = new_chapter
    chapter_changed.emit(current_chapter)
    
func process_triggers(trigger_list: Array):
    for trigger in trigger_list:
        triggers[trigger] = true
