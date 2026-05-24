## 背包面板控制器
## 对应 UX Spec: design/ux/inventory.md
## Z-index = 200（与角色面板同级）
## 数据源: InventorySystem (Autoload) + CurrencyManager (Autoload)

extends CanvasLayer

## 背包面板打开时发出
signal inventory_panel_opened(source: String, context_items: Array)
## 背包面板关闭时发出
signal inventory_panel_closed
## 物品使用时发出
signal inventory_item_used(item_id: String)
## 物品装备时发出
signal inventory_item_equipped(item_id: String, slot: String)
## 物品出售时发出
signal inventory_item_sold(item_id: String, price: int)
## 物品拆解时发出
signal inventory_item_dismantled(item_id: String, materials: Dictionary)
## 背包整理时发出
signal inventory_sorted

## 场景引用
@onready var _panel: PanelContainer = $PanelContainer
@onready var _title_label: Label = $PanelContainer/VBox/HeaderHBox/TitleLabel
@onready var _capacity_label: Label = $PanelContainer/VBox/HeaderHBox/CapacityLabel
@onready var _silver_label: Label = $PanelContainer/VBox/HeaderHBox/SilverLabel
@onready var _close_btn: Button = $PanelContainer/VBox/HeaderHBox/CloseButton
@onready var _filter_all_btn: Button = $PanelContainer/VBox/FilterHBox/FilterAllButton
@onready var _filter_equip_btn: Button = $PanelContainer/VBox/FilterHBox/FilterEquipButton
@onready var _filter_consumable_btn: Button = $PanelContainer/VBox/FilterHBox/FilterConsumableButton
@onready var _filter_material_btn: Button = $PanelContainer/VBox/FilterHBox/FilterMaterialButton
@onready var _sort_option: OptionButton = $PanelContainer/VBox/FilterHBox/SortOptionButton
@onready var _sort_backpack_btn: Button = $PanelContainer/VBox/FilterHBox/SortBackpackButton
@onready var _item_list: ItemList = $PanelContainer/VBox/ItemList
@onready var _item_name_label: Label = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemNameLabel
@onready var _item_desc_label: RichTextLabel = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemDescLabel
@onready var _use_btn: Button = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/UseButton
@onready var _equip_btn: Button = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/EquipButton
@onready var _sell_btn: Button = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/SellButton
@onready var _dismantle_btn: Button = $PanelContainer/VBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/DismantleButton

## 品阶颜色
const TIER_COLORS: Dictionary = {
	"common": Color(1.0, 1.0, 1.0),
	"uncommon": Color(0.0, 1.0, 0.0),
	"rare": Color(0.0, 0.5, 1.0),
	"epic": Color(0.6, 0.2, 0.8),
	"legendary": Color(1.0, 0.8, 0.0),
}

## 物品类型映射（items.json type → 过滤分类）
const TYPE_FILTER_MAP: Dictionary = {
	"weapon": "equipment",
	"armor": "equipment",
	"accessory": "equipment",
	"consumable": "consumable",
	"material": "material",
}

## 是否打开
var _is_open: bool = false
## 当前显示的物品列表（过滤+排序后）
var _displayed_items: Array[Dictionary] = []
## 当前选中物品索引
var _selected_item_index: int = -1
## 当前过滤类型
var _current_filter: String = "all"
## 减少运动设置
var _reduce_motion: bool = false
## 确认对话框实例
var _confirm_dialog: Node = null


func _ready() -> void:
	visible = false

	_load_confirm_dialog()

	# 连接按钮信号
	_close_btn.pressed.connect(close_panel)
	_item_list.item_selected.connect(_on_item_selected)
	_use_btn.pressed.connect(_on_use_item)
	_equip_btn.pressed.connect(_on_equip_item)
	_sell_btn.pressed.connect(_on_sell_item)
	_dismantle_btn.pressed.connect(_on_dismantle_item)
	_sort_backpack_btn.pressed.connect(_on_sort_backpack)

	# 过滤按钮
	_filter_all_btn.pressed.connect(_on_filter_all)
	_filter_equip_btn.pressed.connect(_on_filter_equip)
	_filter_consumable_btn.pressed.connect(_on_filter_consumable)
	_filter_material_btn.pressed.connect(_on_filter_material)

	# 排序选项
	_sort_option.add_item("按名称")
	_sort_option.add_item("按品阶")
	_sort_option.add_item("按数量")
	_sort_option.item_selected.connect(_on_sort_changed)

	_reduce_motion = _load_reduce_motion_setting()

	# 连接 InventorySystem 信号
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		inv.item_added_to_inventory.connect(_on_inventory_changed)
		inv.item_removed_from_inventory.connect(_on_inventory_changed)

	# 连接 CurrencyManager 信号
	var currency = get_node_or_null("/root/CurrencyManager")
	if currency:
		currency.currency_changed.connect(_on_currency_changed)


