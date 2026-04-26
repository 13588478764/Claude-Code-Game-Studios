# 货币管理系统单元测试
# 验证银两系统、核心资源管理、货币验证机制和货币变动事件处理

extends Node

# 加载货币管理系统
var CurrencyManager = load("res://src/scripts/economy/currency_manager.gd")

var currency_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始货币管理系统单元测试...")
	
	# 运行所有测试
	test_silver_system()
	test_core_resource_management()
	test_currency_validation()
	test_currency_change_events()
	
	# 输出测试结果
	print("\n=== 货币管理系统单元测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试银两系统
func test_silver_system():
	print("\n--- 测试银两系统 ---")
	
	currency_manager = CurrencyManager.new()
	
	# 测试初始银两为0
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	if initial_silver == 0:
		add_test_result("银两系统", true, "初始银两为0")
	else:
		add_test_result("银两系统", false, "初始银两不为0")
	
	# 测试添加银两
	var add_result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	if add_result:
		var silver_after_add = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
		if silver_after_add == 1000:
			add_test_result("银两系统", true, "添加银两成功")
		else:
			add_test_result("银两系统", false, "添加银两后数量不正确")
	else:
		add_test_result("银两系统", false, "添加银两失败")
	
	# 测试获得战斗掉落银两
	var drop_result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	if drop_result:
		var silver_after_drop = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
		if silver_after_drop == 1500:
			add_test_result("银两系统", true, "战斗掉落银两成功")
		else:
			add_test_result("银两系统", false, "战斗掉落银两后数量不正确")
	else:
		add_test_result("银两系统", false, "战斗掉落银两失败")

# 测试核心资源管理
func test_core_resource_management():
	print("\n--- 测试核心资源管理 ---")
	
	currency_manager = CurrencyManager.new()
	
	# 测试添加初级强化石
	var add_material_result = currency_manager.add_currency(currency_manager.CurrencyType.PRIMARY_MATERIAL, 1)
	if add_material_result:
		var material_count = currency_manager.get_currency_amount(currency_manager.CurrencyType.PRIMARY_MATERIAL)
		if material_count == 1:
			add_test_result("核心资源管理", true, "添加初级强化石成功")
		else:
			add_test_result("核心资源管理", false, "添加初级强化石后数量不正确")
	else:
		add_test_result("核心资源管理", false, "添加初级强化石失败")
	
	# 测试添加多个资源
	var multiple_add_result = currency_manager.add_multiple_currencies({
		currency_manager.CurrencyType.SECONDARY_MATERIAL: 2,
		currency_manager.CurrencyType.TERTIARY_MATERIAL: 1
	})
	if multiple_add_result:
		var secondary_count = currency_manager.get_currency_amount(currency_manager.CurrencyType.SECONDARY_MATERIAL)
		var tertiary_count = currency_manager.get_currency_amount(currency_manager.CurrencyType.TERTIARY_MATERIAL)
		if secondary_count == 2 and tertiary_count == 1:
			add_test_result("核心资源管理", true, "批量添加资源成功")
		else:
			add_test_result("核心资源管理", false, "批量添加资源后数量不正确")
	else:
		add_test_result("核心资源管理", false, "批量添加资源失败")

# 测试货币验证机制
func test_currency_validation():
	print("\n--- 测试货币验证机制 ---")
	
	currency_manager = CurrencyManager.new()
	
	# 先添加一些银两
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	
	# 测试消耗足够的银两
	var spend_result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 200)
	var silver_after_spend = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	if spend_result and silver_after_spend == 300:
		add_test_result("货币验证机制", true, "消耗足够银两成功")
	else:
		add_test_result("货币验证机制", false, "消耗足够银两失败")
	
	# 测试尝试消耗超过余额的银两
	var overspend_result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 800)  # 只有300
	var silver_after_overspend = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	if not overspend_result and silver_after_overspend == 300:  # 余额应该保持不变
		add_test_result("货币验证机制", true, "阻止超额消耗成功")
	else:
		add_test_result("货币验证机制", false, "未能阻止超额消耗")
	
	# 测试零值消耗
	var zero_spend_result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 0)
	if not zero_spend_result:
		add_test_result("货币验证机制", true, "阻止零值消耗成功")
	else:
		add_test_result("货币验证机制", false, "未能阻止零值消耗")

# 测试货币变动事件处理
func test_currency_change_events():
	print("\n--- 测试货币变动事件处理 ---")
	
	currency_manager = CurrencyManager.new()
	
	# 连接信号以捕获事件
	var event_caught = false
	var event_data = {}
	
	currency_manager.connect("currency_changed", Callable(self, "_on_currency_changed").bind(event_data))
	
	# 触发货币变动
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 100)
	
	# 检查事件是否被捕获
	if event_data.has("currency_type") and event_data["currency_type"] == currency_manager.CurrencyType.SILVER:
		add_test_result("货币变动事件处理", true, "货币变动事件成功触发")
	else:
		add_test_result("货币变动事件处理", false, "货币变动事件未触发")
	
	# 测试福缘修正计算
	var base_drop = 100
	var luck_stat = 50
	var calculated_drop = currency_manager.calculate_drop_with_luck(base_drop, luck_stat)
	var expected_drop = int(base_drop * (1 + luck_stat / 100.0))  # 100 * 1.5 = 150
	if calculated_drop == expected_drop:
		add_test_result("货币变动事件处理", true, "福缘修正计算正确")
	else:
		add_test_result("货币变动事件处理", false, "福缘修正计算错误，期望%d，实际%d" % [expected_drop, calculated_drop])

# 信号处理器
func _on_currency_changed(currency_type, old_amount, new_amount, event_data):
	event_data.currency_type = currency_type
	event_data.old_amount = old_amount
	event_data.new_amount = new_amount

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