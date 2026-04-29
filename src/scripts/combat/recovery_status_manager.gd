## RecoveryStatusManager
## recovery status manager
##
## 战斗系统模块

# RecoveryStatusManager
# 管理恢复和状态效果的系统，实现战斗内外恢复机制和状态效果管理

extends Node
class_name RecoveryStatusManager

# ============================================================================
# 信号定义
# ============================================================================
signal hp_recovered(amount: int)
signal poise_recovered(amount: int)
signal status_effect_applied(effect_name: String)
signal status_effect_removed(effect_name: String)
signal rest_point_used()

# ============================================================================
# 常量定义
# ============================================================================

const STATUS_NORMAL = "normal"
const STATUS_DEFENDING = "defending"
const STATUS_BREAK = "break"
const STATUS_CRITICAL = "critical"
const STATUS_DEAD = "dead"

# 战斗内外恢复相关
var is_in_combat: bool = false
var combat_recovery_timer: Timer = null
var out_of_combat_recovery_timer: Timer = null
var recovery_check_interval: float = 1.0  # 恢复检查间隔（秒）

# 恢复速度
var hp_recovery_rate: float = 0.0  # 战斗外HP恢复速度（每秒恢复最大HP的百分比）
var poise_recovery_rate: float = 0.2  # 战斗外Poise恢复速度（每秒恢复最大Poise的20%）

# 状态效果管理
var active_status_effects: Dictionary = {}
var status_effect_timers: Dictionary = {}

# 系统引用
var health_poise_manager = null
var equipment_system = null
var character_progression_system = null

# 初始化
func _ready():
	# 初始化计时器
	combat_recovery_timer = Timer.new()
	combat_recovery_timer.wait_time = recovery_check_interval
	combat_recovery_timer.timeout.connect(_on_combat_recovery_timeout)
	add_child(combat_recovery_timer)
	
	out_of_combat_recovery_timer = Timer.new()
	out_of_combat_recovery_timer.wait_time = recovery_check_interval
	out_of_combat_recovery_timer.timeout.connect(_on_out_of_combat_recovery_timeout)
	add_child(out_of_combat_recovery_timer)

# 战斗内恢复处理器
func combat_recovery_handler():
	# 架势值在回合结束时自动恢复
	# 这个功能由HealthPoiseManager处理
	pass

# 战斗外恢复处理器
func out_of_combat_recovery_handler():
	# 启动战斗外恢复计时器
	if not out_of_combat_recovery_timer.is_stopped():
		out_of_combat_recovery_timer.start()
	
	# 检查是否在战斗外
	if not is_in_combat:
		# 恢复HP和Poise
		_recover_hp_out_of_combat()
		_recover_poise_out_of_combat()

# 休息点恢复处理器
func rest_point_recovery_handler():
	# 完全恢复所有状态
	if health_poise_manager:
		# 恢复到最大值
		var hp_recovery = health_poise_manager.max_hp - health_poise_manager.current_hp
		var poise_recovery = health_poise_manager.max_poise - health_poise_manager.current_poise
		
		if hp_recovery > 0:
			apply_recovery_to_hp(hp_recovery)
		
		if poise_recovery > 0:
			apply_recovery_to_poise(poise_recovery)
		
		# 移除所有临时状态效果
		clear_temporary_status_effects()
		
		emit_signal("rest_point_used")

# 状态效果管理器
func status_effect_manager():
	# 管理所有状态效果的持续时间和移除
	_update_status_effects()

# 应用HP恢复
func apply_recovery_to_hp(amount: int):
	if not health_poise_manager:
		return
	
	# 恢复HP，但不超过最大值
	var new_hp = min(health_poise_manager.current_hp + amount, health_poise_manager.max_hp)
	var recovery_amount = new_hp - health_poise_manager.current_hp
	
	if recovery_amount > 0:
		health_poise_manager.current_hp = new_hp
		emit_signal("hp_recovered", recovery_amount)

# 应用Poise恢复
func apply_recovery_to_poise(amount: int):
	if not health_poise_manager:
		return
	
	# 恢复Poise，但不超过最大值
	var new_poise = min(health_poise_manager.current_poise + amount, health_poise_manager.max_poise)
	var recovery_amount = new_poise - health_poise_manager.current_poise
	
	if recovery_amount > 0:
		health_poise_manager.current_poise = new_poise
		emit_signal("poise_recovered", recovery_amount)

# 战斗恢复计时器回调
func _on_combat_recovery_timeout():
	if is_in_combat:
		# 战斗中只处理状态效果
		_update_status_effects()

