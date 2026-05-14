## 结局判定系统单元测试
extends GutTest

const RelationshipManagerScript = preload("res://src/scripts/relationship/relationship_manager.gd")

var _manager = null
var _ending: EndingDetermination = null

func before_each() -> void:
	_manager = RelationshipManagerScript.new()
	add_child_autofree(_manager)
	_ending = EndingDetermination.new()

## ============================================================================
## 正道领袖
## ============================================================================

func test_righteous_leader_all_conditions_met() -> void:
	_manager.set_dao_heart_value(60)
	_manager.set_relationship_value("liuruyan", 70)
	_manager.set_relationship_value("xuanjizhenren", 50)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.RIGHTEOUS_LEADER)

func test_righteous_leader_dao_too_low() -> void:
	_manager.set_dao_heart_value(59)
	_manager.set_relationship_value("liuruyan", 70)
	_manager.set_relationship_value("xuanjizhenren", 50)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.RIGHTEOUS_LEADER)

func test_righteous_leader_liuruyan_too_low() -> void:
	_manager.set_dao_heart_value(60)
	_manager.set_relationship_value("liuruyan", 69)
	_manager.set_relationship_value("xuanjizhenren", 50)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.RIGHTEOUS_LEADER)

## ============================================================================
## 魔道霸主
## ============================================================================

func test_evil_overlord_all_conditions_met() -> void:
	_manager.set_dao_heart_value(-60)
	_manager.set_relationship_value("xiaohanye", 70)
	_manager.set_relationship_value("xuewuhen", 30)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.EVIL_OVERLORD)

func test_evil_overlord_dao_not_evil_enough() -> void:
	_manager.set_dao_heart_value(-59)
	_manager.set_relationship_value("xiaohanye", 70)
	_manager.set_relationship_value("xuewuhen", 30)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.EVIL_OVERLORD)

## ============================================================================
## 隐世大能（最高优先级）
## ============================================================================

func test_hidden_master_all_conditions_met() -> void:
	_manager.set_dao_heart_value(0)
	_manager.set_relationship_value("murongxue", 80)
	_manager.set_relationship_value("xuanjizhenren", 60)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.HIDDEN_MASTER)

func test_hidden_master_dao_too_extreme() -> void:
	_manager.set_dao_heart_value(31)
	_manager.set_relationship_value("murongxue", 80)
	_manager.set_relationship_value("xuanjizhenren", 60)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.HIDDEN_MASTER)

func test_hidden_master_priority_over_righteous() -> void:
	# 同时满足隐世和正道条件（道心30边界，隐世优先）
	_manager.set_dao_heart_value(30)
	_manager.set_relationship_value("murongxue", 80)
	_manager.set_relationship_value("xuanjizhenren", 60)
	_manager.set_relationship_value("liuruyan", 70)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.HIDDEN_MASTER)

## ============================================================================
## 逍遥散仙
## ============================================================================

func test_free_spirit_all_conditions_met() -> void:
	_manager.set_dao_heart_value(0)
	for npc_id in ["yunzhonghe", "liuruyan", "xuanjizhenren", "xiaohanye", "xuewuhen", "murongxue"]:
		_manager.set_relationship_value(npc_id, 50)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.FREE_SPIRIT)

func test_free_spirit_one_npc_too_low() -> void:
	_manager.set_dao_heart_value(0)
	for npc_id in ["yunzhonghe", "liuruyan", "xuanjizhenren", "xiaohanye", "xuewuhen"]:
		_manager.set_relationship_value(npc_id, 50)
	_manager.set_relationship_value("murongxue", 49)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.FREE_SPIRIT)

func test_free_spirit_dao_too_extreme() -> void:
	_manager.set_dao_heart_value(21)
	for npc_id in ["yunzhonghe", "liuruyan", "xuanjizhenren", "xiaohanye", "xuewuhen", "murongxue"]:
		_manager.set_relationship_value(npc_id, 50)
	assert_ne(_ending.determine_ending(_manager), EndingDetermination.EndingType.FREE_SPIRIT)

## ============================================================================
## 默认结局
## ============================================================================

func test_default_ending_no_conditions_met() -> void:
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.DEFAULT)

func test_default_ending_name() -> void:
	assert_eq(EndingDetermination.get_ending_name(EndingDetermination.EndingType.DEFAULT), "江湖浪子")

## ============================================================================
## 阈值容忍度
## ============================================================================

func test_tolerance_lowers_threshold() -> void:
	_ending.ending_threshold_tolerance = 5
	_manager.set_dao_heart_value(55)
	_manager.set_relationship_value("liuruyan", 65)
	_manager.set_relationship_value("xuanjizhenren", 45)
	assert_eq(_ending.determine_ending(_manager), EndingDetermination.EndingType.RIGHTEOUS_LEADER)

## ============================================================================
## 结局名称
## ============================================================================

func test_all_ending_names_exist() -> void:
	for ending in EndingDetermination.EndingType.values():
		var name := EndingDetermination.get_ending_name(ending)
		assert_true(name.length() > 0, "结局 %d 应有名称" % ending)
