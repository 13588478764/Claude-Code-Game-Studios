## 设置面板控制器
## 对应 UX Spec: design/ux/settings.md
## Z-index = 250（在HUD之上，暂停菜单之下）

extends Control

## 设置面板打开时发出
signal settings_opened
## 设置面板关闭时发出
signal settings_closed
## 设置变更应用时发出
signal settings_applied
## 设置恢复默认时发出
signal settings_reset_to_defaults

@onready var _tab_bar: TabBar = $MainPanel/VBox/TabBar
@onready var _close_btn: Button = $MainPanel/VBox/HeaderHBox/CloseButton
@onready var _resolution_option: OptionButton = $MainPanel/VBox/TabContent/GraphicsTab/GraphicsVBox/ResolutionOptionButton
@onready var _quality_option: OptionButton = $MainPanel/VBox/TabContent/GraphicsTab/GraphicsVBox/QualityOptionButton
@onready var _fullscreen_check: CheckBox = $MainPanel/VBox/TabContent/GraphicsTab/GraphicsVBox/FullscreenCheck
@onready var _reduce_motion_check: CheckBox = $MainPanel/VBox/TabContent/GraphicsTab/GraphicsVBox/ReduceMotionCheck
@onready var _master_volume: HSlider = $MainPanel/VBox/TabContent/SoundTab/SoundVBox/MasterVolumeSlider
@onready var _music_volume: HSlider = $MainPanel/VBox/TabContent/SoundTab/SoundVBox/MusicVolumeSlider
@onready var _sfx_volume: HSlider = $MainPanel/VBox/TabContent/SoundTab/SoundVBox/SFXVolumeSlider
@onready var _voice_volume: HSlider = $MainPanel/VBox/TabContent/SoundTab/SoundVBox/VoiceVolumeSlider
@onready var _ui_scale_slider: HSlider = $MainPanel/VBox/TabContent/AccessibilityTab/AccessibilityVBox/UIScaleSlider
@onready var _ui_scale_label: Label = $MainPanel/VBox/TabContent/AccessibilityTab/AccessibilityVBox/UIScaleLabel
@onready var _colorblind_option: OptionButton = $MainPanel/VBox/TabContent/AccessibilityTab/AccessibilityVBox/ColorblindOptionButton
@onready var _screen_reader_check: CheckBox = $MainPanel/VBox/TabContent/AccessibilityTab/AccessibilityVBox/ScreenReaderCheck
@onready var _reset_all_btn: Button = $MainPanel/VBox/FooterHBox/ResetAllButton
@onready var _apply_btn: Button = $MainPanel/VBox/FooterHBox/ApplyButton
@onready var _preview_btn: Button = $MainPanel/VBox/TabContent/GraphicsTab/GraphicsVBox/PreviewButton
@onready var _reset_defaults_btn: Button = $MainPanel/VBox/TabContent/ControlVBox/ResetDefaultsButton

const CONFIG_PATH: String = "user://settings.json"

enum ColorblindMode { OFF, RED_GREEN, BLUE_YELLOW }

## 设置变更是否已应用
var _has_unapplied_changes: bool = false


func _ready() -> void:
	visible = false
	_populate_resolution_options()
	_populate_quality_options()
	_populate_colorblind_options()

	# 连接信号
	_close_btn.pressed.connect(close_settings)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_apply_btn.pressed.connect(apply_settings)
	_reset_all_btn.pressed.connect(_reset_all_settings)
	_preview_btn.pressed.connect(_preview_graphics)
	_reset_defaults_btn.pressed.connect(_reset_keybinds)

	# 音量滑块即时生效（无需应用确认）
	_master_volume.value_changed.connect(_on_master_volume_changed)
	_music_volume.value_changed.connect(_on_music_volume_changed)
	_sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	_voice_volume.value_changed.connect(_on_voice_volume_changed)

	# UI缩放即时生效
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)

	# 减少运动即时生效
	_reduce_motion_check.toggled.connect(_on_reduce_motion_changed)

	_load_settings()


## 打开设置面板
func open_settings() -> void:
	visible = true
	_tab_bar.current_tab = 0
	_close_btn.grab_focus()
	settings_opened.emit()


## 关闭设置面板
func close_settings() -> void:
	visible = false
	settings_closed.emit()


