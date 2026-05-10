## enemy_generation_test.gd
## 敌人实例生成集成测试
##
## 测试 TR-enemy-scaling-001 to TR-enemy-scaling-006

extends GutTest

const EnemyGenerator = preload("res://src/scripts/enemy_scaling/enemy_generator.gd")

var enemy_generator: EnemyGenerator

func before_each():
	enemy_generator = EnemyGenerator.new()

## AC-1: 等级1新手区普通敌人数值正确
func test_level_1_beginner_normal_enemy():
	# Given: 等级1, 新手区, 普通敌人
	var enemy_base_data = {
		"base_hp": 100,
		"base_attack": 20
	}
	var player_level = 1
	var region_id = 0  # 新手区
	var enemy_type = 0  # 普通敌人
	
	# When: 生成敌人实例
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data,
		player_level,
		region_id,
		enemy_type
	)
	
	# Then: 验证最终属性
	# Lv1: 系数 = 1.0 + (1-1) × 0.15 = 1.0
	# 境界1: 系数 = 1.1
	# 新手区: 倍率 = 0.8
	# 普通敌人: 1.0x HP, 1.0x 攻击
	# 最终 = 100 × 1.0 × 1.1 × 0.8 × 1.0 = 88
	assert_almost_eq(enemy["final_hp"], 88.0, 1.0, "Level 1 beginner normal enemy HP should be ~88")
	assert_almost_eq(enemy["final_attack"], 17.6, 1.0, "Level 1 beginner normal enemy attack should be ~17.6")

## AC-2: 等级50困难区精英敌人数值正确
func test_level_50_hard_elite_enemy():
	# Given: 等级50, 困难区, 精英敌人
	var enemy_base_data = {
		"base_hp": 100,
		"base_attack": 20
	}
	var player_level = 50
	var region_id = 2  # 困难区
	var enemy_type = 1  # 精英敌人
	
	# When: 生成敌人实例
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data,
		player_level,
		region_id,
		enemy_type
	)
	
	# Then: 验证最终属性
	# Lv50: 中期指数段
	# 境界5: 系数 = 1.5
	# 困难区: 倍率 = 1.3
	# 精英敌人: 2.0x HP, 1.5x 攻击
	assert_true(enemy["final_hp"] > 0, "Level 50 hard elite enemy HP should be positive")
	assert_true(enemy["final_attack"] > 0, "Level 50 hard elite enemy attack should be positive")

## AC-3: 等级99终局区Boss数值正确
func test_level_99_final_boss_enemy():
	# Given: 等级99, 终局区, Boss
	var enemy_base_data = {
		"base_hp": 100,
		"base_attack": 20
	}
	var player_level = 99
	var region_id = 4  # 终局区
	var enemy_type = 2  # Boss
	
	# When: 生成敌人实例
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data,
		player_level,
		region_id,
		enemy_type
	)
	
	# Then: 验证最终属性
	# Lv99: 后期陡峭指数段
	# 境界9: 系数 = 1.9
	# 终局区: 倍率 = 2.0
	# Boss: 4.0x HP, 2.0x 攻击
	assert_true(enemy["final_hp"] > 0, "Level 99 final boss HP should be positive")
	assert_true(enemy["final_attack"] > 0, "Level 99 final boss attack should be positive")
	# Boss应该有最高的属性
	assert_true(enemy["final_hp"] > 1000, "Level 99 final boss HP should be very high")

## 验证敌人生成包含所有必要字段
func test_enemy_instance_has_all_fields():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 50, 2, 1
	)
	
	assert_true(enemy.has("base_hp"))
	assert_true(enemy.has("base_attack"))
	assert_true(enemy.has("final_hp"))
	assert_true(enemy.has("final_attack"))
	assert_true(enemy.has("player_level"))
	assert_true(enemy.has("region_id"))
	assert_true(enemy.has("enemy_type"))
	assert_true(enemy.has("level_coefficient"))
	assert_true(enemy.has("realm_coefficient"))
	assert_true(enemy.has("region_multiplier"))
	assert_true(enemy.has("dynamic_coefficient"))
	assert_true(enemy.has("warning_type"))

## 验证动态难度影响
func test_dynamic_difficulty_affects_stats():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	# 无动态调整
	var normal_enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 50, 2, 1, 0, 0
	)
	
	# 有失败惩罚
	var failed_enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 50, 2, 1, 3, 0
	)
	
	# 失败惩罚应该降低敌人属性
	assert_true(failed_enemy["final_hp"] < normal_enemy["final_hp"],
		"Failed enemy should have lower HP")

