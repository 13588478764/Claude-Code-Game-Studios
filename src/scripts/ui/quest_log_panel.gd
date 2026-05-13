## 任务日志面板
## 显示玩家当前进行中和已完成的任务列表
## 快捷键 J 打开/关闭

extends CanvasLayer

signal quest_log_closed

# ============================================================================
# 节点引用
# ============================================================================

@onready var _panel: PanelContainer = $PanelContainer
@onready var _close_btn: Button = $PanelContainer/VBox/HeaderHBox/CloseButton
@onready var _active_tab_btn: Button = $PanelContainer/VBox/TabHBox/ActiveTabButton
@onready var _completed_tab_btn: Button = $PanelContainer/VBox/TabHBox/CompletedTabButton
@onready var _quest_list_box: VBoxContainer = $PanelContainer/VBox/ScrollContainer/QuestListBox
@onready var _detail_label: RichTextLabel = $PanelContainer/VBox/DetailPanel/DetailLabel

# ============================================================================
# 状态
# ============================================================================

var _is_open: bool = false

## 当前标签页: "active" 或 "completed"
var _current_tab: String = "active"

## 任务系统引用
var _quest_system: Node = null

## 当前选中的任务 ID
var _selected_quest_id: String = ""

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	layer = 110
	visible = false
	_panel.pivot_offset = Vector2(_panel.size.x / 2, _panel.size.y / 2)
	call_deferred("_initialize")


func _initialize() -> void:
	_quest_system = get_node_or_null("/root/QuestSystem")

	_close_btn.pressed.connect(close_panel)
	_active_tab_btn.pressed.connect(func(): _switch_tab("active"))
	_completed_tab_btn.pressed.connect(func(): _switch_tab("completed"))

	if _quest_system:
		if _quest_system.has_signal("quest_accepted"):
			_quest_system.quest_accepted.connect(func(_id): _refresh_quest_list())
		if _quest_system.has_signal("quest_completed"):
			_quest_system.quest_completed.connect(func(_id): _refresh_quest_list())
		if _quest_system.has_signal("quest_objective_updated"):
			_quest_system.quest_objective_updated.connect(func(_id, _i, _c, _t): _refresh_quest_list())

# ============================================================================
# 面板开关
# ============================================================================

## 打开面板（带滑入动画）
func open_panel() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	_current_tab = "active"
	_selected_quest_id = ""
	_update_tab_buttons()
	_refresh_quest_list()
	_detail_label.text = "选择一个任务查看详情"

	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## 关闭面板（带滑出动画）
func close_panel() -> void:
	if not _is_open:
		return
	_is_open = false

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.15)
	tween.chain().tween_callback(func():
		visible = false
		quest_log_closed.emit()
	)

# ============================================================================
# 输入处理
# ============================================================================

func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_J:
			close_panel()
			get_viewport().set_input_as_handled()

# ============================================================================
# 标签页切换
# ============================================================================

func _switch_tab(tab: String) -> void:
	_current_tab = tab
	_selected_quest_id = ""
	_update_tab_buttons()
	_refresh_quest_list()
	_detail_label.text = "选择一个任务查看详情"


func _update_tab_buttons() -> void:
	_active_tab_btn.disabled = (_current_tab == "active")
	_completed_tab_btn.disabled = (_current_tab == "completed")

# ============================================================================
# 任务列表刷新
# ============================================================================

func _refresh_quest_list() -> void:
	for child in _quest_list_box.get_children():
		child.queue_free()

	if _quest_system == null:
		_add_empty_label("任务系统未就绪")
		return

	var quest_ids: Array = []
	if _current_tab == "active":
		quest_ids = _quest_system.get_active_quests()
	else:
		quest_ids = _quest_system.player_completed_quests.duplicate()

	if quest_ids.is_empty():
		var hint := "暂无进行中的任务" if _current_tab == "active" else "暂无已完成的任务"
		_add_empty_label(hint)
		return

	for qid in quest_ids:
		var info: Dictionary = _quest_system.get_quest_info(qid)
		if info.is_empty():
			continue
		_add_quest_entry(info)


func _add_empty_label(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_quest_list_box.add_child(label)


func _add_quest_entry(info: Dictionary) -> void:
	var hbox := HBoxContainer.new()
	hbox.set("theme_override_constants/separation", 8)

	# 任务类型图标
	var type_label := Label.new()
	var quest_type: int = info.get("type", 0)
	match quest_type:
		0: type_label.text = "[主]"
		1: type_label.text = "[支]"
		2: type_label.text = "[赏]"
		3: type_label.text = "[缘]"
		_: type_label.text = "[？]"
	type_label.custom_minimum_size = Vector2(36, 0)
	hbox.add_child(type_label)

	# 任务标题按钮
	var btn := Button.new()
	btn.text = info.get("title", "未知任务")
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var qid: String = info.get("id", "")
	btn.pressed.connect(_on_quest_selected.bind(qid))
	hbox.add_child(btn)

	# 进度标签（仅进行中标签页）
	if _current_tab == "active":
		var objectives: Array = info.get("objectives", [])
		var done_count := 0
		for obj in objectives:
			if obj.get("is_complete", false):
				done_count += 1
		var progress_label := Label.new()
		progress_label.text = "%d/%d" % [done_count, objectives.size()]
		progress_label.custom_minimum_size = Vector2(48, 0)
		progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hbox.add_child(progress_label)

	_quest_list_box.add_child(hbox)

# ============================================================================
# 任务详情显示
# ============================================================================

func _on_quest_selected(quest_id: String) -> void:
	_selected_quest_id = quest_id
	if _quest_system == null:
		return

	var info: Dictionary = _quest_system.get_quest_info(quest_id)
	if info.is_empty():
		_detail_label.text = "无法获取任务信息"
		return

	var bbcode := ""

	# 标题
	bbcode += "[b]%s[/b]\n" % info.get("title", "")

	# 类型
	var type_names := ["主线任务", "支线任务", "悬赏任务", "奇遇任务"]
	var type_idx: int = info.get("type", 0)
	if type_idx >= 0 and type_idx < type_names.size():
		bbcode += "[color=gray]%s[/color]\n" % type_names[type_idx]

	# 描述
	bbcode += "\n%s\n" % info.get("description", "")

	# 目标列表
	var objectives: Array = info.get("objectives", [])
	if not objectives.is_empty():
		bbcode += "\n[b]目标:[/b]\n"
		for obj in objectives:
			var check := "✓" if obj.get("is_complete", false) else "○"
			var color := "green" if obj.get("is_complete", false) else "white"
			bbcode += "[color=%s]%s %s (%d/%d)[/color]\n" % [
				color, check, obj.get("description", ""),
				obj.get("current_count", 0), obj.get("target_count", 1)
			]

	# 奖励
	var rewards: Dictionary = info.get("rewards", {})
	if not rewards.is_empty():
		bbcode += "\n[b]奖励:[/b] "
		var parts: PackedStringArray = []
		if rewards.has("exp") and rewards.exp > 0:
			parts.append("经验 %d" % rewards.exp)
		if rewards.has("silver") and rewards.silver > 0:
			parts.append("银两 %d" % rewards.silver)
		bbcode += ", ".join(parts)

	_detail_label.text = bbcode
