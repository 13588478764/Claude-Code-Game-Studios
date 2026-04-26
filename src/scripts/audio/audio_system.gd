# 武侠奇遇录 - 音效系统
# 负责管理游戏中的所有音频播放和音效控制

extends Node

# 音频类型枚举
enum AudioType {
	BACKGROUND_MUSIC,  # 背景音乐
	SOUND_EFFECT,      # 音效
	VOICE_OVER,        # 语音
	UI_SOUND           # UI音效
}

# 音频配置
var config = {
	"music_volume": 0.8,      # 音乐音量 (0.0-1.0)
	"sfx_volume": 0.9,        # 音效音量 (0.0-1.0)
	"voice_volume": 0.7,      # 语音音量 (0.0-1.0)
	"ui_volume": 0.6,         # UI音量 (0.0-1.0)
	"master_volume": 1.0,     # 主音量 (0.0-1.0)
	"spatial_enabled": true,  # 3D音效启用
	"doppler_enabled": true,  # 多普勒效应启用
	"reverb_enabled": true,   # 混响启用
	"max_sounds": 32          # 最大同时播放音效数量
}

# 音频资源字典
var audio_resources = {
	# 背景音乐
	"bgm_main_menu": "res://audio/music/main_menu.ogg",
	"bgm_exploration": "res://audio/music/exploration.ogg",
	"bgm_combat": "res://audio/music/combat.ogg",
	"bgm_boss": "res://audio/music/boss.ogg",
	"bgm_victory": "res://audio/music/victory.ogg",
	"bgm_town": "res://audio/music/town.ogg",
	
	# 战斗音效
	"sword_slash": "res://audio/sfx/combat/sword_slash.ogg",
	"fire_palm": "res://audio/sfx/combat/fire_palm.ogg",
	"water_sword": "res://audio/sfx/combat/water_sword.ogg",
	"wood_staff": "res://audio/sfx/combat/wood_staff.ogg",
	"earth_fist": "res://audio/sfx/combat/earth_fist.ogg",
	"metal_claw": "res://audio/sfx/combat/metal_claw.ogg",
	"lightning_strike": "res://audio/sfx/combat/lightning_strike.ogg",
	"shadow_step": "res://audio/sfx/combat/shadow_step.ogg",
	"iron_clothes": "res://audio/sfx/combat/iron_clothes.ogg",
	
	# 命中音效
	"hit_normal": "res://audio/sfx/combat/hit_normal.ogg",
	"hit_critical": "res://audio/sfx/combat/hit_critical.ogg",
	"hit_weakness": "res://audio/sfx/combat/hit_weakness.ogg",
	"hit_break": "res://audio/sfx/combat/hit_break.ogg",
	"hit_dodge": "res://audio/sfx/combat/hit_dodge.ogg",
	
	# 奇遇音效
	"encounter_trigger": "res://audio/sfx/encounter/trigger.ogg",
	"encounter_reward": "res://audio/sfx/encounter/reward.ogg",
	"encounter_jianghu": "res://audio/sfx/encounter/jianghu.ogg",
	"encounter_treasure": "res://audio/sfx/encounter/treasure.ogg",
	"encounter_wise_master": "res://audio/sfx/encounter/wise_master.ogg",
	"encounter_secret_realm": "res://audio/sfx/encounter/secret_realm.ogg",
	
	# UI音效
	"ui_button_click": "res://audio/sfx/ui/button_click.ogg",
	"ui_menu_open": "res://audio/sfx/ui/menu_open.ogg",
	"ui_menu_close": "res://audio/sfx/ui/menu_close.ogg",
	"ui_equip_item": "res://audio/sfx/ui/equip_item.ogg",
	"ui_level_up": "res://audio/sfx/ui/level_up.ogg",
	"ui_save_game": "res://audio/sfx/ui/save_game.ogg"
}

# 当前播放的音频
var current_bgm = null
var active_sounds = []

func _ready():
	print("音效系统初始化完成")
	load_audio_resources()

func load_audio_resources():
	"""加载音频资源"""
	# 这里可以预加载常用音频资源
	# 简化实现：暂时只打印信息
	print("加载音频资源...")

func play_background_music(music_id, fade_in_time=1.0):
	"""播放背景音乐"""
	if not audio_resources.has(music_id):
		push_warning("背景音乐不存在: %s" % music_id)
		return
	
	# 停止当前背景音乐
	if current_bgm != null:
		current_bgm.stop()
	
	# 加载并播放新背景音乐
	var audio_stream = load(audio_resources[music_id])
	if audio_stream == null:
		push_error("无法加载背景音乐: %s" % audio_resources[music_id])
		return
	
	current_bgm = AudioStreamPlayer.new()
	current_bgm.stream = audio_stream
	current_bgm.volume_db = linear_to_db(config["music_volume"] * config["master_volume"])
	current_bgm.bus = "Music"
	current_bgm.autoplay = false
	add_child(current_bgm)
	
	# 淡入效果
	if fade_in_time > 0:
		current_bgm.volume_db = -80  # 初始静音
		current_bgm.play()
		tween_volume(current_bgm, -80, linear_to_db(config["music_volume"] * config["master_volume"]), fade_in_time)
	else:
		current_bgm.play()
	
	print("播放背景音乐: %s" % music_id)

