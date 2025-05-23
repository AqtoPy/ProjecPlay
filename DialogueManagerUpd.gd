# dialogue_manager.gd
# В методе add_buttons после создания кнопки:
button.pressed.connect(func():
    if option.triggers.size() > 0:
        StoryManager.process_triggers(option.triggers)
    if option.completes_quest and current_speaker.quest:
        QuestManager.complete_quest(current_speaker.quest)
)
