## StatusEffect机制测试
## 测试互斥状态处理和持续时间溢出保护
## 
## 覆盖Story 002的所有验收标准:
## - AC5: 互斥状态处理
## - AC7: 持续时间溢出保护

extends GutTest

# 测试用的StatusEffectManager实例
var manager: StatusEffectManager

func before_each():
	# 每个测试前创建新的管理器实例
	manager = StatusEffectManager.new()
	manager.set_character_stats(1000.0, 1000.0, 50.0)

func after_each():
	# 清理
	if manager:
		manager.free()
		manager = null

# ============================================================================
# AC5: 互斥状态处理测试
# ============================================================================

func test_mutex_burn_overrides_freeze():
	# Test: 互斥状态按优先级处理,Burn覆盖Freeze
	# Given: 角色已有Freeze状态(持续3回合)
	var freeze_effect = StatusEffect.new(StatusEffect.EffectType.FREEZE, 3, 1, 0.0, 0.0)
	manager.apply_status(freeze_effect)
	assert_true(manager.has_status(StatusEffect.EffectType.FREEZE), "应成功施加Freeze状态")
	
	# When: 施加Burn状态(持续2回合)
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 2, 1, 0.03, 0.0)
	var result = manager.apply_status(burn_effect)
	
	# Then: Freeze状态被移除,Burn状态成功施加
	assert_true(result, "Burn应成功施加")
	assert_false(manager.has_status(StatusEffect.EffectType.FREEZE), "Freeze应被移除")
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn应存在")
	
	# 验证持续时间
	var burn = manager.find_effect_by_type(StatusEffect.EffectType.BURN)
	assert_eq(burn.duration, 2, "Burn持续时间应为2回合")

func test_mutex_freeze_blocked_by_burn():
	# Edge case: Freeze施加到已有Burn的角色时,Burn保持,Freeze被拒绝
	# Given: 角色已有Burn状态
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	
	# When: 尝试施加Freeze状态
	var freeze_effect = StatusEffect.new(StatusEffect.EffectType.FREEZE, 2, 1, 0.0, 0.0)
	var result = manager.apply_status(freeze_effect)
	
	# Then: Freeze被拒绝,Burn保持
	assert_false(result, "Freeze应被拒绝")
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn应保持")
	assert_false(manager.has_status(StatusEffect.EffectType.FREEZE), "Freeze不应存在")

func test_mutex_stun_overrides_root():
	# Edge case: Stun vs Root: Stun优先级更高
	# Given: 角色已有Root状态
	var root_effect = StatusEffect.new(StatusEffect.EffectType.ROOT, 3, 1, 0.0, 0.0)
	manager.apply_status(root_effect)
	assert_true(manager.has_status(StatusEffect.EffectType.ROOT), "应成功施加Root状态")
	
	# When: 施加Stun状态
	var stun_effect = StatusEffect.new(StatusEffect.EffectType.STUN, 2, 1, 0.0, 0.0)
	var result = manager.apply_status(stun_effect)
	
	# Then: Root被移除,Stun成功施加
	assert_true(result, "Stun应成功施加")
	assert_false(manager.has_status(StatusEffect.EffectType.ROOT), "Root应被移除")
	assert_true(manager.has_status(StatusEffect.EffectType.STUN), "Stun应存在")

func test_mutex_root_blocked_by_stun():
	# Edge case: Root施加到已有Stun的角色时,Stun保持,Root被拒绝
	# Given: 角色已有Stun状态
	var stun_effect = StatusEffect.new(StatusEffect.EffectType.STUN, 3, 1, 0.0, 0.0)
	manager.apply_status(stun_effect)
	
	# When: 尝试施加Root状态
	var root_effect = StatusEffect.new(StatusEffect.EffectType.ROOT, 2, 1, 0.0, 0.0)
	var result = manager.apply_status(root_effect)
	
	# Then: Root被拒绝,Stun保持
	assert_false(result, "Root应被拒绝")
	assert_true(manager.has_status(StatusEffect.EffectType.STUN), "Stun应保持")
	assert_false(manager.has_status(StatusEffect.EffectType.ROOT), "Root不应存在")

func test_non_mutex_statuses_coexist():
	# Edge case: 非互斥状态(Burn + Poison)可以共存
	# Given: 角色已有Burn状态
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	
	# When: 施加Poison状态
	var poison_effect = StatusEffect.new(StatusEffect.EffectType.POISON, 3, 1, 0.0, 10.0)
	var result = manager.apply_status(poison_effect)
	
	# Then: 两个状态都存在
	assert_true(result, "Poison应成功施加")
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn应存在")
	assert_true(manager.has_status(StatusEffect.EffectType.POISON), "Poison应存在")
	assert_eq(manager.get_active_effect_count(), 2, "应有2个激活状态")

