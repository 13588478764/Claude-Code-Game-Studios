## PlayerMovementController
## 玩家移动控制器
## 
## 负责管理玩家在开放世界中的移动，包括奔跑、攀爬、滑翔等特殊移动能力。
## 
## 主要功能：
## - 基础移动和奔跑
## - 攀爬和滑翔能力管理
## - 体力值管理和消耗
## - 跳跃和重力处理
## - 属性系统集成

extends Node

class_name PlayerMovementController

# ============================================================================
# 常量定义
# ============================================================================

## 基础移动速度
const MOVE_SPEED: float = 200.0

## 奔跑速度倍数
const RUN_MULTIPLIER: float = 1.5

## 跳跃速度
const JUMP_VELOCITY: float = -400.0

## 重力加速度
const GRAVITY: float = 980.0

## 体力消耗速率（奔跑时）
const STAMINA_DRAIN_RATE: float = 5.0

## 体力恢复速率（空闲时）
const STAMINA_RESTORE_RATE: float = 10.0

## 特殊动作最小体力要求
const MIN_STAMINA_FOR_ACTIONS: float = 10.0

## 轻功属性影响因子
const LIGHTNESS_FACTOR: float = 0.1

## 攀爬速度倍数
const CLIMBING_SPEED_MULTIPLIER: float = 0.5

## 攀爬垂直速度倍数
const CLIMBING_VERTICAL_MULTIPLIER: float = 0.7

## 攀爬体力消耗倍数
const CLIMBING_STAMINA_MULTIPLIER: float = 1.5

## 滑翔速度倍数
const GLIDING_SPEED_MULTIPLIER: float = 0.8

## 滑翔重力倍数
const GLIDING_GRAVITY_MULTIPLIER: float = 0.3

## 滑翔体力消耗倍数
const GLIDING_STAMINA_MULTIPLIER: float = 0.5

## 低体力移动速度倍数
const LOW_STAMINA_SPEED_MULTIPLIER: float = 0.7

## 垂直移动输入阈值
const VERTICAL_INPUT_THRESHOLD: float = 0.1

## 水平移动输入阈值
const HORIZONTAL_INPUT_THRESHOLD: float = 0.1

# ============================================================================
# 信号定义
# ============================================================================

## 体力变化信号
signal stamina_changed(current: float, max: float)

## 玩家移动信号
signal player_moved(new_position: Vector2)

## 垂直移动尝试信号
signal vertical_movement_attempted(action: String, success: bool)

## 攀爬开始信号
signal climbing_started()

## 攀爬结束信号
signal climbing_ended()

## 滑翔开始信号
signal gliding_started()

## 滑翔结束信号
signal gliding_ended()

# ============================================================================
# 成员变量
# ============================================================================

## 玩家属性字典
var attributes: Dictionary = {
	"speed": 50.0,
	"lightness": 50.0,
	"stamina": 100.0,
	"max_stamina": 100.0
}

## 是否正在奔跑
var is_running: bool = false

## 是否正在攀爬
var is_climbing: bool = false

## 是否正在滑翔
var is_gliding: bool = false

## 是否正在跳跃
var is_jumping: bool = false

## 是否已解锁攀爬能力
var can_climb: bool = true

## 是否已解锁滑翔能力
var can_glide: bool = true

## 当前速度向量
var velocity: Vector2 = Vector2.ZERO

## 目标速度向量
var _target_velocity: Vector2 = Vector2.ZERO

## 移动输入向量
var _movement_input: Vector2 = Vector2.ZERO

## 最后移动方向
var _last_direction: Vector2 = Vector2.RIGHT

# ============================================================================
# 生命周期方法
# ============================================================================

## 初始化玩家移动控制器
func _ready() -> void:
	attributes["stamina"] = attributes["max_stamina"]
	print("玩家移动控制器初始化完成")

## 物理处理
func _physics_process(delta: float) -> void:
	# 应用重力（如果不在地面且不在攀爬）
	if not _is_on_floor() and not is_climbing:
		velocity.y += GRAVITY * delta
	else:
		# 在地面上时重置跳跃状态
		if is_jumping:
			is_jumping = false
	
	# 处理移动输入
	_process_movement_input(delta)
	
	# 更新体力
	_update_stamina(delta)
	
	# 移动角色
	_move_character()

