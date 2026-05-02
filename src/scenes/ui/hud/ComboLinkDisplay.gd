extends PanelContainer
class_name ComboLinkDisplay

# ============================================================================
# 节点引用 - 使用@onready缓存避免_process()中的查找
# ============================================================================

@onready var combo_count_label: Label = $VBoxContainer/ComboSection/ComboCountLabel
@onready var combo_multiplier_label: Label = $VBoxContainer/ComboSection/ComboMultiplierLabel
@onready var link_gauge: ProgressBar = $VBoxContainer/LinkGaugeSection/LinkGaugeBar
@onready var link_gauge_label: Label = $VBoxContainer/LinkGaugeSection/LinkGaugeLabel
@onready var link_full_indicator: Control = $VBoxContainer/LinkGaugeSection/LinkFullIndicator

# ============================================================================
# 颜色定义 - 连击颜色阈值
# ============================================================================

const COMBO_COLOR_WHITE: Color = Color.WHITE  # 1-10
const COMBO_COLOR_GOLD: Color = Color(1.0, 0.84, 0.0, 1.0)  # #FFD700 11-30
const COMBO_COLOR_ORANGE: Color = Color(1.0, 0.65, 0.0, 1.0)  # #FFA500 31-50
const COMBO_COLOR_RED: Color = Color.RED  # 51+

# ============================================================================
# 缓存值和脏标记 - 避免重复更新
# ============================================================================

var _cached_combo_count: int = 0
var _cached_combo_multiplier: float = 1.0
var _cached_link_current: int = 0
var _cached_link_max: int = 100

var _combo_count_dirty: bool = false
var _combo_multiplier_dirty: bool = false
var _link_gauge_dirty: bool = false

# ============================================================================
# 动画控制
# ============================================================================

var _combo_tween: Tween = null
var _link_tween: Tween = null
var _link_pulse_tween: Tween = null

# ============================================================================
# 生命周期
# ============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_initialize_display()

func _process(_delta: float) -> void:
	# 脏标记检查 - 仅在需要时更新
	if _combo_count_dirty:
		_apply_combo_count_update()
		_combo_count_dirty = false
	
	if _combo_multiplier_dirty:
		_apply_combo_multiplier_update()
		_combo_multiplier_dirty = false
	
	if _link_gauge_dirty:
		_apply_link_gauge_update()
		_link_gauge_dirty = false

# ============================================================================
# 初始化
# ============================================================================

func _setup_ui() -> void:
	"""设置UI初始状态"""
	# 连击数字 - 48px字号
	combo_count_label.add_theme_font_size_override("font_size", 48)
	combo_count_label.text = "0"
	combo_count_label.modulate = COMBO_COLOR_WHITE
	
	# 连击倍率 - 20px字号
	combo_multiplier_label.add_theme_font_size_override("font_size", 20)
	combo_multiplier_label.text = "×1.0"
	combo_multiplier_label.modulate = COMBO_COLOR_WHITE
	
	# 连携槽 - 300x40px
	link_gauge.custom_minimum_size = Vector2(300, 40)
	link_gauge.max_value = 100
	link_gauge.value = 0
	
	# 连携槽标签
	link_gauge_label.text = "0 / 100"
	
	# 连携槽满指示器 - 初始隐藏
	link_full_indicator.hide()

func _connect_signals() -> void:
	"""连接GameEvents信号"""
	GameEvents.combat_combo_changed.connect(_on_combo_changed)
	GameEvents.combat_link_gauge_changed.connect(_on_link_gauge_changed)
	GameEvents.combat_ended.connect(_on_combat_ended)

func _initialize_display() -> void:
	"""初始化显示状态"""
	_cached_combo_count = 0
	_cached_combo_multiplier = 1.0
	_cached_link_current = 0
	_cached_link_max = 100
	
	combo_count_label.text = "0"
	combo_multiplier_label.text = "×1.0"
	link_gauge.value = 0
	link_gauge_label.text = "0 / 100"
	link_full_indicator.hide()

# ============================================================================
# 信号处理
# ============================================================================

func _on_combo_changed(count: int, multiplier: float) -> void:
	"""处理连击值变化信号"""
	# 检查是否需要更新
	if _cached_combo_count != count or _cached_combo_multiplier != multiplier:
		_cached_combo_count = count
		_cached_combo_multiplier = multiplier
		_combo_count_dirty = true
		_combo_multiplier_dirty = true
		
		# 如果连击中断（从非零变为零），播放抖动动画
		if count == 0 and _cached_combo_count > 0:
			_play_combo_interrupt_animation()

func _on_link_gauge_changed(current: int, max_value: int) -> void:
	"""处理连携槽变化信号"""
	if _cached_link_current != current or _cached_link_max != max_value:
		_cached_link_current = current
		_cached_link_max = max_value
		_link_gauge_dirty = true
		
		# 如果连携槽充满，播放脉冲动画
		if current >= max_value and _cached_link_current < max_value:
			_play_link_full_animation()

