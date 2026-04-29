# 武侠奇遇录 - 战斗机制核心单元测试
# 测试回合制战斗机制、战斗资源系统、战斗状态管理和战斗流程阶段划分

extends "res://addons/gut/test.gd"

# 测试变量
var combat_system = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 创建战斗系统实例
	combat_system = preload("res://src/scripts/combat/combat_system.gd").new()
	combat_system.initialize()

func after_each():
	"""在每个测试之后运行"""
	combat_system = null

# ============================================================================
# AC-1: 回合制战斗机制正常工作（行动顺序、指令输入、执行演出）
# ============================================================================

func test_turn_order_generation_with_different_agility():
	"""AC-1: 验证行动队列根据身法正确生成"""
	# Given: 玩家角色身法为50，敌人身法为40
	var player = combat_system.add_participant("Player", 50)
	var enemy = combat_system.add_participant("Enemy", 40)
	
	# When: 生成行动队列
	var turn_order = combat_system.generate_turn_order()
	
	# Then: 玩家角色在队列中位置优先于敌人
	assert_eq(turn_order.size(), 2, "应该有2个参与者")
	assert_eq(turn_order[0].name, "Player", "身法高的角色应该在前")
	assert_eq(turn_order[1].name, "Enemy", "身法低的角色应该在后")
	assert_eq(turn_order[0].action_order, 0, "玩家的行动顺序应该是0")
	assert_eq(turn_order[1].action_order, 1, "敌人的行动顺序应该是1")

func test_turn_order_with_equal_agility():
	"""AC-1: 验证相同身法值的情况"""
	# Given: 两个角色身法相同
	var char1 = combat_system.add_participant("Char1", 50)
	var char2 = combat_system.add_participant("Char2", 50)
	
	# When: 生成行动队列
	var turn_order = combat_system.generate_turn_order()
	
	# Then: 应该有2个参与者，顺序可能相同
	assert_eq(turn_order.size(), 2, "应该有2个参与者")
	assert_true(turn_order[0].agility == turn_order[1].agility, "身法应该相同")

func test_turn_order_with_multiple_enemies():
	"""AC-1: 验证多个敌人的情况"""
	# Given: 玩家和多个敌人
	var player = combat_system.add_participant("Player", 60)
	var enemy1 = combat_system.add_participant("Enemy1", 40)
	var enemy2 = combat_system.add_participant("Enemy2", 50)
	var enemy3 = combat_system.add_participant("Enemy3", 30)
	
	# When: 生成行动队列
	var turn_order = combat_system.generate_turn_order()
	
	# Then: 应该按身法从高到低排序
	assert_eq(turn_order.size(), 4, "应该有4个参与者")
	assert_eq(turn_order[0].agility, 60, "第一个应该是身法60")
	assert_eq(turn_order[1].agility, 50, "第二个应该是身法50")
	assert_eq(turn_order[2].agility, 40, "第三个应该是身法40")
	assert_eq(turn_order[3].agility, 30, "第四个应该是身法30")

func test_input_phase_transition():
	"""AC-1: 验证进入指令输入阶段"""
	# Given: 战斗已开始
	var player = combat_system.add_participant("Player", 50)
	combat_system.start_combat()
	
	# When: 进入指令输入阶段
	combat_system.enter_input_phase()
	
	# Then: 当前阶段应该是 INPUT
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.INPUT, "应该进入 INPUT 阶段")

func test_execution_phase_transition():
	"""AC-1: 验证进入执行演出阶段"""
	# Given: 战斗已开始
	var player = combat_system.add_participant("Player", 50)
	combat_system.start_combat()
	
	# When: 进入执行演出阶段
	combat_system.enter_execution_phase()
	
	# Then: 当前阶段应该是 EXECUTION
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.EXECUTION, "应该进入 EXECUTION 阶段")

# ============================================================================
# AC-2: 战斗资源系统正确实现（内力、架势、连击值、连携槽）
# ============================================================================

func test_qi_consumption():
	"""AC-2: 验证内力消耗"""
	# Given: 战斗中角色内力上限为100
	var player = combat_system.add_participant("Player", 50, 100, 80)
	var resources = combat_system.get_resources(player)
	
	# When: 角色使用消耗50内力的技能
	var success = combat_system.consume_qi(player, 50)
	
	# Then: 内力应该减少50
	assert_true(success, "消耗应该成功")
	assert_eq(resources.qi_current, 50, "内力应该从100减少到50")

func test_qi_insufficient():
	"""AC-2: 验证内力不足的情况"""
	# Given: 战斗中角色内力为30
	var player = combat_system.add_participant("Player", 50, 100, 80)
	var resources = combat_system.get_resources(player)
	resources.qi_current = 30
	
	# When: 尝试消耗50内力
	var success = combat_system.consume_qi(player, 50)
	
	# Then: 消耗应该失败，内力不变
	assert_false(success, "消耗应该失败")
	assert_eq(resources.qi_current, 30, "内力应该保持不变")

