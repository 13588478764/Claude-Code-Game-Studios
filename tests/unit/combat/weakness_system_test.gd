# 弱点系统单元测试
# 验证属性克制、弱点打击判定、击倒机制和总攻击触发等功能

extends Node

# 加载弱点系统
var WeaknessSystem = load("res://src/scripts/combat/weakness_system.gd")

var weakness_system
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始弱点系统单元测试...")
	
	# 运行所有测试
	test_elemental_weakness_system()
	test_weakness_hit_detection()
	test_knock_down_mechanism()
	test_all_out_attack_condition()
	
	# 输出测试结果
	print("\n=== 弱点系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试属性克制系统
func test_elemental_weakness_system():
	print("\n--- 测试属性克制系统 ---")
	
	weakness_system = WeaknessSystem.new()
	
	# 测试金克木
	var is_weakness = weakness_system.check_elemental_weakness(weakness_system.ElementType.METAL, weakness_system.ElementType.WOOD)
	if is_weakness:
		add_test_result("属性克制系统", true, "金克木关系正确")
	else:
		add_test_result("属性克制系统", false, "金克木关系错误")
	
	# 测试火克金
	is_weakness = weakness_system.check_elemental_weakness(weakness_system.ElementType.FIRE, weakness_system.ElementType.METAL)
	if is_weakness:
		add_test_result("属性克制系统", true, "火克金关系正确")
	else:
		add_test_result("属性克制系统", false, "火克金关系错误")
	
	# 测试无克制关系
	is_weakness = weakness_system.check_elemental_weakness(weakness_system.ElementType.FIRE, weakness_system.ElementType.FIRE)
	if not is_weakness:
		add_test_result("属性克制系统", true, "相同属性无克制关系正确")
	else:
		add_test_result("属性克制系统", false, "相同属性不应有克制关系")

# 测试弱点打击判定
func test_weakness_hit_detection():
	print("\n--- 测试弱点打击判定 ---")
	
	weakness_system = WeaknessSystem.new()
	
	# 创建测试目标
	var test_target = {
		"name": "测试敌人",
		"current_hp": 100,
		"is_enemy": true,
		"status": weakness_system.BattleStatus.NORMAL
	}
	
	# 测试克制属性攻击
	var result = weakness_system.process_weakness_hit(null, test_target, weakness_system.ElementType.METAL, weakness_system.ElementType.WOOD)
	if result.is_weakness_hit:
		add_test_result("弱点打击判定", true, "克制属性攻击弱点判定正确")
	else:
		add_test_result("弱点打击判定", false, "克制属性攻击弱点判定错误")
	
	# 测试非克制属性攻击
	result = weakness_system.process_weakness_hit(null, test_target, weakness_system.ElementType.FIRE, weakness_system.ElementType.WOOD)
	if not result.is_weakness_hit:
		add_test_result("弱点打击判定", true, "非克制属性攻击弱点判定正确")
	else:
		add_test_result("弱点打击判定", false, "非克制属性攻击弱点判定错误")

# 测试击倒机制
func test_knock_down_mechanism():
	print("\n--- 测试击倒机制 ---")
	
	weakness_system = WeaknessSystem.new()
	
	# 创建测试目标
	var test_target = {
		"name": "测试敌人",
		"current_hp": 100,
		"is_enemy": true,
		"status": weakness_system.BattleStatus.NORMAL
	}
	
	# 应用击倒效果
	var knock_down_result = weakness_system.apply_knock_down_effect(test_target)
	if knock_down_result:
		# 检查目标状态是否变为DOWN
		if test_target.status == weakness_system.BattleStatus.DOWN:
			add_test_result("击倒机制", true, "击倒机制正常工作")
		else:
			add_test_result("击倒机制", false, "目标状态未正确设置为DOWN")
	else:
		add_test_result("击倒机制", false, "击倒效果应用失败")

# 测试总攻击触发条件
func test_all_out_attack_condition():
	print("\n--- 测试总攻击触发条件 ---")
	
	weakness_system = WeaknessSystem.new()
	
	# 创建测试目标数组 - 所有敌人都处于Down状态
	var test_targets_all_down = [
		{"name": "敌人1", "is_enemy": true, "status": weakness_system.BattleStatus.DOWN},
		{"name": "敌人2", "is_enemy": true, "status": weakness_system.BattleStatus.DOWN}
	]
	
	# 检查总攻击条件
	var all_out_available = weakness_system.check_all_out_attack_condition(test_targets_all_down)
	if all_out_available:
		add_test_result("总攻击触发条件", true, "所有敌人都Down时总攻击条件正确")
	else:
		add_test_result("总攻击触发条件", false, "所有敌人都Down时总攻击条件错误")
	
	# 创建测试目标数组 - 有一个敌人未处于Down状态
	var test_targets_partial_down = [
		{"name": "敌人1", "is_enemy": true, "status": weakness_system.BattleStatus.DOWN},
		{"name": "敌人2", "is_enemy": true, "status": weakness_system.BattleStatus.NORMAL}
	]
	
	# 检查总攻击条件
	all_out_available = weakness_system.check_all_out_attack_condition(test_targets_partial_down)
	if not all_out_available:
		add_test_result("总攻击触发条件", true, "部分敌人Down时总攻击条件正确")
	else:
		add_test_result("总攻击触发条件", false, "部分敌人Down时总攻击条件错误")

# 辅助函数：添加测试结果
func add_test_result(test_name: String, passed: bool, message: String):
	test_result.total += 1
	if passed:
		test_result.passed += 1
		print("✅ %s: %s" % [test_name, message])
	else:
		test_result.failed += 1
		print("❌ %s: %s" % [test_name, message])
	
	test_result.details.append("%s: %s" % [test_name, "通过" if passed else "失败 - " + message])