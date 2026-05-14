## QuestTriggerManager
## 任务触发管理器
##
## 负责检查NPC个人线的解锁条件（关系值、境界等），并在条件满足时自动触发任务。
##
## 功能：
## - 监听关系值变化，达到阈值时解锁对应NPC个人线
## - 检查境界要求（炼气初期、中期、后期等）
## - 支持前置任务完成检查
## - 跟踪任务进度（收集物品、击杀敌人、完成奇遇等）
## - 自动将符合条件的任务状态从 LOCKED 转为 AVAILABLE
##
## 依赖系统：
## - QuestManager（任务系统）
## - RelationshipManager（关系系统）
## - CharacterSystem（角色系统）
## - CombatSystem（战斗系统，可选）
## - EncounterSystem（奇遇系统，可选）

extends Node

# ============================================================================
# 信号定义
# ============================================================================

## 任务已解锁（条件满足）
signal quest_unlocked(quest_id: String, npc_id: String)

## 任务条件不足
signal quest_locked(quest_id: String, npc_id: String, missing_conditions: Array)

## 关系值达到任务阈值
signal relationship_threshold_reached(npc_id: String, threshold: int, quest_id: String)

# ============================================================================
# 任务触发条件配置
# ============================================================================

# NPC个人线触发条件映射
# 格式: quest_id -> { "npc_id": String, "relationship_threshold": int, "realm_requirement": int, "prerequisites": Array }
var quest_trigger_conditions: Dictionary = {}

# 系统引用
var _quest_manager: Node = null
var _relationship_manager: Node = null
var _character_system: Node = null
var _combat_system: Node = null
var _encounter_system: Node = null

# 任务进度跟踪数据
# 格式: quest_id -> { "objective_type": String, "progress": int }
var quest_progress: Dictionary = {}

# 进度触发器配置
# 格式: quest_id -> { "progress_type": String, "target_id": String, "target_count": int, "npc_id": String }
var quest_progress_conditions: Dictionary = {}

# ============================================================================
# 境界要求映射（对应 CharacterSystem 的 REALMS）
# ============================================================================

# 境界索引与名称对应
const REALM_REQUIREMENTS = {
	"qi_condensation_early": 0,    # 炼气初期
	"qi_condensation_mid": 1,      # 炼气中期
	"qi_condensation_late": 2,     # 炼气后期
	"foundation_establishment_early": 3,  # 筑基初期
	"foundation_establishment_mid": 4,    # 筑基中期
	"foundation_establishment_late": 5,   # 筑基后期
	"golden_core_early": 6,        # 金丹初期
	"golden_core_mid": 7,          # 金丹中期
	"golden_core_late": 8,         # 金丹后期
}

func _ready():
	# 获取系统引用
	_quest_manager = get_node_or_null("/root/QuestSystem")
	_relationship_manager = get_node_or_null("/root/RelationshipManager")
	_character_system = get_node_or_null("/root/CharacterSystem")
	_combat_system = get_node_or_null("/root/CombatSystem")
	_encounter_system = get_node_or_null("/root/EncounterSystem")
	
	# 连接关系值变化信号
	if _relationship_manager:
		_relationship_manager.relationship_changed.connect(_on_relationship_changed)
	
	# 连接境界突破信号
	if _character_system:
		if _character_system.has_signal("realm_breakthrough"):
			_character_system.realm_breakthrough.connect(_on_realm_breakthrough)
	
	# 连接战斗系统信号
	if _combat_system:
		if _combat_system.has_signal("combat_ended"):
			_combat_system.combat_ended.connect(_on_combat_ended)
	
	# 连接奇遇系统信号
	if _encounter_system:
		if _encounter_system.has_signal("encounter_completed"):
			_encounter_system.encounter_completed.connect(_on_encounter_completed)
	
	# 连接任务进度更新信号
	if _quest_manager:
		if _quest_manager.has_signal("quest_objective_updated"):
			_quest_manager.quest_objective_updated.connect(_on_quest_objective_updated)
		if _quest_manager.has_signal("quest_completed"):
			_quest_manager.quest_completed.connect(_on_quest_completed)
	
	# 自动注册NPC个人线
	register_all_npc_questlines()

	print("[QuestTriggerManager] 任务触发管理器已初始化")

