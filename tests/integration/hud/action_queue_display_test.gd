extends GutTest

## Story 004: 行动顺序队列显示 - 集成测试
##
## 测试ActionQueueDisplay组件的所有acceptance criteria:
## - AC-1: 显示当前行动者+接下来3个单位(共4个)
## - AC-2: 当前行动者有金色边框高亮(#FFD700)
## - AC-3: 玩家单位使用青绿边框(#2E8B57)
## - AC-4: 敌人单位使用深红边框(#DC143C)
## - AC-5: 行动顺序改变时队列正确更新
## - AC-6: 队列为空时显示"等待战斗开始"或隐藏队列面板
## - AC-7: 队列单位少于4个时显示实际数量,不填充空槽位
## - AC-8: 行动者死亡时立即从队列移除,后续单位前移
## - AC-9: 队列更新时有0.3秒的滑动动画
## - AC-10: 当前行动者完成行动后,队列向左滚动,新单位从右侧进入
## - AC-11: 所有单位头像资源存在且正确加载

var action_queue_display: Node
var test_scene: Node

# ============================================================================
# 测试生命周期
# ============================================================================

func before_each() -> void:
	# 创建测试场景
	test_scene = Node.new()
	add_child(test_scene)
	
	# 实例化ActionQueueDisplay
	action_queue_display = preload("res://src/scenes/ui/hud/action_queue_display.tscn").instantiate()
	test_scene.add_child(action_queue_display)
	
	# 等待_ready()完成
	await get_tree().process_frame

func after_each() -> void:
	# 清理
	if test_scene:
		test_scene.queue_free()
	action_queue_display = null

# ============================================================================
# AC-1: 显示当前行动者+接下来3个单位(共4个)
# ============================================================================

func test_ac1_display_four_units() -> void:
	## 测试队列显示4个单位
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy2", "unit_name": "敌人2", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 4, "应该显示4个单位")

func test_ac1_display_less_than_four_units() -> void:
	## 测试队列少于4个单位时显示实际数量
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 2, "应该显示2个单位")

