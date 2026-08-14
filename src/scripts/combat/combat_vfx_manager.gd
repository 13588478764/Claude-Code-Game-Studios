## 战斗特效管理器
## 基于 weapon_type 和 element_type 自动分发 VFX
## 混合方案：AI 生成的特效纹理 + GPUParticles2D/Tween 代码动画

extends Node

# 元素 → 颜色映射
const ELEMENT_COLORS: Dictionary = {
	"火": Color(1.0, 0.4, 0.1, 0.9),
	"冰": Color(0.3, 0.7, 1.0, 0.9),
	"雷": Color(0.7, 0.4, 1.0, 0.9),
	"毒": Color(0.3, 0.9, 0.3, 0.8),
	"金": Color(1.0, 0.85, 0.3, 0.9),
	"暗": Color(0.5, 0.2, 0.7, 0.9),
	"光": Color(1.0, 1.0, 0.8, 0.9),
	"水": Color(0.2, 0.5, 1.0, 0.9),
	"木": Color(0.3, 0.8, 0.2, 0.9),
	"土": Color(0.7, 0.5, 0.2, 0.9),
	"风": Color(0.6, 0.9, 0.8, 0.8),
	"无": Color(1.0, 1.0, 1.0, 0.7),
}

# 元素 → 粒子配置
const ELEMENT_PARTICLE_CONFIG: Dictionary = {
	"火": {"amount": 24, "lifetime": 0.6, "gravity_y": -120.0, "spread": 60.0, "velocity": 80.0},
	"冰": {"amount": 16, "lifetime": 0.8, "gravity_y": 30.0, "spread": 360.0, "velocity": 40.0},
	"雷": {"amount": 10, "lifetime": 0.3, "gravity_y": 0.0, "spread": 30.0, "velocity": 200.0},
	"毒": {"amount": 20, "lifetime": 1.2, "gravity_y": -20.0, "spread": 360.0, "velocity": 25.0},
	"金": {"amount": 14, "lifetime": 0.5, "gravity_y": 0.0, "spread": 45.0, "velocity": 120.0},
	"暗": {"amount": 18, "lifetime": 0.9, "gravity_y": 0.0, "spread": 360.0, "velocity": 30.0},
	"光": {"amount": 20, "lifetime": 0.5, "gravity_y": -60.0, "spread": 360.0, "velocity": 60.0},
	"水": {"amount": 16, "lifetime": 0.7, "gravity_y": 50.0, "spread": 120.0, "velocity": 50.0},
	"木": {"amount": 12, "lifetime": 1.0, "gravity_y": -10.0, "spread": 90.0, "velocity": 35.0},
	"土": {"amount": 14, "lifetime": 0.6, "gravity_y": 80.0, "spread": 150.0, "velocity": 60.0},
	"风": {"amount": 18, "lifetime": 0.5, "gravity_y": 0.0, "spread": 360.0, "velocity": 70.0},
	"无": {"amount": 12, "lifetime": 0.4, "gravity_y": 0.0, "spread": 360.0, "velocity": 50.0},
}

# 武器 → 特效纹理路径
const WEAPON_VFX_PATHS: Dictionary = {
	"Sword": "res://assets/ui/vfx/weapon/vfx_slash_arc.png",
	"Blade": "res://assets/ui/vfx/weapon/vfx_slash_arc.png",
	"Fist": "res://assets/ui/vfx/weapon/vfx_fist_wave.png",
	"Staff": "res://assets/ui/vfx/weapon/vfx_staff_impact.png",
	"None": "res://assets/ui/vfx/weapon/vfx_palm_wind.png",
	"": "res://assets/ui/vfx/weapon/vfx_palm_wind.png",
}

# 预加载的纹理缓存
var _texture_cache: Dictionary = {}
var _particle_texture: Texture2D = null


func _ready() -> void:
	_preload_textures()


func _preload_textures() -> void:
	var dot_path := "res://assets/ui/vfx/common/vfx_particle_dot.png"
	if ResourceLoader.exists(dot_path):
		_particle_texture = load(dot_path) as Texture2D

	for key in WEAPON_VFX_PATHS:
		var path: String = WEAPON_VFX_PATHS[key]
		if not _texture_cache.has(path) and ResourceLoader.exists(path):
			_texture_cache[path] = load(path) as Texture2D

	for element in ELEMENT_COLORS:
		var path := "res://assets/ui/vfx/element/vfx_%s.png" % _element_to_filename(element)
		if ResourceLoader.exists(path):
			_texture_cache[path] = load(path) as Texture2D


