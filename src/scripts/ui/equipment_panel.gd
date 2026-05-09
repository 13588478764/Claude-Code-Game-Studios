## 装备面板控制器
## 对应 UX Spec: design/ux/equipment-panel.md
## Z-index = 200（与角色面板、背包面板同级）

extends CanvasLayer

## 装备面板打开时发出
signal equipment_panel_opened(source: String, tab_shown: String)
## 装备面板关闭时发出
signal equipment_panel_closed(time_spent_ms: int, tab_viewed: String, changes_made: bool)
## 装备物品时发出
signal equipment_item_equipped(item_id: String, slot_type: String)
## 卸下装备时发出
signal equipment_item_unequipped(item_id: String, slot_type: String)
## 强化开始时发出
signal equipment_enhancement_started(item_id: String, from_level: int, success_rate: float)
## 强化成功时发出
signal equipment_enhancement_succeeded(item_id: String, new_level: int)
## 强化失败时发出
signal equipment_enhancement_failed(item_id: String, current_level: int, level_dropped: bool)
## 镶嵌宝石时发出
signal equipment_gem_socketed(item_id: String, socket_index: int, gem_color: String)
## 移除宝石时发出
signal equipment_gem_removed(item_id: String, socket_index: int, gem_color: String)
## 套装共鸣激活时发出
signal equipment_set_bonus_activated(gem_color: String, threshold: int)
## 应用幻化时发出
signal equipment_transmog_applied(weapon_id: String, skin_id: String)
## 取消幻化时发出
signal equipment_transmog_removed(weapon_id: String)

## 场景引用
@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/VBox/HeaderHBox/TitleLabel
@onready var _power_label: Label = $PanelContainer/VBox/HeaderHBox/PowerScoreLabel
@onready var _close_btn: Button = $PanelContainer/VBox/HeaderHBox/CloseButton
@onready var _tab_bar: TabBar = $PanelContainer/VBox/TabBar
@onready var _wear_tab: ScrollContainer = $PanelContainer/VBox/TabContent/WearTab
@onready var _enhance_tab: ScrollContainer = $PanelContainer/VBox/TabContent/EnhanceTab
@onready var _socket_tab: ScrollContainer = $PanelContainer/VBox/TabContent/SocketTab
@onready var _transmog_tab: ScrollContainer = $PanelContainer/VBox/TabContent/TransmogTab
@onready var _slot_grid: GridContainer = $PanelContainer/VBox/TabContent/WearTab/WearVBox/SlotGrid
@onready var _detail_name_label: Label = $PanelContainer/VBox/TabContent/WearTab/WearVBox/DetailPanel/DetailVBox/DetailNameLabel
@onready var _detail_desc_label: RichTextLabel = $PanelContainer/VBox/TabContent/WearTab/WearVBox/DetailPanel/DetailVBox/DetailDescLabel
@onready var _unequip_btn: Button = $PanelContainer/VBox/TabContent/WearTab/WearVBox/DetailPanel/DetailVBox/DetailActionHBox/UnequipButton
@onready var _enhance_equip_select: OptionButton = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/EquipSelectOption
@onready var _enhance_preview_label: Label = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/EquipPreviewLabel
@onready var _material_label: Label = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/MaterialLabel
@onready var _success_bar: ProgressBar = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/SuccessRateBar
@onready var _success_label: Label = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/SuccessRateLabel
@onready var _protection_check: CheckBox = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/ProtectionCheck
@onready var _enhance_btn: Button = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/EnhanceButton
@onready var _enhance_history_label: RichTextLabel = $PanelContainer/VBox/TabContent/EnhanceTab/EnhanceVBox/EnhanceHistoryLabel
@onready var _socket_equip_select: OptionButton = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/SocketEquipSelectOption
@onready var _socket_preview_label: Label = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/SocketPreviewLabel
@onready var _socket_hbox: HBoxContainer = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/SocketHBox
@onready var _gem_inventory_label: Label = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/GemInventoryLabel
@onready var _gem_grid: GridContainer = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/GemGrid
@onready var _socket_btn: Button = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/SocketButton
@onready var _remove_gem_btn: Button = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/RemoveGemButton
@onready var _set_bonus_label: RichTextLabel = $PanelContainer/VBox/TabContent/SocketTab/SocketVBox/SetBonusLabel
@onready var _current_weapon_label: Label = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/CurrentWeaponLabel
@onready var _preview_label: Label = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/PreviewLabel
@onready var _skin_grid: GridContainer = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/SkinGrid
@onready var _transmog_cost_label: Label = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/TransmogCostLabel
@onready var _apply_transmog_btn: Button = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/ApplyTransmogButton
@onready var _cancel_transmog_btn: Button = $PanelContainer/VBox/TabContent/TransmogTab/TransmogVBox/CancelTransmogButton

