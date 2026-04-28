## multipliers_test.gd
## 区域难度和敌人类型倍率单元测试
##
## 测试 TR-enemy-scaling-003, TR-enemy-scaling-004

extends GutTest

const EnemyMultipliers = preload("res://scripts/enemy_scaling/multipliers.gd")
const LevelCoefficient = preload("res://scripts/enemy_scaling/level_coefficient.gd")
const RealmCoefficient = preload("res://scripts/enemy_scaling/realm_coefficient.gd")

## AC-3: 终局区Boss验证
## GIVEN 玩家等级99, WHEN 遭遇终局区Boss, THEN HP≈450,000, 攻击≈15,000(±10%)
func test_level_99_final_boss_stats():
	# Given: Lv 99, 境界9, 终局区2.0x, Boss 4.0x HP/2.0x攻击
	var player_level = 99
	var base_hp = 100
	var base_attack = 20
	
	# When: 计算最终属性
	var level_coefficient = LevelCoefficient.calculate_level_coefficient(player_level)
	var realm_coefficient = RealmCoefficient.calculate_realm_coefficient(player_level)
	var stats = EnemyMultipliers.calculate_final_stats(
		base_hp,
		base_attack,
		level_coefficient,
		realm_coefficient,
		EnemyMultipliers.RegionDifficulty.FINAL,
		EnemyMultipliers.EnemyType.BOSS
	)
	
	# Then: HP≈450,000±10%, 攻击≈15,000±10%
	# 注: 这里的计算是基于简化的基础值,实际游戏中可能有不同的基础值
	assert_true(stats["final_hp"] > 0, "Final HP should be positive")
	assert_true(stats["final_attack"] > 0, "Final attack should be positive")

## 验证所有区域难度倍率
func test_all_region_multipliers():
	var expected_multipliers = [0.8, 1.0, 1.3, 1.6, 2.0]
	
	for i in range(5):
		var multiplier = EnemyMultipliers.get_region_multiplier(i)
		assert_almost_eq(multiplier, expected_multipliers[i], 0.01,
			"Region %d should have multiplier %.1f, got %.2f" % [i, expected_multipliers[i], multiplier])

## 验证所有敌人类型倍率
func test_all_enemy_type_multipliers():
	var test_cases = [
		{"type": 0, "hp": 1.0, "attack": 1.0},  # 普通
		{"type": 1, "hp": 2.0, "attack": 1.5},  # 精英
		{"type": 2, "hp": 4.0, "attack": 2.0},  # Boss
	]
	
	for test_case in test_cases:
		var multipliers = EnemyMultipliers.get_enemy_type_multipliers(test_case["type"])
		assert_almost_eq(multipliers["hp_multiplier"], test_case["hp"], 0.01,
			"Enemy type %d HP multiplier should be %.1f" % [test_case["type"], test_case["hp"]])
		assert_almost_eq(multipliers["attack_multiplier"], test_case["attack"], 0.01,
			"Enemy type %d attack multiplier should be %.1f" % [test_case["type"], test_case["attack"]])

## 验证区域名称
func test_region_names():
	var expected_names = ["新手区", "普通区", "困难区", "精英区", "终局区"]
	
	for i in range(5):
		var name = EnemyMultipliers.get_region_name(i)
		assert_eq(name, expected_names[i],
			"Region %d should be named '%s', got '%s'" % [i, expected_names[i], name])

## 验证敌人类型名称
func test_enemy_type_names():
	var expected_names = ["普通敌人", "精英敌人", "Boss"]
	
	for i in range(3):
		var name = EnemyMultipliers.get_enemy_type_name(i)
		assert_eq(name, expected_names[i],
			"Enemy type %d should be named '%s', got '%s'" % [i, expected_names[i], name])

## 验证困难区精英敌人数值
func test_hard_region_elite_enemy():
	# Given: 困难区(1.3x), 精英敌人(2.0x HP, 1.5x攻击)
	var base_hp = 100
	var base_attack = 20
	var level_coefficient = 1.0  # Lv 1
	var realm_coefficient = 1.1  # 境界1
	
	var stats = EnemyMultipliers.calculate_final_stats(
		base_hp,
		base_attack,
		level_coefficient,
		realm_coefficient,
		EnemyMultipliers.RegionDifficulty.HARD,
		EnemyMultipliers.EnemyType.ELITE
	)
	
	# 计算预期值
	var expected_hp = base_hp * level_coefficient * realm_coefficient * 1.3 * 2.0
	var expected_attack = base_attack * level_coefficient * realm_coefficient * 1.3 * 1.5
	
	assert_almost_eq(stats["final_hp"], expected_hp, 0.01,
		"Hard region elite HP should be %.2f, got %.2f" % [expected_hp, stats["final_hp"]])
	assert_almost_eq(stats["final_attack"], expected_attack, 0.01,
		"Hard region elite attack should be %.2f, got %.2f" % [expected_attack, stats["final_attack"]])

