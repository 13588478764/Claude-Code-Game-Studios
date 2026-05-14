## 礼物系统单元测试
## 覆盖：喜好分档、新鲜度衰减、生日加成、每日限制、边界值
extends GutTest

const RelationshipManagerScript = preload("res://src/scripts/relationship/relationship_manager.gd")
var _manager = null

func before_each() -> void:
	_manager = RelationshipManagerScript.new()
	add_child_autofree(_manager)
	# _ready()会从文件加载，之后再覆盖为测试数据
	_manager.current_game_day = 100
	_manager._npc_database = {
		"yunzhonghe": {
			"id": "yunzhonghe",
			"alignment": "righteous",
			"birthday": 100,
			"gift_preferences": {
				"loves": ["ancient_sword", "sword_manual"],
				"likes": ["tea", "calligraphy"],
				"dislikes": ["cheap_jewelry"]
			}
		},
		"xiaohanye": {
			"id": "xiaohanye",
			"alignment": "evil",
			"birthday": 300,
			"gift_preferences": {
				"loves": ["ancient_sword"],
				"likes": ["wine"],
				"dislikes": ["flowers"]
			}
		}
	}

## ============================================================================
## 喜好等级判定
## ============================================================================

func test_preference_loves() -> void:
	assert_eq(_manager.get_gift_preference_level("yunzhonghe", "ancient_sword"), "loves")

func test_preference_likes() -> void:
	assert_eq(_manager.get_gift_preference_level("yunzhonghe", "tea"), "likes")

func test_preference_dislikes() -> void:
	assert_eq(_manager.get_gift_preference_level("yunzhonghe", "cheap_jewelry"), "dislikes")

func test_preference_normal() -> void:
	assert_eq(_manager.get_gift_preference_level("yunzhonghe", "random_item"), "normal")

func test_preference_unknown_npc() -> void:
	assert_eq(_manager.get_gift_preference_level("unknown_npc", "tea"), "normal")

## ============================================================================
## 基础关系值
## ============================================================================

func test_gift_loves_base_value_15() -> void:
	var result: Dictionary = _manager.give_gift("yunzhonghe", "ancient_sword")
	assert_true(result.success)
	assert_eq(result.preference, "loves")
	# 生日当天(100)，birthday_bonus=2.0，gain = int(15 * 1.0 * 2.0) = 30
	assert_eq(result.gain, 30)

func test_gift_likes_base_value_10() -> void:
	_manager.current_game_day = 50
	var result: Dictionary = _manager.give_gift("yunzhonghe", "tea")
	assert_true(result.success)
	assert_eq(result.preference, "likes")
	assert_eq(result.gain, 10)

func test_gift_normal_base_value_5() -> void:
	_manager.current_game_day = 50
	var result: Dictionary = _manager.give_gift("yunzhonghe", "random_item")
	assert_true(result.success)
	assert_eq(result.preference, "normal")
	assert_eq(result.gain, 5)

func test_gift_dislikes_base_value_minus_5() -> void:
	_manager.current_game_day = 50
	var result: Dictionary = _manager.give_gift("yunzhonghe", "cheap_jewelry")
	assert_true(result.success)
	assert_eq(result.preference, "dislikes")
	assert_eq(result.gain, -5)

## ============================================================================
## 生日加成
## ============================================================================

func test_birthday_bonus_doubles_gain() -> void:
	# 云中鹤生日=100，当前日=100
	_manager.current_game_day = 100
	var result: Dictionary = _manager.give_gift("yunzhonghe", "tea")
	# likes(10) * freshness(1.0) * birthday(2.0) = 20
	assert_eq(result.gain, 20)

func test_no_birthday_bonus_on_other_day() -> void:
	_manager.current_game_day = 101
	var result: Dictionary = _manager.give_gift("yunzhonghe", "tea")
	# likes(10) * freshness(1.0) * birthday(1.0) = 10
	assert_eq(result.gain, 10)

func test_birthday_wraps_at_365() -> void:
	# birthday=100, day=465 → 465 % 365 = 100
	_manager.current_game_day = 465
	assert_true(_manager._is_npc_birthday("yunzhonghe"))

## ============================================================================
## 每日限制
## ============================================================================

