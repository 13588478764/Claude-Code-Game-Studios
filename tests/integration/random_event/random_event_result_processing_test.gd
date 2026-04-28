extends "res://addons/gut/test.gd"

class_name RandomEventResultProcessingTest

# 测试随机事件结果处理器
# 覆盖所有四类事件的处理逻辑

var result_processor: RandomEventResultProcessor
var mock_combat_manager: MockCombatManager
var mock_ui_manager: MockUIManager
var mock_item_manager: MockItemManager
var mock_character_system: MockCharacterSystem
var mock_status_effect_system: MockStatusEffectSystem

func before_all():
	# 初始化测试依赖
	result_processor = RandomEventResultProcessor.new()
	mock_combat_manager = MockCombatManager.new()
	mock_ui_manager = MockUIManager.new()
	mock_item_manager = MockItemManager.new()
	mock_character_system = MockCharacterSystem.new()
	mock_status_effect_system = MockStatusEffectSystem.new()
	
	# 设置依赖
	result_processor.set_dependencies(
		mock_combat_manager,
		mock_ui_manager,
		mock_item_manager,
		mock_character_system,
		mock_status_effect_system
	)

func after_all():
	# 清理测试资源
	if result_processor:
		result_processor.queue_free()
	if mock_combat_manager:
		mock_combat_manager.queue_free()
	if mock_ui_manager:
		mock_ui_manager.queue_free()
	if mock_item_manager:
		mock_item_manager.queue_free()
	if mock_character_system:
		mock_character_system.queue_free()
	if mock_status_effect_system:
		mock_status_effect_system.queue_free()

# 测试战斗遭遇事件处理
func test_combat_encounter_processing_correctly_triggers_combat_scene():
	# Given: 触发战斗遭遇事件
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "combat_001"
	event_data.event_type = RandomEventGenerator.EventType.COMBAT_ENCOUNTER
	event_data.base_weight = 20
	event_data.description = "野兽袭击"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理战斗遭遇事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 正确生成敌人并应用战斗结果
	assert_true(success, "战斗遭遇事件处理应该成功")
	assert_true(mock_combat_manager.combat_started, "应该触发战斗场景")
	assert_equal(mock_combat_manager.last_enemy_config["enemies"], ["wolf", "boar"], "应该生成正确的敌人配置")

# 测试奇遇/叙事事件处理
func test_narrative_encounter_processing_provides_options_interface():
	# Given: 触发奇遇/叙事事件
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "narrative_001"
	event_data.event_type = RandomEventGenerator.EventType.ENCOUNTER_NARRATIVE
	event_data.base_weight = 30
	event_data.description = "迷路的孩子"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理奇遇/叙事事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 提供对话选项界面
	assert_true(success, "奇遇/叙事事件处理应该成功")
	assert_true(mock_ui_manager.dialog_shown, "应该显示对话选项界面")
	assert_equal(mock_ui_manager.last_dialog_config["title"], "迷路的孩子", "应该显示正确的对话标题")

# 测试资源/宝藏事件处理
func test_resource_treasure_processing_correctly_awards_items():
	# Given: 触发资源/宝藏事件
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "treasure_001"
	event_data.event_type = RandomEventGenerator.EventType.RESOURCE_TREASURE
	event_data.base_weight = 25
	event_data.description = "路边包裹"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理资源/宝藏事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 正确发放物品奖励
	assert_true(success, "资源/宝藏事件处理应该成功")
	assert_true(mock_item_manager.items_awarded, "应该发放物品奖励")
	assert_equal(mock_item_manager.last_rewards.size(), 2, "应该发放2个奖励")

# 测试环境/状态事件处理
func test_environmental_status_processing_applies_temporary_effects():
	# Given: 触发环境/状态事件
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "env_001"
	event_data.event_type = RandomEventGenerator.EventType.ENVIRONMENTAL_STATUS
	event_data.base_weight = 15
	event_data.description = "天气变化"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理环境/状态事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 施加正确的临时效果
	assert_true(success, "环境/状态事件处理应该成功")
	assert_true(mock_status_effect_system.effects_applied, "应该施加状态效果")
	assert_equal(mock_status_effect_system.last_effects.size(), 2, "应该施加2个状态效果")

# 边缘情况测试：背包满的情况
func test_resource_treasure_processing_handles_full_inventory():
	# Given: 触发资源/宝藏事件，但背包已满
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "treasure_002"
	event_data.event_type = RandomEventGenerator.EventType.RESOURCE_TREASURE
	event_data.base_weight = 25
	event_data.description = "稀有武器"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# 模拟背包已满
	mock_item_manager.simulate_full_inventory = true
	
	# When: 处理资源/宝藏事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 正确处理背包满的情况
	assert_true(success, "即使背包满也应该成功处理")
	assert_true(mock_item_manager.full_inventory_handled, "应该处理背包满的情况")

