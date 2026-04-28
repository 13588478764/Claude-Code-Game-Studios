# 装备UI视觉效果系统
# 实现品阶颜色编码、状态指示、动画效果和套装效果显示

extends Control

# 信号定义
signal visual_effect_played(effect_name: String)

# 品阶颜色映射
var tier_colors: Dictionary = {
	1: Color.WHITE,      # 普通 - 白色
	2: Color.BLUE,        # 稀有 - 蓝色
	3: Color.PURPLE,      # 史诗 - 紫色
	4: Color.YELLOW       # 传说 - 金色
}

# 品阶名称映射
var tier_names: Dictionary = {
	1: "普通",
	2: "稀有", 
	3: "史诗",
	4: "传说"
}

# 状态指示器颜色
var status_colors: Dictionary = {
	"normal": Color.WHITE,
	"positive": Color.GREEN,
	"negative": Color.RED,
	"warning": Color.YELLOW,
	"locked": Color.GRAY
}

# 装备槽位字典
var equipment_slots: Dictionary = {}
# 背包物品列表
var backpack_items: Array = []

# 初始化
func _ready():
	print("装备UI视觉效果系统已初始化")
	
	# 初始化数据
	initialize_data()

# 初始化数据
func initialize_data():
	# 初始化装备槽位
	var slot_types = [
		"weapon_main", "weapon_offhand", "head", "body", "hands",
		"feet", "necklace", "ring_1", "ring_2", "belt",
		"inner_force_1", "inner_force_2", "inner_force_3", "lightness_1"
	]
	
	for slot_type in slot_types:
		equipment_slots[slot_type] = null
	
	# 初始化背包物品
	var sample_items = [
		{"id": "sword_001", "name": "青钢剑", "type": "weapon", "tier": 1, "attack": 10, "defense": 0},
		{"id": "armor_001", "name": "布衣", "type": "armor", "tier": 1, "attack": 0, "defense": 5},
		{"id": "ring_001", "name": "铜戒指", "type": "accessory", "tier": 1, "attack": 2, "defense": 2},
		{"id": "sword_002", "name": "精钢剑", "type": "weapon", "tier": 2, "attack": 15, "defense": 0},
		{"id": "armor_002", "name": "皮甲", "type": "armor", "tier": 2, "attack": 0, "defense": 8},
		{"id": "necklace_001", "name": "珍珠项链", "type": "accessory", "tier": 2, "attack": 3, "defense": 5},
		{"id": "sword_003", "name": "玄铁重剑", "type": "weapon", "tier": 3, "attack": 25, "defense": 0},
		{"id": "armor_003", "name": "金丝软甲", "type": "armor", "tier": 3, "attack": 0, "defense": 15},
		{"id": "ring_002", "name": "玉扳指", "type": "accessory", "tier": 3, "attack": 5, "defense": 5}
	]
	
	backpack_items = sample_items

# 应用品阶颜色编码
func apply_tier_color_coding(ui_element: Control, tier: int):
	if tier_colors.has(tier):
		var color = tier_colors[tier]
		
		# 根据UI元素类型应用颜色
		if ui_element is Button:
			ui_element.add_theme_color_override("font_color", color)
		elif ui_element is Label:
			ui_element.add_theme_color_override("font_color", color)
		elif ui_element is TextureRect:
			ui_element.modulate = color
		else:
			# 对于其他类型的控件，尝试应用颜色
			ui_element.add_theme_color_override("font_color", color)
		
		# 对于高品阶物品，添加特殊效果
		if tier == 3:  # 史诗
			add_glow_effect(ui_element)
		elif tier == 4:  # 传说
			add_golden_particles(ui_element)
	
	emit_signal("visual_effect_played", "tier_color_applied")

# 添加发光效果
func add_glow_effect(ui_element: Control):
	# 在实际实现中，这里会添加发光Shader或使用Godot的发光功能
	print("为UI元素添加发光效果: " + str(ui_element))

# 添加金色粒子效果
func add_golden_particles(ui_element: Control):
	# 在实际实现中，这里会创建粒子系统
	print("为UI元素添加金色粒子效果: " + str(ui_element))

# 显示状态指示
func show_status_indicators(ui_element: Control, status: String):
	if status_colors.has(status):
		var color = status_colors[status]
		
		# 应用状态颜色
		if ui_element is Button:
			ui_element.add_theme_color_override("font_color", color)
		elif ui_element is Label:
			ui_element.add_theme_color_override("font_color", color)
		elif ui_element is TextureRect:
			ui_element.modulate = color
		else:
			ui_element.add_theme_color_override("font_color", color)
		
		# 根据状态添加特殊视觉效果
		match status:
			"positive":
				add_positive_animation(ui_element)
			"negative":
				add_negative_animation(ui_element)
			"warning":
				add_warning_animation(ui_element)
			"locked":
				add_locked_indicator(ui_element)
	
	emit_signal("visual_effect_played", "status_indicator_shown")

# 添加正面动画
func add_positive_animation(ui_element: Control):
	# 在实际实现中，这里会播放一个正面的动画效果
	print("播放正面动画: " + str(ui_element))

