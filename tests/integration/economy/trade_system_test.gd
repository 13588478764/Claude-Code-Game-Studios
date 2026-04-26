# 交易系统集成测试
# 验证商店购买、物品出售、拆解回收和交易验证功能

extends Node

# 加载交易系统和依赖
var TradeManager = load("res://src/scripts/economy/trade_manager.gd")
var CurrencyManager = load("res://src/scripts/economy/currency_manager.gd")

# 模拟库存管理器
class MockInventoryManager:
	var items = {}
	
	func has_space_for_item(item_id: String, quantity: int) -> bool:
		# 简单模拟，假设总是有空间
		return true
	
	func add_item(item_id: String, quantity: int) -> bool:
		if not items.has(item_id):
			items[item_id] = 0
		items[item_id] += quantity
		return true
	
	func remove_item(item_id: String, quantity: int) -> bool:
		if not items.has(item_id) or items[item_id] < quantity:
			return false
		items[item_id] -= quantity
		if items[item_id] <= 0:
			items.erase(item_id)
		return true
	
	func get_item_quantity(item_id: String) -> int:
		return items.get(item_id, 0)

var trade_manager
var currency_manager
var inventory_manager
var test_result = {
	"passed": 0,
	"failed": 0,
	"total": 0,
	"details": []
}

func _ready():
	print("开始交易系统集成测试...")
	
	# 初始化系统
	currency_manager = CurrencyManager.new()
	inventory_manager = MockInventoryManager.new()
	trade_manager = TradeManager.new()
	trade_manager.initialize(currency_manager, inventory_manager)
	
	# 运行所有测试
	test_store_purchase_functionality()
	test_item_sell_functionality()
	test_transaction_validation_mechanism()
	test_transaction_history_recording()
	
	# 输出测试结果
	print("\n=== 交易系统集成测试结果 ===")
	print("通过: %d" % test_result.passed)
	print("失败: %d" % test_result.failed)
	print("总计: %d" % test_result.total)
	
	if test_result.failed == 0:
		print("✅ 所有测试通过！")
	else:
		print("❌ 有 %d 个测试失败" % test_result.failed)
	
	for detail in test_result.details:
		print(detail)

# 测试商店购买功能
func test_store_purchase_functionality():
	print("\n--- 测试商店购买功能 ---")
	
	# 给玩家一些银两
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	
	# 测试购买物品
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var initial_item_count = inventory_manager.get_item_quantity("potion_health_small")
	
	var purchase_result = trade_manager.purchase_item("potion_health_small", 3, 50)  # 3个生命药水，单价50银两
	
	var final_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var final_item_count = inventory_manager.get_item_quantity("potion_health_small")
	
	if purchase_result and final_silver == initial_silver - 150 and final_item_count == initial_item_count + 3:
		add_test_result("商店购买功能", true, "购买物品成功")
	else:
		add_test_result("商店购买功能", false, "购买物品失败")
	
	# 测试余额不足的情况
	var insufficient_funds_result = trade_manager.purchase_item("potion_health_large", 10, 1000)  # 需要10000银两，但只有850
	if not insufficient_funds_result:
		add_test_result("商店购买功能", true, "正确阻止余额不足的购买")
	else:
		add_test_result("商店购买功能", false, "未能阻止余额不足的购买")

# 测试物品出售功能
func test_item_sell_functionality():
	print("\n--- 测试物品出售功能 ---")
	
	# 先给玩家一些物品
	inventory_manager.add_item("sword_basic", 1)
	
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var initial_item_count = inventory_manager.get_item_quantity("sword_basic")
	
	# 测试出售物品
	var sell_result = trade_manager.sell_item("sword_basic", 1)
	
	var final_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var final_item_count = inventory_manager.get_item_quantity("sword_basic")
	
	# sword_basic的基础价值是100，出售价格是50% = 50银两
	if sell_result and final_silver == initial_silver + 50 and final_item_count == initial_item_count - 1:
		add_test_result("物品出售功能", true, "出售物品成功")
	else:
		add_test_result("物品出售功能", false, "出售物品失败")
	
	# 测试出售不存在的物品
	var nonexistent_sell_result = trade_manager.sell_item("nonexistent_item", 1)
	if not nonexistent_sell_result:
		add_test_result("物品出售功能", true, "正确阻止出售不存在的物品")
	else:
		add_test_result("物品出售功能", false, "未能阻止出售不存在的物品")

# 测试交易验证机制
func test_transaction_validation_mechanism():
	print("\n--- 测试交易验证机制 ---")
	
	# 测试购买验证
	var purchase_validation = trade_manager.validate_transaction(trade_manager.TransactionType.PURCHASE, "potion_health_small", 2, 50)
	if purchase_validation.valid:
		add_test_result("交易验证机制", true, "购买验证通过")
	else:
		add_test_result("交易验证机制", false, "购买验证失败")
	
	# 测试余额不足的购买验证
	var currency_before = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, currency_before)  # 花光所有银两
	var insufficient_validation = trade_manager.validate_transaction(trade_manager.TransactionType.PURCHASE, "potion_health_small", 1, 50)
	if not insufficient_validation.valid and "银两不足" in insufficient_validation.errors:
		add_test_result("交易验证机制", true, "正确验证余额不足")
	else:
		add_test_result("交易验证机制", false, "未能正确验证余额不足")
	
	# 测试出售验证
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)  # 重新添加一些银两
	inventory_manager.add_item("armor_basic", 1)
	var sell_validation = trade_manager.validate_transaction(trade_manager.TransactionType.SELL, "armor_basic", 1, 0)
	if sell_validation.valid:
		add_test_result("交易验证机制", true, "出售验证通过")
	else:
		add_test_result("交易验证机制", false, "出售验证失败")

# 测试交易历史记录
func test_transaction_history_recording():
	print("\n--- 测试交易历史记录 ---")
	
	# 连接交易完成信号
	var transaction_recorded = false
	var transaction_data = {}
	
	trade_manager.connect("transaction_completed", Callable(self, "_on_transaction_completed").bind(transaction_data))
	
	# 执行一个交易
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var purchase_result = trade_manager.purchase_item("material_primary", 2, 100)
	
	# 检查是否记录了交易
	if transaction_data.has("item_id") and transaction_data.item_id == "material_primary":
		add_test_result("交易历史记录", true, "交易历史记录功能正常")
		transaction_recorded = true
	else:
		add_test_result("交易历史记录", false, "交易历史记录功能异常")
	
	# 测试拆解功能
	inventory_manager.add_item("sword_basic", 1)
	var disassemble_result = trade_manager.disassemble_item("sword_basic")
	if disassemble_result.success:
		add_test_result("交易历史记录", true, "拆解功能正常")
	else:
		add_test_result("交易历史记录", false, "拆解功能异常")

# 信号处理器
func _on_transaction_completed(transaction_type, item_id, quantity, cost, transaction_data):
	transaction_data.transaction_type = transaction_type
	transaction_data.item_id = item_id
	transaction_data.quantity = quantity
	transaction_data.cost = cost

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