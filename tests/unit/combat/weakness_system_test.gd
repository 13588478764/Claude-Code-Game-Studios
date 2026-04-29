# 武侠奇遇录 - 弱点打击系统单元测试
# 测试属性克制系统、弱点打击判定、击倒机制和总攻击触发

extends "res://addons/gut/test.gd"

# 测试变量
var weakness_system = null
var combat_system = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 创建战斗系统和弱点系统实例
	combat_system = preload("res://src/scripts/combat/combat_system.gd").new()
	combat_system.initialize()
	
	weakness_system = preload("res://src/scripts/combat/weakness_system.gd").new()
	weakness_system.initialize(combat_system)

func after_each():
	"""在每个测试之后运行"""
	weakness_system = null
	combat_system = null

# ============================================================================
# AC-1: 属性克制系统正确实现（金/木/水/火/土）
# ============================================================================

func test_elemental_weakness_metal_vs_wood():
	"""AC-1: 验证金克木"""
	# Given: 金属性克制木属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.METAL,
		weakness_system.Element.WOOD
	)
	
	# Then: 应该返回 true
	assert_true(is_weakness, "金应该克制木")

func test_elemental_weakness_wood_vs_earth():
	"""AC-1: 验证木克土"""
	# Given: 木属性克制土属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.WOOD,
		weakness_system.Element.EARTH
	)
	
	# Then: 应该返回 true
	assert_true(is_weakness, "木应该克制土")

func test_elemental_weakness_earth_vs_water():
	"""AC-1: 验证土克水"""
	# Given: 土属性克制水属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.EARTH,
		weakness_system.Element.WATER
	)
	
	# Then: 应该返回 true
	assert_true(is_weakness, "土应该克制水")

func test_elemental_weakness_water_vs_fire():
	"""AC-1: 验证水克火"""
	# Given: 水属性克制火属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.WATER,
		weakness_system.Element.FIRE
	)
	
	# Then: 应该返回 true
	assert_true(is_weakness, "水应该克制火")

func test_elemental_weakness_fire_vs_metal():
	"""AC-1: 验证火克金"""
	# Given: 火属性克制金属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.FIRE,
		weakness_system.Element.METAL
	)
	
	# Then: 应该返回 true
	assert_true(is_weakness, "火应该克制金")

func test_elemental_weakness_same_element():
	"""AC-1: 验证相同属性不克制"""
	# Given: 相同属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.METAL,
		weakness_system.Element.METAL
	)
	
	# Then: 应该返回 false
	assert_false(is_weakness, "相同属性不应该克制")

func test_elemental_weakness_no_weakness():
	"""AC-1: 验证无克制关系"""
	# Given: 金属性不克制火属性
	var is_weakness = weakness_system.check_elemental_weakness(
		weakness_system.Element.METAL,
		weakness_system.Element.FIRE
	)
	
	# Then: 应该返回 false
	assert_false(is_weakness, "金不应该克制火")

# ============================================================================
# AC-2: 弱点打击判定正常工作（使用克制属性攻击弱点）
# ============================================================================

func test_weakness_hit_with_exposed_weakness():
	"""AC-2: 验证暴露弱点时的弱点打击"""
	# Given: 敌人弱点为火属性，弱点暴露
	var attacker = Node.new()
	var target = Node.new()
	weakness_system.set_participant_weakness(target, weakness_system.Element.FIRE, true)
	
	# When: 使用水属性攻击
	var result = weakness_system.calculate_weakness_hit(
		attacker,
		target,
		weakness_system.Element.WATER
	)
	
	# Then: 应该触发弱点打击，伤害倍率为 1.5
	assert_true(result.is_weakness_hit, "应该触发弱点打击")
	assert_almost_eq(result.damage_multiplier, 1.5, 0.01, "伤害倍率应该是 1.5")
	assert_true(result.triggered_down, "应该触发击倒")

func test_weakness_hit_with_hidden_weakness():
	"""AC-2: 验证隐藏弱点时不触发弱点打击"""
	# Given: 敌人弱点为火属性，弱点隐藏
	var attacker = Node.new()
	var target = Node.new()
	weakness_system.set_participant_weakness(target, weakness_system.Element.FIRE, false)
	
	# When: 使用水属性攻击
	var result = weakness_system.calculate_weakness_hit(
		attacker,
		target,
		weakness_system.Element.WATER
	)
	
	# Then: 不应该触发弱点打击，伤害倍率为 1.0
	assert_false(result.is_weakness_hit, "不应该触发弱点打击")
	assert_almost_eq(result.damage_multiplier, 1.0, 0.01, "伤害倍率应该是 1.0")

func test_weakness_hit_with_non_weakness_element():
	"""AC-2: 验证非克制属性不触发弱点打击"""
	# Given: 敌人弱点为火属性，弱点暴露
	var attacker = Node.new()
	var target = Node.new()
	weakness_system.set_participant_weakness(target, weakness_system.Element.FIRE, true)
	
	# When: 使用金属性攻击（不克制火）
	var result = weakness_system.calculate_weakness_hit(
		attacker,
		target,
		weakness_system.Element.METAL
	)
	
	# Then: 不应该触发弱点打击，伤害倍率为 1.0
	assert_false(result.is_weakness_hit, "不应该触发弱点打击")
	assert_almost_eq(result.damage_multiplier, 1.0, 0.01, "伤害倍率应该是 1.0")