func test_ac1_display_more_than_four_units() -> void:
	## 测试队列超过4个单位时只显示前4个
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy2", "unit_name": "敌人2", "is_player": false, "icon_path": ""},
		{"unit_id": "player3", "unit_name": "队友2", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy3", "unit_name": "敌人3", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 4, "应该只显示前4个单位")

# ============================================================================
# AC-2: 当前行动者有金色边框高亮(#FFD700)
# ============================================================================

func test_ac2_current_actor_golden_border() -> void:
	## 测试当前行动者(第一个)有金色边框
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	var first_unit = action_queue_display.get_queue_unit_at(0)
	assert_not_null(first_unit, "第一个单位应该存在")
	
	var expected_color = Color("#FFD700")
	var actual_color = first_unit.get_border_color()
	assert_eq(actual_color, expected_color, "当前行动者应该有金色边框")

# ============================================================================
# AC-3: 玩家单位使用青绿边框(#2E8B57)
# ============================================================================

func test_ac3_player_unit_green_border() -> void:
	## 测试玩家单位(非当前行动者)有青绿边框
	var queue = [
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	var second_unit = action_queue_display.get_queue_unit_at(1)
	assert_not_null(second_unit, "第二个单位应该存在")
	
	var expected_color = Color("#2E8B57")
	var actual_color = second_unit.get_border_color()
	assert_eq(actual_color, expected_color, "玩家单位应该有青绿边框")

# ============================================================================
# AC-4: 敌人单位使用深红边框(#DC143C)
# ============================================================================

func test_ac4_enemy_unit_red_border() -> void:
	## 测试敌人单位有深红边框
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	var second_unit = action_queue_display.get_queue_unit_at(1)
	assert_not_null(second_unit, "第二个单位应该存在")
	
	var expected_color = Color("#DC143C")
	var actual_color = second_unit.get_border_color()
	assert_eq(actual_color, expected_color, "敌人单位应该有深红边框")

# ============================================================================
# AC-5: 行动顺序改变时队列正确更新
# ============================================================================

func test_ac5_queue_updates_on_order_change() -> void:
	## 测试行动顺序改变时队列正确更新
	var queue1 = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue1)
	await get_tree().process_frame
	
	var first_unit_before = action_queue_display.get_queue_unit_at(0)
	assert_eq(first_unit_before.get_unit_name(), "主角", "初始队列第一个应该是主角")
	
	# 改变顺序
	var queue2 = [
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue2)
	await get_tree().process_frame
	
	var first_unit_after = action_queue_display.get_queue_unit_at(0)
	assert_eq(first_unit_after.get_unit_name(), "敌人1", "更新后队列第一个应该是敌人1")

# ============================================================================
# AC-6: 队列为空时显示"等待战斗开始"或隐藏队列面板
# ============================================================================

func test_ac6_empty_queue_shows_waiting_message() -> void:
	## 测试队列为空时显示"等待战斗开始"提示
	var empty_queue: Array[Dictionary] = []
	
	GameEvents.combat_action_queue_updated.emit(empty_queue)
	await get_tree().process_frame
	
	assert_true(action_queue_display.is_queue_empty(), "队列应该为空")
	assert_eq(action_queue_display.get_queue_unit_count(), 0, "不应该显示任何单位")

func test_ac6_empty_queue_hides_container() -> void:
	## 测试队列为空时隐藏队列容器
	var empty_queue: Array[Dictionary] = []
	
	GameEvents.combat_action_queue_updated.emit(empty_queue)
	await get_tree().process_frame
	
	# 检查队列容器是否隐藏
	var queue_container = action_queue_display.get_node_or_null("VBoxContainer/QueueContainer")
	assert_not_null(queue_container, "队列容器应该存在")
	assert_false(queue_container.visible, "队列容器应该隐藏")

# ============================================================================
# AC-7: 队列单位少于4个时显示实际数量,不填充空槽位
# ============================================================================

func test_ac7_no_empty_slots() -> void:
	## 测试队列少于4个时不填充空槽位
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 3, "应该显示3个单位,不填充空槽位")

# ============================================================================
# AC-8: 行动者死亡时立即从队列移除,后续单位前移
# ============================================================================

func test_ac8_unit_removal_shifts_queue() -> void:
	## 测试单位移除时后续单位前移
	var queue1 = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue1)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 3, "初始应该有3个单位")
	
	# 移除第一个单位
	var queue2 = [
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue2)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 2, "移除后应该有2个单位")
	var first_unit = action_queue_display.get_queue_unit_at(0)
	assert_eq(first_unit.get_unit_name(), "敌人1", "敌人1应该前移到第一位")

# ============================================================================
# AC-9: 队列更新时有0.3秒的滑动动画
# ============================================================================

func test_ac9_animation_duration() -> void:
	## 测试队列更新时有0.3秒的滑动动画
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	var start_time = Time.get_ticks_msec()
	GameEvents.combat_action_queue_updated.emit(queue)
	
	# 等待动画完成(0.3秒 + 缓冲)
	await get_tree().create_timer(0.35).timeout
	
	var end_time = Time.get_ticks_msec()
	var elapsed_time = (end_time - start_time) / 1000.0
	
	# 验证动画时长约为0.3秒(允许±0.1秒误差)
	assert_gt(elapsed_time, 0.2, "动画时长应该至少0.2秒")
	assert_lt(elapsed_time, 0.5, "动画时长应该不超过0.5秒")

# ============================================================================
# AC-10: 当前行动者完成行动后,队列向左滚动,新单位从右侧进入
# ============================================================================

