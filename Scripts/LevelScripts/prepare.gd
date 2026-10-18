extends Control

@onready var backpack_audio_player: AudioStreamPlayer2D = $Backpack
@onready var siren: AudioStreamPlayer2D = $Alarm

@onready var slot_points = $SlotPoints.get_children()
@onready var bag_grid = $BagGrid
var slot_scene = preload("res://Scenes/slot.tscn")

var time_left: float = 10

@onready var prepare_time: Timer = $PrepareTime
@onready var countdown: Label = $Countdown

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	siren.play()
	GameManager.reset_bag_slots()
	GameManager.shuffle_cabinet()
	time_left = prepare_time.wait_time + 1
	prepare_time.timeout.connect(_on_timer_timeout)
	prepare_time.start()
	draw_slots()
	draw_bag_slots()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not prepare_time.is_stopped():
		time_left = prepare_time.time_left + 1
		countdown.text = str(int(time_left))

func draw_bag_slots():
	for child in bag_grid.get_children():
		child.queue_free()
	
	for i in range(GameManager.bag_slots.size()):
		var slot_data = GameManager.bag_slots[i]
		
		var new_slot = slot_scene.instantiate() as Slot
		new_slot.slot_index = i
		new_slot.slot_type = "bag"
		new_slot.slot_clicked.connect(_on_slot_clicked)
		
		bag_grid.add_child(new_slot)
		new_slot.update_slot_data(slot_data)

func draw_slots():
	for i in slot_points:
		for child in i.get_children():
			child.queue_free()
			
	for i in range(GameManager.cabinet_slots.size()):
		if i >= slot_points.size(): break
		
		var slot_data = GameManager.cabinet_slots[i]
		var aimed_slot = slot_points[i]
		
		var new_slot = slot_scene.instantiate() as Slot
		new_slot.slot_index = i
		new_slot.slot_type = "cabinet"
		new_slot.remove_background()
		
		new_slot.slot_clicked.connect(_on_slot_clicked)
		
		aimed_slot.add_child(new_slot)
		
		new_slot.update_slot_data(slot_data)

func _on_slot_clicked(slot_type: String, index: int):
	if slot_type == "cabinet":
		var success = GameManager.add_to_bag_slot(index)
		if success:
			play_sfx()
	elif slot_type == "bag":
		var success = GameManager.remove_from_bag_slot(index)
		if success:
			play_sfx()
	
	
	draw_slots()
	draw_bag_slots()

func _on_timer_timeout():
	get_tree().change_scene_to_file("res://Scenes/in_game.tscn")

func play_sfx():
	if not backpack_audio_player: return
	
	# Rastgele pitch ekleyen tek satır:
	backpack_audio_player.pitch_scale = randf_range(0.9, 1.1)
	backpack_audio_player.play()
