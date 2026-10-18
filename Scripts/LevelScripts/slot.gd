extends PanelContainer

class_name Slot

signal slot_clicked(slot_type, index)

var slot_index: int = -1
var slot_type: String = ""
var slot_item_data: Dictionary = {}

@onready var tooltip_label: Label = $TooltipLabel if has_node("TooltipLabel") else null

@onready var item_icon = $Icon

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Fare giriş/çıkış sinyallerini koda bağlıyoruz
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if tooltip_label:
		tooltip_label.visible = false

func update_slot_data(item_data: Dictionary):
	slot_item_data = item_data
	if item_data.is_empty() or not item_data.has("item_id"):
		leave_empty()
		return
	
	var sprite_path = "res://Assets/Items/" + item_data["item_id"] + ".png"
	item_icon.texture = load(sprite_path)
	item_icon.visible = true
	
	if tooltip_label:
		tooltip_label.text = get_item_display_name(item_data["item_id"])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _on_mouse_entered():
	if slot_item_data.is_empty(): return
	
	# 1. Outline / Parlama hissi için ikonu hafif büyütüp parlatalım (Tween animasyonu)
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(item_icon, "scale", Vector2(1.15, 1.15), 0.15)
	
	# İsteğe bağlı: Mod rengini parlatma (beyazdan hafif sarı/parlak tona)
	tween.tween_property(item_icon, "modulate", Color(1.3, 1.3, 1.3), 0.15)
	
	# 2. Yazıyı göster
	if tooltip_label:
		tooltip_label.visible = true

# --- FARE ÇIKTIĞINDA ---
func _on_mouse_exited():
	if slot_item_data.is_empty(): return
	
	# Eski haline döndür
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(item_icon, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(item_icon, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	
	if tooltip_label:
		tooltip_label.visible = false

func leave_empty():
	slot_item_data = {}
	item_icon.texture = null
	item_icon.visible = false
	if tooltip_label:
		tooltip_label.visible = false
	
func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not slot_item_data.is_empty():
			slot_clicked.emit(slot_type, slot_index)

func remove_background():
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	
func get_item_display_name(item_id: String) -> String:
	match item_id:
		"water": return "Water"
		"con_foods": return "Can Food"
		"flash_light": return "Flashlight"
		"med_kit": return "Med Kit"
		"fire_blanket": return "Fire Blanket"
		"thermal_blanket": return "Thermal Blanket"
		"rubber_boots": return "Rubber Boots"
		"mask": return "Mask"
		"radio": return "Radio"
		"wistel": return "Wistel"
		_: return item_id