## 装备槽位定义（9个）
const EQUIPMENT_SLOTS: Array[Dictionary] = [
	{"id": "main_weapon", "name": "主手武器", "icon": "weapon"},
	{"id": "off_hand", "name": "副手/离手", "icon": "offhand"},
	{"id": "head", "name": "头饰", "icon": "head"},
	{"id": "chest", "name": "衣袍", "icon": "chest"},
	{"id": "hands", "name": "护手", "icon": "hands"},
	{"id": "feet", "name": "靴子", "icon": "feet"},
	{"id": "neck", "name": "项链", "icon": "neck"},
	{"id": "ring_left", "name": "戒指(左)", "icon": "ring"},
	{"id": "ring_right", "name": "戒指(右)", "icon": "ring"},
]

## 品阶颜色
const TIER_COLORS: Dictionary = {
	"common": Color(1.0, 1.0, 1.0),
	"uncommon": Color(0.0, 1.0, 0.0),
	"rare": Color(0.0, 0.5, 1.0),
	"epic": Color(0.6, 0.2, 0.8),
	"legendary": Color(1.0, 0.8, 0.0),
}

## 宝石颜色
const GEM_COLORS: Dictionary = {
	"red": Color(1.0, 0.0, 0.0),
	"blue": Color(0.0, 0.0, 1.0),
	"green": Color(0.0, 1.0, 0.0),
	"yellow": Color(1.0, 1.0, 0.0),
	"purple": Color(0.5, 0.0, 0.5),
	"diamond": Color(0.7, 0.8, 1.0),
}

## 是否打开
var _is_open: bool = false
## 打开时间
var _open_time_ms: float = 0.0
## 是否有变更
var _changes_made: bool = false
## 当前选中槽位索引
var _selected_slot_index: int = -1
## 当前强化选中装备索引
var _enhance_selected_index: int = 0
## 当前镶嵌选中装备索引
var _socket_selected_index: int = 0
## 当前选中宝石颜色
var _selected_gem_color: String = ""
## 当前选中镶嵌孔索引
var _selected_socket_hole: int = -1
## 当前选中幻化外观
var _selected_skin_index: int = -1
## 装备数据快照
var _equipped_items: Dictionary = {}
## 强化历史
var _enhance_history: Array[String] = []
## 减少运动设置
var _reduce_motion: bool = false


func _ready() -> void:
	# 初始隐藏
	visible = true
	_panel.position.x = _panel.size.x

	# 连接信号
	_close_btn.pressed.connect(close_panel)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_unequip_btn.pressed.connect(_on_unequip)
	_enhance_equip_select.item_selected.connect(_on_enhance_equip_selected)
	_enhance_btn.pressed.connect(_on_enhance)
	_protection_check.toggled.connect(_on_protection_toggled)
	_socket_equip_select.item_selected.connect(_on_socket_equip_selected)
	_socket_btn.pressed.connect(_on_socket)
	_remove_gem_btn.pressed.connect(_on_remove_gem)
	_apply_transmog_btn.pressed.connect(_on_apply_transmog)
	_cancel_transmog_btn.pressed.connect(_on_cancel_transmog)

	# 加载设置
	_reduce_motion = _load_reduce_motion_setting()

	# 初始化槽位按钮
	_create_slot_buttons()

	# 填充静态数据
	_populate_enhance_tab()
	_populate_socket_tab()
	_populate_transmog_tab()

	# 初始Tab
	_on_tab_changed(0)


