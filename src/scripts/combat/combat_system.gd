## CombatSystem
## 武侠奇遇录 - 战斗系统核心
##
## 实现回合制战斗机制、战斗资源系统、战斗状态管理和战斗流程阶段划分。
##
## 设计原则（来自 ADR-001）：
## - 使用节点系统和信号系统
## - 依赖注入模式传递系统引用
## - 业务逻辑与 UI 分离
## - 使用信号驱动系统间通信
##
## 依赖关系：
## - CombatParticipant: 战斗参与者数据结构
## - CombatResource: 战斗资源管理
##
## 主要功能：
## - 回合制战斗机制（行动队列、回合管理）
## - 战斗资源系统（内力、架势、连击、连携）
## - 战斗状态管理（正常、击倒、破防、眩晕）
## - 战斗流程阶段划分（遭遇、输入、执行、敌方、结束）

extends Node

class_name CombatSystem

# ============================================================================
# 常量定义
# ============================================================================

## 内力自然恢复百分比（默认 5%）
const QI_RECOVERY_PERCENTAGE: float = 0.05

## 内力自然恢复百分比上限（最高 10%）
const QI_RECOVERY_PERCENTAGE_MAX: float = 0.10

## 连击伤害加成单位（每次连击增加 1%）
const COMBO_DAMAGE_INCREMENT: float = 0.01

## 连击伤害加成上限（最高 30%）
const MAX_COMBO_DAMAGE_BONUS: float = 0.30

## 破防状态伤害加成（50%）
const BREAK_DAMAGE_BONUS: float = 0.50

## 默认内力上限
const DEFAULT_QI_MAX: int = 100

## 默认架势上限
const DEFAULT_POISE_MAX: int = 80

## 默认连携槽上限
const DEFAULT_LINK_GAUGE_MAX: int = 100

# ============================================================================
# 枚举定义
# ============================================================================

## 战斗状态枚举
enum CombatState {
	NORMAL,      ## 正常状态
	DOWN,        ## 击倒状态（跳过下回合）
	BREAK,       ## 破防状态（本回合禁动，伤害+50%）
	STUN         ## 眩晕状态（无法行动）
}

## 战斗阶段枚举
enum CombatPhase {
	ENCOUNTER,   ## 遭遇阶段
	INPUT,       ## 指令输入阶段
	EXECUTION,   ## 执行演出阶段
	ENEMY,       ## 敌方回合
	END          ## 回合结束
}

# ============================================================================
# 内部类定义
# ============================================================================

## 战斗资源类
class CombatResource:
	## 内力上限
	var qi_max: int = DEFAULT_QI_MAX
	
	## 当前内力
	var qi_current: int = DEFAULT_QI_MAX
	
	## 架势上限
	var poise_max: int = DEFAULT_POISE_MAX
	
	## 当前架势
	var poise_current: int = DEFAULT_POISE_MAX
	
	## 连击数
	var combo_count: int = 0
	
	## 连携槽（0-100）
	var link_gauge: int = 0
	
	## 连携槽上限
	var link_gauge_max: int = DEFAULT_LINK_GAUGE_MAX
	
	## 构造函数
	## @param qi_max_val: 内力上限
	## @param poise_max_val: 架势上限
	func _init(qi_max_val: int = DEFAULT_QI_MAX, poise_max_val: int = DEFAULT_POISE_MAX) -> void:
		qi_max = qi_max_val
		qi_current = qi_max_val
		poise_max = poise_max_val
		poise_current = poise_max_val
	
	## 消耗内力
	## @param amount: 消耗量
	## @return 是否成功消耗
	func consume_qi(amount: int) -> bool:
		if qi_current >= amount:
			qi_current -= amount
			return true
		return false
	
	## 恢复内力（每回合结束自动恢复 5%-10%）
	## @param percentage: 恢复百分比
	func recover_qi(percentage: float = QI_RECOVERY_PERCENTAGE) -> void:
		var recovery: int = int(qi_max * percentage)
		qi_current = min(qi_current + recovery, qi_max)
	
	## 受到架势伤害
	## @param amount: 伤害量
	func take_poise_damage(amount: int) -> void:
		poise_current = max(0, poise_current - amount)
	
	## 恢复架势
	## @param amount: 恢复量
	func recover_poise(amount: int) -> void:
		poise_current = min(poise_current + amount, poise_max)
	
	## 增加连击数
	func increment_combo() -> void:
		combo_count += 1
	
	## 重置连击数
	func reset_combo() -> void:
		combo_count = 0
	
	## 增加连携槽
	## @param amount: 增加量
	func add_link_gauge(amount: int) -> void:
		link_gauge = min(link_gauge + amount, link_gauge_max)
	
	## 检查是否破防（架势为0）
	## @return 是否破防
	func is_broken() -> bool:
		return poise_current == 0
	
	## 获取连击伤害倍率（最高+30%）
	## @return 连击伤害倍率
	func get_combo_damage_multiplier() -> float:
		return 1.0 + min(float(combo_count) * COMBO_DAMAGE_INCREMENT, MAX_COMBO_DAMAGE_BONUS)