func test_poise_damage():
	"""AC-2: 验证架势伤害"""
	# Given: 战斗中角色架势上限为80
	var player = combat_system.add_participant("Player", 50, 100, 80)
	var resources = combat_system.get_resources(player)
	
	# When: 受到架势消耗30的攻击
	combat_system.apply_poise_damage(player, 30)
	
	# Then: 架势应该减少30
	assert_eq(resources.poise_current, 50, "架势应该从80减少到50")

func test_poise_break_state():
	"""AC-2: 验证架势归零进入破防状态"""
	# Given: 战斗中角色架势为30
	var player = combat_system.add_participant("Player", 50, 100, 80)
	var resources = combat_system.get_resources(player)
	resources.poise_current = 30
	
	# When: 受到30点架势伤害
	combat_system.apply_poise_damage(player, 30)
	
	# Then: 架势应该为0，状态应该是 BREAK
	assert_eq(resources.poise_current, 0, "架势应该为0")
	assert_eq(combat_system.get_participant_state(player), combat_system.CombatState.BREAK, "应该进入 BREAK 状态")

func test_combo_count_increment():
	"""AC-2: 验证连击数增加"""
	# Given: 战斗中角色连击数为0
	var player = combat_system.add_participant("Player", 50)
	var resources = combat_system.get_resources(player)
	
	# When: 连续命中敌人
	combat_system.increment_combo(player)
	combat_system.increment_combo(player)
	combat_system.increment_combo(player)
	
	# Then: 连击数应该增加到3
	assert_eq(resources.combo_count, 3, "连击数应该为3")

func test_combo_damage_multiplier():
	"""AC-2: 验证连击伤害倍率（最高+30%）"""
	# Given: 战斗中角色连击数为30
	var player = combat_system.add_participant("Player", 50)
	var resources = combat_system.get_resources(player)
	resources.combo_count = 30
	
	# When: 获取连击伤害倍率
	var multiplier = resources.get_combo_damage_multiplier()
	
	# Then: 倍率应该是1.3（+30%）
	assert_almost_eq(multiplier, 1.3, 0.01, "连击伤害倍率应该是1.3")

func test_link_gauge_accumulation():
	"""AC-2: 验证连携槽积累"""
	# Given: 战斗中角色连携槽为0
	var player = combat_system.add_participant("Player", 50)
	var resources = combat_system.get_resources(player)
	
	# When: 积累连携槽
	combat_system.add_link_gauge(player, 20)
	combat_system.add_link_gauge(player, 30)
	
	# Then: 连携槽应该为50
	assert_eq(resources.link_gauge, 50, "连携槽应该为50")

func test_link_gauge_max_limit():
	"""AC-2: 验证连携槽上限"""
	# Given: 战斗中角色连携槽上限为100
	var player = combat_system.add_participant("Player", 50)
	var resources = combat_system.get_resources(player)
	
	# When: 积累超过上限的连携槽
	combat_system.add_link_gauge(player, 80)
	combat_system.add_link_gauge(player, 50)
	
	# Then: 连携槽应该被限制在100
	assert_eq(resources.link_gauge, 100, "连携槽应该被限制在100")

func test_qi_recovery():
	"""AC-2: 验证内力恢复"""
	# Given: 战斗中角色内力为50
	var player = combat_system.add_participant("Player", 50, 100, 80)
	var resources = combat_system.get_resources(player)
	resources.qi_current = 50
	
	# When: 恢复内力（5%）
	resources.recover_qi(0.05)
	
	# Then: 内力应该恢复到55
	assert_eq(resources.qi_current, 55, "内力应该恢复5点")

# ============================================================================
# AC-3: 战斗状态管理正常（Normal、Down、Break、Stun等）
# ============================================================================

func test_state_transition_to_break():
	"""AC-3: 验证状态转换到 BREAK"""
	# Given: 敌人处于 Normal 状态
	var enemy = combat_system.add_participant("Enemy", 40)
	assert_eq(combat_system.get_participant_state(enemy), combat_system.CombatState.NORMAL, "初始状态应该是 NORMAL")
	
	# When: 敌人架势归零
	var resources = combat_system.get_resources(enemy)
	resources.poise_current = 0
	combat_system.set_participant_state(enemy, combat_system.CombatState.BREAK)
	
	# Then: 敌人应该进入 BREAK 状态
	assert_eq(combat_system.get_participant_state(enemy), combat_system.CombatState.BREAK, "应该进入 BREAK 状态")

func test_state_transition_to_down():
	"""AC-3: 验证状态转换到 DOWN"""
	# Given: 角色处于 Normal 状态
	var player = combat_system.add_participant("Player", 50)
	
	# When: 角色被击倒
	combat_system.set_participant_state(player, combat_system.CombatState.DOWN)
	
	# Then: 角色应该进入 DOWN 状态
	assert_eq(combat_system.get_participant_state(player), combat_system.CombatState.DOWN, "应该进入 DOWN 状态")

