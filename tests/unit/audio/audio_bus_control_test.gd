## 音频总线控制单元测试 (s6-05)
## 验证 AudioServer 总线音量控制
extends GutTest


## linear_to_db(1.0) = 0dB
func test_linear_to_db_max_is_zero() -> void:
	var db: float = linear_to_db(1.0)
	assert_almost_eq(db, 0.0, 0.01)


## linear_to_db(0.5) ≈ -6dB
func test_linear_to_db_half_is_minus_6() -> void:
	var db: float = linear_to_db(0.5)
	assert_almost_eq(db, -6.02, 0.1)


## linear_to_db(0.0) → 负无穷（Godot返回 -INF 或极低值）
func test_linear_to_db_zero_is_very_low() -> void:
	var db: float = linear_to_db(0.0)
	assert_true(db < -60.0)


## 设置音量后读取值一致
func test_set_and_get_bus_volume() -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx < 0:
		pass_test("Master总线不存在，跳过")
		return

	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(0.75))
	var db: float = AudioServer.get_bus_volume_db(bus_idx)
	assert_almost_eq(db, linear_to_db(0.75), 0.01)


## 静音/取消静音切换
func test_mute_unmute_toggle() -> void:
	var bus_idx: int = AudioServer.get_bus_index("Master")
	if bus_idx < 0:
		pass_test("Master总线不存在，跳过")
		return

	AudioServer.set_bus_mute(bus_idx, true)
	assert_true(AudioServer.is_bus_mute(bus_idx))

	AudioServer.set_bus_mute(bus_idx, false)
	assert_false(AudioServer.is_bus_mute(bus_idx))


## 负值输入 clamp 到极低 dB
func test_negative_linear_value() -> void:
	var db: float = linear_to_db(-0.5)
	assert_true(db < -60.0)


## 超过1.0的输入应映射到正dB
func test_above_one_linear_value() -> void:
	var db: float = linear_to_db(2.0)
	assert_true(db > 0.0)


## 总线名称不存在时不崩溃
func test_nonexistent_bus_returns_minus_one() -> void:
	var idx: int = AudioServer.get_bus_index("NonExistent_Bus_XYZ")
	assert_eq(idx, -1)
