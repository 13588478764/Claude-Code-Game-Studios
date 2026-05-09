## test_equipment_panel_load.gd
## S2-08 装备面板场景加载测试

extends GutTest

func test_equipment_panel_scene_loads():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	assert_not_null(scene, "装备面板场景应该可以加载")

func test_equipment_panel_instantiates():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "装备面板场景应该可以实例化")
	instance.queue_free()

func test_equipment_panel_root_type():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "装备面板根节点应该是CanvasLayer")
	instance.queue_free()

func test_equipment_panel_script_exists():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance.script, "装备面板应该有脚本附加")
	instance.queue_free()

func test_equipment_panel_z_index():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.z_index, 200, "装备面板Z-index应该是200")
	instance.queue_free()

func test_equipment_panel_has_tabs():
	var scene = load("res://src/scenes/ui/equipment_panel.tscn")
	var instance = scene.instantiate()
	var tab_bar = instance.get_node_or_null("PanelContainer/VBox/TabBar")
	assert_not_null(tab_bar, "装备面板应该有TabBar")
	instance.queue_free()
