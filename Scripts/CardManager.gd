extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_CARD_SLOT = 2
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1
const CARD_BIGGER_SCALE = 1.05
const CARD_SMALLER_SCALE = 0.8

var card_being_dragged
var screen_size
var is_hovering_on_card
var player_hand_reference
var played_monster_card_this_turn = false
var selected_monster

func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_reference = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)

func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))

func card_clicked(card):
	if card.card_slot_card_is_in:
		if $"../BattleManager".is_opponents_turn == false:
			if $"../BattleManager".player_is_attacking == false:
				if card not in $"../BattleManager".player_cards_that_attacked_this_turn:
					if $"../BattleManager".opponent_cards_on_battlefield.size() == 0:
						$"../BattleManager".direct_attack(card, "Player")  # Attacco diretto al giocatore
						return
					else:
						select_card_for_battle(card)
	else: 
		start_drag(card)

func select_card_for_battle(card):
	if selected_monster: 
		if selected_monster == card: 
			selected_monster = card
			card.position.y += 20
			selected_monster = null
		else: 
			selected_monster.position.y += 20 
			selected_monster = card
			card.position.y -= 20 
	else:
		selected_monster = card
		card.position.y -= 20

func start_drag(card):
	card_being_dragged = card
	card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)

func finish_drag():
	card_being_dragged.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		if card_being_dragged.card_type == card_slot_found.card_slot_type:
			if !played_monster_card_this_turn:
				card_being_dragged.scale = Vector2(CARD_SMALLER_SCALE, CARD_SMALLER_SCALE)
				card_being_dragged.z_index = -1
				is_hovering_on_card = false
				card_being_dragged.card_slot_card_is_in = card_slot_found
				player_hand_reference.remove_card_from_hand(card_being_dragged)
				card_being_dragged.position = card_slot_found.position
				card_slot_found.card_in_slot = true
				card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
				$"../BattleManager".player_cards_on_battlefield.append(card_being_dragged)
				played_monster_card_this_turn = true #AGGIUNTA
				card_being_dragged = null
				return
	player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	card_being_dragged = null

func unselect_selected_monster():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)

func on_left_click_released():
	if card_being_dragged:
		finish_drag()

func on_hovered_over_card(card):
	if card.card_slot_card_is_in:
		return
	if !is_hovering_on_card:
		is_hovering_on_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card.defeated:
		if !card.card_slot_card_is_in && card_being_dragged:
			highlight_card(card, false)
			var new_card_hovered = raycast_check_for_card()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering_on_card = false

func highlight_card(card, hovered):
	if hovered: 
		card.scale = Vector2(CARD_BIGGER_SCALE, CARD_BIGGER_SCALE)
		card.z_index = 2
	else: 
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1

func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null

func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	return null

func get_card_with_highest_z_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index

	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card

func reset_played_monster():
	played_monster_card_this_turn = false
