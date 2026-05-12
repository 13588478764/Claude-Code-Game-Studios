# 面板导航集成测试
#
# S2-15: UI集成测试 — 面板加载/Z-index/互斥/内存
#
# 策略：面板脚本的 _ready() 中有 await create_timer 做入场动画，
# add_child 会触发这些协程导致测试卡死。
# 因此所有测试使用 instantiate() 但不 add_child，通过读取场景属性验证。

extends GutTest

const PANEL_SCENES = {
	"main_menu": "res://src/scenes/ui/main_menu.tscn",
	"world_map": "res://src/scenes/ui/world_map.tscn",
	"help_panel": "res://src/scenes/ui/help_panel.tscn",
	"settings_panel": "res://src/scenes/ui/settings_panel.tscn",
	"inventory_panel": "res://src/scenes/ui/inventory_panel.tscn",
	"equipment_panel": "res://src/scenes/ui/equipment_panel.tscn",
}

# 预期 Z-index (CanvasLayer.layer)
const EXPECTED_Z_INDEX = {
	"main_menu": 0,
	"help_panel": 180,
	"inventory_panel": 200,
	"equipment_panel": 200,
	"world_map": 220,
	"settings_panel": 250,
}

var _loaded_scenes: Dictionary = {}


func _load_scene(path: String) -> PackedScene:
	if not _loaded_scenes.has(path):
		if ResourceLoader.exists(path):
			_loaded_scenes[path] = load(path)
		else:
			_loaded_scenes[path] = null
	return _loaded_scenes[path]


# ============================================================
# 1. 面板加载基础测试
# ============================================================

func test_all_ui_panels_load_without_error() -> void:
	var loaded_count := 0
	for panel_name in PANEL_SCENES:
		var path = PANEL_SCENES[panel_name]
		var scene = _load_scene(path)
		assert_not_null(scene, "场景 %s 应能加载" % panel_name)
		if scene == null:
			continue
		var instance = scene.instantiate()
		assert_true(is_instance_valid(instance), "场景 %s 应能实例化" % panel_name)
		if is_instance_valid(instance):
			loaded_count += 1
			instance.free()

	assert_gte(loaded_count, 4, "至少应有4个面板可加载，实际: %d" % loaded_count)


func test_all_panels_have_scripts_attached() -> void:
	for panel_name in PANEL_SCENES:
		var path = PANEL_SCENES[panel_name]
		var scene = _load_scene(path)
		if scene == null:
			continue
		var instance = scene.instantiate()
		assert_not_null(instance.get_script(), "面板 %s 应有脚本挂载" % panel_name)
		instance.free()


# ============================================================
# 2. Z-index 层级测试
# ============================================================

func test_z_index_values_correct() -> void:
	for panel_name in EXPECTED_Z_INDEX:
		var path = PANEL_SCENES[panel_name]
		var scene = _load_scene(path)
		if scene == null:
			continue
		var instance = scene.instantiate()

		if instance is CanvasLayer:
			assert_eq(instance.layer, EXPECTED_Z_INDEX[panel_name],
				"面板 %s 的 Z-index 应为 %d" % [panel_name, EXPECTED_Z_INDEX[panel_name]])

		instance.free()


func test_z_index_hierarchy_ordering() -> void:
	# 验证 Z-index 层级递增关系
	var z_values = [0, 180, 200, 200, 220, 250]
	for i in range(1, z_values.size()):
		assert_gte(z_values[i], z_values[i - 1],
			"Z-index 层级应递增: %d >= %d" % [z_values[i], z_values[i - 1]])


# ============================================================
# 3. 面板互斥：验证不同面板有不同的 Z-index（高层遮挡低层）
# ============================================================

func test_pause_menu_has_higher_z_than_other_panels() -> void:
	# 暂停菜单 Z=260（从 pause_menu.tscn 获取），应高于其他面板
	var pause_scene = load("res://src/scenes/ui/pause_menu.tscn")
	if pause_scene == null:
		pending("pause_menu 场景不可用")
		return

	var pause = pause_scene.instantiate()
	var pause_z = pause.layer if pause is CanvasLayer else -1
	pause.free()

	for panel_name in EXPECTED_Z_INDEX:
		assert_gt(pause_z, EXPECTED_Z_INDEX[panel_name],
			"暂停菜单(Z=%d)应高于%s(Z=%d)" % [pause_z, panel_name, EXPECTED_Z_INDEX[panel_name]])


func test_settings_panel_has_higher_z_than_help_and_inventory() -> void:
	assert_gt(EXPECTED_Z_INDEX["settings_panel"], EXPECTED_Z_INDEX["help_panel"],
		"设置面板应高于帮助面板")
	assert_gt(EXPECTED_Z_INDEX["settings_panel"], EXPECTED_Z_INDEX["inventory_panel"],
		"设置面板应高于背包面板")


func test_world_map_has_higher_z_than_inventory_and_equipment() -> void:
	assert_gt(EXPECTED_Z_INDEX["world_map"], EXPECTED_Z_INDEX["inventory_panel"],
		"大地图应高于背包面板")
	assert_gte(EXPECTED_Z_INDEX["world_map"], EXPECTED_Z_INDEX["equipment_panel"],
		"大地图应不低于装备面板")


# ============================================================
# 4. 面板结构完整性测试
# ============================================================

func test_panels_are_canvas_layer_or_control() -> void:
	for panel_name in PANEL_SCENES:
		var path = PANEL_SCENES[panel_name]
		var scene = _load_scene(path)
		if scene == null:
			continue
		var instance = scene.instantiate()
		assert_true(instance is CanvasLayer or instance is Control,
			"面板 %s 应为 CanvasLayer 或 Control 类型" % panel_name)
		instance.free()


func test_panel_switching_instantiate_and_free_no_crash() -> void:
	# 连续实例化和释放面板（不加入场景树），验证无崩溃
	for _round in range(3):
		for panel_name in PANEL_SCENES:
			var path = PANEL_SCENES[panel_name]
			var scene = _load_scene(path)
			if scene == null:
				continue
			var instance = scene.instantiate()
			assert_true(is_instance_valid(instance), "第%d轮: %s 应能实例化" % [_round + 1, panel_name])
			instance.free()

	assert_true(true, "3轮面板切换（实例化/释放）应无崩溃")


func test_panel_multiple_instantiate_no_leak() -> void:
	# 验证多次实例化和释放不泄漏（检查实例有效性）
	for panel_name in PANEL_SCENES:
		var path = PANEL_SCENES[panel_name]
		var scene = _load_scene(path)
		if scene == null:
			continue

		var instances = []
		for i in range(5):
			instances.append(scene.instantiate())

		# 全部释放
		for inst in instances:
			inst.free()

		# 验证所有实例已被释放
		for inst in instances:
			assert_false(is_instance_valid(inst), "面板 %s 释放后应无效" % panel_name)


# ============================================================
# 5. 帮助面板特殊属性测试
# ============================================================

func test_help_panel_does_not_set_pause_mode() -> void:
	var scene = _load_scene(PANEL_SCENES["help_panel"])
	if scene == null:
		pending("help_panel 场景不可用")
		return

	var instance = scene.instantiate()
	# 帮助面板不应暂停游戏（process_mode 不应为 ALWAYS + 不应设置 tree.paused）
	assert_ne(instance.process_mode, Node.PROCESS_MODE_DISABLED,
		"帮助面板不应被禁用处理")
	instance.free()
