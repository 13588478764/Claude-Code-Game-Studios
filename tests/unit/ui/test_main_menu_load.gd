## test_main_menu_load.gd
## S2-05 主菜单场景加载测试

extends GutTest

func test_main_menu_scene_loads():
	var scene = load("res://src/scenes/ui/main_menu.tscn")
	assert_not_null(scene, "主菜单场景应该可以加载")

func test_main_menu_instantiates():
	var scene = load("res://src/scenes/ui/main_menu.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "主菜单场景应该可以实例化")
	instance.queue_free()

func test_main_menu_root_type():
	var scene = load("res://src/scenes/ui/main_menu.tscn")
	var instance = scene.instantiate()
	assert_true(instance is Control, "主菜单根节点应该是Control")
	instance.queue_free()

func test_main_menu_script_exists():
	var scene = load("res://src/scenes/ui/main_menu.tscn")
	var instance = scene.instantiate()
	var script_path = instance.get_script()
	assert_not_null(script_path, "场景应该有脚本附加")
	instance.queue_free()

func test_main_menu_has_buttons():
	var scene = load("res://src/scenes/ui/main_menu.tscn")
	var instance = scene.instantiate()
	var buttons = [
		"ZoneB_Menu/NewGameButton",
		"ZoneB_Menu/ContinueButton",
		"ZoneB_Menu/SettingsButton",
		"ZoneB_Menu/QuitButton",
	]
	for btn_path in buttons:
		var btn = instance.get_node_or_null(btn_path)
		assert_not_null(btn, "主菜单应该有按钮: %s" % btn_path)
	instance.queue_free()
