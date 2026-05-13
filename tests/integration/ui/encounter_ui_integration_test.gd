extends GutTest
## EncounterUI Integration Test
## 测试奇遇事件UI与EncounterIntegration的完整数据流集成

var character_system: Node  # CharacterSystem (AutoLoad单例)
var encounter_integration: Node  # EncounterIntegration (AutoLoad单例)
var encounter_ui: EncounterUiScript
var item_manager: Node
var test_scene: Node

func before_each():
	# CharacterSystem 是 AutoLoad 单例，已经存在于 /root/CharacterSystem。
	# 不能 .new() 创建新实例 —— UI 内部用 get_node_or_null("/root/CharacterSystem") 
	# 访问 autoload，新实例与 UI 看到的不是同一个对象，集成测试将无效。
	character_system = CharacterSystem
	
	# 创建简单的ItemManager模拟
	item_manager = Node.new()
	item_manager.name = "ItemManager"
	item_manager.set_script(preload("res://tests/mocks/mock_item_manager.gd"))
	add_child_autofree(item_manager)
	
	# EncounterIntegration 同样是 AutoLoad 单例，直接引用
	encounter_integration = EncounterIntegration
	# initialize 仍可调用以重置内部依赖关系（如果方法存在且幂等）
	if encounter_integration.has_method("initialize"):
		encounter_integration.initialize(character_system, null, item_manager)
	
	# 加载UI场景
	var ui_scene = load("res://src/scenes/ui/encounter_ui.tscn")
	test_scene = ui_scene.instantiate()
	add_child_autofree(test_scene)
	
	# 获取UI脚本引用
	encounter_ui = test_scene as EncounterUiScript
	
	# 等待一帧确保_ready执行完成
	await wait_physics_frames(2)

func after_each():
	character_system = null
	encounter_integration = null
	encounter_ui = null
	item_manager = null
	test_scene = null

# ============================================================================
# 奇遇触发概率测试
# ============================================================================

func test_encounter_probability_calculation():
	# Given: 角色福缘为50
	character_system.attributes.luck = 50
	
	# When: 计算触发概率（基础3%）
	var probability = encounter_integration.calculate_encounter_probability(0.03)
	
	# Then: 概率应为 3% * (1 + 50/100) = 4.5%
	assert_almost_eq(probability, 0.045, 0.001, "Probability should be 4.5%")

func test_encounter_probability_cap():
	# Given: 角色福缘为500（极高）
	character_system.attributes.luck = 500
	
	# When: 计算触发概率（基础3%）
	var probability = encounter_integration.calculate_encounter_probability(0.03)
	
	# Then: 概率应被限制在10%
	assert_eq(probability, 0.1, "Probability should be capped at 10%")

func test_encounter_probability_with_zero_luck():
	# Given: 角色福缘为0
	character_system.attributes.luck = 0
	
	# When: 计算触发概率（基础3%）
	var probability = encounter_integration.calculate_encounter_probability(0.03)
	
	# Then: 概率应为基础概率3%
	assert_eq(probability, 0.03, "Probability should be base 3%")

# ============================================================================
# 奇遇类型判定测试
# ============================================================================

func test_encounter_type_determination():
	# When: 判定奇遇类型
	var encounter_type = encounter_integration.determine_encounter_type()
	
	# Then: 应返回5种类型之一
	var valid_types = [
		"wise_master_guidance",
		"secret_realm_discovery",
		"heavenly_treasure",
		"lost_martial_scroll",
		"jianghu_rumor"
	]
	assert_true(valid_types.has(encounter_type), "Should return a valid encounter type")

func test_encounter_type_randomness():
	# Given: 多次判定
	var types_found = {}
	
	# When: 判定100次
	for i in range(100):
		var encounter_type = encounter_integration.determine_encounter_type()
		types_found[encounter_type] = true
	
	# Then: 应该至少出现2种不同类型（验证随机性）
	assert_gte(types_found.size(), 2, "Should have at least 2 different types in 100 rolls")

# ============================================================================
# 奖励发放测试
# ============================================================================

