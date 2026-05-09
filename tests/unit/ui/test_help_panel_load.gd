## test_help_panel_load.gd
## S2-03 帮助面板场景加载测试

extends GutTest

func test_help_panel_scene_loads():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	assert_not_null(scene, "帮助面板场景应该可以加载")

func test_help_panel_instantiates():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "帮助面板场景应该可以实例化")
	instance.queue_free()

func test_help_panel_root_type():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "帮助面板根节点应该是CanvasLayer")
	instance.queue_free()

func test_help_panel_script_exists():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance.script, "帮助面板应该有脚本附加")
	instance.queue_free()

func test_help_panel_z_index():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.z_index, 180, "帮助面板Z-index应该是180")
	instance.queue_free()

func test_help_panel_has_tabs():
	var scene = load("res://src/scenes/ui/help_panel.tscn")
	var instance = scene.instantiate()
	var tab_bar = instance.get_node_or_null("HelpPanelContainer/VBox/TabBar")
	assert_not_null(tab_bar, "帮助面板应该有TabBar")
	instance.queue_free()
