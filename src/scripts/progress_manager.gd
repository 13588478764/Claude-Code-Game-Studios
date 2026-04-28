extends Node

# 玩家进度管理器 - 负责协调所有保存触发条件和管理存档槽位
# 符合ADR-001架构决策：组件化设计，使用Godot信号系统

# 依赖的保存和加载组件
@onready var world_state_saver = $WorldStateSaver
@onready var world_state_loader = $WorldStateLoader

# 存档槽位配置
const MAX_SAVE_SLOTS = 5
const AUTO_SAVE_INTERVAL_REAL_TIME = 600  # 10分钟（现实时间）
const AUTO_SAVE_INTERVAL_GAME_TIME = 1800  # 30分钟（游戏内时间）

# 当前存档槽位
var current_save_slot = 0
var save_slots = []

# 自动保存计时器
var last_auto_save_real_time = 0
var last_auto_save_game_time = 0

# Steam Cloud集成（如果可用）
var steam_cloud_available = false

# 信号：自动保存触发
signal auto_save_triggered(reason: String)
# 信号：手动保存请求
signal manual_save_requested(slot_index: int)
# 信号：关键事件保存触发
signal checkpoint_save_triggered(event_name: String)
# 信号：云同步状态变化
signal cloud_sync_status_changed(status: String)

func _ready() -> void:
	# 初始化存档槽位
	_initialize_save_slots()
	
	# 检查Steam Cloud可用性
	_check_steam_cloud_availability()
	
	# 连接保存完成信号
	world_state_saver.connect("save_completed", _on_save_completed)
	world_state_saver.connect("save_failed", _on_save_failed)
	
	# 连接加载完成信号
	world_state_loader.connect("load_completed", _on_load_completed)
	world_state_loader.connect("load_failed", _on_load_failed)
	
	# 初始化自动保存计时器
	last_auto_save_real_time = OS.get_unix_time()
	last_auto_save_game_time = get_game_time()

func _process(delta: float) -> void:
	# 检查自动保存条件
	_check_auto_save_conditions()

# 初始化存档槽位
func _initialize_save_slots() -> void:
	save_slots.resize(MAX_SAVE_SLOTS)
	for i in range(MAX_SAVE_SLOTS):
		save_slots[i] = {
			"slot_index": i,
			"save_path": "user://saves/slot_" + str(i) + "/save_data.sav",
			"last_save_time": 0,
			"player_level": 1,
			"location": "",
			"cloud_synced": false
		}

# 检查Steam Cloud可用性
func _check_steam_cloud_availability() -> void:
	# 检查是否在Steam环境中运行
	if Engine.has_singleton("Steam"):
		steam_cloud_available = true
		print("Steam Cloud available")
	else:
		steam_cloud_available = false
		print("Steam Cloud not available")

# 检查自动保存条件
func _check_auto_save_conditions() -> void:
	var current_real_time = OS.get_unix_time()
	var current_game_time = get_game_time()
	
	# 检查现实时间间隔
	if current_real_time - last_auto_save_real_time >= AUTO_SAVE_INTERVAL_REAL_TIME:
		trigger_auto_save("real_time_interval")
		last_auto_save_real_time = current_real_time
	
	# 检查游戏内时间间隔
	if current_game_time - last_auto_save_game_time >= AUTO_SAVE_INTERVAL_GAME_TIME:
		trigger_auto_save("game_time_interval")
		last_auto_save_game_time = current_game_time

# 触发自动保存
func trigger_auto_save(reason: String) -> void:
	emit_signal("auto_save_triggered", reason)
	
	# 获取当前游戏状态
	var current_save_data = _collect_current_game_state()
	
	# 执行保存（使用差分保存以提高效率）
	world_state_saver.save_game_differential(current_save_data, save_slots[current_save_slot]["save_path"])
	
	# 更新存档槽位信息
	save_slots[current_save_slot]["last_save_time"] = OS.get_unix_time()
	save_slots[current_save_slot]["player_level"] = get_player_level()
	save_slots[current_save_slot]["location"] = get_current_location()