func _on_combat_ended(_victory: bool, _rewards: Dictionary) -> void:
	"""战斗结束时重置显示"""
	_reset_display()

# ============================================================================
# 更新应用
# ============================================================================

func _apply_combo_count_update() -> void:
	"""应用连击数字更新"""
	# 处理上限显示
	if _cached_combo_count >= 999:
		combo_count_label.text = "MAX"
	else:
		combo_count_label.text = str(_cached_combo_count)
	
	# 更新颜色
	var color = _get_combo_color(_cached_combo_count)
	combo_count_label.modulate = color

func _apply_combo_multiplier_update() -> void:
	"""应用连击倍率更新"""
	combo_multiplier_label.text = "×%.1f" % _cached_combo_multiplier
	
	# 倍率颜色跟随连击数颜色
	var color = _get_combo_color(_cached_combo_count)
	combo_multiplier_label.modulate = color

func _apply_link_gauge_update() -> void:
	"""应用连携槽更新"""
	# 更新进度条
	link_gauge.max_value = _cached_link_max
	link_gauge.value = _cached_link_current
	
	# 更新标签
	link_gauge_label.text = "%d / %d" % [_cached_link_current, _cached_link_max]
	
	# 绘制分段标记
	_draw_link_gauge_segments()

# ============================================================================
# 动画效果
# ============================================================================

func _play_combo_interrupt_animation() -> void:
	"""连击中断时的抖动动画 - 0.2秒"""
	# 取消之前的动画
	if _combo_tween:
		_combo_tween.kill()
	
	_combo_tween = create_tween()
	_combo_tween.set_trans(Tween.TRANS_ELASTIC)
	_combo_tween.set_ease(Tween.EASE_OUT)
	
	# 抖动效果 - 0.2秒
	_combo_tween.tween_property(combo_count_label, "scale", Vector2(1.2, 1.2), 0.1)
	_combo_tween.tween_property(combo_count_label, "scale", Vector2(0.8, 0.8), 0.1)
	
	# 快速归零
	await _combo_tween.finished
	combo_count_label.text = "0"
	combo_count_label.scale = Vector2.ONE
	combo_count_label.modulate = COMBO_COLOR_WHITE

func _play_combo_zero_fade_animation() -> void:
	"""连击值归零时的淡出动画 - 0.3秒"""
	if _combo_tween:
		_combo_tween.kill()
	
	_combo_tween = create_tween()
	_combo_tween.tween_property(combo_count_label, "modulate:a", 0.0, 0.3)
	
	await _combo_tween.finished
	combo_count_label.modulate = COMBO_COLOR_WHITE
	combo_count_label.modulate.a = 1.0

func _play_link_gauge_consume_animation(consume_amount: int) -> void:
	"""使用连携技能时的消耗动画 - 0.5秒"""
	if _link_tween:
		_link_tween.kill()
	
	var start_value = link_gauge.value
	var end_value = max(0, start_value - consume_amount)
	
	_link_tween = create_tween()
	_link_tween.tween_property(link_gauge, "value", end_value, 0.5)

func _play_link_full_animation() -> void:
	"""连携槽充满时的脉冲动画"""
	if _link_pulse_tween:
		_link_pulse_tween.kill()
	
	link_full_indicator.show()
	
	_link_pulse_tween = create_tween()
	_link_pulse_tween.set_loops()
	
	# 脉冲效果 - 发光闪烁
	_link_pulse_tween.tween_property(link_full_indicator, "modulate:a", 1.0, 0.3)
	_link_pulse_tween.tween_property(link_full_indicator, "modulate:a", 0.3, 0.3)

# ============================================================================
# 辅助方法
# ============================================================================

func _get_combo_color(combo_count: int) -> Color:
	"""根据连击数获取对应颜色"""
	match combo_count:
		1 to 10:
			return COMBO_COLOR_WHITE
		11 to 30:
			return COMBO_COLOR_GOLD
		31 to 50:
			return COMBO_COLOR_ORANGE
		_:
			return COMBO_COLOR_RED

func _draw_link_gauge_segments() -> void:
	"""绘制连携槽分段标记 - 33%, 66%, 100%"""
	# 注：实际实现需要在.tscn中添加分段标记节点
	# 这里仅作为占位符，具体实现在场景文件中
	pass

func _reset_display() -> void:
	"""重置显示状态"""
	# 取消所有动画
	if _combo_tween:
		_combo_tween.kill()
	if _link_tween:
		_link_tween.kill()
	if _link_pulse_tween:
		_link_pulse_tween.kill()
	
	# 重置显示
	_cached_combo_count = 0
	_cached_combo_multiplier = 1.0
	_cached_link_current = 0
	_cached_link_max = 100
	
	combo_count_label.text = "0"
	combo_count_label.modulate = COMBO_COLOR_WHITE
	combo_multiplier_label.text = "×1.0"
	combo_multiplier_label.modulate = COMBO_COLOR_WHITE
	link_gauge.value = 0
	link_gauge_label.text = "0 / 100"
	link_full_indicator.hide()