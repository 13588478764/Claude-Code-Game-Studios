## CombatHud
## CombatHud系统
##
## 主要功能：
## - 待补充

extends Node

class_name CombatHud

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

# 战斗HUD显示
# 实现常驻HUD元素、状态效果图标栏、伤害飘字和分辨率适配

# 信号定义
signal hud_updated

# UI元素引用
@onready var character_status_container = $CombatHUD/CharacterStatusContainer
@onready var turn_order_container = $CombatHUD/TurnOrderContainer
@onready var status_icons_container = $CombatHUD/StatusIconsContainer
@onready var floating_text_container = $CombatHUD/FloatingTextContainer

# HUD元素预制体路径
var character_status_prefab = preload("res://src/scenes/ui/character_status.tscn")
var turn_order_prefab = preload("res://src/scenes/ui/turn_order.tscn")
var status_icon_prefab = preload("res://src/scenes/ui/status_icon.tscn")

# 分辨率适配参数
var base_resolution = Vector2(1920, 1080)
var current_resolution = Vector2()

# 初始化
func _ready():
	# 获取当前分辨率
	current_resolution = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), 
	                             ProjectSettings.get_setting("display/window/size/viewport_height"))
	
	# 连接到战斗系统信号
	# 这里假设CombatSystem是全局可用的单例或可以通过其他方式访问
	# CombatSystem.connect("turn_changed", _on_turn_changed)
	# CombatSystem.connect("damage_dealt", _on_damage_dealt)
	# StatusEffectSystem.connect("status_applied", _on_status_applied)
	
	# 初始化HUD元素
	initialize_hud_elements()
	
	# 发送HUD更新信号
	emit_signal("hud_updated")

# 初始化HUD元素
func initialize_hud_elements():
	# 初始化角色状态栏
	initialize_character_status_bars()
	
	# 初始化行动队列
	initialize_turn_order_queue()
	
	# 初始化状态效果图标栏
	initialize_status_icons()

# 初始化角色状态栏
func initialize_character_status_bars():
	# 清除现有状态栏
	for child in character_status_container.get_children():
		child.queue_free()
	
	# 这里应该从战斗系统获取当前战斗中的角色数据
	# 为了演示，我们创建两个示例角色状态栏
	for i in range(2):
		var status_bar = character_status_prefab.instantiate()
		character_status_container.add_child(status_bar)
		
		# 设置示例数据
		var example_data = {
			"name": "角色 " + str(i+1),
			"hp": 100 - i*20,
			"max_hp": 100,
			"qi": 80 - i*10,
			"max_qi": 100,
			"poise": 90 - i*15,
			"max_poise": 100
		}
		
		status_bar.update_character_status(example_data)

# 初始化行动队列
func initialize_turn_order_queue():
	# 清除现有队列
	for child in turn_order_container.get_children():
		child.queue_free()
	
	# 这里应该从战斗系统获取当前行动队列数据
	# 为了演示，我们创建示例队列
	for i in range(5):
		var turn_item = turn_order_prefab.instantiate()
		turn_order_container.add_child(turn_item)
		
		# 设置示例数据
		var example_data = {
			"name": "角色 " + str(i+1),
			"is_current": i == 0,  # 第一个为当前行动单位
			"speed": 100 - i*10
		}
		
		turn_item.update_turn_order(example_data)

# 初始化状态效果图标栏
func initialize_status_icons():
	# 清除现有图标
	for child in status_icons_container.get_children():
		child.queue_free()
	
	# 这里应该从状态效果系统获取当前状态效果数据
	# 为了演示，我们创建示例状态图标
	var example_statuses = [
		{"name": "中毒", "icon": "poison", "duration": 3},
		{"name": "加速", "icon": "speed", "duration": 2}
	]
	
	for status in example_statuses:
		var icon = status_icon_prefab.instantiate()
		status_icons_container.add_child(icon)
		
		icon.update_status_icon(status)

# 更新角色状态栏
func update_character_status_bar(character_data):
	# 查找对应的角色状态栏并更新
	for child in character_status_container.get_children():
		if child.has_method("update_character_status"):
			# 这里需要根据实际角色标识来匹配
			child.update_character_status(character_data)
	
	emit_signal("hud_updated")

# 更新行动队列
func update_turn_order_queue(queue_data):
	# 清除现有队列
	for child in turn_order_container.get_children():
		child.queue_free()
	
	# 重新创建队列
	for data in queue_data:
		var turn_item = turn_order_prefab.instantiate()
		turn_order_container.add_child(turn_item)
		turn_item.update_turn_order(data)
	
	emit_signal("hud_updated")

# 显示状态效果图标
func show_status_icons(status_effects):
	# 清除现有图标
	for child in status_icons_container.get_children():
		child.queue_free()
	
	# 创建新的状态效果图标
	for status in status_effects:
		var icon = status_icon_prefab.instantiate()
		status_icons_container.add_child(icon)
		icon.update_status_icon(status)
	
	emit_signal("hud_updated")

# 显示伤害/状态飘字
func show_floating_text(text_data):
	# 创建飘字节点
	var floating_text = Label.new()
	floating_text.text = str(text_data.value)
	floating_text.add_theme_color_override("font_color", get_damage_color(text_data.type))
	floating_text.position = text_data.position
	floating_text_container.add_child(floating_text)
	
	# 设置飘字动画
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(floating_text, "position", text_data.position + Vector2(0, -100), 1.0)
	tween.tween_property(floating_text, "modulate:a", 0.0, 1.0)
	tween.tween_callback(floating_text.queue_free)
	
	emit_signal("hud_updated")

# 获取伤害颜色
func get_damage_color(damage_type):
	if damage_type == "外功":
		return Color.WHITE
	elif damage_type == "内功":
		return Color.BLUE
	elif damage_type == "暴击":
		return Color.GOLD
	elif damage_type == "真实":
		return Color.RED
	else:
		return Color.WHITE

# 分辨率适配
func adapt_to_resolution():
	# 根据当前分辨率调整UI元素位置和大小
	var scale_factor = Vector2(
		current_resolution.x / base_resolution.x,
		current_resolution.y / base_resolution.y
	)
	
	# 应用缩放到整个HUD
	$CombatHUD.scale = scale_factor

# 处理分辨率变化
func _on_resolution_changed():
	current_resolution = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), 
	                             ProjectSettings.get_setting("display/window/size/viewport_height"))
	adapt_to_resolution()

# 连接战斗系统信号
func connect_combat_signals():
	# 连接到战斗系统信号
	# CombatSystem.connect("turn_changed", _on_turn_changed)
	# CombatSystem.connect("damage_dealt", _on_damage_dealt)
	# StatusEffectSystem.connect("status_applied", _on_status_applied)
	pass

# 战斗系统信号处理函数
func _on_turn_changed(turn_data):
	update_turn_order_queue(turn_data)

func _on_damage_dealt(damage_data):
	show_floating_text(damage_data)

func _on_status_applied(status_data):
	show_status_icons([status_data])