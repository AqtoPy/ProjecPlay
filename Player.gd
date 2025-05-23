# player.gd
extends CharacterBody2D

@export var outfits: Dictionary = {
    "hats": [],
    "eyes": [],
    "clothes": []
}
var current_outfit: Dictionary = {
    "hat": null,
    "eyes": null,
    "clothes": null
}

func change_outfit(type: String, index: int):
    if outfits[type].size() > index:
        current_outfit[type] = outfits[type][index]
        update_appearance()
        
func update_appearance():
    $Hat.texture = current_outfit["hat"]
    $Eyes.texture = current_outfit["eyes"]
    # и т.д.
