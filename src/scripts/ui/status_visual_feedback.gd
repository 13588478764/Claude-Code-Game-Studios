## StatusVisualFeedback
## StatusVisualFeedback Node节点
管理状态效果的粒子特效和音频反馈
遵循ADR-001: 使用Node类管理视觉反馈,监听GameConfigManager的low_memory_mode信号
##
## 主要功能：
## - 待补充

extends Node

class_name StatusVisualFeedback

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

extends Node

## 粒子特效节点字典 {EffectType: GPUParticles2D}
var particle_effects: Dictionary = {}

## 音频播放器节点字典 {EffectType: AudioStreamPlayer}
var audio_players: Dictionary = {}

## 目标角色节点(粒子特效挂载点)
var target_character: Node2D = null

## StatusEffectManager引用
var status_manager: StatusEffectManager = null

## 是否启用粒子特效(受low_memory_mode影响)
var particles_enabled: bool = true

## 是否启用音频反馈(受low_memory_mode影响)
var audio_enabled: bool = true

## 粒子特效配置
const PARTICLE_CONFIGS: Dictionary = {
	StatusEffect.EffectType.BURN: {
		"color": Color(1.0, 0.3, 0.0, 0.8),  # 橙红色
		"amount": 20,
		"lifetime": 1.0,
		"direction": Vector2(0, -1),  # 向上飘动
		"spread": 45.0,
		"gravity": Vector2(0, -50),
	},
	StatusEffect.EffectType.POISON: {
		"color": Color(0.3, 0.8, 0.3, 0.6),  # 绿色
		"amount": 15,
		"lifetime": 1.5,
		"direction": Vector2(0, 0),  # 环绕
		"spread": 360.0,
		"gravity": Vector2(0, 0),
	},
	StatusEffect.EffectType.FREEZE: {
		"color": Color(0.3, 0.6, 1.0, 0.9),  # 蓝色
		"amount": 10,
		"lifetime": 0.5,
		"direction": Vector2(0, 0),
		"spread": 360.0,
		"gravity": Vector2(0, 0),
	},
	StatusEffect.EffectType.REGEN: {
		"color": Color(0.0, 1.0, 0.5, 0.7),  # 青绿色
		"amount": 12,
		"lifetime": 1.2,
		"direction": Vector2(0, -1),  # 向上飘动
		"spread": 30.0,
		"gravity": Vector2(0, -30),
	},
}

## 音频文件路径映射
const AUDIO_PATHS: Dictionary = {
	StatusEffect.EffectType.BURN: "res://assets/audio/sfx/status/burn_loop.ogg",
	StatusEffect.EffectType.POISON: "res://assets/audio/sfx/status/poison_loop.ogg",
	StatusEffect.EffectType.FREEZE: "res://assets/audio/sfx/status/freeze_once.ogg",
	StatusEffect.EffectType.REGEN: "res://assets/audio/sfx/status/regen_loop.ogg",
}

func _ready() -> void:
	# 连接GameConfigManager的low_memory_mode信号
	if GameConfigManager:
		GameConfigManager.low_memory_mode_changed.connect(_on_low_memory_mode_changed)
		# 初始化状态
		particles_enabled = not GameConfigManager.low_memory_mode
		audio_enabled = not GameConfigManager.low_memory_mode

## 设置目标角色和StatusEffectManager
func setup(character: Node2D, manager: StatusEffectManager) -> void:
	target_character = character
	status_manager = manager
	
	# 连接状态管理器信号
	if status_manager:
		status_manager.status_applied.connect(_on_status_applied)
		status_manager.status_removed.connect(_on_status_removed)
		status_manager.status_triggered.connect(_on_status_triggered)

## 信号处理: 低内存模式改变
func _on_low_memory_mode_changed(enabled: bool) -> void:
	particles_enabled = not enabled
	audio_enabled = not enabled
	
	# 如果进入低内存模式,停止所有粒子和音频
	if enabled:
		_stop_all_effects()
	else:
		# 退出低内存模式,重新创建当前状态的特效
		_refresh_all_effects()

## 信号处理: 状态效果被施加
func _on_status_applied(effect_type: StatusEffect.EffectType, stacks: int) -> void:
	# 创建粒子特效
	if particles_enabled:
		_create_particle_effect(effect_type)
	
	# 播放音频
	if audio_enabled:
		_play_audio(effect_type, true)  # true表示循环播放

## 信号处理: 状态效果被移除
func _on_status_removed(effect_type: StatusEffect.EffectType) -> void:
	# 移除粒子特效
	_remove_particle_effect(effect_type)
	
	# 停止音频
	_stop_audio(effect_type)

