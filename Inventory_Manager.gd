# inventory_manager.gd
extends Node

signal inventory_updated

var items: Array[Item] = []

func add_item(item: Item):
    # Проверяем можно ли стакать предмет
    if item.stackable:
        for existing_item in items:
            if existing_item.id == item.id and existing_item.amount < existing_item.max_stack:
                existing_item.amount += 1
                inventory_updated.emit()
                return
    
    # Добавляем новый предмет
    items.append(item)
    inventory_updated.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
    for i in range(items.size() - 1, -1, -1):
        if items[i].id == item_id:
            if items[i].stackable and items[i].amount > amount:
                items[i].amount -= amount
                inventory_updated.emit()
                return true
            else:
                items.remove_at(i)
                inventory_updated.emit()
                return true
    return false

func has_item(item_id: String, amount: int = 1) -> bool:
    var count = 0
    for item in items:
        if item.id == item_id:
            count += item.amount if item.stackable else 1
            if count >= amount:
                return true
    return false
