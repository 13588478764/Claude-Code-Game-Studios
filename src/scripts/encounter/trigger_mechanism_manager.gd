extends Node

# 触发机制管理器
# 实现区域触发器和关键事件钩子，确保条件检查在正确时机激活

# 信号定义
signal trigger_activated(zone_id, encounter_data)
signal global_event_handled(event_type, event_data)

# 区域触发器数据结构
class ZoneTrigger:
	var area_2d: Area2D
	var encounter_id: String
	var zone_id: String
	var conditions: Array
	var is_registered: bool = false

# 事件钩子数据结构
class EventHook:
	var event_name: String
	var callback: Callable
	var is_registered: bool = false

# 存储区域触发器和事件钩子
var zone_triggers: Dictionary = {}
var event_hooks: Dictionary = {}
var registered_areas: Array = []

# 引用条件评估器
var condition_evaluator: Node = null

# 初始化
func _ready():
	# 获取条件评估器实例
	condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 注册全局事件钩子
	register_event_hooks()

# 注册区域触发器
func register_zone_triggers(encounter_zones: Array) -> void:
	for zone_data in encounter_zones:
		var zone_trigger = ZoneTrigger.new()
		zone_trigger.encounter_id = zone_data.get("encounter_id", "")
		zone_trigger.zone_id = zone_data.get("zone_id", "")
		zone_trigger.conditions = zone_data.get("conditions", [])
		
		# 创建Area2D节点作为触发器
		var area_2d = Area2D.new()
		area_2d.name = "ZoneTrigger_" + zone_trigger.zone_id
		
		# 设置碰撞形状（这里使用矩形区域作为示例）
		var collision_shape = CollisionShape2D.new()
		var rectangle_shape = RectangleShape2D.new()
		rectangle_shape.size = zone_data.get("size", Vector2(100, 100))
		collision_shape.shape = rectangle_shape
		area_2d.add_child(collision_shape)
		collision_shape.owner = area_2d
		
		# 设置位置
		area_2d.position = zone_data.get("position", Vector2(0, 0))
		
		# 连接信号
		area_2d.body_entered.connect(_on_body_entered.bind(area_2d, zone_trigger))
		area_2d.area_entered.connect(_on_area_entered.bind(area_2d, zone_trigger))
		
		# 添加到场景树
		self.add_child(area_2d)
		area_2d.owner = self
		
		# 保存触发器引用
		zone_trigger.area_2d = area_2d
		zone_trigger.is_registered = true
		zone_triggers[zone_trigger.zone_id] = zone_trigger
		
		# 添加到已注册区域列表
		registered_areas.append(area_2d)
	
	print("注册了 %d 个区域触发器" % zone_triggers.size())

# 处理区域进入事件
func _on_body_entered(body, area_2d, zone_trigger) -> void:
	# 检查进入的是否是玩家
	if body.has_method("is_player") and body.is_player():
		on_player_entered_zone(zone_trigger.zone_id)

# 处理区域进入事件（Area2D版本）
func _on_area_entered(area, area_2d, zone_trigger) -> void:
	# 检查进入的是否是玩家
	if area.has_method("is_player") and area.is_player():
		on_player_entered_zone(zone_trigger.zone_id)

# 处理玩家进入区域事件
func on_player_entered_zone(zone_id: String) -> void:
	if not zone_triggers.has(zone_id):
		print("错误：未找到区域ID为 %s 的触发器" % zone_id)
		return
	
	var zone_trigger = zone_triggers[zone_id]
	
	# 获取玩家数据
	var player_data = get_player_data()
	var progress_data = get_progress_data()
	
	# 检查条件是否满足
	var conditions_met = evaluate_conditions(zone_trigger.conditions, player_data, progress_data)
	
	if conditions_met:
		# 触发器激活 - 发送信号
		emit_signal("trigger_activated", zone_id, {
			"encounter_id": zone_trigger.encounter_id,
			"zone_id": zone_id,
			"conditions": zone_trigger.conditions
		})
		
		print("区域触发器激活: %s, 奇遇ID: %s" % [zone_id, zone_trigger.encounter_id])
	else:
		print("区域 %s 的条件未满足，未触发奇遇" % zone_id)

