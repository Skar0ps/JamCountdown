@tool
extends EditorPlugin

var countdown_scene = preload("res://addons/jamcountdown/jam_countdown.tscn")
var countdown
var container = 0

var UNIX_TIME_CALC_CORRECTION := 0

func _enter_tree():
	## get offset from UTC for local time calculations:
	var time_zone := Time.get_time_zone_from_system() # <--- this does have an edge case checked windows machines during daylight savings time, not sure how to solve
	# time_zone:bias is how many minutes offset local time is from UTC, convert to seconds for unix epoch offset
	UNIX_TIME_CALC_CORRECTION = time_zone["bias"] * 60
	
	countdown = countdown_scene.instantiate()
	countdown.name = "addon_countdown"
	add_control_to_container(container, countdown)
	
	var parent_container = countdown.get_parent()
	if parent_container:
		parent_container.move_child(countdown,countdown.get_index()-2)

func _exit_tree():
	remove_control_from_container(container, countdown)
	countdown.queue_free()
