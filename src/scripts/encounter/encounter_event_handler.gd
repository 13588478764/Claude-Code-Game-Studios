## EncounterEventHandler
## 奇遇事件处理器
##
## 负责将奇遇系统集成到游戏流程中：
## - 监听全局事件并触发奇遇检查
## - 连接奇遇触发信号到奖励和记录系统
## - 处理奇遇触发后的完整流程
##
## 架构：通过 GameEvents 信号总线实现松耦合

extends Node

# ============================================================================
# 奇遇触发上下文常量
# ============================================================================

const TriggerContext = {
	"MAP_MOVEMENT": "MAP_MOVE",
	"BATTLE_VICTORY": "BATTLE_WIN",
	"REST_SAVE": "REST_SAVE",
	"SPECIAL_LOCATION": "SPECIAL_LOCATION"
}

# ============================================================================
# 信号定义
# ============================================================================

## 奇遇事件已处理（用于通知UI显示奇遇面板）
signal encounter_event_processed(encounter_type: String, encounter_id: String, reward_data: Dictionary)

## 奇遇触发失败（用于调试）
signal encounter_check_failed(trigger_type: String, reason: String)

# ============================================================================
# 成员变量
# ============================================================================

var _encounter_trigger_manager = null
var _encounter_record_manager = null
var _encounter_reward_manager = null
var _history_logger = null
var _history_persistence_manager = null
var _character_system = null
var _encounter_integration = null

var _is_initialized = false

# ============================================================================
# 生命周期方法
# ============================================================================

func _ready() -> void:
	# 延迟初始化，等待所有Autoload系统就绪
	call_deferred("_initialize_encounter_handler")

func _initialize_encounter_handler() -> void:
	if _is_initialized:
		return
	
	# 获取Autoload单例引用
	_encounter_trigger_manager = get_node_or_null("/root/EncounterSystem")
	_encounter_record_manager = get_node_or_null("/root/EncounterRecordManager")
	_encounter_reward_manager = get_node_or_null("/root/EncounterRewardManager")
	_history_logger = get_node_or_null("/root/HistoryLogger")
	_history_persistence_manager = get_node_or_null("/root/HistoryPersistenceManager")
	_character_system = get_node_or_null("/root/CharacterSystem")
	_encounter_integration = get_node_or_null("/root/EncounterIntegration")
	
	# 验证必需系统
	if _encounter_trigger_manager == null:
		push_warning("[EncounterEventHandler] EncounterSystem 未找到，奇遇触发将不可用")
		return
	
	if _encounter_record_manager == null:
		push_warning("[EncounterEventHandler] EncounterRecordManager 未找到，奇遇记录将不可用")
	
	if _history_logger == null:
		push_warning("[EncounterEventHandler] HistoryLogger 未找到，奇遇历史记录将不可用")
	
	# 连接奇遇触发信号
	if _encounter_trigger_manager != null:
		if _encounter_trigger_manager.has_signal("encounter_triggered"):
			_encounter_trigger_manager.encounter_triggered.connect(_on_encounter_triggered)
	
	# 连接全局事件信号
	_connect_global_events()
	
	_is_initialized = true
	print("[EncounterEventHandler] 奇遇事件处理器已初始化")

# ============================================================================
# 事件连接
# ============================================================================

func _connect_global_events() -> void:
	# 连接 GameEvents 信号
	var game_events = get_node_or_null("/root/GameEvents")
	if game_events != null:
		if game_events.has_signal("combat_ended"):
			game_events.combat_ended.connect(_on_combat_ended)
		if game_events.has_signal("nav_area_entered"):
			game_events.nav_area_entered.connect(_on_area_entered)
		if game_events.has_signal("system_save_completed"):
			game_events.system_save_completed.connect(_on_save_completed)
	
	print("[EncounterEventHandler] 全局事件连接完成")

# ============================================================================
# 事件处理器
# ============================================================================

## 战斗胜利时检查奇遇触发
func _on_combat_ended(victory: bool, rewards: Dictionary) -> void:
	if not victory:
		print("[EncounterEventHandler] 战斗失败，跳过奇遇触发检查")
		return
	
	if _encounter_trigger_manager == null or _character_system == null:
		return
	
	print("[EncounterEventHandler] 战斗胜利，检查奇遇触发...")
	_trigger_encounter(TriggerContext.BATTLE_VICTORY)

## 进入新区域时检查奇遇触发
func _on_area_entered(area_name: String, area_level: int) -> void:
	if _encounter_trigger_manager == null or _character_system == null:
		return
	
	print("[EncounterEventHandler] 进入区域 %s，检查奇遇触发..." % area_name)
	_trigger_encounter(TriggerContext.MAP_MOVEMENT)

## 存档完成时检查奇遇触发
func _on_save_completed() -> void:
	if _encounter_trigger_manager == null or _character_system == null:
		return
	
	print("[EncounterEventHandler] 存档完成，检查奇遇触发...")
	_trigger_encounter(TriggerContext.REST_SAVE)

# ============================================================================
# 奇遇触发流程
# ============================================================================

## 触发奇遇检查
func _trigger_encounter(trigger_type: String) -> void:
	if _encounter_trigger_manager == null:
		return
	
	# 获取玩家福缘属性
	var luck_stat = 0.0
	if _character_system != null and _character_system.has_node("attributes") or (_character_system.attributes != null):
		luck_stat = _character_system.attributes.luck
	
	# 执行奇遇触发检查
	var triggered = _encounter_trigger_manager.trigger_encounter_check(trigger_type, luck_stat)
	
	if triggered:
		print("[EncounterEventHandler] ✨ 奇遇触发成功！类型: %s" % trigger_type)
	else:
		print("[EncounterEventHandler] 奇遇未触发，连续失败次数: %d" % _encounter_trigger_manager.consecutive_failures)

