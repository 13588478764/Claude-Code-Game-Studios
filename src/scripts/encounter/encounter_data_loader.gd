## 奇遇数据加载器
## 加载 data/encounters/ 目录下的30个奇遇JSON文件，
## 注册到 DialogueManager 作为对话树，并提供按类型/条件查询的接口。
extends Node

## 已加载的奇遇元数据列表
var _encounters: Array[Dictionary] = []

## 奇遇ID到元数据的映射
var _encounter_map: Dictionary = {}

## 按类型索引
var _type_index: Dictionary = {}

## 已触发的奇遇ID（冷却/一次性控制）
var _triggered_ids: Dictionary = {}

const ENCOUNTER_DIR := "res://data/encounters/"

func _ready() -> void:
	call_deferred("_load_all_encounters")

func _load_all_encounters() -> void:
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager == null:
		push_warning("[EncounterDataLoader] DialogueManager 未找到，延迟加载")
		return

	var dir := DirAccess.open(ENCOUNTER_DIR)
	if dir == null:
		push_warning("[EncounterDataLoader] 目录不存在: %s" % ENCOUNTER_DIR)
		return

	var loaded := 0
	var failed := 0
	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var path := ENCOUNTER_DIR + file_name
			if _load_encounter_file(path, dialogue_manager):
				loaded += 1
			else:
				failed += 1
		file_name = dir.get_next()

	dir.list_dir_end()
	print("[EncounterDataLoader] 加载完成: %d 个奇遇, %d 个失败" % [loaded, failed])

func _load_encounter_file(path: String, dialogue_manager: Node) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[EncounterDataLoader] 无法打开: %s" % path)
		return false

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		push_warning("[EncounterDataLoader] JSON 解析失败: %s" % path)
		return false

	var data: Dictionary = json.data
	var encounter_id: String = data.get("id", "")
	if encounter_id.is_empty():
		push_warning("[EncounterDataLoader] 缺少 id 字段: %s" % path)
		return false

	# 存储奇遇元数据
	var meta := {
		"id": encounter_id,
		"title": data.get("title", ""),
		"description": data.get("description", ""),
		"type": data.get("type", ""),
		"probability": data.get("probability", 0.08),
		"trigger_conditions": data.get("trigger_conditions", {}),
		"dao_heart_alignment": data.get("dao_heart_alignment", "neutral"),
	}
	_encounters.append(meta)
	_encounter_map[encounter_id] = meta

	# 按类型索引
	var enc_type: String = meta.type
	if not _type_index.has(enc_type):
		_type_index[enc_type] = []
	_type_index[enc_type].append(meta)

	# 注册到 DialogueManager 作为对话树
	# encounter JSON 的 nodes 结构兼容 DialogueManager 的格式
	var dialogue_data := {
		"id": encounter_id,
		"title": data.get("title", ""),
		"description": data.get("description", ""),
		"start_node": data.get("start_node", ""),
		"metadata": {
			"source": "encounter",
			"encounter_type": enc_type,
			"dao_heart_alignment": meta.dao_heart_alignment,
		},
		"nodes": data.get("nodes", []),
	}

	if dialogue_manager.has_method("load_dialogue_from_dict"):
		if not dialogue_manager.load_dialogue_from_dict(dialogue_data):
			push_warning("[EncounterDataLoader] 注册对话树失败: %s" % encounter_id)
			return false
	else:
		push_warning("[EncounterDataLoader] DialogueManager 缺少 load_dialogue_from_dict 方法")
		return false

	return true

## 获取所有已加载奇遇的数量
func get_encounter_count() -> int:
	return _encounters.size()

## 按类型获取奇遇列表
func get_encounters_by_type(enc_type: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for meta in _type_index.get(enc_type, []):
		result.append(meta)
	return result

## 获取当前可触发的奇遇（按区域和境界过滤）
## 注：奇遇数据中的 region 值（如 zhongyuan）与游戏区域 ID（如 start_village）
## 使用不同的命名体系，暂不做严格区域过滤，所有奇遇在所有区域均可触发。
func get_available_encounters(region: String = "", _realm: String = "") -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for meta in _encounters:
		var conditions: Dictionary = meta.trigger_conditions

		# 冷却检查
		if _triggered_ids.has(meta.id):
			var cooldown_minutes: int = conditions.get("cooldown_minutes", 0)
			if cooldown_minutes > 0:
				var elapsed_ms: int = Time.get_ticks_msec() - int(_triggered_ids[meta.id])
				if elapsed_ms < cooldown_minutes * 60 * 1000:
					continue

		available.append(meta)
	return available

## 加权随机选择一个可用奇遇
func select_random_encounter(region: String = "", realm: String = "") -> Dictionary:
	var available := get_available_encounters(region, realm)
	if available.is_empty():
		return {}

	# 按 probability 加权选择
	var total_weight := 0.0
	for meta in available:
		total_weight += meta.probability

	if total_weight <= 0.0:
		return available[randi() % available.size()]

	var roll := randf() * total_weight
	var current := 0.0
	for meta in available:
		current += meta.probability
		if roll <= current:
			return meta

	return available[available.size() - 1]

## 标记奇遇已触发（记录时间戳）
func mark_triggered(encounter_id: String) -> void:
	_triggered_ids[encounter_id] = Time.get_ticks_msec()

## 获取奇遇元数据
func get_encounter_meta(encounter_id: String) -> Dictionary:
	return _encounter_map.get(encounter_id, {})

## 获取所有奇遇类型列表
func get_all_types() -> Array[String]:
	var types: Array[String] = []
	for t in _type_index.keys():
		types.append(t)
	return types

## 保存数据
func save_data() -> Dictionary:
	return {
		"triggered_ids": _triggered_ids.duplicate(),
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	_triggered_ids = data.get("triggered_ids", {})
