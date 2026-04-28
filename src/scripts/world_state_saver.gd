extends Node

# 世界状态保存器 - 负责将游戏状态序列化为JSON并保存到本地存储
# 符合ADR-001架构决策：使用JSON格式本地存储，组件化设计

# 加密密钥（可以从游戏版本或玩家ID派生）
const ENCRYPTION_KEY = "wuxia_jianghu_2026"

# 保存数据结构
class SaveData:
	# 玩家核心状态
	var player_core_state = PlayerCoreState.new()
	# 世界探索状态  
	var world_exploration_state = WorldExplorationState.new()
	# 任务与叙事进度
	var quest_narrative_progress = QuestNarrativeProgress.new()
	# 环境与实体状态
	var environment_entity_state = EnvironmentEntityState.new()
	
	func to_dict() -> Dictionary:
		return {
			"player_core_state": player_core_state.to_dict(),
			"world_exploration_state": world_exploration_state.to_dict(),
			"quest_narrative_progress": quest_narrative_progress.to_dict(),
			"environment_entity_state": environment_entity_state.to_dict()
		}
	
	func from_dict(data: Dictionary) -> void:
		if data.has("player_core_state"):
			player_core_state.from_dict(data["player_core_state"])
		if data.has("world_exploration_state"):
			world_exploration_state.from_dict(data["world_exploration_state"])
		if data.has("quest_narrative_progress"):
			quest_narrative_progress.from_dict(data["quest_narrative_progress"])
		if data.has("environment_entity_state"):
			environment_entity_state.from_dict(data["environment_entity_state"])

# 玩家核心状态数据结构
class PlayerCoreState:
	var level = 1
	var realm = 1  # 境界(1-10)
	var health_current = 100
	var health_max = 100
	var energy_current = 50
	var energy_max = 50
	var experience = 0
	var silver = 0
	var attributes = {  # 六维属性
		"strength": 10,      # 力道
		"agility": 10,       # 身法  
		"constitution": 10,   # 根骨
		"intelligence": 10,   # 悟性
		"willpower": 10,      # 定力
		"fortune": 10         # 福缘
	}
	var position = Vector2.ZERO
	var rotation = 0.0
	var inventory = []
	var equipment = {}
	var quick_slots = []
	var martial_arts = []
	var equipped_martial_arts = []
	var talent_tree_points = 0
	var talent_tree_allocation = {}
	
	func to_dict() -> Dictionary:
		return {
			"level": level,
			"realm": realm,
			"health_current": health_current,
			"health_max": health_max,
			"energy_current": energy_current,
			"energy_max": energy_max,
			"experience": experience,
			"silver": silver,
			"attributes": attributes.duplicate(),
			"position": [position.x, position.y],
			"rotation": rotation,
			"inventory": inventory.duplicate(),
			"equipment": equipment.duplicate(),
			"quick_slots": quick_slots.duplicate(),
			"martial_arts": martial_arts.duplicate(),
			"equipped_martial_arts": equipped_martial_arts.duplicate(),
			"talent_tree_points": talent_tree_points,
			"talent_tree_allocation": talent_tree_allocation.duplicate()
		}
	
	func from_dict(data: Dictionary) -> void:
		if data.has("level"): level = data["level"]
		if data.has("realm"): realm = data["realm"]
		if data.has("health_current"): health_current = data["health_current"]
		if data.has("health_max"): health_max = data["health_max"]
		if data.has("energy_current"): energy_current = data["energy_current"]
		if data.has("energy_max"): energy_max = data["energy_max"]
		if data.has("experience"): experience = data["experience"]
		if data.has("silver"): silver = data["silver"]
		if data.has("attributes"): attributes = data["attributes"].duplicate()
		if data.has("position"): position = Vector2(data["position"][0], data["position"][1])
		if data.has("rotation"): rotation = data["rotation"]
		if data.has("inventory"): inventory = data["inventory"].duplicate()
		if data.has("equipment"): equipment = data["equipment"].duplicate()
		if data.has("quick_slots"): quick_slots = data["quick_slots"].duplicate()
		if data.has("martial_arts"): martial_arts = data["martial_arts"].duplicate()
		if data.has("equipped_martial_arts"): equipped_martial_arts = data["equipped_martial_arts"].duplicate()
		if data.has("talent_tree_points"): talent_tree_points = data["talent_tree_points"]
		if data.has("talent_tree_allocation"): talent_tree_allocation = data["talent_tree_allocation"].duplicate()

# 世界探索状态数据结构
class WorldExplorationState:
	var explored_chunks = {}  # 区块探索状态
	var poi_states = {}       # 兴趣点状态
	var unique_encounters_triggered = []  # 已触发的唯一性奇遇
	
	func to_dict() -> Dictionary:
		return {
			"explored_chunks": explored_chunks.duplicate(),
			"poi_states": poi_states.duplicate(),
			"unique_encounters_triggered": unique_encounters_triggered.duplicate()
		}
	
	func from_dict(data: Dictionary) -> void:
		if data.has("explored_chunks"): explored_chunks = data["explored_chunks"].duplicate()
		if data.has("poi_states"): poi_states = data["poi_states"].duplicate()
		if data.has("unique_encounters_triggered"): unique_encounters_triggered = data["unique_encounters_triggered"].duplicate()

