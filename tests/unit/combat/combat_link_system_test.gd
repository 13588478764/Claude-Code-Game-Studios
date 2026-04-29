# 武侠奇遇录 - 连携系统单元测试
# 测试连携槽系统、连击系统、连携攻击和连携条件判定

extends "res://addons/gut/test.gd"

# 测试变量
var link_system = null
var combat_system = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 创建战斗系统和连携系统实例
	combat_system = preload("res://src/scripts/combat/combat_system.gd").new()
	combat_system.initialize()
	
	link_system = preload("res://src/scripts/combat/link_system.gd").new()
	link_system.initialize(combat_system)

func after_each():
	"""在每个测试之后运行"""
	link_system = null
	combat_system = null

# ============================================================================
# AC-1: 连携槽系统正常工作（队友间共享积累）
# ============================================================================

func test_link_gauge_initial_empty():
	"""AC-1: 验证连携槽初始为空"""
	# Given: 战斗开始
	# When: 检查连携槽
	var current = link_system.get_link_gauge_current()
	var max_val = link_system.get_link_gauge_max()
	
	# Then: 连携槽应该为空
	assert_almost_eq(current, 0.0, 0.01, "连携槽初始应该为 0")
	assert_almost_eq(max_val, 100.0, 0.01, "连携槽最大值应该是 100")

func test_link_gauge_accumulation():
	"""AC-1: 验证连携槽积累"""
	# Given: 战斗开始，连携槽为空
	# When: 积累连携槽
	link_system.accumulate_link_gauge(30.0)
	
	# Then: 连携槽应该增加
	var current = link_system.get_link_gauge_current()
	assert_almost_eq(current, 30.0, 0.01, "连携槽应该积累到 30")

func test_link_gauge_max_limit():
	"""AC-1: 验证连携槽不超过最大值"""
	# Given: 战斗开始
	# When: 积累超过最大值的连携槽
	link_system.accumulate_link_gauge(80.0)
	link_system.accumulate_link_gauge(50.0)
	
	# Then: 连携槽应该被限制在最大值
	var current = link_system.get_link_gauge_current()
	assert_almost_eq(current, 100.0, 0.01, "连携槽应该被限制在 100")

func test_link_gauge_full_check():
	"""AC-1: 验证连携槽满的检查"""
	# Given: 连携槽为空
	assert_false(link_system.is_link_gauge_full(), "初始连携槽不应该满")
	
	# When: 积累到满
	link_system.accumulate_link_gauge(100.0)
	
	# Then: 连携槽应该满
	assert_true(link_system.is_link_gauge_full(), "连携槽应该满")

func test_link_gauge_consumption():
	"""AC-1: 验证连携槽消耗"""
	# Given: 连携槽有 50 点
	link_system.accumulate_link_gauge(50.0)
	
	# When: 消耗 30 点
	var success = link_system.link_gauge.consume(30.0)
	
	# Then: 消耗应该成功，剩余 20 点
	assert_true(success, "消耗应该成功")
	assert_almost_eq(link_system.get_link_gauge_current(), 20.0, 0.01, "剩余应该是 20")

func test_link_gauge_insufficient_consumption():
	"""AC-1: 验证连携槽不足时消耗失败"""
	# Given: 连携槽有 20 点
	link_system.accumulate_link_gauge(20.0)
	
	# When: 尝试消耗 50 点
	var success = link_system.link_gauge.consume(50.0)
	
	# Then: 消耗应该失败
	assert_false(success, "消耗应该失败")
	assert_almost_eq(link_system.get_link_gauge_current(), 20.0, 0.01, "连携槽应该不变")

# ============================================================================
# AC-2: 连击系统正常（同一角色连续命中敌人）
# ============================================================================

func test_combo_initial_zero():
	"""AC-2: 验证连击数初始为 0"""
	# Given: 战斗开始
	# When: 检查连击数
	var combo = link_system.get_combo_count()
	
	# Then: 连击数应该为 0
	assert_eq(combo, 0, "连击数初始应该是 0")

func test_combo_increment():
	"""AC-2: 验证连击数递增"""
	# Given: 战斗开始
	var target = Node.new()
	
	# When: 连续命中同一目标
	link_system.record_hit(target)
	link_system.record_hit(target)
	link_system.record_hit(target)
	
	# Then: 连击数应该递增
	assert_eq(link_system.get_combo_count(), 3, "连击数应该是 3")

func test_combo_damage_multiplier():
	"""AC-2: 验证连击伤害倍率"""
	# Given: 战斗开始
	var target = Node.new()
	
	# When: 连续命中 5 次
	for i in range(5):
		link_system.record_hit(target)
	
	# Then: 伤害倍率应该是 1.4（1.0 + (5-1)*0.1）
	var multiplier = link_system.get_combo_damage_multiplier()
	assert_almost_eq(multiplier, 1.4, 0.01, "伤害倍率应该是 1.4")

func test_combo_reset_on_target_change():
	"""AC-2: 验证切换目标时连击重置"""
	# Given: 对目标 A 连击 3 次
	var target_a = Node.new()
	var target_b = Node.new()
	
	link_system.record_hit(target_a)
	link_system.record_hit(target_a)
	link_system.record_hit(target_a)
	assert_eq(link_system.get_combo_count(), 3, "对 A 的连击数应该是 3")
	
	# When: 切换到目标 B
	link_system.record_hit(target_b)
	
	# Then: 连击数应该重置为 1
	assert_eq(link_system.get_combo_count(), 1, "对 B 的连击数应该是 1")