## 验证等级差距保护
func test_level_difference_protection():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	# 玩家等级过高 (Lv60 vs 新手区20-40)
	var too_easy_enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 60, 0, 0
	)
	
	# 应该有警告
	assert_eq(too_easy_enemy["warning_type"], 1)  # TOO_EASY
	assert_almost_eq(too_easy_enemy["region_multiplier"], 0.5, 0.01)

## 验证敌人组生成
func test_generate_enemy_group():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	var enemies = enemy_generator.generate_enemy_group(
		enemy_base_data, 50, 2, 1, 3
	)
	
	assert_eq(enemies.size(), 3, "Should generate 3 enemies")
	for enemy in enemies:
		assert_true(enemy.has("final_hp"))
		assert_true(enemy.has("final_attack"))

## 验证敌人摘要生成
func test_get_enemy_summary():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 50, 2, 1
	)
	
	var summary = enemy_generator.get_enemy_summary(enemy)
	assert_true("敌人生成摘要" in summary)
	assert_true("困难区" in summary)
	assert_true("精英敌人" in summary)

## 验证数据异常处理
func test_invalid_base_data_handling():
	var invalid_enemy_data = {
		"base_hp": 0,  # 无效
		"base_attack": -5  # 无效
	}
	
	var enemy = enemy_generator.generate_enemy_instance(
		invalid_enemy_data, 50, 2, 1
	)
	
	# 应该使用默认值
	assert_eq(enemy["base_hp"], 100)
	assert_eq(enemy["base_attack"], 20)
	assert_true(enemy["has_data_error"])

## 验证所有区域的敌人生成
func test_all_regions():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	for region_id in range(5):
		var enemy = enemy_generator.generate_enemy_instance(
			enemy_base_data, 50, region_id, 0
		)
		assert_true(enemy["final_hp"] > 0, "Region %d should generate valid enemy" % region_id)

## 验证所有敌人类型的生成
func test_all_enemy_types():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	for enemy_type in range(3):
		var enemy = enemy_generator.generate_enemy_instance(
			enemy_base_data, 50, 2, enemy_type
		)
		assert_true(enemy["final_hp"] > 0, "Enemy type %d should generate valid enemy" % enemy_type)

## 验证等级范围
func test_level_range():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	# 测试最低等级
	var low_level_enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 1, 2, 0
	)
	assert_true(low_level_enemy["final_hp"] > 0)
	
	# 测试最高等级
	var high_level_enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 99, 2, 0
	)
	assert_true(high_level_enemy["final_hp"] > 0)
	
	# 高等级敌人应该更强
	assert_true(high_level_enemy["final_hp"] > low_level_enemy["final_hp"])

## 验证完整缩放公式
func test_complete_scaling_formula():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	var enemy = enemy_generator.generate_enemy_instance(
		enemy_base_data, 50, 2, 1
	)
	
	# 验证公式: 最终 = 基础 × 等级系数 × 境界系数 × 区域倍率 × 类型倍率 × 动态系数
	var expected_hp = 100 * enemy["level_coefficient"] * enemy["realm_coefficient"] * enemy["region_multiplier"] * enemy["type_hp_multiplier"] * enemy["dynamic_coefficient"]
	
	assert_almost_eq(enemy["final_hp"], expected_hp, 0.1,
		"Final HP should match complete scaling formula")

## 验证系数范围
func test_coefficient_ranges():
	var enemy_base_data = {"base_hp": 100, "base_attack": 20}
	
	for level in [1, 25, 50, 75, 99]:
		var enemy = enemy_generator.generate_enemy_instance(
			enemy_base_data, level, 2, 0
		)
		
		assert_true(enemy["level_coefficient"] > 0, "Level coefficient should be positive")
		assert_true(enemy["realm_coefficient"] >= 1.1, "Realm coefficient should be >= 1.1")
		assert_true(enemy["realm_coefficient"] <= 1.9, "Realm coefficient should be <= 1.9")
		assert_true(enemy["region_multiplier"] > 0, "Region multiplier should be positive")
		assert_true(enemy["dynamic_coefficient"] >= 0.7, "Dynamic coefficient should be >= 0.7")
		assert_true(enemy["dynamic_coefficient"] <= 1.15, "Dynamic coefficient should be <= 1.15")