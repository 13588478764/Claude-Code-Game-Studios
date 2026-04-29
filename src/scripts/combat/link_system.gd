## LinkSystem
## link system
##
## 战斗系统模块

# 武侠奇遇录 - 连携系统
# 实现连携槽系统、连击系统、连携攻击和连携条件判定
#
# 设计原则（来自 ADR-001）：
# - 使用节点系统和信号系统
# - 依赖注入模式传递系统引用
# - 业务逻辑与 UI 分离
# - 使用信号驱动系统间通信

extends Node
class_name LinkSystem

## 连携攻击类型
enum LinkAttackType {
	FOLLOW_UP,    # 追击
	DUAL_TECH     # 合体技
}

## 连携槽信息类
class LinkGauge:
	var current: float = 0.0
	var max_value: float = 100.0
	
	func _init(max_val: float = 100.0):
		max_value = max_val
		current = 0.0
	
	func accumulate(amount: float):
		current = min(current + amount, max_value)
	
	func consume(amount: float) -> bool:
		if current >= amount:
			current -= amount
			return true
		return false
	
	func is_full() -> bool:
		return current >= max_value
	
	func reset():
		current = 0.0

## 连击追踪类
class ComboTracker:
	var count: int = 0
	var max_combo: int = 10
	var damage_multiplier: float = 1.0
	var current_target = null
	
	func _init(max_c: int = 10):
		max_combo = max_c
		count = 0
		damage_multiplier = 1.0
	
	func hit_target(target) -> float:
		if target != current_target:
			reset()
			current_target = target
		
		count = min(count + 1, max_combo)
		damage_multiplier = 1.0 + (count - 1) * 0.1  # 每次连击增加 10% 伤害
		return damage_multiplier
	
	func reset():
		count = 0
		damage_multiplier = 1.0
		current_target = null
	
	func get_combo_count() -> int:
		return count
	
	func get_damage_multiplier() -> float:
		return damage_multiplier

## 连携条件类
class LinkCondition:
	var required_gauge: float = 100.0
	var required_combo: int = 0
	var required_teammates: int = 1
	
	func _init(gauge: float = 100.0, combo: int = 0, teammates: int = 1):
		required_gauge = gauge
		required_combo = combo
		required_teammates = teammates
	
	func check(gauge_value: float, combo_count: int, alive_teammates: int) -> bool:
		return (gauge_value >= required_gauge and 
				combo_count >= required_combo and 
				alive_teammates >= required_teammates)

## 连携攻击类
class LinkAttack:
	var attack_type: int
	var name: String
	var gauge_cost: float
	var damage_multiplier: float
	var condition: LinkCondition
	
	func _init(type: int, attack_name: String, cost: float, dmg_mult: float, cond: LinkCondition):
		attack_type = type
		name = attack_name
		gauge_cost = cost
		damage_multiplier = dmg_mult
		condition = cond

# ============================================================================
# 信号定义
# ============================================================================
signal link_gauge_changed(current: float, max_value: float)
signal combo_count_changed(count: int, multiplier: float)
signal link_attack_executed(attack_name: String, damage_multiplier: float)
signal link_condition_changed(available: bool)

# 连携系统数据
var combat_system: Node = null
var participants: Array = []
var link_gauge: LinkGauge = null
var combo_tracker: ComboTracker = null
var available_link_attacks: Array = []
var current_link_condition: LinkCondition = null

func _ready():
	pass

## 初始化连携系统
func initialize(combat_sys: Node):
	"""
	初始化连携系统。
	
	参数:
	- combat_sys: 战斗系统引用
	"""
	combat_system = combat_sys
	participants = combat_sys.participants if combat_sys else []
	
	# 初始化连携槽（队友间共享）
	link_gauge = LinkGauge.new(100.0)
	
	# 初始化连击追踪
	combo_tracker = ComboTracker.new(10)
	
	# 初始化可用的连携攻击
	available_link_attacks.clear()
	_setup_default_link_attacks()

## AC-1: 连携槽系统正常工作
func accumulate_link_gauge(amount: float):
	"""
	积累连携槽。队友间共享。
	
	参数:
	- amount: 积累量
	"""
	if link_gauge == null:
		return
	
	link_gauge.accumulate(amount)
	link_gauge_changed.emit(link_gauge.current, link_gauge.max_value)
	
	# 检查连携条件
	_check_link_conditions()

## 获取连携槽当前值
func get_link_gauge_current() -> float:
	"""获取连携槽当前值。"""
	return link_gauge.current if link_gauge else 0.0

## 获取连携槽最大值
func get_link_gauge_max() -> float:
	"""获取连携槽最大值。"""
	return link_gauge.max_value if link_gauge else 100.0

