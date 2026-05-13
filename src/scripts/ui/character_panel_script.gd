## 角色面板控制器
## 负责角色属性显示、属性点分配、战斗属性查看
## 数据来源: CharacterSystem Autoload

extends Node

class_name CharacterPanelScript

## 属性中文名映射
const ATTR_NAMES: Dictionary = {
	"strength": "力道",
	"agility": "身法",
	"constitution": "根骨",
	"intelligence": "悟性",
	"willpower": "定力",
	"luck": "福缘",
}

## 属性列表（保持固定顺序）
const ATTR_LIST: Array = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]

# UI节点引用
var _panel: Control = null
var _level_value: Label = null
var _realm_value: Label = null
var _attr_points_value: Label = null
var _exp_value: Label = null
var _attr_value_labels: Dictionary = {}
var _attr_add_buttons: Dictionary = {}
var _close_button: Button = null
var _reset_button: Button = null
var _apply_button: Button = null

# 临时属性增量（未应用前的暂存）
var _pending_additions: Dictionary = {
	"strength": 0,
	"agility": 0,
	"constitution": 0,
	"intelligence": 0,
	"willpower": 0,
	"luck": 0,
}
var _pending_points_used: int = 0


func _ready() -> void:
	_panel = get_parent()
	if _panel == null:
		push_warning("[CharacterPanel] 无法获取父节点")
		return

	_cache_node_references()
	_connect_buttons()

	# 面板显示时刷新数据
	_panel.visibility_changed.connect(_on_visibility_changed)


func _cache_node_references() -> void:
	_level_value = _panel.get_node_or_null("Background/LevelInfo/LevelValue")
	_realm_value = _panel.get_node_or_null("Background/LevelInfo/RealmValue")
	_attr_points_value = _panel.get_node_or_null("Background/AttributePointsRow/AttributePointsValue")
	_close_button = _panel.get_node_or_null("Background/CloseButton")
	_reset_button = _panel.get_node_or_null("Background/ResetButton")
	_apply_button = _panel.get_node_or_null("Background/ApplyButton")

	# 属性行引用
	var attr_panel = _panel.get_node_or_null("Background/AttributesPanel")
	if attr_panel == null:
		return

	var row_names: Dictionary = {
		"strength": "StrengthRow",
		"agility": "AgilityRow",
		"constitution": "ConstitutionRow",
		"intelligence": "IntelligenceRow",
		"willpower": "WillpowerRow",
		"luck": "LuckRow",
	}

	for attr_key in ATTR_LIST:
		var row_name: String = row_names[attr_key]
		var row = attr_panel.get_node_or_null(row_name)
		if row == null:
			continue
		var capitalized: String = attr_key.capitalize().replace(" ", "")
		_attr_value_labels[attr_key] = row.get_node_or_null("%sValue" % capitalized)
		_attr_add_buttons[attr_key] = row.get_node_or_null("%sAddButton" % capitalized)


func _connect_buttons() -> void:
	if _close_button:
		_close_button.pressed.connect(_on_close_pressed)
	if _reset_button:
		_reset_button.pressed.connect(_on_reset_pressed)
	if _apply_button:
		_apply_button.pressed.connect(_on_apply_pressed)

	# 属性加点按钮
	for attr_key in ATTR_LIST:
		var btn: Button = _attr_add_buttons.get(attr_key)
		if btn:
			btn.pressed.connect(_on_attr_add_pressed.bind(attr_key))


func _input(event: InputEvent) -> void:
	if _panel == null or not _panel.visible:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


## 面板可见性变化时刷新
func _on_visibility_changed() -> void:
	if _panel.visible:
		_reset_pending()
		_refresh_from_system()


## 从 CharacterSystem 读取真实数据并刷新UI
func _refresh_from_system() -> void:
	var cs = get_node_or_null("/root/CharacterSystem")
	if cs == null:
		push_warning("[CharacterPanel] CharacterSystem 未找到")
		return

	# 等级和境界
	if _level_value:
		_level_value.text = str(cs.level)
	if _realm_value:
		var realm_info: Dictionary = cs.get_current_realm()
		_realm_value.text = realm_info.get("name", "未知")

	# 可用属性点
	var available_points: int = cs.total_attribute_points - cs.allocated_attribute_points
	if _attr_points_value:
		_attr_points_value.text = str(available_points)

	# 六维属性（基础值）
	var attrs: Dictionary = cs.attributes.get_total()
	for attr_key in ATTR_LIST:
		var label: Label = _attr_value_labels.get(attr_key)
		if label:
			label.text = str(attrs.get(attr_key, 0))

	_update_add_button_states(available_points)


## 更新加点按钮可用状态
func _update_add_button_states(available_points: int) -> void:
	var remaining: int = available_points - _pending_points_used
	for attr_key in ATTR_LIST:
		var btn: Button = _attr_add_buttons.get(attr_key)
		if btn:
			btn.disabled = remaining <= 0


## 属性加点按钮回调
func _on_attr_add_pressed(attr_key: String) -> void:
	var cs = get_node_or_null("/root/CharacterSystem")
	if cs == null:
		return

	var available: int = cs.total_attribute_points - cs.allocated_attribute_points - _pending_points_used
	if available <= 0:
		return

	_pending_additions[attr_key] += 1
	_pending_points_used += 1

	# 更新显示（基础值+待分配增量）
	var base_value: int = 0
	match attr_key:
		"strength": base_value = cs.attributes.strength
		"agility": base_value = cs.attributes.agility
		"constitution": base_value = cs.attributes.constitution
		"intelligence": base_value = cs.attributes.intelligence
		"willpower": base_value = cs.attributes.willpower
		"luck": base_value = cs.attributes.luck

	var label: Label = _attr_value_labels.get(attr_key)
	if label:
		var new_val: int = base_value + _pending_additions[attr_key]
		label.text = str(new_val)

	# 更新剩余点数
	var remaining: int = cs.total_attribute_points - cs.allocated_attribute_points - _pending_points_used
	if _attr_points_value:
		_attr_points_value.text = str(remaining)

	_update_add_button_states(cs.total_attribute_points - cs.allocated_attribute_points)


## 应用按钮回调 — 将待分配的点数真正写入 CharacterSystem
func _on_apply_pressed() -> void:
	var cs = get_node_or_null("/root/CharacterSystem")
	if cs == null:
		return

	if _pending_points_used == 0:
		return

	for attr_key in ATTR_LIST:
		var points: int = _pending_additions[attr_key]
		if points > 0:
			cs.allocate_attribute_points(attr_key, points)

	print("[CharacterPanel] 已分配 %d 点属性" % _pending_points_used)
	_reset_pending()
	_refresh_from_system()


## 重置按钮回调 — 撤销未应用的加点
func _on_reset_pressed() -> void:
	_reset_pending()
	_refresh_from_system()


## 关闭按钮回调
func _on_close_pressed() -> void:
	_close_panel()


## 关闭面板（撤销未应用的更改）
func _close_panel() -> void:
	_reset_pending()
	if _panel:
		_panel.visible = false


## 清空待分配状态
func _reset_pending() -> void:
	for attr_key in ATTR_LIST:
		_pending_additions[attr_key] = 0
	_pending_points_used = 0
