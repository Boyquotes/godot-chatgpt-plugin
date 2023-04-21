tool
extends EditorPlugin


const MainPanel = preload("res://addons/chat-gpt/ui/main_panel.tscn")
const InspectorPlugin = preload("res://addons/chat-gpt/ui/inspector_plugin.gd")

var main_panel_instance
var inspector_plugin_instance


func _enter_tree():
	main_panel_instance = MainPanel.instance()

	# Add the main panel to the editor's main viewport.
	var editor_interface = get_editor_interface()
	main_panel_instance.set_meta("editor_interface", editor_interface)
	editor_interface.get_editor_viewport().add_child(main_panel_instance)

	inspector_plugin_instance = InspectorPlugin.new()
	add_inspector_plugin(inspector_plugin_instance)
	inspector_plugin_instance.connect(
			"image_variations_requested", self, "_on_image_variations_requested")

	# Hide the main panel. Very much required.
	make_visible(false)

	if not ProjectSettings.has_setting("plugins/chatgpt/openai_api_key"):
		ProjectSettings.set_setting("plugins/chatgpt/openai_api_key", "")
	# connect("main_screen_changed", main_panel_instance, "_on_main_screen_changed")


func _exit_tree():
	if main_panel_instance:
		main_panel_instance.queue_free()

	if inspector_plugin_instance:
		remove_inspector_plugin(inspector_plugin_instance)
		inspector_plugin_instance.queue_free()

#	if ProjectSettings.has_setting("plugins/chatgpt/openai_api_key"):
#		ProjectSettings.clear("plugins/chatgpt/openai_api_key")


func has_main_screen():
	return true


func make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible


func get_plugin_name():
	return "AI Assist"


func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")


func _on_image_variations_requested(texture):
	get_editor_interface().set_main_screen_editor("AI Assist")
	var tabs =  main_panel_instance.get_node("MarginContainer/TabContainer")
	tabs.current_tab = 1
	tabs.get_child(1).generate_image_variations(texture.get_data())
