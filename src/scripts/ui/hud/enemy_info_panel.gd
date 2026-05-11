extends Control
## 敌人信息显示面板
## 显示选中敌人的名称、等级、HP条、五行弱点图标、状态标识
## 遵循ADR-002 (HUD架构模式) 和 ADR-003 (数据绑定机制)

# 节点引用 (@onready缓存)
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_level_label: Label = %EnemyLevelLabel
@onready var hp_bar: ProgressBar = %HPBar
@onready var hp_label: Label = %HPLabel
@onready var weakness_container: HBoxContainer = %WeaknessContainer
@onready var down_indicator: Control = %DownIndicator
@onready var break_indicator: Control = %BreakIndicator
@onready var boss_border: Panel = %BossBorder
@onready var no_target_label: Label = %NoTargetLabel
@onready var fade_animation: AnimationPlayer = %FadeAnimation

# 脏标记 (ADR-002: 避免不必要的更新)
var _dirty_name: bool = false
var _dirty_hp: bool = false
var _dirty_weakness: bool = false
var _dirty_status: bool = false

# 当前选中敌人数据
var _current_enemy_id: String = ""
var _current_enemy_data: Dictionary = {}
var _weakness_icons: Dictionary = {}  # enemy_id -> Array[WeaknessIconDisplay]

# 五行弱点图标场景
var weakness_icon_scene = preload("res://src/scenes/ui/hud/weakness_icon.tscn")

# 颜色常量
const COLOR_GOLD = Color("#FFD700")
const COLOR_NORMAL = Color.WHITE

# 动画时长
const FADE_DURATION = 0.2
const HIGHLIGHT_DURATION = 0.3

func _ready() -> void:
	# 检测 UI 是否完整加载（单元测试 / 脚本测试模式下 unique-name 节点都不存在）。
	# 这种情况下跳过 UI 初始化，但仍然允许信号连接（让脚本逻辑可被独立测试）。
	if not _is_ui_initialized():
		_connect_game_events_safely()
		return
	
	# 初始化UI状态
	_update_no_target_display()
	
	# 连接GameEvents信号
	_connect_game_events_safely()


## 检测脚本依赖的 UI 节点是否都已就位
## 当通过 .tscn 完整加载时返回 true；通过 script.new() 直接实例化时返回 false。
func _is_ui_initialized() -> bool:
	return no_target_label != null and enemy_name_label != null

## 安全连接 GameEvents 信号（避免重复连接 / autoload 不可用时崩溃）
func _connect_game_events_safely() -> void:
	if not is_instance_valid(GameEvents):
		return
	if not GameEvents.enemy_selected.is_connected(_on_enemy_selected):
		GameEvents.enemy_selected.connect(_on_enemy_selected)
	if not GameEvents.enemy_hp_changed.is_connected(_on_enemy_hp_changed):
		GameEvents.enemy_hp_changed.connect(_on_enemy_hp_changed)
	if not GameEvents.enemy_weakness_revealed.is_connected(_on_enemy_weakness_revealed):
		GameEvents.enemy_weakness_revealed.connect(_on_enemy_weakness_revealed)
	if GameEvents.has_signal("enemy_status_changed") \
			and not GameEvents.enemy_status_changed.is_connected(_on_enemy_status_changed):
		GameEvents.enemy_status_changed.connect(_on_enemy_status_changed)

func _process(_delta: float) -> void:
	# 处理脏标记更新 (ADR-002: 脏标记优化)
	if _dirty_name:
		_update_name_display()
		_dirty_name = false
	
	if _dirty_hp:
		_update_hp_display()
		_dirty_hp = false
	
	if _dirty_weakness:
		_update_weakness_display()
		_dirty_weakness = false
	
	if _dirty_status:
		_update_status_display()
		_dirty_status = false

## 敌人被选中时的处理
func _on_enemy_selected(enemy_data: Dictionary) -> void:
	# 如果是同一个敌人，不重复处理
	if _current_enemy_id == enemy_data.get("id", ""):
		return
	
	# 保存新的敌人数据
	_current_enemy_id = enemy_data.get("id", "")
	_current_enemy_data = enemy_data.duplicate()
	
	# 清除旧的弱点图标
	if _weakness_icons.has(_current_enemy_id):
		for icon in _weakness_icons[_current_enemy_id]:
			icon.queue_free()
		_weakness_icons.erase(_current_enemy_id)
	
	# 播放淡入淡出过渡动画 (AC-8: 0.2秒淡入淡出)
	_play_fade_transition()
	
	# 标记所有内容为脏，需要更新
	_dirty_name = true
	_dirty_hp = true
	_dirty_weakness = true
	_dirty_status = true

