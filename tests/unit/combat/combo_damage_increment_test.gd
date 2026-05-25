## combo_damage_increment_test.gd
## 连击伤害加成单位回归测试 (polish-fixlist-2026-05-25 #4 / commit 7a96c95)
##
## 验证 combat_system.gd::COMBO_DAMAGE_INCREMENT 与 get_combo_damage_multiplier():
##   每次连击 +5%, 上限 +30% (6 击封顶)
##
## 对齐 design/gdd/combat-system.md
## 修复前 (错误): COMBO_DAMAGE_INCREMENT = 0.01 → 6 击仅 +6%, 远低于 30% 上限
## 修复后 (正确): COMBO_DAMAGE_INCREMENT = 0.05 → 6 击 ×5% = 30% 触顶

extends GutTest

var CombatSystemScript = load("res://src/scripts/combat/combat_system.gd")
var combat_system: Node = null

func before_each() -> void:
	combat_system = CombatSystemScript.new()
	add_child_autofree(combat_system)
	combat_system.initialize()

func after_each() -> void:
	combat_system = null

func test_combo_increment_constant_is_five_percent() -> void:
	# Arrange / Act
	var increment: float = CombatSystemScript.COMBO_DAMAGE_INCREMENT

	# Assert: 0.05 (5% per combo step)
	assert_almost_eq(increment, 0.05, 0.0001, "COMBO_DAMAGE_INCREMENT 应为 0.05 (5%)")

func test_combo_multiplier_at_zero_combo_is_baseline() -> void:
	# Arrange
	var participant = combat_system.add_participant("Tester", 30)

	# Act: 不增加连击
	var multiplier: float = participant.resources.get_combo_damage_multiplier()

	# Assert: 基线 1.0 (无连击)
	assert_almost_eq(multiplier, 1.0, 0.0001, "0 连击应为基线 1.0")

func test_combo_multiplier_at_three_combos_is_115_percent() -> void:
	# Arrange
	var participant = combat_system.add_participant("Tester", 30)

	# Act: 3 连击
	for i in range(3):
		participant.resources.increment_combo()
	var multiplier: float = participant.resources.get_combo_damage_multiplier()

	# Assert: 1.0 + 3 * 0.05 = 1.15
	assert_almost_eq(multiplier, 1.15, 0.0001, "3 连击应为 +15% (1.15x)")

func test_combo_multiplier_caps_at_six_combos_thirty_percent() -> void:
	# Arrange
	var participant = combat_system.add_participant("Tester", 30)

	# Act: 6 连击 (理论触顶)
	for i in range(6):
		participant.resources.increment_combo()
	var multiplier_at_six: float = participant.resources.get_combo_damage_multiplier()

	# Assert: 1.0 + 6 * 0.05 = 1.30 (恰好触顶)
	assert_almost_eq(multiplier_at_six, 1.30, 0.0001, "6 连击应为 +30% (1.30x), 恰好触顶")

func test_combo_multiplier_caps_at_thirty_percent_even_beyond_six() -> void:
	# 回归测试: 修复前 0.01 单位需要 30 击才触顶, 修复后 6 击触顶, 超过 6 击不应继续增长
	# Arrange
	var participant = combat_system.add_participant("Tester", 30)

	# Act: 10 连击 (远超 6 击)
	for i in range(10):
		participant.resources.increment_combo()
	var multiplier_at_ten: float = participant.resources.get_combo_damage_multiplier()

	# Assert: 仍为 1.30, 不应突破上限
	assert_almost_eq(multiplier_at_ten, 1.30, 0.0001, "10 连击应仍为 +30% (1.30x), 上限保护")
	assert_eq(CombatSystemScript.MAX_COMBO_DAMAGE_BONUS, 0.30, "MAX_COMBO_DAMAGE_BONUS 应为 30%")
