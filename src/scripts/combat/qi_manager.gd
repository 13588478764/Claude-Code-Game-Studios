## QiManager
## 内力管理器
##
## 管理内力系统的节点，实现内力池、恢复和消耗机制。
##
## 功能：
## - 内力池管理（当前值、最大值、计算）
## - 内力消耗（基础消耗、连招递增、心境减免）
## - 内力恢复（自然恢复、行动恢复、战斗外恢复）
## - 过载机制（内力不足时消耗生命值）
##
## 依赖系统：
## - MartialArtsSystem（武学系统）
## - CombatSystem（战斗系统）
## - CharacterProgressionSystem（角色成长系统）

extends Node
class_name QiManager

# ============================================================================
# 常量定义
# ============================================================================

const MAX_OVERLOAD_RATIO: float = 2.0  # 最大过载转换率
const MIN_OVERLOAD_RATIO: float = 0.1  # 最小过载转换率

const DEFAULT_WISDOM: int = 10  # 默认悟性
const DEFAULT_MIND_ATTRIBUTE: int = 10  # 默认心境
const DEFAULT_CULTIVATION_LEVEL: int = 1  # 默认修为境界

const BASE_QI: int = 100  # 基础内力值
const MIN_QI: int = 100  # 最小内力值
const MAX_QI: int = 1000  # 最大内力值

const BASE_RECOVERY_RATE: float = 0.05  # 基础恢复比例
const DEFAULT_OVERLOAD_RATIO: float = 0.8  # 默认过载转换率

const WISDOM_QI_BONUS: int = 5  # 每点悟性提供的内力值
const WISDOM_RECOVERY_BONUS: float = 0.05  # 每点悟性提供的恢复加成
const MIND_REDUCTION_PER_POINT: float = 0.01  # 每点心境提供的消耗减免
const MAX_MIND_REDUCTION: float = 0.3  # 最大消耗减免（30%）

const COMBO_SCALING: float = 0.15  # 连招递增系数
const ATTACK_RECOVERY: int = 10  # 普攻恢复内力
const DEFEND_RECOVERY: int = 20  # 防御恢复内力
const HIT_TAKEN_RECOVERY: int = 5  # 受击恢复内力
const ITEM_RECOVERY: int = 30  # 物品恢复内力

# ============================================================================
# 信号定义
# ============================================================================

signal qi_changed(current: int, max: int)
signal qi_recovered(amount: int)
signal qi_consumed(amount: int)
signal overload_triggered(damage: int)
signal combat_state_changed(in_combat: bool)

# ============================================================================
# 属性定义
# ============================================================================

# 内力池相关属性
var current_qi: int = 0
var max_qi: int = 0

# 角色属性
var wisdom: int = DEFAULT_WISDOM  # 悟性
var mind_attribute: int = DEFAULT_MIND_ATTRIBUTE  # 心境
var cultivation_level: int = DEFAULT_CULTIVATION_LEVEL  # 修为境界

# 装备和技能加成
var equipment_qi_bonus: int = 0
var skill_qi_bonus: int = 0

# 战斗状态
var is_in_combat: bool = false
var combo_count: int = 0  # 当前回合连击数
var last_combat_action: String = ""

# 系统引用
var martial_arts_system: Node = null
var combat_system: Node = null
var character_progression_system: Node = null

# 恢复相关参数
var base_recovery_rate: float = BASE_RECOVERY_RATE  # 基础恢复比例
var overload_ratio: float = DEFAULT_OVERLOAD_RATIO  # 过载转换率

# 初始化
func _ready():
	# 初始化内力池
	initialize_qi_pool()

# 初始化内力池
func initialize_qi_pool():
	# 计算最大内力值
	max_qi = calculate_max_qi()
	
	# 当前内力值设为最大值
	current_qi = max_qi
	
	# 发射内力变化信号
	emit_signal("qi_changed", current_qi, max_qi)

# 计算最大内力值
func calculate_max_qi() -> int:
	# 先天真气：基础值 + 属性修正
	var passive_qi = base_qi + (wisdom * 5)  # 每点悟性提供5点内力
	
	# 后天精气：装备和技能加成
	var active_qi = equipment_qi_bonus + skill_qi_bonus
	
	# 计算总内力
	var total_qi = passive_qi + active_qi
	
	# 限制在合理范围内
	return clamp(total_qi, 100, 1000)