# ============================================================================
# 注册任务触发条件
# ============================================================================

## 注册NPC个人线触发条件
## quest_id: 任务唯一ID
## npc_id: 关联的NPC ID
## relationship_threshold: 关系值要求（-100 到 100）
## realm_requirement: 境界要求索引（见 REALM_REQUIREMENTS）
## prerequisites: 前置任务ID列表
func register_quest_trigger(quest_id: String, npc_id: String, relationship_threshold: int = 0, realm_requirement: int = 0, prerequisites: Array = []) -> bool:
	if quest_trigger_conditions.has(quest_id):
		print("[QuestTriggerManager] 触发条件已存在: ", quest_id)
		return false
	
	quest_trigger_conditions[quest_id] = {
		"quest_id": quest_id,
		"npc_id": npc_id,
		"relationship_threshold": relationship_threshold,
		"realm_requirement": realm_requirement,
		"prerequisites": prerequisites
	}
	
	# 检查当前是否已满足条件
	_check_and_unlock(quest_id)
	
	return true

# ============================================================================
# 条件检查
# ============================================================================

## 检查单个任务的解锁条件并尝试解锁
func _check_and_unlock(quest_id: String) -> bool:
	if not quest_trigger_conditions.has(quest_id):
		return false
	
	var condition = quest_trigger_conditions[quest_id]
	var missing = _check_conditions(condition)
	
	if missing.is_empty():
		# 条件全部满足，解锁任务
		_unlock_quest(quest_id, condition.npc_id)
		return true
	else:
		# 条件不足，发出信号
		quest_locked.emit(quest_id, condition.npc_id, missing)
		return false

## 检查指定条件是否满足
## 返回：满足的缺失条件列表
func _check_conditions(condition: Dictionary) -> Array:
	var missing = []
	
	# 检查关系值
	if condition.has("relationship_threshold"):
		var threshold = condition.relationship_threshold
		if _relationship_manager:
			var current_rel = _relationship_manager.get_relationship_value(condition.npc_id)
			if current_rel < threshold:
				missing.append({
					"type": "relationship",
					"npc_id": condition.npc_id,
					"required": threshold,
					"current": current_rel
				})
		else:
			missing.append({"type": "relationship_manager_not_found"})
	
	# 检查境界
	if condition.has("realm_requirement"):
		var required_realm = condition.realm_requirement
		if _character_system:
			var current_realm = _character_system.realm_index
			if current_realm < required_realm:
				missing.append({
					"type": "realm",
					"required": required_realm,
					"current": current_realm
				})
		else:
			missing.append({"type": "character_system_not_found"})
	
	# 检查前置任务
	if condition.has("prerequisites") and condition.prerequisites.size() > 0:
		var completed = []
		if _quest_manager:
			completed = _quest_manager.player_completed_quests
		else:
			missing.append({"type": "quest_manager_not_found"})
		
		for prereq in condition.prerequisites:
			if not (prereq in completed):
				missing.append({
					"type": "prerequisite_quest",
					"quest_id": prereq
				})
	
	return missing

## 解锁任务
func _unlock_quest(quest_id: String, npc_id: String):
	if not _quest_manager:
		push_warning("[QuestTriggerManager] QuestManager 未找到，无法解锁任务")
		return
	
	# 将任务状态设为 AVAILABLE
	_quest_manager.update_quest_status(quest_id, QuestManager.QuestStatus.AVAILABLE)
	
	# 发出信号
	quest_unlocked.emit(quest_id, npc_id)
	print("[QuestTriggerManager] 任务已解锁: %s (NPC: %s)" % [quest_id, npc_id])

# ============================================================================
# 信号回调
# ============================================================================

