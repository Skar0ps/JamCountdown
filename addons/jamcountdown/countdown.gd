@tool
extends Control

## Emitted when the countdown timer starts.
signal countdown_started

## Emitted each time the countdown timer is updated (every second).
signal countdown_updated

## Emitted when the countdown timer finishes.
signal countdown_finished

const SETTINGS_PREFIX := "jam_countdown/"

## Project setting key for checking if custom data exists.
const SETTING_HAS_DATA := SETTINGS_PREFIX + "has_custom_data"

## Project setting key for the jam title.
const SETTING_TITLE := SETTINGS_PREFIX + "jam_title"

## Project setting key for the end year.
const SETTING_YEAR := SETTINGS_PREFIX + "year"

## Project setting key for the end month.
const SETTING_MONTH := SETTINGS_PREFIX + "month"

## Project setting key for the end day.
const SETTING_DAY := SETTINGS_PREFIX + "day"

## Project setting key for the end hour.
const SETTING_HOUR := SETTINGS_PREFIX + "hour"

## Project setting key for the end minute.
const SETTING_MINUTE := SETTINGS_PREFIX + "minute"

## Project setting key for the jam page URL.
const SETTING_URL := SETTINGS_PREFIX + "link_to_jam_page"

## The title of the game jam.
@export var jam_title := "GamejamName"
## The URL to the game jam's page.
@export var jam_page_url := "https://itch.io/jam/"

@export_category("End date of the gamejam")

## The year the jam ends.
@export var year : int = 2025

## The month the jam ends.
@export_range(1,12,1) var month : int = 10

## The day the jam ends.
@export_range(1,31,1) var day : int = 10

## The hour the jam ends.
@export_range(0,23,1) var hour : int = 10

## The minute the jam ends.
@export_range(0,59,1) var minute : int = 10

## If `true`, shows time units (e.g., "d", "h", "m", "s").
@export var show_time_units := true

@onready var title_label : Button = %TitleLabel
@onready var countdown_label : Label = %CountdownLabel
@onready var link_box: HBoxContainer = %LinkBox
@onready var link_button: Button = %LinkButton

var jam_end_date: Dictionary
var jam_date_unix : int
var time_left_unix : int
var timer : Timer


func _ready() -> void:
	if _has_saved_data():
		_load_settings()
	elif Engine.is_editor_hint():
		_set_default_date()
	start_countdown()
	

## Checks if there is saved countdown data in the project settings.
func _has_saved_data() -> bool:
	return ProjectSettings.has_setting(SETTING_HAS_DATA) and ProjectSettings.get_setting(SETTING_HAS_DATA, false)

## Loads the countdown settings from the project settings.
func _load_settings() -> void:
	var current_date : Dictionary = Time.get_datetime_dict_from_system()
	
	jam_title = ProjectSettings.get_setting(SETTING_TITLE, "GamejamName")
	year = ProjectSettings.get_setting(SETTING_YEAR, current_date.year)
	month = ProjectSettings.get_setting(SETTING_MONTH, current_date.month)
	day = ProjectSettings.get_setting(SETTING_DAY, current_date.day)
	hour = ProjectSettings.get_setting(SETTING_HOUR, 23)
	minute = ProjectSettings.get_setting(SETTING_MINUTE, 59)
	jam_page_url = ProjectSettings.get_setting(SETTING_URL, "https://itch.io/jam/")
	
	$EditPanel._update_values()
	countdown_label.tooltip_text = $EditPanel.get_formatted_end_date()
	
	if jam_page_url != "https://itch.io/jam/": 
		link_box.show()
		if not link_button.is_connected("pressed",_on_jam_link_button_pressed):
			link_button.pressed.connect(_on_jam_link_button_pressed)
	else:
		link_box.hide()

## Sets a default end date for the countdown (7 days from now).
## Used when no custom data is saved.
func _set_default_date() -> void:
	var current_date = Time.get_datetime_dict_from_system()
	var future_unix = Time.get_unix_time_from_datetime_dict(current_date) + (7 * 24 * 60 * 60)
	var future_date = Time.get_datetime_dict_from_unix_time(future_unix)
	
	jam_title = "WeekJam"
	year = future_date.year
	month = future_date.month
	day = future_date.day
	hour = future_date.hour
	minute = future_date.minute

