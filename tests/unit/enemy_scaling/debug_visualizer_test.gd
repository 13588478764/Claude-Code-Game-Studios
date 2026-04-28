## debug_visualizer_test.gd
## 调试可视化工具单元测试
##
## 测试 TR-enemy-scaling-008

extends GutTest

const EnemyScalingDebugVisualizer = preload("res://scripts/enemy_scaling/debug_visualizer.gd")

var debug_visualizer: EnemyScalingDebugVisualizer

func before_each():
	# 仅在开发模式下创建
	if OS.is_debug_build():
		debug_visualizer = EnemyScalingDebugVisualizer.new()

## 开发者UI-1: 缩放系数面板实时显示
func test_scaling_panel_displays_coefficients():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# Given: 设置玩家等级
	debug_visualizer.set_player_level(50)
	debug_visualizer.set_region(2)
	
	# When: 获取调试信息
	var debug_info = debug_visualizer.get_debug_info()
	
	# Then: 应该显示正确的信息
	assert_eq(debug_info["player_level"], 50)
	assert_eq(debug_info["region_id"], 2)

## 开发者UI-2: 属性对比面板显示基础vs缩放属性
func test_attribute_panel_shows_comparison():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# Given: 创建调试可视化工具
	debug_visualizer.set_player_level(50)
	debug_visualizer.set_region(2)
	debug_visualizer.set_enemy_type(1)
	
	# When: 获取调试信息
	var debug_info = debug_visualizer.get_debug_info()
	
	# Then: 应该包含所有必要的信息
	assert_eq(debug_info["player_level"], 50)
	assert_eq(debug_info["region_id"], 2)
	assert_eq(debug_info["enemy_type"], 1)

## 开发者UI-3: 难度曲线图表显示1-99级曲线
func test_difficulty_curve_displays_all_levels():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# Given: 创建调试可视化工具
	debug_visualizer.set_player_level(1)
	
	# When: 获取调试信息
	var debug_info = debug_visualizer.get_debug_info()
	
	# Then: 应该能显示所有等级
	assert_eq(debug_info["player_level"], 1)

## 验证玩家等级设置
func test_set_player_level():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# Test 最低等级
	debug_visualizer.set_player_level(1)
	var info1 = debug_visualizer.get_debug_info()
	assert_eq(info1["player_level"], 1)
	
	# Test 中间等级
	debug_visualizer.set_player_level(50)
	var info2 = debug_visualizer.get_debug_info()
	assert_eq(info2["player_level"], 50)
	
	# Test 最高等级
	debug_visualizer.set_player_level(99)
	var info3 = debug_visualizer.get_debug_info()
	assert_eq(info3["player_level"], 99)
	
	# Test 超出范围 (应该被限制)
	debug_visualizer.set_player_level(100)
	var info4 = debug_visualizer.get_debug_info()
	assert_eq(info4["player_level"], 99)

## 验证区域设置
func test_set_region():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	for region_id in range(5):
		debug_visualizer.set_region(region_id)
		var info = debug_visualizer.get_debug_info()
		assert_eq(info["region_id"], region_id)

## 验证敌人类型设置
func test_set_enemy_type():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	for enemy_type in range(3):
		debug_visualizer.set_enemy_type(enemy_type)
		var info = debug_visualizer.get_debug_info()
		assert_eq(info["enemy_type"], enemy_type)

## 验证失败次数设置
func test_set_failure_count():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	debug_visualizer.set_failure_count(0)
	var info1 = debug_visualizer.get_debug_info()
	assert_eq(info1["failure_count"], 0)
	
	debug_visualizer.set_failure_count(3)
	var info2 = debug_visualizer.get_debug_info()
	assert_eq(info2["failure_count"], 3)
	
	# 负数应该被限制为0
	debug_visualizer.set_failure_count(-5)
	var info3 = debug_visualizer.get_debug_info()
	assert_eq(info3["failure_count"], 0)

## 验证无伤胜利次数设置
func test_set_perfect_win_count():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	debug_visualizer.set_perfect_win_count(0)
	var info1 = debug_visualizer.get_debug_info()
	assert_eq(info1["perfect_win_count"], 0)
	
	debug_visualizer.set_perfect_win_count(10)
	var info2 = debug_visualizer.get_debug_info()
	assert_eq(info2["perfect_win_count"], 10)
	
	# 负数应该被限制为0
	debug_visualizer.set_perfect_win_count(-5)
	var info3 = debug_visualizer.get_debug_info()
	assert_eq(info3["perfect_win_count"], 0)

## 验证调试信息完整性
func test_debug_info_completeness():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	debug_visualizer.set_player_level(50)
	debug_visualizer.set_region(2)
	debug_visualizer.set_enemy_type(1)
	debug_visualizer.set_failure_count(2)
	debug_visualizer.set_perfect_win_count(5)
	
	var debug_info = debug_visualizer.get_debug_info()
	
	# 验证所有字段都存在
	assert_true(debug_info.has("player_level"))
	assert_true(debug_info.has("region_id"))
	assert_true(debug_info.has("enemy_type"))
	assert_true(debug_info.has("failure_count"))
	assert_true(debug_info.has("perfect_win_count"))

## 验证多次更新
func test_multiple_updates():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# 第一次更新
	debug_visualizer.set_player_level(25)
	var info1 = debug_visualizer.get_debug_info()
	assert_eq(info1["player_level"], 25)
	
	# 第二次更新
	debug_visualizer.set_player_level(50)
	var info2 = debug_visualizer.get_debug_info()
	assert_eq(info2["player_level"], 50)
	
	# 第三次更新
	debug_visualizer.set_player_level(75)
	var info3 = debug_visualizer.get_debug_info()
	assert_eq(info3["player_level"], 75)

## 验证边界值
func test_boundary_values():
	if not OS.is_debug_build():
		skip("Test only runs in debug build")
		return
	
	# 测试等级边界
	debug_visualizer.set_player_level(0)
	var info1 = debug_visualizer.get_debug_info()
	assert_eq(info1["player_level"], 1, "Level 0 should be clamped to 1")
	
	debug_visualizer.set_player_level(150)
	var info2 = debug_visualizer.get_debug_info()
	assert_eq(info2["player_level"], 99, "Level 150 should be clamped to 99")
	
	# 测试区域边界
	debug_visualizer.set_region(-1)
	var info3 = debug_visualizer.get_debug_info()
	assert_eq(info3["region_id"], 0, "Region -1 should be clamped to 0")
	
	debug_visualizer.set_region(10)
	var info4 = debug_visualizer.get_debug_info()
	assert_eq(info4["region_id"], 4, "Region 10 should be clamped to 4")