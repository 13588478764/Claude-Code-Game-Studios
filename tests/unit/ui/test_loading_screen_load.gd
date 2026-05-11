## test_loading_screen_load.gd
## S2-04 加载界面场景加载测试

extends GutTest

func test_loading_screen_scene_loads():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	assert_not_null(scene, "加载界面场景应该可以加载")

func test_loading_screen_instantiates():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	var instance = scene.instantiate()
	assert_not_null(instance, "加载界面场景应该可以实例化")
	instance.queue_free()

func test_loading_screen_root_type():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	var instance = scene.instantiate()
	assert_true(instance is CanvasLayer, "加载界面根节点应该是CanvasLayer")
	instance.queue_free()

func test_loading_screen_script_exists():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	var instance = scene.instantiate()
	var script_path = instance.get_script()
	assert_not_null(script_path, "场景应该有脚本附加")
	instance.queue_free()

func test_loading_screen_z_index():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	var instance = scene.instantiate()
	assert_eq(instance.layer, 600, "加载界面Z-index应该是600")
	instance.queue_free()

func test_loading_screen_has_progress_bar():
	var scene = load("res://src/scenes/ui/loading_screen.tscn")
	var instance = scene.instantiate()
	var progress = instance.get_node_or_null("FullContainer/VBox/ProgressContainer/ProgressBar")
	assert_not_null(progress, "加载界面应该有进度条")
	instance.queue_free()