func test_attribute_points_reward():
	# Given: 角色初始属性点为5
	var initial_points = character_system.total_attribute_points
	
	# When: 发放"高人指点"奖励（2-5点属性点）
	var encounter_data = {"type": "wise_master_guidance", "id": "test_001"}
	var result = encounter_integration.grant_encounter_rewards("wise_master_guidance", encounter_data)
	
	# Then: 应成功发放，属性点增加
	assert_true(result, "Reward should be granted")
	assert_gt(character_system.total_attribute_points, initial_points, "Attribute points should increase")
	assert_lte(character_system.total_attribute_points, initial_points + 5, "Should not exceed max reward")

func test_experience_reward():
	# Given: 角色初始经验为0
	var initial_exp = character_system.experience
	
	# When: 发放"秘境发现"奖励（500-1000经验）
	var encounter_data = {"type": "secret_realm_discovery", "id": "test_002"}
	var result = encounter_integration.grant_encounter_rewards("secret_realm_discovery", encounter_data)
	
	# Then: 应成功发放，经验值增加
	assert_true(result, "Reward should be granted")
	assert_gte(character_system.experience, initial_exp + 500, "Experience should increase by at least 500")
	assert_lte(character_system.experience, initial_exp + 1000, "Experience should not exceed 1000")

func test_talent_points_reward():
	# Given: 角色初始天赋点为1
	var initial_points = character_system.total_talent_points
	
	# When: 发放"江湖传闻"奖励（1-2点天赋点）
	var encounter_data = {"type": "jianghu_rumor", "id": "test_003"}
	var result = encounter_integration.grant_encounter_rewards("jianghu_rumor", encounter_data)
	
	# Then: 应成功发放，天赋点增加
	assert_true(result, "Reward should be granted")
	assert_gt(character_system.total_talent_points, initial_points, "Talent points should increase")

# ============================================================================
# 一次性奇遇测试
# ============================================================================

func test_one_time_encounter_tracking():
	# Given: 一次性奇遇ID
	var encounter_id = "unique_encounter_001"
	
	# When: 第一次触发
	var encounter_data = {"type": "wise_master_guidance", "id": encounter_id}
	var result1 = encounter_integration.grant_encounter_rewards("wise_master_guidance", encounter_data)
	
	# Then: 应成功发放
	assert_true(result1, "First trigger should succeed")
	assert_true(encounter_integration.check_encounter_triggered(encounter_id), "Should be marked as triggered")
	
	# When: 第二次触发同一奇遇
	var result2 = encounter_integration.grant_encounter_rewards("wise_master_guidance", encounter_data)
	
	# Then: 应拒绝发放
	assert_false(result2, "Second trigger should fail")

# ============================================================================
# UI显示测试
# ============================================================================

func test_encounter_ui_displays_correct_data():
	# Given: 奇遇数据
	var encounter_data = {
		"title": "高人指点",
		"description": "测试描述",
		"type": "bamboo",
		"player_luck": 75,
		"encounter_type": "wise_master_guidance",
		"encounter_id": "test_ui_001"
	}
	
	# When: 显示奇遇
	encounter_ui.show_encounter(encounter_data)
	await wait_physics_frames(1)
	
	# Then: UI应该可见
	assert_true(encounter_ui.visible, "UI should be visible")
	assert_eq(encounter_ui.current_encounter_data["encounter_type"], "wise_master_guidance", "Should store encounter data")

func test_encounter_ui_shows_lucky_star_icon():
	# Given: 角色福缘>60
	character_system.attributes.luck = 75
	
	# When: 显示奇遇
	var encounter_data = {
		"title": "测试",
		"description": "测试",
		"type": "bamboo",
		"player_luck": 75,
		"encounter_type": "wise_master_guidance",
		"encounter_id": "test_ui_002"
	}
	encounter_ui.show_encounter(encounter_data)
	await wait_physics_frames(1)
	
	# Then: 福缘图标应该可见
	if encounter_ui.lucky_star_icon:
		assert_true(encounter_ui.lucky_star_icon.visible, "Lucky star icon should be visible")

func test_encounter_ui_hides_lucky_star_icon_for_low_luck():
	# Given: 角色福缘<=60
	character_system.attributes.luck = 50
	
	# When: 显示奇遇
	var encounter_data = {
		"title": "测试",
		"description": "测试",
		"type": "bamboo",
		"player_luck": 50,
		"encounter_type": "wise_master_guidance",
		"encounter_id": "test_ui_003"
	}
	encounter_ui.show_encounter(encounter_data)
	await wait_physics_frames(1)
	
	# Then: 福缘图标应该隐藏
	if encounter_ui.lucky_star_icon:
		assert_false(encounter_ui.lucky_star_icon.visible, "Lucky star icon should be hidden")

