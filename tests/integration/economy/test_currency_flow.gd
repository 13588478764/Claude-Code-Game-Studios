## test_currency_flow.gd
## 货币流转集成测试
## S2-11: 验证货币获取、消费、余额更新及上限机制的完整流程
##
## 测试覆盖:
## 1. 货币获取 -> 消费 -> 余额更新完整流程
## 2. 货币不足时交易拒绝
## 3. 货币上限 enforced (add_currency 与 set_currency_amount)
## 4. 信号发出验证

extends GutTest

var CurrencyManager = load("res://src/scripts/economy/currency_manager.gd")

var currency_manager: CurrencyManager


func before_each() -> void:
	# 准备 - 创建新的货币管理器实例
	currency_manager = CurrencyManager.new()


func after_each() -> void:
	# 清理
	if currency_manager:
		currency_manager.queue_free()
		currency_manager = null


# 测试 1: 货币获取 -> 消费 -> 余额更新完整流程
func test_currency_flow_add_spend_balance_update() -> void:
	# 准备 - 添加银两到账户
	var silver_type: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.SILVER
	var add_amount: int = 1000
	currency_manager.add_currency(silver_type, add_amount)
	assert_eq(currency_manager.get_currency_amount(silver_type), add_amount, "添加货币后余额应等于添加量")

	# 执行 - 消费部分银两
	var spend_amount := 300
	var spend_result := currency_manager.spend_currency(silver_type, spend_amount)

	# 断言 - 消费成功且余额正确
	assert_true(spend_result, "消费操作应返回成功")
	assert_eq(
		currency_manager.get_currency_amount(silver_type),
		add_amount - spend_amount,
		"消费后余额应等于添加量减去消费量"
	)

	# 执行 - 继续消费剩余银两
	var remaining := currency_manager.get_currency_amount(silver_type)
	currency_manager.spend_currency(silver_type, remaining)

	# 断言 - 余额归零
	assert_eq(
		currency_manager.get_currency_amount(silver_type),
		0,
		"消费全部余额后余额应为零"
	)


# 测试 2: 货币不足时交易拒绝
func test_currency_flow_spend_insufficient_funds_rejected() -> void:
	# 准备 - 设置少量银两
	var silver_type: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.SILVER
	currency_manager.set_currency_amount(silver_type, 100)

	# 执行 - 尝试消费超出余额的数量
	var spend_result := currency_manager.spend_currency(silver_type, 200)

	# 断言 - 交易失败，余额不变
	assert_false(spend_result, "余额不足时消费应返回失败")
	assert_eq(
		currency_manager.get_currency_amount(silver_type),
		100,
		"消费失败后余额应保持不变"
	)

	# 执行 - has_enough_currency 检查
	var has_enough := currency_manager.has_enough_currency(silver_type, 200)
	assert_false(has_enough, "has_enough_currency 应返回 false")

	# 断言 - 边界值: 刚好等于余额应通过
	var has_exact := currency_manager.has_enough_currency(silver_type, 100)
	assert_true(has_exact, "余额刚好等于消费额时应返回 true")


