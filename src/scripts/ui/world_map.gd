## 大地图控制器
## 对应 UX Spec: design/ux/world-map.md
## Z-index = 220（在HUD之上、设置面板之下）

extends CanvasLayer

## 大地图打开时发出
signal world_map_opened(source: String, tab_shown: String)
## 大地图关闭时发出
signal world_map_closed(time_spent_ms: int, tabs_viewed: Array)
## Tab切换时发出
signal world_map_tab_changed(from_tab: String, to_tab: String)
## 确认旅行时发出
signal world_map_travel_confirmed(from_region: String, to_region: String, cost: int)
## 取消旅行时发出
signal world_map_travel_cancelled(teleport_point_id: String, reason: String)
## 查看区域详情时发出
signal world_map_region_inspected(region_id: String, exploration_percentage: float)

## 场景引用
@onready var _panel: PanelContainer = $MainPanel
@onready var _tab_bar: TabBar = $MainPanel/VBox/HeaderHBox/TabBar
@onready var _close_btn: Button = $MainPanel/VBox/HeaderHBox/CloseButton
@onready var _map_tab: Control = $MainPanel/VBox/TabContent/MapTab
@onready var _travel_tab: ScrollContainer = $MainPanel/VBox/TabContent/TravelTab
@onready var _exploration_tab: ScrollContainer = $MainPanel/VBox/TabContent/ExplorationTab
@onready var _map_viewport: Control = $MainPanel/VBox/TabContent/MapTab/MapViewport
@onready var _map_texture: ColorRect = $MainPanel/VBox/TabContent/MapTab/MapViewport/MapTexture
@onready var _fog_overlay: ColorRect = $MainPanel/VBox/TabContent/MapTab/MapViewport/FogOverlay
@onready var _markers_container: Control = $MainPanel/VBox/TabContent/MapTab/MapViewport/MarkersContainer
@onready var _current_region_label: Label = $MainPanel/VBox/TabContent/MapTab/MapInfoCard/MapInfoVBox/CurrentRegionLabel
@onready var _exploration_label: Label = $MainPanel/VBox/TabContent/MapTab/MapInfoCard/MapInfoVBox/ExplorationLabel
@onready var _zoom_out_btn: Button = $MainPanel/VBox/TabContent/MapTab/ZoomControls/ZoomHBox/ZoomOutButton
@onready var _zoom_in_btn: Button = $MainPanel/VBox/TabContent/MapTab/ZoomControls/ZoomHBox/ZoomInButton
@onready var _reset_zoom_btn: Button = $MainPanel/VBox/TabContent/MapTab/ZoomControls/ZoomHBox/ResetZoomButton
@onready var _zoom_level_label: Label = $MainPanel/VBox/TabContent/MapTab/ZoomControls/ZoomHBox/ZoomLevelLabel
@onready var _legend_btn: Button = $MainPanel/VBox/TabContent/MapTab/ZoomControls/ZoomHBox/LegendButton
@onready var _teleport_list: ItemList = $MainPanel/VBox/TabContent/TravelTab/TravelVBox/TeleportPointList
@onready var _travel_cost_label: Label = $MainPanel/VBox/TabContent/TravelTab/TravelVBox/TravelInfoHBox/TravelCostLabel
@onready var _player_realm_label: Label = $MainPanel/VBox/TabContent/TravelTab/TravelVBox/TravelInfoHBox/PlayerRealmLabel
@onready var _spirit_stone_label: Label = $MainPanel/VBox/TabContent/TravelTab/TravelVBox/TravelInfoHBox/SpiritStoneLabel
@onready var _travel_btn: Button = $MainPanel/VBox/TabContent/TravelTab/TravelVBox/TravelButton
@onready var _overall_progress_bar: ProgressBar = $MainPanel/VBox/TabContent/ExplorationTab/ExplorationVBox/OverallProgressBar
@onready var _overall_percent_label: Label = $MainPanel/VBox/TabContent/ExplorationTab/ExplorationVBox/OverallPercentLabel
@onready var _region_list: ItemList = $MainPanel/VBox/TabContent/ExplorationTab/ExplorationVBox/RegionList

## 缩放级别枚举
enum ZoomLevel { OVERVIEW = 0, REGION = 1, DETAIL = 2 }

## 缩放级别名称
const ZOOM_NAMES: Array[String] = ["概览", "区域", "细节"]

## 缩放级别对应的scale值
const ZOOM_SCALES: Array[float] = [1.0, 2.0, 4.0]