func test_state_transition_to_stun():
	"""AC-3: 验证状态转换到 STUN"""
	# Given: 角色处于 Normal 状态
	var player = combat_system.add_participant("Player", 50)
	
	# When: 角色被眩晕
	combat_system.set_participant_state(player, combat_system.CombatState.STUN)
	
	# Then: 角色应该进入 STUN 状态
	assert_eq(combat_system.get_participant_state(player), combat_system.CombatState.STUN, "应该进入 STUN 状态")

func test_can_act_in_normal_state():
	"""AC-3: 验证 NORMAL 状态可以行动"""
	# Given: 角色处于 NORMAL 状态
	var player = combat_system.add_participant("Player", 50)
	
	# When: 检查是否可以行动
	var can_act = player.can_act()
	
	# Then: 应该可以行动
	assert_true(can_act, "NORMAL 状态应该可以行动")

func test_cannot_act_in_down_state():
	"""AC-3: 验证 DOWN 状态无法行动"""
	# Given: 角色处于 DOWN 状态
	var player = combat_system.add_participant("Player", 50)
	combat_system.set_participant_state(player, combat_system.CombatState.DOWN)
	
	# When: 检查是否可以行动
	var can_act = player.can_act()
	
	# Then: 应该无法行动
	assert_false(can_act, "DOWN 状态应该无法行动")

func test_cannot_act_in_stun_state():
	"""AC-3: 验证 STUN 状态无法行动"""
	# Given: 角色处于 STUN 状态
	var player = combat_system.add_participant("Player", 50)
	combat_system.set_participant_state(player, combat_system.CombatState.STUN)
	
	# When: 检查是否可以行动
	var can_act = player.can_act()
	
	# Then: 应该无法行动
	assert_false(can_act, "STUN 状态应该无法行动")

func test_down_state_cleared_on_turn_end():
	"""AC-3: 验证回合结束时 DOWN 状态被清除"""
	# Given: 角色处于 DOWN 状态
	var player = combat_system.add_participant("Player", 50)
	combat_system.set_participant_state(player, combat_system.CombatState.DOWN)
	
	# When: 回合结束
	combat_system.end_turn()
	
	# Then: DOWN 状态应该被清除，回到 NORMAL
	assert_eq(combat_system.get_participant_state(player), combat_system.CombatState.NORMAL, "DOWN 状态应该被清除")

# ============================================================================
# AC-4: 战斗流程阶段划分正确（遭遇、指令输入、执行演出、敌方回合、回合结束）
# ============================================================================

func test_combat_start_phase():
	"""AC-4: 验证战斗开始进入遭遇阶段"""
	# Given: 战斗未开始
	var player = combat_system.add_participant("Player", 50)
	
	# When: 开始战斗
	combat_system.start_combat()
	
	# Then: 应该进入 ENCOUNTER 阶段
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.ENCOUNTER, "应该进入 ENCOUNTER 阶段")

func test_phase_transition_sequence():
	"""AC-4: 验证阶段转换顺序"""
	# Given: 战斗已开始
	var player = combat_system.add_participant("Player", 50)
	combat_system.start_combat()
	
	# When: 按顺序转换阶段
	combat_system.enter_input_phase()
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.INPUT, "应该进入 INPUT 阶段")
	
	combat_system.enter_execution_phase()
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.EXECUTION, "应该进入 EXECUTION 阶段")
	
	combat_system.enter_enemy_phase()
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.ENEMY, "应该进入 ENEMY 阶段")
	
	combat_system.end_turn()
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.END, "应该进入 END 阶段")

func test_input_phase_allows_command_selection():
	"""AC-4: 验证指令输入阶段允许选择指令"""
	# Given: 战斗已开始
	var player = combat_system.add_participant("Player", 50)
	combat_system.start_combat()
	
	# When: 进入指令输入阶段
	combat_system.enter_input_phase()
	
	# Then: 当前阶段应该是 INPUT（此时应该暂停游戏时间）
	assert_eq(combat_system.get_current_phase(), combat_system.CombatPhase.INPUT, "应该进入 INPUT 阶段")
	# 注：实际的时间暂停由 UI 系统处理，这里只验证阶段转换

func test_turn_order_regenerated_on_turn_end():
	"""AC-4: 验证回合结束时重新生成行动队列"""
	# Given: 战斗已开始，有多个参与者
	var player = combat_system.add_participant("Player", 50)
	var enemy = combat_system.add_participant("Enemy", 40)
	combat_system.start_combat()
	
	# When: 结束回合
	var initial_order = combat_system.get_turn_order().duplicate()
	combat_system.end_turn()
	var new_order = combat_system.get_turn_order()
	
	# Then: 应该重新生成行动队列
	assert_eq(new_order.size(), 2, "应该有2个参与者")
	assert_eq(new_order[0].action_order, 0, "第一个参与者的行动顺序应该是0")

func test_combat_end():
	"""AC-4: 验证战斗结束"""
	# Given: 战斗已开始
	var player = combat_system.add_participant("Player", 50)
	combat_system.start_combat()
	assert_true(combat_system.is_combat_active, "战斗应该是活跃的")
	
	# When: 结束战斗
	combat_system.end_combat()
	
	# Then: 战斗应该结束
	assert_false(combat_system.is_combat_active, "战斗应该已结束")