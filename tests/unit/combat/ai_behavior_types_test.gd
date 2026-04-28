# AI行为类型单元测试
# 验证五种核心战术意识行为的实现

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_basic_attack_behavior_correctly_implemented())
	results.append(test_weakness_exploitation_behavior_correctly_implemented())
	results.append(test_status_management_behavior_correctly_implemented())
	results.append(test_survival_instinct_behavior_correctly_implemented())
	
	return results

# 测试1: 基础攻击行为正确实现
func test_basic_attack_behavior_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "基础攻击行为正确实现"
	
	# 创建测试数据
	var test_enemy = {
		"id": "test_enemy_1",
		"hp": 50,
		"max_hp": 100,
		"attack_power": 20,
		"attack_attribute": "fire",
		"has_debuff_skill": true,
		"has_dispel_skill": true,
		"has_healing_skill": false,
		"hp_ratio": 0.5
	}
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 30,
			"max_hp": 100,
			"hp_ratio": 0.3,
			"attack_power": 25,
			"defense": 10,
			"fire_resistance": -0.2,
			"has_strong_buff": false,
			"has_status": func(status): return status == "broken" if status == "broken" else false
		},
		{
			"id": "player_2", 
			"hp": 80,
			"max_hp": 100,
			"hp_ratio": 0.8,
			"attack_power": 15,
			"defense": 8,
			"fire_resistance": 0.1,
			"has_strong_buff": true,
			"has_status": func(status): return false
		}
	]
	
	# 创建行为管理器实例
	var behavior_manager = load("res://src/scripts/combat/enemy_behavior_manager.gd").new()
	
	# 评估基础攻击行为
	var scores = behavior_manager.evaluate_basic_attack(test_enemy, test_targets)
	
	# 验证结果
	if scores.size() == test_targets.size() and scores.has("player_1") and scores.has("player_2"):
		result.passed = true
		result.message = "基础攻击行为评估成功，为每个目标计算了评分"
	else:
		result.passed = false
		result.message = "基础攻击行为评估失败"
	
	return result

# 测试2: 弱点利用行为正确实现
func test_weakness_exploitation_behavior_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "弱点利用行为正确实现"
	
	# 创建测试数据
	var test_enemy = {
		"id": "test_enemy_1",
		"hp": 50,
		"max_hp": 100,
		"attack_power": 20,
		"attack_attribute": "fire",
		"has_debuff_skill": true,
		"has_dispel_skill": true,
		"has_healing_skill": false,
		"hp_ratio": 0.5
	}
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 30,
			"max_hp": 100,
			"hp_ratio": 0.3,
			"attack_power": 25,
			"defense": 10,
			"fire_resistance": -0.2,  # 弱点
			"has_strong_buff": false,
			"has_status": func(status): return status == "broken"  # 破防
		},
		{
			"id": "player_2", 
			"hp": 80,
			"max_hp": 100,
			"hp_ratio": 0.8,
			"attack_power": 15,
			"defense": 8,
			"fire_resistance": 0.1,  # 非弱点
			"has_strong_buff": true,
			"has_status": func(status): return false
		}
	]
	
	# 创建行为管理器实例
	var behavior_manager = load("res://src/scripts/combat/enemy_behavior_manager.gd").new()
	
	# 评估弱点利用行为
	var scores = behavior_manager.evaluate_weakness_exploitation(test_enemy, test_targets)
	
	# 验证结果
	if scores.size() == test_targets.size() and scores.has("player_1") and scores.has("player_2"):
		result.passed = true
		result.message = "弱点利用行为评估成功，为每个目标计算了评分"
	else:
		result.passed = false
		result.message = "弱点利用行为评估失败"
	
	return result

# 测试3: 状态管理行为正确实现
func test_status_management_behavior_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "状态管理行为正确实现"
	
	# 创建测试数据
	var test_enemy = {
		"id": "test_enemy_1",
		"hp": 50,
		"max_hp": 100,
		"attack_power": 20,
		"attack_attribute": "fire",
		"has_debuff_skill": true,
		"has_dispel_skill": true,
		"has_healing_skill": false,
		"hp_ratio": 0.5
	}
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 30,
			"max_hp": 100,
			"hp_ratio": 0.3,  # 低血
			"attack_power": 25,
			"defense": 10,
			"fire_resistance": -0.2,
			"has_strong_buff": false,
			"has_status": func(status): return status == "broken"
		},
		{
			"id": "player_2", 
			"hp": 80,
			"max_hp": 100,
			"hp_ratio": 0.8,  # 高血
			"attack_power": 15,
			"defense": 8,
			"fire_resistance": 0.1,
			"has_strong_buff": true,  # 有强增益
			"has_status": func(status): return false
		}
	]
	
	# 创建行为管理器实例
	var behavior_manager = load("res://src/scripts/combat/enemy_behavior_manager.gd").new()
	
	# 评估状态管理行为
	var scores = behavior_manager.evaluate_status_management(test_enemy, test_targets)
	
	# 验证结果
	if scores.size() == test_targets.size() and scores.has("player_1") and scores.has("player_2"):
		result.passed = true
		result.message = "状态管理行为评估成功，为每个目标计算了评分"
	else:
		result.passed = false
		result.message = "状态管理行为评估失败"
	
	return result

# 测试4: 生存本能行为正确实现
func test_survival_instinct_behavior_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "生存本能行为正确实现"
	
	# 创建测试数据
	var test_enemy = {
		"id": "test_enemy_1",
		"hp": 20,  # 低血
		"max_hp": 100,
		"attack_power": 20,
		"attack_attribute": "fire",
		"has_debuff_skill": true,
		"has_dispel_skill": true,
		"has_healing_skill": false,  # 无治疗手段
		"hp_ratio": 0.2  # 低血
	}
	
	var test_targets = [
		{
			"id": "player_1",
			"hp": 30,
			"max_hp": 100,
			"hp_ratio": 0.3,
			"attack_power": 25,  # 高威胁
			"defense": 10,
			"fire_resistance": -0.2,
			"has_strong_buff": false,
			"has_status": func(status): return status == "broken"
		},
		{
			"id": "player_2", 
			"hp": 80,
			"max_hp": 100,
			"hp_ratio": 0.8,
			"attack_power": 5,  # 低威胁
			"defense": 8,
			"fire_resistance": 0.1,
			"has_strong_buff": true,
			"has_status": func(status): return false
		}
	]
	
	# 创建行为管理器实例
	var behavior_manager = load("res://src/scripts/combat/enemy_behavior_manager.gd").new()
	
	# 评估生存本能行为
	var scores = behavior_manager.evaluate_survival_instinct(test_enemy, test_targets)
	
	# 验证结果
	if scores.size() == test_targets.size() and scores.has("player_1") and scores.has("player_2"):
		result.passed = true
		result.message = "生存本能行为评估成功，为每个目标计算了评分"
	else:
		result.passed = false
		result.message = "生存本能行为评估失败"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行AI行为类型测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count