## 打开背包面板
func open_panel(source: String = "keyboard", context_items: Array = []) -> void:
	if _is_open:
		return

	_is_open = true
	visible = true
	_panel.position.x = _panel.size.x

	if _reduce_motion:
		_panel.position.x = 0
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "position:x", 0.0, 0.3)

	_refresh_inventory()
	_update_silver_display()
	_close_btn.grab_focus()

	inventory_panel_opened.emit(source, context_items)


## 关闭背包面板
func close_panel() -> void:
	if not _is_open:
		return

	_is_open = false
	_selected_item_index = -1
	_clear_item_detail()

	if _reduce_motion:
		_panel.position.x = _panel.size.x
		visible = false
	else:
		var tween = create_tween()
		tween.tween_property(_panel, "position:x", _panel.size.x, 0.25)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.finished.connect(func(): visible = false)

	inventory_panel_closed.emit()


## 刷新背包列表（从 InventorySystem 读取）
func _refresh_inventory() -> void:
	_item_list.clear()

	var inv = get_node_or_null("/root/InventorySystem")
	if inv == null:
		return

	var all_items = inv.get_all_items_with_data()
	_displayed_items = _filter_items(all_items)
	_sort_items(_displayed_items)

	for i in range(_displayed_items.size()):
		var item = _displayed_items[i]
		var display_name = item.get("name", item.get("id", "???"))
		var qty = item.get("quantity", 1)
		if qty > 1:
			display_name += " x%d" % qty

		var tier = item.get("tier", "common")
		var tier_color = TIER_COLORS.get(tier, Color.WHITE)
		_item_list.add_item(display_name)
		_item_list.set_item_custom_fg_color(i, tier_color)

	# 更新容量
	var slot_count = inv.get_item_slot_count()
	_capacity_label.text = "容量: %d/%d" % [slot_count, inv.MAX_INVENTORY_SIZE]

	_clear_item_detail()


## 更新银两显示
func _update_silver_display() -> void:
	var currency = get_node_or_null("/root/CurrencyManager")
	if currency == null:
		_silver_label.text = "银两: 0"
		return

	var silver = currency.get_currency_amount(currency.CurrencyType.SILVER)
	_silver_label.text = "银两: %d" % silver


## 过滤物品
func _filter_items(items: Array[Dictionary]) -> Array[Dictionary]:
	if _current_filter == "all":
		return items

	var filtered: Array[Dictionary] = []
	for item in items:
		var item_type = item.get("type", "")
		var filter_category = TYPE_FILTER_MAP.get(item_type, "material")
		if filter_category == _current_filter:
			filtered.append(item)
	return filtered


## 排序物品
func _sort_items(items: Array[Dictionary]) -> void:
	var sort_index = _sort_option.selected if _sort_option.selected >= 0 else 0
	match sort_index:
		0: # 按名称
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("name", "") < b.get("name", "")
			)
		1: # 按品阶
			var tier_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return tier_order.get(a.get("tier", "common"), 0) > tier_order.get(b.get("tier", "common"), 0)
			)
		2: # 按数量
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("quantity", 1) > b.get("quantity", 1)
			)


## 物品选中
func _on_item_selected(index: int) -> void:
	_selected_item_index = index
	if index < 0 or index >= _displayed_items.size():
		_clear_item_detail()
		return
	_show_item_detail(_displayed_items[index])


