## 存档槽位选择面板
## 显示3个存档槽位，支持保存和加载两种模式
## 保存模式：点击空槽位直接保存，点击已有存档槽位弹出覆盖确认
## 加载模式：只能点击已有存档的槽位

extends CanvasLayer

signal slot_selected(slot: int)
signal slot_panel_cancelled

# ============================================================================
# 节点引用
# ============================================================================

@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var _slot_list: VBoxContainer = $PanelContainer/VBox/SlotList
@onready var _cancel_btn: Button = $PanelContainer/VBox/CancelButton
@onready var _dim_overlay: ColorRect = $DimOverlay

# ============================================================================
# 状态
# ============================================================================

enum Mode { SAVE, LOAD }

var _mode: Mode = Mode.SAVE
var _is_open: bool = false
var _save_system: Node = null

## 等待覆盖确认的槽位（-1=无）
var _pending_overwrite_slot: int = -1

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	visible = false
	_save_system = get_node_or_null("/root/SaveSystem")
	_cancel_btn.pressed.connect(_on_cancel)
	_dim_overlay.gui_input.connect(_on_dim_overlay_input)


## 以保存模式打开
func open_save() -> void:
	_mode = Mode.SAVE
	_title_label.text = "保存游戏"
	_open()


## 以加载模式打开
func open_load() -> void:
	_mode = Mode.LOAD
	_title_label.text = "加载游戏"
	_open()


func _open() -> void:
	if _is_open:
		return
	_is_open = true
	_pending_overwrite_slot = -1
	visible = true
	_refresh_slot_list()

	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.pivot_offset = Vector2(_panel.size.x / 2, _panel.size.y / 2)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func close() -> void:
	if not _is_open:
		return
	_is_open = false

	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(func():
		visible = false
	)

# ============================================================================
# 输入处理
# ============================================================================

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_cancel()
		get_viewport().set_input_as_handled()


func _on_dim_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_cancel()

# ============================================================================
# 槽位列表
# ============================================================================

func _refresh_slot_list() -> void:
	for child in _slot_list.get_children():
		child.queue_free()

	if _save_system == null:
		var label := Label.new()
		label.text = "存档系统不可用"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_slot_list.add_child(label)
		return

	for slot in range(1, _save_system.MAX_SLOTS + 1):
		var has_save: bool = _save_system.has_save(slot)
		var info: Dictionary = _save_system.get_save_info(slot) if has_save else {}

		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(0, 60)

		if has_save:
			var timestamp: String = info.get("timestamp", "未知时间")
			var version: String = info.get("version", "?")
			slot_btn.text = "槽位 %d — %s (v%s)" % [slot, timestamp, version]
		else:
			slot_btn.text = "槽位 %d — 空" % slot

		if _mode == Mode.LOAD and not has_save:
			slot_btn.disabled = true
			slot_btn.tooltip_text = "没有存档数据"

		var s := slot
		slot_btn.pressed.connect(func(): _on_slot_pressed(s, has_save))
		_slot_list.add_child(slot_btn)

		# 加载模式下显示删除按钮
		if has_save:
			var delete_btn := Button.new()
			delete_btn.text = "删除存档 %d" % slot
			delete_btn.custom_minimum_size = Vector2(0, 28)
			delete_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			delete_btn.pressed.connect(func(): _on_delete_pressed(s))
			_slot_list.add_child(delete_btn)

# ============================================================================
# 事件处理
# ============================================================================

func _on_slot_pressed(slot: int, has_save: bool) -> void:
	if _mode == Mode.SAVE and has_save:
		_show_overwrite_confirm(slot)
		return

	slot_selected.emit(slot)
	close()


func _show_overwrite_confirm(slot: int) -> void:
	_pending_overwrite_slot = slot

	for child in _slot_list.get_children():
		child.queue_free()

	var label := Label.new()
	label.text = "槽位 %d 已有存档，确定要覆盖吗？" % slot
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_slot_list.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set("theme_override_constants/separation", 16)

	var confirm_btn := Button.new()
	confirm_btn.text = "确认覆盖"
	confirm_btn.custom_minimum_size = Vector2(120, 40)
	confirm_btn.pressed.connect(func():
		slot_selected.emit(_pending_overwrite_slot)
		close()
	)
	hbox.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(func():
		_pending_overwrite_slot = -1
		_refresh_slot_list()
	)
	hbox.add_child(back_btn)

	_slot_list.add_child(hbox)


func _on_delete_pressed(slot: int) -> void:
	if _save_system == null:
		return

	for child in _slot_list.get_children():
		child.queue_free()

	var label := Label.new()
	label.text = "确定要删除槽位 %d 的存档吗？此操作不可撤销。" % slot
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_slot_list.add_child(label)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.set("theme_override_constants/separation", 16)

	var confirm_btn := Button.new()
	confirm_btn.text = "确认删除"
	confirm_btn.custom_minimum_size = Vector2(120, 40)
	confirm_btn.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
	confirm_btn.pressed.connect(func():
		_save_system.delete_save(slot)
		_refresh_slot_list()
	)
	hbox.add_child(confirm_btn)

	var back_btn := Button.new()
	back_btn.text = "返回"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(func():
		_refresh_slot_list()
	)
	hbox.add_child(back_btn)

	_slot_list.add_child(hbox)


func _on_cancel() -> void:
	slot_panel_cancelled.emit()
	close()
