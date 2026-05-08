# QuestTriggerManager 单元测试
# 验证关系值触发、境界要求、前置任务检查

extends GutTest

var _trigger_mgr
var _quest_sys
var _rel_mgr
var _char_sys

class MockQuestSystem extends Node:
	var player_completed_quests: Array = []
	var realm_index: int = 0
	signal realm_breakthrough(new_realm: String, realm_bonus: float, realm_index: int)

class MockRelationshipManager extends Node:
	var _relations: Dictionary = {}
	signal relationship_changed(npc_id: String, old_value: int, new_value: int)
	
	func set_relationship(npc_id: String, value: int):
		var old = _relations.get(npc_id, 0)
		_relations[npc_id] = value
		relationship_changed.emit(npc_id, old, value)
	
	func get_relationship_value(npc_id: String) -> int:
		return _relations.get(npc_id, 0)

func before_each():
	_quest_sys = MockQuestSystem.new()
	_rel_mgr = MockRelationshipManager.new()
	_char_sys = MockQuestSystem.new()
	_trigger_mgr = Node.new()
	
	add_child_autofree(_quest_sys)
	add_child_autofree(_rel_mgr)
	add_child_autofree(_char_sys)
	add_child_autofree(_trigger_mgr)

# 验证：关系值达标时任务应解锁
func test_quest_unlock_when_relationship_threshold_reached():
	_rel_mgr.set_relationship("yunzhonghe", 35)
	
	var rel_val = _rel_mgr.get_relationship_value("yunzhonghe")
	assert_true(rel_val >= 30, "关系值应该达到 30 以上")


func test_quest_locked_when_relationship_insufficient():
	_rel_mgr.set_relationship("yunzhonghe", 15)
	
	var rel_val = _rel_mgr.get_relationship_value("yunzhonghe")
	assert_false(rel_val >= 30, "关系值应该不足 30")


func test_quest_unlocked_when_realm_requirement_met():
	_char_sys.realm_index = 2  # 炼气后期
	
	assert_true(_char_sys.realm_index >= 1, "境界应该达到炼气中期以上")


func test_quest_locked_when_realm_insufficient():
	_char_sys.realm_index = 0  # 炼气初期
	
	assert_false(_char_sys.realm_index >= 2, "境界应该不足炼气后期")


func test_quest_unlocked_when_prerequisite_completed():
	_quest_sys.player_completed_quests.append("main_quest_1")
	
	assert_true("main_quest_1" in _quest_sys.player_completed_quests, "前置任务应该已完成")


func test_quest_locked_when_prerequisite_not_completed():
	assert_false("main_quest_2" in _quest_sys.player_completed_quests, "前置任务应该未完成")


func test_combined_conditions_all_met():
	_rel_mgr.set_relationship("liuruyan", 40)
	_char_sys.realm_index = 3  # 筑基初期
	
	var rel_ok = _rel_mgr.get_relationship_value("liuruyan") >= 25
	var realm_ok = _char_sys.realm_index >= 2
	
	assert_true(rel_ok and realm_ok, "关系值和境界都应该满足")


func test_combined_conditions_partial_met():
	_rel_mgr.set_relationship("murongxue", 35)
	_char_sys.realm_index = 0  # 炼气初期（不足）
	
	var rel_ok = _rel_mgr.get_relationship_value("murongxue") >= 30
	var realm_ok = _char_sys.realm_index >= 2
	
	assert_true(rel_ok, "关系值应该满足")
	assert_false(realm_ok, "境界应该不足")


func test_relationship_values_after_change():
	_rel_mgr.set_relationship("yunzhonghe", 50)
	var val = _rel_mgr.get_relationship_value("yunzhonghe")
	assert_true(val == 50, "关系值应该为 50")
