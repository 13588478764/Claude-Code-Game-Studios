extends GutTest

# 加载交易系统和依赖
var TradeManager = load("res://src/scripts/economy/trade_manager.gd")
var CurrencyManager = load("res://src/scripts/economy/currency_manager.gd")

# 模拟库存管理器
class MockInventoryManager:
	var items = {}
	
	func has_space_for_item(item_id: String, quantity: int) -> bool:
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

func before_each():
	# 初始化系统
	currency_manager = CurrencyManager.new()
	inventory_manager = MockInventoryManager.new()
	trade_manager = TradeManager.new()
	trade_manager.initialize(currency_manager, inventory_manager)

func after_each():
	# 清理
	if trade_manager:
		trade_manager.queue_free()
	if currency_manager:
		currency_manager.queue_free()

# 测试商店购买功能
func test_store_purchase_functionality():
	# 给玩家一些银两
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	
	# 测试购买物品
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var initial_item_count = inventory_manager.get_item_quantity("potion_health_small")
	
	var purchase_result = trade_manager.purchase_item("potion_health_small", 3, 50)
	
	var final_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var final_item_count = inventory_manager.get_item_quantity("potion_health_small")
	
	assert_true(purchase_result, "购买应该成功")
	assert_eq(final_silver, initial_silver - 150, "银两应该减少150")
	assert_eq(final_item_count, initial_item_count + 3, "物品数量应该增加3")
	
	# 测试余额不足的情况
	var insufficient_funds_result = trade_manager.purchase_item("potion_health_large", 10, 1000)
	assert_false(insufficient_funds_result, "余额不足时购买应该失败")

# 测试物品出售功能
func test_item_sell_functionality():
	# 先给玩家一些物品
	inventory_manager.add_item("sword_basic", 1)
	
	var initial_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var initial_item_count = inventory_manager.get_item_quantity("sword_basic")
	
	# 测试出售物品
	var sell_result = trade_manager.sell_item("sword_basic", 1)
	
	var final_silver = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	var final_item_count = inventory_manager.get_item_quantity("sword_basic")
	
	assert_true(sell_result, "出售应该成功")
	assert_eq(final_silver, initial_silver + 50, "银两应该增加50")
	assert_eq(final_item_count, initial_item_count - 1, "物品数量应该减少1")
	
	# 测试出售不存在的物品
	var nonexistent_sell_result = trade_manager.sell_item("nonexistent_item", 1)
	assert_false(nonexistent_sell_result, "出售不存在的物品应该失败")

# 测试交易验证机制
func test_transaction_validation_mechanism():
	# 给玩家一些银两
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	
	# 测试购买验证
	var purchase_validation = trade_manager.validate_transaction(trade_manager.TransactionType.PURCHASE, "potion_health_small", 2, 50)
	assert_true(purchase_validation.valid, "购买验证应该通过")
	
	# 测试余额不足的购买验证
	var currency_before = currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER)
	currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, currency_before)
	var insufficient_validation = trade_manager.validate_transaction(trade_manager.TransactionType.PURCHASE, "potion_health_small", 1, 50)
	assert_false(insufficient_validation.valid, "余额不足时验证应该失败")
	assert_true("银两不足" in insufficient_validation.errors, "应该包含银两不足错误")
	
	# 测试出售验证
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 1000)
	inventory_manager.add_item("armor_basic", 1)
	var sell_validation = trade_manager.validate_transaction(trade_manager.TransactionType.SELL, "armor_basic", 1, 0)
	assert_true(sell_validation.valid, "出售验证应该通过")

# 测试交易历史记录
func test_transaction_history_recording():
	# 执行一个交易
	currency_manager.add_currency(currency_manager.CurrencyType.SILVER, 500)
	var purchase_result = trade_manager.purchase_item("material_primary", 2, 100)
	
	assert_true(purchase_result, "购买应该成功")
	
	# 测试拆解功能
	inventory_manager.add_item("sword_basic", 1)
	var disassemble_result = trade_manager.disassemble_item("sword_basic")
	
	assert_true(disassemble_result.success, "拆解应该成功")
	assert_true(disassemble_result.materials_gained.has("material_primary"), "应该获得初级材料")