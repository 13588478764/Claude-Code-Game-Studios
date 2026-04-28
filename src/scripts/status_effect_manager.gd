## StatusEffectManager Node类
## 管理角色身上的所有状态效果
## 
## 负责施加、移除、更新状态效果,并在适当时机触发效果
## 遵循ADR-001: 使用Node类管理状态效果实例,通过信号系统通知状态变化

class_name StatusEffectManager
extends Node

## 信号: 状态效果被施加
## @param effect_type: 状态效果类型
## @param stacks: 层数
signal status_applied(effect_type: StatusEffect.EffectType, stacks: int)

## 信号: 状态效果被移除
## @param effect_type: 状态效果类型
signal status_removed(effect_type: StatusEffect.EffectType)

## 信号: 状态效果被触发
## @param effect_type: 状态效果类型
## @param value: 触发的数值(伤害或恢复量)
signal status_triggered(effect_type: StatusEffect.EffectType, value: float)

## 信号: 状态效果被刷新
## @param effect_type: 状态效果类型
## @param new_duration: 新的持续时间
signal status_refreshed(effect_type: StatusEffect.EffectType, new_duration: int)

## 信号: 状态效果被拒绝
## @param effect_type: 状态效果类型
## @param reason: 拒绝原因
signal status_rejected(effect_type: StatusEffect.EffectType, reason: String)

## 当前激活的状态效果列表
var active_effects: Array[StatusEffect] = []

## 最大同时存在的状态效果数量(Control Manifest Guardrail)
const MAX_ACTIVE_EFFECTS: int = 8

## AC5: 互斥状态规则 - 定义哪些状态互斥以及优先级
## 键是低优先级状态,值是高优先级状态
## 例如: FREEZE: BURN 表示 Burn优先级高于Freeze
const MUTEX_RULES: Dictionary = {
	StatusEffect.EffectType.FREEZE: StatusEffect.EffectType.BURN,  # Burn > Freeze
	StatusEffect.EffectType.ROOT: StatusEffect.EffectType.STUN     # Stun > Root
}

## 角色属性引用(用于计算伤害/恢复)
var max_hp: float = 1000.0
var current_hp: float = 1000.0
var defense: float = 50.0

## AC6: 道具系统桥接器引用(用于监听道具使用信号)
var item_system: Node = null

## 设置角色属性
## @param p_max_hp: 最大生命值
## @param p_current_hp: 当前生命值
## @param p_defense: 防御值
func set_character_stats(p_max_hp: float, p_current_hp: float, p_defense: float) -> void:
	max_hp = p_max_hp
	current_hp = p_current_hp
	defense = p_defense

## 施加状态效果
## @param effect: 要施加的状态效果
## @return: 是否成功施加
func apply_status(effect: StatusEffect) -> bool:
	if effect == null:
		push_warning("Attempted to apply null status effect")
		return false
	
	# AC5: 互斥状态检查 - 在施加前检查互斥关系
	var mutex_result = _check_mutex_status(effect.effect_type)
	if mutex_result.has_conflict:
		if mutex_result.new_has_priority:
			# 新状态优先级更高,移除旧状态
			remove_status(mutex_result.conflicting_type)
		else:
			# 旧状态优先级更高,拒绝新状态
			status_rejected.emit(effect.effect_type, "Blocked by higher priority status: %s" % StatusEffect.EffectType.keys()[mutex_result.conflicting_type])
			return false
	
	# 检查是否已存在相同类型的状态
	var existing_effect = find_effect_by_type(effect.effect_type)
	
	if existing_effect != null:
		# 如果状态可堆叠,增加层数
		if existing_effect.stackable:
			var success = existing_effect.add_stacks(effect.stacks)
			if success:
				status_applied.emit(effect.effect_type, existing_effect.stacks)
			else:
				# 达到最大层数,刷新持续时间
				existing_effect.refresh_duration(effect.duration)
				status_refreshed.emit(effect.effect_type, effect.duration)
			return true
		else:
			# 不可堆叠,刷新持续时间
			existing_effect.refresh_duration(effect.duration)
			status_refreshed.emit(effect.effect_type, effect.duration)
			return true
	
	# 检查是否超过最大数量限制
	if active_effects.size() >= MAX_ACTIVE_EFFECTS:
		push_warning("Cannot apply status effect: maximum active effects reached (%d)" % MAX_ACTIVE_EFFECTS)
		return false
	
	# 添加新的状态效果
	var new_effect = effect.duplicate_effect()
	active_effects.append(new_effect)
	status_applied.emit(effect.effect_type, effect.stacks)
	
	return true