## 关系值变化回调
func _on_relationship_changed(npc_id: String, old_value: int, new_value: int):
	# 检查所有与该NPC相关的任务触发条件
	for quest_id in quest_trigger_conditions:
		var condition = quest_trigger_conditions[quest_id]
		if condition.npc_id == npc_id:
			# 检查是否达到阈值
			if condition.relationship_threshold > 0 and new_value >= condition.relationship_threshold:
				# 检查是否刚跨过阈值
				if old_value < condition.relationship_threshold:
					relationship_threshold_reached.emit(npc_id, condition.relationship_threshold, quest_id)
					_check_and_unlock(quest_id)

## 境界突破回调
func _on_realm_breakthrough(new_realm: String, realm_bonus: float, realm_index: int):
	# 检查所有有境界要求的任务
	for quest_id in quest_trigger_conditions:
		var condition = quest_trigger_conditions[quest_id]
		if condition.has("realm_requirement") and realm_index >= condition.realm_requirement:
			_check_and_unlock(quest_id)

# ============================================================================
# 批量注册（用于初始化NPC个人线）
# ============================================================================

## 注册所有核心NPC个人线触发条件
func register_all_npc_questlines():
	# 云中鹤 — 剑心之路（关系值30，炼气中期）
	register_quest_trigger("yunzhonghe_sword_path", "yunzhonghe", 30, REALM_REQUIREMENTS.qi_condensation_mid, [])
	
	# 铁无双 — 丐帮兄弟（关系值20，炼气初期）
	register_quest_trigger("tiewushuang_beggars", "tiewushuang", 20, REALM_REQUIREMENTS.qi_condensation_early, [])
	
	# 柳如烟 — 正道少侠（关系值25，炼气后期）
	register_quest_trigger("liuruyan_righteous", "liuruyan", 25, REALM_REQUIREMENTS.qi_condensation_late, [])
	
	# 慕容雪 — 前世之谜（关系值30，炼气后期）
	register_quest_trigger("murongxue_past_life", "murongxue", 30, REALM_REQUIREMENTS.qi_condensation_late, [])
	
	# 萧寒夜 — 魔道之路（关系值20，炼气后期）
	register_quest_trigger("xiaohanye_demonic", "xiaohanye", 20, REALM_REQUIREMENTS.qi_condensation_late, [])
	
	print("[QuestTriggerManager] 已注册 5 个核心NPC个人线触发条件")

# ============================================================================
# 工具函数
# ============================================================================

## 获取指定NPC的所有可触发任务
func get_available_quests_for_npc(npc_id: String) -> Array:
	var available = []
	for quest_id in quest_trigger_conditions:
		var condition = quest_trigger_conditions[quest_id]
		if condition.npc_id == npc_id and _check_conditions(condition).is_empty():
			available.append(quest_id)
	return available

## 检查指定任务是否已解锁
func is_quest_trigger_ready(quest_id: String) -> bool:
	if not quest_trigger_conditions.has(quest_id):
		return false
	return _check_conditions(quest_trigger_conditions[quest_id]).is_empty()

## 获取任务缺失条件详情
func get_quest_missing_conditions(quest_id: String) -> Array:
	if not quest_trigger_conditions.has(quest_id):
		return [{"type": "quest_not_registered"}]
	return _check_conditions(quest_trigger_conditions[quest_id])

# ============================================================================
# 任务进度跟踪（收集物品、击杀敌人、完成奇遇等）
# ============================================================================

## 注册任务进度条件
## progress_type: "collect_item", "kill_enemy", "complete_encounter", "explore_location"
## target_id: 物品ID/敌人ID/奇遇ID/位置ID
## target_count: 需要的数量
## quest_id: 关联任务ID
## npc_id: 关联NPC ID（用于解锁后关联）
func register_progress_condition(quest_id: String, progress_type: String, target_id: String, target_count: int, npc_id: String = "") -> bool:
	if quest_progress_conditions.has(quest_id):
		push_warning("[QuestTriggerManager] 进度条件已存在: ", quest_id)
		return false
	
	quest_progress_conditions[quest_id] = {
		"quest_id": quest_id,
		"progress_type": progress_type,
		"target_id": target_id,
		"target_count": target_count,
		"current_count": 0,
		"npc_id": npc_id
	}
	
	# 初始化进度
	quest_progress[quest_id] = 0
	
	# 检查当前是否已满足条件
	_check_progress_and_unlock(quest_id)
	
	print("[QuestTriggerManager] 已注册进度条件: %s (%s, %d/%d)" % [
		quest_id, progress_type, 0, target_count
	])
	return true

