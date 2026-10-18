extends Node

var master_volume: float = 1 # Varsayılan %100 (normal ses)

enum DisasterType {Earthquake, Flood, Avalanche, Fire}
var current_disaster: DisasterType = DisasterType.Earthquake

var tex_earthquake_pre = preload("res://Assets/disasters/disasters_preview/earthquake.png")
var tex_flood_pre = preload("res://Assets/disasters/disasters_preview/flood.png")
var tex_avalanche_pre = preload("res://Assets/disasters/disasters_preview/avalanche.png")
var tex_fire_pre = preload("res://Assets/disasters/disasters_preview/fire.png")

var tex_earthquake = preload("res://Assets/disasters/earthquake.png")
var tex_flood = preload("res://Assets/disasters/flood.png")
var tex_avalanche = preload("res://Assets/disasters/avalanche.png")
var tex_fire = preload("res://Assets/disasters/fire.png")

var tex_ch_earthquake = preload("res://Assets/disasters/earthquake_body.png")
var tex_ch_flood = preload("res://Assets/disasters/flood_body.png")
var tex_ch_avalanche = preload("res://Assets/disasters/avalanche_body.png")
var tex_ch_fire = preload("res://Assets/disasters/fire_body.png")

var max_bag_slot_count: int = 3
var survival_points: int = 0
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
	# ==========================================
	# --- DEPREM (EARTHQUAKE) ---
	# ==========================================
	# Early (Erken Aşama)
	{ "disaster": DisasterType.Earthquake, "phase": "early", "msg": "The sudden earthquake turned off all the lights, and now you cannot see anything in the dark.", "item": "flash_light", "damage": 45, "id": "eq_1" },
	{ "disaster": DisasterType.Earthquake, "phase": "early", "msg": "Dust from the collapsed buildings filled the air, making it very difficult to breathe.", "item": "mask", "damage": 45, "id": "eq_2" },
	{ "disaster": DisasterType.Earthquake, "phase": "early", "msg": "The strong shaking broke glass and scattered debris, which cut your hand.", "item": "med_kit", "damage": 50, "id": "eq_3" },
	
	# Mid (Orta Aşama)
	{ "disaster": DisasterType.Earthquake, "phase": "mid", "msg": "You are trapped under heavy concrete, so you must call out loudly for help.", "item": "wistel", "damage": 55, "id": "eq_4" },
	{ "disaster": DisasterType.Earthquake, "phase": "mid", "msg": "After waiting for hours in your hiding spot, you are feeling extremely hungry.", "item": "con_foods", "damage": 50, "id": "eq_5" },
	{ "disaster": DisasterType.Earthquake, "phase": "mid", "msg": "Burst pipes flooded the area around you, and the freezing air makes it worse.", "item": "thermal_blanket", "damage": 55, "id": "eq_6" },
	
	# Late (Geç Aşama)
	{ "disaster": DisasterType.Earthquake, "phase": "late", "msg": "You have been waiting for rescue for days, and your throat is painfully dry.", "item": "water", "damage": 65, "id": "eq_7" },
	{ "disaster": DisasterType.Earthquake, "phase": "late", "msg": "All phone lines and internet are down, so you have no news from the outside world.", "item": "radio", "damage": 50, "id": "eq_8" },
	{ "disaster": DisasterType.Earthquake, "phase": "late", "msg": "An aftershock started a small fire under the rubble, and sparks are flying around.", "item": "fire_blanket", "damage": 60, "id": "eq_9" },

	# ==========================================
	# --- SEL (FLOOD) ---
	# ==========================================
	# Early (Erken Aşama)
	{ "disaster": DisasterType.Flood, "phase": "early", "msg": "A sudden flood filled the house with water and cut off all the electricity.", "item": "flash_light", "damage": 45, "id": "fl_1" },
	{ "disaster": DisasterType.Flood, "phase": "early", "msg": "The muddy water is rising fast and covering the furniture, so you must leave immediately.", "item": "rubber_boots", "damage": 50, "id": "fl_2" },
	{ "disaster": DisasterType.Flood, "phase": "early", "msg": "Rising water caused a short circuit in the power lines, creating dangerous sparks.", "item": "fire_blanket", "damage": 55, "id": "fl_3" },
	
	# Mid (Orta Aşama)
	{ "disaster": DisasterType.Flood, "phase": "mid", "msg": "You hit a sharp object in the fast current and got injured while drifting.", "item": "med_kit", "damage": 55, "id": "fl_4" },
	{ "disaster": DisasterType.Flood, "phase": "mid", "msg": "You are stranded on a rooftop in wet clothes, and you are starting to freeze.", "item": "thermal_blanket", "damage": 60, "id": "fl_5" },
	{ "disaster": DisasterType.Flood, "phase": "mid", "msg": "You have been stuck for a long time, and you need food to keep your strength up.", "item": "con_foods", "damage": 50, "id": "fl_6" },
	
	# Late (Geç Aşama)
	{ "disaster": DisasterType.Flood, "phase": "late", "msg": "The local water supply is polluted, so finding clean drinking water is a big problem.", "item": "water", "damage": 60, "id": "fl_7" },
	{ "disaster": DisasterType.Flood, "phase": "late", "msg": "You need to wave or make noise to get the attention of the rescue boats.", "item": "wistel", "damage": 55, "id": "fl_8" },
	{ "disaster": DisasterType.Flood, "phase": "late", "msg": "Surrounded by deep water, you are listening carefully for emergency announcements.", "item": "radio", "damage": 50, "id": "fl_9" },
	# ==========================================
	# --- ÇIĞ (AVALANCHE) ---
	# ==========================================
	# Early (Erken Aşama)
	{ "disaster": DisasterType.Avalanche, "phase": "early", "msg": "The avalanche triggered a heavy snowstorm, and you can no longer see the path.", "item": "flash_light", "damage": 45, "id": "av_1" },
	{ "disaster": DisasterType.Avalanche, "phase": "early", "msg": "Freezing winds are blowing snow directly into your face, making it hard to breathe.", "item": "mask", "damage": 50, "id": "av_2" },
	{ "disaster": DisasterType.Avalanche, "phase": "early", "msg": "Meltwater is leaking into your tent, so you need to stay dry to avoid hypothermia.", "item": "rubber_boots", "damage": 45, "id": "av_3" },
	
	# Mid (Orta Aşama)
	{ "disaster": DisasterType.Avalanche, "phase": "mid", "msg": "The extreme cold and strong winds are dropping your body temperature dangerously low.", "item": "thermal_blanket", "damage": 65, "id": "av_4" },
	{ "disaster": DisasterType.Avalanche, "phase": "mid", "msg": "Prolonged exposure to the freezing cold has started to damage your fingers and skin.", "item": "med_kit", "damage": 55, "id": "av_5" },
	{ "disaster": DisasterType.Avalanche, "phase": "mid", "msg": "Stranded in the snow, you need high-calorie food to keep your body warm.", "item": "con_foods", "damage": 50, "id": "av_6" },
	
	# Late (Geç Aşama)
	{ "disaster": DisasterType.Avalanche, "phase": "late", "msg": "You are buried under thick snow, so you must send a signal to show your location.", "item": "wistel", "damage": 65, "id": "av_7" },
	{ "disaster": DisasterType.Avalanche, "phase": "late", "msg": "You lost contact with your team, so you are trying to listen for weather updates.", "item": "radio", "damage": 55, "id": "av_8" },
	{ "disaster": DisasterType.Avalanche, "phase": "late", "msg": "You are very thirsty in the frozen cold, so you need to melt snow to drink.", "item": "water", "damage": 60, "id": "av_9" },

	# ==========================================
	# --- YANGIN (FIRE) ---
	# ==========================================
	# Early (Erken Aşama)
	{ "disaster": DisasterType.Fire, "phase": "early", "msg": "Thick toxic smoke has filled the room, making you cough and gasp for air.", "item": "mask", "damage": 55, "id": "fi_1" },
	{ "disaster": DisasterType.Fire, "phase": "early", "msg": "Flames and flying sparks are spreading quickly towards your personal belongings.", "item": "fire_blanket", "damage": 60, "id": "fi_2" },
	{ "disaster": DisasterType.Fire, "phase": "early", "msg": "The main fire went out, but thick black smoke makes it impossible to see the exit.", "item": "flash_light", "damage": 45, "id": "fi_3" },
	
	# Mid (Orta Aşama)
	{ "disaster": DisasterType.Fire, "phase": "mid", "msg": "The intense heat and dry smoke are making your throat burn with thirst.", "item": "water", "damage": 60, "id": "fi_4" },
	{ "disaster": DisasterType.Fire, "phase": "mid", "msg": "You touched a hot surface while escaping and suffered painful burns on your hands.", "item": "med_kit", "damage": 65, "id": "fi_5" },
	{ "disaster": DisasterType.Fire, "phase": "mid", "msg": "You need to eat something quickly to regain your energy and keep moving.", "item": "con_foods", "damage": 50, "id": "fi_6" },
	
	# Late (Geç Aşama)
	{ "disaster": DisasterType.Fire, "phase": "late", "msg": "The main door is blocked by fire, so you need to yell to guide the rescuers to you.", "item": "wistel", "damage": 60, "id": "fi_7" },
	{ "disaster": DisasterType.Fire, "phase": "late", "msg": "You are trying to hear the firefighters' instructions through the loud noise.", "item": "radio", "damage": 50, "id": "fi_8" },
	{ "disaster": DisasterType.Fire, "phase": "late", "msg": "You must protect yourself from extreme heat stroke while escaping the burning building.", "item": "thermal_blanket", "damage": 55, "id": "fi_9" }
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