func test_mutex_check_before_any_effect():
	# Edge case: 互斥检查在状态施加前执行,不触发任何效果
	var signal_watcher = watch_signals(manager)
	
	# Given: 角色已有Burn状态
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	
	# When: 尝试施加Freeze状态(会被拒绝)
	var freeze_effect = StatusEffect.new(StatusEffect.EffectType.FREEZE, 2, 1, 0.0, 0.0)
	manager.apply_status(freeze_effect)
	
	# Then: 应发射status_rejected信号
	assert_signal_emitted(manager, "status_rejected", "应发射status_rejected信号")
	
	# 验证Freeze没有被添加到active_effects
	assert_eq(manager.get_active_effect_count(), 1, "应只有1个激活状态(Burn)")

# ============================================================================
# AC7: 持续时间溢出保护测试
# ============================================================================

func test_duration_overflow_clamped_to_max():
	# Test: 持续时间计算结果溢出时自动钳制到1-8回合
	# Given: 状态基础持续时间5,持续时间修正+5
	# When: 计算最终持续时间 = 5 + 5 = 10
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 10, 1, 0.03, 0.0)
	
	# Then: 最终持续时间被钳制为8回合
	assert_eq(effect.duration, 8, "持续时间应被钳制为8回合")

func test_duration_underflow_clamped_to_min():
	# Edge case: 基础持续时间1,修正-3,结果-2,钳制为1回合
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, -2, 1, 0.03, 0.0)
	
	# Then: 最终持续时间被钳制为1回合
	assert_eq(effect.duration, 1, "持续时间应被钳制为1回合")

func test_duration_at_max_boundary():
	# Edge case: 基础持续时间5,修正+3,结果8,保持8回合(边界值)
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 8, 1, 0.03, 0.0)
	
	# Then: 持续时间保持8回合
	assert_eq(effect.duration, 8, "持续时间应保持8回合")

func test_duration_at_min_boundary():
	# Edge case: 基础持续时间1,修正0,结果1,保持1回合(边界值)
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 1, 1, 0.03, 0.0)
	
	# Then: 持续时间保持1回合
	assert_eq(effect.duration, 1, "持续时间应保持1回合")

func test_duration_large_overflow():
	# Edge case: 基础持续时间10,修正0,结果10,钳制为8回合
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 10, 1, 0.03, 0.0)
	
	# Then: 持续时间被钳制为8回合
	assert_eq(effect.duration, 8, "持续时间应被钳制为8回合")

func test_duration_large_underflow():
	# Edge case: 负数溢出测试:基础1,修正-10,结果-9,钳制为1回合
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, -9, 1, 0.03, 0.0)
	
	# Then: 持续时间被钳制为1回合
	assert_eq(effect.duration, 1, "持续时间应被钳制为1回合")

func test_duration_clamp_in_manager():
	# 测试在StatusEffectManager中施加状态时,持续时间也被正确钳制
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 15, 1, 0.03, 0.0)
	manager.apply_status(effect)
	
	var applied_effect = manager.find_effect_by_type(StatusEffect.EffectType.BURN)
	assert_eq(applied_effect.duration, 8, "施加的状态持续时间应被钳制为8回合")

func test_duration_clamp_zero():
	# 边界测试: 持续时间为0应被钳制为1
	var effect = StatusEffect.new(StatusEffect.EffectType.BURN, 0, 1, 0.03, 0.0)
	
	assert_eq(effect.duration, 1, "持续时间0应被钳制为1回合")

# ============================================================================
# 综合测试: 互斥状态 + 持续时间钳制
# ============================================================================

func test_mutex_with_clamped_duration():
	# 测试互斥状态处理时,新状态的持续时间也被正确钳制
	# Given: 角色已有Freeze状态
	var freeze_effect = StatusEffect.new(StatusEffect.EffectType.FREEZE, 3, 1, 0.0, 0.0)
	manager.apply_status(freeze_effect)
	
	# When: 施加持续时间溢出的Burn状态(15回合)
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 15, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	
	# Then: Freeze被移除,Burn被施加且持续时间被钳制
	assert_false(manager.has_status(StatusEffect.EffectType.FREEZE), "Freeze应被移除")
	assert_true(manager.has_status(StatusEffect.EffectType.BURN), "Burn应存在")
	
	var burn = manager.find_effect_by_type(StatusEffect.EffectType.BURN)
	assert_eq(burn.duration, 8, "Burn持续时间应被钳制为8回合")

# ============================================================================
# 信号测试
# ============================================================================

func test_status_rejected_signal():
	# 测试status_rejected信号是否正确发射
	var signal_watcher = watch_signals(manager)
	
	# Given: 角色已有Burn状态
	var burn_effect = StatusEffect.new(StatusEffect.EffectType.BURN, 3, 1, 0.03, 0.0)
	manager.apply_status(burn_effect)
	
	# When: 尝试施加Freeze状态(会被拒绝)
	var freeze_effect = StatusEffect.new(StatusEffect.EffectType.FREEZE, 2, 1, 0.0, 0.0)
	manager.apply_status(freeze_effect)
	
	# Then: 应发射status_rejected信号
	assert_signal_emitted(manager, "status_rejected", "应发射status_rejected信号")
	assert_signal_emit_count(manager, "status_rejected", 1, "应发射1次status_rejected信号")