## 背包面板控制器
## 对应 UX Spec: design/ux/inventory.md
## Z-index = 200（与角色面板同级）

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
@onready var _close_btn: Button = $PanelContainer/VBox/HeaderHBox/CloseButton
@onready var _tab_bar: TabBar = $PanelContainer/VBox/TabBar
@onready var _backpack_tab: ScrollContainer = $PanelContainer/VBox/TabContent/BackpackTab
@onready var _currency_tab: ScrollContainer = $PanelContainer/VBox/TabContent/CurrencyTab
@onready var _quick_actions_tab: ScrollContainer = $PanelContainer/VBox/TabContent/QuickActionsTab
@onready var _filter_all_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/FilterHBox/FilterAllButton
@onready var _filter_equip_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/FilterHBox/FilterEquipButton
@onready var _filter_consumable_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/FilterHBox/FilterConsumableButton
@onready var _filter_material_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/FilterHBox/FilterMaterialButton
@onready var _sort_option: OptionButton = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/FilterHBox/SortOptionButton
@onready var _item_list: ItemList = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemList
@onready var _item_name_label: Label = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemNameLabel
@onready var _item_desc_label: RichTextLabel = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemDescLabel
@onready var _use_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/UseButton
@onready var _equip_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/EquipButton
@onready var _sell_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/SellButton
@onready var _dismantle_btn: Button = $PanelContainer/VBox/TabContent/BackpackTab/BackpackVBox/ItemDetailPanel/ItemDetailVBox/ItemActionHBox/DismantleButton
@onready var _spirit_stone_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/SpiritStoneLabel
@onready var _gold_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/GoldLabel
@onready var _silver_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/SilverLabel
@onready var _copper_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/CopperLabel
@onready var _contribution_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/ContributionLabel
@onready var _sect_points_label: Label = $PanelContainer/VBox/TabContent/CurrencyTab/CurrencyVBox/CurrencyGrid/SectPointsLabel
@onready var _bulk_sell_btn: Button = $PanelContainer/VBox/TabContent/QuickActionsTab/QuickActionsVBox/BulkSellButton
@onready var _bulk_dismantle_btn: Button = $PanelContainer/VBox/TabContent/QuickActionsTab/QuickActionsVBox/BulkDismantleButton
@onready var _sort_backpack_btn: Button = $PanelContainer/VBox/TabContent/QuickActionsTab/QuickActionsVBox/SortBackpackButton

## 物品类型枚举
enum ItemType { EQUIPMENT, CONSUMABLE, MATERIAL, QUEST_ITEM }

## 品阶颜色
const TIER_COLORS: Dictionary = {
	"common": Color(1.0, 1.0, 1.0),    # 白色
	"uncommon": Color(0.0, 1.0, 0.0),  # 绿色
	"rare": Color(0.0, 0.5, 1.0),      # 蓝色
	"epic": Color(0.6, 0.2, 0.8),      # 紫色
	"legendary": Color(1.0, 0.8, 0.0), # 金色
}

## 是否打开
var _is_open: bool = false
## 背包容量
var _max_capacity: int = 50
## 当前物品数据（占位）
var _inventory_items: Array[Dictionary] = []
## 当前选中物品索引
var _selected_item_index: int = -1
## 当前过滤类型
var _current_filter: String = "all"
## 减少运动设置
var _reduce_motion: bool = false


func _ready() -> void:
	# 初始隐藏在屏幕右侧之外
	visible = true
	_panel.position.x = _panel.size.x

	# 连接信号
	_close_btn.pressed.connect(close_panel)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_item_list.item_selected.connect(_on_item_selected)
	_use_btn.pressed.connect(_on_use_item)
	_equip_btn.pressed.connect(_on_equip_item)
	_sell_btn.pressed.connect(_on_sell_item)
	_dismantle_btn.pressed.connect(_on_dismantle_item)
	_bulk_sell_btn.pressed.connect(_on_bulk_sell)
	_bulk_dismantle_btn.pressed.connect(_on_bulk_dismantle)
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

	# 加载设置
	_reduce_motion = _load_reduce_motion_setting()

	# 初始化背包数据
	_init_sample_inventory()

	# 填充货币Tab
	_populate_currency_tab()


## 打开背包面板
func open_panel(source: String = "keyboard", context_items: Array = []) -> void:
	if _is_open:
		return

	_is_open = true

	# 注意：半模态，遮罩拦截游戏输入但游戏渲染在背后

	# 滑入动画
	if _reduce_motion:
		_panel.position.x = 0
	else:
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_panel, "position:x", 0.0, 0.3)

	# 刷新数据
	_refresh_inventory()

	# 默认焦点
	_close_btn.grab_focus()

	inventory_panel_opened.emit(source, context_items)


