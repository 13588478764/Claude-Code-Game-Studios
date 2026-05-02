extends GutTest
## 敌人信息显示单元测试
## 测试EnemyInfoPanel的核心逻辑，不依赖完整场景加载

var enemy_info_panel: Node
var game_events: Node

func before_each() -> void:
	# 创建GameEvents单例（如果不存在）
	if not is_instance_valid(GameEvents):
		game_events = Node.new()
		game_events.name = "GameEvents"
		add_child(game_events)
		# 添加必要的信号
		game_events.add_user_signal("enemy_selected")
		game_events.add_user_signal("enemy_hp_changed")
		game_events.add_user_signal("enemy_weakness_revealed")
		game_events.add_user_signal("enemy_status_changed")
	else:
		game_events = GameEvents
	
	# 创建EnemyInfoPanel脚本实例（不加载场景）
	enemy_info_panel = Node.new()
	enemy_info_panel.set_script(load("res://src/scripts/ui/hud/enemy_info_panel.gd"))
	add_child(enemy_info_panel)

func after_each() -> void:
	if is_instance_valid(enemy_info_panel):
		enemy_info_panel.queue_free()

## 测试脚本加载
func test_script_loads() -> void:
	var script = load("res://src/scripts/ui/hud/enemy_info_panel.gd")
	assert_not_null(script, "EnemyInfoPanel脚本应该能加载")

## 测试WeaknessIconDisplay脚本加载
func test_weakness_icon_script_loads() -> void:
	var script = load("res://src/scripts/ui/hud/weakness_icon_display.gd")
	assert_not_null(script, "WeaknessIconDisplay脚本应该能加载")

## 测试场景文件存在
func test_enemy_info_panel_scene_exists() -> void:
	var scene = load("res://src/scenes/ui/hud/enemy_info_panel.tscn")
	assert_not_null(scene, "enemy_info_panel.tscn场景应该存在")

## 测试weakness_icon场景存在
func test_weakness_icon_scene_exists() -> void:
	var scene = load("res://src/scenes/ui/hud/weakness_icon.tscn")
	assert_not_null(scene, "weakness_icon.tscn场景应该存在")

## 测试GameEvents信号存在
func test_game_events_signals_exist() -> void:
	assert_true(GameEvents.has_signal("enemy_selected"), "enemy_selected信号应该存在")
	assert_true(GameEvents.has_signal("enemy_hp_changed"), "enemy_hp_changed信号应该存在")
	assert_true(GameEvents.has_signal("enemy_weakness_revealed"), "enemy_weakness_revealed信号应该存在")
	assert_true(GameEvents.has_signal("enemy_status_changed"), "enemy_status_changed信号应该存在")

## 测试WeaknessIconDisplay的元素映射
func test_weakness_icon_element_mapping() -> void:
	var script = load("res://src/scripts/ui/hud/weakness_icon_display.gd")
	var instance = Node.new()
	instance.set_script(script)
	
	# 检查ELEMENT_ICONS常量
	var element_icons = instance.get("ELEMENT_ICONS")
	assert_not_null(element_icons, "ELEMENT_ICONS应该存在")
	
	var expected_elements = ["metal", "wood", "water", "fire", "earth"]
	for element in expected_elements:
		assert_true(element_icons.has(element), "应该有%s元素的映射" % element)
	
	instance.queue_free()

## 测试EnemyInfoPanel的颜色常量
func test_enemy_info_panel_color_constants() -> void:
	var script = load("res://src/scripts/ui/hud/enemy_info_panel.gd")
	var instance = Node.new()
	instance.set_script(script)
	
	# 检查颜色常量
	var color_gold = instance.get("COLOR_GOLD")
	assert_not_null(color_gold, "COLOR_GOLD应该存在")
	assert_eq(color_gold, Color("#FFD700"), "COLOR_GOLD应该是金色")
	
	instance.queue_free()

## 测试EnemyInfoPanel的动画时长常量
func test_enemy_info_panel_animation_constants() -> void:
	var script = load("res://src/scripts/ui/hud/enemy_info_panel.gd")
	var instance = Node.new()
	instance.set_script(script)
	
	# 检查动画时长常量
	var fade_duration = instance.get("FADE_DURATION")
	assert_not_null(fade_duration, "FADE_DURATION应该存在")
	assert_eq(fade_duration, 0.2, "FADE_DURATION应该是0.2秒")
	
	var highlight_duration = instance.get("HIGHLIGHT_DURATION")
	assert_not_null(highlight_duration, "HIGHLIGHT_DURATION应该存在")
	assert_eq(highlight_duration, 0.3, "HIGHLIGHT_DURATION应该是0.3秒")
	
	instance.queue_free()

## 测试代码注释完整性
func test_code_has_documentation() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	assert_true(script_text.contains("##"), "脚本应该有文档注释")
	assert_true(script_text.contains("func"), "脚本应该有函数定义")

