## test_pause_menu_load.gd
## S2-01 暂停菜单场景加载测试
## 验证场景可以被加载和实例化

extends GutTest

## 测试：场景文件存在且可加载
func test_pause_menu_scene_loads():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	assert_not_null(scene, "暂停菜单场景应该可以加载")

## 测试：场景实例化成功
func test_pause_menu_instantiates():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "暂停菜单场景应该可以实例化")
	instance.queue_free()

## 测试：场景有正确的根节点类型
func test_pause_menu_root_type():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "暂停菜单根节点应该是CanvasLayer")
	instance.queue_free()

## 测试：场景脚本存在
func test_pause_menu_script_exists():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance.script, "暂停菜单应该有脚本附加")
	instance.queue_free()

## 测试：Z-index正确 (260)
func test_pause_menu_z_index():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.layer, 260, "暂停菜单Z-index应该是260")
	instance.queue_free()

## 测试：场景有必要的按钮节点
func test_pause_menu_has_buttons():
	var scene = load("res://src/scenes/ui/pause_menu.tscn")
	var instance = scene.instantiate()
	var panel = instance.get_node_or_null("PanelContainer")
	assert_not_null(panel, "暂停菜单应该有PanelContainer")

	var continue_btn = panel.get_node_or_null("VBoxContainer/ContinueButton")
	var save_btn = panel.get_node_or_null("VBoxContainer/SaveButton")
	var settings_btn = panel.get_node_or_null("VBoxContainer/SettingsButton")
	var quit_btn = panel.get_node_or_null("VBoxContainer/QuitButton")

	assert_not_null(continue_btn, "应该有继续游戏按钮")
	assert_not_null(save_btn, "应该有保存按钮")
	assert_not_null(settings_btn, "应该有设置按钮")
	assert_not_null(quit_btn, "应该有退出按钮")

	instance.queue_free()
