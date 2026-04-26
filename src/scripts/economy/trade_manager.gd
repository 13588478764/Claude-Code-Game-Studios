# 武侠奇遇录 - 交易系统
# 实现商店购买、物品出售、拆解回收和交易验证功能

extends Node

# 信号定义
signal transaction_completed(transaction_type, item_id, quantity, cost)
signal transaction_failed(reason)
signal inventory_changed(item_id, old_quantity, new_quantity)

# 交易类型枚举
enum TransactionType {
	PURCHASE,    # 购买
	SELL,        # 出售
	DISASSEMBLE  # 拆解
}

# 依赖的其他系统
var currency_manager = null
var inventory_manager = null

func _ready():
	print("交易系统初始化完成")

# 初始化交易系统
func initialize(currency_mgr, inventory_mgr):
	currency_manager = currency_mgr
	inventory_manager = inventory_mgr
	print("交易系统已连接到货币和库存管理系统")

# 购买物品
func purchase_item(item_id: String, quantity: int, price_per_item: int) -> bool:
	if quantity <= 0:
		emit_signal("transaction_failed", "购买数量必须大于0")
		return false
	
	if price_per_item <= 0:
		emit_signal("transaction_failed", "物品价格必须大于0")
		return false
	
	var total_cost = price_per_item * quantity
	
	# 检查是否有足够货币
	if not currency_manager.has_enough_currency(currency_manager.CurrencyType.SILVER, total_cost):
		emit_signal("transaction_failed", "银两不足")
		return false
	
	# 检查库存空间
	if not inventory_manager.has_space_for_item(item_id, quantity):
		emit_signal("transaction_failed", "背包空间不足")
		return false
	
	# 执行交易
	if currency_manager.spend_currency(currency_manager.CurrencyType.SILVER, total_cost):
		var add_result = inventory_manager.add_item(item_id, quantity)
		if add_result:
			emit_signal("transaction_completed", TransactionType.PURCHASE, item_id, quantity, total_cost)
			return true
		else:
			# 如果添加物品失败，退还货币
			currency_manager.add_currency(currency_manager.CurrencyType.SILVER, total_cost)
			emit_signal("transaction_failed", "添加物品到背包失败")
			return false
	else:
		emit_signal("transaction_failed", "货币扣款失败")
		return false

# 出售物品
func sell_item(item_id: String, quantity: int) -> bool:
	if quantity <= 0:
		emit_signal("transaction_failed", "出售数量必须大于0")
		return false
	
	# 检查是否有足够物品
	if inventory_manager.get_item_quantity(item_id) < quantity:
		emit_signal("transaction_failed", "物品数量不足")
		return false
	
	# 获取物品基础价值并计算出售价格
	var item_base_value = get_item_base_value(item_id)
	if item_base_value <= 0:
		emit_signal("transaction_failed", "该物品不可出售")
		return false
	
	var sell_price_per_item = int(item_base_value * 0.5)  # 出售价格为基础价值的50%
	var total_revenue = sell_price_per_item * quantity
	
	# 执行交易
	var remove_result = inventory_manager.remove_item(item_id, quantity)
	if remove_result:
		var add_money_result = currency_manager.add_currency(currency_manager.CurrencyType.SILVER, total_revenue)
		if add_money_result:
			emit_signal("transaction_completed", TransactionType.SELL, item_id, quantity, -total_revenue)  # 负数表示收入
			return true
		else:
			# 如果添加货币失败，将物品还回背包
			inventory_manager.add_item(item_id, quantity)
			emit_signal("transaction_failed", "货币添加失败")
			return false
	else:
		emit_signal("transaction_failed", "从背包移除物品失败")
		return false

# 拆解物品
func disassemble_item(item_id: String) -> Dictionary:
	var result = {
		"success": false,
		"materials_gained": {},
		"silver_gained": 0,
		"message": ""
	}
	
	# 检查物品是否存在
	if inventory_manager.get_item_quantity(item_id) < 1:
		result.message = "物品不存在"
		emit_signal("transaction_failed", result.message)
		return result
	
	# 获取拆解产出
	var disassemble_output = get_disassemble_output(item_id)
	if disassemble_output.is_empty():
		result.message = "该物品不可拆解"
		emit_signal("transaction_failed", result.message)
		return result
	
	# 移除被拆解的物品
	var remove_result = inventory_manager.remove_item(item_id, 1)
	if not remove_result:
		result.message = "从背包移除物品失败"
		emit_signal("transaction_failed", result.message)
		return result
	
	# 添加拆解获得的材料
	for material_type in disassemble_output:
		var amount = disassemble_output[material_type]
		if material_type == "silver":
			currency_manager.add_currency(currency_manager.CurrencyType.SILVER, amount)
			result.silver_gained = amount
		else:
			# 假设其他材料是资源类型
			var currency_type = get_currency_type_from_string(material_type)
			if currency_type != null:
				currency_manager.add_currency(currency_type, amount)
			else:
				# 如果是物品类型，则添加到背包
				inventory_manager.add_item(material_type, amount)
			
			result.materials_gained[material_type] = amount
	
	result.success = true
	result.message = "拆解成功"
	emit_signal("transaction_completed", TransactionType.DISASSEMBLE, item_id, 1, result.materials_gained)
	return result

