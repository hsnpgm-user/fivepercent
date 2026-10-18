extends Node2D

const GAME_DURATION: float = 78
const SURVIVE_TIME: float = 78
const EVENT_REACTION_TIME: float = 8
const MID_PHASE_START: float = 20
const LATE_PHASE_START: float = 40

@onready var item_audio_player: AudioStreamPlayer2D = $ItemAudioPlayer
@onready var disaster_audio_player: AudioStreamPlayer2D = $DisasterAudioPlayer

@onready var blur: ColorRect = $UI/Blur
@onready var situation_label: Label = $UI/SituationLabel
@onready var end_game_screen: Control = $EndGameScreen
@onready var summary_title_label: Label = $EndGameScreen/MarginContainer/VBoxContainer/Label
@onready var summary_label_1: Label = $EndGameScreen/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label
@onready var summary_label_2: Label = $EndGameScreen/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Label
@onready var summary_label_3: Label = $EndGameScreen/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/Label
@onready var summary_label_4: Label = $EndGameScreen/MarginContainer/VBoxContainer/MarginContainer4/HBoxContainer/Label
@onready var summary_label_5: Label = $EndGameScreen/MarginContainer/VBoxContainer/MarginContainer5/HBoxContainer/Label

# --- DAİRESEL BAR REFERANSLARI ---
@onready var health_bar: TextureProgressBar = $UI/HealthBar
@onready var thirst_bar: TextureProgressBar = $UI/ThirstBar
@onready var hunger_bar: TextureProgressBar = $UI/HungerBar
@onready var temp_bar: TextureProgressBar = $UI/TempBar

@onready var character: Sprite2D = $UI/Character
@onready var background: TextureRect = $UI/Background
@onready var event_label: Label = $UI/EventLabel
@onready var event_timer: Timer = $EventTimer
@onready var in_game_time: Timer = $InGameTime
@onready var custom_timer: Timer = $CustomTimer
@onready var bag_grid = $UI/BagGrid
@onready var survival_stats_timer: Timer = $SurvivalStatsTimer

var slot_scene = preload("res://Scenes/slot.tscn")

var successful_interventions: int = 0
var current_run_events: Array = []
var active_event: Dictionary = {}
var event_active: bool = false
var event_serial: int = 0
var game_over: bool = false
var elapsed_time: float = 0.0


func _ready() -> void:
	GameManager.player_stats = { "hunger": 100, "thirst": 100, "temperature": 100, "health": 100 }
	change_background()
	play_disaster_ambient()
	if health_bar: health_bar.max_value = 100
	if thirst_bar: thirst_bar.max_value = 100
	if hunger_bar: hunger_bar.max_value = 100
	if temp_bar: temp_bar.max_value = 100
	update_radial_stats_ui()
	current_run_events = GameManager.event_pool.filter(
		func(e): return e["disaster"] == GameManager.current_disaster
	)
	current_run_events.shuffle()
	event_timer.timeout.connect(_on_event_timer_timeout)
	event_timer.start()
	in_game_time_prepare(true, GAME_DURATION, good_ending)
	draw_ingame_bag()
	
	survival_stats_timer.wait_time = 2.5
	survival_stats_timer.timeout.connect(_on_stats_tick)
	survival_stats_timer.start()
	
	event_timer.wait_time = 16
	event_timer.timeout.connect(_on_sparse_event_trigger)
	event_timer.start()

func _process(delta: float) -> void:
	if game_over: return
	
	elapsed_time += delta
	
	if elapsed_time >= SURVIVE_TIME:
		good_ending()
		
	if GameManager.player_stats["health"] <= 0:
		bad_ending()

func update_radial_stats_ui() -> void:
	# Her bir bar için akıcı (smooth) geçiş animasyonu (Tween) oluşturuyoruz
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if health_bar:
		tween.tween_property(health_bar, "value", float(GameManager.player_stats["health"]), 0.5)
	if thirst_bar:
		tween.tween_property(thirst_bar, "value", float(GameManager.player_stats["thirst"]), 0.5)
	if hunger_bar:
		tween.tween_property(hunger_bar, "value", float(GameManager.player_stats["hunger"]), 0.5)
	if temp_bar:
		tween.tween_property(temp_bar, "value", float(GameManager.player_stats["temperature"]), 0.5)

