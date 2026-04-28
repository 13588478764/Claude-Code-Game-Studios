# HealthPoiseManager
# 管理生命值和架势值的系统，实现生命值和架势值机制

extends Node

# 信号定义
signal hp_changed(current: int, max: int)
signal poise_changed(current: int, max: int)
signal break_triggered()
signal death_triggered()
signal status_changed(new_status: String)

# 常量定义
const STATUS_NORMAL = "normal"
const STATUS_DEFENDING = "defending"
const STATUS_BREAK = "break"
const STATUS_CRITICAL = "critical"
const STATUS_DEAD = "dead"

# 生命值相关属性
var current_hp: int
var max_hp: int
var base_hp: int = 100

# 架势值相关属性
var current_poise: int
var max_poise: int
var base_poise: int = 50

# 角色属性
var con_stat: int = 10  # 根骨
var wil_stat: int = 10  # 定力
var agi_stat: int = 10  # 身法

# 装备加成
var equipment_hp_bonus: int = 0
var equipment_poise_bonus: int = 0

# 状态相关
var status: String = STATUS_NORMAL
var break_duration: int = 1  # 破防持续回合数
var break_timer: int = 0
var is_in_combat: bool = false

# 系统引用
var equipment_system = null
var character_progression_system = null

# 破防伤害加成系数
var break_multiplier: float = 1.5

# 初始化
func _ready():
	# 初始化生命值和架势值
	max_hp = calculate_max_hp()
	current_hp = max_hp
	
	max_poise = calculate_max_poise()
	current_poise = max_poise

# 计算最大生命值
func calculate_max_hp() -> int:
	var hp_coefficient: float = 2.0  # 每点根骨提供的生命值加成
	var calculated_max_hp: int = base_hp + con_stat * hp_coefficient + equipment_hp_bonus
	
	# 限制在GDD定义的范围内
	return clamp(calculated_max_hp, 100, 2000)

# 计算最大架势值
func calculate_max_poise() -> int:
	var poise_coefficient: float = 1.5  # 每点定力提供的架势值加成
	var calculated_max_poise: int = base_poise + wil_stat * poise_coefficient + equipment_poise_bonus
	
	# 限制在GDD定义的范围内
	return clamp(calculated_max_poise, 50, 800)

# 应用伤害到生命值
func apply_damage_to_hp(damage: int) -> int:
	if status == STATUS_DEAD:
		return 0
	
	# 确保伤害至少为1
	damage = max(damage, 1)
	
	# 应用伤害
	current_hp -= damage
	
	# 确保生命值不低于0
	current_hp = max(current_hp, 0)
	
	# 发射HP变化信号
	emit_signal("hp_changed", current_hp, max_hp)
	
	# 检查是否死亡
	if current_hp == 0:
		trigger_death()
		return 0
	
	# 检查是否进入濒死状态
	if current_hp < max_hp * 0.1:
		if status != STATUS_CRITICAL:
			status = STATUS_CRITICAL
			emit_signal("status_changed", STATUS_CRITICAL)
	
	return damage

# 应用伤害到架势值
func apply_damage_to_poise(damage: int, is_heavy_attack: bool = false) -> int:
	if status == STATUS_DEAD:
		return 0
	
	# 重攻击对架势值造成额外伤害
	if is_heavy_attack:
		damage = int(damage * 1.5)
	
	# 应用伤害
	current_poise -= damage
	
	# 确保架势值不低于0
	current_poise = max(current_poise, 0)
	
	# 发射Poise变化信号
	emit_signal("poise_changed", current_poise, max_poise)
	
	# 检查是否触发破防
	if current_poise == 0:
		trigger_break_state()
	
	return damage

# 触发破防状态
func trigger_break_state():
	if status == STATUS_DEAD:
		return
	
	status = STATUS_BREAK
	break_timer = break_duration
	
	emit_signal("break_triggered")
	emit_signal("status_changed", STATUS_BREAK)
	
	# 破防时无法行动，伤害增加

# 触发死亡状态
func trigger_death():
	status = STATUS_DEAD
	emit_signal("death_triggered")
	emit_signal("status_changed", STATUS_DEAD)

# 恢复架势值
func restore_poise(amount: int):
	if status == STATUS_DEAD:
		return
	
	current_poise = min(current_poise + amount, max_poise)
	emit_signal("poise_changed", current_poise, max_poise)

# 战斗回合结束时的处理
func on_turn_end():
	# 正常状态下，回合结束时恢复20%架势值
	if status == STATUS_NORMAL or status == STATUS_CRITICAL:
		var recovery_amount = int(max_poise * 0.2)
		restore_poise(recovery_amount)
	
	# 破防状态计时
	if status == STATUS_BREAK:
		break_timer -= 1
		if break_timer <= 0:
			status = STATUS_NORMAL
			# 破防结束后重置架势值为0
			current_poise = 0
			emit_signal("status_changed", STATUS_NORMAL)
			emit_signal("poise_changed", current_poise, max_poise)

# 选择防御指令时的处理
func on_defend_action():
	if status == STATUS_DEAD:
		return
	
	status = STATUS_DEFENDING
	var recovery_amount = int(max_poise * 0.5)  # 防御时恢复50%架势值
	restore_poise(recovery_amount)

# 战斗开始
func start_combat():
	is_in_combat = true
	status = STATUS_NORMAL

# 战斗结束
func end_combat():
	is_in_combat = false
	# 战斗外恢复机制不在这里处理，由RecoveryStatusManager处理

# 获取当前状态信息
func get_status_info() -> Dictionary:
	return {
		"current_hp": current_hp,
		"max_hp": max_hp,
		"current_poise": current_poise,
		"max_poise": max_poise,
		"status": status,
		"is_in_combat": is_in_combat
	}

# 检查是否处于破防状态
func is_in_break_state() -> bool:
	return status == STATUS_BREAK

# 检查是否处于濒死状态
func is_in_critical_state() -> bool:
	return status == STATUS_CRITICAL

# 检查是否死亡
func is_dead() -> bool:
	return status == STATUS_DEAD

# 处理破防后受到的伤害
func apply_damage_after_break(damage: int) -> int:
	var amplified_damage = int(damage * break_multiplier)
	return apply_damage_to_hp(amplified_damage)