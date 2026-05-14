## StatusEffect来源与系统交互集成测试
## 测试内存降级处理和道具系统集成
## 
## 覆盖Story 003的所有验收标准:
## - AC3: 内存不足降级处理
## - AC6: 道具使用获得状态

extends GutTest

# 测试用的组件
var manager: StatusEffectManager
var item_system: Node
var game_config: Node

func before_each():
	# 创建状态效果管理器
	manager = StatusEffectManager.new()
	manager.set_character_stats(1000.0, 500.0, 50.0)
	
	# 创建道具系统桥接器（必须 add_child 触发 _ready 加载物品数据库）
	var ItemSystemBridge = load("res://src/scripts/item_system_bridge.gd")
	item_system = ItemSystemBridge.new()
	add_child_autofree(item_system)

	# 创建游戏配置管理器
	var GameConfigManager = load("res://src/scripts/game_config_manager.gd")
	game_config = GameConfigManager.new()
	# 必须 add_child 到 SceneTree，否则 is_node_ready() 返回 false，
	# game_config 内部所有"节点未就绪就 early return"的方法都不会工作。
	# add_child_autofree 会在测试结束时自动清理。
	add_child_autofree(game_config)
	
	# 连接道具系统
	manager.connect_item_system(item_system)

func after_each():
	# 清理
	if manager:
		manager.free()
		manager = null
	# item_system 和 game_config 已用 add_child_autofree，GUT 会自动清理
	item_system = null
	game_config = null

# ============================================================================
# AC3: 内存不足降级处理测试
# ============================================================================

func test_low_memory_mode_detection():
	# Test: 内存检测和降级模式启用
	# 注意: 这个测试依赖实际内存使用情况,可能需要手动模拟
	
	# 手动设置低内存模式(模拟内存不足)
	game_config.set_manual_low_memory_mode(true)
	
	# Then: 低内存模式应该被启用
	assert_true(game_config.is_low_memory_mode(), "低内存模式应该被启用")

func test_low_memory_mode_preserves_core_logic():
	# Test: 低内存模式下,核心状态逻辑正常工作
	# Given: 启用低内存模式
	game_config.set_manual_low_memory_mode(true)
	
	# When: 施加Burn状态并触发
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	manager.trigger_end_of_turn_effects()
	
	# Then: 状态逻辑正常执行(伤害计算正确)
	var expected_hp = 500.0 - 30.0  # 1000 × 0.03 × 1
	assert_almost_eq(manager.current_hp, expected_hp, 0.01, "低内存模式下伤害计算应正确")
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn状态应存在")

func test_normal_memory_mode():
	# Edge case: 内存充足时,使用完整配置
	# Given: 手动设置正常内存模式
	game_config.set_manual_low_memory_mode(false)
	
	# Then: 低内存模式应该被禁用
	assert_false(game_config.is_low_memory_mode(), "正常内存模式下低内存标志应为false")

func test_low_memory_mode_signal():
	# Test: 低内存模式改变时发射信号
	#
	# 注意：game_config._ready() 会调用 check_memory_and_update_mode()，
	# 在内存使用量 < 2GB 阈值时会自动把 low_memory_mode 设为 true。
	# 因此 before_each 之后 game_config 的 low_memory_mode 状态不可预测。
	#
	# 修复：先显式设置到 false 基线（吞掉初始化引起的信号），
	# 再监听信号 + 切换到 true，才能稳定验证 changed 信号。
	game_config.set_manual_low_memory_mode(false)
	assert_false(game_config.is_low_memory_mode(),
		"前置条件：应已被重置为非低内存模式")
	
	# Given: 信号监听从已知基线开始
	watch_signals(game_config)
	
	# When: 切换低内存模式 (false -> true)
	game_config.set_manual_low_memory_mode(true)
	
	# Then: 应发射 low_memory_mode_changed 信号
	assert_signal_emitted(game_config, "low_memory_mode_changed",
		"应发射 low_memory_mode_changed 信号")

func test_all_status_types_work_in_low_memory():
	# Edge case: 降级模式下,所有状态类型都能正常工作
	game_config.set_manual_low_memory_mode(true)
	
	# 测试DoT (Burn)
	var burn = StatusEffect.new(StatusEffect.EffectType.BURN, 2, 1, 0.03, 0.0)
	assert_true(manager.apply_status(burn), "Burn应成功施加")
	
	# 测试HoT (Regen)
	var regen = StatusEffect.new(StatusEffect.EffectType.REGEN, 2, 1, 0.02, 0.0)
	assert_true(manager.apply_status(regen), "Regen应成功施加")
	
	# 测试Debuff (Poison)
	var poison = StatusEffect.new(StatusEffect.EffectType.POISON, 2, 1, 0.0, 10.0)
	assert_true(manager.apply_status(poison), "Poison应成功施加")
	
	# 验证所有状态都存在
	assert_eq(manager.get_active_effect_count(), 3, "应有3个激活状态")

func test_memory_mode_switch_preserves_data():
	# Edge case: 从降级模式切换回正常模式时,状态数据不丢失
	# Given: 低内存模式下施加状态
	game_config.set_manual_low_memory_mode(true)
	var burn = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 2, 0.03, 0.0)
	manager.apply_status(burn)
	
	# When: 切换回正常模式
	game_config.set_manual_low_memory_mode(false)
	
	# Then: 状态数据应保持不变
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn状态应保持")
	assert_eq(manager.get_status_stacks(StatusEffect.EffectType.BURN), 2, "层数应保持为2")

