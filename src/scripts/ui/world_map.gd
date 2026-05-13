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
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	# CanvasLayer 不可见时 TabBar 可能未加载编辑器定义的标签
	if _tab_bar.tab_count == 0:
		_tab_bar.add_tab("地图")
		_tab_bar.add_tab("传送")
		_tab_bar.add_tab("探索度")

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

	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	_teleport_points.clear()

	if game_loop:
		# 从 GameLoopManager 获取区域数据
		var regions: Array = game_loop.REGIONS
		var marker_positions: Array[Vector2] = [
			Vector2(150, 350), Vector2(400, 200), Vector2(650, 400), Vector2(350, 500)
		]
		for i in range(regions.size()):
			var region: Dictionary = regions[i]
			var pos: Vector2 = marker_positions[i] if i < marker_positions.size() else Vector2(100 + i * 150, 300)
			_teleport_points.append({
				"id": region.id,
				"name": region.name,
				"region": region.name,
				"position": pos,
				"unlocked": true,
				"level": region.level,
			})
	else:
		_teleport_points = [
			{"id": "start_village", "name": "新手村·青石镇", "region": "青石镇", "position": Vector2(150, 350), "unlocked": true, "level": 1},
		]

	# 创建传送点标记
	for point in _teleport_points:
		_create_marker(point.position, point.name, "teleport", point.unlocked)

	# 玩家当前位置标记
	var current_region_name := "未知区域"
	if game_loop:
		current_region_name = game_loop.current_region.get("name", "未知区域")
		# 在当前区域标记上显示玩家位置
		for point in _teleport_points:
			if point.id == game_loop.current_region.get("id", ""):
				_create_marker(point.position + Vector2(0, -20), "▼ 你在此", "player", true)
				break

	_current_region_label.text = "当前区域: %s" % current_region_name
	if game_loop:
		_exploration_label.text = "推荐等级: %d" % game_loop.current_region.get("level", 1)
	else:
		_exploration_label.text = ""


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
		var display_text := "%s (Lv.%d)" % [point.name, point.get("level", 1)]
		_teleport_list.add_item(display_text)

	# 默认选中第一个
	if _teleport_list.item_count > 0:
		_teleport_list.select(0)
		_on_teleport_point_selected(0)
	else:
		_travel_cost_label.text = "旅行费用: --"
		_player_realm_label.text = "境界: --"
		_spirit_stone_label.text = "银两: --"
		_travel_btn.disabled = true


## 传送点选中
func _on_teleport_point_selected(index: int) -> void:
	_selected_teleport_index = index
	if index < 0 or index >= _teleport_points.size():
		return

	var point: Dictionary = _teleport_points[index]
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	var is_current := false
	if game_loop:
		is_current = (point.id == game_loop.current_region.get("id", ""))

	# 旅行费用：推荐等级 × 5 银两
	var cost: int = point.get("level", 1) * 5
	_travel_cost_label.text = "旅行费用: %d 银两" % cost

	# 境界
	var cs: Node = get_node_or_null("/root/CharacterSystem")
	var realm_name := "炼气"
	if cs:
		var realm_info: Dictionary = cs.get_current_realm()
		realm_name = realm_info.get("name", "炼气")
	_player_realm_label.text = "境界: %s" % realm_name

	# 银两
	var currency_mgr: Node = get_node_or_null("/root/CurrencyManager")
	var silver: int = 0
	if currency_mgr and currency_mgr.has_method("get_currency_amount"):
		silver = currency_mgr.get_currency_amount(0)
	_spirit_stone_label.text = "银两: %d" % silver

	# 已在当前区域则禁用旅行
	_travel_btn.disabled = is_current or silver < cost
	if is_current:
		_travel_btn.text = "已在此区域"
	elif silver < cost:
		_travel_btn.text = "银两不足"
	else:
		_travel_btn.text = "前往"


## 确认旅行
func _on_travel_confirmed() -> void:
	if _selected_teleport_index < 0 or _selected_teleport_index >= _teleport_points.size():
		return

	var point: Dictionary = _teleport_points[_selected_teleport_index]
	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	var currency_mgr: Node = get_node_or_null("/root/CurrencyManager")

	var cost: int = point.get("level", 1) * 5

	# 扣除银两
	if currency_mgr and currency_mgr.has_method("spend_currency"):
		currency_mgr.spend_currency(0, cost)

	# 切换区域
	if game_loop:
		var regions: Array = game_loop.REGIONS
		for i in range(regions.size()):
			if regions[i].id == point.id:
				game_loop.select_region(i)
				break

	var from_region := "当前区域"
	if game_loop:
		from_region = game_loop.current_region.get("name", "当前区域")

	world_map_travel_confirmed.emit(from_region, point.name, cost)
	close_map()


## 更新探索度数据
func _update_exploration_data() -> void:
	_region_list.clear()

	var game_loop: Node = get_node_or_null("/root/GameLoopManager")
	if game_loop == null:
		_overall_progress_bar.value = 0
		_overall_percent_label.text = "0%"
		return

	var regions: Array = game_loop.REGIONS
	var current_id: String = game_loop.current_region.get("id", "")
	var cs: Node = get_node_or_null("/root/CharacterSystem")
	var player_level: int = cs.level if cs else 1

	var discovered_count: int = 0
	for region in regions:
		var is_current: bool = (region.id == current_id)
		var accessible: bool = (player_level >= region.level)
		var status_text: String
		if is_current:
			status_text = "📍 当前"
			discovered_count += 1
		elif accessible:
			status_text = "✓ 可前往"
			discovered_count += 1
		else:
			status_text = "🔒 等级不足 (需Lv.%d)" % region.level

		_region_list.add_item("%s (Lv.%d) — %s" % [region.name, region.level, status_text])

	var overall_pct: float = (float(discovered_count) / float(regions.size())) * 100.0 if regions.size() > 0 else 0.0
	_overall_progress_bar.value = overall_pct
	_overall_percent_label.text = "%d%%" % int(overall_pct)


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
				if _tab_bar.tab_count > 0:
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