# 边缘情况测试：不同敌人组合和战斗结果
func test_combat_encounter_processing_handles_different_enemy_combinations():
	# Given: 触发不同类型的战斗遭遇事件
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "combat_002"
	event_data.event_type = RandomEventGenerator.EventType.COMBAT_ENCOUNTER
	event_data.base_weight = 25
	event_data.description = "强盗袭击"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理战斗遭遇事件
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 正确处理不同的敌人组合
	assert_true(success, "战斗遭遇事件处理应该成功")
	assert_equal(mock_combat_manager.last_enemy_config["enemies"], ["bandit_leader", "bandit_archer", "bandit_sword"], "应该生成正确的强盗组合")
	assert_equal(mock_combat_manager.last_enemy_config["difficulty"], "medium", "应该设置正确的难度")

# 边缘情况测试：检查所有选项路径和结果
func test_narrative_encounter_processing_handles_all_choice_paths():
	# Given: 触发奇遇事件并选择不同选项
	var event_data = RandomEventGenerator.EventData.new()
	event_data.event_id = "narrative_002"
	event_data.event_type = RandomEventGenerator.EventType.ENCOUNTER_NARRATIVE
	event_data.base_weight = 30
	event_data.description = "神秘商人"
	event_data.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理奇遇事件（选择购买）
	var success = result_processor.process_random_event_result(event_data, player_id)
	
	# Then: 正确处理所有选项路径
	assert_true(success, "奇遇事件处理应该成功")
	assert_true(mock_ui_manager.dialog_shown, "应该显示对话界面")
	
	# 模拟选择"购买"
	var choice_data = {"id": "buy", "text": "购买一件物品"}
	var result = result_processor._apply_narrative_choice(choice_data, player_id)
	
	assert_true(result.has("item_purchased"), "购买选项应该返回购买的物品")
	assert_equal(result["silver_spent"], 100, "应该消耗100银两")

# 边缘情况测试：检查效果叠加和持续时间
func test_environmental_status_processing_handles_effect_stacking_and_duration():
	# Given: 触发多个环境/状态事件
	var event_data1 = RandomEventGenerator.EventData.new()
	event_data1.event_id = "env_002"
	event_data1.event_type = RandomEventGenerator.EventType.ENVIRONMENTAL_STATUS
	event_data1.base_weight = 20
	event_data1.description = "幸运发现"
	event_data1.region_specific = true
	
	var event_data2 = RandomEventGenerator.EventData.new()
	event_data2.event_id = "env_003"
	event_data2.event_type = RandomEventGenerator.EventType.ENVIRONMENTAL_STATUS
	event_data2.base_weight = 15
	event_data2.description = "疲劳状态"
	event_data2.region_specific = true
	
	var player_id = "player_001"
	
	# When: 处理第一个环境事件
	var success1 = result_processor.process_random_event_result(event_data1, player_id)
	
	# Then: 正确处理效果叠加
	assert_true(success1, "第一个环境事件处理应该成功")
	assert_equal(mock_status_effect_system.last_effects[0]["duration"], 900, "幸运发现效果应该持续15分钟")
	
	# When: 处理第二个环境事件
	var success2 = result_processor.process_random_event_result(event_data2, player_id)
	
	# Then: 正确处理持续时间
	assert_true(success2, "第二个环境事件处理应该成功")
	assert_equal(mock_status_effect_system.last_effects[0]["duration"], 1200, "疲劳效果应该持续20分钟")


# Mock类定义
class MockCombatManager:
	extends Node
	
	var combat_started: bool = false
	var last_enemy_config: Dictionary = {}
	
	func start_combat(enemy_config: Dictionary):
		combat_started = true
		last_enemy_config = enemy_config
		return {"victory": true, "exp_gained": 100, "items_dropped": ["health_potion"]}

class MockUIManager:
	extends Node
	
	var dialog_shown: bool = false
	var last_dialog_config: Dictionary = {}
	
	func show_narrative_dialog(config: Dictionary, callback: Callable):
		dialog_shown = true
		last_dialog_config = config
		# 立即调用回调模拟玩家选择
		callback.call({"id": "help", "text": "帮助他找到回家的路"})

class MockItemManager:
	extends Node
	
	var items_awarded: bool = false
	var last_rewards: Array = []
	var simulate_full_inventory: bool = false
	var full_inventory_handled: bool = false
	
	func award_items(rewards: Array, player_id: String):
		items_awarded = true
		last_rewards = rewards
		
		if simulate_full_inventory:
			full_inventory_handled = true
			# 返回部分成功
			return true
		
		return true
	
	func add_item(item_id: String, player_id: String):
		pass
	
	func consume_item(item_id: String, player_id: String):
		pass

class MockCharacterSystem:
	extends Node
	
	func add_experience(exp: int, player_id: String):
		pass
	
	func modify_reputation(change: int, player_id: String):
		pass
	
	func add_temporary_luck(bonus: int, duration: int, player_id: String):
		pass
	
	func spend_silver(amount: int, player_id: String):
		pass

class MockStatusEffectSystem:
	extends Node
	
	var effects_applied: bool = false
	var last_effects: Array = []
	
	func apply_effects(effects: Array, player_id: String):
		effects_applied = true
		last_effects = effects
		return true