# ============================================================================
# AC6: 道具使用获得状态测试
# ============================================================================

func test_golden_medicine_applies_regen():
	# Test: 使用金创药道具获得Regen状态
	# Given: 角色背包有金创药,当前生命值500/1000,无Regen状态
	assert_eq(manager.current_hp, 500.0, "当前生命值应为500")
	assert_false(manager.has_status(StatusEffect.EffectType.REGEN), "初始无Regen状态")
	
	# 确保背包有金创药
	item_system.add_item("golden_wound_medicine", 1)
	var initial_count = item_system.get_item_count("golden_wound_medicine")
	assert_gt(initial_count, 0, "背包应有金创药")
	
	# When: 使用金创药
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 角色获得Regen状态
	assert_true(manager.has_status(StatusEffect.EffectType.REGEN), "应获得Regen状态")
	
	# 验证Regen状态参数
	var regen = manager.find_effect_by_type(StatusEffect.EffectType.REGEN)
	assert_not_null(regen, "Regen状态应存在")
	assert_eq(regen.duration, 3, "持续时间应为3回合")
	assert_almost_eq(regen.coefficient, 0.02, 0.001, "系数应为0.02")
	
	# 验证道具被移除
	var final_count = item_system.get_item_count("golden_wound_medicine")
	assert_eq(final_count, initial_count - 1, "金创药应被移除1个")

func test_golden_medicine_healing():
	# Test: 金创药的Regen状态正确恢复生命值
	# Given: 使用金创药获得Regen状态
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# When: 回合开始时触发Regen
	var hp_before = manager.current_hp
	manager.trigger_start_of_turn_effects()
	
	# Then: 恢复20点生命值 (1000 × 0.02)
	var expected_hp = hp_before + 20.0
	assert_almost_eq(manager.current_hp, expected_hp, 0.01, "应恢复20点生命值")

func test_golden_medicine_refresh_existing_regen():
	# Edge case: 已有Regen状态时使用金创药,刷新持续时间
	# Given: 已有Regen状态(持续1回合)
	var existing_regen = StatusEffect.new(StatusEffect.EffectType.REGEN, 1, 1, 0.02, 0.0)
	manager.apply_status(existing_regen)
	
	# When: 使用金创药
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 持续时间应刷新为3回合
	var regen = manager.find_effect_by_type(StatusEffect.EffectType.REGEN)
	assert_eq(regen.duration, 3, "持续时间应刷新为3回合")

func test_golden_medicine_no_item_in_inventory():
	# Edge case: 背包无金创药时,使用失败
	# Given: 背包无金创药
	item_system.inventory.clear()
	
	# When: 尝试使用金创药
	var result = item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 使用失败,无Regen状态
	assert_false(result, "使用应失败")
	assert_false(manager.has_status(StatusEffect.EffectType.REGEN), "不应获得Regen状态")

func test_golden_medicine_at_full_hp():
	# Edge case: 生命值满时使用金创药,仍获得Regen状态
	# Given: 生命值满
	manager.set_character_stats(1000.0, 1000.0, 50.0)
	
	# When: 使用金创药
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 仍获得Regen状态(为后续受伤准备)
	assert_true(manager.has_status(StatusEffect.EffectType.REGEN), "满血时也应获得Regen状态")

func test_golden_medicine_outside_combat():
	# Edge case: 战斗外使用金创药,Regen状态正常施加
	# 这个测试与战斗内测试相同,因为状态系统不区分战斗内外
	
	# When: 使用金创药
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: Regen状态正常施加
	assert_true(manager.has_status(StatusEffect.EffectType.REGEN), "战斗外也应获得Regen状态")

# ============================================================================
# 综合测试: 内存降级 + 道具使用
# ============================================================================

func test_item_use_in_low_memory_mode():
	# 综合测试: 低内存模式下使用道具
	# Given: 启用低内存模式
	game_config.set_manual_low_memory_mode(true)
	
	# When: 使用金创药
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: Regen状态正常施加,核心逻辑不受影响
	assert_true(manager.has_status(StatusEffect.EffectType.REGEN), "低内存模式下应获得Regen状态")
	
	# 触发Regen效果
	var hp_before = manager.current_hp
	manager.trigger_start_of_turn_effects()
	var hp_after = manager.current_hp
	
	assert_gt(hp_after, hp_before, "低内存模式下Regen应正常恢复生命值")

# ============================================================================
# 信号测试
# ============================================================================

func test_item_used_signal():
	# 测试道具使用信号
	var signal_watcher = watch_signals(item_system)
	
	# When: 使用道具
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 应发射item_used信号
	assert_signal_emitted(item_system, "item_used", "应发射item_used信号")

func test_item_removed_signal():
	# 测试道具移除信号
	var signal_watcher = watch_signals(item_system)
	
	# When: 使用道具
	item_system.add_item("golden_wound_medicine", 1)
	item_system.use_item("golden_wound_medicine", manager)
	
	# Then: 应发射item_removed_from_inventory信号
	assert_signal_emitted(item_system, "item_removed_from_inventory", "应发射item_removed_from_inventory信号")