# 手动保存请求
func request_manual_save(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		print("Invalid save slot index: ", slot_index)
		return
	
	emit_signal("manual_save_requested", slot_index)
	current_save_slot = slot_index
	
	# 获取当前游戏状态
	var current_save_data = _collect_current_game_state()
	
	# 执行完整保存
	world_state_saver.save_game(current_save_data, save_slots[slot_index]["save_path"])
	
	# 更新存档槽位信息
	save_slots[slot_index]["last_save_time"] = OS.get_unix_time()
	save_slots[slot_index]["player_level"] = get_player_level()
	save_slots[slot_index]["location"] = get_current_location()

# 触发关键事件强制保存
func trigger_checkpoint_save(event_name: String) -> void:
	emit_signal("checkpoint_save_triggered", event_name)
	
	# 获取当前游戏状态
	var current_save_data = _collect_current_game_state()
	
	# 执行完整保存（关键事件需要完整保存）
	world_state_saver.save_game(current_save_data, save_slots[current_save_slot]["save_path"])
	
	# 更新存档槽位信息
	save_slots[current_save_slot]["last_save_time"] = OS.get_unix_time()
	save_slots[current_save_slot]["player_level"] = get_player_level()
	save_slots[current_save_slot]["location"] = get_current_location()

# 收集当前游戏状态
func _collect_current_game_state() -> WorldStateSaver.SaveData:
	var save_data = WorldStateSaver.SaveData.new()
	
	# 填充玩家核心状态
	save_data.player_core_state.level = get_player_level()
	save_data.player_core_state.realm = get_player_realm()
	save_data.player_core_state.health_current = get_player_health_current()
	save_data.player_core_state.health_max = get_player_health_max()
	save_data.player_core_state.energy_current = get_player_energy_current()
	save_data.player_core_state.energy_max = get_player_energy_max()
	save_data.player_core_state.experience = get_player_experience()
	save_data.player_core_state.silver = get_player_silver()
	save_data.player_core_state.attributes = get_player_attributes()
	save_data.player_core_state.position = get_player_position()
	save_data.player_core_state.rotation = get_player_rotation()
	save_data.player_core_state.inventory = get_player_inventory()
	save_data.player_core_state.equipment = get_player_equipment()
	save_data.player_core_state.quick_slots = get_player_quick_slots()
	save_data.player_core_state.martial_arts = get_player_martial_arts()
	save_data.player_core_state.equipped_martial_arts = get_player_equipped_martial_arts()
	save_data.player_core_state.talent_tree_points = get_player_talent_tree_points()
	save_data.player_core_state.talent_tree_allocation = get_player_talent_tree_allocation()
	
	# 填充世界探索状态
	save_data.world_exploration_state.explored_chunks = get_explored_chunks()
	save_data.world_exploration_state.poi_states = get_poi_states()
	save_data.world_exploration_state.unique_encounters_triggered = get_unique_encounters_triggered()
	
	# 填充任务与叙事进度
	save_data.quest_narrative_progress.active_quests = get_active_quests()
	save_data.quest_narrative_progress.completed_quests = get_completed_quests()
	save_data.quest_narrative_progress.npc_states = get_npc_states()
	
	# 填充环境与实体状态
	save_data.environment_entity_state.boss_states = get_boss_states()
	save_data.environment_entity_state.dynamic_entities = get_dynamic_entities()
	save_data.environment_entity_state.game_time = get_game_time()
	save_data.environment_entity_state.weather = get_current_weather()
	
	return save_data

# 加载指定存档槽位
func load_save_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		print("Invalid save slot index: ", slot_index)
		return
	
	var save_path = save_slots[slot_index]["save_path"]
	world_state_loader.load_game(save_path)

# 获取存档槽位信息
func get_save_slot_info(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return {}
	return save_slots[slot_index].duplicate()

# 获取所有存档槽位信息
func get_all_save_slots_info() -> Array:
	var slots_info = []
	for i in range(MAX_SAVE_SLOTS):
		slots_info.append(save_slots[i].duplicate())
	return slots_info

# 删除存档槽位
func delete_save_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return false
	
	var save_path = save_slots[slot_index]["save_path"]
	var result = world_state_loader.delete_save(save_path)
	
	if result:
		# 重置存档槽位信息
		save_slots[slot_index]["last_save_time"] = 0
		save_slots[slot_index]["player_level"] = 1
		save_slots[slot_index]["location"] = ""
		save_slots[slot_index]["cloud_synced"] = false
	
	return result

# 云同步存档
func sync_save_to_cloud(slot_index: int) -> void:
	if not steam_cloud_available:
		print("Steam Cloud not available")
		return
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		print("Invalid save slot index: ", slot_index)
		return
	
	var save_path = save_slots[slot_index]["save_path"]
	
	# 读取本地存档文件
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("Failed to read save file for cloud sync: ", save_path)
		return
	
	var save_data = file.get_as_text()
	file.close()
	
	# 上传到Steam Cloud
	_upload_to_steam_cloud("save_slot_" + str(slot_index) + ".sav", save_data)
	save_slots[slot_index]["cloud_synced"] = true
	emit_signal("cloud_sync_status_changed", "synced")

# 从云下载存档
func download_save_from_cloud(slot_index: int) -> void:
	if not steam_cloud_available:
		print("Steam Cloud not available")
		return
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		print("Invalid save slot index: ", slot_index)
		return
	
	# 从Steam Cloud下载
	var cloud_data = _download_from_steam_cloud("save_slot_" + str(slot_index) + ".sav")
	if cloud_data == "":
		print("Failed to download save from cloud")
		return
	
	# 写入本地存档文件
	var save_path = save_slots[slot_index]["save_path"]
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("Failed to write save file from cloud: ", save_path)
		return
	
	file.store_string(cloud_data)
	file.close()
	
	save_slots[slot_index]["cloud_synced"] = true
	emit_signal("cloud_sync_status_changed", "downloaded")

# 检测云冲突
func check_cloud_conflict(slot_index: int) -> bool:
	if not steam_cloud_available:
		return false
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return false
	
	var save_path = save_slots[slot_index]["save_path"]
	
	# 获取本地存档修改时间
	var dir = Directory.new()
	if not dir.file_exists(save_path):
		return false
	
	var local_modified_time = dir.get_modified_time(save_path)
	
	# 获取云端存档修改时间（模拟）
	var cloud_modified_time = _get_cloud_file_modified_time("save_slot_" + str(slot_index) + ".sav")
	
	# 检查是否有冲突
	return local_modified_time != cloud_modified_time and local_modified_time > cloud_modified_time

# 解决云冲突
func resolve_cloud_conflict(slot_index: int, keep_local: bool) -> void:
	if not steam_cloud_available:
		return
	
	if slot_index < 0 or slot_index >= MAX_SAVE_SLOTS:
		return
	
	if keep_local:
		# 保留本地版本，上传到云端
		sync_save_to_cloud(slot_index)
	else:
		# 下载云端版本，覆盖本地
		download_save_from_cloud(slot_index)

# 上传到Steam Cloud（模拟实现）
func _upload_to_steam_cloud(file_name: String, data: String) -> void:
	if not steam_cloud_available:
		return
	
	# 实际项目中这里会调用Steam API
	# Steam.remote_storage_file_write(file_name, data.to_utf8())
	print("Uploaded to Steam Cloud: ", file_name)

# 从Steam Cloud下载（模拟实现）
func _download_from_steam_cloud(file_name: String) -> String:
	if not steam_cloud_available:
		return ""
	
	# 实际项目中这里会调用Steam API
	# var data = Steam.remote_storage_file_read(file_name)
	# return data.get_string()
	print("Downloaded from Steam Cloud: ", file_name)
	return ""

# 获取云端文件修改时间（模拟实现）
func _get_cloud_file_modified_time(file_name: String) -> int:
	if not steam_cloud_available:
		return 0
	
	# 实际项目中这里会查询Steam Cloud文件信息
	# var file_info = Steam.remote_storage_get_file_info(file_name)
	# return file_info.mtime
	return OS.get_unix_time() - 3600  # 模拟1小时前的修改时间

# 保存完成回调
func _on_save_completed(save_path: String) -> void:
	print("Save completed: ", save_path)
	
	# 如果Steam Cloud可用，自动同步
	if steam_cloud_available:
		# 获取存档槽位索引
		var slot_index = -1
		for i in range(MAX_SAVE_SLOTS):
			if save_slots[i]["save_path"] == save_path:
				slot_index = i
				break
		
		if slot_index != -1:
			sync_save_to_cloud(slot_index)

# 保存失败回调
func _on_save_failed(error_message: String) -> void:
	print("Save failed: ", error_message)
	# 这里可以显示错误UI或记录日志

# 加载完成回调
func _on_load_completed(save_data: Dictionary) -> void:
	print("Load completed")
	# 应用加载的游戏状态
	_apply_loaded_game_state(save_data)

# 加载失败回调
func _on_load_failed(error_message: String) -> void:
	print("Load failed: ", error_message)
	# 这里可以显示错误UI或提供恢复选项

# 应用加载的游戏状态
func _apply_loaded_game_state(save_data: Dictionary) -> void:
	# 这里需要实现将加载的数据应用到游戏世界中
	# 由于这是一个框架实现，具体的实现会依赖于其他系统
	pass

# 以下方法需要由其他系统实现或通过信号连接
# 这些是占位符方法，实际项目中会被替换为具体的实现

func get_player_level() -> int:
	# 实际实现应该从角色系统获取
	return 1

func get_player_realm() -> int:
	# 实际实现应该从角色系统获取
	return 1

func get_player_health_current() -> int:
	# 实际实现应该从战斗系统获取
	return 100

func get_player_health_max() -> int:
	# 实际实现应该从战斗系统获取
	return 100

func get_player_energy_current() -> int:
	# 实际实现应该从内力系统获取
	return 50

func get_player_energy_max() -> int:
	# 实际实现应该从内力系统获取
	return 50

func get_player_experience() -> int:
	# 实际实现应该从经验系统获取
	return 0

func get_player_silver() -> int:
	# 实际实现应该从经济系统获取
	return 0

func get_player_attributes() -> Dictionary:
	# 实际实现应该从属性系统获取
	return {
		"strength": 10,
		"agility": 10,
		"constitution": 10,
		"intelligence": 10,
		"willpower": 10,
		"fortune": 10
	}

func get_player_position() -> Vector2:
	# 实际实现应该从世界系统获取
	return Vector2.ZERO

func get_player_rotation() -> float:
	# 实际实现应该从世界系统获取
	return 0.0

func get_player_inventory() -> Array:
	# 实际实现应该从装备系统获取
	return []

func get_player_equipment() -> Dictionary:
	# 实际实现应该从装备系统获取
	return {}

func get_player_quick_slots() -> Array:
	# 实际实现应该从UI系统获取
	return []

func get_player_martial_arts() -> Array:
	# 实际实现应该从武学系统获取
	return []

func get_player_equipped_martial_arts() -> Array:
	# 实际实现应该从武学系统获取
	return []

func get_player_talent_tree_points() -> int:
	# 实际实现应该从天赋系统获取
	return 0

func get_player_talent_tree_allocation() -> Dictionary:
	# 实际实现应该从天赋系统获取
	return {}

func get_explored_chunks() -> Dictionary:
	# 实际实现应该从探索系统获取
	return {}

func get_poi_states() -> Dictionary:
	# 实际实现应该从POI系统获取
	return {}

func get_unique_encounters_triggered() -> Array:
	# 实际实现应该从奇遇系统获取
	return []

func get_active_quests() -> Dictionary:
	# 实际实现应该从任务系统获取
	return {}

func get_completed_quests() -> Array:
	# 实际实现应该从任务系统获取
	return []

func get_npc_states() -> Dictionary:
	# 实际实现应该从NPC系统获取
	return {}

func get_boss_states() -> Dictionary:
	# 实际实现应该从Boss系统获取
	return {}

func get_dynamic_entities() -> Dictionary:
	# 实际实现应该从实体管理系统获取
	return {}

func get_game_time() -> int:
	# 实际实现应该从时间系统获取
	return 0

func get_current_weather() -> String:
	# 实际实现应该从天气系统获取
	return "clear"

func get_current_location() -> String:
	# 实际实现应该从世界系统获取
	return "unknown"