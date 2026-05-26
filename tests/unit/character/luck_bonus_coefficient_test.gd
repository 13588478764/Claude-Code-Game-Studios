## luck_bonus_coefficient_test.gd
## 福缘软上限系数公式回归测试 (polish-fixlist-2026-05-25 #12)
##
## 验证 character_system.gd::get_luck_bonus_coefficient() 实现软上限:
##   luck <= 0:   coeff = 0.0
##   luck <= 100: coeff = luck / 100  (线性段, 每点 +1%)
##   luck >  100: coeff = 1.0 + (luck - 100) / 300  (递减段, 每点 +0.33%)
##
## 对齐 design/gdd/character-progression-system.md L146-L152
## 修复前: 5 个 call site 用线性 (1 + luck/100), 高福缘 Build 收益脱离设计
## 修复后: 单一真值 static 方法, 100 点后边际递减

extends GutTest

var CharacterSystemScript = load("res://src/scripts/character/character_system.gd")

func test_luck_bonus_zero_or_negative_returns_zero() -> void:
	# Arrange + Act + Assert: 边界与负值都应返回 0.0
	assert_eq(CharacterSystemScript.get_luck_bonus_coefficient(0.0), 0.0, "luck=0 应返回 0.0")
	assert_eq(CharacterSystemScript.get_luck_bonus_coefficient(-10.0), 0.0, "负 luck 应返回 0.0")

func test_luck_bonus_linear_segment_at_50() -> void:
	# 线性段: luck = 50 → coeff = 50 / 100 = 0.5
	var coeff: float = CharacterSystemScript.get_luck_bonus_coefficient(50.0)
	assert_almost_eq(coeff, 0.5, 0.0001, "luck=50 软上限系数应为 0.5")

func test_luck_bonus_at_pivot_100() -> void:
	# 拐点: luck = 100 → coeff = 1.0
	var coeff: float = CharacterSystemScript.get_luck_bonus_coefficient(100.0)
	assert_almost_eq(coeff, 1.0, 0.0001, "luck=100 (拐点) 软上限系数应为 1.0")

func test_luck_bonus_diminishing_segment_at_200() -> void:
	# 递减段: luck = 200 → coeff = 1.0 + 100/300 ≈ 1.3333
	var coeff: float = CharacterSystemScript.get_luck_bonus_coefficient(200.0)
	assert_almost_eq(coeff, 1.3333, 0.001, "luck=200 软上限系数应为 1.33 (GDD 示例)")

func test_luck_bonus_max_at_495() -> void:
	# GDD 示例最大值: luck = 495 → coeff = 1.0 + 395/300 ≈ 2.3167
	var coeff: float = CharacterSystemScript.get_luck_bonus_coefficient(495.0)
	assert_almost_eq(coeff, 2.3167, 0.001, "luck=495 (GDD 上限示例) 软上限系数应为 2.32")

func test_luck_bonus_marginal_rate_drops_at_pivot() -> void:
	# 拐点斜率变化保护: luck 99→100 增加 0.01; luck 100→101 增加 ≈ 0.0033 (1/3 速率)
	var coeff_99: float = CharacterSystemScript.get_luck_bonus_coefficient(99.0)
	var coeff_100: float = CharacterSystemScript.get_luck_bonus_coefficient(100.0)
	var coeff_101: float = CharacterSystemScript.get_luck_bonus_coefficient(101.0)

	var slope_before: float = coeff_100 - coeff_99    # ≈ 0.01
	var slope_after: float = coeff_101 - coeff_100    # ≈ 0.00333

	assert_almost_eq(slope_before, 0.01, 0.0001, "拐点前每点 luck +0.01 加成")
	assert_almost_eq(slope_after, 0.003333, 0.0001, "拐点后每点 luck +0.00333 加成 (软上限生效)")
	assert_true(slope_after < slope_before * 0.5, "拐点后边际收益应至少减半 (软上限保护)")