# ============================================================================
# 公共方法
# ============================================================================

## 处理移动输入
func _process_movement_input(delta: float) -> void:
	"""处理玩家的移动输入"""
	# 获取输入方向
	_movement_input = Vector2.ZERO
	_movement_input.x = Input.get_axis("move_left", "move_right")
	_movement_input.y = Input.get_axis("move_up", "move_down")
	
	# 归一化以防止对角线移动更快
	if _movement_input.length() > 0:
		_movement_input = _movement_input.normalized()
	
	# 判断是否尝试奔跑
	is_running = Input.is_action_pressed("run") and _movement_input.length() > HORIZONTAL_INPUT_THRESHOLD
	
	# 计算基础速度
	var base_speed: float = MOVE_SPEED + attributes["speed"]
	var current_speed: float = base_speed
	
	# 应用奔跑倍数（如果体力充足）
	if is_running and attributes["stamina"] > 5.0:
		current_speed *= RUN_MULTIPLIER
	elif is_running:
		# 体力不足时减速
		current_speed *= LOW_STAMINA_SPEED_MULTIPLIER
	
	# 处理特殊移动能力
	if can_climb and is_climbing:
		_handle_climbing(current_speed, delta)
	elif can_glide and is_gliding:
		_handle_gliding(current_speed, delta)
	else:
		# 常规移动
		velocity.x = _movement_input.x * current_speed
		
		# 更新面向方向
		if _movement_input.x != 0:
			_last_direction.x = _movement_input.x
	
	# 处理跳跃
	if Input.is_action_just_pressed("jump") and _is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true

## 处理攀爬移动
func _handle_climbing(speed: float, delta: float) -> void:
	"""
	处理攀爬移动
	
	参数：
	- speed: 当前速度
	- delta: 帧时间差
	"""
	velocity.x = _movement_input.x * speed * CLIMBING_SPEED_MULTIPLIER
	velocity.y = _movement_input.y * speed * CLIMBING_VERTICAL_MULTIPLIER
	
	# 检查是否仍在可攀爬表面附近
	if not _is_near_climbable_surface():
		is_climbing = false
		climbing_ended.emit()
		vertical_movement_attempted.emit("climbing_end", false)

## 处理滑翔移动
func _handle_gliding(speed: float, delta: float) -> void:
	"""
	处理滑翔移动
	
	参数：
	- speed: 当前速度
	- delta: 帧时间差
	"""
	velocity.x = _movement_input.x * speed * GLIDING_SPEED_MULTIPLIER
	velocity.y += (GRAVITY * GLIDING_GRAVITY_MULTIPLIER) * delta
	
	# 检查是否应该结束滑翔
	if _is_on_floor() or _should_end_glide():
		is_gliding = false
		gliding_ended.emit()
		vertical_movement_attempted.emit("glide_end", true)

## 更新体力值
func _update_stamina(delta: float) -> void:
	"""根据活动更新体力值"""
	var stamina_change: float = 0.0
	
	# 奔跑或特殊动作时消耗体力
	if is_running and attributes["stamina"] > 0:
		stamina_change -= STAMINA_DRAIN_RATE * delta
	elif is_climbing:
		stamina_change -= STAMINA_DRAIN_RATE * CLIMBING_STAMINA_MULTIPLIER * delta
	elif is_gliding:
		stamina_change -= STAMINA_DRAIN_RATE * GLIDING_STAMINA_MULTIPLIER * delta
	
	# 不进行密集活动时恢复体力
	if stamina_change >= 0:
		stamina_change += STAMINA_RESTORE_RATE * delta
	
	# 应用轻功属性修正
	var lightness_modifier: float = 1.0 - (attributes["lightness"] / 100.0) * LIGHTNESS_FACTOR
	stamina_change *= lightness_modifier
	
	# 更新体力值
	attributes["stamina"] = clamp(attributes["stamina"] + stamina_change, 0.0, attributes["max_stamina"])
	
	# 体力变化显著时发出信号
	if abs(stamina_change) > 0.01:
		stamina_changed.emit(attributes["stamina"], attributes["max_stamina"])

