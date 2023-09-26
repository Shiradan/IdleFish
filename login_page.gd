extends Control

	

func _on_join_idle_button_down():
	var email=$LoginPanel/UsernameContainer/Username.text
	var password=$LoginPanel/PasswordContainer/Password.text
	
	print("Authenticating user %s." % email)
	var result=await ServerConnection.authenticate_async(email,password)
	
	if result==OK:
		print("Authenticated user %s successfully." % email)
	else:
		print("Failed to authenticate user %s." % email)
		
	await connect_to_server()
	await join_world()
	
	create_fish_and_join_game()	


func connect_to_server():
	var result=await ServerConnection.connect_to_server_async()
	if result==OK:
		print("Connected to Nakama Server.")
	elif ERR_CANT_CONNECT:
		print("Failed to connect to Nakama Server.")

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
	
