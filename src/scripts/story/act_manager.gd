## ActManager — 幕次管理器
##
## 负责管理游戏的主线幕次（Act）进度：
## - 跟踪当前所处的幕次和章节
## - 检查幕次解锁条件
## - 处理幕次间的过渡和场景跳转
## - 触发幕次内的事件序列
##
## 幕次结构：
## - Act 1: 青云镇危机 (已完成)
## - Act 2: 九州风云 (当前开发阶段)
## - Act 3: 九州之门 (待开发)
##
## 依赖系统：
## - CharacterSystem（角色系统）
## - RelationshipManager（关系系统）
## - DialogueManager（对话系统）
## - EncounterSystem（奇遇系统）

extends Node

# ============================================================================
# 信号定义
# ============================================================================

## 幕次开始
signal act_started(act_id: String, act_title: String)

## 幕次完成
signal act_completed(act_id: String)

## 幕次过渡开始
signal act_transition_started(from_act: String, to_act: String)

## 幕次过渡完成
signal act_transition_completed(to_act: String)

## 事件触发
signal event_triggered(act_id: String, event_id: String)

# ============================================================================
# 常量定义
# ============================================================================

## 幕次 ID 常量
const ActID = {
	"ACT_1": "act_1",
	"ACT_2": "act_2",
	"ACT_3": "act_3"
}

## 幕次标题
const ACT_TITLES = {
	"act_1": "第一幕：青云镇危机",
	"act_2": "第二幕：九州风云",
	"act_3": "第三幕：九州之门"
}

## 幕次状态
enum ActState {
	NOT_STARTED,    # 未开始
	ACTIVE,         # 进行中
	COMPLETED       # 已完成
}

# ============================================================================
# 成员变量
# ============================================================================

## 当前幕次 ID
var current_act: String = ActID.ACT_1

## 幕次状态 {act_id: ActState}
var act_states: Dictionary = {
	ActID.ACT_1: ActState.ACTIVE,
	ActID.ACT_2: ActState.NOT_STARTED,
	ActID.ACT_3: ActState.NOT_STARTED
}

## 已完成的事件 ID 列表
var completed_events: Array[String] = []

## 当前幕次中已触发的事件 ID 列表
var triggered_events: Array[String] = []

## 幕次过渡中
var is_transitioning: bool = false

# ============================================================================
# 系统引用
# ============================================================================

var _character_system: Node = null
var _relationship_manager: Node = null
var _dialogue_manager: Node = null
var _encounter_system: Node = null

func _ready() -> void:
	# 获取系统引用
	_character_system = get_node_or_null("/root/CharacterSystem")
	_relationship_manager = get_node_or_null("/root/RelationshipManager")
	_dialogue_manager = get_node_or_null("/root/DialogueManager")
	_encounter_system = get_node_or_null("/root/EncounterSystem")
	
	print("[ActManager] 幕次管理器已初始化，当前幕次: %s" % get_current_act_title())

# ============================================================================
# 公共 API
# ============================================================================

## 获取当前幕次
func get_current_act() -> String:
	return current_act

## 获取当前幕次标题
func get_current_act_title() -> String:
	return ACT_TITLES.get(current_act, "未知幕次")

## 获取幕次状态
func get_act_state(act_id: String) -> int:
	return act_states.get(act_id, ActState.NOT_STARTED)

## 检查幕次是否已完成
func is_act_completed(act_id: String) -> bool:
	return act_states.get(act_id) == ActState.COMPLETED

## 检查幕次是否解锁
func is_act_unlocked(act_id: String) -> bool:
	var state: int = act_states.get(act_id, ActState.NOT_STARTED)
	return state != ActState.NOT_STARTED

## 检查事件是否已完成
func is_event_completed(event_id: String) -> bool:
	return event_id in completed_events

# ============================================================================
# 幕次控制
# ============================================================================

## 开始指定幕次
func start_act(act_id: String) -> bool:
	if act_states.get(act_id) != ActState.NOT_STARTED:
		push_warning("[ActManager] 幕次 %s 状态不允许开始" % act_id)
		return false
	
	# 标记为激活
	act_states[act_id] = ActState.ACTIVE
	current_act = act_id
	
	# 发送信号
	act_started.emit(act_id, ACT_TITLES.get(act_id, ""))
	
	print("[ActManager] 幕次开始: %s" % ACT_TITLES.get(act_id, act_id))
	return true