# 战斗外恢复计时器回调
func _on_out_of_combat_recovery_timeout():
	if not is_in_combat:
		_recover_hp_out_of_combat()
		_recover_poise_out_of_combat()

# 战斗外HP恢复
func _recover_hp_out_of_combat():
	if not health_poise_manager or health_poise_manager.is_dead():
		return
	
	# 计算恢复量
	var recovery_amount = int(float(health_poise_manager.max_hp) * hp_recovery_rate)
	
	if recovery_amount > 0:
		apply_recovery_to_hp(recovery_amount)

# 战斗外Poise恢复
func _recover_poise_out_of_combat():
	if not health_poise_manager or health_poise_manager.is_dead():
		return
	
	# 计算恢复量
	var recovery_amount = int(float(health_poise_manager.max_poise) * poise_recovery_rate)
	
	if recovery_amount > 0:
		apply_recovery_to_poise(recovery_amount)

# 添加状态效果
func add_status_effect(effect_name: String, duration: float = -1, stacks: int = 1):
	var effect_data = {
		"name": effect_name,
		"duration": duration,
		"remaining_time": duration,
		"stacks": stacks
	}
	
	active_status_effects[effect_name] = effect_data
	
	# 如果有持续时间，创建计时器
	if duration > 0:
		var timer = Timer.new()
		timer.wait_time = duration
		timer.timeout.connect(_on_status_effect_expired.bind(effect_name))
		add_child(timer)
		status_effect_timers[effect_name] = timer
		timer.start()
	
	emit_signal("status_effect_applied", effect_name)

# 移除状态效果
func remove_status_effect(effect_name: String):
	if active_status_effects.has(effect_name):
		var timer = status_effect_timers.get(effect_name)
		if timer:
			if is_instance_valid(timer):
				remove_child(timer)
				timer.queue_free()
			status_effect_timers.erase(effect_name)
		
		active_status_effects.erase(effect_name)
		emit_signal("status_effect_removed", effect_name)

# 状态效果过期回调
func _on_status_effect_expired(effect_name: String):
	remove_status_effect(effect_name)

# 更新状态效果
func _update_status_effects():
	var effects_to_remove = []
	
	for effect_name in active_status_effects:
		var effect_data = active_status_effects[effect_name]
		
		# 如果是永久效果，跳过
		if effect_data.duration < 0:
			continue
		
		# 更新剩余时间
		effect_data.remaining_time -= recovery_check_interval
		
		# 检查是否过期
		if effect_data.remaining_time <= 0:
			effects_to_remove.append(effect_name)
	
	# 移除过期的效果
	for effect_name in effects_to_remove:
		remove_status_effect(effect_name)

# 清除临时状态效果
func clear_temporary_status_effects():
	var effects_to_clear = []
	
	for effect_name in active_status_effects:
		# 不清除永久性状态（如死亡状态）
		if effect_name != STATUS_DEAD:
			effects_to_clear.append(effect_name)
	
	for effect_name in effects_to_clear:
		remove_status_effect(effect_name)

# 设置战斗状态
func set_combat_state(in_combat: bool):
	is_in_combat = in_combat
	
	if in_combat:
		# 进入战斗：停止战斗外恢复，启动战斗恢复
		if not out_of_combat_recovery_timer.is_stopped():
			out_of_combat_recovery_timer.stop()
		combat_recovery_timer.start()
	else:
		# 离开战斗：停止战斗恢复，启动战斗外恢复
		if not combat_recovery_timer.is_stopped():
			combat_recovery_timer.stop()
		out_of_combat_recovery_timer.start()

# 获取状态效果信息
func get_status_effect_info() -> Dictionary:
	return active_status_effects.duplicate(true)

# 检查是否有特定状态效果
func has_status_effect(effect_name: String) -> bool:
	return active_status_effects.has(effect_name)

# 获取当前恢复状态
func get_recovery_status() -> Dictionary:
	return {
		"is_in_combat": is_in_combat,
		"hp_recovery_rate": hp_recovery_rate,
		"poise_recovery_rate": poise_recovery_rate,
		"active_status_effects": active_status_effects.keys()
	}

# 设置恢复速度
func set_recovery_rates(hp_rate: float, poise_rate: float):
	hp_recovery_rate = hp_rate
	poise_recovery_rate = poise_rate

# 战斗结束处理
func on_combat_end():
	set_combat_state(false)
	
	# 战斗结束后，角色的Poise会逐渐恢复
	if health_poise_manager:
		health_poise_manager.current_poise = health_poise_manager.max_poise