# 获取当前内力值
func get_current_qi() -> int:
	return current_qi

# 获取最大内力值
func get_max_qi() -> int:
	return max_qi

# 设置内力值
func set_qi_value(value: int):
	var old_value = current_qi
	current_qi = clamp(value, 0, max_qi)
	
	# 发射内力变化信号
	emit_signal("qi_changed", current_qi, max_qi)
	
	# 如果内力值发生变化，触发UI更新
	if old_value != current_qi:
		# 这里可以添加UI更新逻辑
		pass

# 增加内力值
func add_qi(amount: int) -> int:
	var old_value = current_qi
	var new_value = clamp(current_qi + amount, 0, max_qi)
	var actual_added = new_value - current_qi
	
	current_qi = new_value
	
	# 发射内力变化和恢复信号
	emit_signal("qi_changed", current_qi, max_qi)
	if actual_added > 0:
		emit_signal("qi_recovered", actual_added)
	
	return actual_added

# 消耗内力值
func consume_qi(cost: int, martial_art_data = null) -> bool:
	# 计算实际消耗
	var actual_cost = calculate_actual_cost(cost, martial_art_data)
	
	# 检查是否有足够内力
	if current_qi >= actual_cost:
		# 扣除内力
		current_qi = max(0, current_qi - actual_cost)
		
		# 发射内力变化和消耗信号
		emit_signal("qi_changed", current_qi, max_qi)
		emit_signal("qi_consumed", actual_cost)
		
		# 重置连击计数
		combo_count = 0
		
		return true
	else:
		# 内力不足，检查是否可以使用过载机制
		if can_overload(actual_cost):
			# 触发过载机制
			var overload_damage = trigger_overload(actual_cost)
			emit_signal("overload_triggered", overload_damage)
			
			# 重置连击计数
			combo_count = 0
			
			return true
		else:
			# 无法使用技能
			return false

# 计算实际消耗
func calculate_actual_cost(base_cost: int, martial_art_data = null) -> int:
	var actual_cost = float(base_cost)
	
	# 应用连招递增消耗
	actual_cost *= (1 + get_combo_scaling() * combo_count)
	
	# 应用心境消耗减免
	actual_cost *= (1 - get_mind_reduction())
	
	# 应用境界压制效果（低阶武学消耗减半）
	if martial_art_data and is_low_level_art_for_character(martial_art_data):
		actual_cost *= 0.5
	
	# 确保消耗值不为负数
	actual_cost = max(0, actual_cost)
	
	return int(actual_cost)

# 获取连招递增系数
func get_combo_scaling() -> float:
	# 根据GDD，连招递增系数为0.1-0.2
	return 0.15

# 获取心境消耗减免
func get_mind_reduction() -> float:
	# 每10点心境提供1%消耗减免，最大30%
	var reduction = min(float(mind_attribute) * 0.01, 0.3)
	return reduction

# 检查是否为低阶武学（相对于角色境界）
func is_low_level_art_for_character(martial_art_data) -> bool:
	if martial_art_data.has("level_requirement"):
		return cultivation_level > martial_art_data.level_requirement + 5  # 假设相差5级以上为低阶
	return false

# 检查是否可以过载
func can_overload(required_qi: int) -> bool:
	# 检查是否有生命值系统可以消耗
	# 这里需要与生命值系统集成
	return true  # 简化实现，假设总是可以过载

# 触发过载机制
func trigger_overload(required_qi: int) -> int:
	var qi_deficit = required_qi - current_qi
	var hp_damage = int(float(qi_deficit) * overload_ratio)
	
	# 这里需要与生命值系统集成来实际扣除生命值
	# 并可能触发虚弱状态
	emit_signal("overload_triggered", hp_damage)
	
	return hp_damage