## 播放技能释放特效（武器层 + 元素层）
func play_skill_vfx(weapon_type: String, element_type: String,
		attacker: Control, target: Control) -> void:
	if attacker == null or target == null:
		return

	var canvas: Control = _get_vfx_canvas(attacker)
	if canvas == null:
		return

	_play_weapon_vfx(weapon_type, element_type, attacker, target, canvas)
	_play_element_particles(element_type, target, canvas)


## 播放受击特效
func play_hit_vfx(element_type: String, target: Control) -> void:
	if target == null:
		return

	var canvas: Control = _get_vfx_canvas(target)
	if canvas == null:
		return

	_play_hit_burst(element_type, target, canvas)
	_play_screen_flash(element_type, canvas)


# ============================================================================
# 武器层特效
# ============================================================================

func _play_weapon_vfx(weapon_type: String, element_type: String,
		attacker: Control, target: Control, canvas: Control) -> void:
	var color: Color = ELEMENT_COLORS.get(element_type, ELEMENT_COLORS["无"])
	var tex_path: String = WEAPON_VFX_PATHS.get(weapon_type, WEAPON_VFX_PATHS[""])
	var tex: Texture2D = _texture_cache.get(tex_path)

	var vfx := TextureRect.new()
	vfx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vfx.z_index = 50
	vfx.modulate = color

	if tex:
		vfx.texture = tex
		vfx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vfx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	else:
		vfx.custom_minimum_size = Vector2(120, 120)

	canvas.add_child(vfx)

	var start_pos: Vector2 = attacker.position + attacker.size * 0.5
	var end_pos: Vector2 = target.position + target.size * 0.5

	match weapon_type:
		"Sword", "Blade":
			_animate_slash(vfx, start_pos, end_pos, color)
		"Fist":
			_animate_fist_wave(vfx, start_pos, end_pos, color)
		"Staff":
			_animate_staff_impact(vfx, end_pos, color)
		_:
			_animate_energy_wave(vfx, start_pos, end_pos, color)


func _animate_slash(vfx: TextureRect, start: Vector2, end: Vector2, color: Color) -> void:
	var size := Vector2(180, 60)
	vfx.size = size
	vfx.pivot_offset = size * 0.5
	vfx.position = start - size * 0.5
	vfx.rotation = (end - start).angle()
	vfx.modulate.a = 0.0
	vfx.scale = Vector2(0.3, 0.8)

	var tween := vfx.create_tween()
	tween.tween_property(vfx, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(vfx, "scale", Vector2(1.5, 1.2), 0.12).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx, "position", end - size * 0.5, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(vfx, "modulate:a", 0.0, 0.1)
	tween.tween_callback(vfx.queue_free)


func _animate_fist_wave(vfx: TextureRect, start: Vector2, end: Vector2, _color: Color) -> void:
	var size := Vector2(100, 100)
	vfx.size = size
	vfx.pivot_offset = size * 0.5
	vfx.position = start - size * 0.5
	vfx.modulate.a = 0.8
	vfx.scale = Vector2(0.3, 0.3)

	var tween := vfx.create_tween()
	tween.tween_property(vfx, "position", end - size * 0.5, 0.18).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx, "scale", Vector2(1.8, 1.8), 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx, "modulate:a", 0.0, 0.25)
	tween.tween_callback(vfx.queue_free)


