# 随机事件结果处理器
# 处理四类事件的结果：战斗遭遇、奇遇/叙事、资源/宝藏、环境/状态

extends Node

class_name RandomEventResultProcessor

# 信号定义
signal combat_encounter_processed(encounter_data: Dictionary)
signal narrative_encounter_processed(choice_result: Dictionary)
signal resource_treasure_processed(rewards: Array)
signal environmental_status_processed(status_effects: Array)

# 依赖的系统引用
var combat_manager: Node = null
var ui_manager: Node = null
var item_manager: Node = null
var character_system: Node = null
var status_effect_system: Node = null

# 处理器字典
var event_processors: Dictionary = {}

func _init():
	# 初始化处理器
	_initialize_processors()

# 初始化处理器
func _initialize_processors():
	event_processors[RandomEventGenerator.EventType.COMBAT_ENCOUNTER] = _process_combat_encounter
	event_processors[RandomEventGenerator.EventType.ENCOUNTER_NARRATIVE] = _process_narrative_encounter
	event_processors[RandomEventGenerator.EventType.RESOURCE_TREASURE] = _process_resource_treasure
	event_processors[RandomEventGenerator.EventType.ENVIRONMENTAL_STATUS] = _process_environmental_status

# 设置依赖系统
func set_dependencies(combat_mgr: Node, ui_mgr: Node, item_mgr: Node, char_sys: Node, status_sys: Node):
	combat_manager = combat_mgr
	ui_manager = ui_mgr
	item_manager = item_mgr
	character_system = char_sys
	status_effect_system = status_sys

# 处理随机事件结果
func process_random_event_result(event_data: RandomEventGenerator.EventData, player_id: String, additional_data: Dictionary = {}) -> bool:
	if not event_data:
		print("错误: 事件数据为空")
		return false
	
	if not event_processors.has(event_data.event_type):
		print("错误: 不支持的事件类型 ", event_data.event_type)
		return false
	
	var processor_func = event_processors[event_data.event_type]
	return processor_func.call(event_data, player_id, additional_data)

# 处理战斗遭遇事件
func _process_combat_encounter(event_data: RandomEventGenerator.EventData, player_id: String, additional_data: Dictionary) -> bool:
	if not combat_manager:
		print("错误: 战斗管理器未设置")
		return false
	
	# 根据事件ID生成敌人配置
	var enemy_config = _generate_enemy_configuration(event_data.event_id, player_id)
	
	# 触发战斗场景
	var combat_result = combat_manager.start_combat(enemy_config)
	
	# 应用战斗结果
	if combat_result:
		emit_signal("combat_encounter_processed", {
			"event_id": event_data.event_id,
			"player_id": player_id,
			"enemy_config": enemy_config,
			"combat_result": combat_result
		})
		return true
	else:
		print("错误: 战斗启动失败")
		return false

# 处理奇遇/叙事事件
func _process_narrative_encounter(event_data: RandomEventGenerator.EventData, player_id: String, additional_data: Dictionary) -> bool:
	if not ui_manager:
		print("错误: UI管理器未设置")
		return false
	
	# 获取选项配置
	var options_config = _get_narrative_options(event_data.event_id)
	
	# 显示选项界面
	ui_manager.show_narrative_dialog(options_config, func(choice_data):
		# 处理玩家选择
		var result = _apply_narrative_choice(choice_data, player_id)
		emit_signal("narrative_encounter_processed", {
			"event_id": event_data.event_id,
			"player_id": player_id,
			"choice": choice_data,
			"result": result
		})
	)

	return true

# 处理资源/宝藏事件
func _process_resource_treasure(event_data: RandomEventGenerator.EventData, player_id: String, additional_data: Dictionary) -> bool:
	if not item_manager or not character_system:
		print("错误: 物品管理器或角色系统未设置")
		return false
	
	# 生成奖励物品
	var rewards = _generate_treasure_rewards(event_data.event_id, player_id)
	
	# 发放奖励
	var success = item_manager.award_items(rewards, player_id)
	
	if success:
		emit_signal("resource_treasure_processed", {
			"event_id": event_data.event_id,
			"player_id": player_id,
			"rewards": rewards
		})
		return true
	else:
		print("错误: 奖励发放失败")
		return false

# 处理环境/状态事件
func _process_environmental_status(event_data: RandomEventGenerator.EventData, player_id: String, additional_data: Dictionary) -> bool:
	if not status_effect_system or not character_system:
		print("错误: 状态效果系统或角色系统未设置")
		return false
	
	# 生成状态效果
	var status_effects = _generate_environmental_effects(event_data.event_id, player_id)
	
	# 施加状态效果
	var success = status_effect_system.apply_effects(status_effects, player_id)
	
	if success:
		emit_signal("environmental_status_processed", {
			"event_id": event_data.event_id,
			"player_id": player_id,
			"status_effects": status_effects
		})
		return true
	else:
		print("错误: 状态效果施加失败")
		return false