## 完成当前幕次并过渡到下一幕次
func complete_current_act(next_act_id: String) -> bool:
	if is_transitioning:
		push_warning("[ActManager] 正在过渡中，无法切换")
		return false
	
	if act_states.get(next_act_id) == ActState.COMPLETED:
		push_warning("[ActManager] 目标幕次已完成")
		return false
	
	var previous_act = current_act
	
	# 标记当前幕次完成
	act_states[current_act] = ActState.COMPLETED
	
	# 开始过渡
	is_transitioning = true
	act_transition_started.emit(previous_act, next_act_id)
	
	print("[ActManager] 幕次过渡: %s → %s" % [
		ACT_TITLES.get(previous_act, previous_act),
		ACT_TITLES.get(next_act_id, next_act_id)
	])
	
	# 更新当前幕次
	current_act = next_act_id
	act_states[current_act] = ActState.ACTIVE
	
	# 完成过渡
	is_transitioning = false
	act_transition_completed.emit(next_act_id)
	act_completed.emit(previous_act)
	
	print("[ActManager] 幕次过渡完成，当前幕次: %s" % ACT_TITLES.get(next_act_id, next_act_id))
	return true

# ============================================================================
# 事件管理
# ============================================================================

## 触发幕次事件（用于主线事件序列）
func trigger_event(act_id: String, event_id: String) -> bool:
	if act_id != current_act:
		push_warning("[ActManager] 无法触发非当前幕次的事件: %s" % event_id)
		return false
	
	if event_id in completed_events:
		push_warning("[ActManager] 事件已完成: %s" % event_id)
		return false
	
	# 标记事件已触发
	triggered_events.append(event_id)
	
	# 发送信号
	event_triggered.emit(act_id, event_id)
	
	print("[ActManager] 事件触发: %s (%s)" % [event_id, ACT_TITLES.get(act_id, act_id)])
	return true

## 完成事件
func complete_event(event_id: String) -> void:
	if event_id in completed_events:
		return
	
	completed_events.append(event_id)
	if event_id in triggered_events:
		triggered_events.erase(event_id)
	
	print("[ActManager] 事件完成: %s (已完成事件数: %d)" % [event_id, completed_events.size()])

## 获取幕次中已完成的事件数
func get_completed_event_count(act_id: String) -> int:
	var count := 0
	for event_id in completed_events:
		if event_id.begins_with(act_id):
			count += 1
	return count

# ============================================================================
# 场景过渡
# ============================================================================

## 过渡到指定场景
func transition_to_scene(scene_path: String, transition_duration: float = 1.0) -> void:
	var scene_tree = get_tree()
	if scene_tree == null:
		return
	
	print("[ActManager] 场景过渡: %s" % scene_path)
	
	# 使用 Godot 场景切换
	scene_tree.change_scene_to_file(scene_path)

## Act 1 → Act 2 过渡
func transition_act1_to_act2() -> bool:
	if current_act != ActID.ACT_1:
		push_warning("[ActManager] 当前不在 Act 1，无法过渡")
		return false
	
	return complete_current_act(ActID.ACT_2)

## Act 2 → Act 3 过渡
func transition_act2_to_act3() -> bool:
	if current_act != ActID.ACT_2:
		push_warning("[ActManager] 当前不在 Act 2，无法过渡")
		return false
	
	return complete_current_act(ActID.ACT_3)

# ============================================================================
# 保存和加载
# ============================================================================

## 保存幕次状态
func save_data() -> Dictionary:
	return {
		"current_act": current_act,
		"act_states": act_states,
		"completed_events": completed_events,
		"triggered_events": triggered_events,
		"is_transitioning": is_transitioning
	}

## 加载幕次状态
func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	
	current_act = data.get("current_act", ActID.ACT_1)
	act_states = data.get("act_states", act_states)
	completed_events = data.get("completed_events", [])
	triggered_events = data.get("triggered_events", [])
	is_transitioning = data.get("is_transitioning", false)
	
	print("[ActManager] 幕次状态已加载: %s" % get_current_act_title())

# ============================================================================
# 调试信息
# ============================================================================

## 获取幕次状态摘要
func get_status_summary() -> String:
	var summary := "[幕次状态]\n"
	summary += "当前幕次: %s\n" % get_current_act_title()
	summary += "已完成事件: %d\n" % completed_events.size()
	
	summary += "\n幕次详情:\n"
	for act_id in act_states:
		var state_str: String
		match act_states[act_id]:
			ActState.NOT_STARTED:
				state_str = "未开始"
			ActState.ACTIVE:
				state_str = "进行中"
			ActState.COMPLETED:
				state_str = "已完成"
		summary += "  %s: %s\n" % [ACT_TITLES.get(act_id, act_id), state_str]
	
	return summary
