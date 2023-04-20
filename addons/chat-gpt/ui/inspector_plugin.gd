extends EditorInspectorPlugin


signal image_variations_requested(texture)


func can_handle(object):
	if object is StreamTexture:
		var image = object.get_data()
		if image.is_empty():
			return false

		var button = Button.new()
		button.text = tr("Generate Variations in AI")
		add_custom_control(button)
		button.connect("pressed", self, "emit_signal",
				["image_variations_requested", object])

		return true

	return false
