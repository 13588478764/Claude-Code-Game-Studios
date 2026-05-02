extends GutTest
## 敌人信息显示集成测试
## 覆盖Story 005的所有12个验收标准

var enemy_info_panel: Control
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
	
	# 加载EnemyInfoPanel场景
	var scene = load("res://src/scenes/ui/hud/enemy_info_panel.tscn")
	enemy_info_panel = scene.instantiate()
	add_child(enemy_info_panel)
	await enemy_info_panel.tree_entered

func after_each() -> void:
	if is_instance_valid(enemy_info_panel):
		enemy_info_panel.queue_free()

## AC-1: 选中敌人时显示名称和等级
func test_enemy_name_and_level_display() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var name_label = enemy_info_panel.get_node("%EnemyNameLabel")
	var level_label = enemy_info_panel.get_node("%EnemyLevelLabel")
	
	assert_eq(name_label.text, "火焰骷髅", "敌人名称应该正确显示")
	assert_eq(level_label.text, "Lv.15", "敌人等级应该正确显示")

## AC-2: 敌人HP条正确显示当前值/最大值 (280x20px)
func test_enemy_hp_bar_display() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 75,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var hp_bar = enemy_info_panel.get_node("%HPBar")
	var hp_label = enemy_info_panel.get_node("%HPLabel")
	
	assert_eq(hp_bar.max_value, 100.0, "HP条最大值应该是100")
	assert_eq(hp_bar.value, 75.0, "HP条当前值应该是75")
	assert_eq(hp_label.text, "75/100", "HP标签应该显示75/100")
	assert_eq(hp_bar.custom_minimum_size, Vector2(280, 20), "HP条尺寸应该是280x20px")