## 关闭背包面板
func close_panel() -> void:
	if not _is_open:
		return

	_is_open = false
	_selected_item_index = -1
	_clear_item_detail()

	# 滑出动画
	if _reduce_motion:
		_panel.position.x = _panel.size.x
	else:
		var tween = create_tween()
		tween.tween_property(_panel, "position:x", _panel.size.x, 0.25)
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)

	inventory_panel_closed.emit()


## Tab切换
func _on_tab_changed(tab_index: int) -> void:
	var tabs: Array[Control] = [_backpack_tab, _currency_tab, _quick_actions_tab]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)


## 初始化示例背包数据（占位，后续从EconomySystem读取）
func _init_sample_inventory() -> void:
	_inventory_items = [
		{"id": "common_sword", "name": "铁剑", "type": ItemType.EQUIPMENT, "tier": "common", "slot": "weapon", "desc": "普通的铁剑，攻击力+5", "stats": {"attack": 5}, "quantity": 1, "price": 50},
		{"id": "rare_armor", "name": "精钢甲", "type": ItemType.EQUIPMENT, "tier": "rare", "slot": "chest", "desc": "精钢打造的铠甲，防御力+15", "stats": {"defense": 15}, "quantity": 1, "price": 200},
		{"id": "health_pill", "name": "回春丹", "type": ItemType.CONSUMABLE, "tier": "common", "desc": "恢复50点生命值", "effects": {"health": 50}, "quantity": 5, "price": 20},
		{"id": "spirit_stone_small", "name": "小灵石", "type": ItemType.MATERIAL, "tier": "common", "desc": "用于炼丹和炼器的基础材料", "quantity": 12, "price": 10},
		{"id": "breakthrough_pill", "name": "破境丹", "type": ItemType.CONSUMABLE, "tier": "epic", "desc": "用于境界突破的珍贵丹药", "effects": {"realm_breakthrough": true}, "quantity": 1, "price": 500},
	]


## 刷新背包列表
func _refresh_inventory() -> void:
	_item_list.clear()

	var filtered_items = _get_filtered_items()
	for i in range(filtered_items.size()):
		var item = filtered_items[i]
		var display_name = item.name
		if item.quantity > 1:
			display_name += " x%d" % item.quantity

		var tier_color = TIER_COLORS.get(item.tier, Color.WHITE)
		_item_list.add_item(display_name)
		_item_list.set_item_custom_fg_color(i, tier_color)

	# 更新容量显示
	var count = _inventory_items.size()
	_capacity_label.text = "容量: %d/%d" % [count, _max_capacity]

	# 清除详情
	_clear_item_detail()


## 获取过滤后的物品列表
func _get_filtered_items() -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []

	match _current_filter:
		"all":
			filtered = _inventory_items
		"equipment":
			for item in _inventory_items:
				if item.type == ItemType.EQUIPMENT:
					filtered.append(item)
		"consumable":
			for item in _inventory_items:
				if item.type == ItemType.CONSUMABLE:
					filtered.append(item)
		"material":
			for item in _inventory_items:
				if item.type == ItemType.MATERIAL:
					filtered.append(item)

	return filtered


## 物品选中
func _on_item_selected(index: int) -> void:
	_selected_item_index = index
	var filtered = _get_filtered_items()
	if index < 0 or index >= filtered.size():
		_clear_item_detail()
		return

	var item = filtered[index]
	_show_item_detail(item)


## 显示物品详情
func _show_item_detail(item: Dictionary) -> void:
	var tier_color = TIER_COLORS.get(item.tier, Color.WHITE)
	var tier_name = _get_tier_name(item.tier)

	_item_name_label.text = item.name
	_item_name_label.add_theme_color_override("font_color", tier_color)

	var desc = "[color=%s][%s][/color]\n" % [tier_color.to_html(), tier_name]
	desc += "%s\n\n" % item.get("desc", "")

	if item.has("quantity") and item.quantity > 1:
		desc += "[b]数量:[/b] %d\n" % item.quantity
	if item.has("slot"):
		desc += "[b]部位:[/b] %s\n" % item.slot
	if item.has("stats"):
		desc += "[b]属性:[/b]\n"
		for stat in item.stats:
			desc += "  %s: +%d\n" % [stat, item.stats[stat]]
	if item.has("effects"):
		desc += "[b]效果:[/b]\n"
		for effect in item.effects:
			desc += "  %s: %s\n" % [effect, item.effects[effect]]
	desc += "[b]出售价格:[/b] %d 灵石" % item.get("price", 0)

	_item_desc_label.text = desc

	# 更新按钮可见性
	_use_btn.visible = (item.type == ItemType.CONSUMABLE)
	_equip_btn.visible = (item.type == ItemType.EQUIPMENT)
	_sell_btn.visible = (item.type != ItemType.QUEST_ITEM)
	_dismantle_btn.visible = (item.type == ItemType.EQUIPMENT or item.type == ItemType.MATERIAL)


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
	var filtered = _get_filtered_items()
	if _selected_item_index < 0 or _selected_item_index >= filtered.size():
		return

	var item = filtered[_selected_item_index]
	inventory_item_used.emit(item.id)
	print("[Inventory] 使用物品: %s" % item.name)

	# 减少数量或移除
	_decrement_item(item)
	_refresh_inventory()