# 生成敌人配置（示例实现）
func _generate_enemy_configuration(event_id: String, player_id: String) -> Dictionary:
	# 这里应该从数据文件加载具体的敌人配置
	# 为了示例，返回一个简单的配置
	match event_id:
		"combat_001":
			return {
				"enemies": ["wolf", "boar"],
				"difficulty": "easy",
				"reward_multiplier": 1.0
			}
		"combat_002":
			return {
				"enemies": ["bandit_leader", "bandit_archer", "bandit_sword"],
				"difficulty": "medium",
				"reward_multiplier": 1.5
			}
		_:
			return {
				"enemies": ["generic_enemy"],
				"difficulty": "easy",
				"reward_multiplier": 1.0
			}

# 获取叙事选项配置（示例实现）
func _get_narrative_options(event_id: String) -> Dictionary:
	match event_id:
		"narrative_001":
			return {
				"title": "迷路的孩子",
				"description": "你遇到了一个迷路的小孩，看起来很害怕。",
				"options": [
					{"text": "帮助他找到回家的路", "id": "help"},
					{"text": "给他一些食物和水", "id": "feed"},
					{"text": "告诉他去找守卫", "id": "guard"}
				]
			}
		"narrative_002":
			return {
				"title": "神秘商人",
				"description": "一个神秘的商人向你兜售稀有物品。",
				"options": [
					{"text": "购买一件物品", "id": "buy"},
					{"text": "询问更多关于物品的信息", "id": "ask"},
					{"text": "拒绝并离开", "id": "leave"}
				]
			}
		_:
			return {
				"title": "未知事件",
				"description": "发生了某事...",
				"options": [
					{"text": "选项1", "id": "option1"},
					{"text": "选项2", "id": "option2"}
				]
			}

# 应用叙事选择（示例实现）
func _apply_narrative_choice(choice_data: Dictionary, player_id: String) -> Dictionary:
	var result = {}
	
	match choice_data.id:
		"help":
			result = {
				"exp_reward": 50,
				"item_reward": "compass",
				"reputation_change": 10
			}
		"feed":
			result = {
				"exp_reward": 30,
				"item_consumed": "bread",
				"luck_bonus": 5
			}
		"guard":
			result = {
				"exp_reward": 20,
				"reputation_change": -5
			}
		"buy":
			result = {
				"item_purchased": "mystic_scroll",
				"silver_spent": 100
			}
		"ask":
			result = {
				"knowledge_gained": "merchant_secrets",
				"exp_reward": 40
			}
		"leave":
			result = {
				"nothing_happens": true
			}
		_:
			result = {
				"default_outcome": true
			}
	
	# 应用结果到玩家
	if result.has("exp_reward"):
		character_system.add_experience(result.exp_reward, player_id)
	if result.has("item_reward"):
		item_manager.add_item(result.item_reward, player_id)
	if result.has("reputation_change"):
		character_system.modify_reputation(result.reputation_change, player_id)
	if result.has("luck_bonus"):
		character_system.add_temporary_luck(result.luck_bonus, 300, player_id)  # 5分钟
	if result.has("item_consumed"):
		item_manager.consume_item(result.item_consumed, player_id)
	if result.has("silver_spent"):
		character_system.spend_silver(result.silver_spent, player_id)
	if result.has("item_purchased"):
		item_manager.add_item(result.item_purchased, player_id)
	
	return result

# 生成宝藏奖励（示例实现）
func _generate_treasure_rewards(event_id: String, player_id: String) -> Array:
	var rewards = []
	
	match event_id:
		"treasure_001":
			rewards = [
				{"type": "item", "id": "health_potion", "quantity": 2},
				{"type": "silver", "amount": 50}
			]
		"treasure_002":
			rewards = [
				{"type": "item", "id": "rare_weapon", "quantity": 1},
				{"type": "exp", "amount": 100}
			]
		"treasure_003":
			rewards = [
				{"type": "item", "id": "treasure_map", "quantity": 1},
				{"type": "silver", "amount": 200},
				{"type": "exp", "amount": 50}
			]
		_:
			rewards = [
				{"type": "silver", "amount": 25}
			]
	
	return rewards

# 生成环境效果（示例实现）
func _generate_environmental_effects(event_id: String, player_id: String) -> Array:
	var effects = []
	
	match event_id:
		"env_001":
			effects = [
				{"type": "buff", "id": "weather_resistance", "duration": 600, "strength": 1.2},  # 10分钟
				{"type": "debuff", "id": "visibility_reduced", "duration": 300, "strength": 0.8}  # 5分钟
			]
		"env_002":
			effects = [
				{"type": "buff", "id": "lucky_find", "duration": 900, "strength": 1.5},  # 15分钟
				{"type": "buff", "id": "movement_speed", "duration": 300, "strength": 1.3}  # 5分钟
			]
		"env_003":
			effects = [
				{"type": "debuff", "id": "fatigue", "duration": 1200, "strength": 0.7},  # 20分钟
				{"type": "debuff", "id": "combat_penalty", "duration": 600, "strength": 0.9}  # 10分钟
			]
		_:
			effects = [
				{"type": "buff", "id": "minor_blessing", "duration": 300, "strength": 1.1}
			]
	
	return effects