# 注册全局事件钩子
func register_event_hooks() -> void:
	# 注册休息事件钩子
	var rest_hook = EventHook.new()
	rest_hook.event_name = "on_rest_started"
	rest_hook.callback = handle_rest_event
	rest_hook.is_registered = true
	event_hooks["rest"] = rest_hook
	
	# 注册战斗胜利事件钩子
	var battle_hook = EventHook.new()
	battle_hook.event_name = "on_battle_won"
	battle_hook.callback = handle_battle_won_event
	battle_hook.is_registered = true
	event_hooks["battle"] = battle_hook
	
	# 注册天气变化事件钩子
	var weather_hook = EventHook.new()
	weather_hook.event_name = "on_weather_changed"
	weather_hook.callback = handle_weather_change_event
	weather_hook.is_registered = true
	event_hooks["weather"] = weather_hook
	
	print("注册了 %d 个全局事件钩子" % event_hooks.size())

# 处理休息事件
func handle_rest_event(event_data: Dictionary = {}) -> void:
	print("处理休息事件")
	
	# 检查是否有与休息相关的奇遇
	var rest_encounters = find_encounters_by_event_type("rest")
	
	for encounter in rest_encounters:
		var player_data = get_player_data()
		var progress_data = get_progress_data()
		
		var conditions_met = evaluate_conditions(encounter.conditions, player_data, progress_data)
		
		if conditions_met:
			emit_signal("trigger_activated", "rest_event", {
				"encounter_id": encounter.encounter_id,
				"zone_id": "rest_event",
				"event_type": "rest",
				"conditions": encounter.conditions
			})
			
			print("休息事件触发奇遇: %s" % encounter.encounter_id)

# 处理战斗胜利事件
func handle_battle_won_event(event_data: Dictionary = {}) -> void:
	print("处理战斗胜利事件")
	
	# 检查是否有与战斗胜利相关的奇遇
	var battle_encounters = find_encounters_by_event_type("battle_won")
	
	for encounter in battle_encounters:
		var player_data = get_player_data()
		var progress_data = get_progress_data()
		
		var conditions_met = evaluate_conditions(encounter.conditions, player_data, progress_data)
		
		if conditions_met:
			emit_signal("trigger_activated", "battle_won_event", {
				"encounter_id": encounter.encounter_id,
				"zone_id": "battle_won_event",
				"event_type": "battle_won",
				"conditions": encounter.conditions,
				"battle_data": event_data
			})
			
			print("战斗胜利事件触发奇遇: %s" % encounter.encounter_id)

# 处理天气变化事件
func handle_weather_change_event(event_data: Dictionary = {}) -> void:
	print("处理天气变化事件")
	
	# 检查是否有与天气相关的奇遇
	var weather_encounters = find_encounters_by_event_type("weather")
	
	for encounter in weather_encounters:
		var player_data = get_player_data()
		var progress_data = get_progress_data()
		
		# 更新玩家数据中的天气信息
		player_data.weather = event_data.get("new_weather", player_data.weather)
		
		var conditions_met = evaluate_conditions(encounter.conditions, player_data, progress_data)
		
		if conditions_met:
			emit_signal("trigger_activated", "weather_event", {
				"encounter_id": encounter.encounter_id,
				"zone_id": "weather_event",
				"event_type": "weather",
				"conditions": encounter.conditions,
				"weather_data": event_data
			})
			
			print("天气变化事件触发奇遇: %s" % encounter.encounter_id)

# 处理全局事件
func handle_global_events(event_type: String, event_data: Dictionary = {}) -> void:
	emit_signal("global_event_handled", event_type, event_data)
	
	# 根据事件类型调用相应的处理函数
	match event_type:
		"rest_started":
			handle_rest_event(event_data)
		"battle_won":
			handle_battle_won_event(event_data)
		"weather_changed":
			handle_weather_change_event(event_data)
		_:
			print("未知的全局事件类型: %s" % event_type)

# 评估条件
func evaluate_conditions(conditions: Array, player_data, progress_data) -> bool:
	if condition_evaluator == null:
		condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 简单的AND逻辑：所有条件都必须满足
	for condition in conditions:
		var condition_type = condition.get("type", "")
		var condition_params = condition.get("parameters", {})
		
		var result = evaluate_single_condition(condition_type, condition_params, player_data, progress_data)
		if not result:
			return false
	
	return true

