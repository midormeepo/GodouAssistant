@tool
extends Node

var url: String = "https://ark.cn-beijing.volces.com/api/v3/chat/completions"
var temperature: float = 0.5
var max_tokens: int = 4096
var chat_history = []
var request: HTTPRequest

func _ready():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", _on_request_completed)


func dialogue_request(player_dialogue, settings):
	var headers = ["Content-type: application/json", "Authorization: Bearer " + settings["api-key"]]
	
	var modified_chat_history = chat_history.duplicate()
	
	var context_message: Dictionary
	
	if EditorInterface.get_script_editor().get_open_scripts().is_empty():
		context_message = {
			"role": "user",
			"content": "你是Godot引擎的大师，我正在使用Godot引擎，我使用GDScript代码:\n"
			+ "你的回答请保持简洁精准。"
		}
	else:
		context_message = {
			"role": "user",
			"content": "你是Godot引擎的大师，我正在使用Godot引擎，这是我编写的GDScript代码，请仔细查看:\n"
			+ EditorInterface.get_script_editor().get_current_script().source_code + "\n"
			+ "你的回答请保持简洁精准。"
		}
	
	if chat_history.size() > 4:
		modified_chat_history.resize(4)
	
	modified_chat_history.append(context_message)
	
	chat_history.append({
		"role": "user",
		"content": player_dialogue
	})
	
	modified_chat_history.append({
		"role": "user",
		"content": player_dialogue
	})
	
	var body = JSON.new().stringify({
		"messages": modified_chat_history,
		"temperature": temperature,
		"max_tokens": max_tokens,
		"model": settings["model-id"]
	})
	
	var send_request = request.request(url, headers, HTTPClient.METHOD_POST, body)
	
	if send_request != OK:
		get_parent()._on_request_completed("您的请求发生错误！")
		print("Error!")


func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		get_parent()._on_request_completed("请检查设置信息 \nError: " + str(response_code))
		return
		
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	var message = response["choices"][0]["message"]["content"]
	
	chat_history.append({
		"role": "assistant",
		"content": message
	})
	print(chat_history)
	
	get_parent()._on_request_completed(message)
	
func clear_chat_history():
	chat_history = []