## 移除状态效果
## @param effect_type: 要移除的状态效果类型
## @return: 是否成功移除
func remove_status(effect_type: StatusEffect.EffectType) -> bool:
	for i in range(active_effects.size()):
		if active_effects[i].effect_type == effect_type:
			active_effects.remove_at(i)
			status_removed.emit(effect_type)
			return true
	
	return false

## 查找指定类型的状态效果
## @param effect_type: 状态效果类型
## @return: 找到的状态效果,如果不存在则返回null
func find_effect_by_type(effect_type: StatusEffect.EffectType) -> StatusEffect:
	for effect in active_effects:
		if effect.effect_type == effect_type:
			return effect
	return null

## 检查是否有指定类型的状态效果
## @param effect_type: 状态效果类型
## @return: 是否存在
func has_status(effect_type: StatusEffect.EffectType) -> bool:
	return find_effect_by_type(effect_type) != null

## 获取指定类型状态效果的层数
## @param effect_type: 状态效果类型
## @return: 层数,如果不存在则返回0
func get_status_stacks(effect_type: StatusEffect.EffectType) -> int:
	var effect = find_effect_by_type(effect_type)
	if effect != null:
		return effect.stacks
	return 0

## 回合开始时触发状态效果
func trigger_start_of_turn_effects() -> void:
	for effect in active_effects:
		if effect.trigger_timing == StatusEffect.TriggerTiming.START_OF_TURN:
			_trigger_effect(effect)

## 回合结束时触发状态效果
func trigger_end_of_turn_effects() -> void:
	for effect in active_effects:
		if effect.trigger_timing == StatusEffect.TriggerTiming.END_OF_TURN:
			_trigger_effect(effect)

## 触发单个状态效果
## @param effect: 要触发的状态效果
func _trigger_effect(effect: StatusEffect) -> void:
	var value: float = 0.0
	
	match effect.effect_type:
		StatusEffect.EffectType.BURN:
			value = effect.calculate_burn_damage(max_hp)
			current_hp = max(current_hp - value, 0.0)
			status_triggered.emit(effect.effect_type, value)
		
		StatusEffect.EffectType.POISON:
			value = effect.calculate_poison_damage(defense)
			current_hp = max(current_hp - value, 0.0)
			status_triggered.emit(effect.effect_type, value)
		
		StatusEffect.EffectType.REGEN:
			value = effect.calculate_regen_heal(max_hp)
			current_hp = min(current_hp + value, max_hp)
			status_triggered.emit(effect.effect_type, value)
		
		_:
			# 其他状态效果类型暂不处理
			pass

## 更新所有状态效果(每回合调用)
func update_status_effects() -> void:
	# 使用倒序遍历,以便安全删除过期效果
	for i in range(active_effects.size() - 1, -1, -1):
		var effect = active_effects[i]
		effect.decrease_duration()
		
		if effect.is_expired():
			var effect_type = effect.effect_type
			active_effects.remove_at(i)
			status_removed.emit(effect_type)

## 清除所有状态效果
func clear_all_status() -> void:
	var removed_types: Array[StatusEffect.EffectType] = []
	for effect in active_effects:
		removed_types.append(effect.effect_type)
	
	active_effects.clear()
	
	for effect_type in removed_types:
		status_removed.emit(effect_type)

## 获取所有激活的状态效果
## @return: 状态效果数组的副本
func get_active_effects() -> Array[StatusEffect]:
	return active_effects.duplicate()

## 获取激活的状态效果数量
## @return: 数量
func get_active_effect_count() -> int:
	return active_effects.size()