func test_weakness_hit_with_no_weakness():
	"""AC-2: 验证无弱点时不触发弱点打击"""
	# Given: 敌人没有设置弱点
	var attacker = Node.new()
	var target = Node.new()
	
	# When: 使用任何属性攻击
	var result = weakness_system.calculate_weakness_hit(
		attacker,
		target,
		weakness_system.Element.WATER
	)
	
	# Then: 不应该触发弱点打击，伤害倍率为 1.0
	assert_false(result.is_weakness_hit, "不应该触发弱点打击")
	assert_almost_eq(result.damage_multiplier, 1.0, 0.01, "伤害倍率应该是 1.0")

# ============================================================================
# AC-3: 击倒机制正常（敌人跳过下回合，易伤）
# ============================================================================

func test_down_state_trigger():
	"""AC-3: 验证击倒状态触发"""
	# Given: 敌人处于正常状态
	var target = Node.new()
	assert_false(weakness_system.is_down(target), "初始状态应该不是击倒")
	
	# When: 触发击倒
	weakness_system.trigger_down(target)
	
	# Then: 敌人应该进入击倒状态
	assert_true(weakness_system.is_down(target), "应该进入击倒状态")

func test_down_state_clear():
	"""AC-3: 验证击倒状态清除"""
	# Given: 敌人处于击倒状态
	var target = Node.new()
	weakness_system.trigger_down(target)
	assert_true(weakness_system.is_down(target), "应该处于击倒状态")
	
	# When: 清除击倒状态
	weakness_system.clear_down(target)
	
	# Then: 敌人应该回到正常状态
	assert_false(weakness_system.is_down(target), "应该回到正常状态")

func test_down_vulnerability_multiplier():
	"""AC-3: 验证击倒状态易伤倍率"""
	# Given: 敌人处于击倒状态
	var target = Node.new()
	weakness_system.trigger_down(target)
	
	# When: 获取易伤倍率
	var multiplier = weakness_system.get_down_damage_multiplier(target)
	
	# Then: 倍率应该是 1.5（+50%）
	assert_almost_eq(multiplier, 1.5, 0.01, "易伤倍率应该是 1.5")

func test_normal_state_no_vulnerability():
	"""AC-3: 验证正常状态无易伤"""
	# Given: 敌人处于正常状态
	var target = Node.new()
	
	# When: 获取易伤倍率
	var multiplier = weakness_system.get_down_damage_multiplier(target)
	
	# Then: 倍率应该是 1.0
	assert_almost_eq(multiplier, 1.0, 0.01, "正常状态倍率应该是 1.0")

# ============================================================================
# AC-4: 总攻击触发条件正确（全场敌人均Down时可发动）
# ============================================================================

func test_all_out_attack_all_enemies_down():
	"""AC-4: 验证所有敌人都击倒时总攻击可用"""
	# Given: 战斗中有两个敌人，都被击倒
	var enemy1 = Node.new()
	var enemy2 = Node.new()
	combat_system.add_participant("Enemy1", 40)
	combat_system.add_participant("Enemy2", 35)
	
	weakness_system.trigger_down(combat_system.participants[0])
	weakness_system.trigger_down(combat_system.participants[1])
	
	# When: 检查总攻击可用性
	var is_available = weakness_system.is_all_out_attack_available()
	
	# Then: 总攻击应该可用
	assert_true(is_available, "所有敌人都击倒时总攻击应该可用")

func test_all_out_attack_partial_enemies_down():
	"""AC-4: 验证部分敌人击倒时总攻击不可用"""
	# Given: 战斗中有两个敌人，只有一个被击倒
	combat_system.add_participant("Enemy1", 40)
	combat_system.add_participant("Enemy2", 35)
	
	weakness_system.trigger_down(combat_system.participants[0])
	
	# When: 检查总攻击可用性
	var is_available = weakness_system.is_all_out_attack_available()
	
	# Then: 总攻击不应该可用
	assert_false(is_available, "部分敌人击倒时总攻击不应该可用")

func test_all_out_attack_no_enemies_down():
	"""AC-4: 验证没有敌人击倒时总攻击不可用"""
	# Given: 战斗中有两个敌人，都没有被击倒
	combat_system.add_participant("Enemy1", 40)
	combat_system.add_participant("Enemy2", 35)
	
	# When: 检查总攻击可用性
	var is_available = weakness_system.is_all_out_attack_available()
	
	# Then: 总攻击不应该可用
	assert_false(is_available, "没有敌人击倒时总攻击不应该可用")

func test_all_out_attack_single_enemy_down():
	"""AC-4: 验证单个敌人击倒时总攻击可用"""
	# Given: 战斗中只有一个敌人，被击倒
	combat_system.add_participant("Enemy1", 40)
	
	weakness_system.trigger_down(combat_system.participants[0])
	
	# When: 检查总攻击可用性
	var is_available = weakness_system.is_all_out_attack_available()
	
	# Then: 总攻击应该可用
	assert_true(is_available, "单个敌人击倒时总攻击应该可用")

func test_weakness_exposure_toggle():
	"""AC-2: 验证弱点暴露切换"""
	# Given: 敌人弱点为火属性，初始隐藏
	var target = Node.new()
	weakness_system.set_participant_weakness(target, weakness_system.Element.FIRE, false)
	
	# When: 暴露弱点
	weakness_system.expose_weakness(target)
	
	# Then: 弱点应该暴露
	var weakness_info = weakness_system.get_participant_weakness(target)
	assert_true(weakness_info.is_exposed, "弱点应该暴露")
	
	# When: 隐藏弱点
	weakness_system.hide_weakness(target)
	
	# Then: 弱点应该隐藏
	weakness_info = weakness_system.get_participant_weakness(target)
	assert_false(weakness_info.is_exposed, "弱点应该隐藏")