## 战斗参与者类
class CombatParticipant:
	## 参与者名称
	var name: String
	
	## 身法属性
	var agility: int
	
	## 战斗状态
	var state: CombatState = CombatState.NORMAL
	
	## 战斗资源
	var resources: CombatResource
	
	## 行动队列中的位置
	var action_order: int = 0
	
	## 构造函数
	## @param participant_name: 参与者名称
	## @param agi: 身法属性
	## @param qi_max: 内力上限
	## @param poise_max: 架势上限
	func _init(participant_name: String, agi: int, qi_max: int = DEFAULT_QI_MAX, poise_max: int = DEFAULT_POISE_MAX) -> void:
		name = participant_name
		agility = agi
		resources = CombatResource.new(qi_max, poise_max)
	
	## 检查是否可以行动
	## @return 是否可以行动
	func can_act() -> bool:
		return state != CombatState.DOWN and state != CombatState.STUN

# ============================================================================
# 信号定义
# ============================================================================

## 战斗开始信号
signal combat_started()

## 战斗结束信号
signal combat_ended()

## 阶段改变信号
signal phase_changed(new_phase: CombatPhase)

## 行动队列生成信号
signal turn_order_generated(order: Array)

## 参与者状态改变信号
signal participant_state_changed(participant: CombatParticipant, new_state: CombatState)

## 资源改变信号
signal resources_changed(participant: CombatParticipant)

# ============================================================================
# 成员变量
# ============================================================================

## 战斗参与者列表
var participants: Array[CombatParticipant] = []

## 行动队列
var turn_order: Array[CombatParticipant] = []

## 当前战斗阶段
var current_phase: CombatPhase = CombatPhase.ENCOUNTER

## 当前回合索引
var current_turn_index: int = 0

## 战斗是否激活
var is_combat_active: bool = false

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化战斗系统
func _ready() -> void:
	_initialize_combat_system()

## 初始化战斗系统
func _initialize_combat_system() -> void:
	print("CombatSystem: 战斗系统已初始化")

# ============================================================================
# 战斗初始化
# ============================================================================

## 初始化战斗
func initialize() -> void:
	participants.clear()
	turn_order.clear()
	current_phase = CombatPhase.ENCOUNTER
	current_turn_index = 0
	is_combat_active = false

## 添加战斗参与者
## @param name: 参与者名称
## @param agility: 身法属性
## @param qi_max: 内力上限
## @param poise_max: 架势上限
## @return 创建的战斗参与者
func add_participant(name: String, agility: int, qi_max: int = DEFAULT_QI_MAX, poise_max: int = DEFAULT_POISE_MAX) -> CombatParticipant:
	var participant: CombatParticipant = CombatParticipant.new(name, agility, qi_max, poise_max)
	participants.append(participant)
	return participant

# ============================================================================
# 行动队列管理
# ============================================================================

