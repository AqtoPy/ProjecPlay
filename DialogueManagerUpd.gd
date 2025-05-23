# В DialogueManager при добавлении кнопок:
func add_buttons(options):
    for option in options:
        var show_option = true
        for flag in option.flags_required:
            if StoryFlags.get_flag(flag) != option.flags_required[flag]:
                show_option = false
                break
        if show_option:
            var button = next_button.instantiate()
            button.dialogue = option
            %Options.add_child(button)