func stop_background_music(fade_out_time=1.0):
	"""停止背景音乐"""
	if current_bgm == null:
		return
	
	if fade_out_time > 0:
		tween_volume(current_bgm, current_bgm.volume_db, -80, fade_out_time)
		await get_tree().create_timer(fade_out_time).timeout
	
	current_bgm.stop()
	current_bgm.queue_free()
	current_bgm = null
	print("停止背景音乐")

func play_sound_effect(sound_id, position=null, volume_multiplier=1.0):
	"""播放音效"""
	if not audio_resources.has(sound_id):
		push_warning("音效不存在: %s" % sound_id)
		return
	
	# 检查最大音效数量
	if active_sounds.size() >= config["max_sounds"]:
		# 移除最旧的音效
		var oldest_sound = active_sounds.pop_front()
		if oldest_sound != null:
			oldest_sound.queue_free()
	
	# 加载音效
	var audio_stream = load(audio_resources[sound_id])
	if audio_stream == null:
		push_error("无法加载音效: %s" % audio_resources[sound_id])
		return
	
	# 创建音效播放器
	var sound_player = null
	if position != null and config["spatial_enabled"]:
		# 3D音效
		sound_player = AudioStreamPlayer3D.new()
		sound_player.position = position
		sound_player.doppler_tracking = false if not config["doppler_enabled"] else true
	else:
		# 2D音效
		sound_player = AudioStreamPlayer.new()
	
	sound_player.stream = audio_stream
	sound_player.volume_db = linear_to_db(config["sfx_volume"] * config["master_volume"] * volume_multiplier)
	sound_player.bus = "SFX"
	sound_player.autoplay = false
	
	# 添加到场景树
	add_child(sound_player)
	
	# 播放音效
	sound_player.play()
	
	# 添加到活动音效列表
	active_sounds.append(sound_player)
	
	# 设置自动清理
	sound_player.connect("finished", Callable(self, "_on_sound_finished").bind(sound_player))
	
	print("播放音效: %s" % sound_id)
	return sound_player

func _on_sound_finished(sound_player):
	"""音效播放完成回调"""
	if active_sounds.has(sound_player):
		active_sounds.erase(sound_player)
	sound_player.queue_free()

func play_ui_sound(sound_id):
	"""播放UI音效"""
	if not audio_resources.has(sound_id):
		push_warning("UI音效不存在: %s" % sound_id)
		return
	
	var audio_stream = load(audio_resources[sound_id])
	if audio_stream == null:
		push_error("无法加载UI音效: %s" % audio_resources[sound_id])
		return
	
	var ui_player = AudioStreamPlayer.new()
	ui_player.stream = audio_stream
	ui_player.volume_db = linear_to_db(config["ui_volume"] * config["master_volume"])
	ui_player.bus = "UI"
	ui_player.autoplay = false
	add_child(ui_player)
	
	ui_player.play()
	ui_player.connect("finished", Callable(self, "_on_ui_sound_finished").bind(ui_player))
	
	print("播放UI音效: %s" % sound_id)

func _on_ui_sound_finished(ui_player):
	"""UI音效播放完成回调"""
	ui_player.queue_free()

func set_music_volume(volume):
	"""设置音乐音量"""
	config["music_volume"] = clamp(volume, 0.0, 1.0)
	if current_bgm != null:
		current_bgm.volume_db = linear_to_db(config["music_volume"] * config["master_volume"])

func set_sfx_volume(volume):
	"""设置音效音量"""
	config["sfx_volume"] = clamp(volume, 0.0, 1.0)

func set_ui_volume(volume):
	"""设置UI音量"""
	config["ui_volume"] = clamp(volume, 0.0, 1.0)

func set_master_volume(volume):
	"""设置主音量"""
	config["master_volume"] = clamp(volume, 0.0, 1.0)
	if current_bgm != null:
		current_bgm.volume_db = linear_to_db(config["music_volume"] * config["master_volume"])

func linear_to_db(linear):
	"""线性音量转换为分贝"""
	if linear <= 0:
		return -80
	return log(linear) * 8.685889638  # 20 * log10(linear)

func db_to_linear(db):
	"""分贝转换为线性音量"""
	if db <= -80:
		return 0
	return pow(10, db / 20.0)

func tween_volume(audio_player, from_db, to_db, duration):
	"""淡入淡出音量"""
	if audio_player == null:
		return
	
	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", to_db, duration)

