# 兴趣点追踪功能单元测试
# 测试POI管理器的功能

extends Node

# 导入要测试的脚本
var POIManager = load("res://src/scripts/world/poi_manager.gd")
var POIMarker = load("res://src/scripts/ui/poi_marker.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("运行兴趣点追踪功能测试...")
	
	# 测试1: POI管理器初始化
	test_poi_manager_initialization()
	
	# 测试2: 注册兴趣点
	test_register_poi()
	
	# 测试3: 兴趣点发现机制
	test_poi_discovery_mechanism()
	
	# 测试4: 感知技能功能
	test_perception_skill_functionality()
	
	# 测试5: 兴趣点状态管理
	test_poi_status_management()
	
	# 测试6: POI标记系统
	test_poi_marker_system()
	
	print("兴趣点追踪功能测试完成: %d/%d 通过" % [tests_passed, tests_total])

# 测试POI管理器初始化
func test_poi_manager_initialization():
	var manager = POIManager.new()
	
	assert(manager != null, "POI管理器应成功创建")
	assert(manager.pois.size() == 0, "初始时POI字典应为空")
	assert(manager.player_perception == 50, "默认感知值应为50")
	
	print("✓ POI管理器初始化测试通过")
	tests_passed += 3
	tests_total += 3

# 测试注册兴趣点
func test_register_poi():
	var manager = POIManager.new()
	
	# 测试注册正常POI
	var result1 = manager.register_poi(
		"test_poi_1", 
		Vector2(100, 100), 
		manager.POI_TYPE.RESOURCE_NODE, 
		"测试资源点", 
		"这是一个测试资源点"
	)
	assert(result1 == true, "应能成功注册POI")
	
	# 测试重复注册同一ID
	var result2 = manager.register_poi(
		"test_poi_1", 
		Vector2(200, 200), 
		manager.POI_TYPE.QUEST_TARGET, 
		"重复注册", 
		"重复注册测试"
	)
	assert(result2 == false, "不应能重复注册相同ID的POI")
	
	# 测试获取POI信息
	var poi_info = manager.get_poi_info("test_poi_1")
	assert(poi_info.size() > 0, "应能获取已注册POI的信息")
	assert(poi_info.name == "测试资源点", "POI名称应匹配")
	
	print("✓ 注册兴趣点测试通过")
	tests_passed += 4
	tests_total += 4

# 测试兴趣点发现机制
func test_poi_discovery_mechanism():
	var manager = POIManager.new()
	
	# 创建一个虚拟玩家节点
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册一个近距离的POI（在发现半径内）
	var result1 = manager.register_poi(
		"nearby_poi", 
		Vector2(30, 0),  # 在30像素距离
		manager.POI_TYPE.RESOURCE_NODE, 
		"附近资源点", 
		"距离玩家30像素的资源点",
		false,  # 不是隐藏点
		50.0    # 发现半径50像素
	)
	assert(result1 == true, "应能成功注册附近POI")
	
	# 检查附近POI（这会自动发现距离内的POI）
	manager.check_nearby_pois()
	
	# 验证POI已被发现
	var poi_info = manager.get_poi_info("nearby_poi")
	assert(poi_info.status == manager.POI_STATUS.DISCOVERED, "附近POI应被自动发现")
	
	# 注册一个远距离的POI（在发现半径外）
	var result2 = manager.register_poi(
		"distant_poi", 
		Vector2(100, 0),  # 在100像素距离
		manager.POI_TYPE.QUEST_TARGET, 
		"远距离目标", 
		"距离玩家100像素的目标",
		false,  // 不是隐藏点
		50.0    // 发现半径50像素
	)
	assert(result2 == true, "应能成功注册远距离POI")
	
	# 检查附近POI（远距离POI不应被发现）
	manager.check_nearby_pois()
	
	# 验证远距离POI未被发现
	var distant_info = manager.get_poi_info("distant_poi")
	assert(distant_info.status == manager.POI_STATUS.UNDISCOVERED, "远距离POI不应被发现")
	
	print("✓ 兴趣点发现机制测试通过")
	tests_passed += 5
	tests_total += 5

# 测试感知技能功能
func test_perception_skill_functionality():
	var manager = POIManager.new()
	
	# 创建一个虚拟玩家节点
	var dummy_player = Node2D.new()
	dummy_player.position = Vector2(0, 0)
	manager.set_player_node(dummy_player)
	
	# 注册一个隐藏的POI（需要技能才能发现）
	var result1 = manager.register_poi(
		"hidden_poi", 
		Vector2(60, 0),  // 在60像素距离，小于技能范围
		manager.POI_TYPE.SECRET_ENCOUNTER, 
		"隐藏奇遇点", 
		"需要技能才能发现的奇遇点",
		true,   // 是隐藏点
		0.0,    // 无自动发现半径
		30      // 需要30点感知才能发现
	)
	assert(result1 == true, "应能成功注册隐藏POI")
	
	# 设置玩家感知低于要求
	manager.set_player_perception(20)
	
	# 检查附近POI（由于感知不足，隐藏POI不应被发现）
	manager.check_nearby_pois()
	var poi_info = manager.get_poi_info("hidden_poi")
	assert(poi_info.status == manager.POI_STATUS.UNDISCOVERED, "感知不足时隐藏POI不应被发现")
	
	# 使用感知技能
	var skill_used = manager.use_perception_skill()
	assert(skill_used == true, "应能成功使用感知技能")
	
	# 检查POI状态（现在应该被发现了）
	poi_info = manager.get_poi_info("hidden_poi")
	assert(poi_info.status == manager.POI_STATUS.DISCOVERED, "使用感知技能后隐藏POI应被发现")
	
	# 检查技能冷却
	assert(manager.get_perception_skill_cooldown() > 0, "使用技能后应有冷却时间")
	
	print("✓ 感知技能功能测试通过")
	tests_passed += 5
	tests_total += 5

# 测试兴趣点状态管理
func test_poi_status_management():
	var manager = POIManager.new()
	
	# 注册一个POI
	var result1 = manager.register_poi(
		"status_test_poi", 
		Vector2(50, 50), 
		manager.POI_TYPE.FACILITY, 
		"状态测试点", 
		"用于测试状态转换的POI"
	)
	assert(result1 == true, "应能成功注册状态测试POI")
	
	# 获取初始状态
	var initial_info = manager.get_poi_info("status_test_poi")
	assert(initial_info.status == manager.POI_STATUS.UNDISCOVERED, "POI初始状态应为未发现")
	
	# 激活POI
	var activate_result = manager.activate_poi("status_test_poi")
	assert(activate_result == false, "未发现的POI不能被激活")
	
	# 手动设置为已发现状态
	manager._set_poi_status("status_test_poi", manager.POI_STATUS.DISCOVERED)
	var after_discover_info = manager.get_poi_info("status_test_poi")
	assert(after_discover_info.status == manager.POI_STATUS.DISCOVERED, "手动设置后状态应为已发现")
	
	# 激活POI
	var activate_result2 = manager.activate_poi("status_test_poi")
	assert(activate_result2 == true, "已发现的POI应能被激活")
	
	var after_activate_info = manager.get_poi_info("status_test_poi")
	assert(after_activate_info.status == manager.POI_STATUS.ACTIVATED, "激活后状态应为已激活")
	
	# 完成POI
	var complete_result = manager.complete_poi("status_test_poi")
	assert(complete_result == true, "已激活的POI应能被完成")
	
	var after_complete_info = manager.get_poi_info("status_test_poi")
	assert(after_complete_info.status == manager.POI_STATUS.COMPLETED, "完成后状态应为已完成")
	
	print("✓ 兴趣点状态管理测试通过")
	tests_passed += 7
	tests_total += 7

# 测试POI标记系统
func test_poi_marker_system():
	var marker = POIMarker.new()
	
	assert(marker != null, "POI标记应成功创建")
	
	# 测试初始状态
	assert(marker.poi_status == marker.POI_STATUS.UNDISCOVERED, "POI标记初始状态应为未发现")
	assert(marker.poi_type == marker.POI_TYPE.RESOURCE_NODE, "POI标记初始类型应为资源点")
	
	# 测试更新状态
	marker.update_status(marker.POI_STATUS.DISCOVERED)
	assert(marker.poi_status == marker.POI_STATUS.DISCOVERED, "更新后状态应为已发现")
	
	# 测试更新类型
	marker.update_type(marker.POI_TYPE.QUEST_TARGET)
	assert(marker.poi_type == marker.POI_TYPE.QUEST_TARGET, "更新后类型应为目标")
	
	# 测试任务相关设置
	marker.set_quest_related(true)
	assert(marker.z_index == 200, "任务相关POI的z_index应为200")
	
	marker.set_quest_related(false)
	assert(marker.z_index == 100, "非任务相关POI的z_index应为100")
	
	print("✓ POI标记系统测试通过")
	tests_passed += 6
	tests_total += 6

# 断言函数
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("断言失败: " + message)
	
	tests_total += 1