## CurrencyManager
## 经济系统模块
## 武侠奇遇录 - 货币管理系统
## 实现银两和核心资源的获取、消耗、验证和存储功能
##
## 主要功能：
## - 待补充

extends Node


# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

# 信号定义
signal currency_changed(currency_type, old_amount, new_amount)
signal transaction_failed(reason)

# 货币类型枚举
enum CurrencyType {
	SILVER,         # 银两
	PRIMARY_MATERIAL,   # 初级材料
	SECONDARY_MATERIAL, # 中级材料
	TERTIARY_MATERIAL,  # 高级材料
	REALM_PILL          # 突破丹
}

# 货币上限
const MAX_SILVER = 500000
const MAX_MATERIALS = 9999

# 存储玩家拥有的货币数量
var currencies = {
	CurrencyType.SILVER: 0,
	CurrencyType.PRIMARY_MATERIAL: 0,
	CurrencyType.SECONDARY_MATERIAL: 0,
	CurrencyType.TERTIARY_MATERIAL: 0,
	CurrencyType.REALM_PILL: 0
}

func _ready():
	print("货币管理系统初始化完成")

# 添加货币
func add_currency(currency_type: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		emit_signal("transaction_failed", "添加货币数量必须大于0")
		return false
	
	var old_amount = currencies[currency_type]
	var new_amount = old_amount + amount
	
	# 检查是否超过上限
	if currency_type == CurrencyType.SILVER:
		new_amount = min(new_amount, MAX_SILVER)
	elif currency_type in [CurrencyType.PRIMARY_MATERIAL, CurrencyType.SECONDARY_MATERIAL, CurrencyType.TERTIARY_MATERIAL, CurrencyType.REALM_PILL]:
		new_amount = min(new_amount, MAX_MATERIALS)
	
	currencies[currency_type] = new_amount
	
	# 发送货币变化信号
	emit_signal("currency_changed", currency_type, old_amount, new_amount)
	
	return true

# 消耗货币
func spend_currency(currency_type: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		emit_signal("transaction_failed", "消耗货币数量必须大于0")
		return false
	
	if not has_enough_currency(currency_type, amount):
		emit_signal("transaction_failed", "货币不足")
		return false
	
	var old_amount = currencies[currency_type]
	var new_amount = old_amount - amount
	currencies[currency_type] = new_amount
	
	# 发送货币变化信号
	emit_signal("currency_changed", currency_type, old_amount, new_amount)
	
	return true

# 检查是否有足够货币
func has_enough_currency(currency_type: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		return false
	
	return currencies[currency_type] >= amount

# 获取货币数量
func get_currency_amount(currency_type: CurrencyType) -> int:
	return currencies[currency_type]

# 设置货币数量
func set_currency_amount(currency_type: CurrencyType, amount: int) -> bool:
	if amount < 0:
		emit_signal("transaction_failed", "货币数量不能为负数")
		return false
	
	var max_limit = 0
	if currency_type == CurrencyType.SILVER:
		max_limit = MAX_SILVER
	else:
		max_limit = MAX_MATERIALS
	
	if amount > max_limit:
		emit_signal("transaction_failed", "货币数量超过上限")
		return false
	
	var old_amount = currencies[currency_type]
	currencies[currency_type] = amount
	
	# 发送货币变化信号
	emit_signal("currency_changed", currency_type, old_amount, amount)
	
	return true

# 根据福缘计算掉落修正
func calculate_drop_with_luck(base_amount: int, luck_stat: int) -> int:
	# 使用GDD中的公式：最终掉落 = 基础掉落 × (1 + 福缘/100)
	var multiplier = 1.0 + (float(luck_stat) / 100.0)
	var calculated_amount = int(float(base_amount) * multiplier)
	
	# 检查是否超过银两上限
	if currencies[CurrencyType.SILVER] + calculated_amount > MAX_SILVER:
		calculated_amount = MAX_SILVER - currencies[CurrencyType.SILVER]
		if calculated_amount < 0:
			calculated_amount = 0
	
	return calculated_amount

# 批量添加多种货币
func add_multiple_currencies(currency_dict: Dictionary) -> bool:
	var success = true
	var temp_changes = {}
	
	# 首先验证所有更改是否会超出限制
	for currency_type in currency_dict:
		var amount_to_add = currency_dict[currency_type]
		if amount_to_add <= 0:
			continue
		
		var new_amount = currencies[currency_type] + amount_to_add
		var max_limit = 0
		
		if currency_type == CurrencyType.SILVER:
			max_limit = MAX_SILVER
		else:
			max_limit = MAX_MATERIALS
		
		if new_amount > max_limit:
			new_amount = max_limit
		
		temp_changes[currency_type] = new_amount
	
	# 应用所有更改
	for currency_type in temp_changes:
		var old_amount = currencies[currency_type]
		var new_amount = temp_changes[currency_type]
		currencies[currency_type] = new_amount
		
		# 发送货币变化信号
		emit_signal("currency_changed", currency_type, old_amount, new_amount)
	
	return success

# 批量消耗多种货币
func spend_multiple_currencies(currency_dict: Dictionary) -> bool:
	# 首先验证是否有足够货币
	for currency_type in currency_dict:
		var amount_to_spend = currency_dict[currency_type]
		if amount_to_spend <= 0:
			continue
		
		if not has_enough_currency(currency_type, amount_to_spend):
			emit_signal("transaction_failed", "货币类型 %d 数量不足" % currency_type)
			return false
	
	# 执行消耗
	for currency_type in currency_dict:
		var amount_to_spend = currency_dict[currency_type]
		if amount_to_spend <= 0:
			continue
		
		var old_amount = currencies[currency_type]
		var new_amount = old_amount - amount_to_spend
		currencies[currency_type] = new_amount
		
		# 发送货币变化信号
		emit_signal("currency_changed", currency_type, old_amount, new_amount)
	
	return true

# 获取货币类型名称
func get_currency_name(currency_type: CurrencyType) -> String:
	match currency_type:
		CurrencyType.SILVER:
			return "银两"
		CurrencyType.PRIMARY_MATERIAL:
			return "初级材料"
		CurrencyType.SECONDARY_MATERIAL:
			return "中级材料"
		CurrencyType.TERTIARY_MATERIAL:
			return "高级材料"
		CurrencyType.REALM_PILL:
			return "突破丹"
		_:
			return "未知货币"

# 重置所有货币为0
func reset_all_currencies():
	for currency_type in currencies:
		var old_amount = currencies[currency_type]
		if old_amount != 0:
			currencies[currency_type] = 0
			emit_signal("currency_changed", currency_type, old_amount, 0)

# 保存货币数据
func save_currency_data() -> Dictionary:
	var save_data = {}
	for currency_type in currencies:
		save_data[str(currency_type)] = currencies[currency_type]
	return save_data

# 加载货币数据
func load_currency_data(save_data: Dictionary):
	reset_all_currencies()
	
	for currency_type_str in save_data:
		var currency_type = int(currency_type_str)
		var amount = save_data[currency_type_str]
		if currencies.has(currency_type):
			currencies[currency_type] = amount
			emit_signal("currency_changed", currency_type, 0, amount)