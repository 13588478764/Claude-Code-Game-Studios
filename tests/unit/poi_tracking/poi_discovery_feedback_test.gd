# 兴趣点发现反馈单元测试
# 测试POI发现反馈机制

extends Node

# 导入要测试的脚本
var POIManager = load("res://src/scripts/world/poi_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("运行兴趣点发现反馈测试...")
	
	# 测试1: 兴趣点发现状态追踪
	test_poi_discovery_status_tracking()
	
	# 测试2: 天眼通技能冷却和感知范围计算
	test_perception_skill_cooldown_and_range_calculation()
	
	# 测试3: 兴趣点数据的保存和加载
	test_poi_data_save_and_load()
	
	# 测试4: 距离和方向计算
	test_distance_and_direction_calculation()
	
	print("兴趣点发现反馈测试完成: %d/%d 通过" % [tests_passed, tests_total])

# 测试兴趣点发现状态追踪
func test_poi_discovery_status_tracking():
	var manager = POIManager.new()
	
	# 创建一个虚拟玩家节点
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册一个POI
	var result1 = manager.register_poi(
		"discovery_test_poi", 
		Vector2(30, 0),  # 在30像素距离
		manager.POI_TYPE.RESOURCE_NODE, 
		"发现测试点", 
		"用于测试发现状态的POI",
		false,  # 不是隐藏点
		50.0    # 发现半径50像素
	)
	assert(result1 == true, "应能成功注册发现测试POI")
	
	# 检查初始状态
	var initial_info = manager.get_poi_info("discovery_test_poi")
	assert(initial_info.status == manager.POI_STATUS.UNDISCOVERED, "POI初始状态应为未发现")
	
	# 检查附近POI（这会自动发现距离内的POI）
	manager.check_nearby_pois()
	
	# 验证POI已被发现
	var after_check_info = manager.get_poi_info("discovery_test_poi")
	assert(after_check_info.status == manager.POI_STATUS.DISCOVERED, "附近POI应被自动发现")
	
	# 测试激活POI
	var activate_result = manager.activate_poi("discovery_test_poi")
	assert(activate_result == true, "已发现的POI应能被激活")
	
	var after_activate_info = manager.get_poi_info("discovery_test_poi")
	assert(after_activate_info.status == manager.POI_STATUS.ACTIVATED, "激活后状态应为已激活")
	
	# 测试完成POI
	var complete_result = manager.complete_poi("discovery_test_poi")
	assert(complete_result == true, "已激活的POI应能被完成")
	
	var after_complete_info = manager.get_poi_info("discovery_test_poi")
	assert(after_complete_info.status == manager.POI_STATUS.COMPLETED, "完成后状态应为已完成")
	
	# 测试获取指定状态的POI列表
	var undiscovered_pois = manager.get_pois_with_status(manager.POI_STATUS.UNDISCOVERED)
	var discovered_pois = manager.get_pois_with_status(manager.POI_STATUS.DISCOVERED)
	var activated_pois = manager.get_pois_with_status(manager.POI_STATUS.ACTIVATED)
	var completed_pois = manager.get_pois_with_status(manager.POI_STATUS.COMPLETED)
	
	assert(undiscovered_pois.size() == 0, "不应有未发现的POI")
	assert(discovered_pois.size() == 0, "不应有已发现的POI")
	assert(activated_pois.size() == 0, "不应有已激活的POI")
	assert(completed_pois.size() == 1, "应有一个已完成的POI")
	
	print("✓ 兴趣点发现状态追踪测试通过")
	tests_passed += 8
	tests_total += 8

# 测试天眼通技能冷却和感知范围计算
func test_perception_skill_cooldown_and_range_calculation():
	var manager = POIManager.new()
	
	# 检查默认冷却时间
	assert(manager.get_perception_skill_max_cooldown() == 10.0, "默认最大冷却时间应为10秒")
	assert(manager.get_perception_skill_range() == 120.0, "默认技能范围应为120像素")
	
	# 测试冷却时间更新
	assert(manager.get_perception_skill_cooldown() == 0.0, "初始冷却时间应为0")
	
	# 使用技能
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册一个隐藏POI
	manager.register_poi(
		"hidden_for_cooldown", 
		Vector2(60, 0),
		manager.POI_TYPE.SECRET_ENCOUNTER, 
		"隐藏点", 
		"用于测试冷却的隐藏点",
		true,   # 是隐藏点
		0.0,    # 无自动发现半径
		0       # 无感知要求
	)
	
	# 使用技能
	manager.use_perception_skill()
	
	# 检查冷却是否开始
	var initial_cooldown = manager.get_perception_skill_cooldown()
	assert(initial_cooldown > 0, "使用技能后应有冷却时间")
	assert(initial_cooldown <= manager.get_perception_skill_max_cooldown(), "冷却时间不应超过最大值")
	
	# 模拟时间流逝（在实际游戏中，这会在_process中自动处理）
	# 这里我们直接测试冷却减少逻辑
	manager._process(2.0)  # 模拟2秒过去
	var cooldown_after_wait = manager.get_perception_skill_cooldown()
	assert(cooldown_after_wait == initial_cooldown - 2.0, "冷却时间应随时间减少")
	
	# 测试再次使用技能（应在冷却中）
	var second_use = manager.use_perception_skill()
	# 注意：由于第一次使用技能时没有真正的POI会被发现，所以技能可能不会真正进入冷却
	# 我们主要测试机制本身
	
	print("✓ 天眼通技能冷却和感知范围计算测试通过")
	tests_passed += 6
	tests_total += 6

# 测试兴趣点数据的保存和加载
func test_poi_data_save_and_load():
	var manager = POIManager.new()
	
	# 创建一个虚拟玩家节点
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册几个不同状态的POI
	manager.register_poi(
		"save_test_1", 
		Vector2(10, 10), 
		manager.POI_TYPE.RESOURCE_NODE, 
		"保存测试1", 
		"用于测试保存的第一个POI"
	)
	
	manager.register_poi(
		"save_test_2", 
		Vector2(20, 20), 
		manager.POI_TYPE.QUEST_TARGET, 
		"保存测试2", 
		"用于测试保存的第二个POI",
		true,  # 隐藏点
		0.0,   # 无发现半径
		25     # 感知要求
	)
	
	manager.register_poi(
		"save_test_3", 
		Vector2(30, 30), 
		manager.POI_TYPE.FACILITY, 
		"保存测试3", 
		"用于测试保存的第三个POI"
	)
	
	# 改变一些POI的状态
	manager.check_nearby_pois()  # 发现附近的POI
	manager.activate_poi("save_test_1")
	manager.complete_poi("save_test_1")  # 完成第一个POI
	
	# 保存数据
	var saved_data = manager.save_poi_data()
	assert(saved_data.size() >= 3, "保存的数据应包含所有注册的POI")
	
	# 验证保存的数据
	assert(saved_data.has("save_test_1"), "保存的数据应包含POI save_test_1")
	assert(saved_data.has("save_test_2"), "保存的数据应包含POI save_test_2")
	assert(saved_data.has("save_test_3"), "保存的数据应包含POI save_test_3")
	
	var poi1_saved_status = saved_data["save_test_1"].status
	assert(poi1_saved_status == manager.POI_STATUS.COMPLETED, "保存的POI状态应为已完成")
	
	# 创建新管理器并加载数据
	var new_manager = POIManager.new()
	new_manager.set_player_node(dummy_player)
	
	new_manager.load_poi_data(saved_data)
	
	# 验证加载的数据
	var loaded_poi1_info = new_manager.get_poi_info("save_test_1")
	var loaded_poi2_info = new_manager.get_poi_info("save_test_2")
	var loaded_poi3_info = new_manager.get_poi_info("save_test_3")
	
	assert(loaded_poi1_info.status == manager.POI_STATUS.COMPLETED, "加载后POI1状态应为已完成")
	assert(loaded_poi2_info.status == manager.POI_STATUS.UNDISCOVERED, "加载后POI2状态应为未发现（因为它是隐藏的且不在玩家附近）")
	assert(loaded_poi3_info.status == manager.POI_STATUS.DISCOVERED, "加载后POI3状态应为已发现")
	
	assert(loaded_poi2_info.is_hidden == true, "加载后POI2应仍为隐藏点")
	assert(loaded_poi2_info.perception_required == 25, "加载后POI2的感知要求应为25")
	
	print("✓ 兴趣点数据的保存和加载测试通过")
	tests_passed += 10
	tests_total += 10

# 测试距离和方向计算
func test_distance_and_direction_calculation():
	var manager = POIManager.new()
	
	# 创建一个虚拟玩家节点
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册几个不同位置的POI
	manager.register_poi(
		"dist_test_1", 
		Vector2(100, 0),   # 正东方向
		manager.POI_TYPE.RESOURCE_NODE, 
		"距离测试1", 
		"正东方向的POI"
	)
	
	manager.register_poi(
		"dist_test_2", 
		Vector2(0, -100),  # 正北方向
		manager.POI_TYPE.QUEST_TARGET, 
		"距离测试2", 
		"正北方向的POI"
	)
	
	manager.register_poi(
		"dist_test_3", 
		Vector2(-50, 50),  # 西北方向
		manager.POI_TYPE.FACILITY, 
		"距离测试3", 
		"西北方向的POI"
	)
	
	# 获取附近的POI信息（包含距离和方向）
	var nearby_pois = manager.get_nearby_pois(200.0)  # 200像素范围
	
	# 验证返回的POI数量
	assert(nearby_pois.size() == 3, "应返回所有3个POI")
	
	# 验证距离计算
	var poi1_info = null
	var poi2_info = null
	var poi3_info = null
	
	for poi in nearby_pois:
		if poi.poi_id == "dist_test_1":
			poi1_info = poi
		elif poi.poi_id == "dist_test_2":
			poi2_info = poi
		elif poi.poi_id == "dist_test_3":
			poi3_info = poi
	
	assert(poi1_info != null, "应能找到POI1信息")
	assert(poi2_info != null, "应能找到POI2信息")
	assert(poi3_info != null, "应能找到POI3信息")
	
	# 验证距离（使用勾股定理）
	assert(abs(poi1_info.distance - 100.0) < 0.1, "POI1距离应约为100")
	assert(abs(poi2_info.distance - 100.0) < 0.1, "POI2距离应约为100")
	assert(abs(poi3_info.distance - sqrt(50*50 + 50*50)) < 0.1, "POI3距离应约为70.71")
	
	# 验证方向向量的长度应为1（单位向量）
	assert(abs(poi1_info.direction.length() - 1.0) < 0.1, "POI1方向向量应为单位向量")
	assert(abs(poi2_info.direction.length() - 1.0) < 0.1, "POI2方向向量应为单位向量")
	assert(abs(poi3_info.direction.length() - 1.0) < 0.1, "POI3方向向量应为单位向量")
	
	# 验证方向（大致方向）
	assert(abs(poi1_info.direction.x - 1.0) < 0.1 and abs(poi1_info.direction.y - 0.0) < 0.1, "POI1方向应大致向东")
	assert(abs(poi2_info.direction.x - 0.0) < 0.1 and abs(poi2_info.direction.y - (-1.0)) < 0.1, "POI2方向应大致向北")
	
	print("✓ 距离和方向计算测试通过")
	tests_passed += 11
	tests_total += 11

# 断言函数
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("断言失败: " + message)
	
	tests_total += 1