# 战斗相关音效函数
func play_martial_art_sound(martial_art_id, position=null):
	"""播放武学音效"""
	match martial_art_id:
		"basic_punch":
			play_sound_effect("sword_slash", position)
		"basic_sword":
			play_sound_effect("sword_slash", position)
		"fire_palm":
			play_sound_effect("fire_palm", position)
		"water_sword":
			play_sound_effect("water_sword", position)
		"wood_staff":
			play_sound_effect("wood_staff", position)
		"earth_fist":
			play_sound_effect("earth_fist", position)
		"metal_claw":
			play_sound_effect("metal_claw", position)
		"lightning_strike":
			play_sound_effect("lightning_strike", position)
		"shadow_step":
			play_sound_effect("shadow_step", position)
		"iron_clothes":
			play_sound_effect("iron_clothes", position)
		_:
			play_sound_effect("sword_slash", position)

func play_hit_sound(hit_type, position=null):
	"""播放命中音效"""
	match hit_type:
		"critical":
			play_sound_effect("hit_critical", position)
		"weakness":
			play_sound_effect("hit_weakness", position)
		"break":
			play_sound_effect("hit_break", position)
		"dodge":
			play_sound_effect("hit_dodge", position)
		_:
			play_sound_effect("hit_normal", position)

# 奇遇相关音效函数
func play_encounter_sound(encounter_type):
	"""播放奇遇音效"""
	match encounter_type:
		"jianghu_rumor":
			play_sound_effect("encounter_jianghu")
		"heavenly_treasure":
			play_sound_effect("encounter_treasure")
		"wise_master_guidance":
			play_sound_effect("encounter_wise_master")
		"secret_realm_discovery":
			play_sound_effect("encounter_secret_realm")
		_:
			play_sound_effect("encounter_trigger")

# UI相关音效函数
func play_button_click():
	"""播放按钮点击音效"""
	play_ui_sound("ui_button_click")

func play_menu_open():
	"""播放菜单打开音效"""
	play_ui_sound("ui_menu_open")

func play_menu_close():
	"""播放菜单关闭音效"""
	play_ui_sound("ui_menu_close")

func play_equip_item():
	"""播放装备音效"""
	play_ui_sound("ui_equip_item")

func play_level_up():
	"""播放升级音效"""
	play_ui_sound("ui_level_up")

func play_save_game():
	"""播放存档音效"""
	play_ui_sound("ui_save_game")

# 调试函数
func debug_print_audio_info():
	"""打印音频信息用于调试"""
	print("=== 音效系统信息 ===")
	print("音乐音量: %.2f" % config["music_volume"])
	print("音效音量: %.2f" % config["sfx_volume"])
	print("UI音量: %.2f" % config["ui_volume"])
	print("主音量: %.2f" % config["master_volume"])
	print("3D音效: %s" % ("启用" if config["spatial_enabled"] else "禁用"))
	print("当前背景音乐: %s" % ("是" if current_bgm != null else "否"))
	print("活动音效数量: %d" % active_sounds.size())
	print("====================")

# UI回调函数
func _on_test_bgm_pressed():
	"""测试背景音乐按钮回调"""
	print("=== 背景音乐测试 ===")
	
	# 测试主菜单BGM
	play_background_music("bgm_main_menu", 1.0)
	
	# 3秒后切换到战斗BGM
	await get_tree().create_timer(3.0).timeout
	play_background_music("bgm_combat", 1.0)
	
	# 再3秒后停止BGM
	await get_tree().create_timer(3.0).timeout
	stop_background_music(1.0)
	
	print("背景音乐测试完成")
	print("====================")

func _on_test_combat_sfx_pressed():
	"""测试战斗音效按钮回调"""
	print("=== 战斗音效测试 ===")
	
	# 测试各种武学音效
	play_martial_art_sound("basic_sword")
	play_martial_art_sound("fire_palm")
	play_martial_art_sound("water_sword")
	play_martial_art_sound("wood_staff")
	play_martial_art_sound("earth_fist")
	play_martial_art_sound("metal_claw")
	play_martial_art_sound("lightning_strike")
	
	# 测试命中音效
	play_hit_sound("normal")
	play_hit_sound("critical")
	play_hit_sound("weakness")
	play_hit_sound("break")
	play_hit_sound("dodge")
	
	print("战斗音效测试完成")
	print("====================")

func _on_test_encounter_sfx_pressed():
	"""测试奇遇音效按钮回调"""
	print("=== 奇遇音效测试 ===")
	
	# 测试各种奇遇音效
	play_encounter_sound("jianghu_rumor")
	play_encounter_sound("heavenly_treasure")
	play_encounter_sound("wise_master_guidance")
	play_encounter_sound("secret_realm_discovery")
	
	# 测试通用奇遇触发音效
	play_encounter_sound("unknown")
	
	print("奇遇音效测试完成")
	print("====================")

func _on_test_ui_sfx_pressed():
	"""测试UI音效按钮回调"""
	print("=== UI音效测试 ===")
	
	# 测试各种UI音效
	play_button_click()
	play_menu_open()
	play_menu_close()
	play_equip_item()
	play_level_up()
	play_save_game()
	
	print("UI音效测试完成")
	print("====================")