func _on_stats_tick():
	var thirst_drop = 3
	var hunger_drop = 2
	var temp_drop = 3
	
	match GameManager.current_disaster:
		GameManager.DisasterType.Avalanche:
			temp_drop = 6
		GameManager.DisasterType.Flood:
			thirst_drop = 5
		GameManager.DisasterType.Fire:
			temp_drop = 5
			thirst_drop = 4
		GameManager.DisasterType.Earthquake:
			pass
			
	GameManager.player_stats["thirst"] = max(0, GameManager.player_stats["thirst"] - thirst_drop)
	GameManager.player_stats["hunger"] = max(0, GameManager.player_stats["hunger"] - hunger_drop)
	GameManager.player_stats["temperature"] = max(0, GameManager.player_stats["temperature"] - temp_drop)
	
	if GameManager.player_stats["thirst"] == 0 or GameManager.player_stats["hunger"] == 0 or GameManager.player_stats["temperature"] == 0:
		GameManager.player_stats["health"] = max(0, GameManager.player_stats["health"] - 10)
		if not event_active:
			event_label.text = "⚠️ Vücut sınırda! Açlık/Susuzluk/Isı tükeniyor!"
	
	update_radial_stats_ui()

func _on_sparse_event_trigger():
	if event_active: return
	
	var possible_crises = []
	
	if GameManager.player_stats["thirst"] < 35:
		possible_crises.append({ "msg": "Kritik Susuzluk! Boğazın kurumaya başladı.", "stat_effect": "thirst" })
	if GameManager.player_stats["temperature"] < 35:
		possible_crises.append({ "msg": "Şiddetli Titreme! Donmak üzeresin.", "stat_effect": "temperature" })
	if GameManager.player_stats["hunger"] < 35:
		possible_crises.append({ "msg": "Miden kazınıyor, gücün kesiliyor.", "stat_effect": "hunger" })
		
	if possible_crises.is_empty():
		match GameManager.current_disaster:
			GameManager.DisasterType.Avalanche:
				possible_crises.append({ "msg": "Tipiden ötürü çadırın sarsılıyor!", "stat_effect": "none" })
			GameManager.DisasterType.Earthquake:
				possible_crises.append({ "msg": "Güçlü bir artçı sarsıntı vurdu!", "stat_effect": "none" })
			GameManager.DisasterType.Flood:
				possible_crises.append({ "msg": "Su seviyesi hızla yükseliyor!", "stat_effect": "none" })
			GameManager.DisasterType.Fire:
				possible_crises.append({ "msg": "Duman yoğunluğu arttı, gözlerin yanıyor!", "stat_effect": "none" })
				
	possible_crises.shuffle()
	var chosen_crisis = possible_crises[0]
	
	event_active = true
	event_label.text = "🚨 " + chosen_crisis["msg"]
	
	await get_tree().create_timer(6.0).timeout
	if event_active:
		event_active = false
		GameManager.player_stats["health"] = max(0, GameManager.player_stats["health"] - 10)
		event_label.text = "❌ Durum kötüleşti! Can azaldı."
		update_radial_stats_ui()
		await get_tree().create_timer(2.0).timeout
		event_label.text = ""

# ---------- Puan ----------

func calculate_detailed_points(is_survived: bool) -> int:
	var base_score: int = 0

	if is_survived:
		base_score += 600
	else:
		var survival_score: int = int(elapsed_time * 5)
		base_score += survival_score

	var intervention_bonus: int = successful_interventions * 100
	base_score += intervention_bonus

	GameManager.survival_points += base_score
	return base_score


# ---------- Timer yardımcıları ----------

func in_game_time_prepare(is_one_shot: bool, total_time: float, activate_function: Callable) -> void:
	in_game_time.one_shot = is_one_shot
	in_game_time.wait_time = total_time
	in_game_time.timeout.connect(activate_function, CONNECT_ONE_SHOT if is_one_shot else 0)
	in_game_time.start()


func prepare_custom_timer(waiting_time: float, is_one_shot: bool, on_timeout_callback: Callable) -> void:
	custom_timer.wait_time = waiting_time
	custom_timer.one_shot = is_one_shot
	custom_timer.timeout.connect(on_timeout_callback, CONNECT_ONE_SHOT if is_one_shot else 0)
	custom_timer.start()


# ---------- Oyun sonu ----------

