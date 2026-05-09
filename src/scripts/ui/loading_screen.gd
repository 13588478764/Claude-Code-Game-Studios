## 加载界面控制器
## 对应 UX Spec: design/ux/loading-screen.md
## Z-index = 600 (最高层，在Dialog Overlay 500之上)

extends CanvasLayer

## 加载开始时发出
signal loading_started(load_type: String, save_slot_id: int)
## 加载进度更新
signal loading_progress(progress_percent: float, current_stage: String)
## 加载完成
signal loading_completed(load_time_ms: int)
## 加载失败
signal loading_failed(error_reason: String, load_type: String)
## 加载取消
signal loading_cancelled(load_type: String, progress_at_cancel: float)

## 场景引用
@onready var _background: ColorRect = $Background
@onready var _status_label: Label = $"FullContainer/VBox/ProgressContainer/StatusLabel"
@onready var _progress_bar: ProgressBar = $"FullContainer/VBox/ProgressBar"
@onready var _tip_panel: PanelContainer = $"FullContainer/VBox/TipPanel"
@onready var _tip_label: Label = $"FullContainer/VBox/TipPanel/TipVBox/TipLabel"
@onready var _cancel_btn: Button = $"FullContainer/VBox/CancelButton"
@onready var _error_container: Control = $ErrorContainer
@onready var _error_desc: Label = $ErrorContainer/ErrorPanel/ErrorVBox/ErrorDesc
@onready var _retry_btn: Button = $ErrorContainer/ErrorPanel/ErrorVBox/ErrorHBox/RetryButton
@onready var _return_btn: Button = $ErrorContainer/ErrorPanel/ErrorVBox/ErrorHBox/ReturnButton
@onready var _version_label: Label = $VersionLabel

## 提示文本列表（5条）
const TIPS: Array[String] = [
	"五行相克：金克木，木克土，土克水，水克火，火克金。利用相克关系可获得战斗优势。",
	"按C键打开角色面板，查看属性、境界和天赋。升级后可分配属性点和天赋点。",
	"按I键打开背包，管理物品、使用消耗品和出售多余装备。新获得的物品会标记'NEW'角标。",
	"福缘属性影响奇遇触发概率和稀有掉落率。提升福缘可获得更多仙缘机缘。",
	"境界突破后所有属性增加10%。确保满足突破条件（等级、突破丹、心境试炼）后再尝试。",
]

## 加载状态文字
const STAGE_TEXTS: Array[String] = [
	"初始化资源...",
	"加载世界...",
	"加载修士数据...",
	"修炼界面准备中...",
	"准备就绪...",
]

## 加载类型
enum LoadType { STARTUP, SAVE_LOAD, SCENE_TRANSITION, RETURN_TO_MENU }

## 当前加载类型
var _load_type: LoadType = LoadType.STARTUP
## 存档槽ID
var _save_slot_id: int = -1
## 是否可取消
var _can_cancel: bool = false
## 开始时间
var _start_time: float = 0.0
## 当前提示索引
var _current_tip_index: int = 0
## 提示定时器
var _tip_timer: Timer = null
## 减少运动设置
var _reduce_motion: bool = false


func _ready() -> void:
	visible = false
	_background.modulate = Color(1, 1, 1, 0)
	_error_container.visible = false

	# 连接错误按钮
	_retry_btn.pressed.connect(_on_retry_pressed)
	_return_btn.pressed.connect(_on_return_pressed)
	_cancel_btn.pressed.connect(_on_cancel_pressed)

	# 版本号
	var version = "v%s" % ProjectSettings.get_setting("application/config/version", "1.0.0")
	_version_label.text = version

	# 读取减少运动设置
	_reduce_motion = _load_reduce_motion_setting()


## 开始加载（完整界面）
func start_loading(
	load_type: LoadType = LoadType.STARTUP,
	save_slot_id: int = -1,
	allow_cancel: bool = false
) -> void:
	_load_type = load_type
	_save_slot_id = save_slot_id
	_can_cancel = allow_cancel and load_type != LoadType.STARTUP
	_start_time = Time.get_ticks_msec()

	visible = true
	_error_container.visible = false
	_progress_bar.value = 0.0

	# 淡入背景
	$"FullContainer/VBox".modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_background, "modulate", Color(1, 1, 1, 1), 0.15)
	tween.parallel().tween_property($"FullContainer/VBox", "modulate", Color(1, 1, 1, 1), 0.2)

	# 显示取消按钮
	_cancel_btn.visible = _can_cancel

	# 显示提示面板（非启动加载时不显示）
	if load_type == LoadType.STARTUP:
		_tip_panel.visible = true
		_start_tip_rotation()
	else:
		_tip_panel.visible = false

	loading_started.emit(_load_type_to_string(load_type), save_slot_id)


