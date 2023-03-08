tool
extends Control


const generated_picture = preload("res://addons/chat-gpt/ui/generate_images/generated_picture.tscn")

onready var results_container = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer
onready var prompt_text = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HSplitContainer/PromptEdit
onready var prompt_label = $MarginContainer/VBoxContainer/Prompt_label
onready var send_button = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HSplitContainer/Button


func _on_PromtEdit_text_entered(_new_text: String) -> void:
	_on_Send_Button_pressed()


func _on_Send_Button_pressed() -> void:
	$HTTP.image_generation(prompt_text.text)
	prompt_label.text = prompt_text.text
	prompt_text.text = "Generating images..."


func _on_HTTP_images_request_completed(results) -> void:
	prompt_text.clear()
	# MANERA 1 - GENERANDO LAS IMAGENES EN EL MOMENTO
#	for generated_texture in results:
#		var picture = generated_picture.instance()
#		picture.texture = generated_texture
#		results_container.add_child(picture)

	# MANERA 2 - UTILIZANDO NODOS PREVIAMENTE CREADOS EN EL EDITOR
	for i in range(results.size()):
		if i >= results_container.get_child_count():
			break

		results_container.get_child(i).texture = results[i]
