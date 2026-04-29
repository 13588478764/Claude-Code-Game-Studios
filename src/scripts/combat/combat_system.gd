## CombatSystem
## combat system
##
## 战斗系统模块

# 武侠奇遇录 - 战斗系统核心
# 实现回合制战斗机制、战斗资源系统、战斗状态管理和战斗流程阶段划分
#
# 设计原则（来自 ADR-001）：
# - 使用节点系统和信号系统
# - 依赖注入模式传递系统引用
# - 业务逻辑与 UI 分离
# - 使用信号驱动系统间通信

extends Node
class_name CombatSystem

## 战斗状态枚举
enum CombatState {
	NORMAL,      # 正常状态
	DOWN,        # 击倒状态（跳过下回合）
	BREAK,       # 破防状态（本回合禁动，伤害+50%）
	STUN         # 眩晕状态（无法行动）
}

## 战斗阶段枚举
enum CombatPhase {
	ENCOUNTER,   # 遭遇阶段
	INPUT,       # 指令输入阶段
	EXECUTION,   # 执行演出阶段
	ENEMY,       # 敌方回合
	END          # 回合结束
}

## 战斗资源类
class CombatResource:
	var qi_max: int = 100           # 内力上限
	var qi_current: int = 100       # 当前内力
	var poise_max: int = 80         # 架势上限
	var poise_current: int = 80     # 当前架势
	var combo_count: int = 0        # 连击数
	var link_gauge: int = 0         # 连携槽（0-100）
	var link_gauge_max: int = 100   # 连携槽上限
	
	func _init(qi_max_val: int = 100, poise_max_val: int = 80):
		qi_max = qi_max_val
		qi_current = qi_max_val
		poise_max = poise_max_val
		poise_current = poise_max_val
	
	## 消耗内力
	func consume_qi(amount: int) -> bool:
		if qi_current >= amount:
			qi_current -= amount
			return true
		return false
	
	## 恢复内力（每回合结束自动恢复 5%-10%）
	func recover_qi(percentage: float = 0.05):
		var recovery = int(qi_max * percentage)
		qi_current = min(qi_current + recovery, qi_max)
	
	## 受到架势伤害
	func take_poise_damage(amount: int):
		poise_current = max(0, poise_current - amount)
	
	## 恢复架势
	func recover_poise(amount: int):
		poise_current = min(poise_current + amount, poise_max)
	
	## 增加连击数
	func increment_combo():
		combo_count += 1
	
	## 重置连击数
	func reset_combo():
		combo_count = 0
	
	## 增加连携槽
	func add_link_gauge(amount: int):
		link_gauge = min(link_gauge + amount, link_gauge_max)
	
	## 检查是否破防（架势为0）
	func is_broken() -> bool:
		return poise_current == 0
	
	## 获取连击伤害倍率（最高+30%）
	func get_combo_damage_multiplier() -> float:
		return 1.0 + min(combo_count * 0.01, 0.30)

## 战斗参与者类
class CombatParticipant:
	var name: String
	var agility: int                # 身法属性
	var state: CombatState = CombatState.NORMAL
	var resources: CombatResource
	var action_order: int = 0       # 行动队列中的位置
	
	func _init(participant_name: String, agi: int, qi_max: int = 100, poise_max: int = 80):
		name = participant_name
		agility = agi
		resources = CombatResource.new(qi_max, poise_max)
	
	## 检查是否可以行动
	func can_act() -> bool:
		return state != CombatState.DOWN and state != CombatState.STUN

# ============================================================================
# 信号定义
# ============================================================================
signal combat_started
signal combat_ended
signal phase_changed(new_phase: CombatPhase)
signal turn_order_generated(order: Array)
signal participant_state_changed(participant: CombatParticipant, new_state: CombatState)
signal resources_changed(participant: CombatParticipant)

# 战斗数据
var participants: Array[CombatParticipant] = []
var turn_order: Array[CombatParticipant] = []
var current_phase: CombatPhase = CombatPhase.ENCOUNTER
var current_turn_index: int = 0
var is_combat_active: bool = false

func _ready():
	pass

## 初始化战斗系统
func initialize():
	participants.clear()
	turn_order.clear()
	current_phase = CombatPhase.ENCOUNTER
	current_turn_index = 0
	is_combat_active = false

## 添加战斗参与者
func add_participant(name: String, agility: int, qi_max: int = 100, poise_max: int = 80) -> CombatParticipant:
	var participant = CombatParticipant.new(name, agility, qi_max, poise_max)
	participants.append(participant)
	return participant

