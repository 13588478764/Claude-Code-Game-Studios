extends PanelContainer
class_name PlayerStatusPanel

## 角色状态显示面板
##
## 显示主角的核心状态信息(P0级):
## - HP/Qi/Poise条形图和数值
## - 等级和经验
## - 境界图标和名称
##
## 使用信号驱动更新 + 脏标记优化,确保UI更新响应时间<16.67ms(60FPS)

# ============================================================================
# 节点引用 - 使用@onready缓存
# ============================================================================

## HP条形图
@onready var hp_bar: ProgressBar = $VBox/HPContainer/HPBar
## HP数值标签
@onready var hp_label: Label = $VBox/HPContainer/HPBar/Label

## Qi条形图
@onready var qi_bar: ProgressBar = $VBox/QiContainer/QiBar
## Qi数值标签
@onready var qi_label: Label = $VBox/QiContainer/QiBar/Label

## Poise条形图
@onready var poise_bar: ProgressBar = $VBox/PoiseContainer/PoiseBar
## Poise数值标签
@onready var poise_label: Label = $VBox/PoiseContainer/PoiseBar/Label

## 等级标签
@onready var level_label: Label = $VBox/InfoContainer/LevelLabel
## 经验条形图
@onready var exp_bar: ProgressBar = $VBox/InfoContainer/ExpBar
## 经验数值标签
@onready var exp_label: Label = $VBox/InfoContainer/ExpBar/Label

## 境界图标
@onready var realm_icon: TextureRect = $VBox/RealmContainer/RealmIcon
## 境界名称标签
@onready var realm_label: Label = $VBox/RealmContainer/RealmLabel

# ============================================================================
# 脏标记和缓存值
# ============================================================================

## HP缓存值
var _cached_hp: int = 0
var _cached_hp_max: int = 1
var _hp_dirty: bool = false

## Qi缓存值
var _cached_qi: int = 0
var _cached_qi_max: int = 1
var _qi_dirty: bool = false

## Poise缓存值
var _cached_poise: int = 0
var _cached_poise_max: int = 1
var _poise_dirty: bool = false

## 等级缓存值
var _cached_level: int = 1
var _level_dirty: bool = false

## 经验缓存值
var _cached_exp: int = 0
var _cached_exp_to_next: int = 100
var _exp_dirty: bool = false

## 境界缓存值
var _cached_realm: String = ""
var _realm_dirty: bool = false

# ============================================================================
# Poise闪烁相关
# ============================================================================

## Poise闪烁Tween
var _poise_blink_tween: Tween = null
## Poise是否正在闪烁
var _poise_is_blinking: bool = false

# ============================================================================
# 颜色常量
# ============================================================================

const COLOR_HP_NORMAL: Color = Color("#2E8B57")  # 绿色 >60%
const COLOR_HP_WARNING: Color = Color.YELLOW      # 黄色 30-60%
const COLOR_HP_CRITICAL: Color = Color("#DC143C") # 深红色 <30%

# ============================================================================
# 初始化
# ============================================================================

func _ready() -> void:
	_connect_signals()
	_initialize_ui()

## 连接GameEvents信号
func _connect_signals() -> void:
	if GameEvents:
		GameEvents.player_hp_changed.connect(_on_hp_changed)
		GameEvents.player_qi_changed.connect(_on_qi_changed)
		GameEvents.player_poise_changed.connect(_on_poise_changed)
		GameEvents.player_level_up.connect(_on_level_up)
		GameEvents.player_exp_changed.connect(_on_exp_changed)
		GameEvents.player_realm_changed.connect(_on_realm_changed)
	else:
		push_error("PlayerStatusPanel: GameEvents autoload not found!")

## 初始化UI默认状态
func _initialize_ui() -> void:
	# 设置初始值
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_label.text = "100 / 100"
	
	qi_bar.max_value = 100
	qi_bar.value = 100
	qi_label.text = "100 / 100"
	
	poise_bar.max_value = 100
	poise_bar.value = 100
	poise_label.text = "100 / 100"
	
	level_label.text = "Lv.1"
	
	exp_bar.max_value = 100
	exp_bar.value = 0
	exp_label.text = "0 / 100"
	
	realm_label.text = "炼气"
	_load_realm_icon("炼气")

# ============================================================================
# 更新逻辑 - 脏标记检查
# ============================================================================