func test_combo_max_limit():
	"""AC-2: 验证连击数不超过最大值"""
	# Given: 战斗开始
	var target = Node.new()
	
	# When: 连续命中 15 次（超过最大值 10）
	for i in range(15):
		link_system.record_hit(target)
	
	# Then: 连击数应该被限制在 10
	assert_eq(link_system.get_combo_count(), 10, "连击数应该被限制在 10")

func test_combo_reset_manual():
	"""AC-2: 验证手动重置连击"""
	# Given: 连击数为 5
	var target = Node.new()
	for i in range(5):
		link_system.record_hit(target)
	
	# When: 手动重置
	link_system.reset_combo()
	
	# Then: 连击数应该重置为 0
	assert_eq(link_system.get_combo_count(), 0, "连击数应该重置为 0")

# ============================================================================
# AC-3: 连携攻击实现（追击和合体技）
# ============================================================================

func test_link_attack_insufficient_gauge():
	"""AC-3: 验证连携槽不足时攻击失败"""
	# Given: 连携槽只有 30 点，连击数为 3
	link_system.accumulate_link_gauge(30.0)
	var target = Node.new()
	link_system.record_hit(target)
	link_system.record_hit(target)
	link_system.record_hit(target)
	
	# When: 尝试执行追击（需要 50 点）
	var success = link_system.execute_link_attack("追击")
	
	# Then: 执行应该失败
	assert_false(success, "追击执行应该失败")

func test_link_attack_insufficient_combo():
	"""AC-3: 验证连击数不足时攻击失败"""
	# Given: 连携槽有 50 点，但连击数只有 1
	link_system.accumulate_link_gauge(50.0)
	var target = Node.new()
	link_system.record_hit(target)
	
	# When: 尝试执行追击（需要 3 连击）
	var success = link_system.execute_link_attack("追击")
	
	# Then: 执行应该失败
	assert_false(success, "追击执行应该失败")

# ============================================================================
# AC-4: 连携条件判定正确（消耗连携槽，满足触发条件）
# ============================================================================

func test_link_condition_check_pass():
	"""AC-4: 验证连携条件满足"""
	# Given: 创建条件（需要 50 连携槽，3 连击，1 队友）
	var condition = link_system.LinkCondition.new(50.0, 3, 1)
	
	# When: 检查条件（有 50 连携槽，3 连击，1 队友）
	var result = condition.check(50.0, 3, 1)
	
	# Then: 条件应该满足
	assert_true(result, "条件应该满足")

func test_link_condition_check_fail_gauge():
	"""AC-4: 验证连携槽不足时条件不满足"""
	# Given: 创建条件（需要 50 连携槽）
	var condition = link_system.LinkCondition.new(50.0, 0, 1)
	
	# When: 检查条件（只有 30 连携槽）
	var result = condition.check(30.0, 0, 1)
	
	# Then: 条件应该不满足
	assert_false(result, "条件应该不满足")

func test_link_condition_check_fail_combo():
	"""AC-4: 验证连击数不足时条件不满足"""
	# Given: 创建条件（需要 3 连击）
	var condition = link_system.LinkCondition.new(0.0, 3, 1)
	
	# When: 检查条件（只有 1 连击）
	var result = condition.check(0.0, 1, 1)
	
	# Then: 条件应该不满足
	assert_false(result, "条件应该不满足")

func test_link_condition_check_fail_teammates():
	"""AC-4: 验证队友数不足时条件不满足"""
	# Given: 创建条件（需要 2 队友）
	var condition = link_system.LinkCondition.new(0.0, 0, 2)
	
	# When: 检查条件（只有 1 队友）
	var result = condition.check(0.0, 0, 1)
	
	# Then: 条件应该不满足
	assert_false(result, "条件应该不满足")

func test_link_condition_multiple_conditions():
	"""AC-4: 验证多条件组合"""
	# Given: 创建条件（需要 50 连携槽，3 连击，2 队友）
	var condition = link_system.LinkCondition.new(50.0, 3, 2)
	
	# When: 检查条件（有 50 连携槽，3 连击，2 队友）
	var result = condition.check(50.0, 3, 2)
	
	# Then: 条件应该满足
	assert_true(result, "条件应该满足")

func test_link_gauge_accumulation_on_hit():
	"""AC-1: 验证命中时自动积累连携槽"""
	# Given: 战斗开始，连携槽为空
	assert_almost_eq(link_system.get_link_gauge_current(), 0.0, 0.01, "初始连携槽应该为 0")
	
	# When: 记录一次命中
	var target = Node.new()
	link_system.record_hit(target)
	
	# Then: 连携槽应该积累 10 点
	assert_almost_eq(link_system.get_link_gauge_current(), 10.0, 0.01, "连携槽应该积累 10")

func test_combo_and_gauge_integration():
	"""AC-2 和 AC-1: 验证连击和连携槽的集成"""
	# Given: 战斗开始
	var target = Node.new()
	
	# When: 连续命中 5 次
	for i in range(5):
		link_system.record_hit(target)
	
	# Then: 连击数应该是 5，连携槽应该是 50
	assert_eq(link_system.get_combo_count(), 5, "连击数应该是 5")
	assert_almost_eq(link_system.get_link_gauge_current(), 50.0, 0.01, "连携槽应该是 50")