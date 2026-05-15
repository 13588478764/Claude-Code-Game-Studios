## 状态图标 — 单个状态效果图标，显示图标、层数、剩余回合数
extends PanelContainer

class_name StatusIcon

## 状态效果数据
var effect_data: StatusEffect = null

## 当前层数
var current_stacks: int = 1

## UI节点引用
@onready var icon_texture: TextureRect = $VBoxContainer/IconTexture
@onready var duration_label: Label = $VBoxContainer/IconTexture/DurationLabel
@onready var stack_label: Label = $VBoxContainer/IconTexture/StackLabel
@onready var tooltip: StatusTooltip = $StatusTooltip

## 图标纹理路径映射
const ICON_TEXTURES: Dictionary = {
	StatusEffect.EffectType.BURN: "res://assets/icons/status/burn.png",
	StatusEffect.EffectType.POISON: "res://assets/icons/status/poison.png",
	StatusEffect.EffectType.BLEED: "res://assets/icons/status/bleed.png",
	StatusEffect.EffectType.REGEN: "res://assets/icons/status/regen.png",
	StatusEffect.EffectType.STRENGTH_UP: "res://assets/icons/status/strength_up.png",
	StatusEffect.EffectType.FOCUS: "res://assets/icons/status/focus.png",
	StatusEffect.EffectType.SHIELD: "res://assets/icons/status/shield.png",
	StatusEffect.EffectType.WEAKEN: "res://assets/icons/status/weaken.png",
	StatusEffect.EffectType.VULNERABLE: "res://assets/icons/status/vulnerable.png",
	StatusEffect.EffectType.BLIND: "res://assets/icons/status/blind.png",
	StatusEffect.EffectType.STUN: "res://assets/icons/status/stun.png",
	StatusEffect.EffectType.ROOT: "res://assets/icons/status/root.png",
	StatusEffect.EffectType.SILENCE: "res://assets/icons/status/silence.png",
	StatusEffect.EffectType.FREEZE: "res://assets/icons/status/freeze.png",
	StatusEffect.EffectType.BREAK: "res://assets/icons/status/break.png",
	StatusEffect.EffectType.MARK: "res://assets/icons/status/mark.png",
}

func _ready() -> void:
	# 连接鼠标事件
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# 初始化tooltip为隐藏
	if tooltip:
		tooltip.visible = false

## 设置状态图标数据
func setup(effect: StatusEffect, stacks: int) -> void:
	effect_data = effect
	current_stacks = stacks
	
	# 加载图标纹理
	_load_icon_texture()
	
	# 更新显示
	_update_display()

## AC4: 设置图标大小
func set_icon_size(size: Vector2) -> void:
	if icon_texture:
		icon_texture.custom_minimum_size = size

## 更新层数
func update_stacks(stacks: int) -> void:
	current_stacks = stacks
	_update_stack_label()

## 更新持续时间
func update_duration(duration: int) -> void:
	if effect_data:
		effect_data.duration = duration
		_update_duration_label()

## 加载图标纹理
func _load_icon_texture() -> void:
	if effect_data == null or icon_texture == null:
		return
	
	var texture_path = ICON_TEXTURES.get(effect_data.effect_type, "")
	
	# 如果纹理文件存在,加载它
	if ResourceLoader.exists(texture_path):
		icon_texture.texture = load(texture_path)
	else:
		# 使用占位符颜色
		_create_placeholder_texture()

## 创建占位符纹理(当图标文件不存在时)
func _create_placeholder_texture() -> void:
	# 根据状态类型使用不同颜色
	var color = _get_status_color()
	
	# 创建简单的ColorRect作为占位符
	var color_rect = ColorRect.new()
	color_rect.color = color
	color_rect.custom_minimum_size = Vector2(32, 32)
	
	# 替换TextureRect
	if icon_texture and icon_texture.get_parent():
		var parent = icon_texture.get_parent()
		var index = icon_texture.get_index()
		parent.remove_child(icon_texture)
		parent.add_child(color_rect)
		parent.move_child(color_rect, index)
		icon_texture = null

## 获取状态类型对应的颜色
func _get_status_color() -> Color:
	if effect_data == null:
		return Color.GRAY
	
	# 根据状态类型返回颜色
	match effect_data.effect_type:
		StatusEffect.EffectType.BURN:
			return Color(1.0, 0.3, 0.0)  # 橙红色
		StatusEffect.EffectType.POISON:
			return Color(0.3, 0.8, 0.3)  # 绿色
		StatusEffect.EffectType.FREEZE:
			return Color(0.3, 0.6, 1.0)  # 蓝色
		StatusEffect.EffectType.REGEN:
			return Color(0.0, 1.0, 0.5)  # 青绿色
		StatusEffect.EffectType.STRENGTH_UP, StatusEffect.EffectType.FOCUS, StatusEffect.EffectType.SHIELD:
			return Color(0.3, 0.8, 1.0)  # 浅蓝色(增益)
		StatusEffect.EffectType.WEAKEN, StatusEffect.EffectType.VULNERABLE, StatusEffect.EffectType.BLIND:
			return Color(0.8, 0.3, 0.8)  # 紫色(减益)
		StatusEffect.EffectType.STUN, StatusEffect.EffectType.ROOT, StatusEffect.EffectType.SILENCE:
			return Color(1.0, 0.8, 0.0)  # 黄色(控制)
		_:
			return Color.GRAY

## 更新显示
func _update_display() -> void:
	_update_duration_label()
	_update_stack_label()

## 更新持续时间标签
func _update_duration_label() -> void:
	if duration_label == null or effect_data == null:
		return
	
	# 显示剩余回合数
	if effect_data.duration > 0:
		duration_label.text = str(effect_data.duration)
		duration_label.visible = true
	else:
		duration_label.visible = false

## 更新层数标签
func _update_stack_label() -> void:
	if stack_label == null:
		return
	
	# 只有支持堆叠的状态才显示层数
	if effect_data and effect_data.can_stack and current_stacks > 1:
		stack_label.text = "x%d" % current_stacks
		stack_label.visible = true
	else:
		stack_label.visible = false

## 鼠标进入 - 显示tooltip
func _on_mouse_entered() -> void:
	if tooltip and effect_data:
		tooltip.show_tooltip(effect_data, current_stacks)

## 鼠标离开 - 隐藏tooltip
func _on_mouse_exited() -> void:
	if tooltip:
		tooltip.hide_tooltip()