# 验证交易可行性
func validate_transaction(transaction_type: TransactionType, item_id: String, quantity: int, price_per_item: int = 0) -> Dictionary:
	var result = {
		"valid": false,
		"errors": [],
		"warnings": []
	}
	
	if quantity <= 0:
		result.errors.append("数量必须大于0")
		return result
	
	match transaction_type:
		TransactionType.PURCHASE:
			var total_cost = price_per_item * quantity
			if currency_manager.get_currency_amount(currency_manager.CurrencyType.SILVER) < total_cost:
				result.errors.append("银两不足")
			
			if not inventory_manager.has_space_for_item(item_id, quantity):
				result.errors.append("背包空间不足")
		
		TransactionType.SELL:
			if inventory_manager.get_item_quantity(item_id) < quantity:
				result.errors.append("物品数量不足")
			
			var item_base_value = get_item_base_value(item_id)
			if item_base_value <= 0:
				result.errors.append("该物品不可出售")
		
		TransactionType.DISASSEMBLE:
			if inventory_manager.get_item_quantity(item_id) < quantity:
				result.errors.append("物品数量不足")
			
			if get_disassemble_output(item_id).is_empty():
				result.errors.append("该物品不可拆解")
	
	result.valid = result.errors.is_empty()
	return result

# 获取物品基础价值
func get_item_base_value(item_id: String) -> int:
	# 这里应该从物品数据库获取实际的价值
	# 为了演示，我们使用一些默认值
	var default_values = {
		"sword_basic": 100,
		"sword_advanced": 500,
		"armor_basic": 150,
		"armor_advanced": 600,
		"potion_health_small": 50,
		"potion_health_large": 100,
		"material_primary": 20,
		"material_secondary": 50,
		"material_tertiary": 100,
		"pill_realm": 1000
	}
	
	return default_values.get(item_id, 0)

# 获取拆解产出
func get_disassemble_output(item_id: String) -> Dictionary:
	# 这里应该从物品数据库获取实际的拆解产出
	# 为了演示，我们使用一些默认产出
	var default_outputs = {
		"sword_basic": {"material_primary": 2, "silver": 30},
		"sword_advanced": {"material_secondary": 1, "material_primary": 3, "silver": 80},
		"armor_basic": {"material_primary": 3, "silver": 45},
		"armor_advanced": {"material_secondary": 2, "material_primary": 2, "silver": 120},
		"potion_health_small": {"material_primary": 1},
		"potion_health_large": {"material_secondary": 1}
	}
	
	return default_outputs.get(item_id, {})

# 获取货币类型从字符串
func get_currency_type_from_string(type_str: String):
	match type_str:
		"silver":
			return currency_manager.CurrencyType.SILVER
		"primary_material":
			return currency_manager.CurrencyType.PRIMARY_MATERIAL
		"secondary_material":
			return currency_manager.CurrencyType.SECONDARY_MATERIAL
		"tertiary_material":
			return currency_manager.CurrencyType.TERTIARY_MATERIAL
		"realm_pill":
			return currency_manager.CurrencyType.REALM_PILL
		_:
			return null

# 批量交易处理
func process_bulk_transaction(transactions: Array) -> Dictionary:
	var result = {
		"success_count": 0,
		"failure_count": 0,
		"results": []
	}
	
	for transaction in transactions:
		var trans_result = {}
		match transaction.type:
			"purchase":
				trans_result.success = purchase_item(transaction.item_id, transaction.quantity, transaction.price)
				trans_result.type = "purchase"
			"sell":
				trans_result.success = sell_item(transaction.item_id, transaction.quantity)
				trans_result.type = "sell"
			"disassemble":
				trans_result = disassemble_item(transaction.item_id)
				trans_result.type = "disassemble"
			_:
				trans_result.success = false
				trans_result.error = "未知的交易类型"
		
		if trans_result.success:
			result.success_count += 1
		else:
			result.failure_count += 1
		
		result.results.append(trans_result)
	
	return result

# 获取商店库存（示例）
func get_shop_inventory() -> Array:
	# 这里应该从商店数据库获取实际的库存
	# 为了演示，我们返回一些示例商品
	return [
		{"item_id": "potion_health_small", "name": "小还丹", "price": 50, "stock": 10},
		{"item_id": "material_primary", "name": "初级强化石", "price": 100, "stock": 5},
		{"item_id": "pill_realm", "name": "筑基丹", "price": 10000, "stock": 1}
	]

# 更新商店库存
func update_shop_stock(item_id: String, new_stock: int):
	# 这里应该更新商店数据库中的库存
	# 为了演示，我们只打印一条消息
	print("商店物品 %s 库存更新为 %d" % [item_id, new_stock])