# 添加负面动画
func add_negative_animation(ui_element: Control):
	# 在实际实现中，这里会播放一个负面的动画效果
	print("播放负面动画: " + str(ui_element))

# 添加警告动画
func add_warning_animation(ui_element: Control):
	# 在实际实现中，这里会播放一个警告的动画效果
	print("播放警告动画: " + str(ui_element))

# 添加锁定指示器
func add_locked_indicator(ui_element: Control):
	# 在实际实现中，这里会添加一个锁定图标
	print("添加锁定指示器: " + str(ui_element))

# 播放动画效果
func play_animation(animation_type: String, target: Control = null):
	match animation_type:
		"equip_success":
			play_equip_success_animation(target)
		"equip_failure":
			play_equip_failure_animation(target)
		"tier_upgrade":
			play_tier_upgrade_animation(target)
		"item_pickup":
			play_item_pickup_animation(target)
		_:
			print("未知的动画类型: " + animation_type)

# 播放装备成功动画
func play_equip_success_animation(target: Control):
	# 播放绿色闪光动画
	if target:
		var original_color = target.get_theme_color("font_color", "normal")
		# 在实际实现中，这里会使用Tween来创建动画
		print("播放装备成功动画到目标: " + str(target))
	
	emit_signal("visual_effect_played", "equip_success_animation")

# 播放装备失败动画
func play_equip_failure_animation(target: Control):
	# 播放红色震动动画
	if target:
		# 在实际实现中，这里会使用Tween来创建震动效果
		print("播放装备失败动画到目标: " + str(target))
	
	emit_signal("visual_effect_played", "equip_failure_animation")

# 播放品阶升级动画
func play_tier_upgrade_animation(target: Control):
	# 播放对应颜色的粒子爆发效果
	if target:
		print("播放品阶升级动画到目标: " + str(target))
	
	emit_signal("visual_effect_played", "tier_upgrade_animation")

# 播放物品拾取动画
func play_item_pickup_animation(target: Control):
	# 播放物品拾取动画
	if target:
		print("播放物品拾取动画到目标: " + str(target))
	
	emit_signal("visual_effect_played", "item_pickup_animation")

# 显示套装效果
func show_set_effects(set_effects: Array, target: Control = null):
	var set_info = "套装效果:\n"
	
	for effect in set_effects:
		set_info += effect + "\n"
	
	print("显示套装效果: " + set_info)
	
	if target:
		# 在实际实现中，这里会在目标控件上显示套装效果
		print("在目标上显示套装效果: " + str(target))
	
	emit_signal("visual_effect_played", "set_effects_shown")

# 显示元素属性
func show_elemental_attributes(elemental_attrs: Dictionary, target: Control = null):
	var element_info = "元素属性:\n"
	
	for element in elemental_attrs:
		element_info += element + ": " + str(elemental_attrs[element]) + "\n"
	
	print("显示元素属性: " + element_info)
	
	if target:
		# 在实际实现中，这里会在目标控件上显示元素属性
		print("在目标上显示元素属性: " + str(target))
	
	emit_signal("visual_effect_played", "elemental_attributes_shown")

# 更新装备槽位视觉状态
func update_slot_visual_state(slot_type: String, equipment: Dictionary = {}):
	var slot_control = equipment_slots.get(slot_type, null)
	
	if slot_control and equipment.size() > 0:
		# 应用品阶颜色
		apply_tier_color_coding(slot_control, equipment.tier)
		
		# 根据装备状态更新视觉效果
		var status = determine_slot_status(slot_type, equipment)
		show_status_indicators(slot_control, status)
	
	emit_signal("visual_effect_played", "slot_visual_state_updated")

# 确定槽位状态
func determine_slot_status(slot_type: String, equipment: Dictionary) -> String:
	# 简化的状态判断逻辑
	# 在实际实现中，这里会根据角色等级、境界等判断状态
	
	if equipment.size() == 0:
		return "normal"
	
	# 检查是否满足装备条件
	var meets_requirements = check_equipment_requirements(equipment)
	
	if meets_requirements:
		return "positive"
	else:
		return "negative"

# 检查装备需求
func check_equipment_requirements(equipment: Dictionary) -> bool:
	# 简化的检查逻辑
	# 在实际实现中，这里会检查角色等级、境界、职业等要求
	return true

# 高亮推荐装备
func highlight_recommended_items(recommended_items: Array):
	for item in recommended_items:
		var item_ui = find_ui_element_for_item(item)
		if item_ui:
			# 应用推荐高亮效果
			item_ui.add_theme_color_override("border_color", Color.YELLOW)
			item_ui.add_theme_color_override("border_width_left", 2)
			item_ui.add_theme_color_override("border_width_right", 2)
			item_ui.add_theme_color_override("border_width_top", 2)
			item_ui.add_theme_color_override("border_width_bottom", 2)

# 查找物品的UI元素
func find_ui_element_for_item(item: Dictionary) -> Control:
	# 在实际实现中，这里会查找与物品对应的UI控件
	return null

