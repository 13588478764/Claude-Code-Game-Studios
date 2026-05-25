## critical_rate_formula_test.gd
## 暴击率公式回归测试 (polish-fixlist-2026-05-25 #4 / commit 7a96c95)
##
## 验证 character_system.gd::get_combat_stats() 中的暴击率公式:
##   critical_rate = agility * 0.003 + luck * 0.002
##
## 对齐 design/gdd/character-progression-system.md L59
## 修复前 (错误): intelligence / 20.0  → 仅依赖悟性, 与 GDD 完全脱节
## 修复后 (正确): agility * 0.003 + luck * 0.002

extends GutTest

var CharacterSystemScript = load("res://src/scripts/character/character_system.gd")
var character_system: Node = null

func before_each() -> void:
	character_system = CharacterSystemScript.new()
	add_child_autofree(character_system)
	character_system.initialize_character()

func after_each() -> void:
	character_system = null

func test_critical_rate_baseline_at_default_attributes() -> void:
	# Arrange: 默认属性 agility=10, luck=10, realm_bonus=1.0
	# Act
	var combat_stats: Dictionary = character_system.get_combat_stats()

	# Assert: 10 * 0.003 + 10 * 0.002 = 0.03 + 0.02 = 0.05 (5%)
	assert_almost_eq(combat_stats["critical_rate"], 0.05, 0.0001, "默认属性暴击率应为 5%")

func test_critical_rate_scales_with_agility() -> void:
	# Arrange: 直接拍属性, 跳过 allocate_attribute_points 的总点数限制
	character_system.attributes.agility = 50
	character_system.attributes.luck = 10

	# Act
	var combat_stats: Dictionary = character_system.get_combat_stats()

	# Assert: 50 * 0.003 + 10 * 0.002 = 0.15 + 0.02 = 0.17 (17%)
	assert_almost_eq(combat_stats["critical_rate"], 0.17, 0.0001, "身法 50 / 福缘 10 暴击率应为 17%")

func test_critical_rate_scales_with_luck() -> void:
	# Arrange: luck 从 10 → 100 (高福缘角色)
	character_system.attributes.agility = 10
	character_system.attributes.luck = 100

	# Act
	var combat_stats: Dictionary = character_system.get_combat_stats()

	# Assert: 10 * 0.003 + 100 * 0.002 = 0.03 + 0.20 = 0.23 (23%)
	assert_almost_eq(combat_stats["critical_rate"], 0.23, 0.0001, "身法 10 / 福缘 100 暴击率应为 23%")

func test_critical_rate_not_influenced_by_intelligence() -> void:
	# 回归测试: 修复前公式是 intelligence / 20.0; 修复后悟性不应再影响暴击率
	# Arrange: agility 和 luck 保持基线, intelligence 拉到 999
	character_system.attributes.agility = 10
	character_system.attributes.luck = 10
	character_system.attributes.intelligence = 999

	# Act
	var combat_stats: Dictionary = character_system.get_combat_stats()

	# Assert: 暴击率仍为基线 5%, 不受悟性影响
	assert_almost_eq(combat_stats["critical_rate"], 0.05, 0.0001, "悟性不应影响暴击率 (修复前 bug 的回归保护)")
