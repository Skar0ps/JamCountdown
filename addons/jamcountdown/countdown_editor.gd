@tool
extends ConfirmationDialog

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

# Variables pour stocker la date système actuelle
var current_date: Dictionary

func _ready() -> void:
	var editor_theme = EditorInterface.get_editor_theme()
	var accent_color = editor_theme.get_color("accent_color", "Editor")
	
	human_date.add_theme_color_override("font_color",accent_color)
	
	# Récupérer la date système actuelle
	current_date = Time.get_datetime_dict_from_system()
	
	if not day.is_connected("value_changed", _on_date_value_changed):
		day.value_changed.connect(_on_date_value_changed)
	if not month.is_connected("value_changed", _on_date_value_changed):
		month.value_changed.connect(_on_date_value_changed)
	if not year.is_connected("value_changed", _on_date_value_changed):
		year.value_changed.connect(_on_date_value_changed)
	if not hour.is_connected("value_changed", _on_date_value_changed):
		hour.value_changed.connect(_on_date_value_changed)
	if not minute.is_connected("value_changed", _on_date_value_changed):
		minute.value_changed.connect(_on_date_value_changed)


func _on_confirmed() -> void:
	get_parent().year = year.value
	get_parent().month = month.value
	get_parent().day = day.value
	get_parent().hour = hour.value
	get_parent().minute = minute.value
	get_parent().jam_title = gamejam_title.text
	get_parent().jam_page_url = jam_link.text
	
	# Sauvegarder toutes les données dans ProjectSettings
	_save_settings()
	countdown_label.tooltip_text = get_formatted_end_date()
	
	get_parent().start_countdown()

func _save_settings() -> void:
	# MODIFIÉ : Utiliser les constantes définies dans le parent
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

func _update_values() -> void:
	# Mettre à jour la date système actuelle à chaque ouverture
	current_date = Time.get_datetime_dict_from_system()
	
	year.value = get_parent().year 
	month.value = get_parent().month 
	day.value = get_parent().day
	hour.value = get_parent().hour
	minute.value = get_parent().minute
	gamejam_title.text = get_parent().jam_title
	jam_link.text = get_parent().jam_page_url
	# Appliquer les contraintes de date
	_update_date_constraints()
	_update_human_date()

func edit() -> void:
	_update_values()
	popup()


## Met à jour les contraintes des SpinBox selon la date système
func _update_date_constraints() -> void:
	# Contraintes pour l'année (minimum = année actuelle)
	year.min_value = current_date.year
	
		# Contraintes pour le mois
	if int(year.value) == current_date.year:
		# Si l'année sélectionnée est l'année actuelle, limiter le mois
		month.min_value = current_date.month
	else:
		# Si l'année est future, pas de contrainte sur le mois
		month.min_value = 1
	
	# Contraintes pour le jour
	if int(year.value) == current_date.year and int(month.value) == current_date.month:
		# Si l'année et le mois sélectionnés sont actuels, limiter le jour
		day.min_value = current_date.day
	else:
		# Sinon, pas de contrainte sur le jour (minimum = 1)
		day.min_value = 1
	
	# Contraintes supplémentaires pour l'heure et la minute si c'est le même jour
	if int(year.value) == current_date.year and int(month.value) == current_date.month and int(day.value) == current_date.day:
		hour.min_value = current_date.hour
		# Si c'est aussi la même heure, limiter les minutes
		if int(hour.value) == current_date.hour:
			minute.min_value = current_date.minute
		else:
			minute.min_value = 0
	else:
		# Sinon, pas de contrainte sur l'heure et les minutes
		hour.min_value = 0
		minute.min_value = 0
	




func get_formatted_end_date() -> String :
	return "%02d/%02d/%02d %02d:%02d" % [
		int(day.value),
		int(month.value), 
		int(year.value) % 100,  # Année sur 2 chiffres
		int(hour.value),
		int(minute.value)
	]

## Met à jour l'affichage de la date formatée
func _update_human_date() -> void:
	human_date.text = get_formatted_end_date()

## Callback pour la modification d'une valeur de date/heure
func _on_date_value_changed(_value: float) -> void:
	# Mettre à jour les contraintes à chaque changement de valeur
	_update_date_constraints()
	_update_human_date()