# 评估单个条件
func evaluate_single_condition(condition_type: String, parameters: Dictionary, player_data, progress_data) -> bool:
	if condition_evaluator == null:
		condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	# 根据条件类型调用评估器的相应方法
	match condition_type:
		"TEMPORAL_ENVIRONMENT":
			# 将 PlayerData 对象转换为字典
			var player_dict = _player_data_to_dict(player_data)
			return condition_evaluator.evaluate_temporal_environment_conditions(player_dict)
		"CHARACTER_STATE":
			# 将 PlayerData 对象转换为字典
			var player_dict = _player_data_to_dict(player_data)
			return condition_evaluator.evaluate_character_state_conditions(player_dict)
		"PROGRESS_HISTORY":
			# 将 ProgressData 对象转换为字典
			var progress_dict = _progress_data_to_dict(progress_data)
			return condition_evaluator.evaluate_progress_history_conditions(progress_dict)
		"RANDOM_PROBABILITY":
			var base_prob = parameters.get("base_probability", 0.05)
			# 获取福缘值
			var luck = 50.0
			if player_data is Dictionary:
				luck = player_data.get("luck", 50.0)
			else:
				# 尝试访问对象的 luck 属性
				if player_data and player_data.has_method("get"):
					luck = player_data.get("luck", 50.0)
				elif player_data:
					luck = player_data.luck if "luck" in player_data else 50.0
			return condition_evaluator.evaluate_random_probability_conditions(luck, base_prob)
		_:
			print("未知的条件类型: %s" % condition_type)
			return false

# 将 PlayerData 对象转换为字典
func _player_data_to_dict(player_data) -> Dictionary:
	var result = {}
	
	# 检查是否是 PlayerData 对象（通过检查属性）
	if player_data is Object and player_data.has_method("get_class") == false:
		# 尝试访问 PlayerData 的属性
		if player_data.has_meta("position") or (player_data is Object and "position" in player_data):
			result["position"] = player_data.position if player_data.has_meta("position") else Vector2.ZERO
			result["time"] = player_data.time if player_data.has_meta("time") else 0.0
			result["weather"] = player_data.weather if player_data.has_meta("weather") else ""
			result["luck"] = player_data.luck if player_data.has_meta("luck") else 50.0
			result["wisdom"] = player_data.wisdom if player_data.has_meta("wisdom") else 60.0
			result["health"] = player_data.health if player_data.has_meta("health") else 0.8
			result["max_health"] = 1.0
			result["qi"] = player_data.qi if player_data.has_meta("qi") else 0.7
			result["attributes"] = player_data.attributes if player_data.has_meta("attributes") else {}
			result["inventory"] = player_data.inventory if player_data.has_meta("inventory") else []
			result["skills"] = player_data.skills if player_data.has_meta("skills") else []
			result["realm"] = player_data.realm if player_data.has_meta("realm") else ""
			result["location"] = "default_location"
			result["time_of_day"] = "day"
			result["status_effects"] = []
		else:
			# 如果不是 PlayerData 对象，尝试直接访问属性
			result["position"] = player_data.position if "position" in player_data else Vector2.ZERO
			result["time"] = player_data.time if "time" in player_data else 0.0
			result["weather"] = player_data.weather if "weather" in player_data else ""
			result["luck"] = player_data.luck if "luck" in player_data else 50.0
			result["wisdom"] = player_data.wisdom if "wisdom" in player_data else 60.0
			result["health"] = player_data.health if "health" in player_data else 0.8
			result["max_health"] = 1.0
			result["qi"] = player_data.qi if "qi" in player_data else 0.7
			result["attributes"] = player_data.attributes if "attributes" in player_data else {}
			result["inventory"] = player_data.inventory if "inventory" in player_data else []
			result["skills"] = player_data.skills if "skills" in player_data else []
			result["realm"] = player_data.realm if "realm" in player_data else ""
			result["location"] = "default_location"
			result["time_of_day"] = "day"
			result["status_effects"] = []
	elif player_data is Dictionary:
		result = player_data
	else:
		# 默认值
		result["position"] = Vector2.ZERO
		result["time"] = 0.0
		result["weather"] = ""
		result["luck"] = 50.0
		result["wisdom"] = 60.0
		result["health"] = 0.8
		result["max_health"] = 1.0
		result["qi"] = 0.7
		result["attributes"] = {}
		result["inventory"] = []
		result["skills"] = []
		result["realm"] = ""
		result["location"] = "default_location"
		result["time_of_day"] = "day"
		result["status_effects"] = []
	
	return result

