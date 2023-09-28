extends Control

@onready var status_panel=$LoginPanel/StatusPanel

func register_and_login():
	var email=$LoginPanel/UsernameContainer/Username.text
	var password=$LoginPanel/PasswordContainer/Password.text
	
	status_panel.text="认证用户: %s." % email
	var result=await ServerConnection.authenticate_async(email,password)
	
	if result==OK:
		status_panel.text="成功认证用户 %s." % email
	else:
		status_panel.text="认证用户 %s 失败, 请检查邮箱格式并使用八位数以上密码登录." % email
		return
		
	await connect_to_server()
	await join_world()
	
	create_fish_and_join_game()	


func connect_to_server():
	var result=await ServerConnection.connect_to_server_async()
	if result==OK:
		status_panel.text="连接到Nakama服务器."
	elif ERR_CANT_CONNECT:
		status_panel.text="连接Nakama服务器失败，请检查网络情况或联系站长."
		return

func join_world():
	var presences=await ServerConnection.join_world_async()
	print("Joined World.")
	print("Other connected players: %s" % presences.size())

func create_fish_and_join_game():
	var charactersData=await ServerConnection.read_characters_async()
	if charactersData.size()>0:
		print("Characters:")
		for character in charactersData:
			print("Character Name: %s" % character.name)
		get_tree().change_scene_to_file("res://fish_tank.tscn")
		ServerConnection.send_spawn(charactersData[0].name)
	else:
		var loginPanel=$LoginPanel
		loginPanel.hide()
		var fishCreatePanel=$FishCreatePanel
		fishCreatePanel.show()


func _on_join_idle_button_down():
	register_and_login()

func _on_join_tank_button_down():
	var fishName=$FishCreatePanel/FishContainer/FishName.text
	if fishName!="":
		var characters=[
			{name=fishName}
		]
		await ServerConnection.write_characters_async(characters)
		print("Fish added: "+fishName)
		get_tree().change_scene_to_file("res://fish_tank.tscn")
		ServerConnection.send_spawn(fishName)
	
func _on_password_text_submitted(new_text):
	register_and_login()