func _process(_delta: float) -> void:
	# 检查脏标记并应用更新
	if _hp_dirty:
		_apply_hp_update()
		_hp_dirty = false
	
	if _qi_dirty:
		_apply_qi_update()
		_qi_dirty = false
	
	if _poise_dirty:
		_apply_poise_update()
		_poise_dirty = false
	
	if _level_dirty:
		_apply_level_update()
		_level_dirty = false
	
	if _exp_dirty:
		_apply_exp_update()
		_exp_dirty = false
	
	if _realm_dirty:
		_apply_realm_update()
		_realm_dirty = false

# ============================================================================
# 信号处理函数
# ============================================================================

## HP变化信号处理
func _on_hp_changed(current: int, max_value: int) -> void:
	if _cached_hp != current or _cached_hp_max != max_value:
		_cached_hp = current
		_cached_hp_max = max_value
		_hp_dirty = true

## Qi变化信号处理
func _on_qi_changed(current: int, max_value: int) -> void:
	if _cached_qi != current or _cached_qi_max != max_value:
		_cached_qi = current
		_cached_qi_max = max_value
		_qi_dirty = true

## Poise变化信号处理
func _on_poise_changed(current: int, max_value: int) -> void:
	if _cached_poise != current or _cached_poise_max != max_value:
		_cached_poise = current
		_cached_poise_max = max_value
		_poise_dirty = true

## 升级信号处理
func _on_level_up(new_level: int, _old_level: int) -> void:
	if _cached_level != new_level:
		_cached_level = new_level
		_level_dirty = true

## 经验变化信号处理
func _on_exp_changed(current: int, to_next: int) -> void:
	if _cached_exp != current or _cached_exp_to_next != to_next:
		_cached_exp = current
		_cached_exp_to_next = to_next
		_exp_dirty = true

## 境界变化信号处理
func _on_realm_changed(new_realm: String, _old_realm: String) -> void:
	if _cached_realm != new_realm:
		_cached_realm = new_realm
		_realm_dirty = true

# ============================================================================
# UI更新应用函数
# ============================================================================

## 应用HP更新
func _apply_hp_update() -> void:
	hp_bar.max_value = _cached_hp_max
	hp_bar.value = _cached_hp
	hp_label.text = _format_stat_display(_cached_hp, _cached_hp_max)
	
	# 临界状态颜色
	var percentage := float(_cached_hp) / float(_cached_hp_max) if _cached_hp_max > 0 else 0.0
	if percentage < 0.3:
		hp_bar.modulate = COLOR_HP_CRITICAL
	elif percentage < 0.6:
		hp_bar.modulate = COLOR_HP_WARNING
	else:
		hp_bar.modulate = COLOR_HP_NORMAL

## 应用Qi更新
func _apply_qi_update() -> void:
	qi_bar.max_value = _cached_qi_max
	qi_bar.value = _cached_qi
	qi_label.text = _format_stat_display(_cached_qi, _cached_qi_max)

## 应用Poise更新
func _apply_poise_update() -> void:
	poise_bar.max_value = _cached_poise_max
	poise_bar.value = _cached_poise
	poise_label.text = _format_stat_display(_cached_poise, _cached_poise_max)
	
	# Poise<20%时闪烁
	var percentage := float(_cached_poise) / float(_cached_poise_max) if _cached_poise_max > 0 else 0.0
	if percentage < 0.2:
		if not _poise_is_blinking:
			_start_poise_blink()
	else:
		if _poise_is_blinking:
			_stop_poise_blink()

## 应用等级更新
func _apply_level_update() -> void:
	level_label.text = "Lv.%d" % _cached_level

## 应用经验更新
func _apply_exp_update() -> void:
	exp_bar.max_value = _cached_exp_to_next
	exp_bar.value = _cached_exp
	exp_label.text = _format_stat_display(_cached_exp, _cached_exp_to_next)

## 应用境界更新
func _apply_realm_update() -> void:
	realm_label.text = _cached_realm
	# 尝试加载境界图标
	_load_realm_icon(_cached_realm)

# ============================================================================
# Poise闪烁控制
# ============================================================================

## 开始Poise闪烁 (2Hz频率 = 0.5秒周期)
func _start_poise_blink() -> void:
	_poise_is_blinking = true
	
	# 停止之前的Tween
	if _poise_blink_tween:
		_poise_blink_tween.kill()
	
	# 创建新的Tween
	_poise_blink_tween = create_tween()
	_poise_blink_tween.set_loops()
	
	# 0.25秒淡出到0.3透明度,0.25秒淡入到1.0透明度 = 0.5秒周期 = 2Hz
	_poise_blink_tween.tween_property(poise_bar, "modulate:a", 0.3, 0.25)
	_poise_blink_tween.tween_property(poise_bar, "modulate:a", 1.0, 0.25)

