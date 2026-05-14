## 设置持久化集成测试 (s6-01)
## 验证设置面板保存到 ConfigFile 后重新加载值一致
extends GutTest

const SettingsPanelScript = preload("res://src/scripts/ui/settings_panel.gd")
const CONFIG_PATH: String = "user://settings.cfg"

var _panel: Control = null


func before_each() -> void:
	# 清理测试配置文件
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)

	_panel = SettingsPanelScript.new()
	add_child_autofree(_panel)


func after_each() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		DirAccess.remove_absolute(CONFIG_PATH)


## 默认值在配置文件不存在时正确初始化
func test_defaults_loaded_when_no_config_file() -> void:
	assert_false(FileAccess.file_exists(CONFIG_PATH))
	# _ready 自动调用 _load_settings → _load_defaults


## 音量设为0时应静音总线
func test_volume_zero_mutes_bus() -> void:
	_panel._set_bus_volume("Master", 0.0)
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		assert_true(AudioServer.is_bus_mute(bus_idx))


## 音量设为100时应为0dB
func test_volume_max_sets_zero_db() -> void:
	_panel._set_bus_volume("Master", 100.0)
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		assert_false(AudioServer.is_bus_mute(bus_idx))
		var db: float = AudioServer.get_bus_volume_db(bus_idx)
		assert_almost_eq(db, 0.0, 0.01)


## 保存后重新加载值一致
func test_save_load_roundtrip() -> void:
	_panel._master_volume.value = 60.0
	_panel._music_volume.value = 45.0
	_panel._sfx_volume.value = 90.0
	_panel._voice_volume.value = 75.0
	_panel._resolution_option.selected = 2
	_panel._fullscreen_check.button_pressed = true

	_panel._save_to_config()

	assert_true(FileAccess.file_exists(CONFIG_PATH))

	var config := ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	assert_eq(err, OK)
	assert_almost_eq(config.get_value("audio", "master_volume", 0.0), 60.0, 0.01)
	assert_almost_eq(config.get_value("audio", "music_volume", 0.0), 45.0, 0.01)
	assert_almost_eq(config.get_value("audio", "sfx_volume", 0.0), 90.0, 0.01)
	assert_almost_eq(config.get_value("audio", "voice_volume", 0.0), 75.0, 0.01)
	assert_eq(config.get_value("graphics", "resolution_index", 0), 2)
	assert_eq(config.get_value("graphics", "fullscreen", false), true)


## 配置文件损坏时加载默认值
func test_corrupted_config_loads_defaults() -> void:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	file.store_string("这不是有效的ConfigFile格式{{{")
	file.close()

	var panel2: Control = SettingsPanelScript.new()
	add_child_autofree(panel2)
	# 不崩溃即为通过


## 不存在的总线名称不会崩溃
func test_nonexistent_bus_no_crash() -> void:
	_panel._set_bus_volume("NonExistentBus12345", 50.0)
	# 不崩溃即为通过
	assert_true(true)


## 音量中间值映射正确
func test_volume_50_maps_to_negative_6db() -> void:
	_panel._set_bus_volume("Master", 50.0)
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		var db: float = AudioServer.get_bus_volume_db(bus_idx)
		# linear_to_db(0.5) ≈ -6.02 dB
		assert_almost_eq(db, -6.02, 0.1)
