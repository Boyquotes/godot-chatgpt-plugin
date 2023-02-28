tool
extends HTTPRequest

const endpoint = "https://api.openai.com/v1/"


signal completions_request_completed(result)
signal images_request_completed(results)

signal error()


func _on_completions_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	var json = JSON.parse(body.get_string_from_utf8())
	match response_code:
		200:
			emit_signal("completions_request_completed", json.result.choices[0].text)
		401:
			printerr("You didn't provide an OpenAI API key. You can obtain an API key from https://platform.openai.com/account/api-keys. Then set it up in Project Settings -> Plugins -> Chatgpt -> openai_api_key")
			emit_signal("error")
		_:
			printerr(JSON.print(json.result.error.message))
			emit_signal("error")


func completions(prompt: String):
	var request_params = {
		"model": "code-cushman-001",
		"prompt": prompt,
		"max_tokens": 1920,
		"temperature": 0.9,
		"top_p": 1,
		"best_of": 5,
		"frequency_penalty": 0.5,
		"presence_penalty": 0.5,
	}

	var headers = [
		"Authorization: Bearer " + ProjectSettings.get("plugins/chatgpt/openai_api_key"),
		"Content-Type: application/json",
	]

	connect("request_completed", self, "_on_completions_request_completed", [], CONNECT_ONESHOT)
	request_raw(endpoint + "completions", headers, false, HTTPClient.METHOD_POST, JSON.print(request_params).to_utf8())