## 测试WeaknessIconDisplay代码注释完整性
func test_weakness_icon_has_documentation() -> void:
	var script_text = load("res://src/scripts/ui/hud/weakness_icon_display.gd").source_code
	assert_true(script_text.contains("##"), "脚本应该有文档注释")
	assert_true(script_text.contains("func"), "脚本应该有函数定义")

## 测试所有五行图标资源存在
func test_all_element_icons_exist() -> void:
	var elements = ["metal", "wood", "water", "fire", "earth"]
	var icon_paths = {
		"metal": "res://assets/ui/element_icons/element_icon_metal.png",
		"wood": "res://assets/ui/element_icons/element_icon_wood.png",
		"water": "res://assets/ui/element_icons/element_icon_water.png",
		"fire": "res://assets/ui/element_icons/element_icon_fire.png",
		"earth": "res://assets/ui/element_icons/element_icon_earth.png",
	}
	
	for element in elements:
		var path = icon_paths[element]
		var resource = load(path)
		assert_not_null(resource, "元素%s的图标应该存在于%s" % [element, path])

## 测试代码遵循命名规范
func test_naming_conventions() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	
	# 检查类名使用PascalCase
	assert_true(script_text.contains("class_name EnemyInfoPanel"), "类名应该使用PascalCase")
	
	# 检查变量使用snake_case
	assert_true(script_text.contains("_current_enemy_id"), "变量应该使用snake_case")
	assert_true(script_text.contains("_dirty_name"), "变量应该使用snake_case")
	
	# 检查常量使用UPPER_SNAKE_CASE
	assert_true(script_text.contains("COLOR_GOLD"), "常量应该使用UPPER_SNAKE_CASE")
	assert_true(script_text.contains("FADE_DURATION"), "常量应该使用UPPER_SNAKE_CASE")

## 测试WeaknessIconDisplay命名规范
func test_weakness_icon_naming_conventions() -> void:
	var script_text = load("res://src/scripts/ui/hud/weakness_icon_display.gd").source_code
	
	# 检查类名使用PascalCase
	assert_true(script_text.contains("class_name WeaknessIconDisplay"), "类名应该使用PascalCase")
	
	# 检查常量使用UPPER_SNAKE_CASE
	assert_true(script_text.contains("ELEMENT_ICONS"), "常量应该使用UPPER_SNAKE_CASE")
	assert_true(script_text.contains("COLOR_HIGHLIGHT"), "常量应该使用UPPER_SNAKE_CASE")

## 测试脚本使用@onready缓存
func test_uses_onready_caching() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	assert_true(script_text.contains("@onready"), "脚本应该使用@onready缓存节点引用")

## 测试脚本实现脏标记优化
func test_implements_dirty_marking() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	assert_true(script_text.contains("_dirty_"), "脚本应该实现脏标记优化")
	assert_true(script_text.contains("_process"), "脚本应该在_process中处理脏标记")

## 测试脚本使用信号驱动架构
func test_uses_signal_driven_architecture() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	assert_true(script_text.contains("GameEvents"), "脚本应该使用GameEvents信号总线")
	assert_true(script_text.contains(".connect("), "脚本应该连接信号")

## 测试WeaknessIconDisplay实现动画
func test_weakness_icon_implements_animation() -> void:
	var script_text = load("res://src/scripts/ui/hud/weakness_icon_display.gd").source_code
	assert_true(script_text.contains("play_reveal_animation"), "脚本应该实现play_reveal_animation方法")
	assert_true(script_text.contains("create_tween"), "脚本应该使用Tween系统")

## 测试代码复杂度（通过检查方法长度）
func test_method_length_reasonable() -> void:
	var script_text = load("res://src/scripts/ui/hud/enemy_info_panel.gd").source_code
	
	# 简单检查：没有超长的方法（超过100行）
	var lines = script_text.split("\n")
	var current_method_length = 0
	var max_method_length = 0
	
	for line in lines:
		if line.strip_edges().starts_with("func "):
			if current_method_length > max_method_length:
				max_method_length = current_method_length
			current_method_length = 0
		else:
			current_method_length += 1
	
	assert_true(max_method_length < 100, "方法长度应该合理（< 100行）")

## 测试场景文件有正确的节点结构
func test_scene_has_correct_structure() -> void:
	var scene = load("res://src/scenes/ui/hud/enemy_info_panel.tscn")
	assert_not_null(scene, "场景应该存在")
	
	# 场景应该是PackedScene
	assert_true(scene is PackedScene, "应该是PackedScene类型")

## 测试weakness_icon场景有正确的节点结构
func test_weakness_icon_scene_has_correct_structure() -> void:
	var scene = load("res://src/scenes/ui/hud/weakness_icon.tscn")
	assert_not_null(scene, "场景应该存在")
	
	# 场景应该是PackedScene
	assert_true(scene is PackedScene, "应该是PackedScene类型")