## 奇遇触发后的处理
func _on_encounter_triggered(encounter_type: String, encounter_id: String) -> void:
	print("[EncounterEventHandler] 处理奇遇: %s (%s)" % [encounter_type, encounter_id])
	
	# 1. 记录奇遇到历史
	_log_encounter_history(encounter_type, encounter_id)
	
	# 2. 发放奇遇奖励
	var reward_data = _grant_encounter_rewards(encounter_type, encounter_id)
	
	# 3. 更新奇遇记录状态
	_update_encounter_record(encounter_id)
	
	# 4. 持久化历史记录
	_persist_history()
	
	# 5. 通知UI显示奇遇面板
	emit_signal("encounter_event_processed", encounter_type, encounter_id, reward_data)
	
	print("[EncounterEventHandler] 奇遇处理完成")

# ============================================================================
# 奇遇处理子流程
# ============================================================================

func _log_encounter_history(encounter_type: String, encounter_id: String) -> void:
	if _history_logger == null:
		return
	
	var encounter_data = {
		"id": encounter_id,
		"title": _get_encounter_title(encounter_type),
		"type": encounter_type,
		"outcome": "success",
		"rewards": [],
		"position": Vector2.ZERO,
		"weather": "sunny",
		"player_data": _get_player_data_snapshot()
	}
	
	var record_id = _history_logger.log_encounter(encounter_data)
	if not record_id.is_empty():
		print("[EncounterEventHandler] 奇遇历史记录已创建: %s" % record_id)
	else:
		push_warning("[EncounterEventHandler] 奇遇历史记录创建失败")

func _grant_encounter_rewards(encounter_type: String, encounter_id: String) -> Dictionary:
	var reward_data = {}
	
	# 尝试使用 EncounterIntegration 发放奖励
	if _encounter_integration != null:
		var encounter_data = {
			"id": encounter_id,
			"type": encounter_type
		}
		var success = _encounter_integration.grant_encounter_rewards(encounter_type, encounter_data)
		reward_data["success"] = success
		reward_data["source"] = "EncounterIntegration"
		return reward_data
	
	# 如果 EncounterIntegration 不可用，尝试直接使用 EncounterRewardManager
	if _encounter_reward_manager != null:
		if _encounter_reward_manager.has_method("generate_reward_package"):
			var rewards = _encounter_reward_manager.generate_reward_package(encounter_type, 0.0)
			reward_data["rewards"] = rewards
			reward_data["success"] = true
			reward_data["source"] = "EncounterRewardManager"
			return reward_data
	
	# 降级处理：使用默认奖励
	push_warning("[EncounterEventHandler] 奖励系统不可用，使用默认奖励")
	reward_data["fallback"] = true
	reward_data["success"] = false
	return reward_data

func _update_encounter_record(encounter_id: String) -> void:
	if _encounter_record_manager != null:
		if _encounter_record_manager.has_method("mark_encounter_completed"):
			_encounter_record_manager.mark_encounter_completed(encounter_id)
			print("[EncounterEventHandler] 奇遇完成状态已更新")

func _persist_history() -> void:
	if _history_persistence_manager != null:
		if _history_persistence_manager.has_method("save_to_file"):
			_history_persistence_manager.save_to_file()
			print("[EncounterEventHandler] 奇遇历史已持久化")

# ============================================================================
# 辅助方法
# ============================================================================

func _get_encounter_title(encounter_type: String) -> String:
	match encounter_type:
		"JiangHuRumor":
			return "江湖传闻"
		"TianCaiDiBao":
			return "天材地宝"
		"GaoRenZhiDian":
			return "高人指点"
		"ShiChuanMiJi":
			return "失传秘籍"
		"MiJingChallenge":
			return "秘境挑战"
		_:
			return "未知奇遇"

func _get_player_data_snapshot() -> Dictionary:
	if _character_system == null:
		return {"level": 1, "realm": "", "attributes": {}}
	
	# 注意：Object.get(name) 只接受 1 个参数，找不到属性返回 null
	# 不能像 Dictionary.get(key, default) 那样传第二个默认值参数
	var level_value = _character_system.get("level")
	if level_value == null:
		level_value = 1
	
	var realm_value = _character_system.get("realm_name")
	if realm_value == null:
		realm_value = ""
	
	return {
		"level": level_value,
		"realm": realm_value,
		"attributes": _get_character_attributes()
	}

func _get_character_attributes() -> Dictionary:
	if _character_system == null:
		return {}
	
	if _character_system.attributes != null:
		if _character_system.attributes.has_method("get_total"):
			return _character_system.attributes.get_total()
	
	return {}

# ============================================================================
# 公共API
# ============================================================================

## 手动触发奇遇检查（供外部系统调用）
func manual_trigger_encounter_check(trigger_type: String) -> void:
	_trigger_encounter(trigger_type)

## 获取奇遇系统状态信息
func get_encounter_status_info() -> Dictionary:
	var info = {
		"initialized": _is_initialized,
		"trigger_manager_active": _encounter_trigger_manager != null,
		"record_manager_active": _encounter_record_manager != null,
		"reward_manager_active": _encounter_reward_manager != null,
		"history_logger_active": _history_logger != null,
		"persistence_manager_active": _history_persistence_manager != null,
		"integration_active": _encounter_integration != null
	}
	
	if _encounter_trigger_manager != null:
		info["consecutive_failures"] = _encounter_trigger_manager.consecutive_failures
		info["encounter_history_count"] = _encounter_trigger_manager.encounter_history.size()
	
	if _encounter_record_manager != null:
		info["completed_encounters"] = _encounter_record_manager.completed_encounters.size()
		info["record_history_count"] = _encounter_record_manager.encounter_history.size()
	
	return info
