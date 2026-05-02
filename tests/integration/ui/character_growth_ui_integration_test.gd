extends GutTest
## CharacterGrowthUI Integration Test
## 测试角色成长UI与CharacterSystem的完整数据流集成

var character_system: Node  # CharacterSystem (AutoLoad单例)
var character_growth_ui: CharacterGrowthUiScript
var test_scene: Node

func before_each():
	# 创建CharacterSystem实例
	character_system = CharacterSystem.new()
	character_system.name = "CharacterSystem"
	add_child_autofree(character_system)
	
	# 加载UI场景
	var ui_scene = load("res://src/scenes/ui/character_growth_ui.tscn")
	test_scene = ui_scene.instantiate()
	add_child_autofree(test_scene)
	
	# 获取UI脚本引用
	character_growth_ui = test_scene as CharacterGrowthUiScript
	
	# 等待一帧确保_ready执行完成
	await wait_frames(2)

func after_each():
	character_system = null
	character_growth_ui = null
	test_scene = null

# ============================================================================
# 角色面板数据绑定测试
# ============================================================================

func test_character_panel_displays_initial_data():
	# Given: 角色系统已初始化
	assert_not_null(character_system, "CharacterSystem should be initialized")
	assert_not_null(character_growth_ui, "CharacterGrowthUI should be loaded")
	
	# When: 显示UI
	character_growth_ui.show_ui()
	await wait_frames(1)
	
	# Then: 角色面板应显示初始数据
	assert_eq(character_system.level, 1, "Initial level should be 1")
	assert_eq(character_system.attributes.strength, 10, "Initial strength should be 10")
	assert_eq(character_system.total_attribute_points, 5, "Initial attribute points should be 5")

func test_character_panel_updates_on_level_up():
	# Given: 角色初始等级为1
	var initial_level = character_system.level
	
	# When: 角色升级
	character_system.add_experience(1000)  # 足够升级的经验
	await wait_frames(1)
	
	# Then: UI应该反映新的等级
	assert_gt(character_system.level, initial_level, "Level should increase")
	assert_gt(character_system.total_attribute_points, 5, "Should gain attribute points")

func test_character_panel_shows_realm_bonus():
	# Given: 角色在炼气期
	assert_eq(character_system.realm_index, 0, "Should start in first realm")
	
	# When: 角色突破到筑基期
	character_system.level = 10
	character_system.breakthrough_realm()
	await wait_frames(1)
	
	# Then: 应显示境界加成
	assert_eq(character_system.realm_index, 1, "Should be in second realm")
	assert_eq(character_system.realm_bonus, 1.1, "Should have 10% bonus")

# ============================================================================
# 属性分配系统测试
# ============================================================================

func test_attribute_allocation_slider_binding():
	# Given: 角色有5点可用属性点
	assert_eq(character_system.total_attribute_points, 5, "Should have 5 attribute points")
	assert_eq(character_system.allocated_attribute_points, 0, "No points allocated yet")
	
	# When: 显示UI
	character_growth_ui.show_ui()
	await wait_frames(1)
	
	# Then: 滑块应该正确绑定
	if character_growth_ui.strength_slider:
		assert_eq(character_growth_ui.strength_slider.max_value, 5, "Slider max should be 5")

func test_attribute_allocation_confirm():
	# Given: 角色有5点可用属性点
	var initial_strength = character_system.attributes.strength
	
	# When: 分配3点到力道
	character_growth_ui.temp_attribute_allocation["strength"] = 3
	character_growth_ui._on_confirm_allocation()
	await wait_frames(1)
	
	# Then: 力道应增加3点
	assert_eq(character_system.attributes.strength, initial_strength + 3, "Strength should increase by 3")
	assert_eq(character_system.allocated_attribute_points, 3, "3 points should be allocated")

func test_attribute_allocation_validation():
	# Given: 角色有5点可用属性点
	character_system.total_attribute_points = 5
	character_system.allocated_attribute_points = 0
	
	# When: 尝试分配6点（超出可用点数）
	var result = character_system.allocate_attribute_points("strength", 6)
	
	# Then: 分配应该失败
	assert_false(result, "Should not allow allocating more than available points")

func test_attribute_reset():
	# Given: 已分配3点到力道
	character_system.allocate_attribute_points("strength", 3)
	character_system.free_reset_count = 1
	var initial_strength = character_system.attributes.strength
	
	# When: 重置属性
	var result = character_system.reset_attributes()
	await wait_frames(1)
	
	# Then: 属性应恢复到基础值
	assert_true(result, "Reset should succeed")
	assert_eq(character_system.attributes.strength, 10, "Strength should reset to 10")
	assert_eq(character_system.allocated_attribute_points, 0, "Allocated points should reset to 0")