## 是否打开
var _is_open: bool = false
## 子面板是否打开（图例等）
var _subpanel_open: bool = false
## 打开时间（用于统计）
var _open_time_ms: float = 0.0
## 查看过的Tab
var _tabs_viewed: Array[int] = []
## 当前缩放级别
var _current_zoom: ZoomLevel = ZoomLevel.OVERVIEW
## 地图偏移（用于拖拽平移）
var _map_offset: Vector2 = Vector2.ZERO
## 是否正在拖拽
var _is_dragging: bool = false
## 拖拽起始鼠标位置
var _drag_start_mouse: Vector2 = Vector2.ZERO
## 拖拽起始偏移
var _drag_start_offset: Vector2 = Vector2.ZERO
## 当前选中的传送点索引
var _selected_teleport_index: int = -1
## 传送点数据（从 FastTravelManager 获取）
var _teleport_points: Array[Dictionary] = []


func _ready() -> void:
	visible = false
	_panel.modulate = Color(1, 1, 1, 0)

	# 连接信号
	_close_btn.pressed.connect(close_map)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_zoom_in_btn.pressed.connect(_on_zoom_in)
	_zoom_out_btn.pressed.connect(_on_zoom_out)
	_reset_zoom_btn.pressed.connect(_on_reset_zoom)
	_legend_btn.pressed.connect(_on_legend)
	_travel_btn.pressed.connect(_on_travel_confirmed)
	_teleport_list.item_selected.connect(_on_teleport_point_selected)

	# 设置地图拖拽
	_setup_map_drag()

	# 初始Tab
	_on_tab_changed(0)


## 打开大地图
func open_map(source: String = "keyboard", initial_tab: int = 0) -> void:
	if _is_open:
		return

	_is_open = true
	_open_time_ms = Time.get_ticks_msec()
	_tabs_viewed = [initial_tab]

	# 暂停游戏
	get_tree().paused = true

	visible = true
	_tab_bar.current_tab = initial_tab
	_on_tab_changed(initial_tab)

	# 淡入动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 1), 0.35)

	# 更新数据
	_update_map_data()
	_update_travel_data()
	_update_exploration_data()
	_update_zoom_controls()

	# 默认焦点
	_close_btn.grab_focus()

	world_map_opened.emit(source, _get_tab_name(initial_tab))


## 关闭大地图
func close_map() -> void:
	if not _is_open:
		return

	_subpanel_open = false

	var time_spent = int(Time.get_ticks_msec() - _open_time_ms)
	var tab_names: Array[String] = []
	for idx in _tabs_viewed:
		tab_names.append(_get_tab_name(idx))

	_is_open = false

	# 淡出动画
	var tween = create_tween()
	tween.tween_property(_panel, "modulate", Color(1, 1, 1, 0), 0.25)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func() -> void:
		visible = false
		get_tree().paused = false
	)

	world_map_closed.emit(time_spent, tab_names)


## Tab切换
func _on_tab_changed(tab_index: int) -> void:
	var tabs: Array[Control] = [_map_tab, _travel_tab, _exploration_tab]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)

	if not _tabs_viewed.has(tab_index):
		_tabs_viewed.append(tab_index)

	# 切换时更新对应数据
	match tab_index:
		0: _update_map_data()
		1: _update_travel_data()
		2: _update_exploration_data()


## 设置地图拖拽
func _setup_map_drag() -> void:
	_map_viewport.gui_input.connect(_on_map_viewport_gui_input)


## 地图视口输入处理
func _on_map_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _is_dragging:
			var delta = event.position - _drag_start_mouse
			_map_offset = _drag_start_offset + delta
			_apply_map_offset()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start_mouse = event.position
				_drag_start_offset = _map_offset
			else:
				_is_dragging = false


## 应用地图偏移
func _apply_map_offset() -> void:
	_map_texture.position = _map_offset
	_fog_overlay.position = _map_offset
	_markers_container.position = _map_offset


## 缩放控制
func _on_zoom_in() -> void:
	if _current_zoom < ZoomLevel.DETAIL:
		_current_zoom += 1
		_apply_zoom()
		_update_zoom_controls()


func _on_zoom_out() -> void:
	if _current_zoom > ZoomLevel.OVERVIEW:
		_current_zoom -= 1
		_apply_zoom()
		_update_zoom_controls()


func _on_reset_zoom() -> void:
	_current_zoom = ZoomLevel.OVERVIEW
	_map_offset = Vector2.ZERO
	_apply_map_offset()
	_apply_zoom()
	_update_zoom_controls()


func _on_legend() -> void:
	# TODO: 打开图例面板
	pass


## 应用缩放
func _apply_zoom() -> void:
	var scale_value = ZOOM_SCALES[_current_zoom]
	_map_viewport.scale = Vector2(scale_value, scale_value)
	_zoom_level_label.text = ZOOM_NAMES[_current_zoom]


