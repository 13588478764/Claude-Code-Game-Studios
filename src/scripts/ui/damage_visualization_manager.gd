extends CanvasLayer

# 伤害可视化管理器
# 实现伤害数字显示、暴击特效、伤害预览和详细分解界面

# 伤害类型枚举（与DamageCalculator保持一致）
enum DamageType {
	WAI_GONG,    # 外功伤害
	NEI_GONG,    # 内功伤害
	ZHEN_SHI     # 真实伤害
}

# 伤害数字预设
class DamageNumber:
	var label: Label
	var damage_value: int
	var damage_type: DamageType
	var is_critical: bool
	var animation: Tween

# 伤害数字池
var damage_number_pool: Array = []
var pool_size: int = 20

# 伤害预览标签
var damage_preview_label: Label = null

# 详细伤害分解界面
var damage_breakdown_panel: Panel = null
var breakdown_label: Label = null

# 初始化
func _ready():
	# 创建伤害数字池
	for i in range(pool_size):
		var label = Label.new()
		label.visible = false
		label.add_theme_color_override("font_color", Color.WHITE)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		self.add_child(label)
		
		var damage_num = DamageNumber.new()
		damage_num.label = label
		damage_number_pool.append(damage_num)
	
	# 创建伤害预览标签
	damage_preview_label = Label.new()
	damage_preview_label.name = "DamagePreviewLabel"
	damage_preview_label.visible = false
	damage_preview_label.add_theme_color_override("font_color", Color.YELLOW)
	self.add_child(damage_preview_label)
	
	# 创建详细伤害分解界面
	damage_breakdown_panel = Panel.new()
	damage_breakdown_panel.name = "DamageBreakdownPanel"
	damage_breakdown_panel.visible = false
	damage_breakdown_panel.size = Vector2(400, 300)
	damage_breakdown_panel.position = Vector2(100, 100)
	self.add_child(damage_breakdown_panel)
	
	breakdown_label = Label.new()
	breakdown_label.name = "BreakdownLabel"
	breakdown_label.size = damage_breakdown_panel.size
	breakdown_label.position = Vector2(10, 10)
	damage_breakdown_panel.add_child(breakdown_label)

# 显示伤害数字
func show_damage_number(damage_value: int, damage_type: DamageType, is_critical: bool = false, position: Vector2 = Vector2.ZERO):
	# 从池中获取一个可用的伤害数字
	var damage_num: DamageNumber = get_available_damage_number()
	if damage_num == null:
		print("伤害数字池已满，无法显示更多伤害数字")
		return
	
	# 设置伤害数字内容
	damage_num.damage_value = damage_value
	damage_num.damage_type = damage_type
	damage_num.is_critical = is_critical
	
	# 设置颜色
	var color = get_damage_color(damage_type, is_critical)
	damage_num.label.add_theme_color_override("font_color", color)
	
	# 设置文本
	damage_num.label.text = str(damage_value)
	
	# 设置位置
	damage_num.label.position = position
	
	# 设置初始大小
	damage_num.label.scale = Vector2(1, 1)
	
	# 显示标签
	damage_num.label.visible = true
	
	# 如果是暴击，播放特效
	if is_critical:
		play_critical_animation(damage_num)
	else:
		play_normal_animation(damage_num)

# 获取可用的伤害数字
func get_available_damage_number() -> DamageNumber:
	for damage_num in damage_number_pool:
		if not damage_num.label.visible:
			return damage_num
	return null

# 获取伤害颜色
func get_damage_color(damage_type: DamageType, is_critical: bool) -> Color:
	if is_critical:
		return Color.GOLD  # 暴击为金色
	
	match damage_type:
		DamageType.WAI_GONG: return Color.WHITE  # 外功为白色
		DamageType.NEI_GONG: return Color.BLUE   # 内功为蓝色
		DamageType.ZHEN_SHI: return Color.RED    # 真实为红色
		_: return Color.WHITE