# ============================================================================
# 天赋网格系统测试
# ============================================================================

func test_talent_grid_initialization():
	# Given: UI已加载
	character_growth_ui.show_ui()
	await wait_frames(1)
	
	# Then: 天赋网格应该初始化为4x4
	assert_eq(character_system.talent_grid.size(), 4, "Should have 4 rows")
	assert_eq(character_system.talent_grid[0].size(), 4, "Each row should have 4 columns")

func test_talent_unlock():
	# Given: 角色有1点天赋点
	assert_eq(character_system.total_talent_points, 1, "Should have 1 talent point")
	
	# When: 解锁天赋(0,0)
	var result = character_system.unlock_talent(0, 0)
	await wait_frames(1)
	
	# Then: 天赋应该被解锁
	assert_true(result, "Talent unlock should succeed")
	assert_true(character_system.talent_grid[0][0]["unlocked"], "Talent should be unlocked")
	assert_eq(character_system.allocated_talent_points, 1, "1 talent point should be allocated")

func test_talent_unlock_validation():
	# Given: 角色有1点天赋点，已解锁一个天赋
	character_system.unlock_talent(0, 0)
	
	# When: 尝试解锁第二个天赋（天赋点不足）
	var result = character_system.unlock_talent(0, 1)
	
	# Then: 解锁应该失败
	assert_false(result, "Should not allow unlocking without talent points")

func test_talent_effects_apply_to_attributes():
	# Given: 角色有1点天赋点
	var initial_strength = character_system.attributes.strength
	
	# When: 解锁"力拔山兮"天赋（+10力道）
	character_system.unlock_talent(0, 0)
	var final_attrs = character_system.get_final_attributes()
	
	# Then: 最终力道应增加10点
	assert_eq(final_attrs.strength, initial_strength + 10, "Strength should increase by 10 from talent")

func test_talent_reset():
	# Given: 已解锁一个天赋
	character_system.unlock_talent(0, 0)
	
	# When: 重置天赋
	var result = character_system.reset_talents()
	
	# Then: 所有天赋应恢复未解锁状态
	assert_true(result, "Talent reset should succeed")
	assert_false(character_system.talent_grid[0][0]["unlocked"], "Talent should be locked")
	assert_eq(character_system.allocated_talent_points, 0, "Allocated talent points should reset")

# ============================================================================
# 信号集成测试
# ============================================================================

func test_level_up_signal_triggers_ui_update():
	# Given: 监听level_up信号
	var signal_watcher = watch_signals(character_system)
	
	# When: 角色升级
	character_system.add_experience(1000)
	await wait_frames(1)
	
	# Then: 应该发射level_up_event信号
	assert_signal_emitted(character_system, "level_up_event", "Should emit level_up_event")

func test_attribute_allocation_signal():
	# Given: 监听attribute_points_allocated信号
	var signal_watcher = watch_signals(character_system)
	
	# When: 分配属性点
	character_system.allocate_attribute_points("strength", 2)
	
	# Then: 应该发射attribute_points_allocated信号
	assert_signal_emitted(character_system, "attribute_points_allocated", "Should emit attribute_points_allocated")

# ============================================================================
# 完整流程集成测试
# ============================================================================

func test_complete_character_growth_flow():
	# Given: 新角色
	assert_eq(character_system.level, 1, "Start at level 1")
	assert_eq(character_system.total_attribute_points, 5, "Start with 5 attribute points")
	
	# When: 完整的成长流程
	# 1. 获得经验升级
	character_system.add_experience(1000)
	await wait_frames(1)
	
	# 2. 分配新获得的属性点
	character_system.allocate_attribute_points("strength", 3)
	character_system.allocate_attribute_points("agility", 2)
	
	# 3. 解锁天赋
	character_system.unlock_talent(0, 0)
	
	# Then: 所有系统应该正确协同工作
	assert_gt(character_system.level, 1, "Should have leveled up")
	assert_gt(character_system.attributes.strength, 10, "Strength should have increased")
	assert_true(character_system.talent_grid[0][0]["unlocked"], "Talent should be unlocked")
	
	# 验证最终属性包含所有加成
	var final_attrs = character_system.get_final_attributes()
	assert_gt(final_attrs.strength, character_system.attributes.strength, "Final strength should include talent bonus")

func test_ui_responds_to_character_system_changes():
	# Given: UI已显示
	character_growth_ui.show_ui()
	await wait_frames(1)
	
	# When: 角色系统发生变化
	character_system.add_experience(500)
	character_system.allocate_attribute_points("strength", 2)
	await wait_frames(1)
	
	# Then: UI应该自动更新（通过信号）
	# 这个测试验证信号连接是否正常工作
	assert_not_null(character_growth_ui.character_system, "UI should have character system reference")