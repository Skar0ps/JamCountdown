@tool
extends ConfirmationDialog

## A dialog for configuring the jam countdown settings.
##
## This dialog exists to set the jam's title, end date, and an optional URL.
## The settings are saved to the project's file (`project.godot`).

@onready var gamejam_title: LineEdit = %GamejamTitle
@onready var day: SpinBox = %Day
@onready var month: SpinBox = %Month
@onready var year: SpinBox = %Year
@onready var hour: SpinBox = %Hour
@onready var minute: SpinBox = %Minute
@onready var human_date: Label = %HumanDate
@onready var jam_link: LineEdit = %JamLink
@onready var link_box: HBoxContainer = %LinkBox
@onready var countdown_label: Label = %CountdownLabel
@onready var title_label: Button = %TitleLabel

var current_date: Dictionary


func _ready() -> void:
	var editor_theme = EditorInterface.get_editor_theme()
	var accent_color = editor_theme.get_color("accent_color", "Editor")
	
	human_date.add_theme_color_override("font_color",accent_color)
	
	current_date = Time.get_datetime_dict_from_system()
	
	if !title_label.pressed.is_connected(_enter_edit_mode):
		title_label.pressed.connect(_enter_edit_mode,CONNECT_DEFERRED)
	
	if not confirmed.is_connected(_on_confirmed):
		confirmed.connect(_on_confirmed)
	
	# Connect signals only if they are not already connected.
	if not day.value_changed.is_connected(_on_date_value_changed):
		day.value_changed.connect(_on_date_value_changed)
	if not month.value_changed.is_connected(_on_date_value_changed):
		month.value_changed.connect(_on_date_value_changed)
	if not year.value_changed.is_connected(_on_date_value_changed):
		year.value_changed.connect(_on_date_value_changed)
	if not hour.value_changed.is_connected(_on_date_value_changed):
		hour.value_changed.connect(_on_date_value_changed)
	if not minute.value_changed.is_connected(_on_date_value_changed):
		minute.value_changed.connect(_on_date_value_changed)


func _on_confirmed() -> void:
	# Transfer settings from the dialog to the parent countdown node.
	get_parent().year = year.value
	get_parent().month = month.value
	get_parent().day = day.value
	get_parent().hour = hour.value
	get_parent().minute = minute.value
	get_parent().jam_title = gamejam_title.text
	get_parent().jam_page_url = jam_link.text
	
	_save_settings()
	countdown_label.tooltip_text = get_formatted_end_date()
	
	get_parent().start_countdown()

## Saves the current settings to the project's settings.
func _save_settings() -> void:
	var p = get_parent()
	ProjectSettings.set_setting(p.SETTING_TITLE, gamejam_title.text)
	ProjectSettings.set_setting(p.SETTING_YEAR, int(year.value))
	ProjectSettings.set_setting(p.SETTING_MONTH, int(month.value))
	ProjectSettings.set_setting(p.SETTING_DAY, int(day.value))
	ProjectSettings.set_setting(p.SETTING_HOUR, int(hour.value))
	ProjectSettings.set_setting(p.SETTING_MINUTE, int(minute.value))
	ProjectSettings.set_setting(p.SETTING_HAS_DATA, true)
	ProjectSettings.set_setting(p.SETTING_URL, jam_link.text.strip_edges())
	
	link_box.visible = jam_link.text.strip_edges() != ""
	ProjectSettings.save()

## Populates the dialog's fields with the current countdown settings.
func _update_values() -> void:
	current_date = Time.get_datetime_dict_from_system()
	
	year.value = get_parent().year 
	month.value = get_parent().month 
	day.value = get_parent().day
	hour.value = get_parent().hour
	minute.value = get_parent().minute
	gamejam_title.text = get_parent().jam_title
	jam_link.text = get_parent().jam_page_url
	_update_date_constraints()
	_update_human_date()

## Opens the dialog to edit the countdown settings.
func _enter_edit_mode() -> void:
	_update_values()
	popup_centered()

## Prevents the user from setting a date in the past.
## Updates the minimum values of the date/time SpinBoxes based on the current system time.
func _update_date_constraints() -> void:
	year.min_value = current_date.year
	
	if int(year.value) == current_date.year:
		month.min_value = current_date.month
	else:
		month.min_value = 1
	
	if int(year.value) == current_date.year and int(month.value) == current_date.month:
		day.min_value = current_date.day
	else:
		day.min_value = 1
	
	if int(year.value) == current_date.year and int(month.value) == current_date.month and int(day.value) == current_date.day:
		hour.min_value = current_date.hour
		if int(hour.value) == current_date.hour:
			minute.min_value = current_date.minute
		else:
			minute.min_value = 0
	else:
		hour.min_value = 0
		minute.min_value = 0

## Returns the end date formatted as a string (DD/MM/YY HH:MM).
func get_formatted_end_date() -> String :
	return "%02d/%02d/%02d %02d:%02d" % [
		int(day.value),
		int(month.value), 
		int(year.value) % 100,
		int(hour.value),
		int(minute.value)
	]

## Updates the human-readable date label in the dialog.
func _update_human_date() -> void:
	human_date.text = get_formatted_end_date()

## Callback function for when any of the date/time SpinBoxes change.
func _on_date_value_changed(_value: float) -> void:
	_update_date_constraints()
	_update_human_date()
