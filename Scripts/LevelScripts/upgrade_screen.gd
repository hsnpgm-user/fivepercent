extends Control

# --- UI REFERANSLARI ---
# Sahne ağacındaki Node isimlerine göre buradaki yolları kontrol edebilirsin.
@onready var total_score_label: Label = $MarginContainer/VBoxContainer/TotalScore
@onready var capacity_info_label: Label = $MarginContainer/VBoxContainer/CapasityInfo
@onready var cost_label: Label = $MarginContainer/VBoxContainer/Price
@onready var status_message_label: Label = $MarginContainer/VBoxContainer/StatusMsg
@onready var upgrade_button: Button = $MarginContainer/VBoxContainer/UpgradeButton
@onready var next_run_button: Button = $MarginContainer/VBoxContainer/NextButton

# --- AYARLAR ---
const BASE_UPGRADE_COST: int = 300    # İlk yükseltme maliyeti
const COST_INCREASE_PER_LEVEL: int = 200 # Her seviyede maliyet artışı
const MAX_BAG_CAPACITY: int = 8       # Maksimum çanta slot sınırı

var current_upgrade_cost: int = 300

func _ready() -> void:
	# Sinyal bağlantılarını koda da ekleyelim (Güvenlik için)
	if upgrade_button and not upgrade_button.pressed.is_connected(_on_upgrade_button_pressed):
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
		
	if next_run_button and not next_run_button.pressed.is_connected(_on_next_run_button_pressed):
		next_run_button.pressed.connect(_on_next_run_button_pressed)

	if status_message_label:
		status_message_label.text = ""

	update_ui()

func calculate_current_cost() -> int:
	# Başlangıç kapasitesi 3 kabul edilirse, yapılan upgrade sayısına göre maliyeti hesaplar
	var upgrades_made = max(0, GameManager.max_bag_slot_count - 3)
	return BASE_UPGRADE_COST + (upgrades_made * COST_INCREASE_PER_LEVEL)

func update_ui() -> void:
	current_upgrade_cost = calculate_current_cost()
	
	# 1. Toplam Skor Gösterimi
	if total_score_label:
		total_score_label.text = "🏆 TOPLAM SKOR: " + str(GameManager.survival_points)
		
	# 2. Çanta Kapasitesi Gösterimi
	if capacity_info_label:
		capacity_info_label.text = "📦 Çanta Kapasitesi: " + str(GameManager.max_bag_slot_count) + " / " + str(MAX_BAG_CAPACITY) + " Slot"

	# 3. Maksimum Kapasite veya Maliyet Kontrolü
	if GameManager.max_bag_slot_count >= MAX_BAG_CAPACITY:
		if cost_label:
			cost_label.text = "✨ Maksimum Çanta Seviyesine Ulaşıldı!"
		if upgrade_button:
			upgrade_button.disabled = true
			upgrade_button.text = "MAKSİMUM SEVİYE"
	else:
		if cost_label:
			cost_label.text = "💰 Yükseltme Maliyeti: " + str(current_upgrade_cost) + " Puan"
		
		# Puan yetiyorsa butonu aktif et, yetmiyorsa pasifleştir
		if upgrade_button:
			if GameManager.survival_points >= current_upgrade_cost:
				upgrade_button.disabled = false
				upgrade_button.text = "🎒 ÇANTAYI BÜYÜT (+1 SLOT)"
			else:
				upgrade_button.disabled = true
				upgrade_button.text = "YETERSİZ PUAN"

# --- ÇANTA YÜKSELTME BUTONU ---
func _on_upgrade_button_pressed() -> void:
	# Çift Kontrol: Kapasite ve Puan
	if GameManager.max_bag_slot_count >= MAX_BAG_CAPACITY:
		show_status("Maksimum kapasiteye zaten ulaştın!", false)
		return

	if GameManager.survival_points >= current_upgrade_cost:
		# Puanı düş
		GameManager.survival_points -= current_upgrade_cost
		
		# GameManager'daki çanta kapasitesini artıran fonksiyonu çalıştır
		GameManager.upgrade_bag_capasity()
		
		# Görsel mesaj ver ve arayüzü güncelle
		show_status("✅ Çanta Kapasitesi Başarıyla Artırıldı!", true)
		update_ui()
	else:
		show_status("❌ Yetersiz Puan! Daha fazla afet atlatmalısın.", false)

# --- SONRAKİ TURA GEÇİŞ BUTONU ---
func _on_next_run_button_pressed() -> void:
	# Rastgele yeni bir afet seçip hazırlık/oyun sahnesine geri dönüyoruz
	GameManager.select_random_disaster()
	GameManager.reset_bag_slots()
	GameManager.shuffle_cabinet()
	get_tree().change_scene_to_file("res://Scenes/countdown_screen.tscn") # Ya da "res://Scenes/in_game.tscn"

# Yardımcı Geçici Durum Mesajı
func show_status(msg: String, is_success: bool) -> void:
	if status_message_label:
		status_message_label.text = msg
		# Yeşile veya Kırmızıya boyayabilirsin (Varsayılan font rengi)
		await get_tree().create_timer(2.5).timeout
		if status_message_label and status_message_label.text == msg:
			status_message_label.text = ""
