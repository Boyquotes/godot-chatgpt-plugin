tool
extends Control


export (NodePath) var root

onready var response_text = $MarginContainer/HSplitContainer/VSplitContainer/VSplitContainer/Response_RichText
onready var prompt_text = $MarginContainer/HSplitContainer/VSplitContainer/HSplitContainer/Prompt_LineEdit
onready var prompt_title = $MarginContainer/HSplitContainer/VSplitContainer/VSplitContainer/Title_Label
onready var send_button = $MarginContainer/HSplitContainer/VSplitContainer/HSplitContainer/Send_Button


func _on_HTTP_completed(result : String):
	response_text.text = result


func _on_Send_Button_pressed():
	response_text.text = "Requesting...."
	prompt_title.text = prompt_text.text
	$HTTP.completions(prompt_text.text)
	prompt_text.clear()


func _on_Prompt_LineEdit_text_entered(_new_text):
	_on_Send_Button_pressed()


func _on_HTTP_error():
	response_text.text = "ERROR. Check the Output Log"
