class_name GameRoot
extends Node

func _ready():
	var player_state = global.player_state()

	player_state.characters.append(PlayableCharacter.new("Rozemyne"))
	player_state.characters.append(PlayableCharacter.new("Charlotte"))
	player_state.characters.append(PlayableCharacter.new("Brunhilde"))

	($Level as BaseLevel).spawn_playable_characters(player_state.characters)
