## test_settings_panel_load.gd
## S2-06 设置面板场景加载测试

extends GutTest

func test_settings_panel_scene_loads():
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	assert_not_null(scene, "设置面板场景应该可以加载")

func test_settings_panel_instantiates():
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "设置面板场景应该可以实例化")
	instance.queue_free()

func test_settings_panel_root_type():
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	var instance = scene.instantiate()
	assert_true(instance is Control, "设置面板根节点应该是Control")
	instance.queue_free()

func test_settings_panel_script_exists():
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	var instance = scene.instantiate()
	var script_path = instance.get_script()
	assert_not_null(script_path, "场景应该有脚本附加")
	instance.queue_free()

func test_settings_panel_has_tabs():
	var scene = load("res://src/scenes/ui/settings_panel.tscn")
	var instance = scene.instantiate()
	var tab_bar = instance.get_node_or_null("MainPanel/VBox/TabBar")
	assert_not_null(tab_bar, "设置面板应该有TabBar")
	instance.queue_free()
