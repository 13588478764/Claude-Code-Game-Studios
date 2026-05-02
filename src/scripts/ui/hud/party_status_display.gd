extends PanelContainer
class_name PartyStatusDisplay

## 队友状态显示面板
## 监听GameEvents信号,实时显示最多3名队友的状态
## 支持淡入/淡出动画和HP平滑过渡

# 队友槽位容器
@onready var party_slots_container: VBoxContainer = $VBoxContainer/PartySlotsContainer

# 队友槽位预制体(动态创建)
var party_member_slot_scene: PackedScene = preload("res://src/scenes/ui/hud/party_member_slot.tscn")

# 队友数据缓存
var _party_members: Array[Dictionary] = []  # {id, name, hp, max_hp, is_downed}
var _member_slots: Dictionary = {}  # {member_id: PartyMemberSlot}
var _max_visible_members: int = 3

# 脏标记
var _party_dirty: bool = false

func _ready() -> void:
	_connect_signals()
	_initialize_empty_state()

func _connect_signals() -> void:
	## 连接GameEvents信号
	GameEvents.party_member_added.connect(_on_party_member_added)
	GameEvents.party_member_removed.connect(_on_party_member_removed)
	GameEvents.party_member_hp_changed.connect(_on_party_member_hp_changed)
	GameEvents.party_member_downed.connect(_on_party_member_downed)

func _initialize_empty_state() -> void:
	## 初始化空状态提示
	if party_slots_container.get_child_count() == 0:
		var empty_label = Label.new()
		empty_label.text = "无队友"
		empty_label.add_theme_font_size_override("font_size", 14)
		empty_label.modulate = Color.GRAY
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		party_slots_container.add_child(empty_label)
		empty_label.name = "EmptyLabel"

func _process(_delta: float) -> void:
	## 处理脏标记更新
	if _party_dirty:
		_apply_party_update()
		_party_dirty = false

# ============================================================================
# 信号处理函数
# ============================================================================

func _on_party_member_added(member_id: String, member_name: String) -> void:
	## 队友加入队伍
	var member_data = {
		"id": member_id,
		"name": member_name,
		"hp": 100,
		"max_hp": 100,
		"is_downed": false
	}
	_party_members.append(member_data)
	_party_dirty = true

func _on_party_member_removed(member_id: String) -> void:
	## 队友离开队伍
	_party_members = _party_members.filter(func(m): return m["id"] != member_id)
	_party_dirty = true

func _on_party_member_hp_changed(member_id: String, current: int, max_value: int) -> void:
	## 队友HP变化
	for member in _party_members:
		if member["id"] == member_id:
			member["hp"] = current
			member["max_hp"] = max_value
			break
	
	# 直接更新对应槽位的HP条(不使用脏标记,HP变化需要实时响应)
	if member_id in _member_slots:
		_member_slots[member_id].update_hp(current, max_value)

func _on_party_member_downed(member_id: String, is_downed: bool) -> void:
	## 队友倒地状态变化
	for member in _party_members:
		if member["id"] == member_id:
			member["is_downed"] = is_downed
			break
	
	# 直接更新对应槽位的倒地状态
	if member_id in _member_slots:
		_member_slots[member_id].set_downed_state(is_downed)

# ============================================================================
# 更新逻辑
# ============================================================================

func _apply_party_update() -> void:
	## 应用队友列表更新
	
	# 移除超出显示范围的槽位
	var visible_count = min(_party_members.size(), _max_visible_members)
	var slots_to_remove = []
	
	for member_id in _member_slots.keys():
		var member_index = _get_member_index(member_id)
		if member_index >= visible_count:
			slots_to_remove.append(member_id)
	
	# 执行移除动画
	for member_id in slots_to_remove:
		_remove_member_slot_with_animation(member_id)
	
	# 添加或更新槽位
	for i in range(visible_count):
		var member = _party_members[i]
		if member["id"] not in _member_slots:
			_add_member_slot_with_animation(member)
		else:
			# 更新现有槽位
			_member_slots[member["id"]].update_member_data(member)
	
	# 处理空状态
	if visible_count == 0:
		_show_empty_state()
	else:
		_hide_empty_state()

func _add_member_slot_with_animation(member: Dictionary) -> void:
	## 添加队友槽位并播放淡入动画
	var slot = party_member_slot_scene.instantiate()
	slot.name = "PartyMemberSlot_%s" % member["id"]
	party_slots_container.add_child(slot)
	
	# 初始化槽位数据
	slot.set_member_data(member)
	_member_slots[member["id"]] = slot
	
	# 淡入动画(0.2秒)
	var tween = create_tween()
	slot.modulate.a = 0.0
	tween.tween_property(slot, "modulate:a", 1.0, 0.2)

func _remove_member_slot_with_animation(member_id: String) -> void:
	## 移除队友槽位并播放淡出动画
	if member_id not in _member_slots:
		return
	
	var slot = _member_slots[member_id]
	var tween = create_tween()
	tween.tween_property(slot, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		slot.queue_free()
		_member_slots.erase(member_id)
	)

func _show_empty_state() -> void:
	## 显示空状态提示
	var empty_label = party_slots_container.get_node_or_null("EmptyLabel")
	if empty_label == null:
		_initialize_empty_state()
	else:
		empty_label.show()

func _hide_empty_state() -> void:
	## 隐藏空状态提示
	var empty_label = party_slots_container.get_node_or_null("EmptyLabel")
	if empty_label != null:
		empty_label.hide()

# ============================================================================
# 工具函数
# ============================================================================

func _get_member_index(member_id: String) -> int:
	## 获取队友在列表中的索引
	for i in range(_party_members.size()):
		if _party_members[i]["id"] == member_id:
			return i
	return -1