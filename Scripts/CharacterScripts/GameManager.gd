extends Node

enum DisasterType {Earthquake, Flood, Avalanche, Fire}
var current_disaster: DisasterType = DisasterType.Earthquake

var tex_earthquake = preload("res://Assets/disasters/earthquake.png")
var tex_flood = preload("res://Assets/disasters/flood.png")
var tex_avalanche = preload("res://Assets/disasters/avalanche.png")
var tex_fire = preload("res://Assets/disasters/fire.png")

var tex_ch_earthquake = preload("res://Assets/disasters/earthquake_body.png")
var tex_ch_flood = preload("res://Assets/disasters/flood_body.png")
var tex_ch_avalanche = preload("res://Assets/disasters/avalanche_body.png")
var tex_ch_fire = preload("res://Assets/disasters/fire_body.png")

var max_bag_slot_count: int = 3
var survival_points: int = 700
var cabinet_slots: Array = []
var bag_slots: Array = []

var player_stats: Dictionary = {
	"hunger": 100,
	"thirst": 100,
	"temperature": 100,
	"health": 100
}

# --- BU DİZİYİ GAMEMANAGER İÇİNDEKİ ESKİ all_item_pool İLE DEĞİŞTİR ---
var all_item_pool: Array = [
	{ 
		"item_id": "water", 
		"count": 2,
		"thirst_restore": 40,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 10 },
			DisasterType.Flood: { "stat": "health", "val": -15 },
			DisasterType.Avalanche: { "stat": "temperature", "val": -20 },
			DisasterType.Fire: { "stat": "health", "val": 20 }
		}
	},
	{ 
		"item_id": "con_foods", 
		"count": 2,
		"hunger_restore": 40,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 15 },
			DisasterType.Flood: { "stat": "health", "val": 10 },
			DisasterType.Avalanche: { "stat": "health", "val": 20 },
			DisasterType.Fire: { "stat": "health", "val": -10 }
		}
	},
	{ 
		"item_id": "flash_light", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 15 },
			DisasterType.Flood: { "stat": "health", "val": 0 },
			DisasterType.Avalanche: { "stat": "health", "val": 10 },
			DisasterType.Fire: { "stat": "health", "val": -10 }
		}
	},
	{ 
		"item_id": "med_kit", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 30 },
			DisasterType.Flood: { "stat": "health", "val": 25 },
			DisasterType.Avalanche: { "stat": "health", "val": 25 },
			DisasterType.Fire: { "stat": "health", "val": 30 }
		}
	},
	{ 
		"item_id": "fire_blanket", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 5 },
			DisasterType.Flood: { "stat": "health", "val": 0 },
			DisasterType.Avalanche: { "stat": "temperature", "val": 15 },
			DisasterType.Fire: { "stat": "health", "val": 35 } # Yangında hayat kurtarır
		}
	},
	{ 
		"item_id": "thermal_blanket", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 5 },
			DisasterType.Flood: { "stat": "temperature", "val": 15 },
			DisasterType.Avalanche: { "stat": "temperature", "val": 35 }, # Çığda hayat kurtarır
			DisasterType.Fire: { "stat": "temperature", "val": -10 }
		}
	},
	{ 
		"item_id": "rubber_boots", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 5 },
			DisasterType.Flood: { "stat": "health", "val": 30 }, # Selde hayat kurtarır
			DisasterType.Avalanche: { "stat": "health", "val": 10 },
			DisasterType.Fire: { "stat": "health", "val": 0 }
		}
	},
	{ 
		"item_id": "mask", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 15 },
			DisasterType.Flood: { "stat": "health", "val": 5 },
			DisasterType.Avalanche: { "stat": "health", "val": -5 },
			DisasterType.Fire: { "stat": "health", "val": 30 }
		}
	},
	{ 
		"item_id": "radio", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 10 },
			DisasterType.Flood: { "stat": "health", "val": 10 },
			DisasterType.Avalanche: { "stat": "health", "val": 10 },
			DisasterType.Fire: { "stat": "health", "val": 10 }
		}
	},
	{ 
		"item_id": "wistel", 
		"count": 1,
		"effects": {
			DisasterType.Earthquake: { "stat": "health", "val": 20 },
			DisasterType.Flood: { "stat": "health", "val": 15 },
			DisasterType.Avalanche: { "stat": "health", "val": 20 },
			DisasterType.Fire: { "stat": "health", "val": 10 }
		}
	}
]