## 尝试开始攀爬
func attempt_climb() -> bool:
	"""
	尝试开始攀爬
	
	返回：
	- 攀爬是否成功开始
	"""
	if not can_climb or attributes["stamina"] < MIN_STAMINA_FOR_ACTIONS:
		vertical_movement_attempted.emit("climb_start", false)
		return false
	
	if _is_near_climbable_surface():
		is_climbing = true
		velocity = Vector2.ZERO
		climbing_started.emit()
		vertical_movement_attempted.emit("climb_start", true)
		return true
	else:
		vertical_movement_attempted.emit("climb_start", false)
		return false

## 尝试开始滑翔
func attempt_glide() -> bool:
	"""
	尝试开始滑翔
	
	返回：
	- 滑翔是否成功开始
	"""
	if not can_glide or attributes["stamina"] < MIN_STAMINA_FOR_ACTIONS:
		vertical_movement_attempted.emit("glide_start", false)
		return false
	
	if not _is_on_floor() and not is_climbing:
		is_gliding = true
		gliding_started.emit()
		vertical_movement_attempted.emit("glide_start", true)
		return true
	else:
		vertical_movement_attempted.emit("glide_start", false)
		return false

## 获取当前移动方向
func get_current_direction() -> Vector2:
	"""
	获取当前移动方向
	
	返回：
	- 移动方向向量
	"""
	return _last_direction

## 获取当前移动速度
func get_current_speed() -> float:
	"""
	获取当前移动速度
	
	返回：
	- 当前速度值
	"""
	var base_speed: float = MOVE_SPEED + attributes["speed"]
	if is_running and attributes["stamina"] > 5.0:
		return base_speed * RUN_MULTIPLIER
	return base_speed

## 获取体力信息
func get_stamina_info() -> Dictionary:
	"""
	获取体力信息
	
	返回：
	- 包含当前体力、最大体力和百分比的字典
	"""
	return {
		"current": attributes["stamina"],
		"max": attributes["max_stamina"],
		"percent": attributes["stamina"] / attributes["max_stamina"] * 100.0
	}

## 设置玩家属性
func set_attribute(attr_name: String, value: float) -> void:
	"""
	设置玩家属性
	
	参数：
	- attr_name: 属性名称
	- value: 属性值
	"""
	if attributes.has(attr_name):
		attributes[attr_name] = value
		# 设置最大体力时按比例调整当前体力
		if attr_name == "max_stamina":
			var ratio: float = attributes["stamina"] / attributes.get("max_stamina", 1.0)
			attributes["stamina"] = value * ratio

## 获取玩家属性
func get_attribute(attr_name: String) -> float:
	"""
	获取玩家属性
	
	参数：
	- attr_name: 属性名称
	
	返回：
	- 属性值
	"""
	return attributes.get(attr_name, 0.0)

## 解锁攀爬能力
func unlock_climbing() -> void:
	"""解锁攀爬能力"""
	can_climb = true
	print("攀爬能力已解锁")

## 解锁滑翔能力
func unlock_glide() -> void:
	"""解锁滑翔能力"""
	can_glide = true
	print("滑翔能力已解锁")

## 检查探索奖励
func check_exploration_rewards() -> void:
	"""检查当前位置的探索奖励"""
	player_moved.emit(global_position)

# ============================================================================
# 私有方法
# ============================================================================

## 检查是否在地面上
func _is_on_floor() -> bool:
	"""
	检查玩家是否在地面上
	
	返回：
	- 是否在地面上
	"""
	# 这里应该使用实际的碰撞检测
	# 简化实现：检查速度和位置
	return velocity.y >= 0

## 检查是否在可攀爬表面附近
func _is_near_climbable_surface() -> bool:
	"""
	检查是否在可攀爬表面附近
	
	返回：
	- 是否在可攀爬表面附近
	"""
	return abs(_movement_input.y) > VERTICAL_INPUT_THRESHOLD

## 检查是否应该结束滑翔
func _should_end_glide() -> bool:
	"""
	检查是否应该结束滑翔
	
	返回：
	- 是否应该结束滑翔
	"""
	return _movement_input.y < -VERTICAL_INPUT_THRESHOLD or attributes["stamina"] < 5.0

## 移动角色
func _move_character() -> void:
	"""移动角色"""
	# 这里应该使用实际的物理移动
	# 简化实现：直接更新全局位置
	global_position += velocity * get_physics_process_delta_time()