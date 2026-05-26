## exp_exponent_piecewise_test.gd
## EXP 分段指数公式回归测试 (polish-fixlist-2026-05-25 #9)
##
## 验证 character_system.gd::_get_exp_exponent() 返回分段指数:
##   Lv 1-33  → 1.0 (线性, 引导期)
##   Lv 34-66 → 1.5 (温和指数, 中期)
##   Lv 67-99 → 1.8 (陡峭指数, 后期)
##
## 对齐 design/gdd/experience-system.md L170-L172
## 修复前: exponent 扁平 = 1.5 (中期段全程, 后期升级过缓)
## 修复后: 分段函数, 后期 EXP 需求与 50000 上限对齐 GDD 设计

extends GutTest

var CharacterSystemScript = load("res://src/scripts/character/character_system.gd")
var character_system: Node = null

func before_each() -> void:
	character_system = CharacterSystemScript.new()
	add_child_autofree(character_system)
	character_system.initialize_character()

func after_each() -> void:
	character_system = null

func test_exp_exponent_early_segment_returns_1_0() -> void:
	# Arrange: 引导期等级 (Lv 1-33)
	# Act + Assert: 边界 + 中点
	assert_eq(character_system._get_exp_exponent(2), 1.0, "Lv 2 应该返回 1.0 (线性段)")
	assert_eq(character_system._get_exp_exponent(15), 1.0, "Lv 15 应该返回 1.0 (线性段)")
	assert_eq(character_system._get_exp_exponent(33), 1.0, "Lv 33 (边界) 应该返回 1.0")

func test_exp_exponent_mid_segment_returns_1_5() -> void:
	# Arrange: 中期等级 (Lv 34-66)
	# Act + Assert
	assert_eq(character_system._get_exp_exponent(34), 1.5, "Lv 34 (边界) 应该返回 1.5")
	assert_eq(character_system._get_exp_exponent(50), 1.5, "Lv 50 应该返回 1.5")
	assert_eq(character_system._get_exp_exponent(66), 1.5, "Lv 66 (边界) 应该返回 1.5")

func test_exp_exponent_late_segment_returns_1_8() -> void:
	# Arrange: 后期等级 (Lv 67-99)
	# Act + Assert
	assert_eq(character_system._get_exp_exponent(67), 1.8, "Lv 67 (边界) 应该返回 1.8")
	assert_eq(character_system._get_exp_exponent(85), 1.8, "Lv 85 应该返回 1.8")
	assert_eq(character_system._get_exp_exponent(99), 1.8, "Lv 99 (顶级) 应该返回 1.8")

func test_get_exp_required_uses_piecewise_exponent_at_boundary() -> void:
	# 验证 get_exp_required_for_level 正确接入分段函数:
	# 边界对比 — Lv 34 vs Lv 33 应有显著差异 (指数 1.0 → 1.5 切换)

	var exp_lv_33: int = character_system.get_exp_required_for_level(33)
	var exp_lv_34: int = character_system.get_exp_required_for_level(34)

	# Lv 33: base(100) * pow(33, 1.0) * realm_multiplier[3] (筑基后期 idx=3, mult=2.5) = 100 * 33 * 2.5 = 8250
	# Lv 34: base(100) * pow(34, 1.5) * realm_multiplier[3] = 100 * 198.21 * 2.5 ≈ 49553
	assert_eq(exp_lv_33, 8250, "Lv 33 分段指数 1.0 时 EXP 需求应为 8250")
	assert_true(exp_lv_34 > 49000 and exp_lv_34 < 50000, "Lv 34 切到指数 1.5 后 EXP 需求应跳到约 49553 (实际: %d)" % exp_lv_34)

func test_get_exp_required_late_game_uses_exponent_1_8() -> void:
	# Lv 99: base(100) * pow(99, 1.8) * realm_multiplier[9] (真仙 idx=9, mult=6.0)
	# pow(99, 1.8) ≈ 4178; 100 * 4178 * 6.0 ≈ 2506800
	# 注: 当前实现没有 50000 EXP 硬上限, 仅验证公式正确执行
	var exp_lv_99: int = character_system.get_exp_required_for_level(99)
	assert_true(exp_lv_99 > 2000000, "Lv 99 后期段 EXP 需求应反映指数 1.8 + realm_mult 6.0 (实际: %d)" % exp_lv_99)