## 显示物品详情
func _show_item_detail(item: Dictionary) -> void:
	var tier = item.get("tier", "common")
	var tier_color = TIER_COLORS.get(tier, Color.WHITE)
	var tier_name = _get_tier_name(tier)

	_item_name_label.text = item.get("name", "")
	_item_name_label.add_theme_color_override("font_color", tier_color)

	var desc = "[color=%s][%s][/color]\n" % [tier_color.to_html(), tier_name]
	desc += "%s\n\n" % item.get("description", "")

	var qty = item.get("quantity", 1)
	if qty > 1:
		desc += "[b]数量:[/b] %d\n" % qty
	if item.has("slot") and item.slot != "inventory":
		desc += "[b]部位:[/b] %s\n" % item.slot
	if item.has("attributes"):
		var attrs = item.attributes
		if attrs.has("combat"):
			desc += "[b]战斗属性:[/b]\n"
			for stat in attrs.combat:
				desc += "  %s: +%s\n" % [stat, str(attrs.combat[stat])]
		if attrs.has("base"):
			desc += "[b]基础属性:[/b]\n"
			for stat in attrs.base:
				desc += "  %s: +%s\n" % [stat, str(attrs.base[stat])]
	if item.has("consumable_effect"):
		desc += "[b]效果:[/b] "
		var eff = item.consumable_effect
		match eff.get("type", ""):
			"heal":
				desc += "恢复 %d 生命值\n" % eff.get("value", 0)
			"exp_boost":
				desc += "获得 %d 修炼经验\n" % eff.get("value", 0)
			"breakthrough":
				desc += "用于境界突破\n"
			"reset_attributes":
				desc += "重置属性点分配\n"
			"random":
				desc += "随机效果（经验 %d~%d）\n" % [int(eff.get("value", 0) * 0.5), int(eff.get("value", 0) * 1.5)]
			_:
				desc += "%s\n" % str(eff)
	if item.has("special_effects"):
		desc += "[b]特殊效果:[/b]\n"
		for effect in item.special_effects:
			desc += "  · %s\n" % effect

	desc += "\n[b]出售价格:[/b] %d 银两" % item.get("value_gold", 0)
	_item_desc_label.text = desc

	# 按钮可见性
	var item_type = item.get("type", "")
	_use_btn.visible = (item_type == "consumable")
	_equip_btn.visible = (item_type in ["weapon", "armor", "accessory"])
	_sell_btn.visible = true
	_dismantle_btn.visible = (item_type in ["weapon", "armor", "accessory"])


## 清除物品详情
func _clear_item_detail() -> void:
	_item_name_label.text = "未选择物品"
	_item_name_label.add_theme_color_override("font_color", Color.WHITE)
	_item_desc_label.text = ""
	_use_btn.visible = false
	_equip_btn.visible = false
	_sell_btn.visible = false
	_dismantle_btn.visible = false


## 使用物品
func _on_use_item() -> void:
	if _selected_item_index < 0 or _selected_item_index >= _displayed_items.size():
		return

	var item = _displayed_items[_selected_item_index]
	var item_id = item.get("id", "")

	var inv = get_node_or_null("/root/InventorySystem")
	if inv and inv.use_item(item_id):
		inventory_item_used.emit(item_id)
		print("[Inventory] 使用物品: %s" % item.get("name", item_id))


## 装备物品
func _on_equip_item() -> void:
	if _selected_item_index < 0 or _selected_item_index >= _displayed_items.size():
		return

	var item = _displayed_items[_selected_item_index]
	var item_id = item.get("id", "")
	var slot = item.get("slot", "")

	var inv = get_node_or_null("/root/InventorySystem")
	if inv and inv.equip_item(item_id, slot):
		inventory_item_equipped.emit(item_id, slot)
		print("[Inventory] 装备物品: %s (部位: %s)" % [item.get("name", ""), slot])


## 出售物品
func _on_sell_item() -> void:
	if _selected_item_index < 0 or _selected_item_index >= _displayed_items.size():
		return

	var item = _displayed_items[_selected_item_index]
	var item_id = item.get("id", "")
	var price = item.get("value_gold", 0)

	_show_confirm_dialog(
		"确认出售",
		"确定要出售 %s 吗？\n获得 %d 银两" % [item.get("name", ""), price],
		"sell_%s" % item_id,
		func() -> void:
			var inv = get_node_or_null("/root/InventorySystem")
			if inv and inv.sell_item(item_id):
				inventory_item_sold.emit(item_id, price)
				_update_silver_display()
				print("[Inventory] 出售物品: %s, 获得 %d 银两" % [item.get("name", ""), price])
	)


