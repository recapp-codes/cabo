class_name CardList
extends Node2D

signal size_changed(size)

var card_scene = preload("res://assets/cabo/scenes/card.tscn")

@export var cards: Array[Card] = []

func _to_string():
	print(str(cards))

func get_top_card() -> Card:
	var card = cards.back()
	return card

func pop_top_card() -> Card:
	var card = cards.pop_back()
	size_changed.emit(cards.size())
	return card

func add_card(card) -> void:
	cards.append(card)
	size_changed.emit(cards.size())

func deal_card(player) -> void:
	if cards.size() > 0:
		var card = pop_top_card()
		player.hand.append(card)

func draw_card(player) -> void:
	if cards.size() > 0:
		var card = pop_top_card()
		player.set_new_card(card)
		if player.is_human:
			player.get_node('Control/CaboButton').disabled = true
		player.can_draw = false

func empty() -> bool:
	return cards.is_empty()

func shuffle() -> void:
	cards.shuffle()

func clear() -> void:
	cards.clear()
