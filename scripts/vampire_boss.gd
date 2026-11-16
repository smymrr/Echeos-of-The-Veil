extends CharacterBody2D

var target_player: Node2D = null
var is_active: bool = false


# The dungeon scene will call this function
func activate(player_instance: Node2D) -> void:
	target_player = player_instance
	is_active = true
	
	# Trigger roar animation, show boss health bar, etc.
	print("Boss activated! Target is: ", target_player.name)
