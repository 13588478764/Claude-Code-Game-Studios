## 暂停菜单管理器
## 负责控制暂停菜单的打开/关闭、游戏暂停状态、ESC键处理
## Z-index层级：暂停菜单=260，奇遇面板=300，对话框=500

extends Node

## 当游戏暂停时发出
signal game_paused
## 当游戏恢复时发出
signal game_resumed

## 暂停菜单场景路径
const PAUSE_MENU_SCENE: String = "res://src/scenes/ui/pause_menu.tscn"

## 暂停菜单实例
var _pause_menu: Node = null
## 是否已暂停
var _is_paused: bool = false
## 当前区域名
var _current_area: String = ""
## 游戏内时间
var _game_time: String = ""


func _ready() -> void:
	# 暂停菜单不需要在_ready中创建，按需创建
	pass


## 打开暂停菜单
func open_pause_menu(area_name: String = "", game_time_str: String = "") -> void:
	if _pause_menu != null and _is_paused:
		return

	if _pause_menu == null:
		var scene = load(PAUSE_MENU_SCENE)
		if scene == null:
			push_error("Failed to load pause menu scene: %s" % PAUSE_MENU_SCENE)
			return
		_pause_menu = scene.instantiate()
		# 连接到暂停菜单信号
		_pause_menu.pause_menu_closed_continue.connect(_on_pause_menu_closed)
		_pause_menu.pause_menu_quit_confirmed.connect(_on_pause_menu_quit_confirmed)
		_pause_menu.pause_menu_return_to_main.connect(_on_pause_menu_return_to_main)
		get_tree().root.add_child(_pause_menu)

	_current_area = area_name
	_game_time = game_time_str
	_is_paused = true

	# 暂停游戏进程
	get_tree().paused = true

	# 打开菜单
	_pause_menu.open_menu(area_name, game_time_str)
	game_paused.emit()


## 关闭暂停菜单
func close_pause_menu() -> void:
	if _pause_menu == null:
		return

	_is_paused = false
	_pause_menu.close_menu()

	# 恢复游戏进程
	get_tree().paused = false
	game_resumed.emit()


## 检查是否有存档
func _check_has_save() -> bool:
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys and save_sys.has_method("has_save"):
		for slot in range(1, save_sys.MAX_SLOTS + 1):
			if save_sys.has_save(slot):
				return true
	return false


## 更新存档状态
func update_save_status() -> void:
	if _pause_menu != null:
		var has_save = _check_has_save()
		_pause_menu.update_save_status(has_save)


## 信号回调：暂停菜单关闭
func _on_pause_menu_closed() -> void:
	close_pause_menu()


## 信号回调：确认退出
func _on_pause_menu_quit_confirmed(_saved: bool) -> void:
	get_tree().quit()


## 信号回调：返回主菜单
func _on_pause_menu_return_to_main(_saved: bool) -> void:
	var main_menu_path = "res://src/scenes/main_menu.tscn"
	if ResourceLoader.exists(main_menu_path):
		get_tree().change_scene_to_file(main_menu_path)
	else:
		push_warning("Main menu scene not found at %s" % main_menu_path)
		close_pause_menu()