# --- BU DİZİYİ GAMEMANAGER İÇİNDEKİ ESKİ event_pool İLE DEĞİŞTİR ---
var event_pool: Array = [
	# --- DEPREM (EARTHQUAKE) ---
	{ "disaster": DisasterType.Earthquake, "phase": "early", "msg": "Sarsıntı başladı! Eşyalar devriliyor, etraf karanlık.", "item": "flash_light", "damage": 40, "id": "eq_1" },
	{ "disaster": DisasterType.Earthquake, "phase": "early", "msg": "Toz bulutu yayıldı, nefes almak zorlaşıyor!", "item": "mask", "damage": 45, "id": "eq_2" },
	{ "disaster": DisasterType.Earthquake, "phase": "mid", "msg": "Hafif yaralandın, kanama var!", "item": "med_kit", "damage": 50, "id": "eq_3" },
	{ "disaster": DisasterType.Earthquake, "phase": "mid", "msg": "Enkaz altındasın! Sesini dışarıya duyurman lazım.", "item": "wistel", "damage": 35, "id": "eq_4" },
	{ "disaster": DisasterType.Earthquake, "phase": "late", "msg": "Çaresiz bir bekleyiş başladı, boğazın kurudu!", "item": "water", "damage": 55, "id": "eq_5" },
	{ "disaster": DisasterType.Earthquake, "phase": "late", "msg": "Dış dünya ile bağın koptu, bilgi alamıyorsun!", "item": "radio", "damage": 45, "id": "eq_6" },

	# --- SEL (FLOOD) ---
	{ "disaster": DisasterType.Flood, "phase": "early", "msg": "Su baskını kapıya ulaştı! Eşyalar ıslanıyor.", "item": "flash_light", "damage": 35, "id": "fl_1" },
	{ "disaster": DisasterType.Flood, "phase": "early", "msg": "Su yükseliyor, ayakların suyun altında kaldı!", "item": "rubber_boots", "damage": 40, "id": "fl_2" },
	{ "disaster": DisasterType.Flood, "phase": "mid", "msg": "Soğuk suyun içinde kalmaktan vücudun yaralandı!", "item": "med_kit", "damage": 45, "id": "fl_3" },
	{ "disaster": DisasterType.Flood, "phase": "mid", "msg": "Su seviyesi beline kadar geldi, titremeye başladın!", "item": "thermal_blanket", "damage": 45, "id": "fl_4" },
	{ "disaster": DisasterType.Flood, "phase": "late", "msg": "Çatıya tıkıldın, hipotermi riski var!", "item": "water", "damage": 50, "id": "fl_5" },
	{ "disaster": DisasterType.Flood, "phase": "late", "msg": "Kurtarma botlarına sesini duyurmalısın!", "item": "wistel", "damage": 40, "id": "fl_6" },

	# --- ÇIĞ (AVALANCHE) ---
	{ "disaster": DisasterType.Avalanche, "phase": "early", "msg": "Şiddetli fırtına ve kar bastırdı!", "item": "flash_light", "damage": 35, "id": "av_1" },
	{ "disaster": DisasterType.Avalanche, "phase": "early", "msg": "Kar fırtınasında yüzün ve ağzın karla doluyor!", "item": "mask", "damage": 35, "id": "av_2" },
	{ "disaster": DisasterType.Avalanche, "phase": "mid", "msg": "Vücut ısın hızla düşüyor, donuyorsun!", "item": "thermal_blanket", "damage": 50, "id": "av_3" },
	{ "disaster": DisasterType.Avalanche, "phase": "mid", "msg": "Donma belirtileri başladı, tıbbi müdahale lazım!", "item": "med_kit", "damage": 45, "id": "av_4" },
	{ "disaster": DisasterType.Avalanche, "phase": "late", "msg": "Kar kütlesinin altında mahsur kaldın, ses ver!", "item": "wistel", "damage": 50, "id": "av_5" },
	{ "disaster": DisasterType.Avalanche, "phase": "late", "msg": "Gücün tükeniyor, yardım ekiplerinden haber bekle!", "item": "radio", "damage": 40, "id": "av_6" },

	# --- YANGIN (FIRE) ---
	{ "disaster": DisasterType.Fire, "phase": "early", "msg": "Duman pencerelerden içeri doluyor, boğuluyorsun!", "item": "mask", "damage": 45, "id": "fi_1" },
	{ "disaster": DisasterType.Fire, "phase": "early", "msg": "Kıvılcımlar üstüne sıçramaya başladı!", "item": "fire_blanket", "damage": 50, "id": "fi_2" },
	{ "disaster": DisasterType.Fire, "phase": "mid", "msg": "Alevler etrafı sardı, aşırı sıcaklıktan kavruluyorsun!", "item": "water", "damage": 45, "id": "fi_3" },
	{ "disaster": DisasterType.Fire, "phase": "mid", "msg": "Cildinde ciddi yanıklar oluştu!", "item": "med_kit", "damage": 50, "id": "fi_4" },
	{ "disaster": DisasterType.Fire, "phase": "late", "msg": "Çıkış yolu alevlerle kapandı, karanlık ve duman basıyor!", "item": "flash_light", "damage": 40, "id": "fi_5" },
	{ "disaster": DisasterType.Fire, "phase": "late", "msg": "İtfaiye ekiplerine yerini bildirmelisin!", "item": "radio", "damage": 40, "id": "fi_6" }
]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	select_random_disaster()
	reset_bag_slots()
	shuffle_cabinet()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func reset_bag_slots():
	bag_slots.resize(max_bag_slot_count)
	bag_slots.fill({})