# 战斗内恢复内力
func recover_qi_in_combat():
	if not is_in_combat:
		return
	
	# 自然回复
	var natural_recovery = calculate_natural_recovery()
	add_qi(int(natural_recovery))
	
	# 行动回收（根据上一次行动类型）
	match last_combat_action:
		"attack":
			add_qi(10)  # 普攻恢复10点内力
		"defend":
			add_qi(20)  # 防御恢复20点内力
		"hit_taken":
			add_qi(5)   # 受击恢复少量内力

# 战斗外恢复内力
func recover_qi_out_of_combat():
	if is_in_combat:
		return
	
	# 自动恢复到满值
	var recovery_amount = max_qi - current_qi
	if recovery_amount > 0:
		add_qi(recovery_amount)

# 计算自然恢复量
func calculate_natural_recovery() -> float:
	# 内力恢复量 = 最大内力 × 基础恢复率 × (1 + 悟性修正系数)
	var wisdom_bonus = min(float(wisdom) * 0.05, 0.5)  # 每10点悟性+5%恢复，最大50%
	return float(max_qi) * base_recovery_rate * (1 + wisdom_bonus)

# 计算恢复量
func calculate_recovery_amount(recovery_type: String) -> float:
	match recovery_type:
		"natural":
			return calculate_natural_recovery()
		"attack":
			return 10.0
		"defend":
			return 20.0
		"hit_taken":
			return 5.0
		"item":
			# 从物品数据中获取恢复量
			return 30.0  # 示例值
		_:
			return 0.0

# 应用恢复加成
func apply_recovery_bonus(amount: float, bonus_type: String) -> float:
	var bonus_multiplier = 1.0
	
	match bonus_type:
		"wisdom":
			# 悟性提供恢复加成
			bonus_multiplier += min(float(wisdom) * 0.02, 0.3)  # 每10点悟性+2%恢复，最大30%
		"environment":
			# 环境加成（如灵气浓郁区域）
			bonus_multiplier = 2.0  # 2倍恢复速度
		"item":
			# 特定物品加成
			bonus_multiplier += 0.5  # 50%额外恢复
	
	return amount * bonus_multiplier

# 重置连击计数
func reset_combo():
	combo_count = 0

# 开始新连击
func start_new_combo():
	combo_count = 0

# 增加连击计数
func increment_combo():
	if is_in_combat:
		combo_count += 1

# 设置战斗状态
func set_combat_state(in_combat: bool):
	is_in_combat = in_combat

# 记录最后的战斗行动
func record_last_action(action: String):
	last_combat_action = action

# 更新角色属性
func update_character_attributes(wis: int, mind: int, level: int):
	wisdom = wis
	mind_attribute = mind
	cultivation_level = level
	
	# 重新计算最大内力
	var old_max = max_qi
	max_qi = calculate_max_qi()
	
	# 如果最大内力发生变化，调整当前内力
	if max_qi != old_max:
		current_qi = min(current_qi, max_qi)
		emit_signal("qi_changed", current_qi, max_qi)

# 更新装备加成
func update_equipment_bonus(bonus: int):
	equipment_qi_bonus = bonus
	var old_max = max_qi
	max_qi = calculate_max_qi()
	
	# 如果最大内力发生变化，调整当前内力
	if max_qi != old_max:
		current_qi = min(current_qi, max_qi)
		emit_signal("qi_changed", current_qi, max_qi)

# 更新技能加成
func update_skill_bonus(bonus: int):
	skill_qi_bonus = bonus
	var old_max = max_qi
	max_qi = calculate_max_qi()
	
	# 如果最大内力发生变化，调整当前内力
	if max_qi != old_max:
		current_qi = min(current_qi, max_qi)
		emit_signal("qi_changed", current_qi, max_qi)

# 获取内力状态信息
func get_qi_status() -> Dictionary:
	return {
		"current": current_qi,
		"max": max_qi,
		"wisdom": wisdom,
		"mind_attribute": mind_attribute,
		"cultivation_level": cultivation_level,
		"combo_count": combo_count,
		"is_in_combat": is_in_combat
	}

# 设置过载转换率
func set_overload_ratio(ratio: float):
	overload_ratio = clamp(ratio, MIN_OVERLOAD_RATIO, MAX_OVERLOAD_RATIO)