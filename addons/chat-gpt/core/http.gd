tool
extends HTTPRequest

const endpoint = "https://api.openai.com/v1/"

# USE THIS SIGNALS TO GET RESULTS
signal completions_request_completed(result)
signal images_request_completed(results)

# EXCEPTION SIGNALS
signal error()

# INTERNAL SIGNALS (DON'T USE)
signal image_downloaded(texture)


# CHATBOT
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


# IMAGE GENERATION
func _on_image_generation_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray):
	var json = JSON.parse(body.get_string_from_utf8())
	match response_code:
		200:
			var textures : Array
			for image in json.result.data:
				var image_download = HTTPRequest.new()#http_texture_download.instance()
				add_child(image_download)
				image_download.connect("request_completed", self, "_on_image_download_request_completed")

				var http_error = image_download.request(image.url)
				if http_error == OK:
					var texture = yield(self, "image_downloaded")
					textures.push_back(texture)
					image_download.queue_free()
				else:
					print("An error occurred in the HTTP request.")

			emit_signal("images_request_completed", textures)
		_:
			printerr(JSON.print(json.result.error.message))
			emit_signal("error")


func _on_image_download_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var image_error = image.load_png_from_buffer(body)
	if image_error != OK:
		print("An error occurred while trying to display the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)
	emit_signal("image_downloaded", texture)


func image_generation(prompt: String):
	var request_params = {
		"prompt": prompt,
		"n": 4,
		# Must be one of 256x256, 512x512, or 1024x1024
		"size": "1024x1024",
	}

	var headers = [
		"Authorization: Bearer " + ProjectSettings.get("plugins/chatgpt/openai_api_key"),
		"Content-Type: application/json",
	]

	connect("request_completed", self, "_on_image_generation_request_completed", [], CONNECT_ONESHOT)
	request_raw(endpoint + "images/generations", headers, false, HTTPClient.METHOD_POST, JSON.print(request_params).to_utf8())