func shuffle_cabinet():
	var pool_copy = all_item_pool.duplicate(true)
	pool_copy.shuffle()
	cabinet_slots.clear()
	var cabinet_capasity = 12
	
	for i in range(cabinet_capasity):
		if i < pool_copy.size():
			cabinet_slots.append(pool_copy[i])
		else:
			cabinet_slots.append({})

func upgrade_bag_capasity():
	max_bag_slot_count += 1
	var old_bag_count = bag_slots.size()
	bag_slots.resize(max_bag_slot_count)
	for i in range(old_bag_count, max_bag_slot_count):
		bag_slots[i] = {}
	print("Çanta kapasitesi artırıldı! Yeni kapasite:", max_bag_slot_count)

func add_to_bag_slot(cabinet_index: int) -> bool:
	var item = cabinet_slots[cabinet_index]
	if item.is_empty(): return false
	
	for i in range(bag_slots.size()):
		if bag_slots[i].is_empty():
			bag_slots[i] = item.duplicate()
			cabinet_slots[cabinet_index] = {}
			return true # Başarıyla eklendi!
	return false

func remove_from_bag_slot(bag_index: int) -> bool:
	var item = bag_slots[bag_index]
	if item.is_empty(): return false
	
	for i in range(cabinet_slots.size()):
		if cabinet_slots[i].is_empty():
			cabinet_slots[i] = item.duplicate()
			bag_slots[bag_index] = {}
			return true
	return false

func select_random_disaster():
	var random_index = randi() % DisasterType.size()
	current_disaster = random_index as DisasterType
