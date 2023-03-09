tool
extends TextureRect

onready var _popup_dialog: PopupDialog = $"../../../../../../PopupDialog"
onready var _texture_rect: TextureRect = $"../../../../../../PopupDialog/TextureRect"
onready var _close: Button = $"../../../../../../PopupDialog/Close"


var _current_image: int = 0

func _on_FirstPicture_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.is_pressed():
			_texture_rect.texture = self.texture
			_popup_dialog.show()
			_close.visible = true
