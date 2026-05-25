## martial_arts_proficiency_cap_test.gd
## 武学熟练度上限回归测试 (polish-fixlist-2026-05-25 #4 / commit 7a96c95)
##
## 验证 martial_arts_system.gd::MAX_PROFICIENCY_LEVEL 与 increase_proficiency() 上限保护:
##   熟练度上限 = 15 (与 design/gdd/martial-arts-system.md 及 :297-298 实际上限对齐)
##
## 修复前 (错误): MAX_PROFICIENCY_LEVEL = 10, 但 increase_proficiency 内部 cap 是 15 → 双标
## 修复后 (正确): MAX_PROFICIENCY_LEVEL = 15, 统一为 15

extends GutTest

var MartialArtsSystemScript = load("res://src/scripts/combat/martial_arts_system.gd")
var ma_system: Node = null
const TEST_MA_ID: String = "sword_basic_01"

func before_each() -> void:
	ma_system = MartialArtsSystemScript.new()
	add_child_autofree(ma_system)
	# 手动放置一个已学会的武学, 避免走 acquire/synthesize 流程
	var ma_info = ma_system.martial_arts_database[TEST_MA_ID].duplicate(true)
	ma_system.player_martial_arts[TEST_MA_ID] = ma_info

func after_each() -> void:
	ma_system = null

func test_max_proficiency_constant_is_fifteen() -> void:
	# Arrange / Act
	var cap: int = MartialArtsSystemScript.MAX_PROFICIENCY_LEVEL

	# Assert
	assert_eq(cap, 15, "MAX_PROFICIENCY_LEVEL 应为 15")

func test_proficiency_increases_within_cap() -> void:
	# Arrange: 起始熟练度 0
	var ma = ma_system.player_martial_arts[TEST_MA_ID]
	assert_eq(ma.proficiency_level, 0, "初始熟练度应为 0")

	# Act: 增加 5 点熟练度
	ma_system.increase_proficiency(TEST_MA_ID, 5)

	# Assert
	assert_eq(ma.proficiency_level, 5, "应增加到 5")

func test_proficiency_caps_at_fifteen() -> void:
	# Arrange
	var ma = ma_system.player_martial_arts[TEST_MA_ID]

	# Act: 一次性灌入 100 点熟练度
	ma_system.increase_proficiency(TEST_MA_ID, 100)

	# Assert: 应被 cap 在 15
	assert_eq(ma.proficiency_level, 15, "熟练度应被限制在 15")

func test_proficiency_cap_after_repeated_increases() -> void:
	# 回归测试: 多次累加不应突破上限
	# Arrange
	var ma = ma_system.player_martial_arts[TEST_MA_ID]

	# Act: 累计 6 次, 每次 +5
	for i in range(6):
		ma_system.increase_proficiency(TEST_MA_ID, 5)

	# Assert: 应停在 15
	assert_eq(ma.proficiency_level, 15, "重复加点后熟练度应停在 15")

func test_proficiency_returns_zero_for_unowned_martial_art() -> void:
	# 边界条件: 未拥有的武学应返回 0 增量
	# Act
	var gained: float = ma_system.increase_proficiency("unowned_ma_999", 10)

	# Assert
	assert_almost_eq(gained, 0.0, 0.0001, "未拥有的武学应返回 0 熟练度增量")
