## test_inventory_panel_load.gd
## S2-07 背包面板场景加载测试

extends GutTest

func test_inventory_panel_scene_loads():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	assert_not_null(scene, "背包面板场景应该可以加载")

func test_inventory_panel_instantiates():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "背包面板场景应该可以实例化")
	instance.queue_free()

func test_inventory_panel_root_type():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "背包面板根节点应该是CanvasLayer")
	instance.queue_free()

func test_inventory_panel_script_exists():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance.script, "背包面板应该有脚本附加")
	instance.queue_free()

func test_inventory_panel_z_index():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.z_index, 200, "背包面板Z-index应该是200")
	instance.queue_free()

func test_inventory_panel_has_tabs():
	var scene = load("res://src/scenes/ui/inventory_panel.tscn")
	var instance = scene.instantiate()
	var tab_bar = instance.get_node_or_null("PanelContainer/VBox/TabBar")
	assert_not_null(tab_bar, "背包面板应该有TabBar")
	instance.queue_free()