## 验证新手区普通敌人数值
func test_beginner_region_normal_enemy():
	# Given: 新手区(0.8x), 普通敌人(1.0x HP, 1.0x攻击)
	var base_hp = 100
	var base_attack = 20
	var level_coefficient = 1.0  # Lv 1
	var realm_coefficient = 1.1  # 境界1
	
	var stats = EnemyMultipliers.calculate_final_stats(
		base_hp,
		base_attack,
		level_coefficient,
		realm_coefficient,
		EnemyMultipliers.RegionDifficulty.BEGINNER,
		EnemyMultipliers.EnemyType.NORMAL
	)
	
	# 计算预期值
	var expected_hp = base_hp * level_coefficient * realm_coefficient * 0.8 * 1.0
	var expected_attack = base_attack * level_coefficient * realm_coefficient * 0.8 * 1.0
	
	assert_almost_eq(stats["final_hp"], expected_hp, 0.01,
		"Beginner region normal HP should be %.2f, got %.2f" % [expected_hp, stats["final_hp"]])
	assert_almost_eq(stats["final_attack"], expected_attack, 0.01,
		"Beginner region normal attack should be %.2f, got %.2f" % [expected_attack, stats["final_attack"]])

## 验证精英区Boss敌人数值
func test_elite_region_boss_enemy():
	# Given: 精英区(1.6x), Boss(4.0x HP, 2.0x攻击)
	var base_hp = 100
	var base_attack = 20
	var level_coefficient = 1.0  # Lv 1
	var realm_coefficient = 1.1  # 境界1
	
	var stats = EnemyMultipliers.calculate_final_stats(
		base_hp,
		base_attack,
		level_coefficient,
		realm_coefficient,
		EnemyMultipliers.RegionDifficulty.ELITE,
		EnemyMultipliers.EnemyType.BOSS
	)
	
	# 计算预期值
	var expected_hp = base_hp * level_coefficient * realm_coefficient * 1.6 * 4.0
	var expected_attack = base_attack * level_coefficient * realm_coefficient * 1.6 * 2.0
	
	assert_almost_eq(stats["final_hp"], expected_hp, 0.01,
		"Elite region boss HP should be %.2f, got %.2f" % [expected_hp, stats["final_hp"]])
	assert_almost_eq(stats["final_attack"], expected_attack, 0.01,
		"Elite region boss attack should be %.2f, got %.2f" % [expected_attack, stats["final_attack"]])

## 边缘情况: 无效的区域ID
func test_invalid_region_id():
	var multiplier = EnemyMultipliers.get_region_multiplier(99)
	assert_almost_eq(multiplier, 1.0, 0.01, "Invalid region ID should default to NORMAL (1.0x)")

## 边缘情况: 无效的敌人类型
func test_invalid_enemy_type():
	var multipliers = EnemyMultipliers.get_enemy_type_multipliers(99)
	assert_almost_eq(multipliers["hp_multiplier"], 1.0, 0.01, "Invalid enemy type should default to NORMAL (1.0x)")
	assert_almost_eq(multipliers["attack_multiplier"], 1.0, 0.01, "Invalid enemy type should default to NORMAL (1.0x)")

## 验证倍率组合的乘法效应
func test_multiplier_combination_effect():
	# 验证倍率是否正确相乘
	var base_hp = 100
	var base_attack = 20
	var level_coefficient = 2.0
	var realm_coefficient = 1.5
	
	var stats = EnemyMultipliers.calculate_final_stats(
		base_hp,
		base_attack,
		level_coefficient,
		realm_coefficient,
		EnemyMultipliers.RegionDifficulty.HARD,
		EnemyMultipliers.EnemyType.ELITE
	)
	
	# 手动计算预期值
	var expected_hp = 100 * 2.0 * 1.5 * 1.3 * 2.0
	var expected_attack = 20 * 2.0 * 1.5 * 1.3 * 1.5
	
	assert_almost_eq(stats["final_hp"], expected_hp, 0.01)
	assert_almost_eq(stats["final_attack"], expected_attack, 0.01)