func _animate_staff_impact(vfx: TextureRect, target_pos: Vector2, _color: Color) -> void:
	var size := Vector2(140, 140)
	vfx.size = size
	vfx.pivot_offset = size * 0.5
	vfx.position = target_pos - size * 0.5 + Vector2(0, -60)
	vfx.modulate.a = 0.0
	vfx.scale = Vector2(0.5, 2.0)

	var tween := vfx.create_tween()
	tween.tween_property(vfx, "position:y", target_pos.y - size.y * 0.5, 0.1).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(vfx, "modulate:a", 1.0, 0.08)
	tween.tween_property(vfx, "scale", Vector2(2.0, 0.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx, "modulate:a", 0.0, 0.2)
	tween.tween_callback(vfx.queue_free)


func _animate_energy_wave(vfx: TextureRect, start: Vector2, end: Vector2, _color: Color) -> void:
	var size := Vector2(80, 80)
	vfx.size = size
	vfx.pivot_offset = size * 0.5
	vfx.position = start - size * 0.5
	vfx.modulate.a = 0.7
	vfx.scale = Vector2(0.5, 0.5)

	var tween := vfx.create_tween()
	tween.tween_property(vfx, "position", end - size * 0.5, 0.2).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(vfx, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(vfx, "modulate:a", 0.0, 0.15)
	tween.tween_callback(vfx.queue_free)


# ============================================================================
# 元素粒子层
# ============================================================================

func _play_element_particles(element_type: String, target: Control, canvas: Control) -> void:
	var color: Color = ELEMENT_COLORS.get(element_type, ELEMENT_COLORS["无"])
	var config: Dictionary = ELEMENT_PARTICLE_CONFIG.get(element_type, ELEMENT_PARTICLE_CONFIG["无"])
	var center: Vector2 = target.position + target.size * 0.5

	var particles := GPUParticles2D.new()
	particles.z_index = 55
	particles.position = center
	particles.amount = config.amount
	particles.lifetime = config.lifetime
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.8

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 25.0
	mat.direction = Vector3(0, -1, 0)
	mat.spread = config.spread
	mat.gravity = Vector3(0, config.gravity_y, 0)
	mat.initial_velocity_min = config.velocity * 0.6
	mat.initial_velocity_max = config.velocity
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.damping_min = 10.0
	mat.damping_max = 20.0

	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	particles.process_material = mat

	if _particle_texture:
		particles.texture = _particle_texture

	canvas.add_child(particles)

	var cleanup_timer := get_tree().create_timer(config.lifetime + 0.5)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


# ============================================================================
# 受击特效
# ============================================================================

func _play_hit_burst(element_type: String, target: Control, canvas: Control) -> void:
	var color: Color = ELEMENT_COLORS.get(element_type, ELEMENT_COLORS["无"])
	var center: Vector2 = target.position + target.size * 0.5

	var particles := GPUParticles2D.new()
	particles.z_index = 60
	particles.position = center
	particles.amount = 16
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 160.0
	mat.gravity = Vector3(0, 60, 0)
	mat.scale_min = 3.0
	mat.scale_max = 6.0
	mat.damping_min = 30.0
	mat.damping_max = 50.0

	var gradient := Gradient.new()
	var bright := Color(min(color.r * 1.5, 1.0), min(color.g * 1.5, 1.0), min(color.b * 1.5, 1.0), 1.0)
	gradient.set_color(0, bright)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var grad_tex := GradientTexture1D.new()
	grad_tex.gradient = gradient
	mat.color_ramp = grad_tex

	particles.process_material = mat
	if _particle_texture:
		particles.texture = _particle_texture

	canvas.add_child(particles)

	var cleanup_timer := get_tree().create_timer(1.0)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


func _play_screen_flash(element_type: String, canvas: Control) -> void:
	var color: Color = ELEMENT_COLORS.get(element_type, ELEMENT_COLORS["无"])
	var flash := ColorRect.new()
	flash.color = Color(color.r, color.g, color.b, 0.15)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 70
	canvas.add_child(flash)

	var tween := flash.create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.12)
	tween.tween_callback(flash.queue_free)


# ============================================================================
# 工具方法
# ============================================================================

func _get_vfx_canvas(reference: Control) -> Control:
	var node: Node = reference
	while node != null:
		if node is Control and node.name == "Root":
			return node as Control
		node = node.get_parent()
	return reference.get_parent() as Control if reference.get_parent() is Control else null


func _element_to_filename(element: String) -> String:
	match element:
		"火": return "fire_burst"
		"冰": return "ice_crystal"
		"雷": return "lightning_bolt"
		"毒": return "poison_cloud"
		"金": return "metal_glint"
		"暗": return "dark_vortex"
		"光": return "light_burst"
		"水": return "water_splash"
		"木": return "wood_thorns"
		"土": return "earth_crack"
		"风": return "wind_spiral"
		_: return "energy_default"
