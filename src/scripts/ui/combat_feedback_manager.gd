extends Node
## 战斗反馈管理器 - 管理战斗反馈效果
## 处理伤害数字、特效、音效和状态图标动画

class_name CombatFeedbackManager

# 信号定义
signal feedback_played(feedback_type: String)
signal damage_number_shown(damage: int, position: Vector2)
signal effect_played(effect_type: String)
signal audio_played(audio_type: String)
signal status_animated(status_type: String)

# 伤害类型枚举
enum DamageType {
	PHYSICAL,      # 外功伤害 - 白色
	INTERNAL,      # 内功伤害 - 蓝色
	CRITICAL,      # 暴击伤害 - 金色
	TRUE_DAMAGE    # 真实伤害 - 红色
}

# 特效类型枚举
enum EffectType {
	HIT,           # 命中特效
	CRITICAL_HIT,  # 暴击特效
	MISS,          # Miss特效
	SKILL_EFFECT   # 技能特效
}

# 音效类型枚举
enum AudioType {
	UI_CLICK,      # UI点击音效
	COMBAT_HIT,    # 战斗命中音效
	CRITICAL_HIT,  # 暴击音效
	SKILL_CAST     # 技能释放音效
}

# 伤害数字颜色映射
var damage_color_map: Dictionary = {
	DamageType.PHYSICAL: Color.WHITE,
	DamageType.INTERNAL: Color.CYAN,
	DamageType.CRITICAL: Color.YELLOW,
	DamageType.TRUE_DAMAGE: Color.RED
}

# 反馈延迟限制
var feedback_delay: float = 0.0
var feedback_delay_threshold: float = 0.05  # 50ms延迟限制

# 活跃的伤害数字
var active_damage_numbers: Array[Dictionary] = []

# 活跃的特效
var active_effects: Array[Dictionary] = []

# 音频播放状态
var audio_enabled: bool = true

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# 处理反馈延迟
	if feedback_delay > 0:
		feedback_delay -= delta
	
	# 更新伤害数字
	_update_damage_numbers(delta)
	
	# 更新特效
	_update_effects(delta)

## 显示伤害数字
func show_damage_number(damage_data: Dictionary) -> void:
	if feedback_delay > 0:
		return
	
	var damage = damage_data.get("damage", 0)
	var damage_type = damage_data.get("type", DamageType.PHYSICAL)
	var position = damage_data.get("position", Vector2.ZERO)
	var duration = damage_data.get("duration", 1.0)
	
	# 获取伤害颜色
	var color = damage_color_map.get(damage_type, Color.WHITE)
	
	# 创建伤害数字数据
	var damage_number = {
		"damage": damage,
		"position": position,
		"color": color,
		"duration": duration,
		"elapsed": 0.0,
		"start_position": position
	}
	
	active_damage_numbers.append(damage_number)
	
	# 发送信号
	damage_number_shown.emit(damage, position)
	feedback_played.emit("damage_number")
	
	feedback_delay = feedback_delay_threshold

## 播放战斗特效
func play_combat_effect(effect_type: int, position: Vector2) -> void:
	if feedback_delay > 0:
		return
	
	# 创建特效数据
	var effect = {
		"type": effect_type,
		"position": position,
		"duration": 0.5,
		"elapsed": 0.0
	}
	
	active_effects.append(effect)
	
	# 发送信号
	var effect_name = EffectType.keys()[effect_type] if effect_type < EffectType.size() else "UNKNOWN"
	effect_played.emit(effect_name)
	feedback_played.emit("combat_effect")
	
	feedback_delay = feedback_delay_threshold

## 播放音效反馈
func play_audio_feedback(audio_type: int) -> void:
	if not audio_enabled or feedback_delay > 0:
		return
	
	var audio_name = AudioType.keys()[audio_type] if audio_type < AudioType.size() else "UNKNOWN"
	
	# 发送信号
	audio_played.emit(audio_name)
	feedback_played.emit("audio_feedback")
	
	feedback_delay = feedback_delay_threshold

## 处理状态图标动画
func animate_status_icons(status_data: Dictionary) -> void:
	if feedback_delay > 0:
		return
	
	var status_type = status_data.get("type", "")
	var duration = status_data.get("duration", 5.0)
	var icon_position = status_data.get("position", Vector2.ZERO)
	
	# 创建状态动画数据
	var status_animation = {
		"type": status_type,
		"position": icon_position,
		"duration": duration,
		"elapsed": 0.0,
		"rotation": 0.0
	}
	
	# 发送信号
	status_animated.emit(status_type)
	feedback_played.emit("status_animation")
	
	feedback_delay = feedback_delay_threshold

## 获取伤害颜色
func get_damage_color(damage_type: int) -> Color:
	return damage_color_map.get(damage_type, Color.WHITE)

## 启用/禁用音频
func set_audio_enabled(enabled: bool) -> void:
	audio_enabled = enabled

## 清除所有反馈
func clear_all_feedback() -> void:
	active_damage_numbers.clear()
	active_effects.clear()

## 内部方法：更新伤害数字
func _update_damage_numbers(delta: float) -> void:
	var to_remove = []
	
	for i in range(active_damage_numbers.size()):
		var damage_number = active_damage_numbers[i]
		damage_number["elapsed"] += delta
		
		# 检查是否过期
		if damage_number["elapsed"] >= damage_number["duration"]:
			to_remove.append(i)
		else:
			# 更新位置（向上浮动）
			var progress = damage_number["elapsed"] / damage_number["duration"]
			damage_number["position"].y = damage_number["start_position"].y - (progress * 50)
	
	# 移除过期的伤害数字
	for i in to_remove.reverse():
		active_damage_numbers.remove_at(i)

## 内部方法：更新特效
func _update_effects(delta: float) -> void:
	var to_remove = []
	
	for i in range(active_effects.size()):
		var effect = active_effects[i]
		effect["elapsed"] += delta
		
		# 检查是否过期
		if effect["elapsed"] >= effect["duration"]:
			to_remove.append(i)
	
	# 移除过期的特效
	for i in to_remove.reverse():
		active_effects.remove_at(i)

## 获取活跃的伤害数字数量
func get_active_damage_numbers_count() -> int:
	return active_damage_numbers.size()

## 获取活跃的特效数量
func get_active_effects_count() -> int:
	return active_effects.size()

## 检查是否有活跃的反馈
func has_active_feedback() -> bool:
	return active_damage_numbers.size() > 0 or active_effects.size() > 0