## 打开装备面板
func open_panel(source: String = "keyboard", default_tab: int = 0) -> void:
	if _is_open:
		return

	_is_open = true
	_open_time_ms = Time.get_ticks_msec()
	_changes_made = false

	# 读取装备快照
	_load_equipment_snapshot()

	# 滑入动画
	if _reduce_motion:
		_panel.position.x = 0
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "position:x", 0.0, 0.3)

	# 刷新显示
	_refresh_wear_tab()
	_refresh_power_score()
	_tab_bar.current_tab = default_tab
	_on_tab_changed(default_tab)

	_close_btn.grab_focus()

	equipment_panel_opened.emit(source, _get_tab_name(default_tab))


## 关闭装备面板
func close_panel() -> void:
	if not _is_open:
		return

	var time_spent = int(Time.get_ticks_msec() - _open_time_ms)
	var tab_name = _get_tab_name(_tab_bar.current_tab)
	_is_open = false

	# 滑出动画
	if _reduce_motion:
		_panel.position.x = _panel.size.x
	else:
		var tween = create_tween()
		tween.tween_property(_panel, "position:x", _panel.size.x, 0.25)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)

	equipment_panel_closed.emit(time_spent, tab_name, _changes_made)


## Tab切换
func _on_tab_changed(tab_index: int) -> void:
	var tabs: Array[Control] = [_wear_tab, _enhance_tab, _socket_tab, _transmog_tab]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)

	# 切换时刷新对应数据
	match tab_index:
		1: _refresh_enhance_tab()
		2: _refresh_socket_tab()
		3: _refresh_transmog_tab()


## 创建装备槽位按钮
func _create_slot_buttons() -> void:
	# 清除旧按钮
	for child in _slot_grid.get_children():
		child.queue_free()

	for slot in EQUIPMENT_SLOTS:
		var btn = Button.new()
		btn.text = slot.name
		btn.custom_minimum_size = Vector2(72, 72)
		btn.flat = true
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.pressed.connect(func() -> void: _on_slot_clicked(EQUIPMENT_SLOTS.find(slot)))
		btn.mouse_entered.connect(func() -> void: _on_slot_hovered(EQUIPMENT_SLOTS.find(slot), true))
		btn.mouse_exited.connect(func() -> void: _on_slot_hovered(EQUIPMENT_SLOTS.find(slot), false))
		_slot_grid.add_child(btn)


## 槽位点击
func _on_slot_clicked(slot_index: int) -> void:
	_selected_slot_index = slot_index
	_show_slot_detail(slot_index)


## 槽位悬浮
func _on_slot_hovered(slot_index: int, hovered: bool) -> void:
	pass  # TODO: 悬浮时显示简要信息tooltip


## 刷新穿戴Tab
func _refresh_wear_tab() -> void:
	var btns = _slot_grid.get_children()
	for i in range(btns.size()):
		var btn = btns[i] as Button
		var slot = EQUIPMENT_SLOTS[i]
		if _equipped_items.has(slot.id) and _equipped_items[slot.id] != null:
			var item = _equipped_items[slot.id]
			var tier_color = TIER_COLORS.get(item.tier, Color.WHITE)
			btn.text = "%s\n+%d" % [item.name, item.get("enhancement_level", 0)]
			btn.add_theme_color_override("font_color", tier_color)
			btn.add_theme_stylebox_override("normal", _create_tier_stylebox(tier_color))
		else:
			btn.text = slot.name
			btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			btn.remove_theme_stylebox_override("normal")