## 拆解物品
func _on_dismantle_item() -> void:
	if _selected_item_index < 0 or _selected_item_index >= _displayed_items.size():
		return

	var item = _displayed_items[_selected_item_index]
	var item_id = item.get("id", "")
	var materials: Dictionary = _get_dismantle_materials(item.get("tier", "common"))

	_show_confirm_dialog(
		"确认拆解",
		"确定要拆解 %s 吗？\n获得: %s" % [item.get("name", ""), _format_materials(materials)],
		"dismantle_%s" % item_id,
		func() -> void:
			var inv = get_node_or_null("/root/InventorySystem")
			if inv and inv.remove_item(item_id, 1):
				for mat_id in materials:
					inv.add_item(mat_id, materials[mat_id])
				inventory_item_dismantled.emit(item_id, materials)
				print("[Inventory] 拆解物品: %s" % item.get("name", ""))
	)


## 整理背包
func _on_sort_backpack() -> void:
	_refresh_inventory()
	inventory_sorted.emit()


## 过滤按钮回调
func _on_filter_all() -> void: _set_filter("all")
func _on_filter_equip() -> void: _set_filter("equipment")
func _on_filter_consumable() -> void: _set_filter("consumable")
func _on_filter_material() -> void: _set_filter("material")


## 设置过滤类型
func _set_filter(filter_type: String) -> void:
	_current_filter = filter_type
	_filter_all_btn.button_pressed = (filter_type == "all")
	_filter_equip_btn.button_pressed = (filter_type == "equipment")
	_filter_consumable_btn.button_pressed = (filter_type == "consumable")
	_filter_material_btn.button_pressed = (filter_type == "material")
	_refresh_inventory()


## 排序选项变化
func _on_sort_changed(_index: int) -> void:
	_refresh_inventory()


## InventorySystem 信号回调：物品变动时刷新UI
func _on_inventory_changed(_item_id: String, _count: int) -> void:
	if _is_open:
		_refresh_inventory()


## CurrencyManager 信号回调：货币变动时刷新
func _on_currency_changed(_currency_type: int, _old: int, _new: int) -> void:
	if _is_open:
		_update_silver_display()


## 获取品阶名称
func _get_tier_name(tier: String) -> String:
	match tier:
		"common": return "普通"
		"uncommon": return "优秀"
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
		_: return "未知"


## 获取拆解材料
func _get_dismantle_materials(tier: String) -> Dictionary:
	match tier:
		"common": return {"iron_ingot": 2}
		"uncommon": return {"iron_ingot": 3, "spirit_stone_small": 1}
		"rare": return {"iron_ingot": 5, "spirit_stone_small": 3}
		"epic": return {"spirit_stone_small": 5}
		"legendary": return {"spirit_stone_small": 10}
		_: return {}


## 格式化材料显示
func _format_materials(materials: Dictionary) -> String:
	var inv = get_node_or_null("/root/InventorySystem")
	var parts: Array[String] = []
	for mat_id in materials:
		var mat_name = mat_id
		if inv:
			var data = inv.get_item_data(mat_id)
			mat_name = data.get("name", mat_id)
		parts.append("%s x%d" % [mat_name, materials[mat_id]])
	return ", ".join(parts)


## 输入处理
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE, KEY_I:
				if _is_open:
					close_panel()
					get_viewport().set_input_as_handled()


## 加载确认对话框（作为自身最后子节点，确保在同一canvas中渲染在最上层）
func _load_confirm_dialog() -> void:
	var scene = load("res://src/scenes/ui/confirm_dialog.tscn")
	if scene != null:
		_confirm_dialog = scene.instantiate()
		add_child(_confirm_dialog)
		_confirm_dialog.confirmed.connect(_on_dialog_confirmed)
		_confirm_dialog.cancelled.connect(_on_dialog_cancelled)


## 显示确认对话框
func _show_confirm_dialog(title: String, description: String, suppress_key: String, on_confirm: Callable) -> void:
	if _confirm_dialog != null:
		_confirm_dialog.show_confirm(title, description, suppress_key)
		_confirm_dialog.confirmed.connect(on_confirm, CONNECT_ONE_SHOT)

func _on_dialog_confirmed() -> void:
	pass

func _on_dialog_cancelled() -> void:
	pass


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
