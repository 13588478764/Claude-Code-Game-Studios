# 武侠奇遇录 - 奇遇集成系统集成测试
# 测试奇遇触发概率计算、奇遇类型判定、奖励发放和一次性奇遇状态记录

extends "res://addons/gut/test.gd"

# 测试用例变量
var character_system = null
var encounter_integration = null
var item_manager = null

func before_all():
	"""在所有测试之前运行"""
	pass

func after_all():
	"""在所有测试之后运行"""
	pass

func before_each():
	"""在每个测试之前运行"""
	# 创建角色系统实例
	character_system = load("res://src/scripts/character/character_system.gd").new()
	character_system.initialize_character()
	
	# 创建物品管理器实例
	item_manager = load("res://src/scripts/economy/item_manager.gd").new()
	
	# 创建奇遇集成管理器实例
	encounter_integration = load("res://src/scripts/encounter/encounter_integration.gd").new()
	encounter_integration.initialize(character_system, null, item_manager)

func after_each():
	"""在每个测试之后运行"""
	character_system = null
	encounter_integration = null
	item_manager = null

# 测试用例1: 奇遇触发概率计算正确
func test_encounter_probability_calculation_works():
	"""AC-1: 奇遇触发概率计算正确"""
	# Given: 基础概率为0.03（3%），角色福缘为50
	var base_probability = 0.03
	character_system.attributes.luck = 50
	
	# When: 计算奇遇触发概率
	var encounter_probability = encounter_integration.calculate_encounter_probability(base_probability)
	
	# Then: 触发概率 = 0.03 × (1 + 50/100) = 0.03 × 1.5 = 0.045（4.5%）
	assert_almost_eq(encounter_probability, 0.045, 0.001)
	
	# 测试福缘为0的情况
	character_system.attributes.luck = 0
	encounter_probability = encounter_integration.calculate_encounter_probability(base_probability)
	assert_almost_eq(encounter_probability, 0.03, 0.001)
	
	# 测试福缘为100的情况
	character_system.attributes.luck = 100
	encounter_probability = encounter_integration.calculate_encounter_probability(base_probability)
	# 0.03 × (1 + 100/100) = 0.03 × 2 = 0.06
	assert_almost_eq(encounter_probability, 0.06, 0.001)
	
	# 测试概率超过上限10%的情况
	base_probability = 0.08
	character_system.attributes.luck = 100
	encounter_probability = encounter_integration.calculate_encounter_probability(base_probability)
	# 0.08 × 2 = 0.16，但上限为0.1
	assert_almost_eq(encounter_probability, 0.1, 0.001)

# 测试用例2: 奇遇类型判定正常工作
func test_encounter_type_determination_works():
	"""AC-2: 奇遇类型判定正常工作"""
	# Given: 触发奇遇事件
	# When: 根据随机数判定奇遇类型
	# Then: 返回5种奇遇类型之一
	
	var encounter_types = [
		"wise_master_guidance",
		"secret_realm_discovery",
		"heavenly_treasure",
		"lost_martial_scroll",
		"jianghu_rumor"
	]
	
	# 测试多次以确保所有类型都能触发
	var type_counts = {}
	for type in encounter_types:
		type_counts[type] = 0
	
	# 运行100次
	for i in range(100):
		var encounter_type = encounter_integration.determine_encounter_type()
		assert_true(encounter_types.has(encounter_type), "返回的奇遇类型应该在预定义列表中")
		type_counts[encounter_type] += 1
	
	# 验证所有类型都至少触发过一次（概率上应该如此）
	for type in encounter_types:
		assert_gt(type_counts[type], 0, "每种奇遇类型都应该至少触发一次")

# 测试用例3: 奖励发放机制正确
func test_reward_granting_mechanism_works():
	"""AC-3: 奖励发放机制正确"""
	# Given: 触发"高人指点"奇遇
	var encounter_type = "wise_master_guidance"
	var encounter_data = {"type": encounter_type, "id": "test_001"}
	
	# 记录初始属性点
	var initial_attribute_points = character_system.total_attribute_points
	
	# When: 发放奖励（2-5点属性点）
	var result = encounter_integration.grant_encounter_rewards(encounter_type, encounter_data)
	
	# Then: 角色获得对应数量的自由属性点
	assert_true(result)
	var gained_points = character_system.total_attribute_points - initial_attribute_points
	assert_true(gained_points >= 2, "至少获得2点属性点")
	assert_true(gained_points <= 5, "最多获得5点属性点")
	
	# 测试秘境发现奖励（EXP）
	encounter_type = "secret_realm_discovery"
	encounter_data = {"type": encounter_type, "id": "test_002"}
	var initial_exp = character_system.experience
	result = encounter_integration.grant_encounter_rewards(encounter_type, encounter_data)
	assert_true(result)
	var gained_exp = character_system.experience - initial_exp
	assert_true(gained_exp >= 500, "至少获得500点经验值")
	assert_true(gained_exp <= 1000, "最多获得1000点经验值")
	
	# 测试天材地宝奖励（物品）
	encounter_type = "heavenly_treasure"
	encounter_data = {"type": encounter_type, "id": "test_003"}
	var initial_wash_marrow_pill = item_manager.get_item_count("wash_marrow_pill")
	var initial_breakthrough_pill = item_manager.get_item_count("breakthrough_pill")
	result = encounter_integration.grant_encounter_rewards(encounter_type, encounter_data)
	assert_true(result)
	var total_pills = item_manager.get_item_count("wash_marrow_pill") + item_manager.get_item_count("breakthrough_pill")
	var initial_total = initial_wash_marrow_pill + initial_breakthrough_pill
	assert_eq(total_pills, initial_total + 1, "应该获得1个丹药")