## 显示槽位详情
func _show_slot_detail(slot_index: int) -> void:
	var slot = EQUIPMENT_SLOTS[slot_index]
	if _equipped_items.has(slot.id) and _equipped_items[slot.id] != null:
		var item = _equipped_items[slot.id]
		var tier_color = TIER_COLORS.get(item.tier, Color.WHITE)
		var tier_name = _get_tier_name(item.tier)

		_detail_name_label.text = "%s (+%d)" % [item.name, item.get("enhancement_level", 0)]
		_detail_name_label.add_theme_color_override("font_color", tier_color)

		var desc = "[color=%s][%s][/color]\n\n" % [tier_color.to_html(), tier_name]
		desc += "[b]部位:[/b] %s\n" % slot.name
		if item.has("stats"):
			desc += "[b]属性:[/b]\n"
			for stat in item.stats:
				desc += "  %s: +%d\n" % [stat, item.stats[stat]]
		if item.has("socket_count") and item.socket_count > 0:
			var gem_text = ""
			if item.has("sockets"):
				for gem in item.sockets:
					gem_text += "%s, " % gem.get("color", "?")
			desc += "[b]孔洞:[/b] %d (%s)\n" % [item.socket_count, gem_text]

		_detail_desc_label.text = desc
		_unequip_btn.visible = true
	else:
		_detail_name_label.text = slot.name
		_detail_name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		_detail_desc_label.text = "空槽位"
		_unequip_btn.visible = false


## 卸下装备
func _on_unequip() -> void:
	if _selected_slot_index < 0 or _selected_slot_index >= EQUIPMENT_SLOTS.size():
		return

	var slot = EQUIPMENT_SLOTS[_selected_slot_index]
	if _equipped_items.has(slot.id) and _equipped_items[slot.id] != null:
		var item = _equipped_items[slot.id]
		equipment_item_unequipped.emit(item.id, slot.id)
		_equipped_items[slot.id] = null
		_changes_made = true
		_refresh_wear_tab()
		_refresh_power_score()
		_clear_detail()


## 清除详情
func _clear_detail() -> void:
	_detail_name_label.text = "未选择装备"
	_detail_name_label.add_theme_color_override("font_color", Color.WHITE)
	_detail_desc_label.text = ""
	_unequip_btn.visible = false


## 填充强化Tab数据
func _populate_enhance_tab() -> void:
	_enhance_equip_select.add_item("无装备")
	_success_bar.value = 0
	_success_label.text = "成功率: 0%"
	_enhance_btn.disabled = true

	# 强化石和银两（占位）
	_material_label.text = "强化石: 50 / 银两: 5000"


## 刷新强化Tab
func _refresh_enhance_tab() -> void:
	_enhance_equip_select.clear()

	var has_any = false
	for slot in EQUIPMENT_SLOTS:
		if _equipped_items.has(slot.id) and _equipped_items[slot.id] != null:
			var item = _equipped_items[slot.id]
			var level = item.get("enhancement_level", 0)
			_enhance_equip_select.add_item("%s (+%d)" % [item.name, level])
			has_any = true

	if not has_any:
		_enhance_equip_select.add_item("无装备")
		_enhance_btn.disabled = true
		return

	# 选中第一个
	if _enhance_selected_index >= _enhance_equip_select.item_count:
		_enhance_selected_index = 0
	_enhance_equip_select.select(_enhance_selected_index)
	_on_enhance_equip_selected(_enhance_selected_index)


## 强化装备选中变化
func _on_enhance_equip_selected(index: int) -> void:
	_enhance_selected_index = index

	# 计算成功率（占位公式）
	var success_rate = 100.0
	var target_level = _get_target_enhance_level()
	if target_level > 10:
		success_rate = max(20.0, 100.0 - (target_level - 10) * 8.0)

	_success_bar.value = success_rate
	_success_label.text = "成功率: %d%%" % int(success_rate)
	_update_success_rate_color(success_rate)

	_enhance_btn.disabled = (target_level > 20)


## 获取目标强化等级
func _get_target_enhance_level() -> int:
	if _enhance_selected_index < 0:
		return 1
	# 占位: 假设+1
	return 1


