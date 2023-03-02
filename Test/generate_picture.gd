tool
extends Control

onready var response_first_picture = $Background/MarginContainer/VBoxContainer/HBoxContainer/FirstPicture
onready var response_second_picture = $Background/MarginContainer/VBoxContainer/HBoxContainer/SecondPicture
onready var response_third_picture = $Background/MarginContainer/VBoxContainer/HBoxContainer/ThirdPicture
onready var response_fourth_picture = $Background/MarginContainer/VBoxContainer/HBoxContainer/FourthPicture

onready var prompt_text = $Background/MarginContainer/VBoxContainer/HSplitContainer/PromtEdit
onready var prompt_label = $Background/Prompt_label
onready var send_button = $Background/MarginContainer/VBoxContainer/HSplitContainer/Button

var current_number : int = 0

func _on_PromtEdit_text_entered(_new_text: String) -> void:
	_on_Send_Button_pressed()

func _on_Send_Button_pressed() -> void:
	$HTTP.image_generation(prompt_text.text)
	prompt_label.text = prompt_text.text
	prompt_text.text = "Generating images..."
	
	
func _on_HTTP_images_request_completed(results) -> void:
	if len(results) < current_number:
		$HTTP._on_image_download_request_completed(results)

func _on_HTTP_image_downloaded(texture) -> void:
	current_number += 1
	match current_number:
		1:
			response_first_picture.texture = texture
		2:
			response_second_picture.texture = texture
		3:
			response_third_picture.texture = texture
		4:
			response_fourth_picture.texture = texture
			prompt_text.clear()
			current_number = 0