## 加载设置
func _load_settings() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		_load_defaults()
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_load_defaults()
		return

	var json = JSON.parse_string(file.get_as_text())
	file.close()

	if json == null:
		_load_defaults()
		return

	# 画面设置
	_resolution_option.selected = json.get("resolution_index", 0)
	_quality_option.selected = json.get("quality_index", 1)
	_fullscreen_check.button_pressed = json.get("fullscreen", false)
	_reduce_motion_check.button_pressed = json.get("reduce_motion", false)

	# 音量
	_master_volume.value = json.get("master_volume", 80.0)
	_music_volume.value = json.get("music_volume", 70.0)
	_sfx_volume.value = json.get("sfx_volume", 80.0)
	_voice_volume.value = json.get("voice_volume", 90.0)

	# 无障碍
	_ui_scale_slider.value = json.get("ui_scale", 1.0)
	_ui_scale_label.text = "UI缩放: %d%%" % int(_ui_scale_slider.value * 100)
	_colorblind_option.selected = json.get("colorblind_mode", 0)
	_screen_reader_check.button_pressed = json.get("screen_reader", false)


## 加载默认设置
func _load_defaults() -> void:
	_resolution_option.selected = 0
	_quality_option.selected = 1
	_fullscreen_check.button_pressed = false
	_reduce_motion_check.button_pressed = false
	_master_volume.value = 80.0
	_music_volume.value = 70.0
	_sfx_volume.value = 80.0
	_voice_volume.value = 90.0
	_ui_scale_slider.value = 1.0
	_ui_scale_label.text = "UI缩放: 100%"
	_colorblind_option.selected = 0
	_screen_reader_check.button_pressed = false


## 应用设置
func apply_settings() -> void:
	var settings = _collect_settings()
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()

	_has_unapplied_changes = false
	settings_applied.emit()


## 收集当前设置
func _collect_settings() -> Dictionary:
	return {
		"resolution_index": _resolution_option.selected,
		"quality_index": _quality_option.selected,
		"fullscreen": _fullscreen_check.button_pressed,
		"reduce_motion": _reduce_motion_check.button_pressed,
		"master_volume": _master_volume.value,
		"music_volume": _music_volume.value,
		"sfx_volume": _sfx_volume.value,
		"voice_volume": _voice_volume.value,
		"ui_scale": _ui_scale_slider.value,
		"colorblind_mode": _colorblind_option.selected,
		"screen_reader": _screen_reader_check.button_pressed,
	}


## 恢复所有设置到默认
func _reset_all_settings() -> void:
	_load_defaults()
	_has_unapplied_changes = true
	settings_reset_to_defaults.emit()


## 重置键位到默认
func _reset_keybinds() -> void:
	# TODO: 重置键位配置
	pass


## 预览画面更改
func _preview_graphics() -> void:
	# TODO: 应用分辨率/画质预览
	pass


## Tab切换
func _on_tab_changed(tab_index: int) -> void:
	var tabs = [
		$"MainPanel/VBox/TabContent/GraphicsTab",
		$"MainPanel/VBox/TabContent/SoundTab",
		$"MainPanel/VBox/TabContent/ControlTab",
		$"MainPanel/VBox/TabContent/AccessibilityTab",
	]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)


## 音量变更即时生效
func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
	_has_unapplied_changes = true


func _on_music_volume_changed(value: float) -> void:
	# TODO: 设置音乐总线音量
	_has_unapplied_changes = true


func _on_sfx_volume_changed(value: float) -> void:
	# TODO: 设置音效总线音量
	_has_unapplied_changes = true


func _on_voice_volume_changed(value: float) -> void:
	# TODO: 设置语音总线音量
	_has_unapplied_changes = true


## UI缩放即时生效
func _on_ui_scale_changed(value: float) -> void:
	_ui_scale_label.text = "UI缩放: %d%%" % int(value * 100)
	# TODO: 应用到根Control的size
	_has_unapplied_changes = true


## 减少运动即时生效
func _on_reduce_motion_changed(enabled: bool) -> void:
	# TODO: 应用到全局动画设置
	_has_unapplied_changes = true


## 填充分辨率选项
func _populate_resolution_options() -> void:
	var resolutions = [
		"1280x720",
		"1920x1080",
		"2560x1440",
		"3840x2160",
	]
	for res in resolutions:
		_resolution_option.add_item(res)


## 填充画质选项
func _populate_quality_options() -> void:
	_quality_option.add_item("低")
	_quality_option.add_item("中")
	_quality_option.add_item("高")
	_quality_option.add_item("极高")


## 填充色盲模式选项
func _populate_colorblind_options() -> void:
	_colorblind_option.add_item("关闭")
	_colorblind_option.add_item("红色盲")
	_colorblind_option.add_item("绿色盲")
	_colorblind_option.add_item("蓝黄色盲")


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				close_settings()
				get_viewport().set_input_as_handled()