## 更新缩放控件状态
func _update_zoom_controls() -> void:
	_zoom_out_btn.disabled = (_current_zoom <= ZoomLevel.OVERVIEW)
	_zoom_in_btn.disabled = (_current_zoom >= ZoomLevel.DETAIL)


## 更新地图数据（标记、区域信息）
func _update_map_data() -> void:
	# 清除旧标记
	for child in _markers_container.get_children():
		child.queue_free()

	# 从 FastTravelManager 获取已发现的传送点
	var fast_travel: Node = get_tree().root.get_node_or_null("FastTravelManager")
	_teleport_points.clear()

	if fast_travel != null and fast_travel.has_method("get_unlocked_locations"):
		var locations = fast_travel.get_unlocked_locations()
		for loc in locations:
			if loc is Object and loc.has_method("get"):
				_teleport_points.append({
					"id": loc.get("id", loc.get("name", "")),
					"name": loc.get("name", ""),
					"region": loc.get("region", ""),
					"position": loc.get("position", Vector2.ZERO),
					"unlocked": loc.get("is_unlocked", false),
				})
	else:
		# 使用占位数据
		_teleport_points = [
			{"id": "qingyun_mountain", "name": "青云山", "region": "青州", "position": Vector2(300, 400), "unlocked": true},
			{"id": "tianjian_sect", "name": "天剑宗", "region": "剑域", "position": Vector2(700, 300), "unlocked": true},
		]

	# 创建传送点标记
	for point in _teleport_points:
		_create_marker(point.position, point.name, "teleport", point.unlocked)

	# 创建玩家当前位置标记（占位）
	var player_pos = Vector2(300, 400)  # TODO: 从玩家数据系统读取
	_create_marker(player_pos, "当前位置", "player", true)

	# 更新信息卡
	_current_region_label.text = "当前区域: 青云山"  # TODO: 从数据系统读取
	var exploration_pct = 0.0
	var explore_mgr: Node = get_tree().root.get_node_or_null("ExploreManager")
	if explore_mgr != null and explore_mgr.has_method("get_current_region_exploration_percentage"):
		exploration_pct = explore_mgr.get_current_region_exploration_percentage()
	else:
		exploration_pct = 67.0  # 占位
	_exploration_label.text = "探索进度: %d%%" % int(exploration_pct)


## 创建标记
func _create_marker(pos: Vector2, label_text: String, marker_type: String, unlocked: bool = true) -> void:
	var marker = Control.new()
	marker.position = pos
	marker.size = Vector2(32, 32)
	marker.mouse_filter = Control.MOUSE_FILTER_STOP

	# 根据类型设置颜色
	var marker_color: Color
	match marker_type:
		"player":
			marker_color = Color(1.0, 0.84, 0.0)  # 金色
		"teleport":
			marker_color = Color(0.6, 0.35, 0.72) if unlocked else Color(0.5, 0.5, 0.5)  # 紫色/灰色
		"quest":
			marker_color = Color(1.0, 0.84, 0.0)  # 金色
		_:
			marker_color = Color.WHITE

	var rect = ColorRect.new()
	rect.size = Vector2(24, 24)
	rect.position = Vector2(4, 4)
	rect.color = marker_color
	rect.mouse_filter = Control.MOUSE_FILTER_PASS
	marker.add_child(rect)

	# 标签
	var label = Label.new()
	label.text = label_text
	label.position = Vector2(0, 28)
	label.size = Vector2(80, 20)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", marker_color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	marker.add_child(label)

	_markers_container.add_child(marker)


## 更新传送数据
func _update_travel_data() -> void:
	_teleport_list.clear()

	for point in _teleport_points:
		var display_text = "%s (%s)" % [point.name, point.region]
		_teleport_list.add_item(display_text)

	# 默认选中第一个
	if _teleport_list.item_count > 0:
		_teleport_list.select(0)
		_on_teleport_point_selected(0)
	else:
		_travel_cost_label.text = "旅行费用: --"
		_player_realm_label.text = "境界: --"
		_spirit_stone_label.text = "灵石: --"
		_travel_btn.disabled = true


