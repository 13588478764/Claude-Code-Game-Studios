extends Control
class_name HotbarController

## 快捷栏系统 - Story 008
## 实现8个槽位的快捷栏，支持物品拖拽、快捷键绑定、冷却时间显示

const HOTBAR_SLOT_COUNT = 8
const SLOT_SIZE = Vector2(64, 64)
const SLOT_SPACING = 10

# 快捷栏槽位数据结构
class HotbarSlotData:
	var item_id: String = ""
	var quantity: int = 0
	var cooldown_remaining: float = 0.0
	var cooldown_total: float = 0.0
	
	func _init(p_item_id: String = "", p_quantity: int = 0) -> void:
		item_id = p_item_id
		quantity = p_quantity

# 快捷栏槽位UI引用
var _slots: Array[HotbarSlot] = []
var _slot_data: Array[HotbarSlotData] = []

# 拖拽状态
var _dragging_from_slot: int = -1
var _drag_preview: Control = null

# 冷却时间更新
var _cooldown_timer: Timer

@onready var slot_container: HBoxContainer = $SlotContainer

func _ready() -> void:
	_initialize_slots()
	_setup_cooldown_timer()
	_connect_signals()

func _initialize_slots() -> void:
	# 创建8个槽位
	for i in range(HOTBAR_SLOT_COUNT):
		var slot = HotbarSlot.new()
		slot.slot_index = i
		slot.custom_minimum_size = SLOT_SIZE
		slot_container.add_child(slot)
		_slots.append(slot)
		_slot_data.append(HotbarSlotData.new())
		
		# 连接槽位信号
		slot.slot_pressed.connect(_on_slot_pressed.bindv([i]))
		slot.slot_drag_started.connect(_on_slot_drag_started.bindv([i]))

func _setup_cooldown_timer() -> void:
	_cooldown_timer = Timer.new()
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
	_cooldown_timer.wait_time = 0.016  # ~60FPS更新

func _connect_signals() -> void:
	# 监听物品系统信号
	GameEvents.item_hotbar_changed.connect(_on_item_hotbar_changed)
	GameEvents.item_used.connect(_on_item_used)
	GameEvents.item_quantity_changed.connect(_on_item_quantity_changed)

## AC-1: 8个槽位正确显示(64x64px)
## AC-2: 物品图标正确显示
## AC-3: 物品数量正确显示(右下角)
func add_item_to_slot(slot_index: int, item_id: String, quantity: int) -> bool:
	if slot_index < 0 or slot_index >= HOTBAR_SLOT_COUNT:
		return false
	
	# AC-9: 只有消耗品类型的物品可放入快捷栏
	if not _is_consumable_item(item_id):
		return false
	
	_slot_data[slot_index].item_id = item_id
	_slot_data[slot_index].quantity = quantity
	_update_slot_display(slot_index)
	return true

## AC-4: 数字键1-8正确绑定到对应槽位
func _process(_delta: float) -> void:
	# 处理数字键1-8快捷键
	for i in range(HOTBAR_SLOT_COUNT):
		var action_name = "hotbar_%d" % (i + 1)
		if Input.is_action_just_pressed(action_name):
			_use_item_in_slot(i)

## AC-5: 使用物品后数量正确减少
## AC-6: 物品用完后槽位清空
func _use_item_in_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= HOTBAR_SLOT_COUNT:
		return
	
	var slot_data = _slot_data[slot_index]
	if slot_data.item_id.is_empty() or slot_data.quantity <= 0:
		return
	
	# 检查冷却时间
	if slot_data.cooldown_remaining > 0:
		return
	
	# 使用物品
	GameEvents.item_used.emit(slot_data.item_id, 1)
	
	# 数量减少
	slot_data.quantity -= 1
	
	# AC-10: 物品使用后有冷却时间显示(圆形进度条)
	slot_data.cooldown_remaining = _get_item_cooldown(slot_data.item_id)
	slot_data.cooldown_total = slot_data.cooldown_remaining
	
	# 如果数量为0，清空槽位
	if slot_data.quantity <= 0:
		slot_data.item_id = ""
		slot_data.quantity = 0
	
	_update_slot_display(slot_index)
	
	# 启动冷却时间更新
	if not _cooldown_timer.is_stopped():
		_cooldown_timer.start()

