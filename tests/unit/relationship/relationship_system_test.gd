## 角色关系系统单元测试
## 覆盖：关系值/等级判定、道心值/等级判定、NPC态度修正、商店折扣、时间衰减、信号触发
extends GutTest

const RelationshipManagerScript = preload("res://src/scripts/relationship/relationship_manager.gd")
var _manager = null

func before_each() -> void:
	_manager = RelationshipManagerScript.new()
	add_child_autofree(_manager)
	_manager.enable_time_decay = true
	_manager.current_game_day = 100

## ============================================================================
## 关系值与等级判定
## ============================================================================

func test_relationship_level_enemy_at_minus_50() -> void:
	_manager.set_relationship_value("npc_a", -50)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.ENEMY)

func test_relationship_level_cold_at_minus_10() -> void:
	_manager.set_relationship_value("npc_a", -10)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.COLD)

func test_relationship_level_neutral_at_0() -> void:
	_manager.set_relationship_value("npc_a", 0)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.NEUTRAL)

func test_relationship_level_neutral_at_9() -> void:
	_manager.set_relationship_value("npc_a", 9)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.NEUTRAL)

func test_relationship_level_friendly_at_10() -> void:
	_manager.set_relationship_value("npc_a", 10)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.FRIENDLY)

func test_relationship_level_friendly_at_49() -> void:
	_manager.set_relationship_value("npc_a", 49)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.FRIENDLY)

func test_relationship_level_intimate_at_50() -> void:
	_manager.set_relationship_value("npc_a", 50)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.INTIMATE)

func test_relationship_level_intimate_at_79() -> void:
	_manager.set_relationship_value("npc_a", 79)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.INTIMATE)

func test_relationship_level_best_friend_at_80() -> void:
	_manager.set_relationship_value("npc_a", 80)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.BEST_FRIEND)

func test_relationship_level_best_friend_at_100() -> void:
	_manager.set_relationship_value("npc_a", 100)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.BEST_FRIEND)

func test_relationship_clamp_at_max() -> void:
	_manager.set_relationship_value("npc_a", 90)
	_manager.modify_relationship("npc_a", 50, "test")
	assert_eq(_manager.get_relationship_value("npc_a"), 100)

func test_relationship_clamp_at_min() -> void:
	_manager.set_relationship_value("npc_a", -90)
	_manager.modify_relationship("npc_a", -50, "test")
	assert_eq(_manager.get_relationship_value("npc_a"), -100)

## ============================================================================
## 关系值修改和multiplier
## ============================================================================

func test_modify_relationship_with_multiplier() -> void:
	_manager.global_multiplier = 2.0
	_manager.modify_relationship("npc_a", 10, "test")
	assert_eq(_manager.get_relationship_value("npc_a"), 20)

func test_modify_relationship_with_half_multiplier() -> void:
	_manager.global_multiplier = 0.5
	_manager.modify_relationship("npc_a", 10, "test")
	assert_eq(_manager.get_relationship_value("npc_a"), 5)

## ============================================================================
## 关系等级变化信号
## ============================================================================

func test_relationship_level_changed_signal_emitted() -> void:
	var result_arr := [false]
	var callback := func(_npc_id, _old, _new): result_arr[0] = true
	_manager.relationship_level_changed.connect(callback)

	# 从0(中立)到50(亲密)
	_manager.modify_relationship("npc_a", 50, "test")
	assert_true(result_arr[0])

func test_relationship_changed_signal_no_level_change() -> void:
	var result_arr := [false]
	var callback := func(_npc_id, _old, _new): result_arr[0] = true
	_manager.relationship_level_changed.connect(callback)

	# 从0到5，仍在中立范围
	_manager.modify_relationship("npc_a", 5, "test")
	assert_false(result_arr[0])

func test_relationship_level_downgrade() -> void:
	_manager.set_relationship_value("npc_a", 80)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.BEST_FRIEND)

	_manager.set_relationship_value("npc_a", 49)
	assert_eq(_manager.get_relationship_level("npc_a"), RelationshipData.RelationshipLevel.FRIENDLY)

## ============================================================================
## 道心值与等级判定
## ============================================================================

func test_dao_heart_evil_master_at_minus_60() -> void:
	_manager.set_dao_heart_value(-60)
	assert_eq(_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.EVIL_MASTER)

func test_dao_heart_evil_leaning_at_minus_30() -> void:
	_manager.set_dao_heart_value(-30)
	assert_eq(_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.EVIL_LEANING)

func test_dao_heart_neutral_at_0() -> void:
	_manager.set_dao_heart_value(0)
	assert_eq(_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.NEUTRAL)

func test_dao_heart_righteous_leaning_at_30() -> void:
	_manager.set_dao_heart_value(30)
	assert_eq(_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.RIGHTEOUS_LEANING)

func test_dao_heart_righteous_master_at_60() -> void:
	_manager.set_dao_heart_value(60)
	assert_eq(_manager.get_dao_heart_level(), RelationshipData.DaoHeartLevel.RIGHTEOUS_MASTER)

func test_dao_heart_clamp_at_max() -> void:
	_manager.set_dao_heart_value(90)
	_manager.modify_dao_heart(50, "test")
	assert_eq(_manager.get_dao_heart_value(), 100)

func test_dao_heart_clamp_at_min() -> void:
	_manager.set_dao_heart_value(-90)
	_manager.modify_dao_heart(-50, "test")
	assert_eq(_manager.get_dao_heart_value(), -100)