## 更新成功率颜色
func _update_success_rate_color(rate: float) -> void:
	if rate >= 60:
		_success_label.add_theme_color_override("font_color", Color(0.18, 0.55, 0.34))
	elif rate >= 40:
		_success_label.add_theme_color_override("font_color", Color(0.83, 0.63, 0.09))
	else:
		_success_label.add_theme_color_override("font_color", Color(0.94, 0.27, 0.27))


## 保护符切换
func _on_protection_toggled(enabled: bool) -> void:
	pass  # TODO: 更新消耗预览


## 执行强化
func _on_enhance() -> void:
	if _enhance_selected_index < 0:
		return

	var success_rate = _success_bar.value
	var from_level = _get_target_enhance_level()

	# 模拟强化结果
	var roll = randf() * 100.0
	if roll <= success_rate:
		# 成功
		equipment_enhancement_started.emit("", from_level, success_rate / 100.0)
		equipment_enhancement_succeeded.emit("", from_level + 1)
		_enhance_history.append("[color=green]强化成功! 等级 +%d[/color]" % (from_level + 1))
	else:
		# 失败（+16以上降级）
		var level_dropped = (from_level >= 15)
		equipment_enhancement_failed.emit("", from_level, level_dropped)
		_enhance_history.append("[color=red]强化失败!%s[/color]" % (" 等级-%d" % (2 if from_level >= 17 else 1) if level_dropped else ""))

	_changes_made = true
	_update_enhance_history()
	_refresh_enhance_tab()


## 更新强化历史显示
func _update_enhance_history() -> void:
	var history_text = "[b]强化历史[/b]\n"
	var show_count = min(5, _enhance_history.size())
	for i in range(show_count):
		history_text += _enhance_history[_enhance_history.size() - show_count + i] + "\n"
	_enhance_history_label.text = history_text


## 填充镶嵌Tab数据
func _populate_socket_tab() -> void:
	_socket_equip_select.add_item("无装备")

	# 宝石库存（占位）
	for color in GEM_COLORS:
		var label = Label.new()
		label.text = "%s x3" % color.capitalize()
		label.add_theme_color_override("font_color", GEM_COLORS[color])
		_gem_grid.add_child(label)

	_gem_inventory_label.text = "宝石库存"
	_set_bonus_label.text = "[b]套装共鸣[/b]\n\n红色: 0/6 ❌\n蓝色: 0/6 ❌\n绿色: 0/6 ❌\n黄色: 0/6 ❌\n紫色: 0/6 ❌\n钻石: 0/6 ❌"


## 刷新镶嵌Tab
func _refresh_socket_tab() -> void:
	_socket_equip_select.clear()
	var has_any = false
	for slot in EQUIPMENT_SLOTS:
		if _equipped_items.has(slot.id) and _equipped_items[slot.id] != null:
			var item = _equipped_items[slot.id]
			var sockets = item.get("socket_count", 0)
			var filled = 0
			if item.has("sockets"):
				filled = item.sockets.size()
			_socket_equip_select.add_item("%s (%d/%d)" % [item.name, filled, sockets])
			has_any = true

	if not has_any:
		_socket_equip_select.add_item("无装备")
		return

	if _socket_selected_index >= _socket_equip_select.item_count:
		_socket_selected_index = 0
	_socket_equip_select.select(_socket_selected_index)
	_on_socket_equip_selected(_socket_selected_index)


## 镶嵌装备选中变化
func _on_socket_equip_selected(index: int) -> void:
	_socket_selected_index = index
	_socket_preview_label.text = "孔洞: 0/3"  # TODO: 实际数据


## 执行镶嵌
func _on_socket() -> void:
	# TODO: 弹出确认对话框
	print("[Equipment] 镶嵌宝石")
	_changes_made = true


## 移除宝石
func _on_remove_gem() -> void:
	# TODO: 弹出确认对话框
	print("[Equipment] 移除宝石")
	_changes_made = true


