## 加载游戏流程集成测试 (s6-03)
## 验证存档检测、加载、和错误处理
extends GutTest

const SaveSystemScript = preload("res://src/scripts/save/save_system.gd")

var _save_sys: Node = null


func before_each() -> void:
	_save_sys = SaveSystemScript.new()
	_save_sys.name = "SaveSystem"
	add_child_autofree(_save_sys)


func after_each() -> void:
	# 清理测试存档
	for slot in range(1, _save_sys.MAX_SLOTS + 1):
		_save_sys.delete_save(slot)


## 无存档时 has_save 返回 false
func test_has_save_returns_false_when_empty() -> void:
	for slot in range(1, _save_sys.MAX_SLOTS + 1):
		_save_sys.delete_save(slot)
	assert_false(_save_sys.has_save(1))
	assert_false(_save_sys.has_save(2))
	assert_false(_save_sys.has_save(3))


## 保存后 has_save 返回 true
func test_has_save_returns_true_after_save() -> void:
	_save_sys.save_to_slot(1)
	assert_true(_save_sys.has_save(1))


## 无效槽位加载返回 false
func test_load_invalid_slot_returns_false() -> void:
	assert_false(_save_sys.load_from_slot(0))
	assert_false(_save_sys.load_from_slot(99))


## 不存在的存档加载返回 false
func test_load_nonexistent_save_returns_false() -> void:
	_save_sys.delete_save(1)
	assert_false(_save_sys.load_from_slot(1))


## get_save_info 无存档时返回空字典
func test_get_save_info_empty_when_no_save() -> void:
	_save_sys.delete_save(1)
	var info: Dictionary = _save_sys.get_save_info(1)
	assert_eq(info.size(), 0)


## 保存/加载信号正确触发
func test_save_completed_signal() -> void:
	var signal_fired: Array = [false]
	var callback := func(_slot: int): signal_fired[0] = true
	_save_sys.save_completed.connect(callback)

	_save_sys.save_to_slot(1)
	assert_true(signal_fired[0])
