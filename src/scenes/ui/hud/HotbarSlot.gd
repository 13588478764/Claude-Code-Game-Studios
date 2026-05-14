extends PanelContainer
class_name HotbarSlot

## 快捷栏槽位 - Story 008
## 单个快捷栏槽位的UI表现

signal slot_pressed(slot_index: int)
signal slot_drag_started(slot_index: int)

var slot_index: int = 0

# UI元素
var _vbox: VBoxContainer = null
var _icon_label: Label = null
var _quantity_label: Label = null
var _cooldown_progress: ProgressBar = null

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

	# 创建容器和子节点
	_vbox = VBoxContainer.new()
	_vbox.name = "VBoxContainer"
	add_child(_vbox)

	_icon_label = Label.new()
	_icon_label.name = "IconLabel"
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox.add_child(_icon_label)

	_quantity_label = Label.new()
	_quantity_label.name = "QuantityLabel"
	_quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_vbox.add_child(_quantity_label)

	_cooldown_progress = ProgressBar.new()
	_cooldown_progress.name = "CooldownProgress"
	_cooldown_progress.visible = false
	_cooldown_progress.min_value = 0
	_cooldown_progress.max_value = 100
	_cooldown_progress.value = 0
	_vbox.add_child(_cooldown_progress)

func set_item(item_id: String, quantity: int) -> void:
	if item_id.is_empty():
		_icon_label.text = ""
		_quantity_label.text = ""
		tooltip_text = ""
	else:
		_icon_label.text = item_id.substr(0, 1).to_upper()
		if quantity > 1:
			_quantity_label.text = str(quantity)
		else:
			_quantity_label.text = ""
		_update_tooltip(item_id, quantity)


## 更新tooltip显示物品信息
func _update_tooltip(item_id: String, quantity: int) -> void:
	var inv: Node = Engine.get_singleton("InventorySystem") if Engine.has_singleton("InventorySystem") else null
	if inv == null:
		inv = _get_node_safe("/root/InventorySystem")

	var item_name: String = item_id
	var item_desc: String = ""

	if inv and inv.has_method("get_item_data"):
		var data: Dictionary = inv.get_item_data(item_id)
		if not data.is_empty():
			item_name = data.get("name", item_id)
			item_desc = data.get("description", "")

	var tip: String = item_name
	if quantity > 1:
		tip += " x%d" % quantity
	if item_desc != "":
		tip += "\n%s" % item_desc
	tooltip_text = tip


func _get_node_safe(path: String) -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null(path)

func set_cooldown(remaining: float, total: float) -> void:
	if total > 0:
		_cooldown_progress.visible = true
		_cooldown_progress.value = (1.0 - remaining / total) * 100
	else:
		_cooldown_progress.visible = false
		_cooldown_progress.value = 0

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			slot_pressed.emit(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_drag_started.emit(slot_index)