## 停止Poise闪烁
func _stop_poise_blink() -> void:
	_poise_is_blinking = false
	
	if _poise_blink_tween:
		_poise_blink_tween.kill()
		_poise_blink_tween = null
	
	# 恢复正常透明度
	poise_bar.modulate.a = 1.0

# ============================================================================
# 辅助函数
# ============================================================================

## 格式化数值显示
## 小于10000: "1234 / 5000"
## 大于等于10000: "12.5K / 15K"
func _format_stat_display(current: int, max_value: int) -> String:
	var current_str := _format_number(current)
	var max_str := _format_number(max_value)
	return "%s / %s" % [current_str, max_str]

## 格式化单个数值
func _format_number(value: int) -> String:
	if value < 10000:
		return str(value)
	else:
		# 转换为K单位,保留一位小数
		var k_value := float(value) / 1000.0
		return "%.1fK" % k_value

## 加载境界图标
## 兼容多种境界名格式: "炼气" (character_system) / "炼气期" / "真仙境" (level_up_manager)
## / "炼气期(早期)" (历史遗留) — 统一去后缀和括号后查表
func _load_realm_icon(realm_name: String) -> void:
	# 境界裸名 → 文件名 (与 src/scripts/character/character_system.gd REALMS 对齐)
	const REALM_NAME_TO_FILE := {
		"炼气": "qi_refining",
		"筑基": "foundation",
		"金丹": "golden_core",
		"元婴": "nascent_soul",
		"化神": "spirit_transformation",
		"返虚": "void_reverting",
		"合道": "dao_unity",
		"大乘": "great_vehicle",
		"渡劫": "heavenly_tribulation",
		"真仙": "true_immortal"
	}

	# 规范化: 去掉 "(早期)" / "(后期)" 等括号注解, 再去掉 "期"/"境" 后缀
	var key := realm_name
	var paren_pos := key.find("(")
	if paren_pos != -1:
		key = key.substr(0, paren_pos)
	if key.ends_with("期") or key.ends_with("境"):
		key = key.substr(0, key.length() - 1)

	if not REALM_NAME_TO_FILE.has(key):
		push_warning("PlayerStatusPanel: Unknown realm name: %s (normalized: %s)" % [realm_name, key])
		_use_placeholder_icon()
		return

	var icon_path := "res://assets/ui/realm_icons/%s.png" % REALM_NAME_TO_FILE[key]
	if not ResourceLoader.exists(icon_path):
		push_warning("PlayerStatusPanel: Realm icon not found: %s" % icon_path)
		_use_placeholder_icon()
		return

	var texture := load(icon_path) as Texture2D
	if texture == null:
		push_warning("PlayerStatusPanel: Failed to load realm icon: %s" % icon_path)
		_use_placeholder_icon()
		return

	realm_icon.texture = texture

## 使用占位符图标(简单的ColorRect)
func _use_placeholder_icon() -> void:
	# 创建一个简单的占位符纹理
	# 注意: 这里简化处理,实际应该使用PlaceholderTexture2D或ColorRect
	realm_icon.texture = null

# ============================================================================
# 清理
# ============================================================================

func _exit_tree() -> void:
	# 停止Poise闪烁
	if _poise_blink_tween:
		_poise_blink_tween.kill()
		_poise_blink_tween = null
	
	# 断开信号连接(Godot会自动处理,但显式断开更安全)
	if GameEvents:
		if GameEvents.player_hp_changed.is_connected(_on_hp_changed):
			GameEvents.player_hp_changed.disconnect(_on_hp_changed)
		if GameEvents.player_qi_changed.is_connected(_on_qi_changed):
			GameEvents.player_qi_changed.disconnect(_on_qi_changed)
		if GameEvents.player_poise_changed.is_connected(_on_poise_changed):
			GameEvents.player_poise_changed.disconnect(_on_poise_changed)
		if GameEvents.player_level_up.is_connected(_on_level_up):
			GameEvents.player_level_up.disconnect(_on_level_up)
		if GameEvents.player_exp_changed.is_connected(_on_exp_changed):
			GameEvents.player_exp_changed.disconnect(_on_exp_changed)
		if GameEvents.player_realm_changed.is_connected(_on_realm_changed):
			GameEvents.player_realm_changed.disconnect(_on_realm_changed)