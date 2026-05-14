## 支线任务触发验证集成测试 (s6-06)
## 验证3个支线在关系值达标时正确触发
extends GutTest

const QuestTriggerManagerScript = preload("res://src/scripts/quest/quest_trigger_manager.gd")
const RelationshipManagerScript = preload("res://src/scripts/relationship/relationship_manager.gd")

var _trigger_mgr: Node = null
var _rel_mgr: Node = null


func before_each() -> void:
	_rel_mgr = RelationshipManagerScript.new()
	_rel_mgr.name = "RelationshipManager"
	add_child(_rel_mgr)

	_trigger_mgr = QuestTriggerManagerScript.new()
	_trigger_mgr.name = "QuestTriggerManager"
	add_child_autofree(_trigger_mgr)
	# 手动注入依赖
	_trigger_mgr._relationship_manager = _rel_mgr


func after_each() -> void:
	if _rel_mgr and is_instance_valid(_rel_mgr):
		remove_child(_rel_mgr)
		_rel_mgr.queue_free()


## 柳如烟支线：关系值>=25 + 境界炼气后期时触发
func test_liuruyan_quest_unlocks_at_threshold() -> void:
	_trigger_mgr.register_quest_trigger(
		"liuruyan_righteous", "liuruyan", 25, 2, []
	)
	# 模拟境界满足
	_trigger_mgr._character_system = null

	# 关系值不足
	_rel_mgr.set_relationship_value("liuruyan", 20)
	assert_false(_trigger_mgr.is_quest_trigger_ready("liuruyan_righteous"))


## 慕容雪支线：关系值>=30 时条件检查
func test_murongxue_quest_relationship_check() -> void:
	_trigger_mgr.register_quest_trigger(
		"murongxue_past_life", "murongxue", 30, 2, []
	)
	_rel_mgr.set_relationship_value("murongxue", 35)
	# 境界条件仍需CharacterSystem，但关系值条件满足
	var missing: Array = _trigger_mgr.get_quest_missing_conditions("murongxue_past_life")
	var has_relationship_missing := false
	for m in missing:
		if m.get("type", "") == "relationship":
			has_relationship_missing = true
	assert_false(has_relationship_missing)


## 萧寒夜支线：关系值>=20 时关系条件满足
func test_xiaohanye_quest_relationship_check() -> void:
	_trigger_mgr.register_quest_trigger(
		"xiaohanye_demonic", "xiaohanye", 20, 2, []
	)
	_rel_mgr.set_relationship_value("xiaohanye", 25)
	var missing: Array = _trigger_mgr.get_quest_missing_conditions("xiaohanye_demonic")
	var has_relationship_missing := false
	for m in missing:
		if m.get("type", "") == "relationship":
			has_relationship_missing = true
	assert_false(has_relationship_missing)


## 关系值不足时不触发
func test_quest_not_triggered_when_relationship_insufficient() -> void:
	_trigger_mgr.register_quest_trigger(
		"liuruyan_righteous", "liuruyan", 25, 0, []
	)
	_rel_mgr.set_relationship_value("liuruyan", 10)
	assert_false(_trigger_mgr.is_quest_trigger_ready("liuruyan_righteous"))


## 关系值刚好达到阈值时条件满足
func test_quest_ready_at_exact_threshold() -> void:
	_trigger_mgr.register_quest_trigger(
		"xiaohanye_demonic", "xiaohanye", 20, 0, []
	)
	_rel_mgr.set_relationship_value("xiaohanye", 20)
	assert_true(_trigger_mgr.is_quest_trigger_ready("xiaohanye_demonic"))


## 同时满足多个支线条件
func test_multiple_quests_ready_simultaneously() -> void:
	_trigger_mgr.register_quest_trigger("q1", "liuruyan", 10, 0, [])
	_trigger_mgr.register_quest_trigger("q2", "murongxue", 10, 0, [])
	_rel_mgr.set_relationship_value("liuruyan", 50)
	_rel_mgr.set_relationship_value("murongxue", 50)
	assert_true(_trigger_mgr.is_quest_trigger_ready("q1"))
	assert_true(_trigger_mgr.is_quest_trigger_ready("q2"))


## 注册所有NPC个人线不崩溃
func test_register_all_npc_questlines_no_crash() -> void:
	_trigger_mgr.register_all_npc_questlines()
	assert_true(_trigger_mgr.quest_trigger_conditions.size() >= 5)


## 未注册的任务返回false
func test_unregistered_quest_not_ready() -> void:
	assert_false(_trigger_mgr.is_quest_trigger_ready("nonexistent_quest"))


## 缺失条件正确报告
func test_missing_conditions_report() -> void:
	_trigger_mgr.register_quest_trigger(
		"test_quest", "liuruyan", 50, 5, ["prereq_quest"]
	)
	_rel_mgr.set_relationship_value("liuruyan", 10)
	var missing: Array = _trigger_mgr.get_quest_missing_conditions("test_quest")
	assert_true(missing.size() >= 1)
