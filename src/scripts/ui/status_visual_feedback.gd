## 管理状态效果的粒子特效和音频反馈
## 遵循ADR-001: 使用Node类管理视觉反馈,监听GameConfigManager的low_memory_mode信号
extends Node

class_name StatusVisualFeedback

## 粒子特效节点字典 {EffectType: GPUParticles2D}
var particle_effects: Dictionary = {}

## 音频播放器节点字典 {EffectType: AudioStreamPlayer}
var audio_players: Dictionary = {}

## 目标角色节点(粒子特效挂载点)
var target_character: Node2D = null

## StatusEffectManager引用
var status_manager: Node = null

## 是否启用粒子特效(受low_memory_mode影响)
var particles_enabled: bool = true

## 是否启用音频反馈(受low_memory_mode影响)
var audio_enabled: bool = true

## 粒子特效配置
var _particle_configs: Dictionary = {}

## 音频文件路径映射
var _audio_paths: Dictionary = {}

func _ready() -> void:
	_init_configs()

func _init_configs() -> void:
	var E = StatusEffect.EffectType
	_particle_configs = {
		E.BURN: {
			"color": Color(1.0, 0.3, 0.0, 0.8),
			"amount": 20,
			"lifetime": 1.0,
			"direction": Vector2(0, -1),
			"spread": 45.0,
			"gravity": Vector2(0, -50),
		},
		E.POISON: {
			"color": Color(0.3, 0.8, 0.3, 0.6),
			"amount": 15,
			"lifetime": 1.5,
			"direction": Vector2(0, 0),
			"spread": 360.0,
			"gravity": Vector2(0, 0),
		},
		E.FREEZE: {
			"color": Color(0.3, 0.6, 1.0, 0.9),
			"amount": 10,
			"lifetime": 0.5,
			"direction": Vector2(0, 0),
			"spread": 360.0,
			"gravity": Vector2(0, 0),
		},
		E.REGEN: {
			"color": Color(0.0, 1.0, 0.5, 0.7),
			"amount": 12,
			"lifetime": 1.2,
			"direction": Vector2(0, -1),
			"spread": 30.0,
			"gravity": Vector2(0, -30),
		},
	}
	_audio_paths = {
		E.BURN: "res://assets/audio/sfx/status/burn_loop.ogg",
		E.POISON: "res://assets/audio/sfx/status/poison_loop.ogg",
		E.FREEZE: "res://assets/audio/sfx/status/freeze_once.ogg",
		E.REGEN: "res://assets/audio/sfx/status/regen_loop.ogg",
	}

## 设置目标角色和StatusEffectManager
func setup(character: Node2D, manager: Node) -> void:
	target_character = character
	status_manager = manager

	if status_manager:
		status_manager.status_applied.connect(_on_status_applied)
		status_manager.status_removed.connect(_on_status_removed)
		if status_manager.has_signal("status_triggered"):
			status_manager.status_triggered.connect(_on_status_triggered)

## 信号处理: 状态效果被施加
func _on_status_applied(effect_type: int, stacks: int) -> void:
	if particles_enabled:
		_create_particle_effect(effect_type)

	if audio_enabled:
		_play_audio(effect_type, true)

## 信号处理: 状态效果被移除
func _on_status_removed(effect_type: int) -> void:
	_remove_particle_effect(effect_type)
	_stop_audio(effect_type)

## 信号处理: 状态效果被触发
func _on_status_triggered(effect_type: int, value: float) -> void:
	if audio_enabled:
		_play_trigger_sound(effect_type)

## 创建粒子特效
func _create_particle_effect(effect_type: int) -> void:
	if particle_effects.has(effect_type):
		return

	if not _particle_configs.has(effect_type):
		return

	if target_character == null:
		push_warning("[StatusVisualFeedback] 目标角色未设置,无法创建粒子特效")
		return

	var config = _particle_configs[effect_type]

	var particles = GPUParticles2D.new()
	particles.name = "StatusParticle_%d" % effect_type

	particles.amount = config["amount"]
	particles.lifetime = config["lifetime"]
	particles.emitting = true
	particles.one_shot = false

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

	var gradient = Gradient.new()
	gradient.add_point(0.0, config["color"])
	gradient.add_point(1.0, Color(config["color"].r, config["color"].g, config["color"].b, 0.0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.color_ramp = gradient_texture

	particles.process_material = material

	target_character.add_child(particles)
	particle_effects[effect_type] = particles

## 移除粒子特效
func _remove_particle_effect(effect_type: int) -> void:
	if not particle_effects.has(effect_type):
		return

	var particles = particle_effects[effect_type]
	particles.emitting = false

	await get_tree().create_timer(particles.lifetime).timeout

	particles.queue_free()
	particle_effects.erase(effect_type)

## 播放音频
func _play_audio(effect_type: int, loop: bool = false) -> void:
	if audio_players.has(effect_type):
		return

	if not _audio_paths.has(effect_type):
		return

	var audio_path = _audio_paths[effect_type]

	if not ResourceLoader.exists(audio_path):
		return

	var player = AudioStreamPlayer.new()
	player.name = "StatusAudio_%d" % effect_type
	player.stream = load(audio_path)

	if loop and player.stream is AudioStreamOggVorbis:
		player.stream.loop = true

	add_child(player)
	player.play()
	audio_players[effect_type] = player

## 停止音频
func _stop_audio(effect_type: int) -> void:
	if not audio_players.has(effect_type):
		return

	var player = audio_players[effect_type]
	player.stop()
	player.queue_free()
	audio_players.erase(effect_type)

## 播放触发音效(一次性)
func _play_trigger_sound(effect_type: int) -> void:
	pass

## 停止所有特效
func _stop_all_effects() -> void:
	for particles in particle_effects.values():
		particles.emitting = false
		particles.queue_free()
	particle_effects.clear()

	for player in audio_players.values():
		player.stop()
		player.queue_free()
	audio_players.clear()

## 刷新所有特效(用于退出低内存模式)
func _refresh_all_effects() -> void:
	if status_manager == null:
		return

	for effect in status_manager.active_effects:
		if particles_enabled:
			_create_particle_effect(effect.effect_type)
		if audio_enabled:
			_play_audio(effect.effect_type, true)