# 创建品阶边框效果
func create_tier_border_effect(tier: int, target: Control):
	if tier_colors.has(tier):
		var color = tier_colors[tier]
		
		# 根据品阶创建不同的边框效果
		match tier:
			1: # 普通 - 简单边框
				target.add_theme_stylebox_override("normal", create_simple_border(color))
			2: # 稀有 - 发光边框
				target.add_theme_stylebox_override("normal", create_glowing_border(color))
			3: # 史诗 - 动态发光边框
				target.add_theme_stylebox_override("normal", create_animated_glowing_border(color))
			4: # 传说 - 粒子特效边框
				target.add_theme_stylebox_override("normal", create_particle_border(color))

# 创建简单边框
func create_simple_border(color: Color) -> StyleBox:
	var stylebox = StyleBoxFlat.new()
	stylebox.border_color = color
	stylebox.border_width_left = 1
	stylebox.border_width_right = 1
	stylebox.border_width_top = 1
	stylebox.border_width_bottom = 1
	return stylebox

# 创建发光边框
func create_glowing_border(color: Color) -> StyleBox:
	var stylebox = StyleBoxFlat.new()
	stylebox.border_color = color
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	# 在实际实现中，这里会添加发光Shader
	return stylebox

# 创建动画发光边框
func create_animated_glowing_border(color: Color) -> StyleBox:
	var stylebox = StyleBoxFlat.new()
	stylebox.border_color = color
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	# 在实际实现中，这里会添加动画发光效果
	return stylebox

# 创建粒子边框
func create_particle_border(color: Color) -> StyleBox:
	var stylebox = StyleBoxFlat.new()
	stylebox.border_color = color
	stylebox.border_width_left = 3
	stylebox.border_width_right = 3
	stylebox.border_width_top = 3
	stylebox.border_width_bottom = 3
	# 在实际实现中，这里会添加粒子系统
	return stylebox

# 更新背包物品视觉效果
func update_backpack_item_visuals():
	for item in backpack_items:
		var item_ui = find_ui_element_for_item(item)
		if item_ui:
			# 应用品阶颜色编码
			apply_tier_color_coding(item_ui, item.tier)
			
			# 创建品阶边框效果
			create_tier_border_effect(item.tier, item_ui)

# 显示装备属性差异
func show_attribute_differences(current_attrs: Dictionary, new_attrs: Dictionary, target: Control):
	var diff_text = "属性差异:\n"
	
	for attr in new_attrs:
		if current_attrs.has(attr):
			var diff = new_attrs[attr] - current_attrs[attr]
			if diff > 0:
				diff_text += attr + ": " + str(current_attrs[attr]) + " → " + str(new_attrs[attr]) + " (+" + str(diff) + ")\n"
			elif diff < 0:
				diff_text += attr + ": " + str(current_attrs[attr]) + " → " + str(new_attrs[attr]) + " (" + str(diff) + ")\n"
			else:
				diff_text += attr + ": " + str(current_attrs[attr]) + " → " + str(new_attrs[attr]) + " (无变化)\n"
		else:
			diff_text += attr + ": 0 → " + str(new_attrs[attr]) + " (新增)\n"
	
	# 在目标控件上显示差异
	if target is Label:
		target.text = diff_text
	elif target is RichTextLabel:
		target.text = diff_text
	
	emit_signal("visual_effect_played", "attribute_differences_shown")

# 创建装备提示框
func create_equipment_tooltip(equipment: Dictionary) -> Control:
	var tooltip = Panel.new()
	tooltip.size = Vector2(300, 200)
	
	var tooltip_text = create_equipment_tooltip_text(equipment)
	
	var label = Label.new()
	label.text = tooltip_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tooltip.add_child(label)
	
	return tooltip

# 创建装备提示文本
func create_equipment_tooltip_text(equipment: Dictionary) -> String:
	var text = "【" + tier_names.get(equipment.tier, "未知") + "】" + equipment.name + "\n"
	text += "类型: " + equipment.type + "\n"
	
	if equipment.has("attack"):
		text += "攻击力: " + str(equipment.attack) + "\n"
	if equipment.has("defense"):
		text += "防御力: " + str(equipment.defense) + "\n"
	
	# 添加其他属性
	text += "品阶: " + str(equipment.tier) + "\n"
	text += "ID: " + equipment.id + "\n"
	
	return text

# 颜色盲友好模式
func enable_color_blind_mode(ui_element: Control):
	# 在颜色盲友好模式下，使用形状+颜色双重标识
	print("启用颜色盲友好模式")
	
	# 在实际实现中，这里会修改UI元素以使用形状+颜色双重标识
	if ui_element is Button:
		# 添加图标或形状标识
		pass

# 性能优化：批量更新视觉效果
func batch_update_visual_effects(effects: Array):
	for effect in effects:
		var type = effect.get("type", "")
		var target = effect.get("target", null)
		var data = effect.get("data", {})
		
		match type:
			"tier_color":
				apply_tier_color_coding(target, data.get("tier", 1))
			"status_indicator":
				show_status_indicators(target, data.get("status", "normal"))
			"animation":
				play_animation(data.get("animation_type", ""), target)
			"set_effect":
				show_set_effects(data.get("effects", []), target)
			_:
				print("未知的批量效果类型: " + type)