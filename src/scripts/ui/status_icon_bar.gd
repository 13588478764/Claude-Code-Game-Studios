## 状态图标栏 — 显示角色当前的状态效果图标
extends HBoxContainer

class_name StatusIconBar

## 状态图标场景预制体路径
const STATUS_ICON_SCENE_PATH := "res://src/scenes/ui/status_icon.tscn"

## 最大显示图标数量(Control Manifest Guardrail)
const MAX_VISIBLE_ICONS: int = 8

## 图标大小配置(基于1920x1080基准分辨率)
const ICON_SIZE_1080P: Vector2 = Vector2(32, 32)
const ICON_SIZE_1440P: Vector2 = Vector2(48, 48)

## 当前缩放因子
var current_scale_factor: float = 1.0

## 状态图标节点字典 {EffectType: StatusIcon}
var status_icons: Dictionary = {}

## StatusEffectManager引用
var status_manager: StatusEffectManager = null

func _ready() -> void:
	# 监听viewport尺寸变化
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	
	# 初始化UI缩放
	_update_ui_scale()
	
	# 设置容器属性
	alignment = ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 4)

## 设置StatusEffectManager引用并连接信号
func setup(manager: StatusEffectManager) -> void:
	if status_manager != null:
		# 断开旧的信号连接
		status_manager.status_applied.disconnect(_on_status_applied)
		status_manager.status_removed.disconnect(_on_status_removed)
		status_manager.status_refreshed.disconnect(_on_status_refreshed)
	
	status_manager = manager
	
	# 连接信号
	status_manager.status_applied.connect(_on_status_applied)
	status_manager.status_removed.connect(_on_status_removed)
	status_manager.status_refreshed.connect(_on_status_refreshed)
	
	# 初始化现有状态
	_refresh_all_icons()

## AC4: 响应viewport尺寸变化,更新UI缩放
func _on_viewport_size_changed() -> void:
	_update_ui_scale()

## AC4: 更新UI缩放因子
func _update_ui_scale() -> void:
	var viewport_size = get_viewport().size
	
	# 基准分辨率1920x1080
	current_scale_factor = viewport_size.x / 1920.0
	
	# 应用缩放
	scale = Vector2(current_scale_factor, current_scale_factor)
	
	# 更新所有图标的大小
	_update_all_icon_sizes()

## 更新所有图标的大小
func _update_all_icon_sizes() -> void:
	var icon_size = _get_icon_size_for_resolution()
	
	for icon in status_icons.values():
		if icon is StatusIcon:
			icon.set_icon_size(icon_size)

## AC4: 根据分辨率获取图标大小
func _get_icon_size_for_resolution() -> Vector2:
	var viewport_size = get_viewport().size
	
	# 1920x1080: 32x32
	if viewport_size.x <= 1920:
		return ICON_SIZE_1080P
	# 2560x1440 或 3440x1440: 48x48
	else:
		return ICON_SIZE_1440P

## 信号处理: 状态效果被施加
func _on_status_applied(effect_type: StatusEffect.EffectType, stacks: int) -> void:
	# 如果图标已存在,更新层数
	if status_icons.has(effect_type):
		var icon = status_icons[effect_type]
		icon.update_stacks(stacks)
		_play_refresh_animation(icon)
		return
	
	# 检查是否超过最大显示数量
	if status_icons.size() >= MAX_VISIBLE_ICONS:
		push_warning("[StatusIconBar] 已达到最大图标数量限制: %d" % MAX_VISIBLE_ICONS)
		return
	
	# 创建新图标
	_create_status_icon(effect_type, stacks)

## 信号处理: 状态效果被移除
func _on_status_removed(effect_type: StatusEffect.EffectType) -> void:
	if not status_icons.has(effect_type):
		return
	
	var icon = status_icons[effect_type]
	_play_remove_animation(icon)
	
	# 动画完成后移除
	await get_tree().create_timer(0.3).timeout
	
	status_icons.erase(effect_type)
	icon.queue_free()

## 信号处理: 状态效果被刷新
func _on_status_refreshed(effect_type: StatusEffect.EffectType, new_duration: int) -> void:
	if not status_icons.has(effect_type):
		return
	
	var icon = status_icons[effect_type]
	icon.update_duration(new_duration)
	_play_refresh_animation(icon)

## 创建状态图标
func _create_status_icon(effect_type: StatusEffect.EffectType, stacks: int) -> void:
	# 从StatusEffectManager获取状态效果数据
	var effect = _find_effect_by_type(effect_type)
	if effect == null:
		push_error("[StatusIconBar] 未找到状态效果: %s" % StatusEffect.EffectType.keys()[effect_type])
		return
	
	# 实例化图标场景
	var icon = load(STATUS_ICON_SCENE_PATH).instantiate()
	add_child(icon)
	
	# 设置图标数据
	icon.setup(effect, stacks)
	icon.set_icon_size(_get_icon_size_for_resolution())
	
	# 存储引用
	status_icons[effect_type] = icon
	
	# 播放施加动画
	_play_apply_animation(icon)

## 从StatusEffectManager查找状态效果
func _find_effect_by_type(effect_type: StatusEffect.EffectType) -> StatusEffect:
	if status_manager == null:
		return null
	
	for effect in status_manager.active_effects:
		if effect.effect_type == effect_type:
			return effect
	
	return null

## 刷新所有图标(用于初始化)
func _refresh_all_icons() -> void:
	# 清除现有图标
	for icon in status_icons.values():
		icon.queue_free()
	status_icons.clear()
	
	# 重新创建所有图标
	if status_manager == null:
		return
	
	for effect in status_manager.active_effects:
		_create_status_icon(effect.effect_type, effect.stacks)

## 播放施加动画 - 旋转入场
func _play_apply_animation(icon: Control) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 初始状态
	icon.rotation = -PI / 2  # -90度
	icon.modulate.a = 0.0
	
	# 旋转到0度
	tween.tween_property(icon, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# 淡入
	tween.tween_property(icon, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_LINEAR)

## 播放刷新动画 - 闪烁
func _play_refresh_animation(icon: Control) -> void:
	var tween = create_tween()
	
	# 闪烁效果
	tween.tween_property(icon, "modulate:a", 0.3, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(icon, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_LINEAR)

## 播放移除动画 - 淡出消失
func _play_remove_animation(icon: Control) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 淡出
	tween.tween_property(icon, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_LINEAR)
	# 缩小
	tween.tween_property(icon, "scale", Vector2(0.5, 0.5), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)