func test_ac10_queue_scroll_animation() -> void:
	## 测试队列滚动动画(当前行动者完成后)
	var queue1 = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy2", "unit_name": "敌人2", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue1)
	await get_tree().process_frame
	
	var first_unit_before = action_queue_display.get_queue_unit_at(0)
	assert_eq(first_unit_before.get_unit_name(), "主角", "初始第一个应该是主角")
	
	# 主角完成行动,队列更新
	var queue2 = [
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy2", "unit_name": "敌人2", "is_player": false, "icon_path": ""},
		{"unit_id": "player3", "unit_name": "队友2", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue2)
	await get_tree().process_frame
	
	var first_unit_after = action_queue_display.get_queue_unit_at(0)
	assert_eq(first_unit_after.get_unit_name(), "敌人1", "更新后第一个应该是敌人1")
	
	var last_unit = action_queue_display.get_queue_unit_at(3)
	assert_eq(last_unit.get_unit_name(), "队友2", "新单位应该从右侧进入")

# ============================================================================
# AC-11: 所有单位头像资源存在且正确加载
# ============================================================================

func test_ac11_unit_icon_loading() -> void:
	## 测试单位头像加载(使用占位符)
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	var first_unit = action_queue_display.get_queue_unit_at(0)
	assert_not_null(first_unit, "第一个单位应该存在")
	
	# 验证单位名称正确加载
	assert_eq(first_unit.get_unit_name(), "主角", "单位名称应该正确加载")

# ============================================================================
# 边界情况测试
# ============================================================================

func test_edge_case_single_unit() -> void:
	## 测试只有一个单位的队列
	var queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue)
	await get_tree().process_frame
	
	assert_eq(action_queue_display.get_queue_unit_count(), 1, "应该显示1个单位")
	
	var unit = action_queue_display.get_queue_unit_at(0)
	var expected_color = Color("#FFD700")
	assert_eq(unit.get_border_color(), expected_color, "唯一的单位应该有金色边框")

func test_edge_case_rapid_updates() -> void:
	## 测试快速连续更新队列
	var queue1 = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""}
	]
	var queue2 = [
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	var queue3 = [
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(queue1)
	GameEvents.combat_action_queue_updated.emit(queue2)
	GameEvents.combat_action_queue_updated.emit(queue3)
	
	await get_tree().process_frame
	
	# 最后一次更新应该生效
	assert_eq(action_queue_display.get_queue_unit_count(), 1, "应该显示最后一次更新的队列")
	var unit = action_queue_display.get_queue_unit_at(0)
	assert_eq(unit.get_unit_name(), "队友1", "应该显示最后一次更新的单位")

func test_edge_case_empty_to_full() -> void:
	## 测试从空队列到满队列的转换
	var empty_queue: Array[Dictionary] = []
	GameEvents.combat_action_queue_updated.emit(empty_queue)
	await get_tree().process_frame
	
	assert_true(action_queue_display.is_queue_empty(), "初始应该为空")
	
	var full_queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""},
		{"unit_id": "player2", "unit_name": "队友1", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy2", "unit_name": "敌人2", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(full_queue)
	await get_tree().process_frame
	
	assert_false(action_queue_display.is_queue_empty(), "应该不为空")
	assert_eq(action_queue_display.get_queue_unit_count(), 4, "应该显示4个单位")

func test_edge_case_full_to_empty() -> void:
	## 测试从满队列到空队列的转换
	var full_queue = [
		{"unit_id": "player1", "unit_name": "主角", "is_player": true, "icon_path": ""},
		{"unit_id": "enemy1", "unit_name": "敌人1", "is_player": false, "icon_path": ""}
	]
	
	GameEvents.combat_action_queue_updated.emit(full_queue)
	await get_tree().process_frame
	
	assert_false(action_queue_display.is_queue_empty(), "初始应该不为空")
	
	var empty_queue: Array[Dictionary] = []
	GameEvents.combat_action_queue_updated.emit(empty_queue)
	await get_tree().process_frame
	
	assert_true(action_queue_display.is_queue_empty(), "应该为空")
	assert_eq(action_queue_display.get_queue_unit_count(), 0, "不应该显示任何单位")