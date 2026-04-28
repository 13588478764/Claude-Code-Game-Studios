## StatusUITestController
## 测试场景控制脚本,用于演示状态UI系统
## 
## 用于Story 004的手动测试

extends Node2D

@onready var status_manager: StatusEffectManager = $StatusEffectManager
@onready var status_icon_bar: StatusIconBar = $CanvasLayer/StatusIconBar
@onready var status_visual_feedback: StatusVisualFeedback = $TestCharacter/StatusVisualFeedback
@onready var test_character: Node2D = $TestCharacter

# 按钮引用
@onready var apply_burn_button: Button = $CanvasLayer/TestControls/ApplyBurnButton
@onready var apply_poison_button: Button = $CanvasLayer/TestControls/ApplyPoisonButton
@onready var apply_regen_button: Button = $CanvasLayer/TestControls/ApplyRegenButton
@onready var apply_shield_button: Button = $CanvasLayer/TestControls/ApplyShieldButton
@onready var remove_all_button: Button = $CanvasLayer/TestControls/RemoveAllButton
@onready var toggle_low_memory_button: Button = $CanvasLayer/TestControls/ToggleLowMemoryButton
@onready var res_1080p_button: Button = $CanvasLayer/TestControls/Res1080pButton
@onready var res_1440p_button: Button = $CanvasLayer/TestControls/Res1440pButton
@onready var res_21_9_button: Button = $CanvasLayer/TestControls/Res21_9Button

func _ready() -> void:
	# 设置StatusIconBar
	status_icon_bar.setup(status_manager)
	
	# 设置StatusVisualFeedback
	status_visual_feedback.setup(test_character, status_manager)
	
	# 连接按钮信号
	apply_burn_button.pressed.connect(_on_apply_burn_pressed)
	apply_poison_button.pressed.connect(_on_apply_poison_pressed)
	apply_regen_button.pressed.connect(_on_apply_regen_pressed)
	apply_shield_button.pressed.connect(_on_apply_shield_pressed)
	remove_all_button.pressed.connect(_on_remove_all_pressed)
	toggle_low_memory_button.pressed.connect(_on_toggle_low_memory_pressed)
	res_1080p_button.pressed.connect(_on_res_1080p_pressed)
	res_1440p_button.pressed.connect(_on_res_1440p_pressed)
	res_21_9_button.pressed.connect(_on_res_21_9_pressed)
	
	print("[StatusUITest] 测试场景已准备就绪")
	print("[StatusUITest] 使用左侧按钮测试状态UI功能")

## 施加燃烧状态
func _on_apply_burn_pressed() -> void:
	var burn_effect = StatusEffect.new()
	burn_effect.effect_type = StatusEffect.EffectType.BURN
	burn_effect.duration = 3
	burn_effect.coefficient = 30.0
	burn_effect.can_stack = true
	burn_effect.max_stacks = 3
	
	status_manager.apply_status(burn_effect)
	print("[StatusUITest] 施加燃烧状态")

## 施加中毒状态
func _on_apply_poison_pressed() -> void:
	var poison_effect = StatusEffect.new()
	poison_effect.effect_type = StatusEffect.EffectType.POISON
	poison_effect.duration = 5
	poison_effect.coefficient = 20.0
	poison_effect.can_stack = true
	poison_effect.max_stacks = 5
	
	status_manager.apply_status(poison_effect)
	print("[StatusUITest] 施加中毒状态")

## 施加再生状态
func _on_apply_regen_pressed() -> void:
	var regen_effect = StatusEffect.new()
	regen_effect.effect_type = StatusEffect.EffectType.REGEN
	regen_effect.duration = 4
	regen_effect.coefficient = 50.0
	regen_effect.can_stack = false
	
	status_manager.apply_status(regen_effect)
	print("[StatusUITest] 施加再生状态")

## 施加护盾状态
func _on_apply_shield_pressed() -> void:
	var shield_effect = StatusEffect.new()
	shield_effect.effect_type = StatusEffect.EffectType.SHIELD
	shield_effect.duration = 2
	shield_effect.coefficient = 100.0
	shield_effect.can_stack = false
	
	status_manager.apply_status(shield_effect)
	print("[StatusUITest] 施加护盾状态")

## 移除所有状态
func _on_remove_all_pressed() -> void:
	# 复制列表以避免在迭代时修改
	var effects_to_remove = status_manager.active_effects.duplicate()
	
	for effect in effects_to_remove:
		status_manager.remove_status(effect.effect_type)
	
	print("[StatusUITest] 移除所有状态")

## 切换低内存模式
func _on_toggle_low_memory_pressed() -> void:
	if GameConfigManager:
		GameConfigManager.manual_override = true
		GameConfigManager.manual_low_memory_mode = not GameConfigManager.low_memory_mode
		GameConfigManager.check_memory_and_update_mode()
		
		var mode_text = "启用" if GameConfigManager.low_memory_mode else "禁用"
		print("[StatusUITest] 低内存模式: %s" % mode_text)

## 切换到1920x1080分辨率
func _on_res_1080p_pressed() -> void:
	get_window().size = Vector2i(1920, 1080)
	print("[StatusUITest] 切换到1920x1080分辨率")

## 切换到2560x1440分辨率
func _on_res_1440p_pressed() -> void:
	get_window().size = Vector2i(2560, 1440)
	print("[StatusUITest] 切换到2560x1440分辨率")

## 切换到3440x1440分辨率(21:9)
func _on_res_21_9_pressed() -> void:
	get_window().size = Vector2i(3440, 1440)
	print("[StatusUITest] 切换到3440x1440分辨率(21:9)")