# 将 ProgressData 对象转换为字典
func _progress_data_to_dict(progress_data) -> Dictionary:
	var result = {}
	
	# 检查是否是 ProgressData 对象（通过检查属性）
	if progress_data is Object and progress_data.has_method("get_class") == false:
		# 尝试访问 ProgressData 的属性
		if progress_data.has_meta("quest_status") or (progress_data is Object and "quest_status" in progress_data):
			result["quest_status"] = progress_data.quest_status if progress_data.has_meta("quest_status") else {}
			result["explored_areas"] = progress_data.explored_areas if progress_data.has_meta("explored_areas") else []
			result["encounter_history"] = progress_data.encounter_history if progress_data.has_meta("encounter_history") else []
			result["behavior_history"] = progress_data.behavior_history if progress_data.has_meta("behavior_history") else {}
			result["encounters_completed"] = progress_data.encounter_history if progress_data.has_meta("encounter_history") else []
			result["level"] = 1
		else:
			# 如果不是 ProgressData 对象，尝试直接访问属性
			result["quest_status"] = progress_data.quest_status if "quest_status" in progress_data else {}
			result["explored_areas"] = progress_data.explored_areas if "explored_areas" in progress_data else []
			result["encounter_history"] = progress_data.encounter_history if "encounter_history" in progress_data else []
			result["behavior_history"] = progress_data.behavior_history if "behavior_history" in progress_data else {}
			result["encounters_completed"] = progress_data.encounter_history if "encounter_history" in progress_data else []
			result["level"] = 1
	elif progress_data is Dictionary:
		result = progress_data
	else:
		# 默认值
		result["quest_status"] = {}
		result["explored_areas"] = []
		result["encounter_history"] = []
		result["behavior_history"] = {}
		result["encounters_completed"] = []
		result["level"] = 1
	
	return result

# 获取玩家数据（模拟）
func get_player_data() -> Object:
	if condition_evaluator == null:
		condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	var player_data = condition_evaluator.PlayerData.new()
	
	# 模拟玩家数据
	player_data.position = Vector2(randi() % 1000, randi() % 1000)  # 随机位置
	player_data.time = Engine.get_main_loop().get_node("/root").get_time() if Engine.get_main_loop().has_method("get_time") else Time.get_unix_time_from_system()
	player_data.weather = "sunny"  # 默认天气
	player_data.luck = 50.0
	player_data.wisdom = 60.0
	player_data.health = 0.8  # 80%
	player_data.qi = 0.7     # 70%
	player_data.attributes = {"luck": 50, "wisdom": 60, "health": 80}
	player_data.inventory = ["mysterious_jade"]
	player_data.skills = ["taijiquan"]
	player_data.realm = "ZhuJi"  # 筑基期
	
	return player_data

# 获取进度数据（模拟）
func get_progress_data() -> Object:
	if condition_evaluator == null:
		condition_evaluator = load("res://src/scripts/encounter/condition_evaluator.gd").new()
	
	var progress_data = condition_evaluator.ProgressData.new()
	
	# 模拟进度数据
	progress_data.quest_status = {"main_chapter": 3, "side_quest_completed": true}
	progress_data.explored_areas = ["Qingyun_Mountain", "Black_Wind_Fortress"]
	progress_data.encounter_history = ["encounter_001", "encounter_002"]
	progress_data.behavior_history = {"bandits_killed": 55, "npc_helped": 12}
	
	return progress_data

# 根据事件类型查找奇遇（模拟）
func find_encounters_by_event_type(event_type: String) -> Array:
	var encounters = []
	
	# 这里应该从数据源加载实际的奇遇数据
	# 为了演示，我们创建一些模拟数据
	match event_type:
		"rest":
			encounters.append({
				"encounter_id": "rest_dream_encounter",
				"conditions": [
					{"type": "TEMPORAL_ENVIRONMENT", "parameters": {"time_of_day": "night"}},
					{"type": "CHARACTER_STATE", "parameters": {"health": "<0.5"}}
				]
			})
		"battle_won":
			encounters.append({
				"encounter_id": "battle_loot_encounter",
				"conditions": [
					{"type": "PROGRESS_HISTORY", "parameters": {"recent_battle": true}},
					{"type": "CHARACTER_STATE", "parameters": {"luck": ">30"}}
				]
			})
		"weather":
			encounters.append({
				"encounter_id": "weather_storm_encounter",
				"conditions": [
					{"type": "TEMPORAL_ENVIRONMENT", "parameters": {"weather": "storm"}},
					{"type": "CHARACTER_STATE", "parameters": {"position_near_shelter": false}}
				]
			})
	
	return encounters

# 测试函数
func test_trigger_mechanisms():
	print("开始测试触发机制...")
	
	# 创建测试区域数据
	var test_zones = [
		{
			"encounter_id": "test_encounter_1",
			"zone_id": "zone_1",
			"position": Vector2(100, 100),
			"size": Vector2(50, 50),
			"conditions": [
				{"type": "CHARACTER_STATE", "parameters": {"luck": ">20"}}
			]
		}
	]
	
	# 注册区域触发器
	register_zone_triggers(test_zones)
	
	# 模拟玩家进入区域
	on_player_entered_zone("zone_1")
	
	# 测试事件钩子
	handle_global_events("rest_started")
	handle_global_events("battle_won")
	handle_global_events("weather_changed", {"new_weather": "rain"})
	
	print("触发机制测试完成")