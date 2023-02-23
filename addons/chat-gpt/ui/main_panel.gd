tool
extends Control

onready var response_text = $MarginContainer/HSplitContainer/VSplitContainer/VSplitContainer/Response_RichText
onready var prompt_text = $MarginContainer/HSplitContainer/VSplitContainer/HSplitContainer/Prompt_LineEdit
onready var prompt_title = $MarginContainer/HSplitContainer/VSplitContainer/VSplitContainer/Title_Label


func _on_HTTP_completed(result : String):
	response_text.text = result


func _on_Send_Button_pressed():
	response_text.text = "Requesting...."
	prompt_title.text = prompt_text.text
	$HTTP.prompt(prompt_text.text)
	prompt_text.clear()
