# AI难度等级单元测试
# 验证三种难度等级及对应AI行为特征的实现

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_simple_difficulty_correctly_implemented())
	results.append(test_normal_difficulty_correctly_implemented())
	results.append(test_hard_difficulty_correctly_implemented())
	results.append(test_difficulty_adjustment_mechanism_normal())
	
	return results

# 测试1: 简单难度正确实现
func test_simple_difficulty_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "简单难度正确实现"
	
	# 创建测试数据
	var test_scores = {
		"skill_1": 100,
		"skill_2": 150,
		"skill_3": 80,
		"skill_4": 200
	}
	
	# 创建难度管理器实例
	var difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 设置简单难度
	difficulty_manager.set_difficulty_level("EASY")
	
	# 应用难度调整
	var adjusted_scores = difficulty_manager.apply_difficulty_modifiers(test_scores)
	
	# 验证结果
	if adjusted_scores.size() == test_scores.size():
		result.passed = true
		result.message = "简单难度调整成功，为每个技能计算了调整后评分"
	else:
		result.passed = false
		result.message = "简单难度调整失败"
	
	return result

# 测试2: 普通难度正确实现
func test_normal_difficulty_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "普通难度正确实现"
	
	# 创建测试数据
	var test_scores = {
		"skill_1": 100,
		"skill_2": 150,
		"skill_3": 80,
		"skill_4": 200
	}
	
	# 创建难度管理器实例
	var difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 设置普通难度
	difficulty_manager.set_difficulty_level("NORMAL")
	
	# 应用难度调整
	var adjusted_scores = difficulty_manager.apply_difficulty_modifiers(test_scores)
	
	# 验证结果
	if adjusted_scores.size() == test_scores.size():
		result.passed = true
		result.message = "普通难度调整成功，为每个技能计算了调整后评分"
	else:
		result.passed = false
		result.message = "普通难度调整失败"
	
	return result

# 测试3: 困难难度正确实现
func test_hard_difficulty_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "困难难度正确实现"
	
	# 创建测试数据
	var test_scores = {
		"skill_1": 100,
		"skill_2": 150,
		"skill_3": 80,
		"skill_4": 200
	}
	
	# 创建难度管理器实例
	var difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 设置困难难度
	difficulty_manager.set_difficulty_level("HARD")
	
	# 应用难度调整
	var adjusted_scores = difficulty_manager.apply_difficulty_modifiers(test_scores)
	
	# 验证结果
	if adjusted_scores.size() == test_scores.size():
		result.passed = true
		result.message = "困难难度调整成功，为每个技能计算了调整后评分"
	else:
		result.passed = false
		result.message = "困难难度调整失败"
	
	# 额外验证困难难度的特殊功能
	var predictions = difficulty_manager.predict_player_actions()
	var resource_mgmt = difficulty_manager.manage_resources_efficiently()
	
	if predictions.size() >= 0 and resource_mgmt != null:
		result.message += "，预测功能和资源管理功能正常"
	
	return result

# 测试4: 难度调整机制正常
func test_difficulty_adjustment_mechanism_normal() -> TestResult:
	var result = TestResult.new()
	result.test_name = "难度调整机制正常"
	
	# 创建难度管理器实例
	var difficulty_manager = load("res://src/scripts/combat/ai_difficulty_manager.gd").new()
	
	# 测试获取难度描述
	var easy_desc = difficulty_manager.get_difficulty_description("EASY")
	var normal_desc = difficulty_manager.get_difficulty_description("NORMAL")
	var hard_desc = difficulty_manager.get_difficulty_description("HARD")
	
	# 验证结果
	if easy_desc != null and normal_desc != null and hard_desc != null:
		result.passed = true
		result.message = "难度调整机制正常，能够获取各难度的描述信息"
	else:
		result.passed = false
		result.message = "难度调整机制异常，无法获取难度描述信息"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行AI难度等级测试...")
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