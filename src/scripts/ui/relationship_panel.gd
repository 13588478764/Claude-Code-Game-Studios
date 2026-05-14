## 关系面板
## 显示NPC关系列表、关系值进度条、等级文字、道心指示器
extends CanvasLayer

signal relationship_panel_closed

var _relationship_manager: RelationshipManager = null
var _npc_list_container: VBoxContainer = null
var _dao_heart_label: Label = null
var _dao_heart_bar: ProgressBar = null
var _title_label: Label = null
var _close_button: Button = null
var _panel_container: PanelContainer = null

## 关系等级对应颜色
const LEVEL_COLORS: Dictionary = {
	-3: Color(0.9, 0.2, 0.2),    # 仇敌 - 红
	-2: Color(0.6, 0.6, 0.6),    # 冷淡 - 灰
	-1: Color(0.9, 0.9, 0.9),    # 中立 - 白
	0: Color(0.3, 0.8, 0.3),     # 友好 - 绿
	1: Color(0.3, 0.5, 0.9),     # 亲密 - 蓝
	2: Color(0.9, 0.8, 0.2),     # 挚友 - 金
}

func _ready() -> void:
	layer = 250
	visible = false
	_build_ui()
	call_deferred("_connect_manager")

func _connect_manager() -> void:
	if has_node("/root/RelationshipManager"):
		_relationship_manager = get_node("/root/RelationshipManager")

func open_panel() -> void:
	if _relationship_manager == null:
		_connect_manager()
	_refresh_display()
	visible = true

func close_panel() -> void:
	visible = false
	relationship_panel_closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	_panel_container = PanelContainer.new()
	_panel_container.name = "RelationshipPanelContainer"
	_panel_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel_container.custom_minimum_size = Vector2(600, 500)
	_panel_container.position = Vector2(-300, -250)
	add_child(_panel_container)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	_panel_container.add_child(main_vbox)

	# 标题栏
	var header := HBoxContainer.new()
	main_vbox.add_child(header)

	_title_label = Label.new()
	_title_label.text = "角色关系"
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 24)
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.pressed.connect(close_panel)
	header.add_child(_close_button)

	# 道心指示器
	var dao_box := VBoxContainer.new()
	main_vbox.add_child(dao_box)

	_dao_heart_label = Label.new()
	_dao_heart_label.text = "道心: 中立 (0)"
	dao_box.add_child(_dao_heart_label)

	_dao_heart_bar = ProgressBar.new()
	_dao_heart_bar.min_value = -100
	_dao_heart_bar.max_value = 100
	_dao_heart_bar.value = 0
	_dao_heart_bar.custom_minimum_size = Vector2(0, 20)
	_dao_heart_bar.show_percentage = false
	dao_box.add_child(_dao_heart_bar)

	# 分隔线
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# NPC列表滚动容器
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 300)
	main_vbox.add_child(scroll)

	_npc_list_container = VBoxContainer.new()
	_npc_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_npc_list_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_npc_list_container)

func _refresh_display() -> void:
	if _relationship_manager == null:
		return

	# 道心指示器
	var dao_value := _relationship_manager.get_dao_heart_value()
	var dao_level_name := _relationship_manager.get_dao_heart_level_name()
	_dao_heart_label.text = "道心: %s (%d)" % [dao_level_name, dao_value]
	_dao_heart_bar.value = dao_value

	# 道心颜色
	var dao_level := _relationship_manager.get_dao_heart_level()
	match dao_level:
		RelationshipData.DaoHeartLevel.RIGHTEOUS_MASTER, RelationshipData.DaoHeartLevel.RIGHTEOUS_LEANING:
			_dao_heart_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.2))
		RelationshipData.DaoHeartLevel.EVIL_MASTER, RelationshipData.DaoHeartLevel.EVIL_LEANING:
			_dao_heart_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.8))
		_:
			_dao_heart_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

	# 清空NPC列表
	for child in _npc_list_container.get_children():
		child.queue_free()

	# 重建NPC列表
	var npc_ids := _relationship_manager.get_all_npc_ids()
	for npc_id in npc_ids:
		var npc_data := _relationship_manager.get_npc_data(npc_id)
		if npc_data.is_empty():
			continue
		_add_npc_row(npc_id, npc_data)

func _add_npc_row(npc_id: String, npc_data: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_npc_list_container.add_child(row)

	# NPC名称和头衔
	var name_box := VBoxContainer.new()
	name_box.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_box)

	var name_label := Label.new()
	name_label.text = npc_data.get("name", npc_id)
	name_label.add_theme_font_size_override("font_size", 16)
	name_box.add_child(name_label)

	var title_label := Label.new()
	title_label.text = npc_data.get("title", "")
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	name_box.add_child(title_label)

	# 关系值进度条
	var bar_box := VBoxContainer.new()
	bar_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(bar_box)

	var rel_value := _relationship_manager.get_relationship_value(npc_id)
	var rel_level := _relationship_manager.get_relationship_level(npc_id)
	var rel_level_name := _relationship_manager.get_relationship_level_name(npc_id)

	var bar := ProgressBar.new()
	bar.min_value = -100
	bar.max_value = 100
	bar.value = rel_value
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	bar_box.add_child(bar)

	# 等级标签
	var level_label := Label.new()
	level_label.text = "%s (%d)" % [rel_level_name, rel_value]
	level_label.add_theme_font_size_override("font_size", 13)

	var color: Color = LEVEL_COLORS.get(int(rel_level), Color.WHITE)
	level_label.add_theme_color_override("font_color", color)
	bar_box.add_child(level_label)