## 检查连携槽是否满
func is_link_gauge_full() -> bool:
	"""检查连携槽是否满。"""
	return link_gauge.is_full() if link_gauge else false

## AC-2: 连击系统正常
func record_hit(target) -> float:
	"""
	记录一次命中，更新连击数和伤害倍率。
	
	参数:
	- target: 被击中的目标
	
	返回: 伤害倍率
	"""
	if combo_tracker == null:
		return 1.0
	
	var multiplier = combo_tracker.hit_target(target)
	combo_count_changed.emit(combo_tracker.count, multiplier)
	
	# 积累连携槽（每次命中积累 10 点）
	accumulate_link_gauge(10.0)
	
	return multiplier

## 重置连击
func reset_combo():
	"""重置连击计数。"""
	if combo_tracker:
		combo_tracker.reset()
		combo_count_changed.emit(0, 1.0)

## 获取连击数
func get_combo_count() -> int:
	"""获取当前连击数。"""
	return combo_tracker.count if combo_tracker else 0

## 获取连击伤害倍率
func get_combo_damage_multiplier() -> float:
	"""获取连击伤害倍率。"""
	return combo_tracker.damage_multiplier if combo_tracker else 1.0

## AC-3: 连携攻击实现
func execute_link_attack(attack_name: String) -> bool:
	"""
	执行连携攻击。
	
	参数:
	- attack_name: 连携攻击名称
	
	返回: 是否成功执行
	"""
	if link_gauge == null or combo_tracker == null:
		return false
	
	# 查找攻击
	var attack = null
	for link_attack in available_link_attacks:
		if link_attack.name == attack_name:
			attack = link_attack
			break
	
	if attack == null:
		return false
	
	# 检查条件
	var alive_teammates = _count_alive_teammates()
	if not attack.condition.check(link_gauge.current, combo_tracker.count, alive_teammates):
		return false
	
	# 消耗连携槽
	if not link_gauge.consume(attack.gauge_cost):
		return false
	
	# 发射信号
	link_attack_executed.emit(attack.name, attack.damage_multiplier)
	link_gauge_changed.emit(link_gauge.current, link_gauge.max_value)
	
	# 重置连击
	reset_combo()
	
	# 检查连携条件
	_check_link_conditions()
	
	return true

## 获取可用的连携攻击列表
func get_available_link_attacks() -> Array:
	"""获取当前可用的连携攻击列表。"""
	var available = []
	var alive_teammates = _count_alive_teammates()
	
	if link_gauge == null or combo_tracker == null:
		return available
	
	for attack in available_link_attacks:
		if attack.condition.check(link_gauge.current, combo_tracker.count, alive_teammates):
			available.append(attack)
	
	return available

## AC-4: 连携条件判定正确
func _check_link_conditions():
	"""检查连携条件是否满足。"""
	if current_link_condition == null:
		return
	
	var alive_teammates = _count_alive_teammates()
	var is_available = current_link_condition.check(
		link_gauge.current,
		combo_tracker.count,
		alive_teammates
	)
	
	link_condition_changed.emit(is_available)

## 设置连携条件
func set_link_condition(condition: LinkCondition):
	"""
	设置连携条件。
	
	参数:
	- condition: 连携条件
	"""
	current_link_condition = condition
	_check_link_conditions()

## 获取活着的队友数量
func _count_alive_teammates() -> int:
	"""获取活着的队友数量。"""
	if combat_system == null or participants.is_empty():
		return 0
	
	var count = 0
	for participant in participants:
		if participant:
			count += 1
	
	return count

## 设置默认的连携攻击
func _setup_default_link_attacks():
	"""设置默认的连携攻击。"""
	# 追击攻击（消耗 50 连携槽）
	var follow_up_condition = LinkCondition.new(50.0, 3, 1)
	var follow_up = LinkAttack.new(
		LinkAttackType.FOLLOW_UP,
		"追击",
		50.0,
		1.5,
		follow_up_condition
	)
	available_link_attacks.append(follow_up)
	
	# 合体技（消耗 100 连携槽）
	var dual_tech_condition = LinkCondition.new(100.0, 5, 2)
	var dual_tech = LinkAttack.new(
		LinkAttackType.DUAL_TECH,
		"合体技",
		100.0,
		2.5,
		dual_tech_condition
	)
	available_link_attacks.append(dual_tech)

## 重置连携系统
func reset():
	"""重置连携系统状态。"""
	if link_gauge:
		link_gauge.reset()
	if combo_tracker:
		combo_tracker.reset()
	link_gauge_changed.emit(0.0, 100.0)
	combo_count_changed.emit(0, 1.0)