func good_ending() -> void:
	if game_over: return
	_finish_run()
	var advice = "Harika hazırlık! Eşyaları doğru kullanarak afeti atlattın."
	show_game_summary(true, "AFETTEN SAĞ KURTULDUN!", advice)


func bad_ending() -> void:
	if game_over: return
	_finish_run()
	
	if event_label:
		event_label.text = ""
	
	var advice = "Zorlu turdu! Eksik hazırlık veya ters tepen eşyalar can yaktı."
	show_game_summary(false, "NAKAVT OLDUN...", advice)


func _finish_run() -> void:
	game_over = true
	event_timer.stop()
	set_process(false)


func change_scene() -> void:
	get_tree().change_scene_to_file("res://Scenes/upgrade_screen.tscn")


func _on_continue_button_pressed() -> void:
	prepare_custom_timer(0.5, true, change_scene)


# ---------- Çanta ve Eşya Mekanikleri ----------

func draw_ingame_bag() -> void:
	for child in bag_grid.get_children():
		child.queue_free()

	for i in range(GameManager.bag_slots.size()):
		var new_slot := slot_scene.instantiate() as Slot
		new_slot.slot_index = i
		new_slot.slot_type = "ingame_canta"
		new_slot.slot_clicked.connect(_on_slot_clicked)
		bag_grid.add_child(new_slot)
		new_slot.update_slot_data(GameManager.bag_slots[i])


func _on_slot_clicked(slot_type: String, index: int) -> void:
	if game_over: return
	if slot_type != "ingame_canta" and slot_type != "ingame_bag": return
	
	var item: Dictionary = GameManager.bag_slots[index]
	if item.is_empty(): return

	var item_id: String = item["item_id"]
	
	play_item_sound(item_id)

	# 1. Temel İhtiyaç Giderme (Su sadece susuzluk, konserve sadece açlık doldurur!)
	if item.has("thirst_restore" or item_id == "water"):
		GameManager.player_stats["thirst"] = min(100, GameManager.player_stats["thirst"] + item["thirst_restore"])
	if item.has("hunger_restore" or item_id == "con_foods"):
		GameManager.player_stats["hunger"] = min(100, GameManager.player_stats["hunger"] + item["hunger_restore"])

	# 2. Afet Matrisi ve Eşya Özel Etkileri
	for proto in GameManager.all_item_pool:
		if proto["item_id"] == item_id and proto.has("effects"):
			var disaster_effects = proto["effects"]
			if disaster_effects.has(GameManager.current_disaster):
				var effect_data = disaster_effects[GameManager.current_disaster]
				var target_stat = effect_data["stat"] 
				var val = effect_data["val"]
				
				# KURAL: Can (health) değerini artıran tek eşya MEDKIT'tir.
				if target_stat == "health":
					if item_id == "med_kit":
						if event_active:
							# Kriz anında kullanılırsa yüksek telafi (18 can)
							GameManager.player_stats["health"] = min(100, GameManager.player_stats["health"] + 18)
						else:
							# Kriz dışında kullanılırsa çok az can tazeleme (5 can)
							GameManager.player_stats["health"] = min(100, GameManager.player_stats["health"] + 5)
					else:
						# Diğer eşyaların cana olan olumsuz etkileri (yanlış eşya cezaları) aynen çalışır
						if val < 0:
							GameManager.player_stats["health"] = max(0, GameManager.player_stats["health"] + val)
				else:
					# Isı veya diğer stat değişimleri
					GameManager.player_stats[target_stat] = clamp(GameManager.player_stats[target_stat] + val, 0, 100)

	# 3. Kriz Durumu Kontrolü
	var is_correct_item_for_event = false
	if event_active and active_event.has("item") and item_id == active_event["item"]:
		event_active = false
		successful_interventions += 1
		GameManager.survival_points += 100
		is_correct_item_for_event = true
		
		# Eğer doğru eşya Medkit ise kriz çözüldüğünde ekstra can telafisi verelim
		if item_id == "med_kit":
			GameManager.player_stats["health"] = min(100, GameManager.player_stats["health"] + 15)
	
	update_radial_stats_ui()

	# --- HİKAYESEL GÖRSEL GERİ BİLDİRİM ---
	var story_text = get_item_narrative(item_id)
	
	if is_correct_item_for_event:
		situation_label.text = "✅ Kriz Çözüldూ! (+100 Puan)\n📖 " + story_text
		event_label.text = ""
	else:
		situation_label.text = "📖 " + story_text
	
	GameManager.bag_slots[index] = {}
	draw_ingame_bag()

	await get_tree().create_timer(6.0).timeout
	
	if not event_active and not game_over:
		situation_label.text = ""


