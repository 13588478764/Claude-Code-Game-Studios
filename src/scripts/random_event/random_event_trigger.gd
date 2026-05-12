# 随机事件触发器
# 实现基于移动距离和时间的触发机制，安全区检测，以及预警系统

extends Node

class_name RandomEventTrigger

# 常量定义
const TRIGGER_DISTANCE_THRESHOLD: float = 100.0  # 每移动100个格子进行一次触发判定
const TRIGGER_TIME_THRESHOLD: float = 300.0  # 每5分钟（300秒）进行一次触发判定
const WARNING_TIME: float = 2.5  # 预警时间2.5秒（2-3秒范围内）
const BASE_TRIGGER_PROBABILITY: float = 0.3  # 基础触发概率30%
const LUCK_PROBABILITY_BONUS: float = 0.01  # 福缘属性每点增加1%概率
const COMBAT_PENALTY_COEFFICIENT: float = 0.05  # 连续战斗次数每次减少5%概率

# 安全区类型枚举
enum SafeZoneType {
	NONE,           # 非安全区
	TOWN,           # 城镇
	INN,            # 驿站
	TEMPLE,         # 寺庙
	SAFE_HOUSE      # 安全屋
}

# 信号定义
signal trigger_check_requested(trigger_type: String)  # 请求触发检查
signal event_trigger_warning(warning_time: float)  # 事件触发预警
signal event_trigger_ready(trigger_data: Dictionary)  # 事件准备触发
signal safe_zone_entered(zone_type: SafeZoneType)  # 进入安全区
signal safe_zone_exited(zone_type: SafeZoneType)  # 离开安全区
signal distance_threshold_reached(distance: float)  # 距离阈值达到
signal time_threshold_reached(elapsed_time: float)  # 时间阈值达到

# 距离跟踪
var total_distance_traveled: float = 0.0  # 总移动距离
var distance_since_last_check: float = 0.0  # 上次检查后的移动距离
var last_position: Vector2 = Vector2.ZERO  # 上次记录的位置
var _has_recorded_position: bool = false  # 是否已记录初始位置（避免 last_position == ZERO 假阳性）

# 时间跟踪
var total_time_elapsed: float = 0.0  # 总游戏时间
var time_since_last_check: float = 0.0  # 上次检查后的时间
var is_time_tracking_active: bool = true  # 时间跟踪是否激活

# 安全区检测
var current_safe_zone: SafeZoneType = SafeZoneType.NONE  # 当前安全区类型
var safe_zone_regions: Dictionary = {}  # 安全区域定义 {region_id: SafeZoneType}

# 预警系统
var warning_timer: Timer = null  # 预警计时器
var is_warning_active: bool = false  # 预警是否激活
var pending_trigger_data: Dictionary = {}  # 待触发的事件数据

# 玩家属性（用于触发概率计算）
var player_luck: int = 0  # 玩家福缘属性
var consecutive_combat_count: int = 0  # 连续战斗次数

func _init():
	# 初始化预警计时器
	warning_timer = Timer.new()
	warning_timer.one_shot = true
	warning_timer.timeout.connect(_on_warning_timeout)
	
	# 初始化默认安全区
	_initialize_default_safe_zones()

func _ready():
	# 添加Timer到场景树
	if warning_timer and not warning_timer.is_inside_tree():
		add_child(warning_timer)
	
	# 设置进程模式
	set_process(true)

func _process(delta: float):
	# 更新时间跟踪
	if is_time_tracking_active and current_safe_zone == SafeZoneType.NONE:
		_update_time_tracking(delta)

# 初始化默认安全区
func _initialize_default_safe_zones():
	safe_zone_regions["village"] = SafeZoneType.TOWN
	safe_zone_regions["inn_01"] = SafeZoneType.INN
	safe_zone_regions["temple_01"] = SafeZoneType.TEMPLE

# 更新玩家位置（用于距离跟踪）
func update_player_position(new_position: Vector2):
	# 如果在安全区，不进行距离跟踪
	if current_safe_zone != SafeZoneType.NONE:
		last_position = new_position
		_has_recorded_position = true
		return
	
	# 计算移动距离
	# 修复：之前用 `if last_position != Vector2.ZERO` 检测"是否首次调用"，
	# 但 last_position 默认就是 ZERO，且玩家可能真的从 (0,0) 出发，
	# 这种情况下第二次调用时 last_position == ZERO，会被误判为"首次"，
	# 导致距离永远累计为 0。改用 _has_recorded_position 显式标志位。
	if _has_recorded_position:
		var distance_moved = last_position.distance_to(new_position)
		total_distance_traveled += distance_moved
		distance_since_last_check += distance_moved
		
		# 检查是否达到距离阈值
		if distance_since_last_check >= TRIGGER_DISTANCE_THRESHOLD:
			_on_distance_threshold_reached()
	
	last_position = new_position
	_has_recorded_position = true

# 更新时间跟踪
func _update_time_tracking(delta: float):
	total_time_elapsed += delta
	time_since_last_check += delta
	
	# 检查是否达到时间阈值
	if time_since_last_check >= TRIGGER_TIME_THRESHOLD:
		_on_time_threshold_reached()

# 距离阈值达到处理
func _on_distance_threshold_reached():
	emit_signal("distance_threshold_reached", distance_since_last_check)
	emit_signal("trigger_check_requested", "distance")
	
	# 重置距离计数器
	distance_since_last_check = 0.0
	
	# 执行触发检查
	_perform_trigger_check("distance")

