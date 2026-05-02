extends Control
## 弱点图标显示组件
## 显示单个五行弱点图标，支持高亮和动画
## 遵循ADR-002 (HUD架构模式) 和 ADR-003 (数据绑定机制)

# 节点引用
@onready var icon_texture: TextureRect = %IconTexture
@onready var highlight_overlay: Panel = %HighlightOverlay

# 元素类型和对应的图标路径
var _element: String = ""
var _is_highlighted: bool = false

# 元素图标映射
const ELEMENT_ICONS = {
	"metal": "res://assets/ui/element_icons/element_icon_metal.png",
	"wood": "res://assets/ui/element_icons/element_icon_wood.png",
	"water": "res://assets/ui/element_icons/element_icon_water.png",
	"fire": "res://assets/ui/element_icons/element_icon_fire.png",
	"earth": "res://assets/ui/element_icons/element_icon_earth.png",
}

# 颜色常量
const COLOR_HIGHLIGHT = Color("#FFD700")  # 金色高亮
const COLOR_NORMAL = Color.WHITE
const COLOR_DISCOVERED = Color("#90EE90")  # 浅绿色已发现

func _ready() -> void:
	# 初始化UI状态
	highlight_overlay.visible = false
	custom_minimum_size = Vector2(32, 32)  # AC-3: 32x32px

## 设置元素类型并加载对应的图标
func set_element(element: String) -> void:
	_element = element
	
	if ELEMENT_ICONS.has(element):
		icon_texture.texture = load(ELEMENT_ICONS[element])
	else:
		push_error("Unknown element type: %s" % element)

## 高亮显示已发现的弱点
func highlight() -> void:
	if _is_highlighted:
		return
	
	_is_highlighted = true
	highlight_overlay.visible = true
	highlight_overlay.modulate = COLOR_HIGHLIGHT

## 取消高亮
func unhighlight() -> void:
	if not _is_highlighted:
		return
	
	_is_highlighted = false
	highlight_overlay.visible = false

## 播放弱点发现时的高亮动画 (AC-9: 0.3秒高亮动画)
func play_reveal_animation(duration: float = 0.3) -> void:
	# 创建高亮闪烁动画
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# 高亮闪烁效果：快速闪烁3次
	var flash_count = 3
	var flash_duration = duration / (flash_count * 2)
	
	for i in range(flash_count):
		# 闪烁到金色
		tween.tween_property(highlight_overlay, "modulate", COLOR_HIGHLIGHT, flash_duration)
		# 闪烁回正常
		tween.tween_property(highlight_overlay, "modulate", COLOR_DISCOVERED, flash_duration)
	
	# 最后保持高亮状态
	tween.tween_callback(func(): highlight_overlay.modulate = COLOR_HIGHLIGHT)

## 获取当前元素类型
func get_element() -> String:
	return _element

## 获取高亮状态
func is_highlighted() -> bool:
	return _is_highlighted