## 填充幻化Tab数据
func _populate_transmog_tab() -> void:
	# 外观库（占位）
	var skins = [
		"倚天剑", "屠龙刀", "青釭剑", "龙鳞剑",
		"寒冰刃", "烈火刀", "玄铁剑", "紫金锤",
		"白云剑", "秋水剑", "清风剑", "明月刀",
	]
	for skin in skins:
		var btn = Button.new()
		btn.text = skin
		btn.custom_minimum_size = Vector2(64, 64)
		btn.flat = true
		btn.pressed.connect(func() -> void: _select_skin(skins.find(skin)))
		_skin_grid.add_child(btn)


## 刷新幻化Tab
func _refresh_transmog_tab() -> void:
	# 当前武器（占位）
	_current_weapon_label.text = "当前武器: 铁剑"
	_preview_label.text = "当前外观 → 未选择"
	_apply_transmog_btn.disabled = true


## 选中外观
func _select_skin(index: int) -> void:
	_selected_skin_index = index
	var btns = _skin_grid.get_children()
	for btn in btns:
		btn.add_theme_stylebox_override("normal", null)

	var target_btn = btns[index] as Button
	var gold_style = _create_tier_stylebox(TIER_COLORS.legendary)
	target_btn.add_theme_stylebox_override("normal", gold_style)

	_preview_label.text = "当前外观 → %s" % target_btn.text
	_apply_transmog_btn.disabled = false


## 应用幻化
func _on_apply_transmog() -> void:
	if _selected_skin_index < 0:
		return
	# TODO: 弹出确认对话框
	equipment_transmog_applied.emit("current_weapon", str(_selected_skin_index))
	_changes_made = true
	print("[Equipment] 应用幻化: index %d" % _selected_skin_index)


## 取消幻化
func _on_cancel_transmog() -> void:
	equipment_transmog_removed.emit("currentWeapon")
	_changes_made = true
	_preview_label.text = "当前外观 → 未选择"
	_selected_skin_index = -1
	for btn in _skin_grid.get_children():
		btn.add_theme_stylebox_override("normal", null)


## 加载装备快照（占位，后续从EquipmentSystem读取）
func _load_equipment_snapshot() -> void:
	_equipped_items = {
		"main_weapon": {"id": "iron_sword", "name": "铁剑", "tier": "common", "enhancement_level": 3, "stats": {"attack": 15}, "socket_count": 0},
		"chest": {"id": "leather_armor", "name": "皮甲", "tier": "common", "enhancement_level": 1, "stats": {"defense": 8}, "socket_count": 0},
		"ring_left": {"id": "jade_ring", "name": "碧玉环", "tier": "rare", "enhancement_level": 0, "stats": {"luck": 5}, "socket_count": 2, "sockets": [{"color": "red"}]},
	}


## 刷新战力评分
func _refresh_power_score() -> void:
	var power = 0
	for slot_id in _equipped_items:
		var item = _equipped_items[slot_id]
		if item == null:
			continue
		if item.has("stats"):
			for stat in item.stats:
				power += item.stats[stat]
		var level_bonus = item.get("enhancement_level", 0) * 5
		power += level_bonus

	_power_label.text = "战力: %d" % power


## 获取Tab名称
func _get_tab_name(tab_index: int) -> String:
	match tab_index:
		0: return "穿戴"
		1: return "强化"
		2: return "镶嵌"
		3: return "幻化"
		_: return "未知"


## 获取品阶名称
func _get_tier_name(tier: String) -> String:
	match tier:
		"common": return "普通"
		"uncommon": return "优秀"
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
		_: return "未知"


## 创建品阶样式框
func _create_tier_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.3)
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style


## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_E:
				if _is_open:
					close_panel()
					get_viewport().set_input_as_handled()


## 读取减少运动设置
func _load_reduce_motion_setting() -> bool:
	var settings_path = "user://settings.json"
	if not FileAccess.file_exists(settings_path):
		return false
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if file == null:
		return false
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null:
		return false
	return json.get("reduce_motion", false)