# 时间阈值达到处理
func _on_time_threshold_reached():
	emit_signal("time_threshold_reached", time_since_last_check)
	emit_signal("trigger_check_requested", "time")
	
	# 重置时间计数器
	time_since_last_check = 0.0
	
	# 执行触发检查
	_perform_trigger_check("time")

# 执行触发检查
func _perform_trigger_check(trigger_type: String):
	# 如果在安全区，不触发事件
	if current_safe_zone != SafeZoneType.NONE:
		return
	
	# 如果预警已激活，不重复触发
	if is_warning_active:
		return
	
	# 计算触发概率
	var trigger_probability = calculate_trigger_probability()
	
	# 生成随机数判断是否触发
	var random_value = randf()
	if random_value <= trigger_probability:
		# 触发事件预警
		_start_warning(trigger_type)

# 计算触发概率
# 触发概率公式 = 基础概率 + (福缘属性 × 概率加成) - (连续战斗次数 × 惩罚系数)
func calculate_trigger_probability() -> float:
	var probability = BASE_TRIGGER_PROBABILITY
	probability += player_luck * LUCK_PROBABILITY_BONUS
	probability -= consecutive_combat_count * COMBAT_PENALTY_COEFFICIENT
	
	# 确保概率在0-1范围内
	return clamp(probability, 0.0, 1.0)

# 开始预警
func _start_warning(trigger_type: String):
	is_warning_active = true
	
	# 准备触发数据
	pending_trigger_data = {
		"trigger_type": trigger_type,
		"trigger_time": Time.get_unix_time_from_system(),
		"player_luck": player_luck,
		"consecutive_combat": consecutive_combat_count,
		"trigger_probability": calculate_trigger_probability()
	}
	
	# 发送预警信号
	emit_signal("event_trigger_warning", WARNING_TIME)
	
	# 启动预警计时器
	warning_timer.start(WARNING_TIME)

# 预警超时处理
func _on_warning_timeout():
	is_warning_active = false
	
	# 再次检查是否在安全区（玩家可能在预警期间进入安全区）
	if current_safe_zone != SafeZoneType.NONE:
		pending_trigger_data.clear()
		return
	
	# 发送事件准备触发信号
	# 关键：必须 duplicate(true) 一份再传出去，否则 emit_signal 后立即调用 clear()
	# 会同时清空所有订阅者持有的 Dictionary 引用（GDScript Dictionary 是引用类型）。
	# 之前的 bug：测试中 observation["trigger_data"] 和 pending_trigger_data 指向同一对象，
	# clear() 后两者都变空，导致 has("trigger_type") 失败。
	emit_signal("event_trigger_ready", pending_trigger_data.duplicate(true))
	
	# 清空待触发数据（不会影响已经发出去的拷贝）
	pending_trigger_data.clear()

# 设置当前区域
func set_current_region(region_id: String):
	var new_safe_zone = safe_zone_regions.get(region_id, SafeZoneType.NONE)
	
	# 检查安全区状态变化
	if new_safe_zone != current_safe_zone:
		var old_safe_zone = current_safe_zone
		current_safe_zone = new_safe_zone
		
		if new_safe_zone != SafeZoneType.NONE:
			# 进入安全区
			emit_signal("safe_zone_entered", new_safe_zone)
			
			# 取消预警（如果有）
			if is_warning_active:
				warning_timer.stop()
				is_warning_active = false
				pending_trigger_data.clear()
		else:
			# 离开安全区
			emit_signal("safe_zone_exited", old_safe_zone)

# 检查是否在安全区
func is_in_safe_zone() -> bool:
	return current_safe_zone != SafeZoneType.NONE

# 获取当前安全区类型
func get_current_safe_zone_type() -> SafeZoneType:
	return current_safe_zone

# 添加安全区定义
func add_safe_zone(region_id: String, zone_type: SafeZoneType):
	safe_zone_regions[region_id] = zone_type

# 移除安全区定义
func remove_safe_zone(region_id: String):
	safe_zone_regions.erase(region_id)

# 设置玩家福缘属性
func set_player_luck(luck: int):
	player_luck = max(0, luck)

# 设置连续战斗次数
func set_consecutive_combat_count(count: int):
	consecutive_combat_count = max(0, count)

# 增加连续战斗次数
func increment_combat_count():
	consecutive_combat_count += 1

# 重置连续战斗次数
func reset_combat_count():
	consecutive_combat_count = 0

# 暂停时间跟踪
func pause_time_tracking():
	is_time_tracking_active = false

# 恢复时间跟踪
func resume_time_tracking():
	is_time_tracking_active = true

# 重置距离跟踪
func reset_distance_tracking():
	total_distance_traveled = 0.0
	distance_since_last_check = 0.0
	last_position = Vector2.ZERO
	_has_recorded_position = false

# 重置时间跟踪
func reset_time_tracking():
	total_time_elapsed = 0.0
	time_since_last_check = 0.0

# 重置所有跟踪数据
func reset_all_tracking():
	reset_distance_tracking()
	reset_time_tracking()
	reset_combat_count()

# 获取跟踪统计信息
func get_tracking_stats() -> Dictionary:
	return {
		"total_distance": total_distance_traveled,
		"distance_since_check": distance_since_last_check,
		"total_time": total_time_elapsed,
		"time_since_check": time_since_last_check,
		"current_safe_zone": current_safe_zone,
		"is_warning_active": is_warning_active,
		"player_luck": player_luck,
		"consecutive_combat": consecutive_combat_count,
		"trigger_probability": calculate_trigger_probability()
	}