## 敌人HP变化时的处理
func _on_enemy_hp_changed(enemy_id: String, current_hp: int, max_hp: int) -> void:
	if enemy_id != _current_enemy_id:
		return
	
	_current_enemy_data["current_hp"] = current_hp
	_current_enemy_data["max_hp"] = max_hp
	_dirty_hp = true

## 敌人弱点被发现时的处理
func _on_enemy_weakness_revealed(enemy_id: String, element: String) -> void:
	if enemy_id != _current_enemy_id:
		return
	
	# 更新敌人数据中的已发现弱点
	if not _current_enemy_data.has("discovered_weaknesses"):
		_current_enemy_data["discovered_weaknesses"] = []
	
	if element not in _current_enemy_data["discovered_weaknesses"]:
		_current_enemy_data["discovered_weaknesses"].append(element)
	
	_dirty_weakness = true

## 敌人状态变化时的处理
func _on_enemy_status_changed(enemy_id: String, status: String) -> void:
	if enemy_id != _current_enemy_id:
		return
	
	_current_enemy_data["status"] = status
	_dirty_status = true

## 更新敌人名称和等级显示
func _update_name_display() -> void:
	if _current_enemy_id.is_empty():
		_update_no_target_display()
		return
	
	var name_text = _current_enemy_data.get("name", "未知敌人")
	var level = _current_enemy_data.get("level", 1)
	
	enemy_name_label.text = name_text
	enemy_level_label.text = "Lv.%d" % level
	
	# 显示敌人信息面板，隐藏"未选中目标"提示
	no_target_label.visible = false
	enemy_name_label.visible = true
	enemy_level_label.visible = true
	hp_bar.visible = true
	hp_label.visible = true
	weakness_container.visible = true

## 更新HP条显示 (AC-2: 280x20px)
func _update_hp_display() -> void:
	if _current_enemy_id.is_empty():
		return
	
	var current_hp = _current_enemy_data.get("current_hp", 0)
	var max_hp = _current_enemy_data.get("max_hp", 1)
	
	# 更新进度条
	hp_bar.max_value = float(max_hp)
	hp_bar.value = float(current_hp)
	
	# 更新HP标签
	hp_label.text = "%d/%d" % [current_hp, max_hp]

## 更新弱点图标显示 (AC-3, AC-4: 五行弱点图标)
func _update_weakness_display() -> void:
	if _current_enemy_id.is_empty():
		return
	
	# 清除旧的弱点图标
	for child in weakness_container.get_children():
		child.queue_free()
	
	_weakness_icons[_current_enemy_id] = []
	
	var weaknesses = _current_enemy_data.get("weaknesses", [])
	var discovered_weaknesses = _current_enemy_data.get("discovered_weaknesses", [])
	
	# 创建五行弱点图标 (金/木/水/火/土)
	for element in weaknesses:
		var icon = weakness_icon_scene.instantiate()
		weakness_container.add_child(icon)
		
		# 设置元素类型
		icon.set_element(element)
		
		# 如果已发现，高亮显示并播放动画
		if element in discovered_weaknesses:
			icon.highlight()
			icon.play_reveal_animation(HIGHLIGHT_DURATION)
		
		_weakness_icons[_current_enemy_id].append(icon)

## 更新状态标识显示 (AC-5, AC-6: Down/Break状态)
func _update_status_display() -> void:
	if _current_enemy_id.is_empty():
		down_indicator.visible = false
		break_indicator.visible = false
		boss_border.visible = false
		return
	
	var status = _current_enemy_data.get("status", "")
	var is_boss = _current_enemy_data.get("is_boss", false)
	
	# 显示Down状态标识
	down_indicator.visible = (status == "down")
	
	# 显示Break状态标识
	break_indicator.visible = (status == "break")
	
	# 显示Boss边框 (AC-12: Boss敌人特殊边框)
	boss_border.visible = is_boss

## 更新"未选中目标"显示 (AC-7)
func _update_no_target_display() -> void:
	no_target_label.visible = true
	enemy_name_label.visible = false
	enemy_level_label.visible = false
	hp_bar.visible = false
	hp_label.visible = false
	weakness_container.visible = false
	down_indicator.visible = false
	break_indicator.visible = false
	boss_border.visible = false

## 播放淡入淡出过渡动画 (AC-8: 0.2秒淡入淡出)
func _play_fade_transition() -> void:
	# 淡出当前内容
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION / 2.0)
	
	# 淡入新内容
	tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION / 2.0)