## AC-3: 五行弱点图标正确显示 (32x32px)
func test_weakness_icons_display() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["metal", "water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var weakness_container = enemy_info_panel.get_node("%WeaknessContainer")
	var icons = weakness_container.get_children()
	
	assert_eq(icons.size(), 2, "应该显示2个弱点图标")
	
	for icon in icons:
		assert_eq(icon.custom_minimum_size, Vector2(32, 32), "弱点图标尺寸应该是32x32px")

## AC-4: 已发现弱点高亮显示
func test_discovered_weakness_highlight() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["metal", "water"],
		"discovered_weaknesses": ["water"],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var weakness_container = enemy_info_panel.get_node("%WeaknessContainer")
	var icons = weakness_container.get_children()
	
	# 检查第二个图标（water）是否高亮
	var water_icon = icons[1]
	assert_true(water_icon.is_highlighted(), "已发现的water弱点应该高亮")

## AC-5: Down状态有明显标识
func test_down_status_indicator() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "down",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var down_indicator = enemy_info_panel.get_node("%DownIndicator")
	assert_true(down_indicator.visible, "Down状态应该显示标识")

## AC-6: Break状态有明显标识
func test_break_status_indicator() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "break",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	var break_indicator = enemy_info_panel.get_node("%BreakIndicator")
	assert_true(break_indicator.visible, "Break状态应该显示标识")

## AC-7: 未选中敌人时显示"未选中目标"或隐藏
func test_no_target_display() -> void:
	var no_target_label = enemy_info_panel.get_node("%NoTargetLabel")
	assert_true(no_target_label.visible, "初始状态应该显示'未选中目标'")
	
	# 选中敌人后应该隐藏
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	assert_false(no_target_label.visible, "选中敌人后应该隐藏'未选中目标'")

## AC-8: 切换选中目标时有0.2秒的淡入淡出过渡
func test_fade_transition_animation() -> void:
	var enemy_data_1 = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data_1)
	await enemy_info_panel.get_tree().process_frame
	
	# 记录初始透明度
	var initial_alpha = enemy_info_panel.modulate.a
	
	# 切换到另一个敌人
	var enemy_data_2 = {
		"id": "enemy_002",
		"name": "冰霜巨人",
		"level": 20,
		"current_hp": 150,
		"max_hp": 150,
		"weaknesses": ["fire"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data_2)
	
	# 等待淡出动画
	await enemy_info_panel.get_tree().create_timer(0.15).timeout
	
	# 在淡出过程中，透明度应该降低
	var mid_alpha = enemy_info_panel.modulate.a
	assert_true(mid_alpha < initial_alpha, "淡出过程中透明度应该降低")
	
	# 等待淡入动画完成
	await enemy_info_panel.get_tree().create_timer(0.15).timeout
	
	# 动画完成后，透明度应该恢复
	var final_alpha = enemy_info_panel.modulate.a
	assert_almost_eq(final_alpha, 1.0, 0.1, "淡入完成后透明度应该恢复到1.0")

## AC-9: 弱点从未发现到已发现时有高亮动画 (0.3秒)
func test_weakness_reveal_animation() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	# 发现弱点
	game_events.enemy_weakness_revealed.emit("enemy_001", "water")
	await enemy_info_panel.get_tree().process_frame
	
	var weakness_container = enemy_info_panel.get_node("%WeaknessContainer")
	var water_icon = weakness_container.get_children()[0]
	
	# 检查高亮状态
	assert_true(water_icon.is_highlighted(), "弱点应该被高亮")

## AC-10: 多个敌人时，选中逻辑正确
func test_multiple_enemies_selection() -> void:
	var enemy_data_1 = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data_1)
	await enemy_info_panel.get_tree().process_frame
	
	var name_label = enemy_info_panel.get_node("%EnemyNameLabel")
	assert_eq(name_label.text, "火焰骷髅", "应该显示第一个敌人")
	
	# 切换到第二个敌人
	var enemy_data_2 = {
		"id": "enemy_002",
		"name": "冰霜巨人",
		"level": 20,
		"current_hp": 150,
		"max_hp": 150,
		"weaknesses": ["fire"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data_2)
	await enemy_info_panel.get_tree().process_frame
	
	assert_eq(name_label.text, "冰霜巨人", "应该显示第二个敌人")

## AC-11: 所有五行图标资源存在
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

## AC-12: Boss敌人显示特殊边框
func test_boss_enemy_border() -> void:
	var boss_data = {
		"id": "boss_001",
		"name": "火焰之王",
		"level": 50,
		"current_hp": 500,
		"max_hp": 500,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": true
	}
	
	game_events.enemy_selected.emit(boss_data)
	await enemy_info_panel.get_tree().process_frame
	
	var boss_border = enemy_info_panel.get_node("%BossBorder")
	assert_true(boss_border.visible, "Boss敌人应该显示特殊边框")

## 测试HP变化更新
func test_hp_change_update() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	# 更新HP
	game_events.enemy_hp_changed.emit("enemy_001", 50, 100)
	await enemy_info_panel.get_tree().process_frame
	
	var hp_bar = enemy_info_panel.get_node("%HPBar")
	var hp_label = enemy_info_panel.get_node("%HPLabel")
	
	assert_eq(hp_bar.value, 50.0, "HP条应该更新为50")
	assert_eq(hp_label.text, "50/100", "HP标签应该更新为50/100")

## 测试状态变化更新
func test_status_change_update() -> void:
	var enemy_data = {
		"id": "enemy_001",
		"name": "火焰骷髅",
		"level": 15,
		"current_hp": 100,
		"max_hp": 100,
		"weaknesses": ["water"],
		"discovered_weaknesses": [],
		"status": "",
		"is_boss": false
	}
	
	game_events.enemy_selected.emit(enemy_data)
	await enemy_info_panel.get_tree().process_frame
	
	# 更新状态为Down
	game_events.enemy_status_changed.emit("enemy_001", "down")
	await enemy_info_panel.get_tree().process_frame
	
	var down_indicator = enemy_info_panel.get_node("%DownIndicator")
	assert_true(down_indicator.visible, "Down状态应该显示")