## 装备物品
func _on_equip_item() -> void:
	var filtered = _get_filtered_items()
	if _selected_item_index < 0 or _selected_item_index >= filtered.size():
		return

	var item = filtered[_selected_item_index]
	var slot = item.get("slot", "")
	inventory_item_equipped.emit(item.id, slot)
	print("[Inventory] 装备物品: %s (部位: %s)" % [item.name, slot])

	# 从背包移除（已装备）
	_remove_item(item)
	_refresh_inventory()


## 出售物品
func _on_sell_item() -> void:
	var filtered = _get_filtered_items()
	if _selected_item_index < 0 or _selected_item_index >= filtered.size():
		return

	var item = filtered[_selected_item_index]
	var price = item.get("price", 0)
	inventory_item_sold.emit(item.id, price)
	print("[Inventory] 出售物品: %s (价格: %d)" % [item.name, price])

	_remove_item(item)
	_refresh_inventory()


## 拆解物品
func _on_dismantle_item() -> void:
	var filtered = _get_filtered_items()
	if _selected_item_index < 0 or _selected_item_index >= filtered.size():
		return

	var item = filtered[_selected_item_index]
	var materials: Dictionary = {}

	# 根据品阶返回材料
	match item.tier:
		"common":
			materials = {"铁锭": 2}
		"rare":
			materials = {"精钢": 2, "灵石": 1}
		"epic":
			materials = {"玄铁": 3, "灵石": 3}
		"legendary":
			materials = {"天外陨铁": 2, "灵石": 5}

	inventory_item_dismantled.emit(item.id, materials)
	print("[Inventory] 拆解物品: %s (获得: %s)" % [item.name, materials])

	_remove_item(item)
	_refresh_inventory()


## 批量出售
func _on_bulk_sell() -> void:
	# TODO: 弹出确认对话框，选择要出售的物品
	print("[Inventory] 批量出售功能")


## 批量拆解
func _on_bulk_dismantle() -> void:
	# TODO: 弹出确认对话框，选择要拆解的物品
	print("[Inventory] 批量拆解功能")


## 整理背包
func _on_sort_backpack() -> void:
	# 按类型+品阶排序
	_inventory_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.type != b.type:
			return a.type < b.type
		var tier_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
		return tier_order.get(a.tier, 0) < tier_order.get(b.tier, 0)
	)
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
	# 更新按钮状态
	_filter_all_btn.button_pressed = (filter_type == "all")
	_filter_equip_btn.button_pressed = (filter_type == "equipment")
	_filter_consumable_btn.button_pressed = (filter_type == "consumable")
	_filter_material_btn.button_pressed = (filter_type == "material")
	_refresh_inventory()


## 排序选项变化
func _on_sort_changed(index: int) -> void:
	match index:
		0: # 按名称
			_inventory_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.name < b.name
			)
		1: # 按品阶
			var tier_order = {"common": 0, "uncommon": 1, "rare": 2, "epic": 3, "legendary": 4}
			_inventory_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return tier_order.get(a.tier, 0) > tier_order.get(b.tier, 0)
			)
		2: # 按数量
			_inventory_items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a.get("quantity", 1) > b.get("quantity", 1)
			)
	_refresh_inventory()


## 减少物品数量
func _decrement_item(item: Dictionary) -> void:
	for i in range(_inventory_items.size()):
		if _inventory_items[i].id == item.id:
			if _inventory_items[i].quantity > 1:
				_inventory_items[i].quantity -= 1
			else:
				_inventory_items.remove_at(i)
			break


## 移除物品
func _remove_item(item: Dictionary) -> void:
	for i in range(_inventory_items.size()):
		if _inventory_items[i].id == item.id:
			_inventory_items.remove_at(i)
			break


## 获取品阶名称
func _get_tier_name(tier: String) -> String:
	match tier:
		"common": return "普通"
		"uncommon": return "优秀"
		"rare": return "稀有"
		"epic": return "史诗"
		"legendary": return "传说"
		_: return "未知"


## 填充货币Tab
func _populate_currency_tab() -> void:
	# TODO: 从 EconomyManager 读取真实数据
	_spirit_stone_label.text = "灵石: 500"
	_gold_label.text = "金币: 0"
	_silver_label.text = "银币: 0"
	_copper_label.text = "铜币: 120"
	_contribution_label.text = "贡献点: 0"
	_sect_points_label.text = "宗门贡献: 0"


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
