tool
extends Control


const generated_picture = preload("res://addons/chat-gpt/ui/generate_images/generated_picture.tscn")

export (NodePath) var root

onready var results_container = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HBoxContainer
onready var prompt_text = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HSplitContainer/PromptEdit
onready var prompt_label = $MarginContainer/VBoxContainer/Prompt_label
onready var send_button = $MarginContainer/VBoxContainer/MarginContainer/VBoxContainer/HSplitContainer/Button
onready var preview_dialog_texture = $PreviewDialog/Control/Preview/TextureRect
onready var editor_interface = get_node(root).get_meta("editor_interface")


var current_dialog_index = -1


func _ready():
	for i in range(results_container.get_child_count()):
		results_container.get_child(i).connect("gui_input", self, "_on_Picture_gui_input", [i])


func _on_PromtEdit_text_entered(_new_text: String) -> void:
	_on_Send_Button_pressed()


func _on_Send_Button_pressed() -> void:
	$HTTP.image_generation(prompt_text.text)
	prompt_label.text = prompt_text.text
	prompt_text.text = "Generating images..."


func _on_HTTP_images_request_completed(results) -> void:
	prompt_text.clear()
	for i in range(results.size()):
		if i >= results_container.get_child_count():
			break

		results_container.get_child(i).texture = results[i]


func _on_Picture_gui_input(event, index):
	if event is InputEventMouseButton and \
		event.button_index == 1 and \
		event.is_pressed():
			preview_dialog_texture.texture = results_container.get_child(index).texture
			current_dialog_index = index
			$PreviewDialog.popup(editor_interface.get_editor_viewport().get_global_rect())


func _on_Previous_pressed():
	current_dialog_index = min(current_dialog_index + 1, results_container.get_child_count() - 1)
	preview_dialog_texture.texture = results_container.get_child(current_dialog_index).texture


func _on_Next_pressed():
	current_dialog_index = max(current_dialog_index - 1, 0)
	preview_dialog_texture.texture = results_container.get_child(current_dialog_index).texture


func _on_Close_gui_input(event):
	if event is InputEventMouseButton and \
		event.button_index == 1 and \
		event.is_pressed():
			$PreviewDialog.hide()


func _on_SaveImage_pressed():
	$SaveImageDialog.popup(editor_interface.get_editor_viewport().get_global_rect())


func _on_SaveImageDialog_file_selected(path):
	preview_dialog_texture.texture.get_data().save_png(path)

	# Update editor filesystem
	editor_interface.get_resource_filesystem().scan()
