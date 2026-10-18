extends Control

var time_left: float = 0

@onready var disaster_name: Label = $AfterCoundown/DisasterName
@onready var before_countdown: Control = $BeforeCountdown
@onready var after_countdown: Control = $AfterCoundown
@onready var custom_timer: Timer = $WaitTime
@onready var timer: Timer = $MainCountdown
@onready var label: Label = $BeforeCountdown/TimeOnScreen

@onready var disaster_texture_rect: TextureRect = $AfterCoundown/TextureRect

# Görsellerin dosya yollarını preload ile yükleyelim (Game Jam için en güvenli yol)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	time_left = timer.wait_time + 1
	timer.timeout.connect(_on_main_timer_timeout)
	timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not timer.is_stopped():
		time_left = timer.time_left +1
		label.text = str(int(time_left))

func prepare_custom_timer(waiting_time: float, is_OneShot: bool, on_timeout_callback: Callable):
	custom_timer.wait_time = waiting_time
	custom_timer.one_shot = is_OneShot
	custom_timer.timeout.connect(on_timeout_callback)
	if is_OneShot:
		custom_timer.timeout.connect(func(): custom_timer.timeout.disconnect(on_timeout_callback), CONNECT_ONE_SHOT)
	custom_timer.start()

func switch_to_preview_screen():
	update_disaster_visual()
	before_countdown.visible = false
	after_countdown.visible = true
		
	prepare_custom_timer(2, true, change_scene)

func change_scene():
	get_tree().change_scene_to_file("res://Scenes/prepare.tscn")

func _on_main_timer_timeout():
	label.text = "Time is Up"
	GameManager.select_random_disaster()
	prepare_custom_timer(0.5, true, switch_to_preview_screen)
	
func update_disaster_visual():
	match GameManager.current_disaster:
		GameManager.DisasterType.Earthquake:
			disaster_texture_rect.texture = GameManager.tex_earthquake
			disaster_name.text = "Earthquake"
			
		GameManager.DisasterType.Flood:
			disaster_texture_rect.texture = GameManager.tex_flood
			disaster_name.text = "Flood"
			
		GameManager.DisasterType.Avalanche:
			disaster_texture_rect.texture = GameManager.tex_avalanche
			disaster_name.text = "Avalanche"
			
		GameManager.DisasterType.Fire:
			disaster_texture_rect.texture = GameManager.tex_fire
			disaster_name.text = "Fire"