# 任务与叙事进度数据结构
class QuestNarrativeProgress:
	var active_quests = {}
	var completed_quests = []
	var npc_states = {}
	
	func to_dict() -> Dictionary:
		return {
			"active_quests": active_quests.duplicate(),
			"completed_quests": completed_quests.duplicate(),
			"npc_states": npc_states.duplicate()
		}
	
	func from_dict(data: Dictionary) -> void:
		if data.has("active_quests"): active_quests = data["active_quests"].duplicate()
		if data.has("completed_quests"): completed_quests = data["completed_quests"].duplicate()
		if data.has("npc_states"): npc_states = data["npc_states"].duplicate()

# 环境与实体状态数据结构
class EnvironmentEntityState:
	var boss_states = {}
	var dynamic_entities = {}
	var game_time = 0
	var weather = "clear"
	
	func to_dict() -> Dictionary:
		return {
			"boss_states": boss_states.duplicate(),
			"dynamic_entities": dynamic_entities.duplicate(),
			"game_time": game_time,
			"weather": weather
		}
	
	func from_dict(data: Dictionary) -> void:
		if data.has("boss_states"): boss_states = data["boss_states"].duplicate()
		if data.has("dynamic_entities"): dynamic_entities = data["dynamic_entities"].duplicate()
		if data.has("game_time"): game_time = data["game_time"]
		if data.has("weather"): weather = data["weather"]

# 上次保存的状态（用于差分存储）
var last_saved_data: SaveData = null

# 信号：保存完成
signal save_completed(save_path: String)
# 信号：保存失败
signal save_failed(error_message: String)

# 保存游戏状态到指定路径
func save_game(save_data: SaveData, save_path: String) -> void:
	# 在后台线程中执行保存操作，避免阻塞主线程
	var thread = Thread.new()
	thread.start(_save_game_thread.bind(save_data, save_path))

# 后台线程保存函数
func _save_game_thread(save_data: SaveData, save_path: String) -> void:
	var result = _perform_save(save_data, save_path)
	if result.success:
		call_deferred("emit_signal", "save_completed", save_path)
	else:
		call_deferred("emit_signal", "save_failed", result.error_message)

# 执行实际的保存操作
func _perform_save(save_data: SaveData, save_path: String) -> Dictionary:
	var result = {"success": false, "error_message": ""}
	
	# 创建保存数据字典
	var save_dict = save_data.to_dict()
	
	# 序列化为JSON字符串
	var json_string = JSON.stringify(save_dict, "\t")
	if json_string == "":
		result.error_message = "Failed to serialize save data to JSON"
		return result
	
	# 加密JSON字符串（Base64 + XOR）
	var encrypted_data = _encrypt_data(json_string)
	
	# 创建目录（如果不存在）
	var dir = Directory.new()
	var path_parts = save_path.split("/")
	var current_path = ""
	for i in range(path_parts.size() - 1):
		current_path += path_parts[i] + "/"
		if not dir.dir_exists(current_path):
			dir.make_dir_recursive(current_path)
	
	# 写入文件
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		result.error_message = "Failed to open file for writing: " + save_path
		return result
	
	file.store_string(encrypted_data)
	file.close()
	
	# 创建备份文件（保留最近3个备份）
	_create_backup(save_path)
	
	# 更新上次保存的数据（用于差分存储）
	last_saved_data = save_data
	
	result.success = true
	return result

# 加密数据（简单的Base64 + XOR）
func _encrypt_data(data: String) -> String:
	# Base64编码
	var base64_data = Marshalls.raw_to_base64(data.to_utf8())
	
	# XOR加密
	var xor_result = ""
	for i in range(base64_data.length()):
		var char_code = base64_data.ord_at(i)
		var key_char = ENCRYPTION_KEY.ord_at(i % ENCRYPTION_KEY.length())
		xor_result += char(char_code ^ key_char)
	
	return xor_result

# 创建备份文件
func _create_backup(save_path: String) -> void:
	var backup_dir = save_path.get_base_dir() + "/backups/"
	var dir = Directory.new()
	if not dir.dir_exists(backup_dir):
		dir.make_dir_recursive(backup_dir)
	
	# 获取当前时间戳
	var timestamp = str(OS.get_unix_time())
	var backup_path = backup_dir + "backup_" + timestamp + ".sav"
	
	# 复制当前存档到备份
	dir.copy(save_path, backup_path)
	
	# 清理旧的备份文件（只保留最近3个）
	_cleanup_old_backups(backup_dir, 3)

# 清理旧的备份文件
func _cleanup_old_backups(backup_dir: String, max_backups: int) -> void:
	var dir = Directory.new()
	if not dir.dir_exists(backup_dir):
		return
	
	dir.open(backup_dir)
	dir.list_dir_begin()
	
	var backup_files = []
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("backup_") and file_name.ends_with(".sav"):
			backup_files.append(file_name)
		file_name = dir.get_next()
	
	# 按时间戳排序（最新的在前面）
	backup_files.sort_custom(func(a, b): return a > b)
	
	# 删除多余的备份文件
	for i in range(max_backups, backup_files.size()):
		dir.remove(backup_dir + backup_files[i])

# 差分保存 - 只保存变化的数据
func save_game_differential(current_data: SaveData, save_path: String) -> void:
	if last_saved_data == null:
		# 如果没有上次保存的数据，执行完整保存
		save_game(current_data, save_path)
		return
	
	# 比较当前数据和上次保存的数据，只保存变化的部分
	var differential_data = _compute_differential(current_data, last_saved_data)
	save_game(differential_data, save_path)

# 计算差分数据
func _compute_differential(current: SaveData, previous: SaveData) -> SaveData:
	var diff = SaveData.new()
	
	# 这里可以实现更精细的差分逻辑
	# 为了简化，我们直接返回当前数据（实际项目中可以优化）
	return current