## 传送点选中
func _on_teleport_point_selected(index: int) -> void:
	_selected_teleport_index = index
	if index < 0 or index >= _teleport_points.size():
		return

	var point = _teleport_points[index]
	var fast_travel: Node = get_tree().root.get_node_or_null("FastTravelManager")

	var cost = 0
	if fast_travel != null and fast_travel.has_method("calculate_travel_cost"):
		var current_loc = ""
		if fast_travel.has_method("get_current_location_info"):
			var loc_info = fast_travel.get_current_location_info()
			current_loc = loc_info.get("id", "")
		cost = fast_travel.calculate_travel_cost(current_loc, point.id)
	else:
		cost = 10  # 占位费用

	_travel_cost_label.text = "旅行费用: %d" % cost
	_player_realm_label.text = "境界: 炼气"  # TODO: 从角色系统读取
	_spirit_stone_label.text = "灵石: 500"  # TODO: 从经济系统读取

	# TODO: 检查境界和灵石是否足够，不足时禁用旅行按钮
	_travel_btn.disabled = false


## 确认旅行
func _on_travel_confirmed() -> void:
	if _selected_teleport_index < 0 or _selected_teleport_index >= _teleport_points.size():
		return

	var point = _teleport_points[_selected_teleport_index]

	var fast_travel: Node = get_tree().root.get_node_or_null("FastTravelManager")
	var cost = 0
	if fast_travel != null and fast_travel.has_method("calculate_travel_cost"):
		var current_loc = ""
		if fast_travel.has_method("get_current_location_info"):
			var loc_info = fast_travel.get_current_location_info()
			current_loc = loc_info.get("id", "")
		cost = fast_travel.calculate_travel_cost(current_loc, point.id)

	world_map_travel_confirmed.emit("青云山", point.region, cost)

	# TODO: 调用 FastTravelManager.travel_to_location(point.id)
	# TODO: 显示加载界面，切换到目标区域
	close_map()


## 更新探索度数据
func _update_exploration_data() -> void:
	var explore_mgr: Node = get_tree().root.get_node_or_null("ExploreManager")
	var overall_pct = 0.0

	_region_list.clear()

	var region_data_list = _get_region_data()

	if explore_mgr != null and explore_mgr.has_method("get_region_exploration_percentage"):
		var total_pct = 0.0
		var region_count = 0
		for region in region_data_list:
			var pct = explore_mgr.get_region_exploration_percentage(region.id)
			if pct > 0:
				total_pct += pct
				region_count += 1
			_region_list.add_item("%s - %d%%" % [region.name, int(pct)])

		if region_count > 0:
			overall_pct = total_pct / region_count
	else:
		# 使用占位数据
		for region in region_data_list:
			_region_list.add_item("%s - %d%%" % [region.name, int(region.exploration)])
			overall_pct += region.exploration
		if region_data_list.size() > 0:
			overall_pct /= region_data_list.size()

	_overall_progress_bar.value = overall_pct
	_overall_percent_label.text = "%d%%" % int(overall_pct)


## 获取区域数据列表（占位，后续从世界数据系统读取）
func _get_region_data() -> Array[Dictionary]:
	return [
		{"id": "qingyun_mountain", "name": "青云山", "region": "青州", "exploration": 67.0},
		{"id": "tianjian_sect", "name": "天剑宗", "region": "剑域", "exploration": 35.0},
		{"id": "jiangnan_town", "name": "江南水乡", "region": "江南", "exploration": 0.0},
		{"id": "beast_mountain", "name": "兽王山", "region": "西域", "exploration": 0.0},
		{"id": "dragon_temple", "name": "龙王庙", "region": "东海", "exploration": 0.0},
	]


## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_M:
				if _subpanel_open:
					_on_subpanel_closed()
				else:
					close_map()
				get_viewport().set_input_as_handled()
			KEY_TAB:
				# Tab键循环切换Tab页
				var next_tab = (_tab_bar.current_tab + 1) % _tab_bar.tab_count
				_tab_bar.current_tab = next_tab
				get_viewport().set_input_as_handled()
			KEY_PLUS, KEY_EQUAL:
				_on_zoom_in()
				get_viewport().set_input_as_handled()
			KEY_MINUS:
				_on_zoom_out()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_map_offset.x += 30
				_apply_map_offset()
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_map_offset.x -= 30
				_apply_map_offset()
				get_viewport().set_input_as_handled()
			KEY_UP:
				_map_offset.y += 30
				_apply_map_offset()
				get_viewport().set_input_as_handled()
			KEY_DOWN:
				_map_offset.y -= 30
				_apply_map_offset()
				get_viewport().set_input_as_handled()

	# 鼠标滚轮缩放
	if event is InputEventMouseButton and _is_open:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_on_zoom_in()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_on_zoom_out()
			get_viewport().set_input_as_handled()


## 子面板关闭处理
func _on_subpanel_closed() -> void:
	_subpanel_open = false


## 获取Tab名称
func _get_tab_name(tab_index: int) -> String:
	match tab_index:
		0: return "地图"
		1: return "传送"
		2: return "探索度"
		_: return "未知"