# ---------- Kriz sistemi ----------

func _get_active_phase() -> String:
	if elapsed_time > LATE_PHASE_START:
		return "late"
	if elapsed_time > MID_PHASE_START:
		return "mid"
	return "early"


func _on_event_timer_timeout() -> void:
	if game_over or event_active or current_run_events.is_empty():
		return

	var active_phase := _get_active_phase()
	var candidate_index: int = current_run_events.find_custom(
		func(e): return e["phase"] == active_phase
	)
	if candidate_index == -1:
		candidate_index = 0

	active_event = current_run_events.pop_at(candidate_index)
	event_active = true
	event_serial += 1
	var my_serial := event_serial

	event_label.text = "⚠️ KRİZ: " + active_event["msg"]

	await get_tree().create_timer(EVENT_REACTION_TIME).timeout

	if game_over or not event_active or my_serial != event_serial:
		return

	event_active = false
	var dmg = active_event["damage"]
	
	GameManager.player_stats["health"] = max(0, GameManager.player_stats["health"] - dmg)
	event_label.text = "❌ Krize zamanında müdahale edilmedi! (-" + str(dmg) + " Can)"
	
	update_radial_stats_ui()
	
	if GameManager.player_stats["health"] <= 0:
		bad_ending()
		return

	await get_tree().create_timer(1.5).timeout
	if not event_active and not game_over:
		event_label.text = ""

func change_background():
	match GameManager.current_disaster:
		GameManager.DisasterType.Earthquake:
			character.texture = GameManager.tex_ch_earthquake
			background.texture = GameManager.tex_earthquake
		GameManager.DisasterType.Flood:
			character.texture = GameManager.tex_ch_flood
			background.texture = GameManager.tex_flood
		GameManager.DisasterType.Fire:
			character.texture = GameManager.tex_ch_fire
			background.texture = GameManager.tex_fire
		GameManager.DisasterType.Avalanche:
			character.texture = GameManager.tex_ch_avalanche
			background.texture = GameManager.tex_avalanche

func show_game_summary(is_survived: bool, title_text: String, advice_text: String):
	event_label.visible = false
	var earned_score = calculate_detailed_points(is_survived)
	
	end_game_screen.visible = true
	blur.visible = true
	
	if summary_title_label:
		summary_title_label.text = title_text
		
	if summary_label_1:
		summary_label_1.text = "⏱️ Dayanma Süresi: " + str(int(elapsed_time)) + " Saniye"
	if summary_label_2:
		summary_label_2.text = "✅ Başarılı Müdahale: " + str(successful_interventions) + " Adet"
	if summary_label_3:
		summary_label_3.text = "⭐ Bu Tur Kazanılan Puan: +" + str(earned_score)
	if summary_label_4:
		summary_label_4.text = "🏆 Toplam Skor: " + str(GameManager.survival_points)
	if summary_label_5:
		summary_label_5.text = "💡 Tavsiye: " + advice_text