## 更新加载进度 (0.0 - 1.0)
func update_progress(progress: float, stage_index: int = 0) -> void:
	_progress_bar.value = progress * 100.0
	if stage_index >= 0 and stage_index < STAGE_TEXTS.size():
		_status_label.text = STAGE_TEXTS[stage_index]

	loading_progress.emit(progress * 100.0, STAGE_TEXTS[stage_index])


## 加载完成
func finish_loading() -> void:
	_progress_bar.value = 100.0
	_status_label.text = "准备就绪..."
	loading_progress.emit(100.0, "准备就绪...")

	var elapsed = Time.get_ticks_msec() - _start_time

	# 满格停留0.3秒
	await get_tree().create_timer(0.3).timeout

	# 淡出
	var tween = create_tween()
	tween.tween_property(_background, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: visible = false)

	loading_completed.emit(int(elapsed))


## 加载失败
func show_error(error_message: String) -> void:
	_error_container.visible = true
	_error_desc.text = error_message
	$"FullContainer/VBox".visible = false
	_tip_panel.visible = false
	_cancel_btn.visible = false

	loading_failed.emit(error_message, _load_type_to_string(_load_type))


## 开始提示轮换
func _start_tip_rotation() -> void:
	_show_current_tip()

	_tip_timer = Timer.new()
	_tip_timer.wait_time = 5.0
	_tip_timer.timeout.connect(_on_tip_timer_timeout)
	add_child(_tip_timer)
	_tip_timer.start()


## 显示当前提示
func _show_current_tip() -> void:
	_tip_label.text = TIPS[_current_tip_index % TIPS.size()]


## 提示定时器超时
func _on_tip_timer_timeout() -> void:
	if not _reduce_motion:
		# 淡出旧提示
		var tween = create_tween()
		tween.tween_property(_tip_label, "modulate", Color(1, 1, 1, 0), 0.15)
		await tween.finished

	_current_tip_index += 1
	_show_current_tip()

	if not _reduce_motion:
		# 淡入新提示
		_tip_label.modulate = Color(1, 1, 1, 0)
		var tween = create_tween()
		tween.tween_property(_tip_label, "modulate", Color(1, 1, 1, 1), 0.15)


func _input(event: InputEvent) -> void:
	if not visible or _error_container.visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and _can_cancel:
			_on_cancel_pressed()
			get_viewport().set_input_as_handled()


## 取消加载
func _on_cancel_pressed() -> void:
	var progress = _progress_bar.value / 100.0
	loading_cancelled.emit(_load_type_to_string(_load_type), progress)

	# 淡出
	var tween = create_tween()
	tween.tween_property(_background, "modulate", Color(1, 1, 1, 0), 0.2)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: visible = false)


## 重试加载
func _on_retry_pressed() -> void:
	_error_container.visible = false
	$"FullContainer/VBox".visible = true

	if _load_type == LoadType.STARTUP:
		_tip_panel.visible = true
		_start_tip_rotation()

	# TODO: 重新开始加载流程
	start_loading(_load_type, _save_slot_id, _can_cancel)


## 返回主菜单
func _on_return_pressed() -> void:
	# TODO: 加载主菜单场景
	var main_menu_path = "res://src/scenes/main_menu.tscn"
	if ResourceLoader.exists(main_menu_path):
		get_tree().change_scene_to_file(main_menu_path)


## 清理定时器
func _exit_tree() -> void:
	if _tip_timer != null:
		_tip_timer.queue_free()


## 转换加载类型为字符串
func _load_type_to_string(load_type: LoadType) -> String:
	match load_type:
		LoadType.STARTUP: return "startup"
		LoadType.SAVE_LOAD: return "save_load"
		LoadType.SCENE_TRANSITION: return "scene_transition"
		LoadType.RETURN_TO_MENU: return "return_to_menu"
	return "unknown"


## 读取减少运动设置
func _load_reduce_motion_setting() -> bool:
	var config_path = "user://settings.json"
	if not FileAccess.file_exists(config_path):
		return false
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return false
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null:
		return false
	return json.get("reduce_motion", false)
