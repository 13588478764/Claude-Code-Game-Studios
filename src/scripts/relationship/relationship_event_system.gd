## 关系事件触发系统
## 在关系值达到阈值时检查并触发专属事件
extends Node

signal event_triggered(event_id: String, npc_id: String, event_type: String)
signal event_available(event_id: String, npc_id: String)

## 事件定义 {event_id: EventConfig}
var _event_registry: Dictionary = {}

## 已触发事件列表
var _triggered_events: Array[String] = []

## 关系管理器引用
var _relationship_manager: RelationshipManager = null

## 事件配置数据类
class EventConfig:
	var id: String = ""
	var npc_id: String = ""
	var event_type: String = "dialogue"
	var relationship_threshold: int = 0
	var dao_heart_min: int = -100
	var dao_heart_max: int = 100
	var required_quest: String = ""
	var required_realm: int = 0
	var dialogue_id: String = ""
	var description: String = ""
	var repeatable: bool = false

func _ready() -> void:
	if has_node("/root/RelationshipManager"):
		_relationship_manager = get_node("/root/RelationshipManager")
		_relationship_manager.relationship_changed.connect(_on_relationship_changed)
		_relationship_manager.relationship_level_changed.connect(_on_relationship_level_changed)

	_load_default_events()

## 注册事件
func register_event(config: EventConfig) -> void:
	_event_registry[config.id] = config

## 检查事件是否可触发
func check_event(event_id: String) -> bool:
	if not _event_registry.has(event_id):
		return false

	var config: EventConfig = _event_registry[event_id]

	# 已触发且不可重复
	if event_id in _triggered_events and not config.repeatable:
		return false

	if _relationship_manager == null:
		return false

	# 关系值阈值
	var rel_value := _relationship_manager.get_relationship_value(config.npc_id)
	if rel_value < config.relationship_threshold:
		return false

	# 道心值范围
	var dao_value := _relationship_manager.get_dao_heart_value()
	if dao_value < config.dao_heart_min or dao_value > config.dao_heart_max:
		return false

	return true

## 触发事件
func trigger_event(event_id: String) -> bool:
	if not check_event(event_id):
		return false

	var config: EventConfig = _event_registry[event_id]

	if not config.repeatable:
		_triggered_events.append(event_id)

	event_triggered.emit(event_id, config.npc_id, config.event_type)
	print("[关系事件] 触发事件: %s (NPC: %s, 类型: %s)" % [event_id, config.npc_id, config.event_type])
	return true

## 检查NPC所有可触发事件
func check_npc_events(npc_id: String) -> Array[String]:
	var available: Array[String] = []
	for event_id in _event_registry:
		var config: EventConfig = _event_registry[event_id]
		if config.npc_id == npc_id and check_event(event_id):
			available.append(event_id)
	return available

## 尝试触发NPC的下一个可用事件
func try_trigger_next_event(npc_id: String) -> String:
	var available := check_npc_events(npc_id)
	if available.is_empty():
		return ""

	# 按阈值排序，触发最低阈值的事件
	available.sort_custom(func(a, b):
		return _event_registry[a].relationship_threshold < _event_registry[b].relationship_threshold
	)

	var event_id: String = available[0]
	if trigger_event(event_id):
		return event_id
	return ""

## 检查事件是否已触发
func is_event_triggered(event_id: String) -> bool:
	return event_id in _triggered_events

## 获取已触发事件列表
func get_triggered_events() -> Array[String]:
	return _triggered_events.duplicate()

## 关系值变化回调——检查新解锁的事件
func _on_relationship_changed(npc_id: String, _old_value: int, _new_value: int) -> void:
	var available := check_npc_events(npc_id)
	for event_id in available:
		event_available.emit(event_id, npc_id)

func _on_relationship_level_changed(_npc_id: String, _old_level: RelationshipData.RelationshipLevel, _new_level: RelationshipData.RelationshipLevel) -> void:
	pass

## 加载默认事件配置
func _load_default_events() -> void:
	# 云中鹤事件链
	_register_event("yunzhonghe_friendly", "yunzhonghe", "dialogue", 10, "初次认可")
	_register_event("yunzhonghe_sword_teaching", "yunzhonghe", "quest", 30, "剑术指导任务")
	_register_event("yunzhonghe_intimate", "yunzhonghe", "dialogue", 50, "吐露心事")
	_register_event("yunzhonghe_secret", "yunzhonghe", "quest", 70, "青云秘密任务")
	_register_event("yunzhonghe_legacy", "yunzhonghe", "combat", 90, "传承试炼")

	# 柳如烟事件链
	_register_event("liuruyan_friendly", "liuruyan", "dialogue", 10, "初见好感")
	_register_event("liuruyan_together", "liuruyan", "quest", 30, "结伴历练")
	_register_event("liuruyan_trust", "liuruyan", "dialogue", 50, "信任对话")
	_register_event("liuruyan_confession", "liuruyan", "dialogue", 70, "表白剧情")
	_register_event("liuruyan_romance", "liuruyan", "romance", 80, "恋爱剧情")

	# 萧寒夜事件链
	_register_event("xiaohanye_interest", "xiaohanye", "dialogue", 10, "引起兴趣")
	_register_event("xiaohanye_alliance", "xiaohanye", "quest", 30, "暂时结盟任务")
	_register_event("xiaohanye_truth", "xiaohanye", "dialogue", 50, "身世真相")
	_register_event("xiaohanye_choice", "xiaohanye", "quest", 70, "抉择时刻")

	# 慕容雪事件链
	_register_event("murongxue_acquaintance", "murongxue", "dialogue", 10, "偶遇交谈")
	_register_event("murongxue_adventure", "murongxue", "quest", 30, "探险邀约")
	_register_event("murongxue_memory", "murongxue", "dialogue", 50, "往事追忆")
	_register_event("murongxue_romance", "murongxue", "romance", 80, "恋爱剧情")

	# 玄机真人事件链
	_register_event("xuanjizhenren_approval", "xuanjizhenren", "dialogue", 10, "获得认可")
	_register_event("xuanjizhenren_wisdom", "xuanjizhenren", "dialogue", 50, "天机指引")

	# 血无痕事件链
	_register_event("xuewuhen_notice", "xuewuhen", "dialogue", 10, "引起注意")
	_register_event("xuewuhen_deal", "xuewuhen", "quest", 50, "交易提议")

## 快捷注册方法
func _register_event(id: String, npc_id: String, event_type: String, threshold: int, desc: String) -> void:
	var config := EventConfig.new()
	config.id = id
	config.npc_id = npc_id
	config.event_type = event_type
	config.relationship_threshold = threshold
	config.description = desc
	_event_registry[id] = config

## 保存数据
func save_data() -> Dictionary:
	return {
		"triggered_events": _triggered_events.duplicate()
	}

## 加载数据
func load_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var events = data.get("triggered_events", [])
	_triggered_events.clear()
	for e in events:
		_triggered_events.append(str(e))

## 重置
func reset_all() -> void:
	_triggered_events.clear()
