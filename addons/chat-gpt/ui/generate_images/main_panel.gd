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

var original_image_size = Vector2()
var is_image_square = false

var current_dialog_index = -1


func _ready():
	for i in range(results_container.get_child_count()):
		results_container.get_child(i).connect("gui_input", self, "_on_Picture_gui_input", [i])


func generate_image_variations(texture):
	var image = texture.duplicate()
	original_image_size = image.get_size()

	# Images are expected to have the same width and height. If that's not the
	# case, surround the necessary space with black bars.
	is_image_square = original_image_size.x == original_image_size.y
	if not is_image_square:
		var max_size = max(original_image_size.x, original_image_size.y)

		# Create a full black square image.
		var square_image = Image.new()
		square_image.create(max_size, max_size, false, image.get_format())
		square_image.fill(Color(0, 0, 0))

		# Center the old image into the square one.
		var dest = Vector2()
		if original_image_size.x < original_image_size.y:
			dest.x = (original_image_size.y - original_image_size.x) / 2
		else:
			dest.y = (original_image_size.x - original_image_size.y) / 2

		square_image.blit_rect(image, Rect2(Vector2(), original_image_size), dest)
		image = square_image

	$HTTP.image_variation(image)
	$PreviewDialog.hide()
	prompt_label.text = ""
	prompt_text.text = "Generating varied images..."


func _on_Picture_gui_input(event, index):
	if event is InputEventMouseButton and \
		event.button_index == 1 and \
		event.is_pressed():
			var texture : Texture = results_container.get_child(index).texture
			if (texture):
				preview_dialog_texture.texture = texture
				current_dialog_index = index
				$PreviewDialog.popup(editor_interface.get_editor_viewport().get_global_rect())


func _on_PromtEdit_text_entered(_new_text: String) -> void:
	_on_Send_Button_pressed()


func _on_Send_Button_pressed() -> void:
	# A image is being generated from scratch, so make those values be ignored.
	original_image_size.x = -1
	is_image_square = true

	$HTTP.image_generation(prompt_text.text)
	prompt_label.text = prompt_text.text
	prompt_text.text = "Generating images..."


func _on_Previous_pressed():
	current_dialog_index = max(current_dialog_index - 1, 0)
	preview_dialog_texture.texture = results_container.get_child(current_dialog_index).texture


func _on_Next_pressed():
	current_dialog_index = min(current_dialog_index + 1, results_container.get_child_count() - 1)
	preview_dialog_texture.texture = results_container.get_child(current_dialog_index).texture


func _on_Close_gui_input(event):
	if event is InputEventMouseButton and \
		event.button_index == 1 and \
		event.is_pressed():
			$PreviewDialog.hide()


func _on_SaveImage_pressed():
	$SaveImageDialog.popup(editor_interface.get_editor_viewport().get_global_rect())


func _on_SaveResource_pressed():
	$SaveResourceDialog.popup(editor_interface.get_editor_viewport().get_global_rect())


func _on_SaveImageDialog_file_selected(path):
	preview_dialog_texture.texture.get_data().save_png(path)

	# Update editor filesystem
	editor_interface.get_resource_filesystem().scan()


func _on_SaveResourceDialog_file_selected(path):
	var image = preview_dialog_texture.texture
	image.set_meta("_ai", {})
	ResourceSaver.save(path, preview_dialog_texture.texture)

	# Update editor filesystem
	editor_interface.get_resource_filesystem().scan()


func _on_GenerateVariation_pressed():
	generate_image_variations(preview_dialog_texture.texture.get_data())


func _on_HTTP_image_downloaded(index, texture):
	if original_image_size.x != -1:
		var image = texture.get_data()
		var max_size = max(original_image_size.x, original_image_size.y)
		image.resize(max_size, max_size, Image.INTERPOLATE_LANCZOS)

	# If the image was not a square before, make it have the original
	# dimensions again. Some stuff will likely be cut out, but what you can do.
	if not is_image_square:
		var image = texture.get_data()
		var max_size = max(original_image_size.x, original_image_size.y)
		image.resize(max_size, max_size, Image.INTERPOLATE_LANCZOS)

		var new_image = Image.new()
		new_image.create(original_image_size.x, original_image_size.y,
				false, image.get_format())

		var start = Vector2()
		if original_image_size.x < original_image_size.y:
			start.x = (original_image_size.y - original_image_size.x) / 2
		else:
			start.y = (original_image_size.x - original_image_size.y) / 2

		new_image.blit_rect(image, Rect2(start, original_image_size), Vector2())
		image = new_image

		texture = ImageTexture.new()
		texture.create_from_image(image)

	results_container.get_child(index).texture = texture