## AC-7: 支持从背包拖拽物品到快捷栏槽位
## AC-8: 支持在快捷栏内拖拽物品交换位置
func _on_slot_drag_started(slot_index: int) -> void:
	_dragging_from_slot = slot_index
	# TODO: 实现拖拽预览

func _on_slot_pressed(slot_index: int) -> void:
	# 如果正在拖拽，交换物品
	if _dragging_from_slot >= 0 and _dragging_from_slot != slot_index:
		_swap_items(_dragging_from_slot, slot_index)
		_dragging_from_slot = -1
	else:
		# 否则使用物品
		_use_item_in_slot(slot_index)

func _swap_items(from_index: int, to_index: int) -> void:
	var temp = _slot_data[from_index]
	_slot_data[from_index] = _slot_data[to_index]
	_slot_data[to_index] = temp
	
	_update_slot_display(from_index)
	_update_slot_display(to_index)

## AC-12: 物品数量与物品系统实时同步
func _on_item_quantity_changed(item_id: String, new_quantity: int) -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		if _slot_data[i].item_id == item_id:
			_slot_data[i].quantity = new_quantity
			if new_quantity <= 0:
				_slot_data[i].item_id = ""
			_update_slot_display(i)

## AC-11: 快捷栏配置在游戏退出后保存,重新进入时恢复
func save_hotbar_config() -> Dictionary:
	var config = {}
	for i in range(HOTBAR_SLOT_COUNT):
		config[str(i)] = {
			"item_id": _slot_data[i].item_id,
			"quantity": _slot_data[i].quantity
		}
	return config

func load_hotbar_config(config: Dictionary) -> void:
	for i in range(HOTBAR_SLOT_COUNT):
		if config.has(str(i)):
			var slot_config = config[str(i)]
			_slot_data[i].item_id = slot_config.get("item_id", "")
			_slot_data[i].quantity = slot_config.get("quantity", 0)
			_update_slot_display(i)

func _update_slot_display(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	
	var slot = _slots[slot_index]
	var data = _slot_data[slot_index]
	
	slot.set_item(data.item_id, data.quantity)
	slot.set_cooldown(data.cooldown_remaining, data.cooldown_total)

func _on_cooldown_timer_timeout() -> void:
	var has_active_cooldown = false
	
	for i in range(HOTBAR_SLOT_COUNT):
		if _slot_data[i].cooldown_remaining > 0:
			_slot_data[i].cooldown_remaining -= _cooldown_timer.wait_time
			if _slot_data[i].cooldown_remaining < 0:
				_slot_data[i].cooldown_remaining = 0
			_update_slot_display(i)
			has_active_cooldown = true
	
	if not has_active_cooldown:
		_cooldown_timer.stop()

func _on_item_hotbar_changed(slot_index: int, item_id: String, quantity: int) -> void:
	add_item_to_slot(slot_index, item_id, quantity)

func _on_item_used(item_id: String, quantity: int) -> void:
	# 更新所有包含该物品的槽位
	for i in range(HOTBAR_SLOT_COUNT):
		if _slot_data[i].item_id == item_id:
			_slot_data[i].quantity -= quantity
			if _slot_data[i].quantity <= 0:
				_slot_data[i].item_id = ""
				_slot_data[i].quantity = 0
			_update_slot_display(i)

func _is_consumable_item(item_id: String) -> bool:
	# TODO: 与物品系统集成，检查物品类型
	return true

func _get_item_cooldown(item_id: String) -> float:
	# TODO: 与物品系统集成，获取物品冷却时间
	return 5.0

## AC-13: 数字键1-8在其他UI打开时不触发快捷栏
func set_enabled(enabled: bool) -> void:
	set_process(enabled)
	for slot in _slots:
		slot.set_process_input(enabled)