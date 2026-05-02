## BuffIconPool - Buff图标对象池
## 预分配20个Buff图标，减少GC压力
class_name BuffIconPool
extends ObjectPool

## 创建BuffIconPool实例
static func create() -> BuffIconPool:
	var pool = BuffIconPool.new(20, _create_buff_icon, _reset_buff_icon)
	return pool

## 创建Buff图标对象
static func _create_buff_icon() -> Node:
	var icon = Control.new()
	icon.custom_minimum_size = Vector2(32, 32)
	
	# 添加TextureRect用于显示图标
	var texture_rect = TextureRect.new()
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.add_child(texture_rect)
	
	# 添加Label用于显示层数
	var label = Label.new()
	label.text = "1"
	label.add_theme_font_size_override("font_size", 10)
	label.anchor_left = 0.7
	label.anchor_top = 0.7
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	icon.add_child(label)
	
	# 存储引用
	icon.set_meta("texture_rect", texture_rect)
	icon.set_meta("label", label)
	icon.set_meta("buff_id", "")
	icon.set_meta("stack_count", 1)
	icon.set_meta("duration", 0.0)
	
	return icon

## 重置Buff图标
static func _reset_buff_icon(icon: Node) -> void:
	if not icon:
		return
	
	# 隐藏图标
	icon.visible = false
	
	# 重置数据
	icon.set_meta("buff_id", "")
	icon.set_meta("stack_count", 1)
	icon.set_meta("duration", 0.0)
	
	# 清空纹理
	var texture_rect = icon.get_meta("texture_rect")
	if texture_rect:
		texture_rect.texture = null
	
	# 重置标签
	var label = icon.get_meta("label")
	if label:
		label.text = "1"

## 获取Buff图标
func acquire_buff_icon(buff_id: String, texture: Texture2D, stack_count: int = 1) -> Node:
	var icon = acquire()
	
	if icon:
		# 设置数据
		icon.set_meta("buff_id", buff_id)
		icon.set_meta("stack_count", stack_count)
		icon.visible = true
		
		# 设置纹理
		var texture_rect = icon.get_meta("texture_rect")
		if texture_rect:
			texture_rect.texture = texture
		
		# 设置层数标签
		var label = icon.get_meta("label")
		if label:
			label.text = str(stack_count) if stack_count > 1 else ""
	
	return icon

## 释放Buff图标
func release_buff_icon(icon: Node) -> void:
	release(icon)

## 更新Buff图标的层数
func update_buff_stack_count(icon: Node, stack_count: int) -> void:
	if not icon:
		return
	
	icon.set_meta("stack_count", stack_count)
	
	var label = icon.get_meta("label")
	if label:
		label.text = str(stack_count) if stack_count > 1 else ""

## 获取Buff图标的ID
func get_buff_id(icon: Node) -> String:
	if not icon:
		return ""
	return icon.get_meta("buff_id", "")

## 获取Buff图标的层数
func get_buff_stack_count(icon: Node) -> int:
	if not icon:
		return 0
	return icon.get_meta("stack_count", 1)