# 播放普通伤害动画
func play_normal_animation(damage_num: DamageNumber):
	# 创建动画
	var tween = Tween.new()
	self.add_child(tween)
	damage_num.animation = tween
	
	# 向上浮动
	tween.interpolate_property(damage_num.label, "position", 
		damage_num.label.position, 
		damage_num.label.position - Vector2(0, 50), 
		1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	# 淡出效果
	tween.interpolate_property(damage_num.label, "modulate:a", 
		1.0, 0.0, 
		1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	tween.start()
	
	# 动画结束后隐藏标签
	yield(tween, "tween_completed")
	damage_num.label.visible = false
	tween.queue_free()

# 播放暴击动画
func play_critical_animation(damage_num: DamageNumber):
	# 创建动画
	var tween = Tween.new()
	self.add_child(tween)
	damage_num.animation = tween
	
	# 放大效果
	tween.interpolate_property(damage_num.label, "scale", 
		Vector2(1, 1), 
		Vector2(1.5, 1.5), 
		0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	
	# 向上浮动
	tween.interpolate_property(damage_num.label, "position", 
		damage_num.label.position, 
		damage_num.label.position - Vector2(0, 80), 
		1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.1)
	
	# 闪烁效果
	tween.interpolate_property(damage_num.label, "modulate", 
		Color(1, 1, 1, 1), 
		Color(1, 1, 0, 1),  # 金色闪烁
		0.2, Tween.TRANS_SINE, Tween.EASE_IN_OUT, 0.15, 0.2)
	
	# 淡出效果
	tween.interpolate_property(damage_num.label, "modulate:a", 
		1.0, 0.0, 
		0.8, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, 0.2)
	
	tween.start()
	
	# 动画结束后隐藏标签
	yield(tween, "tween_completed")
	damage_num.label.visible = false
	tween.queue_free()

# 显示伤害预览
func show_damage_preview(expected_damage: int, position: Vector2 = Vector2(10, 10)):
	damage_preview_label.visible = true
	damage_preview_label.text = "预计伤害: %d" % expected_damage
	damage_preview_label.position = position

# 隐藏伤害预览
func hide_damage_preview():
	damage_preview_label.visible = false

# 显示详细伤害分解
func show_detailed_damage_breakdown(damage_data: Dictionary):
	# 构建伤害分解文本
	var breakdown_text = "伤害分解:\n"
	breakdown_text += "基础伤害: %d\n" % damage_data.get("base_damage", 0)
	breakdown_text += "防御减免: %d\n" % damage_data.get("defense_reduced", 0)
	breakdown_text += "暴击倍率: %.2fx\n" % damage_data.get("critical_multiplier", 1.0)
	breakdown_text += "其他修正: %.2fx\n" % damage_data.get("other_modifiers", 1.0)
	breakdown_text += "最终伤害: %d\n" % damage_data.get("final_damage", 0)
	
	breakdown_label.text = breakdown_text
	damage_breakdown_panel.visible = true

# 隐藏详细伤害分解
func hide_detailed_damage_breakdown():
	damage_breakdown_panel.visible = false

# 播放伤害反馈特效
func play_damage_feedback(damage_type: DamageType, is_critical: bool = false):
	# 这里可以添加粒子特效、屏幕震动等反馈
	if is_critical:
		# 暴击时添加屏幕震动效果
		print("播放暴击反馈特效")
	else:
		# 普通伤害反馈
		print("播放普通伤害反馈特效")

# 测试函数
func test_visualization():
	print("开始测试伤害可视化...")
	
	# 测试普通伤害
	show_damage_number(50, DamageType.WAI_GONG, false, Vector2(400, 300))
	
	# 测试暴击
	show_damage_number(120, DamageType.NEI_GONG, true, Vector2(420, 320))
	
	# 测试真实伤害
	show_damage_number(75, DamageType.ZHEN_SHI, false, Vector2(440, 340))
	
	# 测试伤害预览
	show_damage_preview(85, Vector2(100, 100))
	
	# 测试伤害分解
	var test_data = {
		"base_damage": 100,
		"defense_reduced": 30,
		"critical_multiplier": 1.5,
		"other_modifiers": 1.1,
		"final_damage": 115
	}
	show_detailed_damage_breakdown(test_data)
	
	print("伤害可视化测试完成")