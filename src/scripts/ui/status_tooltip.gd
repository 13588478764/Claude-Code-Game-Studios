## StatusTooltip Control节点
## 显示状态效果的详细信息提示框
## 
## AC4: UI适配不同分辨率
## 遵循ADR-001: 使用Control节点实现UI

class_name StatusTooltip
extends PanelContainer

## UI节点引用
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var duration_label: Label = $VBoxContainer/DurationLabel
@onready var stack_label: Label = $VBoxContainer/StackLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel

## AC4: 最小字号保证(所有分辨率下)
const MIN_FONT_SIZE: int = 12

## 状态类型名称映射
const TYPE_NAMES: Dictionary = {
	StatusEffect.EffectType.BURN: "持续伤害",
	StatusEffect.EffectType.POISON: "持续伤害",
	StatusEffect.EffectType.BLEED: "持续伤害",
	StatusEffect.EffectType.REGEN: "持续恢复",
	StatusEffect.EffectType.STRENGTH_UP: "增益",
	StatusEffect.EffectType.FOCUS: "增益",
	StatusEffect.EffectType.SHIELD: "增益",
	StatusEffect.EffectType.WEAKEN: "减益",
	StatusEffect.EffectType.VULNERABLE: "减益",
	StatusEffect.EffectType.BLIND: "减益",
	StatusEffect.EffectType.STUN: "控制",
	StatusEffect.EffectType.ROOT: "控制",
	StatusEffect.EffectType.SILENCE: "控制",
	StatusEffect.EffectType.FREEZE: "控制",
	StatusEffect.EffectType.BREAK: "特殊",
	StatusEffect.EffectType.MARK: "特殊",
}

## 状态效果描述映射
const EFFECT_DESCRIPTIONS: Dictionary = {
	StatusEffect.EffectType.BURN: "每回合造成{value}点火属性伤害",
	StatusEffect.EffectType.POISON: "每回合造成{value}点毒素伤害",
	StatusEffect.EffectType.BLEED: "受击时额外造成{value}点真实伤害",
	StatusEffect.EffectType.REGEN: "每回合恢复{value}点生命值",
	StatusEffect.EffectType.STRENGTH_UP: "攻击力提升{value}%",
	StatusEffect.EffectType.FOCUS: "命中率+{value}%,暴击率+5%",
	StatusEffect.EffectType.SHIELD: "吸收{value}点伤害",
	StatusEffect.EffectType.WEAKEN: "攻击力降低{value}%",
	StatusEffect.EffectType.VULNERABLE: "受到伤害增加{value}%",
	StatusEffect.EffectType.BLIND: "命中率降低{value}%",
	StatusEffect.EffectType.STUN: "无法行动",
	StatusEffect.EffectType.ROOT: "无法移动",
	StatusEffect.EffectType.SILENCE: "无法使用技能",
	StatusEffect.EffectType.FREEZE: "无法行动,受击必暴击",
	StatusEffect.EffectType.BREAK: "架势值归零,易伤",
	StatusEffect.EffectType.MARK: "特定来源伤害增加{value}%",
}

func _ready() -> void:
	# 初始化为隐藏
	visible = false
	
	# AC4: 确保字体大小不小于最小值
	_ensure_min_font_size()

## AC4: 确保所有Label的字体大小不小于最小值
func _ensure_min_font_size() -> void:
	var labels = [name_label, type_label, duration_label, stack_label, description_label]
	
	for label in labels:
		if label == null:
			continue
		
		# 获取当前字体大小
		var font_size = label.get_theme_font_size("font_size")
		
		# 如果小于最小值,设置为最小值
		if font_size < MIN_FONT_SIZE:
			label.add_theme_font_size_override("font_size", MIN_FONT_SIZE)

## 显示tooltip
func show_tooltip(effect: StatusEffect, stacks: int) -> void:
	if effect == null:
		return
	
	# 更新内容
	_update_content(effect, stacks)
	
	# 显示tooltip
	visible = true
	
	# 调整位置(在鼠标旁边)
	_update_position()

## 隐藏tooltip
func hide_tooltip() -> void:
	visible = false

## 更新tooltip内容
func _update_content(effect: StatusEffect, stacks: int) -> void:
	# 状态名称
	if name_label:
		name_label.text = _get_effect_name(effect.effect_type)
	
	# 状态类型
	if type_label:
		var type_name = TYPE_NAMES.get(effect.effect_type, "未知")
		type_label.text = "类型: %s" % type_name
	
	# 剩余回合数
	if duration_label:
		if effect.duration > 0:
			duration_label.text = "剩余回合: %d" % effect.duration
			duration_label.visible = true
		else:
			duration_label.visible = false
	
	# 层数
	if stack_label:
		if effect.can_stack and stacks > 1:
			stack_label.text = "层数: %d" % stacks
			stack_label.visible = true
		else:
			stack_label.visible = false
	
	# 效果描述
	if description_label:
		var desc = EFFECT_DESCRIPTIONS.get(effect.effect_type, "未知效果")
		# 替换占位符
		desc = desc.replace("{value}", str(effect.coefficient))
		description_label.text = desc

## 获取状态效果名称
func _get_effect_name(effect_type: StatusEffect.EffectType) -> String:
	match effect_type:
		StatusEffect.EffectType.BURN:
			return "燃烧"
		StatusEffect.EffectType.POISON:
			return "中毒"
		StatusEffect.EffectType.BLEED:
			return "流血"
		StatusEffect.EffectType.REGEN:
			return "再生"
		StatusEffect.EffectType.STRENGTH_UP:
			return "力量提升"
		StatusEffect.EffectType.FOCUS:
			return "专注"
		StatusEffect.EffectType.SHIELD:
			return "护盾"
		StatusEffect.EffectType.WEAKEN:
			return "虚弱"
		StatusEffect.EffectType.VULNERABLE:
			return "易伤"
		StatusEffect.EffectType.BLIND:
			return "致盲"
		StatusEffect.EffectType.STUN:
			return "眩晕"
		StatusEffect.EffectType.ROOT:
			return "定身"
		StatusEffect.EffectType.SILENCE:
			return "沉默"
		StatusEffect.EffectType.FREEZE:
			return "冻结"
		StatusEffect.EffectType.BREAK:
			return "破防"
		StatusEffect.EffectType.MARK:
			return "标记"
		_:
			return "未知状态"

## 更新tooltip位置(跟随鼠标)
func _update_position() -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 偏移量,避免遮挡鼠标
	var offset = Vector2(10, 10)
	
	# 设置位置
	global_position = mouse_pos + offset
	
	# 确保不超出屏幕边界
	var viewport_size = get_viewport().size
	var tooltip_size = size
	
	# 右边界检查
	if global_position.x + tooltip_size.x > viewport_size.x:
		global_position.x = mouse_pos.x - tooltip_size.x - offset.x
	
	# 下边界检查
	if global_position.y + tooltip_size.y > viewport_size.y:
		global_position.y = mouse_pos.y - tooltip_size.y - offset.y