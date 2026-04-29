# 武侠奇遇录 - 弱点打击系统
# 实现属性克制系统、弱点打击判定、击倒机制和总攻击触发
#
# 设计原则（来自 ADR-001）：
# - 使用节点系统和信号系统
# - 依赖注入模式传递系统引用
# - 业务逻辑与 UI 分离
# - 使用信号驱动系统间通信

extends Node

## 属性枚举（五行属性）
enum Element {
	METAL,    # 金
	WOOD,     # 木
	WATER,    # 水
	FIRE,     # 火
	EARTH     # 土
}

## 属性克制关系
## 金克木、木克土、土克水、水克火、火克金
const ELEMENT_WEAKNESS = {
	Element.METAL: Element.WOOD,   # 金克木
	Element.WOOD: Element.EARTH,   # 木克土
	Element.EARTH: Element.WATER,  # 土克水
	Element.WATER: Element.FIRE,   # 水克火
	Element.FIRE: Element.METAL    # 火克金
}

## 弱点打击伤害倍率
const WEAKNESS_DAMAGE_MULTIPLIER = 1.5
const NORMAL_DAMAGE_MULTIPLIER = 1.0

## 击倒状态易伤倍率
const DOWN_VULNERABILITY_MULTIPLIER = 1.5

## 弱点信息类
class WeaknessInfo:
	var element: int              # 弱点属性
	var is_exposed: bool = false  # 弱点是否暴露
	
	func _init(elem: int, exposed: bool = false):
		element = elem
		is_exposed = exposed

## 弱点打击结果类
class WeaknessHitResult:
	var is_weakness_hit: bool = false
	var damage_multiplier: float = 1.0
	var triggered_down: bool = false
	
	func _init(is_hit: bool = false, multiplier: float = 1.0, down: bool = false):
		is_weakness_hit = is_hit
		damage_multiplier = multiplier
		triggered_down = down

# 信号定义
signal weakness_hit(attacker: Node, target: Node, result: WeaknessHitResult)
signal down_triggered(target: Node)
signal down_cleared(target: Node)
signal all_out_attack_available
signal all_out_attack_unavailable

# 弱点系统数据
var combat_system: Node = null  # 引用战斗系统
var participant_weaknesses: Dictionary = {}  # 参与者弱点信息
var participant_down_status: Dictionary = {}  # 参与者击倒状态

func _ready():
	pass

## 初始化弱点系统
func initialize(combat_sys: Node):
	"""
	初始化弱点系统。
	
	参数:
	- combat_sys: 战斗系统引用
	"""
	combat_system = combat_sys
	participant_weaknesses.clear()
	participant_down_status.clear()

## 为参与者设置弱点
func set_participant_weakness(participant, element: int, exposed: bool = false):
	"""
	为参与者设置弱点属性。
	
	参数:
	- participant: 参与者对象
	- element: 弱点属性（Element 枚举值）
	- exposed: 弱点是否暴露
	"""
	participant_weaknesses[participant] = WeaknessInfo.new(element, exposed)

## 获取参与者弱点
func get_participant_weakness(participant) -> WeaknessInfo:
	"""
	获取参与者的弱点信息。
	"""
	if participant in participant_weaknesses:
		return participant_weaknesses[participant]
	return null

## 暴露弱点
func expose_weakness(participant):
	"""
	暴露参与者的弱点。
	"""
	if participant in participant_weaknesses:
		participant_weaknesses[participant].is_exposed = true

## 隐藏弱点
func hide_weakness(participant):
	"""
	隐藏参与者的弱点。
	"""
	if participant in participant_weaknesses:
		participant_weaknesses[participant].is_exposed = false

## AC-1: 属性克制系统正确实现
func check_elemental_weakness(attacker_element: int, target_element: int) -> bool:
	"""
	检查攻击属性是否克制目标属性。
	
	参数:
	- attacker_element: 攻击者属性
	- target_element: 目标属性
	
	返回: 是否克制
	"""
	if attacker_element in ELEMENT_WEAKNESS:
		return ELEMENT_WEAKNESS[attacker_element] == target_element
	return false

## AC-2: 弱点打击判定正常工作
func calculate_weakness_hit(attacker, target, attacker_element: int) -> WeaknessHitResult:
	"""
	计算弱点打击效果。
	
	参数:
	- attacker: 攻击者
	- target: 目标
	- attacker_element: 攻击属性
	
	返回: 弱点打击结果
	"""
	var result = WeaknessHitResult.new()
	
	# 获取目标弱点
	var target_weakness = get_participant_weakness(target)
	if target_weakness == null:
		result.damage_multiplier = NORMAL_DAMAGE_MULTIPLIER
		return result
	
	# 检查弱点是否暴露
	if not target_weakness.is_exposed:
		result.damage_multiplier = NORMAL_DAMAGE_MULTIPLIER
		return result
	
	# 检查属性克制
	if check_elemental_weakness(attacker_element, target_weakness.element):
		result.is_weakness_hit = true
		result.damage_multiplier = WEAKNESS_DAMAGE_MULTIPLIER
		
		# 触发击倒
		result.triggered_down = true
		trigger_down(target)
	else:
		result.damage_multiplier = NORMAL_DAMAGE_MULTIPLIER
	
	# 发射信号
	weakness_hit.emit(attacker, target, result)
	
	return result

## AC-3: 击倒机制正常
func trigger_down(participant):
	"""
	触发参与者的击倒状态。
	
	参数:
	- participant: 参与者
	"""
	if participant not in participant_down_status:
		participant_down_status[participant] = true
		down_triggered.emit(participant)
		
		# 检查是否所有敌人都被击倒
		check_all_out_attack_availability()

## 清除击倒状态
func clear_down(participant):
	"""
	清除参与者的击倒状态。
	
	参数:
	- participant: 参与者
	"""
	if participant in participant_down_status:
		participant_down_status.erase(participant)
		down_cleared.emit(participant)
		
		# 检查是否所有敌人都被击倒
		check_all_out_attack_availability()

## 检查参与者是否处于击倒状态
func is_down(participant) -> bool:
	"""
	检查参与者是否处于击倒状态。
	"""
	return participant in participant_down_status

## 获取击倒状态下的伤害倍率
func get_down_damage_multiplier(participant) -> float:
	"""
	获取击倒状态下的伤害倍率（易伤）。
	
	参数:
	- participant: 参与者
	
	返回: 伤害倍率
	"""
	if is_down(participant):
		return DOWN_VULNERABILITY_MULTIPLIER
	return 1.0

## AC-4: 总攻击触发条件正确
func check_all_out_attack_availability() -> bool:
	"""
	检查是否可以发动总攻击。
	
	总攻击条件：所有敌人都处于击倒状态
	
	返回: 是否可以发动总攻击
	"""
	if combat_system == null:
		return false
	
	# 获取所有参与者
	var participants = combat_system.participants
	if participants.is_empty():
		return false
	
	# 检查是否所有参与者都被击倒
	var all_down = true
	for participant in participants:
		if not is_down(participant):
			all_down = false
			break
	
	# 发射信号
	if all_down:
		all_out_attack_available.emit()
	else:
		all_out_attack_unavailable.emit()
	
	return all_down

## 获取总攻击可用状态
func is_all_out_attack_available() -> bool:
	"""
	获取总攻击是否可用。
	"""
	return check_all_out_attack_availability()

## 重置弱点系统
func reset():
	"""
	重置弱点系统状态。
	"""
	participant_weaknesses.clear()
	participant_down_status.clear()