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
@onready var _reset_defaults_btn: Button = $MainPanel/VBox/TabContent/ControlTab/ControlVBox/ResetDefaultsButton

const CONFIG_PATH: String = "user://settings.cfg"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

enum ColorblindMode { OFF, RED_GREEN, BLUE_YELLOW }

var _has_unapplied_changes: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_populate_resolution_options()
	_populate_quality_options()
	_populate_colorblind_options()

	_close_btn.pressed.connect(close_settings)
	_tab_bar.tab_changed.connect(_on_tab_changed)
	_apply_btn.pressed.connect(apply_settings)
	_reset_all_btn.pressed.connect(_reset_all_settings)
	_preview_btn.pressed.connect(_preview_graphics)
	_reset_defaults_btn.pressed.connect(_reset_keybinds)

	_master_volume.value_changed.connect(_on_master_volume_changed)
	_music_volume.value_changed.connect(_on_music_volume_changed)
	_sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	_voice_volume.value_changed.connect(_on_voice_volume_changed)
	_ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	_reduce_motion_check.toggled.connect(_on_reduce_motion_changed)

	_load_settings()


func open_settings() -> void:
	visible = true
	_tab_bar.current_tab = 0
	_close_btn.grab_focus()
	settings_opened.emit()


func close_settings() -> void:
	visible = false
	settings_closed.emit()


## 从 ConfigFile 加载设置
func _load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		_load_defaults()
		_apply_audio_to_buses()
		return

	_resolution_option.selected = config.get_value("graphics", "resolution_index", 0)
	_quality_option.selected = config.get_value("graphics", "quality_index", 1)
	_fullscreen_check.button_pressed = config.get_value("graphics", "fullscreen", false)
	_reduce_motion_check.button_pressed = config.get_value("graphics", "reduce_motion", false)

	_master_volume.value = config.get_value("audio", "master_volume", 80.0)
	_music_volume.value = config.get_value("audio", "music_volume", 70.0)
	_sfx_volume.value = config.get_value("audio", "sfx_volume", 80.0)
	_voice_volume.value = config.get_value("audio", "voice_volume", 90.0)

	_ui_scale_slider.value = config.get_value("accessibility", "ui_scale", 1.0)
	_ui_scale_label.text = "UI缩放: %d%%" % int(_ui_scale_slider.value * 100)
	_colorblind_option.selected = config.get_value("accessibility", "colorblind_mode", 0)
	_screen_reader_check.button_pressed = config.get_value("accessibility", "screen_reader", false)

	_apply_audio_to_buses()
	_apply_graphics()


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


## 应用设置（保存到磁盘 + 应用画面）
func apply_settings() -> void:
	_save_to_config()
	_apply_graphics()
	_has_unapplied_changes = false
	settings_applied.emit()


## 保存到 ConfigFile
func _save_to_config() -> void:
	var config := ConfigFile.new()

	config.set_value("graphics", "resolution_index", _resolution_option.selected)
	config.set_value("graphics", "quality_index", _quality_option.selected)
	config.set_value("graphics", "fullscreen", _fullscreen_check.button_pressed)
	config.set_value("graphics", "reduce_motion", _reduce_motion_check.button_pressed)

	config.set_value("audio", "master_volume", _master_volume.value)
	config.set_value("audio", "music_volume", _music_volume.value)
	config.set_value("audio", "sfx_volume", _sfx_volume.value)
	config.set_value("audio", "voice_volume", _voice_volume.value)

	config.set_value("accessibility", "ui_scale", _ui_scale_slider.value)
	config.set_value("accessibility", "colorblind_mode", _colorblind_option.selected)
	config.set_value("accessibility", "screen_reader", _screen_reader_check.button_pressed)

	config.save(CONFIG_PATH)


## 将音量应用到 AudioServer 总线
func _apply_audio_to_buses() -> void:
	_set_bus_volume("Master", _master_volume.value)
	_set_bus_volume("Music", _music_volume.value)
	_set_bus_volume("SFX", _sfx_volume.value)
	_set_bus_volume("Voice", _voice_volume.value)


## 设置指定总线音量（0-100 线性值）
func _set_bus_volume(bus_name: String, linear_percent: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return

	var linear: float = linear_percent / 100.0
	if linear <= 0.0:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))


## 应用画面设置
func _apply_graphics() -> void:
	if _fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res_index: int = _resolution_option.selected
		if res_index >= 0 and res_index < RESOLUTIONS.size():
			DisplayServer.window_set_size(RESOLUTIONS[res_index])


func _reset_all_settings() -> void:
	_load_defaults()
	_apply_audio_to_buses()
	_has_unapplied_changes = true
	settings_reset_to_defaults.emit()


func _reset_keybinds() -> void:
	pass


func _preview_graphics() -> void:
	_apply_graphics()


func _on_tab_changed(tab_index: int) -> void:
	var tabs: Array[Control] = [
		$"MainPanel/VBox/TabContent/GraphicsTab",
		$"MainPanel/VBox/TabContent/SoundTab",
		$"MainPanel/VBox/TabContent/ControlTab",
		$"MainPanel/VBox/TabContent/AccessibilityTab",
	]
	for i in range(tabs.size()):
		if tabs[i] != null:
			tabs[i].visible = (i == tab_index)


func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume("Master", value)
	_has_unapplied_changes = true


func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume("Music", value)
	_has_unapplied_changes = true


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume("SFX", value)
	_has_unapplied_changes = true


func _on_voice_volume_changed(value: float) -> void:
	_set_bus_volume("Voice", value)
	_has_unapplied_changes = true


func _on_ui_scale_changed(value: float) -> void:
	_ui_scale_label.text = "UI缩放: %d%%" % int(value * 100)
	_has_unapplied_changes = true


func _on_reduce_motion_changed(_enabled: bool) -> void:
	_has_unapplied_changes = true


func _populate_resolution_options() -> void:
	for res in RESOLUTIONS:
		_resolution_option.add_item("%dx%d" % [res.x, res.y])


func _populate_quality_options() -> void:
	_quality_option.add_item("低")
	_quality_option.add_item("中")
	_quality_option.add_item("高")
	_quality_option.add_item("极高")


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