## 生成行动队列（根据身法属性排序）
## AC-1: 回合制战斗机制 - 行动顺序
## @return 行动队列
func generate_turn_order() -> Array[CombatParticipant]:
	turn_order = participants.duplicate()
	
	# 按身法从高到低排序
	turn_order.sort_custom(func(a: CombatParticipant, b: CombatParticipant) -> bool: return a.agility > b.agility)
	
	# 设置行动顺序
	for i in range(turn_order.size()):
		turn_order[i].action_order = i
	
	emit_signal("turn_order_generated", turn_order)
	return turn_order

## 获取行动队列
## @return 行动队列
func get_turn_order() -> Array[CombatParticipant]:
	return turn_order

# ============================================================================
# 战斗流程管理
# ============================================================================

## 开始战斗
func start_combat() -> void:
	is_combat_active = true
	generate_turn_order()
	set_phase(CombatPhase.ENCOUNTER)
	emit_signal("combat_started")

## 结束战斗
func end_combat() -> void:
	is_combat_active = false
	emit_signal("combat_ended")

# ============================================================================
# 战斗阶段管理
# ============================================================================

## 设置战斗阶段
## AC-4: 战斗流程阶段划分
## @param new_phase: 新阶段
func set_phase(new_phase: CombatPhase) -> void:
	current_phase = new_phase
	emit_signal("phase_changed", new_phase)

## 获取当前阶段
## @return 当前阶段
func get_current_phase() -> CombatPhase:
	return current_phase

## 进入指令输入阶段
func enter_input_phase() -> void:
	set_phase(CombatPhase.INPUT)

## 进入执行演出阶段
func enter_execution_phase() -> void:
	set_phase(CombatPhase.EXECUTION)

## 进入敌方回合
func enter_enemy_phase() -> void:
	set_phase(CombatPhase.ENEMY)

## 结束回合
func end_turn() -> void:
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

# ============================================================================
# 战斗状态管理
# ============================================================================

## 设置参与者状态
## AC-3: 战斗状态管理
## @param participant: 战斗参与者
## @param new_state: 新状态
func set_participant_state(participant: CombatParticipant, new_state: CombatState) -> void:
	if participant.state != new_state:
		participant.state = new_state
		emit_signal("participant_state_changed", participant, new_state)

## 获取参与者状态
## @param participant: 战斗参与者
## @return 战斗状态
func get_participant_state(participant: CombatParticipant) -> CombatState:
	return participant.state

# ============================================================================
# 资源管理
# ============================================================================

## 处理架势伤害并检查破防
## @param participant: 战斗参与者
## @param damage: 架势伤害
func apply_poise_damage(participant: CombatParticipant, damage: int) -> void:
	participant.resources.take_poise_damage(damage)
	emit_signal("resources_changed", participant)
	
	# 检查是否破防
	if participant.resources.is_broken():
		set_participant_state(participant, CombatState.BREAK)

## 消耗内力
## @param participant: 战斗参与者
## @param amount: 消耗量
## @return 是否成功消耗
func consume_qi(participant: CombatParticipant, amount: int) -> bool:
	var success: bool = participant.resources.consume_qi(amount)
	if success:
		emit_signal("resources_changed", participant)
	return success

## 增加连击数
## @param participant: 战斗参与者
func increment_combo(participant: CombatParticipant) -> void:
	participant.resources.increment_combo()
	emit_signal("resources_changed", participant)

## 重置连击数
## @param participant: 战斗参与者
func reset_combo(participant: CombatParticipant) -> void:
	participant.resources.reset_combo()
	emit_signal("resources_changed", participant)

## 增加连携槽
## @param participant: 战斗参与者
## @param amount: 增加量
func add_link_gauge(participant: CombatParticipant, amount: int) -> void:
	participant.resources.add_link_gauge(amount)
	emit_signal("resources_changed", participant)

## 获取参与者的战斗资源
## @param participant: 战斗参与者
## @return 战斗资源
func get_resources(participant: CombatParticipant) -> CombatResource:
	return participant.resources
