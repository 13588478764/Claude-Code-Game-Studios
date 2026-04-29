extends GutTest

# 货币管理系统单元测试
# 验证银两系统、核心资源管理、货币验证机制和货币变动事件处理

var currency_manager

func before_each():
	# 创建一个 Node 实例并附加货币管理器脚本
	var node = Node.new()
	var script = load("res://src/scripts/economy/currency_manager.gd")
	node.set_script(script)
	currency_manager = node
	# 添加到场景树以便信号工作
	get_tree().root.add_child(currency_manager)

func after_each():
	# 清理
	if currency_manager and currency_manager.is_inside_tree():
		currency_manager.queue_free()

# AC-1: 银两系统正常工作
func test_silver_system_initial_value():
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(initial_silver, 0, "初始银两应为0")

func test_silver_system_add_currency():
	var result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	assert_true(result, "添加银两应该成功")
	var silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(silver, 1000, "添加1000银两后应该等于1000")

func test_silver_system_combat_drop():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	var result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	assert_true(result, "添加战斗掉落银两应该成功")
	var silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(silver, 1500, "添加500银两后应该等于1500")

func test_silver_system_zero_add():
	var result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 0)
	assert_false(result, "添加0银两应该失败")

func test_silver_system_negative_add():
	var result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, -100)
	assert_false(result, "添加负数银两应该失败")

# AC-2: 核心资源管理正确
func test_resource_management_add_material():
	var result = currency_manager.add_currency(currency_manager.CurrencyType.PRIMARY_MATERIAL, 1)
	assert_true(result, "添加初级强化石应该成功")
	var count = currency_manager.get_currency_amount(currency_manager.CurrencyType.PRIMARY_MATERIAL)
	assert_eq(count, 1, "添加1个初级强化石后应该等于1")

func test_resource_management_multiple_add():
	var result = currency_manager.add_multiple_currencies({
		currency_manager.CurrencyType.SECONDARY_MATERIAL: 2,
		currency_manager.CurrencyType.TERTIARY_MATERIAL: 1
	})
	assert_true(result, "批量添加资源应该成功")
	var secondary = currency_manager.get_currency_amount(currency_manager.CurrencyType.SECONDARY_MATERIAL)
	var tertiary = currency_manager.get_currency_amount(currency_manager.CurrencyType.TERTIARY_MATERIAL)
	assert_eq(secondary, 2, "添加2个次级材料后应该等于2")
	assert_eq(tertiary, 1, "添加1个三级材料后应该等于1")

func test_resource_management_stacking_limit():
	# 堆叠上限为9999，添加150应该成功但被限制在9999
	var result = currency_manager.add_currency(currency_manager.CurrencyType.PRIMARY_MATERIAL, 150)
	assert_true(result, "添加材料应该成功")
	var count = currency_manager.get_currency_amount(currency_manager.CurrencyType.PRIMARY_MATERIAL)
	assert_eq(count, 150, "添加150个材料后应该等于150")
	
	# 现在尝试添加超过上限的数量
	var result2 = currency_manager.add_currency(currency_manager.CurrencyType.PRIMARY_MATERIAL, 10000)
	assert_true(result2, "添加超过上限的材料应该成功但被限制")
	var count2 = currency_manager.get_currency_amount(currency_manager.CurrencyType.PRIMARY_MATERIAL)
	assert_eq(count2, 9999, "添加后应该被限制在9999")

# AC-3: 货币验证机制正常
func test_currency_validation_sufficient_spend():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 200)
	assert_true(result, "消耗足够的银两应该成功")
	var silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(silver, 300, "消耗200银两后应该等于300")

func test_currency_validation_insufficient_spend():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 800)
	assert_false(result, "消耗超过余额应该失败")
	var silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(silver, 500, "消耗失败后银两应该保持不变")

func test_currency_validation_exact_spend():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 500)
	assert_true(result, "消耗恰好等于余额应该成功")
	var silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	assert_eq(silver, 0, "消耗500银两后应该等于0")

func test_currency_validation_zero_spend():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, 0)
	assert_false(result, "消耗0银两应该失败")

func test_currency_validation_negative_spend():
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var result = currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, -100)
	assert_false(result, "消耗负数银两应该失败")

# AC-4: 货币变动事件处理正确
func test_currency_change_event_signal():
	var signal_emitted = false
	var signal_data = {}
	
	currency_manager.connect("currency_changed", Callable(self, "_on_currency_changed").bind(signal_data))
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 100)
	
	assert_true(signal_data.has("currency_type"), "应该发出currency_changed信号")
	assert_eq(signal_data.get("currency_type"), currency_manager.CurrencyType.SILVER, "信号应该包含正确的货币类型")

func test_fortune_modifier_calculation():
	var base_drop = 100
	var luck_stat = 50
	var calculated_drop = currency_manager.calculate_drop_with_luck(base_drop, luck_stat)
	var expected_drop = int(base_drop * (1 + luck_stat / 100.0))  # 100 * 1.5 = 150
	assert_eq(calculated_drop, expected_drop, "福缘修正计算应该正确")

func test_fortune_modifier_zero_luck():
	var base_drop = 100
	var luck_stat = 0
	var calculated_drop = currency_manager.calculate_drop_with_luck(base_drop, luck_stat)
	var expected_drop = 100  # 100 * 1.0 = 100
	assert_eq(calculated_drop, expected_drop, "福缘为0时应该返回基础掉落")

func test_fortune_modifier_max_luck():
	var base_drop = 100
	var luck_stat = 100
	var calculated_drop = currency_manager.calculate_drop_with_luck(base_drop, luck_stat)
	var expected_drop = 200  # 100 * 2.0 = 200
	assert_eq(calculated_drop, expected_drop, "福缘为100时应该返回2倍掉落")

func test_fortune_modifier_overflow():
	var base_drop = 100
	var luck_stat = 150
	var calculated_drop = currency_manager.calculate_drop_with_luck(base_drop, luck_stat)
	# 假设有上限，不应该超过某个值
	assert_true(calculated_drop > 0, "福缘修正后应该大于0")

# 信号处理器
func _on_currency_changed(currency_type, old_amount, new_amount, signal_data):
	signal_data.currency_type = currency_type
	signal_data.old_amount = old_amount
	signal_data.new_amount = new_amount