# --- BU FONKSİYONU ESKİSİYLE DEĞİŞTİR ---
func get_item_narrative(item_id: String) -> String:
	var disaster = GameManager.current_disaster
	
	match item_id:
		"water":
			if disaster == GameManager.DisasterType.Avalanche:
				return "Dondurucu soğukta içtiğin su, içten içe vücut ısını düşürdü. Yanlış bir tercih miydi?"
			elif disaster == GameManager.DisasterType.Flood:
				return "Etrafı çamurlu sular basmışken bu temiz suyu yudumlamak değerliydi, boğazın yumuşadı."
			else:
				return "Mataradaki serin suyu yudumladın. Kuruyan boğazın rahatladı, zihnin biraz berraklaştı."
				
		"con_foods":
			if disaster == GameManager.DisasterType.Fire:
				return "Aşırı sıcak havada bu konserve ağır geldi, miden bulandı ve susuzluğun arttı."
			elif disaster == GameManager.DisasterType.Avalanche:
				return "Dondurucu soğukta konserve gıdayı açıp yedin; aldığın kalori vücut direncini ayakta tuttu."
			else:
				return "Konserve kutusunu açıp karnını doyurdun. Enerjin yerine geldi."
				
		"flash_light":
			if disaster == GameManager.DisasterType.Fire:
				return "Alevlerin aydınlettiği ortamda feneri açmak gereksizdi; dumanla birleşince gözlerini yaktı."
			else:
				return "Fenerin huzmesi karanlık köşeleri aydınlattı. Çevreni net görebilmek korkunu hafifletti."
				
		"med_kit":
			return "İlk yardım setini açıp yarana müdahale ettin. Akan kan durdu, gücün yerine gelmeye başladı."
				
		"fire_blanket":
			if disaster == GameManager.DisasterType.Fire:
				return "Yangın battaniyesine sarılarak alevlerin ve sıcağın etkisinden korundun. Hayat kurtarıcı hamle!"
			else:
				return "Yanmaz örtüyü etrafına örttün, şu anlık çok kritik bir işlevi olmasa da güvende hissettirdi."
				
		"thermal_blanket":
			if disaster == GameManager.DisasterType.Avalanche:
				return "Termal battaniyeye sıkıca sarındın; donmaktan son anda kurtuldun, vücut ısın dengeleniyor."
			else:
				return "Termal battaniyeyi üzerine örttün."
				
		"rubber_boots":
			if disaster == GameManager.DisasterType.Flood:
				return "Su geçirmez çizmeleri giydin; yükselen suların içinde güvenle adım atıyorsun!"
			else:
				return "Çizmeleri ayağına geçirdin."
				
		"mask":
			if disaster == GameManager.DisasterType.Fire:
				return "Maskeyi yüzüne taktın. Yoğun duman filtreden süzüldü, ciğerlerin bayram etti!"
			else:
				return "Toz bulutunun ortasında maske sayesinde rahatça nefes alabildin."
				
		"radio":
			return "Telsizden gelen cızırtılı anonsları dinledin. Dış dünyadan gelen ses umut oldu."
				
		"wistel":
			return "Düvele güçlüce üfledin; sesin uzaklardan yankılandı, ekiplere yerini belli ettin!"
			
		_:
			return "Eşyayı dikkatle kullandın. Durumunda ufak bir değişim hissediliyor."

func play_item_sound(item_id: String) -> void:
	if not item_audio_player: return
	
	var sound_path = "res://Assets/Audio/SFX/" + get_sound_filename(item_id) + ".mp3"
	if ResourceLoader.exists(sound_path):
		var audio_stream = load(sound_path)
		item_audio_player.stream = audio_stream
		item_audio_player.play()
	else:
		# Eğer .wav bulamazsa .ogg dener
		var ogg_path = "res://Assets/Audio/SFX/" + get_sound_filename(item_id) + ".ogg"
		if ResourceLoader.exists(ogg_path):
			item_audio_player.stream = load(ogg_path)
			item_audio_player.play()

# Hangi eşyanın hangi ses dosyasına karşılık geldiğini eşler
func get_sound_filename(item_id: String) -> String:
	match item_id:
		"water": return "water_drink"
		"con_foods": return "eat_food"
		"flash_light": return "flashlight"
		"med_kit": return "med_kit"
		"fire_blanket": return "fire_blanket"
		"thermal_blanket": return "thermal_blanket"
		"rubber_boots": return "rubber_boots"
		"mask": return "mask"
		"radio": return "radio"
		"wistel": return "wistel"
		_: return "default_use"

func play_disaster_ambient() -> void:
	if not disaster_audio_player: return
	
	var ambient_filename = ""
	match GameManager.current_disaster:
		GameManager.DisasterType.Earthquake:
			ambient_filename = "earthquake_ambient"
		GameManager.DisasterType.Flood:
			ambient_filename = "flood_ambient"
		GameManager.DisasterType.Avalanche:
			ambient_filename = "avalanche_ambient"
		GameManager.DisasterType.Fire:
			ambient_filename = "fire_ambient"
			
	var sound_path = "res://Assets/Audio/Ambient/" + ambient_filename + ".mp3"
	if ResourceLoader.exists(sound_path):
		var stream = load(sound_path)
		# Eğer ses dosyasının kendi içinde loop özelliği yoksa kodla da döngüye alabiliriz
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
			
		disaster_audio_player.stream = stream
		disaster_audio_player.play()