## ============================================================================
## 功法修炼限制
## ============================================================================

func test_can_learn_righteous_martial_art_with_positive_dao() -> void:
	_manager.set_dao_heart_value(10)
	assert_true(_manager.can_learn_martial_art("righteous"))

func test_cannot_learn_righteous_martial_art_with_negative_dao() -> void:
	_manager.set_dao_heart_value(-10)
	assert_false(_manager.can_learn_martial_art("righteous"))

func test_can_learn_evil_martial_art_with_negative_dao() -> void:
	_manager.set_dao_heart_value(-10)
	assert_true(_manager.can_learn_martial_art("evil"))

func test_cannot_learn_evil_martial_art_with_positive_dao() -> void:
	_manager.set_dao_heart_value(10)
	assert_false(_manager.can_learn_martial_art("evil"))

func test_can_learn_neutral_martial_art_always() -> void:
	_manager.set_dao_heart_value(50)
	assert_true(_manager.can_learn_martial_art("neutral"))
	_manager.set_dao_heart_value(-50)
	assert_true(_manager.can_learn_martial_art("neutral"))

## ============================================================================
## 商店折扣
## ============================================================================

func test_shop_discount_no_discount_for_neutral() -> void:
	_manager.set_relationship_value("npc_a", 0)
	assert_eq(_manager.get_shop_discount("npc_a"), 0.0)

func test_shop_discount_10_percent_for_friendly() -> void:
	_manager.set_relationship_value("npc_a", 30)
	assert_almost_eq(_manager.get_shop_discount("npc_a"), 0.10, 0.001)

func test_shop_discount_20_percent_for_intimate() -> void:
	_manager.set_relationship_value("npc_a", 60)
	assert_almost_eq(_manager.get_shop_discount("npc_a"), 0.20, 0.001)

func test_shop_discount_30_percent_for_best_friend() -> void:
	_manager.set_relationship_value("npc_a", 85)
	assert_almost_eq(_manager.get_shop_discount("npc_a"), 0.30, 0.001)

## ============================================================================
## NPC态度修正
## ============================================================================

func test_righteous_npc_positive_modifier_with_high_dao() -> void:
	_manager.set_dao_heart_value(60)
	var modifier: int = _manager.get_npc_attitude_modifier("npc_a", "righteous")
	assert_eq(modifier, 20)

func test_righteous_npc_negative_modifier_with_evil_dao() -> void:
	_manager.set_dao_heart_value(-60)
	var modifier: int = _manager.get_npc_attitude_modifier("npc_a", "righteous")
	assert_eq(modifier, -30)

func test_evil_npc_positive_modifier_with_evil_dao() -> void:
	_manager.set_dao_heart_value(-60)
	var modifier: int = _manager.get_npc_attitude_modifier("npc_a", "evil")
	assert_eq(modifier, 20)

func test_evil_npc_negative_modifier_with_righteous_dao() -> void:
	_manager.set_dao_heart_value(60)
	var modifier: int = _manager.get_npc_attitude_modifier("npc_a", "evil")
	assert_eq(modifier, -30)

## ============================================================================
## 时间衰减
## ============================================================================

func test_time_decay_triggers_after_7_days() -> void:
	_manager.set_relationship_value("npc_a", 30)
	var rel: RelationshipData.NPCRelationship = _manager.get_or_create_relationship("npc_a")
	rel.last_interaction_time = 90
	_manager.current_game_day = 100

	_manager.process_time_decay()
	assert_eq(_manager.get_relationship_value("npc_a"), 29)

func test_time_decay_no_effect_within_7_days() -> void:
	_manager.set_relationship_value("npc_a", 30)
	var rel: RelationshipData.NPCRelationship = _manager.get_or_create_relationship("npc_a")
	rel.last_interaction_time = 95
	_manager.current_game_day = 100

	_manager.process_time_decay()
	assert_eq(_manager.get_relationship_value("npc_a"), 30)

func test_time_decay_no_effect_on_neutral() -> void:
	_manager.set_relationship_value("npc_a", 5)
	var rel: RelationshipData.NPCRelationship = _manager.get_or_create_relationship("npc_a")
	rel.last_interaction_time = 80
	_manager.current_game_day = 100

	_manager.process_time_decay()
	assert_eq(_manager.get_relationship_value("npc_a"), 5)

func test_time_decay_disabled() -> void:
	_manager.enable_time_decay = false
	_manager.set_relationship_value("npc_a", 30)
	var rel: RelationshipData.NPCRelationship = _manager.get_or_create_relationship("npc_a")
	rel.last_interaction_time = 80

	_manager.process_time_decay()
	assert_eq(_manager.get_relationship_value("npc_a"), 30)

## ============================================================================
## 保存/加载
## ============================================================================

func test_save_load_roundtrip() -> void:
	_manager.set_relationship_value("npc_a", 42)
	_manager.set_dao_heart_value(35)
	_manager.current_game_day = 200

	var saved: Dictionary = _manager.save_data()

	_manager.reset_all()
	assert_eq(_manager.get_relationship_value("npc_a"), 0)

	_manager.load_data(saved)
	assert_eq(_manager.get_relationship_value("npc_a"), 42)
	assert_eq(_manager.get_dao_heart_value(), 35)
	assert_eq(_manager.current_game_day, 200)

func test_load_empty_data_no_crash() -> void:
	_manager.set_relationship_value("npc_a", 10)
	_manager.load_data({})
	assert_eq(_manager.get_relationship_value("npc_a"), 10)