# ============================================================================
# 按钮交互测试
# ============================================================================

func test_accept_button_grants_reward():
	# Given: 显示奇遇
	var initial_points = character_system.total_attribute_points
	encounter_ui.current_encounter_data = {
		"encounter_type": "wise_master_guidance",
		"id": "test_accept_001"
	}
	
	# When: 点击接受按钮
	encounter_ui._on_accept_button_pressed()
	await wait_physics_frames(1)
	
	# Then: 应发放奖励
	assert_gt(character_system.total_attribute_points, initial_points, "Should grant attribute points")

func test_decline_button_does_not_grant_reward():
	# Given: 显示奇遇
	var initial_points = character_system.total_attribute_points
	encounter_ui.current_encounter_data = {
		"encounter_type": "wise_master_guidance",
		"id": "test_decline_001"
	}
	
	# When: 点击拒绝按钮
	encounter_ui._on_decline_button_pressed()
	await wait_physics_frames(1)
	
	# Then: 不应发放奖励
	assert_eq(character_system.total_attribute_points, initial_points, "Should not grant reward")

# ============================================================================
# 信号集成测试
# ============================================================================

func test_encounter_triggered_signal():
	# Given: 监听encounter_triggered信号
	var signal_watcher = watch_signals(encounter_integration)
	
	# When: 触发奇遇
	encounter_integration.trigger_encounter_with_integration(1.0, "test_signal_001")
	await wait_physics_frames(1)
	
	# Then: 应发射encounter_triggered信号
	assert_signal_emitted(encounter_integration, "encounter_triggered", "Should emit encounter_triggered")

func test_reward_granted_signal():
	# Given: 监听encounter_reward_granted信号
	var signal_watcher = watch_signals(encounter_integration)
	
	# When: 发放奖励
	var encounter_data = {"type": "wise_master_guidance", "id": "test_signal_002"}
	encounter_integration.grant_encounter_rewards("wise_master_guidance", encounter_data)
	
	# Then: 应发射encounter_reward_granted信号
	assert_signal_emitted(encounter_integration, "encounter_reward_granted", "Should emit encounter_reward_granted")

# ============================================================================
# 完整流程集成测试
# ============================================================================

func test_complete_encounter_flow():
	# Given: 角色福缘为50
	character_system.attributes.luck = 50
	var initial_points = character_system.total_attribute_points

	# When: 完整的奇遇流程
	# 1. 触发奇遇（保证成功）
	var result = encounter_integration.trigger_encounter_with_integration(1.0, "test_complete_001")
	await wait_physics_frames(1)

	# Then: 奇遇应该触发
	assert_true(result["triggered"], "Encounter should trigger")
	assert_not_null(result["encounter_type"], "Should have encounter type")

	# 奖励由UI"接受"按钮触发（trigger_encounter_with_integration 不再自动发放）
	# 模拟玩家点击接受按钮
	encounter_ui.current_encounter_data = {
		"encounter_type": result["encounter_type"],
		"id": "test_complete_001"
	}
	encounter_ui._on_accept_button_pressed()
	await wait_physics_frames(1)

	# 验证奖励已发放（根据奇遇类型）
	var data_changed = (
		character_system.total_attribute_points > initial_points or
		character_system.experience > 0 or
		character_system.total_talent_points > 1
	)
	assert_true(data_changed, "Some character data should have changed after accepting")

func test_ui_responds_to_encounter_integration_signals():
	# Given: UI已初始化
	assert_not_null(encounter_ui.encounter_integration, "UI should have encounter integration reference")
	
	# When: 通过encounter_integration触发奇遇
	encounter_integration.trigger_encounter_with_integration(1.0, "test_ui_signal_001")
	await wait_physics_frames(2)
	
	# Then: UI应该响应并显示（通过信号）
	# 注意：由于UI的_on_encounter_triggered会被调用，current_encounter_data应该被设置
	assert_not_null(encounter_ui.current_encounter_data, "UI should have encounter data")