## 检查进度并尝试解锁
func _check_progress_and_unlock(quest_id: String) -> bool:
	if not quest_progress_conditions.has(quest_id):
		return false
	
	var condition = quest_progress_conditions[quest_id]
	var current = quest_progress.get(quest_id, 0)
	
	if current >= condition.target_count:
		# 进度完成，检查其他条件
		if quest_trigger_conditions.has(quest_id):
			return _check_and_unlock(quest_id)
		else:
			# 没有触发条件，直接发出进度完成信号
			quest_progress_completed.emit(quest_id, condition.npc_id)
			return true
	
	return false

## 更新进度（通用）
func update_progress(quest_id: String, amount: int = 1) -> bool:
	if not quest_progress_conditions.has(quest_id):
		return false
	
	quest_progress[quest_id] = quest_progress.get(quest_id, 0) + amount
	var current = quest_progress[quest_id]
	var max_val = quest_progress_conditions[quest_id].target_count
	
	# 发出进度更新信号
	quest_progress_updated.emit(quest_id, current, max_val)
	
	print("[QuestTriggerManager] 进度更新: %s %d/%d" % [quest_id, current, max_val])
	
	return _check_progress_and_unlock(quest_id)

## 检查物品是否在背包中并更新收集进度
func check_item_collected(item_id: String, count: int = 1) -> void:
	for quest_id in quest_progress_conditions:
		var condition = quest_progress_conditions[quest_id]
		if condition.progress_type == "collect_item" and condition.target_id == item_id:
			update_progress(quest_id, count)

## 检查敌人击杀并更新击杀进度
func check_enemy_killed(enemy_id: String, count: int = 1) -> void:
	for quest_id in quest_progress_conditions:
		var condition = quest_progress_conditions[quest_id]
		if condition.progress_type == "kill_enemy" and condition.target_id == enemy_id:
			update_progress(quest_id, count)

## 检查奇遇是否完成并更新进度
func check_encounter_completed(encounter_id: String) -> void:
	for quest_id in quest_progress_conditions:
		var condition = quest_progress_conditions[quest_id]
		if condition.progress_type == "complete_encounter" and condition.target_id == encounter_id:
			update_progress(quest_id, 1)

# ============================================================================
# 进度相关信号回调
# ============================================================================

## 战斗结束回调
func _on_combat_ended(victory: bool, enemies: Array = []):
	if not victory:
		return
	
	# 检查击杀敌人进度
	for enemy_data in enemies:
		var enemy_id = enemy_data.get("id", "")
		if not enemy_id.is_empty():
			check_enemy_killed(enemy_id)

## 奇遇完成回调
func _on_encounter_completed(encounter_id: String, rewards: Dictionary):
	check_encounter_completed(encounter_id)

## 任务目标更新回调
func _on_quest_objective_updated(quest_id: String, objective_index: int, current_value: int, target_value: int):
	if quest_progress_conditions.has(quest_id):
		quest_progress[quest_id] = current_value
		var condition = quest_progress_conditions[quest_id]
		quest_progress_updated.emit(quest_id, current_value, target_value)
		_check_progress_and_unlock(quest_id)

## 任务完成回调
func _on_quest_completed(quest_id: String):
	# 检查是否有依赖此任务的前置条件
	for other_quest_id in quest_trigger_conditions:
		var condition = quest_trigger_conditions[other_quest_id]
		if condition.has("prerequisites") and quest_id in condition.prerequisites:
			_check_and_unlock(other_quest_id)

# ============================================================================
# 新增信号
# ============================================================================

## 任务进度更新
signal quest_progress_updated(quest_id: String, current_count: int, target_count: int)

## 任务进度完成
signal quest_progress_completed(quest_id: String, npc_id: String)
