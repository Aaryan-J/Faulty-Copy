extends Control

# ui text references
@onready var left_stats_label: Label = $HBoxContainer/LeftPerson/VBoxContainer/LeftStats
@onready var right_stats_label: Label = $HBoxContainer/RightPerson/VBoxContainer/RightStats
@onready var score_label: Label = $ScoreLabel
@onready var left_btn: TextureButton = $HBoxContainer/LeftPerson/VBoxContainer/LeftPortrait
@onready var right_btn: TextureButton = $HBoxContainer/RightPerson/VBoxContainer/RightPortrait

# ui references
@onready var left_base: TextureRect = $HBoxContainer/LeftPerson/VBoxContainer/LeftPortrait/LeftBase
@onready var left_hair: TextureRect = $HBoxContainer/LeftPerson/VBoxContainer/LeftPortrait/LeftHair
@onready var left_eyes: TextureRect = $HBoxContainer/LeftPerson/VBoxContainer/LeftPortrait/LeftEyes

@onready var right_base: TextureRect = $HBoxContainer/RightPerson/VBoxContainer/RightPortrait/RightBase
@onready var right_hair: TextureRect = $HBoxContainer/RightPerson/VBoxContainer/RightPortrait/RightHair
@onready var right_eyes: TextureRect = $HBoxContainer/RightPerson/VBoxContainer/RightPortrait/RightEyes

# audio references
@onready var gunAudio: AudioStreamPlayer2D = $GunAudio
@onready var click_audio: AudioStreamPlayer2D = $ClickAudio
@onready var bg_music: AudioStreamPlayer = $BGMusic


# misc references
@onready var left_red_flash: ColorRect = $HBoxContainer/LeftPerson/LeftRedFlash
@onready var right_red_flash: ColorRect = $HBoxContainer/RightPerson/RightRedFlash

#  cinematic overlay
@onready var cinematic_overlay: ColorRect = $CinematicOverlay
@onready var cinematic_label: Label = $CinematicOverlay/CenterContainer/CinematicLabel

# main menu references
@onready var main_menu_overlay: Control = $MainMenuOverlay
@onready var start_button: Button = $MainMenuOverlay/VBoxContainer/StartButton

# game over references
@onready var game_over_overlay: Control = $GameOverOverlay
@onready var home_button: Button = $GameOverOverlay/VBoxContainer/HomeButton

# label floaty stuff
var time_passed: float = 0.0
@onready var menu_title_label: Label = $MainMenuOverlay/VBoxContainer/TitleLabel
@onready var game_over_title_label: Label = $GameOverOverlay/VBoxContainer/GameOverLabel

# tutorial menu
@onready var protocol_btn: Button = $MainMenuOverlay/ProtocolBtn
@onready var protocol_panel: PanelContainer = $MainMenuOverlay/ProtocolPanel

# --- art assets ---

# hair
var hair_options = [
	preload("res://Assets/human_hair_1.png"),
	preload("res://Assets/human_hair_2.png"),
	preload("res://Assets/human_hair_3.png"),
	preload("res://Assets/human_hair_4.png")
]

# human eyess
var human_eye_options = [
	preload("res://Assets/human_eyes_1.png"),
	preload("res://Assets/human_eyes_2.png")
]

# alien eyes
var alien_eye_options = [
	preload("res://Assets/alien_eyes_1.png"),
	preload("res://Assets/alien_eyes_2.png")
]

var img_base = preload("res://Assets/base.png")

# game state teracking
var left_is_alien: bool = false
var current_level: int = 1  
var is_game_over: bool = false

var human_names = ["John", "Sarah", "Alex", "Elena", "Marcus", "Chloe"]
var jobs = ["Engineer", "Chef", "Doctor", "Artist", "Teacher", "Pilot"]

var shake_intensity: float = 0.0
var original_container_position: Vector2 = Vector2.ZERO

# history tracking so that back to back levels dont have duplicate features
var last_hair: Texture2D = null
var last_human_eyes: Texture2D = null
var last_alien_eyes: Texture2D = null
var last_stat_sabotaged: int = -1

var skip_requested: bool = false

var reached_true_ending: bool = false