func test_can_give_gift_initially() -> void:
	assert_true(_manager.can_give_gift("yunzhonghe"))

func test_daily_limit_blocks_second_gift() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	assert_false(_manager.can_give_gift("yunzhonghe"))

func test_daily_limit_resets_next_day() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	_manager.current_game_day = 51
	assert_true(_manager.can_give_gift("yunzhonghe"))

func test_daily_limit_per_npc() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	assert_true(_manager.can_give_gift("xiaohanye"))

func test_second_gift_same_day_rejected() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	var result: Dictionary = _manager.give_gift("yunzhonghe", "ancient_sword")
	assert_false(result.success)
	assert_eq(result.reason, "今日已赠送")

## ============================================================================
## 新鲜度衰减
## ============================================================================

func test_freshness_first_gift_is_1() -> void:
	assert_almost_eq(_manager._calculate_freshness("yunzhonghe"), 1.0, 0.001)

func test_freshness_consecutive_day_2() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	_manager.current_game_day = 51
	# consecutive_gifts=1 → max(0.5, 1.0 - 1*0.17) = 0.83
	assert_almost_eq(_manager._calculate_freshness("yunzhonghe"), 0.83, 0.01)

func test_freshness_consecutive_day_3_min() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	_manager.current_game_day = 51
	_manager.give_gift("yunzhonghe", "tea")
	_manager.current_game_day = 52
	# consecutive_gifts=2 → max(0.5, 1.0 - 2*0.17) = 0.66
	assert_almost_eq(_manager._calculate_freshness("yunzhonghe"), 0.66, 0.01)

func test_freshness_resets_after_gap() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	_manager.current_game_day = 53
	# 隔了2天（>1天），新鲜度重置
	assert_almost_eq(_manager._calculate_freshness("yunzhonghe"), 1.0, 0.001)

func test_freshness_floor_at_0_5() -> void:
	# 连续赠送10天
	for day in range(10):
		_manager.current_game_day = 50 + day
		_manager.give_gift("yunzhonghe", "tea")

	_manager.current_game_day = 60
	assert_almost_eq(_manager._calculate_freshness("yunzhonghe"), 0.5, 0.01)

## ============================================================================
## 关系值clamp边界
## ============================================================================

func test_gift_clamp_at_max_100() -> void:
	_manager.set_relationship_value("yunzhonghe", 95)
	_manager.current_game_day = 50
	var result: Dictionary = _manager.give_gift("yunzhonghe", "ancient_sword")
	# loves(15), 但关系值不超过100
	assert_eq(_manager.get_relationship_value("yunzhonghe"), 100)

func test_gift_dislikes_clamp_at_min() -> void:
	_manager.set_relationship_value("yunzhonghe", -98)
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "cheap_jewelry")
	assert_eq(_manager.get_relationship_value("yunzhonghe"), -100)

## ============================================================================
## 赠送不存在的NPC
## ============================================================================

func test_gift_to_unknown_npc_fails() -> void:
	var result: Dictionary = _manager.give_gift("unknown_npc", "tea")
	assert_false(result.success)
	assert_eq(result.reason, "NPC不存在")

## ============================================================================
## 信号触发
## ============================================================================

func test_gift_given_signal_emitted() -> void:
	var result_arr := [false, 0]
	var callback := func(_npc_id, _item_id, gain):
		result_arr[0] = true
		result_arr[1] = gain
	_manager.gift_given.connect(callback)

	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")
	assert_true(result_arr[0])
	assert_eq(result_arr[1], 10)

## ============================================================================
## 保存/加载礼物记录
## ============================================================================

func test_gift_history_save_load_roundtrip() -> void:
	_manager.current_game_day = 50
	_manager.give_gift("yunzhonghe", "tea")

	var saved: Dictionary = _manager.save_data()
	_manager.reset_all()
	_manager._npc_database = {"yunzhonghe": {"id": "yunzhonghe", "birthday": 100, "gift_preferences": {"loves": [], "likes": ["tea"], "dislikes": []}}}
	_manager.load_data(saved)

	_manager.current_game_day = 50
	assert_false(_manager.can_give_gift("yunzhonghe"))
	_manager.current_game_day = 51
	assert_true(_manager.can_give_gift("yunzhonghe"))
