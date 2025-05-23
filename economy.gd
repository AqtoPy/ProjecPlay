# economy.gd
extends Node

var money: int = 0:
    set(value):
        money = max(0, value)
        money_changed.emit(money)

signal money_changed(amount)

func add_money(amount: int):
    money += amount
    
func spend_money(amount: int) -> bool:
    if money >= amount:
        money -= amount
        return true
    return false
