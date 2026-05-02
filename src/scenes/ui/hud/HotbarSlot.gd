extends PanelContainer
class_name HotbarSlot

## 快捷栏槽位 - Story 008
## 单个快捷栏槽位的UI表现

signal slot_pressed
signal slot_drag_started

var slot_index: int = 0

# UI元素
@onready var icon_label: Label = $VBoxContainer/IconLabel
@onready var quantity_label: Label = $VBoxContainer/QuantityLabel
@onready var cooldown_progress: ProgressBar = $VBoxContainer/CooldownProgress

func _ready() -> void:
	_setup_ui()
	gui_input.connect(_on_gui_input)

func _setup_ui() -> void:
	# 设置槽位样式
	var style_box = StyleBoxFlat.new()
	style_box.set_corner_radius_all(4)
	style_box.bg_color = Color(0.2, 0.2, 0.2, 0.8)
	style_box.border_color = Color(0.5, 0.5, 0.5, 1.0)
	style_box.set_border_width_all(2)
	
	var theme = Theme.new()
	theme.set_stylebox("panel", "PanelContainer", style_box)
	self.theme = theme
	
	# 初始化标签
	icon_label.text = ""
	quantity_label.text = ""
	cooldown_progress.value = 0
	cooldown_progress.visible = false

func set_item(item_id: String, quantity: int) -> void:
	if item_id.is_empty():
		icon_label.text = ""
		quantity_label.text = ""
	else:
		# TODO: 从物品系统获取图标
		icon_label.text = item_id.substr(0, 1).to_upper()
		if quantity > 1:
			quantity_label.text = str(quantity)
		else:
			quantity_label.text = ""

func set_cooldown(remaining: float, total: float) -> void:
	if total > 0:
		cooldown_progress.visible = true
		cooldown_progress.value = (1.0 - remaining / total) * 100
	else:
		cooldown_progress.visible = false
		cooldown_progress.value = 0

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit()
		elif event.button_index == MOUSE_BUTTON_LEFT and Input.is_key_pressed(KEY_SHIFT):
			slot_drag_started.emit()