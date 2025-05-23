# item.gd
extends Resource
class_name Item

@export_category("Item Info")
@export var id: String
@export var name: String
@export var texture: Texture2D
@export_multiline var description: String

@export_category("Item Properties")
@export var stackable: bool = true
@export var max_stack: int = 99
@export var value: int = 10  # Базовая стоимость
@export var consumable: bool = false

# Для экипировки (если нужно)
enum ItemType { GENERAL, WEAPON, ARMOR, CONSUMABLE }
@export var type: ItemType = ItemType.GENERAL

# Дополнительные свойства для разных типов предметов
@export_group("Weapon Properties")
@export var damage: int = 0

@export_group("Armor Properties")
@export var defense: int = 0

@export_group("Consumable Properties")
@export var health_restore: int = 0