## 信号处理: 状态效果被触发
func _on_status_triggered(effect_type: StatusEffect.EffectType, value: float) -> void:
	# 触发时播放一次性音效(如果有)
	if audio_enabled:
		_play_trigger_sound(effect_type)

## 创建粒子特效
func _create_particle_effect(effect_type: StatusEffect.EffectType) -> void:
	# 如果已存在,不重复创建
	if particle_effects.has(effect_type):
		return
	
	# 检查是否有配置
	if not PARTICLE_CONFIGS.has(effect_type):
		return
	
	# 检查目标角色是否存在
	if target_character == null:
		push_warning("[StatusVisualFeedback] 目标角色未设置,无法创建粒子特效")
		return
	
	var config = PARTICLE_CONFIGS[effect_type]
	
	# 创建GPUParticles2D节点
	var particles = GPUParticles2D.new()
	particles.name = "StatusParticle_%s" % StatusEffect.EffectType.keys()[effect_type]
	
	# 基础设置
	particles.amount = config["amount"]
	particles.lifetime = config["lifetime"]
	particles.emitting = true
	particles.one_shot = false
	
	# 创建ParticleProcessMaterial
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 20.0
	material.direction = Vector3(config["direction"].x, config["direction"].y, 0)
	material.spread = config["spread"]
	material.gravity = Vector3(config["gravity"].x, config["gravity"].y, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.scale_min = 0.5
	material.scale_max = 1.5
	
	# 颜色渐变
	var gradient = Gradient.new()
	gradient.add_point(0.0, config["color"])
	gradient.add_point(1.0, Color(config["color"].r, config["color"].g, config["color"].b, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture
	
	particles.process_material = material
	
	# 添加到目标角色
	target_character.add_child(particles)
	
	# 存储引用
	particle_effects[effect_type] = particles

## 移除粒子特效
func _remove_particle_effect(effect_type: StatusEffect.EffectType) -> void:
	if not particle_effects.has(effect_type):
		return
	
	var particles = particle_effects[effect_type]
	
	# 停止发射
	particles.emitting = false
	
	# 等待粒子生命周期结束后删除
	await get_tree().create_timer(particles.lifetime).timeout
	
	particles.queue_free()
	particle_effects.erase(effect_type)

## 播放音频
func _play_audio(effect_type: StatusEffect.EffectType, loop: bool = false) -> void:
	# 如果已存在,不重复创建
	if audio_players.has(effect_type):
		return
	
	# 检查是否有音频文件
	if not AUDIO_PATHS.has(effect_type):
		return
	
	var audio_path = AUDIO_PATHS[effect_type]
	
	# 检查文件是否存在
	if not ResourceLoader.exists(audio_path):
		return
	
	# 创建AudioStreamPlayer
	var player = AudioStreamPlayer.new()
	player.name = "StatusAudio_%s" % StatusEffect.EffectType.keys()[effect_type]
	player.stream = load(audio_path)
	
	# 设置循环
	if loop and player.stream is AudioStreamOggVorbis:
		player.stream.loop = true
	
	# 添加到场景树
	add_child(player)
	
	# 播放
	player.play()
	
	# 存储引用
	audio_players[effect_type] = player

## 停止音频
func _stop_audio(effect_type: StatusEffect.EffectType) -> void:
	if not audio_players.has(effect_type):
		return
	
	var player = audio_players[effect_type]
	player.stop()
	player.queue_free()
	audio_players.erase(effect_type)

## 播放触发音效(一次性)
func _play_trigger_sound(effect_type: StatusEffect.EffectType) -> void:
	# 触发音效通常是一次性的,不需要存储引用
	# 这里可以播放额外的触发音效,如伤害数字弹出的声音
	pass

## 停止所有特效
func _stop_all_effects() -> void:
	# 停止所有粒子
	for particles in particle_effects.values():
		particles.emitting = false
		particles.queue_free()
	particle_effects.clear()
	
	# 停止所有音频
	for player in audio_players.values():
		player.stop()
		player.queue_free()
	audio_players.clear()

## 刷新所有特效(用于退出低内存模式)
func _refresh_all_effects() -> void:
	if status_manager == null:
		return
	
	# 为当前所有激活的状态创建特效
	for effect in status_manager.active_effects:
		if particles_enabled:
			_create_particle_effect(effect.effect_type)
		if audio_enabled:
			_play_audio(effect.effect_type, true)