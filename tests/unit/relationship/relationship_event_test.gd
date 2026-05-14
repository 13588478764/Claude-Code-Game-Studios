## 关系事件触发系统单元测试
extends GutTest

const RelationshipManagerScript = preload("res://src/scripts/relationship/relationship_manager.gd")
const RelationshipEventSystem = preload("res://src/scripts/relationship/relationship_event_system.gd")
var _manager = null
var _event_system = null

func before_each() -> void:
	_manager = RelationshipManagerScript.new()
	_manager.name = "RelationshipManager"
	add_child(_manager)
	# _ready()后再覆盖为测试数据
	_manager.current_game_day = 100
	_manager._npc_database = {
		"yunzhonghe": {"id": "yunzhonghe", "alignment": "righteous", "birthday": 88, "gift_preferences": {"loves": [], "likes": [], "dislikes": []}},
		"liuruyan": {"id": "liuruyan", "alignment": "righteous", "birthday": 215, "gift_preferences": {"loves": [], "likes": [], "dislikes": []}}
	}

	_event_system = RelationshipEventSystem.new()
	add_child_autofree(_event_system)
	# _ready()后再注入，避免被覆盖为null
	_event_system._relationship_manager = _manager
	_manager.relationship_changed.connect(_event_system._on_relationship_changed)

func after_each() -> void:
	if _manager and is_instance_valid(_manager):
		remove_child(_manager)
		_manager.queue_free()

## ============================================================================
## 事件注册与检查
## ============================================================================

func test_default_events_loaded() -> void:
	assert_true(_event_system._event_registry.size() > 0, "默认事件应已加载")

func test_check_event_below_threshold() -> void:
	_manager.set_relationship_value("yunzhonghe", 5)
	assert_false(_event_system.check_event("yunzhonghe_friendly"))

func test_check_event_at_threshold() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	assert_true(_event_system.check_event("yunzhonghe_friendly"))

func test_check_event_above_threshold() -> void:
	_manager.set_relationship_value("yunzhonghe", 50)
	assert_true(_event_system.check_event("yunzhonghe_friendly"))

## ============================================================================
## 事件触发
## ============================================================================

func test_trigger_event_success() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	assert_true(_event_system.trigger_event("yunzhonghe_friendly"))

func test_trigger_event_marks_as_triggered() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	_event_system.trigger_event("yunzhonghe_friendly")
	assert_true(_event_system.is_event_triggered("yunzhonghe_friendly"))

func test_triggered_event_not_repeatable() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	_event_system.trigger_event("yunzhonghe_friendly")
	assert_false(_event_system.check_event("yunzhonghe_friendly"))

func test_trigger_event_emits_signal() -> void:
	var result_arr := [false]
	var callback := func(_eid, _npc, _type): result_arr[0] = true
	_event_system.event_triggered.connect(callback)

	_manager.set_relationship_value("yunzhonghe", 10)
	_event_system.trigger_event("yunzhonghe_friendly")
	assert_true(result_arr[0])

## ============================================================================
## 多阈值跳跃
## ============================================================================

func test_multiple_events_available_after_big_jump() -> void:
	_manager.set_relationship_value("yunzhonghe", 90)
	var available: Array[String] = _event_system.check_npc_events("yunzhonghe")
	# 应该有多个事件可触发(10/30/50/70/90阈值)
	assert_true(available.size() >= 4, "跳到90应有多个事件可触发，实际: %d" % available.size())

func test_try_trigger_next_fires_lowest_threshold_first() -> void:
	_manager.set_relationship_value("yunzhonghe", 90)
	var event_id: String = _event_system.try_trigger_next_event("yunzhonghe")
	assert_eq(event_id, "yunzhonghe_friendly")

## ============================================================================
## 降级后再升级不重复触发
## ============================================================================

func test_no_repeat_after_downgrade_and_upgrade() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	_event_system.trigger_event("yunzhonghe_friendly")

	_manager.set_relationship_value("yunzhonghe", 5)
	_manager.set_relationship_value("yunzhonghe", 15)
	assert_false(_event_system.check_event("yunzhonghe_friendly"))

## ============================================================================
## 保存/加载
## ============================================================================

func test_triggered_events_save_load() -> void:
	_manager.set_relationship_value("yunzhonghe", 10)
	_event_system.trigger_event("yunzhonghe_friendly")

	var saved: Dictionary = _event_system.save_data()
	_event_system.reset_all()
	assert_false(_event_system.is_event_triggered("yunzhonghe_friendly"))

	_event_system.load_data(saved)
	assert_true(_event_system.is_event_triggered("yunzhonghe_friendly"))

func test_load_empty_data() -> void:
	_event_system.load_data({})
	assert_eq(_event_system.get_triggered_events().size(), 0)

## ============================================================================
## 不存在的事件
## ============================================================================

func test_check_nonexistent_event() -> void:
	assert_false(_event_system.check_event("does_not_exist"))

func test_trigger_nonexistent_event() -> void:
	assert_false(_event_system.trigger_event("does_not_exist"))