## 驱散指定数量的负面状态
## @param count: 要驱散的数量,-1表示全部
## @return: 实际驱散的数量
func dispel_debuffs(count: int = 1) -> int:
	var debuff_types = [
		StatusEffect.EffectType.BURN,
		StatusEffect.EffectType.POISON,
		StatusEffect.EffectType.BLEED,
		StatusEffect.EffectType.WEAKEN,
		StatusEffect.EffectType.VULNERABLE,
		StatusEffect.EffectType.BLIND,
		StatusEffect.EffectType.STUN,
		StatusEffect.EffectType.ROOT,
		StatusEffect.EffectType.SILENCE,
		StatusEffect.EffectType.FREEZE,
		StatusEffect.EffectType.BREAK
	]
	
	var dispelled = 0
	var to_remove: Array[StatusEffect.EffectType] = []
	
	for effect in active_effects:
		if effect.effect_type in debuff_types:
			to_remove.append(effect.effect_type)
			dispelled += 1
			if count > 0 and dispelled >= count:
				break
	
	for effect_type in to_remove:
		remove_status(effect_type)
	
	return dispelled

## 性能监控: 获取状态效果计算耗时
## @return: 耗时(毫秒)
func get_last_update_time_ms() -> float:
	# 这是一个占位符,实际实现需要在update_status_effects中测量
	# Control Manifest Guardrail: 状态效果计算每帧不超过1ms
	return 0.0

## AC6: 连接道具系统
## @param p_item_system: 道具系统桥接器节点
func connect_item_system(p_item_system: Node) -> void:
	if item_system != null:
		# 断开旧的连接
		if item_system.is_connected("item_used", _on_item_used):
			item_system.disconnect("item_used", _on_item_used)
	
	item_system = p_item_system
	
	if item_system != null:
		# 连接新的信号
		item_system.connect("item_used", _on_item_used)
		print("[StatusEffectManager] Connected to item system")

## AC6: 道具使用信号处理
## @param item_id: 道具ID
## @param user: 使用者节点
func _on_item_used(item_id: String, user: Node) -> void:
	# 检查是否是金创药
	if item_id == "golden_wound_medicine":
		_apply_regen_from_golden_medicine(user)

## AC6: 从金创药施加Regen状态
## @param user: 使用者节点
func _apply_regen_from_golden_medicine(user: Node) -> void:
	# 创建Regen状态效果
	# 持续3回合,regen_coefficient=0.02
	var regen_effect = StatusEffect.new(
		StatusEffect.EffectType.REGEN,
		3,  # duration
		1,  # stacks
		0.02,  # coefficient
		0.0  # base_value
	)
	
	# 施加状态
	var success = apply_status(regen_effect)
	
	if success:
		print("[StatusEffectManager] Applied Regen from golden medicine: duration=3, coefficient=0.02")
	else:
		push_warning("[StatusEffectManager] Failed to apply Regen from golden medicine")

## AC5: 检查互斥状态
## @param new_effect_type: 要施加的新状态类型
## @return: 字典包含 {has_conflict: bool, new_has_priority: bool, conflicting_type: EffectType}
func _check_mutex_status(new_effect_type: StatusEffect.EffectType) -> Dictionary:
	var result = {
		"has_conflict": false,
		"new_has_priority": false,
		"conflicting_type": -1
	}
	
	# 检查新状态是否在互斥规则中(作为低优先级)
	if MUTEX_RULES.has(new_effect_type):
		var higher_priority_type = MUTEX_RULES[new_effect_type]
		# 检查是否已有高优先级状态
		if has_status(higher_priority_type):
			result.has_conflict = true
			result.new_has_priority = false
			result.conflicting_type = higher_priority_type
			return result
	
	# 检查现有状态中是否有被新状态压制的(新状态是高优先级)
	for existing_effect in active_effects:
		if MUTEX_RULES.has(existing_effect.effect_type):
			var higher_priority_type = MUTEX_RULES[existing_effect.effect_type]
			if higher_priority_type == new_effect_type:
				result.has_conflict = true
				result.new_has_priority = true
				result.conflicting_type = existing_effect.effect_type
				return result
	
	return result