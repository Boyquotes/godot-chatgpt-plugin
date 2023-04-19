tool
extends HTTPRequest

const endpoint = "https://api.openai.com/v1/"

# USE THIS SIGNALS TO GET RESULTS
signal completions_request_completed(result)
signal image_downloaded(index, texture)

# EXCEPTION SIGNALS
signal error()


# Helper functions
func custom_headers(content_type = "application/json") -> PoolStringArray:
	return PoolStringArray([
		"Authorization: Bearer " + ProjectSettings.get("plugins/chatgpt/openai_api_key"),
		"Content-Type: %s" % content_type,
	])


func multipart_body(time_boundary: String, request_params: Dictionary) -> PoolByteArray:
	var body : PoolByteArray
	for k in request_params.keys():
		var v = request_params[k]

		body.append_array(String("--" + time_boundary).to_utf8())
		body.append_array(String("\r\nContent-Disposition: form-data; name=\"%s\"" % k).to_utf8())

		if v is Image:
			body.append_array(String("; filename=\"test.png\"").to_utf8())

		body.append_array(String("\r\n\r\n").to_utf8())

		if v is Image:
			body.append_array(v.save_png_to_buffer())
		else:
			body.append_array(String(v).to_utf8())

		body.append_array("\r\n".to_utf8())

	if not body.empty():
		body.append_array(String("--" + time_boundary + "--").to_utf8())

	return body


func download_image(index: int, url: String):
	var http = HTTPRequest.new()
	add_child(http)
	var http_error = http.request(url)

	if http_error == OK:
		var result = yield(http, "request_completed")

		var image = Image.new()
		var image_error = image.load_png_from_buffer(result[3])
		if image_error != OK:
			print("An error occurred while trying to display the image.")
		else:
			var texture = ImageTexture.new()
			texture.create_from_image(image)
			emit_signal("image_downloaded", index, texture)
	else:
		print("An error occurred in the HTTP request.")

	http.queue_free()


func _on_request_completed(result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray, callback: String):
	var json = JSON.parse(body.get_string_from_utf8())
	match response_code:
		200:
			call(callback, json.result)
		401:
			printerr("You didn't provide an OpenAI API key. You can obtain an API key from https://platform.openai.com/account/api-keys. Then set it up in Project Settings -> Plugins -> Chatgpt -> openai_api_key")
			emit_signal("error")
		_:
			printerr(JSON.print(json.result.error.message))
			emit_signal("error")


# CHATBOT
func _on_completions_request_completed(result):
	emit_signal("completions_request_completed", result.choices[0].text)


func completions(prompt: String):
	var request_params = {
		"model": "text-davinci-003",
		"prompt": prompt,
		"max_tokens": 1920,
		"temperature": 0,
		"top_p": 1,
		"best_of": 5,
		"frequency_penalty": 0.5,
		"presence_penalty": 0.5,
	}

	connect("request_completed", self, "_on_request_completed", ["_on_completions_request_completed"], CONNECT_ONESHOT)
	request_raw(endpoint + "completions", custom_headers(), false, HTTPClient.METHOD_POST, JSON.print(request_params).to_utf8())


# IMAGE GENERATION
func _on_image_request_completed(result):
	var textures : Array
	for i in range(result.data.size()):
		download_image(i, result.data[i].url)


func image_generation(prompt: String):
	var request_params = {
		"prompt": prompt,
		"n": 4,

		# Must be one of 256x256, 512x512, or 1024x1024
		"size": "1024x1024",
	}

	connect("request_completed", self, "_on_request_completed", ["_on_image_request_completed"], CONNECT_ONESHOT)
	request_raw(endpoint + "images/generations", custom_headers(), false, HTTPClient.METHOD_POST, JSON.print(request_params).to_utf8())


func image_variation(image: Image):
	var time_boundary = "--" + String(Time.get_ticks_msec())
	var request_params = {
		"image": image,
		"n": 4,

		# Must be one of 256x256, 512x512, or 1024x1024
		"size": "1024x1024",
	}
	var body = multipart_body(time_boundary, request_params)

	connect("request_completed", self, "_on_request_completed", ["_on_image_request_completed"], CONNECT_ONESHOT)
	request_raw(endpoint + "images/variations", custom_headers("multipart/form-data; boundary=" + time_boundary), false, HTTPClient.METHOD_POST, body)


func image_edit(prompt: String, image: Image, mask: Image):
	var time_boundary = "--" + String(Time.get_ticks_msec())
	var request_params = {
		"prompt": prompt,
		"image": image,
		"mask": mask,
		"n": 4,

		# Must be one of 256x256, 512x512, or 1024x1024
		"size": "1024x1024",
	}
	var body = multipart_body(time_boundary, request_params)

	connect("request_completed", self, "_on_request_completed", ["_on_image_request_completed"], CONNECT_ONESHOT)
	request_raw(endpoint + "images/edits", custom_headers("multipart/form-data; boundary=" + time_boundary), false, HTTPClient.METHOD_POST, body)