# 测试用例4: 一次性奇遇状态记录正确
func test_one_time_encounter_state_recording_works():
	"""AC-4: 一次性奇遇状态记录正确"""
	# Given: 触发一次性奇遇ID为"unique_001"
	var encounter_id = "unique_001"
	
	# 初始状态应该未触发
	assert_false(encounter_integration.check_encounter_triggered(encounter_id))
	
	# When: 记录到triggered_encounters数组
	encounter_integration.mark_encounter_triggered(encounter_id)
	
	# Then: 再次检查时该奇遇已触发
	assert_true(encounter_integration.check_encounter_triggered(encounter_id))
	
	# 测试重复检查
	assert_true(encounter_integration.check_encounter_triggered(encounter_id))
	
	# 测试多个一次性奇遇
	var encounter_id_2 = "unique_002"
	var encounter_id_3 = "unique_003"
	
	encounter_integration.mark_encounter_triggered(encounter_id_2)
	encounter_integration.mark_encounter_triggered(encounter_id_3)
	
	assert_true(encounter_integration.check_encounter_triggered(encounter_id_2))
	assert_true(encounter_integration.check_encounter_triggered(encounter_id_3))
	assert_eq(encounter_integration.triggered_encounters.size(), 3)

# 测试用例5: 完整的奇遇触发流程
func test_complete_encounter_trigger_flow():
	"""测试完整的奇遇触发流程"""
	# 设置角色福缘
	character_system.attributes.luck = 50
	
	# 设置基础概率为100%以确保触发
	var base_probability = 1.0
	
	# 触发奇遇
	var result = encounter_integration.trigger_encounter_with_integration(base_probability, "test_complete_001")
	
	# 验证结果
	assert_true(result["triggered"])
	assert_gt(result["probability"], 0.0)
	assert_ne(result["encounter_type"], "")
	assert_eq(result["encounter_id"], "test_complete_001")
	
	# 验证奇遇已被标记为触发
	assert_true(encounter_integration.check_encounter_triggered("test_complete_001"))
	
	# 再次触发相同ID的奇遇应该不会发放奖励
	var initial_attribute_points = character_system.total_attribute_points
	result = encounter_integration.trigger_encounter_with_integration(base_probability, "test_complete_001")
	# 即使触发，由于已经触发过，不会发放奖励
	assert_eq(character_system.total_attribute_points, initial_attribute_points)

# 测试用例6: 信号系统集成
func test_signal_system_integration():
	"""测试信号系统是否正确发射"""
	var signal_data = {}
	
	# 连接信号
	encounter_integration.connect("encounter_reward_granted", func(reward_type, amount):
		signal_data["reward_type"] = reward_type
		signal_data["amount"] = amount
	)
	
	# 触发奖励发放
	var encounter_type = "wise_master_guidance"
	var encounter_data = {"type": encounter_type, "id": "test_signal_001"}
	encounter_integration.grant_encounter_rewards(encounter_type, encounter_data)
	
	# 等待一帧以确保信号被处理
	await wait_frames(1)
	
	# 验证信号已发射
	assert_true(signal_data.has("reward_type"), "信号应该已发射并设置了 reward_type")
	assert_eq(signal_data["reward_type"], "attribute_points")
	assert_true(signal_data["amount"] >= 2)
	assert_true(signal_data["amount"] <= 5)

# 测试用例7: 边界情况测试
func test_edge_cases():
	"""测试边界情况"""
	# 测试未初始化角色系统的情况
	var uninit_integration = load("res://src/scripts/encounter/encounter_integration.gd").new()
	var probability = uninit_integration.calculate_encounter_probability(0.03)
	assert_eq(probability, 0.03, "未初始化时应返回基础概率")
	
	# 测试极端福缘值
	character_system.attributes.luck = 1000  # 极高福缘
	probability = encounter_integration.calculate_encounter_probability(0.01)
	assert_eq(probability, 0.1, "即使福缘极高，概率也不应超过上限10%")
	
	# 测试负数福缘（理论上不应该发生，但要处理）
	character_system.attributes.luck = -50
	probability = encounter_integration.calculate_encounter_probability(0.05)
	# 0.05 × (1 + (-50)/100) = 0.05 × 0.5 = 0.025
	assert_almost_eq(probability, 0.025, 0.001)