## 生成行动队列（根据身法属性排序）
## AC-1: 回合制战斗机制 - 行动顺序
func generate_turn_order() -> Array[CombatParticipant]:
	"""
	根据身法属性生成行动队列。
	身法越高，在队列中的位置越靠前。
	"""
	turn_order = participants.duplicate()
	
	# 按身法从高到低排序
	turn_order.sort_custom(func(a, b): return a.agility > b.agility)
	
	# 设置行动顺序
	for i in range(turn_order.size()):
		turn_order[i].action_order = i
	
	turn_order_generated.emit(turn_order)
	return turn_order

## 获取行动队列
func get_turn_order() -> Array[CombatParticipant]:
	return turn_order

## 开始战斗
func start_combat():
	"""
	开始战斗流程：
	1. 生成行动队列
	2. 进入遭遇阶段
	3. 发射战斗开始信号
	"""
	is_combat_active = true
	generate_turn_order()
	set_phase(CombatPhase.ENCOUNTER)
	combat_started.emit()

## 设置战斗阶段
## AC-4: 战斗流程阶段划分
func set_phase(new_phase: CombatPhase):
	"""
	设置战斗阶段。
	不同阶段有不同的游戏状态：
	- ENCOUNTER: 遭遇阶段
	- INPUT: 指令输入阶段（时间暂停）
	- EXECUTION: 执行演出阶段
	- ENEMY: 敌方回合
	- END: 回合结束
	"""
	current_phase = new_phase
	phase_changed.emit(new_phase)

## 获取当前阶段
func get_current_phase() -> CombatPhase:
	return current_phase

## 进入指令输入阶段
func enter_input_phase():
	"""
	进入指令输入阶段。
	此时应该暂停游戏时间，允许玩家选择指令。
	"""
	set_phase(CombatPhase.INPUT)

## 进入执行演出阶段
func enter_execution_phase():
	"""
	进入执行演出阶段。
	此时应该恢复游戏时间，执行选定的指令。
	"""
	set_phase(CombatPhase.EXECUTION)

## 进入敌方回合
func enter_enemy_phase():
	"""
	进入敌方回合。
	敌人执行其 AI 决策的行动。
	"""
	set_phase(CombatPhase.ENEMY)

## 结束回合
func end_turn():
	"""
	结束当前回合。
	执行回合结束逻辑：
	1. 恢复所有参与者的内力
	2. 清除临时状态（如 DOWN）
	3. 生成下一回合的行动队列
	"""
	set_phase(CombatPhase.END)
	
	# 恢复内力和清除状态
	for participant in participants:
		participant.resources.recover_qi()
		
		# 清除 DOWN 状态
		if participant.state == CombatState.DOWN:
			set_participant_state(participant, CombatState.NORMAL)
	
	# 生成下一回合的行动队列
	generate_turn_order()
	current_turn_index = 0

## 设置参与者状态
## AC-3: 战斗状态管理
func set_participant_state(participant: CombatParticipant, new_state: CombatState):
	"""
	设置参与者的战斗状态。
	状态转换规则：
	- Normal: 正常状态
	- Down: 击倒状态（跳过下回合）
	- Break: 破防状态（本回合禁动，伤害+50%）
	- Stun: 眩晕状态（无法行动）
	"""
	if participant.state != new_state:
		participant.state = new_state
		participant_state_changed.emit(participant, new_state)

## 获取参与者状态
func get_participant_state(participant: CombatParticipant) -> CombatState:
	return participant.state

## 处理架势伤害并检查破防
func apply_poise_damage(participant: CombatParticipant, damage: int):
	"""
	对参与者造成架势伤害。
	如果架势归零，进入 Break 状态。
	"""
	participant.resources.take_poise_damage(damage)
	resources_changed.emit(participant)
	
	# 检查是否破防
	if participant.resources.is_broken():
		set_participant_state(participant, CombatState.BREAK)

## 消耗内力
func consume_qi(participant: CombatParticipant, amount: int) -> bool:
	"""
	消耗参与者的内力。
	如果内力不足，返回 false。
	"""
	var success = participant.resources.consume_qi(amount)
	if success:
		resources_changed.emit(participant)
	return success

## 增加连击数
func increment_combo(participant: CombatParticipant):
	"""
	增加参与者的连击数。
	"""
	participant.resources.increment_combo()
	resources_changed.emit(participant)

## 重置连击数
func reset_combo(participant: CombatParticipant):
	"""
	重置参与者的连击数。
	"""
	participant.resources.reset_combo()
	resources_changed.emit(participant)

## 增加连携槽
func add_link_gauge(participant: CombatParticipant, amount: int):
	"""
	增加参与者的连携槽。
	"""
	participant.resources.add_link_gauge(amount)
	resources_changed.emit(participant)

## 获取参与者的战斗资源
func get_resources(participant: CombatParticipant) -> CombatResource:
	return participant.resources

## 结束战斗
func end_combat():
	"""
	结束战斗。
	"""
	is_combat_active = false
	combat_ended.emit()