func _ready() -> void:
	# get player input
	left_btn.pressed.connect(_on_kill_left_pressed)
	right_btn.pressed.connect(_on_kill_right_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)
	
	start_button.pivot_offset = start_button.size / 2.0
	home_button.pivot_offset = home_button.size / 2.0
	
	# button anims
	start_button.mouse_entered.connect(func(): 
		create_tween().tween_property(start_button, "scale", Vector2(1.05, 1.05), 0.1)
	)
	start_button.mouse_exited.connect(func(): 
		create_tween().tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	home_button.mouse_entered.connect(func(): 
		create_tween().tween_property(home_button, "scale", Vector2(1.05, 1.05), 0.1)
	)
	home_button.mouse_exited.connect(func(): 
		create_tween().tween_property(home_button, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	# portrait anims
	left_btn.mouse_entered.connect(func(): 
		click_audio.play() # play click sound
		var t = create_tween()
		t.tween_property(left_btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	left_btn.mouse_exited.connect(func(): 
		click_audio.play()
		var t = create_tween()
		t.tween_property(left_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	
	right_btn.mouse_entered.connect(func(): 
		var t = create_tween()
		t.tween_property(right_btn, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	right_btn.mouse_exited.connect(func(): 
		var t = create_tween()
		t.tween_property(right_btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	
	# -- tutorial button stuff --
	protocol_btn.pressed.connect(_on_protocol_button_pressed)
	
	# button anims
	protocol_btn.focus_mode = Control.FOCUS_NONE
	protocol_btn.pivot_offset = protocol_btn.size / 2.0
	protocol_btn.mouse_entered.connect(func(): 
		create_tween().tween_property(protocol_btn, "scale", Vector2(1.05, 1.05), 0.1)
	)
	protocol_btn.mouse_exited.connect(func(): 
		create_tween().tween_property(protocol_btn, "scale", Vector2(1.0, 1.0), 0.1)
	)

	# initialize everything
	randomize()
	original_container_position = $HBoxContainer.position
	show_main_menu()

func show_main_menu() -> void:
	is_game_over = true # freeze gameplay inputs while on the main menu
	main_menu_overlay.visible = true
	game_over_overlay.visible = false
	cinematic_overlay.visible = false
	protocol_panel.visible = false 
	$ScoreLabel.text = ""
	if not bg_music.playing:
		bg_music.play()

func start_game() -> void:
	current_level = 1
	is_game_over = false
	left_btn.disabled = false   
	right_btn.disabled = false
	left_btn.focus_mode = Control.FOCUS_NONE
	right_btn.focus_mode = Control.FOCUS_NONE
	
	left_btn.pivot_offset = left_btn.size / 2.0
	right_btn.pivot_offset = right_btn.size / 2.0

	main_menu_overlay.visible = false
	game_over_overlay.visible = false
	cinematic_overlay.visible = false
	play_story_intro()
	
func _on_home_button_pressed() -> void:
	click_audio.play()
	$GameOverOverlay/VBoxContainer/GameOverLabel.text = "AGENT TERMINATED"
	game_over_overlay.visible = false
	show_main_menu()

func _on_start_button_pressed() -> void:
	click_audio.play()
	main_menu_overlay.visible = false
	start_game()

func generate_round() -> void:
	if is_game_over: return
		
	if current_level <= 11:
		score_label.text = "Threat Level: " + str(current_level) + " / 11"
		left_is_alien = randf() > 0.5
		
		var name_choice = human_names.pick_random()
		var job_choice = jobs.pick_random()
		
		# choose random art
		var shared_hair = hair_options.pick_random()
		while shared_hair == last_hair and hair_options.size() > 1:
			shared_hair = hair_options.pick_random()
			
		var chosen_human_eyes = human_eye_options.pick_random()
		while chosen_human_eyes == last_human_eyes and human_eye_options.size() > 1:
			chosen_human_eyes = human_eye_options.pick_random()
			
		var chosen_alien_eyes = alien_eye_options.pick_random()
		while chosen_alien_eyes == last_alien_eyes and alien_eye_options.size() > 1:
			chosen_alien_eyes = alien_eye_options.pick_random()
			
		last_hair = shared_hair
		last_human_eyes = chosen_human_eyes
		last_alien_eyes = chosen_alien_eyes

		# healthy human baselines 
		var h_temp = randf_range(36.4, 37.2)
		var h_blink = randi_range(12, 20)
		var h_ox = randi_range(95, 99)
		var h_pupil = randf_range(2.0, 4.0)
		var h_blood = "DARK CRIMSON"
		
		var a_temp = h_temp
		var a_blink = h_blink
		var a_ox = h_ox
		var a_pupil = h_pupil
		var a_blood = h_blood
		
		# this makes sure that no continous levels dont have the same anomalies
		var stat_layout_slot = randi_range(1, 4)
		while stat_layout_slot == last_stat_sabotaged:
			stat_layout_slot = randi_range(1, 4)
		last_stat_sabotaged = stat_layout_slot
		
		# --- difficulty increase ---
		if current_level <= 3:
			# --- easy mode ---
			match stat_layout_slot:
				1:
					a_temp = h_temp + randf_range(15.0, 25.0)
					a_blink = h_blink + 40
					a_blood = ["OXIDIZED GREEN", "COBALT BLUE"].pick_random()
				2:
					a_ox = randi_range(30, 50)
					a_pupil = 8.5
					a_blood = ["AMBER TRACES", "PALE CHROMIUM"].pick_random()
				3:
					a_temp = h_temp + randf_range(15.0, 25.0)
					a_ox = randi_range(30, 50)
					a_pupil = 0.5
				4:
					a_blink = h_blink + 50
					a_pupil = 9.0
					a_blood = ["OXIDIZED GREEN", "PALE CHROMIUM"].pick_random()
			
		elif current_level <= 6:
			# --- medium mode ---
			match stat_layout_slot:
				1:
					a_blink = 0
					a_ox = randi_range(50, 70)
				2:
					a_temp = h_temp + 12.0
					a_blood = "PALE CHROMIUM"
				3:
					a_ox = randi_range(50, 70)
					a_pupil = 8.5
				4:
					a_temp = h_temp + 12.0
					a_blink = 0
			
		elif current_level <= 9:
			# --- hard mode ---
			match stat_layout_slot:
				1: a_temp = h_temp + 12.0                  
				2: a_blink = 0                             
				3: a_ox = randi_range(40, 60)              
				4: a_pupil = 8.5                           
				
		else:
			# --- expert mode (harder than hard mode) ---
			match stat_layout_slot:
				1: a_temp = 37.6 # human max is 37.2
				2: a_blink = 24  # human max is 20
				3: a_ox = 93     # human min is 95
				4: a_pupil = 4.6 # human max is 4.0

		# format ui float
		var h_temp_str = "%.1f" % h_temp
		var a_temp_str = "%.1f" % a_temp
		var h_pupil_str = "%.1f" % h_pupil
		var a_pupil_str = "%.1f" % a_pupil
		
		# human stats text block
		var human_text = "SUBJECT: " + name_choice + "\n"
		human_text += "OCCUPATION: " + job_choice + "\n"
		human_text += "BODY TEMP: " + h_temp_str + "°C\n"
		human_text += "BLINK RATE: " + str(h_blink) + " / MIN\n"
		human_text += "O2 PULSE: " + str(h_ox) + "%\n"
		human_text += "PUPIL SIZE: " + h_pupil_str + " mm\n"
		human_text += "BLOOD CORE: " + h_blood

		# alient stats text block
		var alien_text = "SUBJECT: " + name_choice + "\n"
		alien_text += "OCCUPATION: " + job_choice + "\n"
		alien_text += "BODY TEMP: " + a_temp_str + "°C\n"
		alien_text += "BLINK RATE: " + str(a_blink) + " / MIN\n"
		alien_text += "O2 PULSE: " + str(a_ox) + "%\n"
		alien_text += "PUPIL SIZE: " + a_pupil_str + " mm\n"
		alien_text += "BLOOD CORE: " + a_blood
		
		var show_alien_eyes: bool = (current_level <= 3)
		
		if left_is_alien:
			left_stats_label.text = alien_text
			right_stats_label.text = human_text
			apply_visuals(true, shared_hair, chosen_alien_eyes if show_alien_eyes else chosen_human_eyes)
			apply_visuals(false, shared_hair, chosen_human_eyes) 
		else:
			left_stats_label.text = human_text
			right_stats_label.text = alien_text
			apply_visuals(true, shared_hair, chosen_human_eyes)
			apply_visuals(false, shared_hair, chosen_alien_eyes if show_alien_eyes else chosen_human_eyes)

	elif current_level == 12:
		score_label.text = "[ ERR: OFFLINE // LOCAL_THREAT_DETECTED ]"
		left_is_alien = true 
		
		left_stats_label.text = "NAME: YOU\nJOB: AGENT\nBODY TEMP: 0.0°C\nBLINK RATE: 0 / MIN\nO2 PULSE: 0%\nPUPIL SIZE: 0.0 mm\nBLOOD CORE: UNKNOWN"
		right_stats_label.text = "NAME: YOU\nJOB: AGENT\nBODY TEMP: 36.6°C\nBLINK RATE: 14 / MIN\nO2 PULSE: 98%\nPUPIL SIZE: 3.1 mm\nBLOOD CORE: DARK CRIMSON"
		
		apply_visuals(true, hair_options, alien_eye_options)
		apply_visuals(false, hair_options, human_eye_options)

# refactor renderer
func apply_visuals(is_left_side: bool, hair: Texture2D, eyes: Texture2D) -> void:
	if is_left_side:
		left_base.texture = img_base
		left_hair.texture = hair
		left_eyes.texture = eyes
	else:
		right_base.texture = img_base
		right_hair.texture = hair
		right_eyes.texture = eyes

func _on_kill_left_pressed() -> void:
	gunAudio.play()
	trigger_screen_shake(15)
	if is_game_over: return
	handle_choice(true)

func _on_kill_right_pressed() -> void:
	gunAudio.play()
	trigger_screen_shake(15)
	if is_game_over: return
	handle_choice(false)

func handle_choice(chose_left: bool) -> void:
	var correct_guess = (chose_left == left_is_alien)
	if current_level == 12:
		if correct_guess: 
			trigger_secret_ending()
		else:
			trigger_alien_victory_ending()
	else:
		if correct_guess:
			current_level += 1
			check_story_milestones()
		else:
			trigger_death_scene(chose_left)

# --- cutscene anims ---
func fade_in_sentences(sentences: Array[String]) -> void:
	# reset flags
	skip_requested = false
	cinematic_label.text = ""
	cinematic_label.modulate = Color(1, 1, 1, 0)
	
	for sentence in sentences:
		if sentence.strip_edges() == "": continue
		
		cinematic_label.text += sentence + "."
		
		var fade_tween = create_tween()
		fade_tween.tween_property(cinematic_label, "modulate", Color(1, 1, 1, 1), 0.5)
		
		# handle skips
		while fade_tween.is_running():
			if skip_requested:
				fade_tween.kill()
				cinematic_label.modulate = Color(1, 1, 1, 1)
				break
			await get_tree().create_timer(0.02).timeout
			
		var read_timer = 0.0
		while read_timer < 2.5:
			if skip_requested:
				break
			read_timer += 0.05
			await get_tree().create_timer(0.05).timeout
			
		# reset flag
		if skip_requested:
			skip_requested = false

# --- handle death and endings ---
func trigger_death_scene(was_left: bool) -> void:
	is_game_over = true
	left_btn.disabled = true
	right_btn.disabled = true
	
	if was_left: left_red_flash.visible = true
	else: right_red_flash.visible = true
	
	await get_tree().create_timer(2.0).timeout
	
	left_red_flash.visible = false
	right_red_flash.visible = false
	cinematic_overlay.visible = true
	
	var death_text: Array[String] = [
		"YOU KILLED A HUMAN",
		"\n\nThe real alien screeches and lunges forward",
		"\n\nYou are devoured alive"
	]
	await fade_in_sentences(death_text)
	
	cinematic_overlay.visible = false
	game_over_overlay.visible = true

func trigger_alien_victory_ending() -> void:
	is_game_over = true
	left_btn.disabled = true
	right_btn.disabled = true
	
	await get_tree().create_timer(2.0).timeout
	cinematic_overlay.visible = true
	
	var alien_win_text: Array[String] = [
		"You shot your own human clone",
		"\n\nYour inner extraterrestrial instincts completely take over",
		"\n\nYou feast on the last surviving organic lifeform"
	]
	await fade_in_sentences(alien_win_text)
	
	cinematic_overlay.visible = false
	game_over_overlay.visible = true

func trigger_secret_ending() -> void:
	is_game_over = true
	left_btn.disabled = true
	right_btn.disabled = true
	
	left_stats_label.text = ""
	right_stats_label.text = ""
	apply_visuals(true, null, null)
	apply_visuals(false, null, null)
	left_base.texture = null
	right_base.texture = null
	
	await get_tree().create_timer(2.0).timeout
	cinematic_overlay.visible = true
	
	var twist_text: Array[String] = [
		"*BANG*",
		"\n*THUD*",
		"\n\n\nTrust no one",
		"\n\n\nNot even yourself"
	]
	await fade_in_sentences(twist_text)
	
	reached_true_ending = true
	
	$GameOverOverlay/VBoxContainer/GameOverLabel.text = "THANKS FOR PLAYING"
	
	await get_tree().create_timer(3.0).timeout
	cinematic_overlay.visible = false
	game_over_overlay.visible = true

#  screen shake (shakira)
func _process(delta: float) -> void:
	time_passed += delta
	
	# moves text up and down in main menu and other screens (sin wave thingy)
	var vertical_float_offset = sin(time_passed * 2.0) * 8.0
	
	# apply the sin wave thingy
	if main_menu_overlay.visible and menu_title_label:
		menu_title_label.position.y = vertical_float_offset
		
	if game_over_overlay.visible and game_over_title_label:
		game_over_title_label.position.y = vertical_float_offset
	
	if shake_intensity > 0.0:
		var random_offset_x = randf_range(-shake_intensity, shake_intensity)
		var random_offset_y = randf_range(-shake_intensity, shake_intensity)
		
		$HBoxContainer.position = original_container_position + Vector2(random_offset_x, random_offset_y)
		shake_intensity = move_toward(shake_intensity, 0.0, delta * 80.0)
	else:
		$HBoxContainer.position = original_container_position

func trigger_screen_shake(amount: float) -> void:
	shake_intensity = amount
	
func play_story_intro():
	is_game_over = true # freeze input during cutscenes
	cinematic_overlay.visible = true
	
	var intro_text: Array[String] = [
		"BUNKER LEVEL 4 - OUTPOST OMEGA",
		"\n\nAnomalous shape-shifters have infiltrated the staff",
		"\n\nReview the biometric data on your inspection desk",
		"\n\nTrust your instruments. Eliminate the duplicates"
	]
	await fade_in_sentences(intro_text)
	
	cinematic_overlay.visible = false
	is_game_over = false
	generate_round()

func check_story_milestones() -> void:
	if current_level == 4:
		is_game_over = true
		cinematic_overlay.visible = true
		
		var mid_text: Array[String] = [
			"INCOMING TRANSMISSION FROM COMMAND...",
			"\n\n'Agent, be advised'",
			"\n\nThe entities are adapting to our diagnostic scans",
			"\n\nMultiple anomalies are fading. Check the logs closer"
		]
		await fade_in_sentences(mid_text)
		
		cinematic_overlay.visible = false
		is_game_over = false
		generate_round()
		
	elif current_level == 7:
		is_game_over = true
		cinematic_overlay.visible = true
		
		var pre_hard_text: Array[String] = [
			"WARNING: OUTPOST IS UNDER TOTAL LOCKDOWN",
			"\n\nBio-scans are failing across all lower decks",
			"\n\nAnomalies are now near-microscopic",
			"\n\nOne mistake will breach the bunker core"
		]
		await fade_in_sentences(pre_hard_text)
		
		cinematic_overlay.visible = false
		is_game_over = false
		generate_round()
		
	elif current_level == 12:
		is_game_over = true
		cinematic_overlay.visible = true
		
		var critical_text: Array[String] = [
			"ALERT: TERMINAL DATA DISCONNECTED",
			"\n\nSYSTEM WARNING: SENSOR ARRAYS TAMPERED WITH",
			"\n\n\nCRITICAL ERROR: THREAT IS INSIDE THE ROOM", # climax text
			"\n\n   'I was an anomaly all along?...'"
		]
		await fade_in_sentences(critical_text)
		
		# show final round
		cinematic_overlay.visible = false
		is_game_over = false
		generate_round()
		
	else:
		generate_round()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if cinematic_overlay.visible:
			skip_requested = true

# tutorial toggling handler
func _on_protocol_button_pressed() -> void:
	click_audio.play()
	protocol_panel.visible = !protocol_panel.visible
