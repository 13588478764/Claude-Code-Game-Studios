## test_world_map_load.gd
## S2-02 大地图场景加载测试

extends GutTest

func test_world_map_scene_loads():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	assert_not_null(scene, "大地图场景应该可以加载")

func test_world_map_instantiates():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "大地图场景应该可以实例化")
	instance.queue_free()

func test_world_map_root_type():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "大地图根节点应该是CanvasLayer")
	instance.queue_free()

func test_world_map_script_exists():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance.script, "大地图应该有脚本附加")
	instance.queue_free()

func test_world_map_z_index():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.z_index, 220, "大地图Z-index应该是220")
	instance.queue_free()

func test_world_map_has_tabs():
	var scene = load("res://src/scenes/ui/world_map.tscn")
	var instance = scene.instantiate()
	var tab_bar = instance.get_node_or_null("MainPanel/VBox/HeaderHBox/TabBar")
	assert_not_null(tab_bar, "大地图应该有TabBar")
	instance.queue_free()
