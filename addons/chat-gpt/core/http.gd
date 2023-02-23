tool
extends HTTPRequest

const endpoint = "https://api.openai.com/v1/"

signal _completed(result)


func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	var json = JSON.parse(body.get_string_from_utf8())
	emit_signal("_completed", json.result.choices[0].text)


func prompt(query: String):
	var request_params = {
		"model": "text-davinci-003",
		"prompt": query,
		"max_tokens": 1024,
		"temperature": 0.9,
		"top_p": 1,
		"n": 1,
		"stream": false,
		"logprobs": null,
		"frequency_penalty": 0.5,
		"presence_penalty": 0.5,
		"stop": "",
	}

	var headers = [
		"Authorization: Bearer " + ProjectSettings.get("plugins/chatgpt/openai_api_key"),
		"Content-Type: application/json",
	]

	request_raw(endpoint + "completions", headers, false, HTTPClient.METHOD_POST, JSON.print(request_params).to_utf8())
