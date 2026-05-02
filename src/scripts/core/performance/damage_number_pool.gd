## DamageNumberPool - 伤害飘字对象池
## 预分配30个伤害数字，减少GC压力
class_name DamageNumberPool
extends ObjectPool

## 创建DamageNumberPool实例
static func create() -> DamageNumberPool:
	var pool = DamageNumberPool.new(30, _create_damage_number, _reset_damage_number)
	return pool

## 创建伤害数字对象
static func _create_damage_number() -> Node:
	var label = Label.new()
	label.text = "0"
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.RED)
	label.custom_minimum_size = Vector2(50, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 存储引用
	label.set_meta("damage_value", 0)
	label.set_meta("damage_type", "normal")  # normal, critical, heal
	label.set_meta("animation_time", 0.0)
	label.set_meta("total_duration", 1.0)
	
	return label

## 重置伤害数字
static func _reset_damage_number(label: Node) -> void:
	if not label:
		return
	
	# 隐藏标签
	label.visible = false
	
	# 重置数据
	label.set_meta("damage_value", 0)
	label.set_meta("damage_type", "normal")
	label.set_meta("animation_time", 0.0)
	label.text = "0"
	label.add_theme_color_override("font_color", Color.RED)

## 获取伤害数字
func acquire_damage_number(damage_value: int, damage_type: String = "normal") -> Node:
	var label = acquire()
	
	if label:
		# 设置数据
		label.set_meta("damage_value", damage_value)
		label.set_meta("damage_type", damage_type)
		label.set_meta("animation_time", 0.0)
		label.visible = true
		
		# 设置文本
		label.text = str(damage_value)
		
		# 根据伤害类型设置颜色
		match damage_type:
			"critical":
				label.add_theme_color_override("font_color", Color.YELLOW)
			"heal":
				label.add_theme_color_override("font_color", Color.GREEN)
			_:
				label.add_theme_color_override("font_color", Color.RED)
	
	return label

## 释放伤害数字
func release_damage_number(label: Node) -> void:
	release(label)

## 获取伤害值
func get_damage_value(label: Node) -> int:
	if not label:
		return 0
	return label.get_meta("damage_value", 0)

## 获取伤害类型
func get_damage_type(label: Node) -> String:
	if not label:
		return "normal"
	return label.get_meta("damage_type", "normal")

## 更新动画时间
func update_animation_time(label: Node, delta: float) -> void:
	if not label:
		return
	
	var current_time = label.get_meta("animation_time", 0.0)
	var total_duration = label.get_meta("total_duration", 1.0)
	
	current_time += delta
	label.set_meta("animation_time", current_time)
	
	# 计算透明度（从1到0）
	var progress = current_time / total_duration
	var alpha = 1.0 - progress
	
	# 更新颜色透明度
	var color = label.get_theme_color("font_color")
	color.a = alpha
	label.add_theme_color_override("font_color", color)
	
	# 计算位置偏移（向上飘）
	var offset = progress * 50.0
	label.position.y -= offset

## 是否动画完成
func is_animation_complete(label: Node) -> bool:
	if not label:
		return true
	
	var current_time = label.get_meta("animation_time", 0.0)
	var total_duration = label.get_meta("total_duration", 1.0)
	
	return current_time >= total_duration