## Initializes and starts the countdown timer.
## Sets up the end date dictionary and updates the UI.
func start_countdown() -> void:
	jam_end_date = {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": 0
	}
	title_label.text = jam_title
	countdown_label.text = ""
	countdown_label.visible = true
	var editor_theme = EditorInterface.get_editor_theme()
	var accent_color = editor_theme.get_color("accent_color", "Editor")
	
	title_label.add_theme_color_override("font_color",accent_color)
	
	initialize_countdown()
	emit_signal("countdown_started")

## Creates and configures the [Timer] node for the countdown.
## The timer is synchronized with the system clock to ensure it ticks every second accurately.
func create_timer() -> void:
	if not is_instance_valid(timer):
		timer = Timer.new()
		add_child(timer)
		timer.connect("timeout",_on_Timer_timeout)
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	timer.one_shot = false
	
	# Sync with system clock to start the timer at the beginning of a second.
	var system_time_ms = Time.get_unix_time_from_system() * 1000
	var str_millis = str(system_time_ms)
	var wait_time = (1000-int(str_millis.substr(str_millis.length()-3,str_millis.length()-1)))/1000.0
	if wait_time == 0: wait_time = 1
	
	timer.set_wait_time(wait_time)
	timer.start()

func _on_Timer_timeout() -> void:
	if not is_instance_valid(timer):
		return
	timer.wait_time = 1
	update_countdown()

func _on_jam_link_button_pressed() -> void:
	OS.shell_open(ProjectSettings.get_setting("jam_countdown/link_to_jam_page", "https://itch.io/jam/"))

## Sets up the initial state of the countdown.
## Calculates the initial time remaining and starts the timer.
func initialize_countdown() -> void:
	jam_date_unix = Time.get_unix_time_from_datetime_dict(jam_end_date)
	var current_time_unix = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	
	time_left_unix = jam_date_unix - current_time_unix
	if time_left_unix <= 0:
		countdown_label.text = "Ended !"
		emit_signal("countdown_finished")
		return
	update_countdown_label_text()
	create_timer()

## Updates the countdown every second.
## Stops the timer if the end date is reached.
func update_countdown() -> void:
	var current_time_unix = Time.get_unix_time_from_datetime_dict(Time.get_datetime_dict_from_system())
	time_left_unix = jam_date_unix - current_time_unix
	
	if time_left_unix <= 0:
		countdown_label.text = "Ended !"
		countdown_label.visible = true
		if is_instance_valid(timer): timer.queue_free()
		emit_signal("countdown_finished")
		return
	
	update_countdown_label_text()
	emit_signal("countdown_updated")

## Formats and displays the remaining time. [br]
## The format depends on the [member show_time_units] property.
func update_countdown_label_text() -> void:
	var time_left = get_datetime_from_unix(time_left_unix)
	
	var str_days
	var str_hours
	var str_minutes
	var str_seconds
	
	if show_time_units:
		str_days    = "%02d" % time_left.day + "d "    if time_left.day    > 0 else ""
		str_hours   = "%02d" % time_left.hour + "h "   if time_left.hour   > 0 else ""
		str_minutes = "%02d" % time_left.minute + "m "
		str_seconds = "%02d" % time_left.second + "s"
	else:
		str_days    = "%02d" % time_left.day    +":"
		str_hours   = "%02d" % time_left.hour   +":"
		str_minutes = "%02d" % time_left.minute +":"
		str_seconds = "%02d" % time_left.second
		
	countdown_label.text = str_days + str_hours + str_minutes + str_seconds

## Converts a Unix timestamp into a dictionary of days, hours, minutes, and seconds. [br]
## Returns a dictionary with "day", "hour", "minute", and "second" keys.
func get_datetime_from_unix(unix_timestamp: int) -> Dictionary:
	var seconds = floor(unix_timestamp % 60)
	var minutes = floor((unix_timestamp / 60) % 60)
	var hours   = floor((unix_timestamp / 3600) % 24)
	var days    = floor(unix_timestamp / 86400)
	
	var time = {
		"day": days,
		"hour": hours,
		"minute": minutes,
		"second": seconds
	}
	return time
