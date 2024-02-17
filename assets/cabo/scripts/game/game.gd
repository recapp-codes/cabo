extends Node2D

const PLAYER = preload("res://assets/cabo/scenes/player/player.tscn")
const COMPUTER = preload("res://assets/cabo/scenes/player/computer.tscn")

# PAUSE TIME
const LONG_LONG = 5
const LONG = 3
const MEDIUM = 2
const SHORT = 1
const SHORT_SHORT = 0.5
var turn_list := []
var turn_index: int
var cabo_called := false
var cabo_caller: Player

var num_players = 4

func _ready():
	$Players.add_child(PLAYER.instantiate())
	for i in range(num_players - 1):
		var computer = COMPUTER.instantiate()
		$Players.add_child(computer)
		computer.name_label = i + 1

	set_player_positions()
	
	$Players.get_child(0).is_main_player = true
	
	$EndPanel.connect('new_round', _on_new_round)
	
	for player in $Players.get_children():
		Scoreboard.set_score(0, player)
		player.connect('cabo_called', _on_cabo_called)
	
	start_round()

func _process(_delta):	
	if $Deck.cards.size() == 0:
		$Deck.cards = $Pile.cards.slice(1)
		$Pile.cards = $Pile.cards.slice(0, 1)
		$Deck.shuffle()
		$Deck.update()
		$Pile.update()

func set_player_positions():
	var positions = [Vector2(800, 1050), Vector2(800, 150)] if $Players.get_child_count() == 2 else [ Vector2(800, 1050), Vector2(150, 600), Vector2(800, 150), Vector2(1450, 600)]
	var rotations = [0, PI] if $Players.get_child_count() == 2 else [0, PI / 2, PI, -(PI / 2)]
	for i in range($Players.get_child_count()):
		$Players.get_child(i).position = positions[i]
		$Players.get_child(i).rotation = rotations[i]

func _on_cabo_called(player):
	$Deck.disable()
	$Pile.disable()
	cabo_called = true
	cabo_caller = player

var turn_count := 0

func _on_new_round():
	turn_count = 0
	cabo_called = false
	start_round()

func start_round():
	$EndPanel.hide()
	
	for player in $Players.get_children():
		turn_list.append(player)
		for i in range(4):
			$Deck.deal_card(player)
	
	$Pile.discard($Deck.pop_top_card())

	$Deck.update()
	$Pile.update()
	
	turn_index = randi_range(0, $Players.get_child_count() - 1)
	
	await get_tree().create_timer(MEDIUM).timeout
	
	for player in $Players.get_children():
		if not player.is_human:
			for opp in $Players.get_children():
				player.memory[opp] = [null, null, null, null] if opp != player else [player.hand[0], player.hand[1], null, null]
		if player.is_main_player:
			player.get_node('Hand').get_child(0).flip()
			player.get_node('Hand').get_child(1).flip()
			await get_tree().create_timer(LONG).timeout
			player.get_node('Hand').get_child(0).flip()
			player.get_node('Hand').get_child(1).flip()
	await get_tree().create_timer(SHORT).timeout
	start_turn(turn_list[turn_index])

var current_player: Player

func start_turn(player):
	turn_count += 1
	current_player = player
	if player.is_human:
		$Deck.enable()
		$Pile.enable()
		player.enable_cabo_button()
	player.can_draw = true
	player.get_node('TurnIndicator').show()
	if not player.is_human:
		player.computer_turn()

func end_turn(player):
	await get_tree().create_timer(SHORT_SHORT).timeout
	player.get_node('TurnIndicator').hide()
	player.disable_cabo_button()
	if cabo_called:
		turn_list.erase($Players.get_child(turn_index))
		if turn_list.size() == 0:
			end_round()
			return
	turn_index = (turn_index + 1) % $Players.get_child_count()
	start_turn($Players.get_child(turn_index))

func end_round():
	for player in $Players.get_children():
		for card in player.get_node('Hand').get_children():
			card.flip()
	await get_tree().create_timer(LONG_LONG).timeout
	$EndPanel.display_scoreboard()

func swap(list_a: Array, a_index: int, list_b: Array, b_index: int) -> void:
	var temp = list_a[a_index]
	list_a[a_index] = list_b[b_index]
	list_b[b_index] = temp

# RETURN METHODS
func sum(list) -> int:
	var total = 0
	for i in list:
		if i != null:
			total += i.value
	return total

func minpos(list: Array) -> int:
	var list_values = []
	for card in list:
		if card == null:
			list_values.append(INF)
		else:
			list_values.append(card.value)
	return list_values.find(list_values.min())
	
func maxpos(list: Array) -> int:
	var list_values = []
	for card in list:
		if card == null:
			list_values.append(-INF)
		else:
			list_values.append(card.value)
	return list_values.find(list_values.max())

func value_in_hand(value, list) -> Array: # [bool, index]
	for i in range(list.size()):
		if (value == null and list[i] == null) or (value != null and list[i] != null and list[i].value == value):
			return [true, i]
	return [false, null]

func get_sorted_players(dict: Dictionary) -> Array:
	var players = []
	var arr = [INF]
	for player in dict:
		arr.sort()
		var n = sum(dict[player]) if typeof(dict[player]) == TYPE_ARRAY else dict[player]
		for i in range(arr.size()):
			if n < arr[i]:
				players.insert(i, player)
				break
		arr.append(n)
	return players
