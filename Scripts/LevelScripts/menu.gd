extends Control

@onready var menu_music: AudioStreamPlayer2D = $MenuMusic

# --- DÜĞÜM REFERANSLARI ---
@onready var play_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/OptionsButton
@onready var credits_button: Button = $MarginContainer/VBoxContainer/CreditsButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/ExitButton

# Pop-up / Alt Paneller
@onready var settings_panel: Control = $OptionsPanel if has_node("OptionsPanel") else null
@onready var credits_panel: Control = $CreditsPanel if has_node("CreditsPanel") else null

# Panellerin içindeki bileşenler (Doğru node yolları: OptionsPanel kullanıldı)
@onready var volume_slider: HSlider = $OptionsPanel/VolumeSlider if has_node("OptionsPanel/VolumeSlider") else null
@onready var settings_back_button: Button = $OptionsPanel/BackButton if has_node("OptionsPanel/BackButton") else null
@onready var credits_back_button: Button = $CreditsPanel/BackButton if has_node("CreditsPanel/BackButton") else null

var master_bus_index: int


func _ready() -> void:
	menu_music.play()
	# Master ses otobüsü indeksini alıyoruz
	master_bus_index = AudioServer.get_bus_index("Master")

	if settings_panel: settings_panel.visible = false
	if credits_panel: credits_panel.visible = false

	# VolumeSlider Ayarları (%0 - %200 Ölçeği)
	if volume_slider:
		volume_slider.min_value = 0.0     # %0 (Tam sessiz)
		volume_slider.max_value = 2.0     # %200 (Maksimum seviye, +6 dB)
		volume_slider.step = 0.05
		
		# Mevcut ses seviyesini slider'a aktar
		volume_slider.value = GameManager.master_volume
		_on_volume_slider_value_changed(volume_slider.value)
		
		volume_slider.value_changed.connect(_on_volume_slider_value_changed)

	# Ana Menü Buton Sinyalleri
	if play_button: play_button.pressed.connect(_on_play_button_pressed)
	if settings_button: settings_button.pressed.connect(_on_settings_button_pressed)
	if credits_button: credits_button.pressed.connect(_on_credits_button_pressed)
	if quit_button: quit_button.pressed.connect(_on_quit_button_pressed)

	# Geri Butonları
	if settings_back_button: settings_back_button.pressed.connect(_on_settings_back_pressed)
	if credits_back_button: credits_back_button.pressed.connect(_on_credits_back_pressed)


# --- SES AYARI FONKSİYONU ---
func _on_volume_slider_value_changed(value: float) -> void:
	GameManager.master_volume = value # Değeri GameManager'da sakla
	
	if value <= 0.01:
		# Eğer bar en sol yani 0 ise, sesi doğrudan MUTE (sustur) yap
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		# Değeri dB'e çevirip uygula (1.0 normal sestir, 2.0 %200'dür)
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))


# --- MENÜ AKSİYONLARI ---
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/countdown_screen.tscn")

func _on_settings_button_pressed() -> void:
	if settings_panel: settings_panel.visible = true
	if credits_panel: credits_panel.visible = false

func _on_credits_button_pressed() -> void:
	if credits_panel: credits_panel.visible = true
	if settings_panel: settings_panel.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_settings_back_pressed() -> void:
	if settings_panel: settings_panel.visible = false

func _on_credits_back_pressed() -> void:
	if credits_panel: credits_panel.visible = false