# 测试 3: 货币上限 enforced (add_currency 封顶 + set_currency_amount 超限拒绝)
func test_currency_flow_cap_enforced() -> void:
	# --- 场景 3a: add_currency 超过上限时自动封顶 ---
	var silver_type: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.SILVER

	# 执行 - 添加超出上限的银两 (MAX_SILVER = 500000)
	var add_amount := 999999
	currency_manager.add_currency(silver_type, add_amount)

	# 断言 - add_currency 封顶到 MAX_SILVER
	assert_eq(
		currency_manager.get_currency_amount(silver_type),
		CurrencyManager.MAX_SILVER,
		"add_currency 超过上限时应封顶到 MAX_SILVER"
	)

	# --- 场景 3b: set_currency_amount 超过上限时返回失败 ---
	# 执行 - 尝试设置超出上限的银两
	var set_result := currency_manager.set_currency_amount(silver_type, 999999)

	# 断言 - set_currency_amount 返回失败 (不自动封顶，直接拒绝)
	assert_false(set_result, "set_currency_amount 超过上限时应返回失败")

	# --- 场景 3c: 材料类货币也有上限 (MAX_MATERIALS = 9999) ---
	var material_type: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.PRIMARY_MATERIAL
	currency_manager.add_multiple_currencies({material_type: 20000})

	# 断言 - 材料类封顶到 MAX_MATERIALS
	assert_eq(
		currency_manager.get_currency_amount(material_type),
		CurrencyManager.MAX_MATERIALS,
		"材料类货币应封顶到 MAX_MATERIALS"
	)

	# --- 场景 3d: 零和负数添加被拒绝 ---
	var zero_result := currency_manager.add_currency(silver_type, 0)
	var neg_result := currency_manager.add_currency(silver_type, -50)
	assert_false(zero_result, "添加零数量应返回失败")
	assert_false(neg_result, "添加负数应返回失败")

	# --- 场景 3e: 零和负数消费被拒绝 ---
	currency_manager.set_currency_amount(silver_type, 500)
	var spend_zero := currency_manager.spend_currency(silver_type, 0)
	var spend_neg := currency_manager.spend_currency(silver_type, -10)
	assert_false(spend_zero, "消费零数量应返回失败")
	assert_false(spend_neg, "消费负数应返回失败")


# 测试 4: 信号发出验证 (currency_changed 和 transaction_failed)
func test_currency_flow_signals_emitted() -> void:
	# 准备 - 监听信号
	var silver_type: CurrencyManager.CurrencyType = CurrencyManager.CurrencyType.SILVER
	currency_manager.add_currency(silver_type, 100)  # 先有一些余额用于后续测试

	# 注意：GDScript 4 的 lambda 对局部标量变量（int/String/bool）是按值捕获，
	# 在 lambda 内赋值不会反映到外部变量。因此必须用 Dictionary 包装状态。
	var change_state: Dictionary = {
		"count": 0,
		"type": -1,
		"old": -1,
		"new": -1,
	}

	var _on_currency_changed = func(type: int, old_amount: int, new_amount: int) -> void:
		change_state["count"] = int(change_state["count"]) + 1
		change_state["type"] = type
		change_state["old"] = old_amount
		change_state["new"] = new_amount

	currency_manager.currency_changed.connect(_on_currency_changed)

	var fail_state: Dictionary = {"count": 0, "reason": ""}

	var _on_transaction_failed = func(reason: String) -> void:
		fail_state["count"] = int(fail_state["count"]) + 1
		fail_state["reason"] = reason

	currency_manager.transaction_failed.connect(_on_transaction_failed)

	# 执行 - 添加货币触发 currency_changed
	currency_manager.add_currency(silver_type, 200)

	# 断言 - 信号被触发，参数正确
	assert_eq(change_state["count"], 1, "添加货币应触发一次 currency_changed 信号")
	assert_eq(change_state["type"], silver_type, "信号应包含正确的货币类型")
	assert_eq(change_state["old"], 100, "信号应包含正确的旧余额")
	assert_eq(change_state["new"], 300, "信号应包含正确的新余额")

	# 执行 - 消费货币触发 currency_changed
	currency_manager.spend_currency(silver_type, 50)
	assert_eq(change_state["count"], 2, "消费货币应再次触发 currency_changed 信号")
	assert_eq(change_state["old"], 300, "消费信号旧余额应为 300")
	assert_eq(change_state["new"], 250, "消费信号新余额应为 250")

	# 执行 - 余额不足触发 transaction_failed
	currency_manager.spend_currency(silver_type, 99999)
	assert_eq(fail_state["count"], 1, "余额不足应触发一次 transaction_failed 信号")
	assert_true("货币不足" in String(fail_state["reason"]), "失败原因应包含'货币不足'")

	# 执行 - 非法数量触发 transaction_failed
	currency_manager.add_currency(silver_type, -10)
	assert_eq(fail_state["count"], 2, "添加负数应触发第二次 transaction_failed 信号")
