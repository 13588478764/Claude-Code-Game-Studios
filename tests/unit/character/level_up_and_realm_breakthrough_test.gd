# 升级与境界突破单元测试
# 验证分段指数升级曲线、境界突破机制、属性点分配和升级特效

extends Node

# 导入需要测试的脚本
var LevelUpManager = load("res://src/scripts/character/level_up_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行升级与境界突破单元测试...")
	
	# 运行分段指数升级曲线测试
	test_exp_curve_early_stage()
	test_exp_curve_mid_stage()
	test_exp_curve_late_stage()
	test_exp_curve_progression()
	
	# 运行境界突破机制测试
	test_realm_breakthrough_at_level_10()
	test_realm_breakthrough_at_level_20()
	test_realm_breakthrough_multiple_levels()
	
	# 运行属性点分配机制测试
	test_attribute_points_allocation()
	test_talent_points_allocation()
	test_points_allocation_on_realm_breakthrough()
	
	# 运行升级检查和执行测试
	test_level_up_check()
	test_perform_level_up()
	test_multiple_level_ups()
	
	# 运行角色信息获取测试
	test_character_info()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试初期等级曲线
func test_exp_curve_early_stage():
	var level_up_manager = LevelUpManager.new()
	
	# 测试1-10级（初期线性）
	var exp_for_level_5 = level_up_manager.get_exp_for_level(5, 100)
	var expected = int(100 * pow(5, 1.0))  # 100 * 5 = 500
	
	assert(exp_for_level_5 == expected, "初期等级曲线应为线性增长")
	
	print("✓ 初期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试中期等级曲线
func test_exp_curve_mid_stage():
	var level_up_manager = LevelUpManager.new()
	
	# 测试15级（中期温和指数）
	var exp_for_level_15 = level_up_manager.get_exp_for_level(15, 150)
	var expected = int(150 * pow(15, 1.5))
	
	assert(exp_for_level_15 == expected, "中期等级曲线应为温和指数增长")
	
	print("✓ 中期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试后期等级曲线
func test_exp_curve_late_stage():
	var level_up_manager = LevelUpManager.new()
	
	# 测试35级（后期陡峭指数）
	var exp_for_level_35 = level_up_manager.get_exp_for_level(35, 200)
	var expected = int(200 * pow(35, 2.5))
	
	assert(exp_for_level_35 == expected, "后期等级曲线应为陡峭指数增长")
	
	print("✓ 后期等级曲线测试通过")
	tests_passed += 1
	tests_total += 1

# 测试等级曲线的阶段性
func test_exp_curve_progression():
	var level_up_manager = LevelUpManager.new()
	
	# 测试不同阶段的等级曲线系数
	var early_coeff = level_up_manager.get_exponent_coefficient_for_level(5)   # 应为EXP_CURVE_EARLY
	var mid_coeff = level_up_manager.get_exponent_coefficient_for_level(15)    # 应为EXP_CURVE_MID
	var late_coeff = level_up_manager.get_exponent_coefficient_for_level(35)  # 应为EXP_CURVE_LATE
	
	assert(early_coeff == level_up_manager.EXP_CURVE_EARLY, "1-10级应使用初期系数")
	assert(mid_coeff == level_up_manager.EXP_CURVE_MID, "11-30级应使用中期系数")
	assert(late_coeff == level_up_manager.EXP_CURVE_LATE, "31级以上应使用后期系数")
	
	print("✓ 等级曲线阶段性测试通过")
	tests_passed += 3
	tests_total += 3

# 测试等级10时的境界突破
func test_realm_breakthrough_at_level_10():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player1", 9)
	
	# 添加足够的经验以达到10级
	var exp_needed_for_level_10 = level_up_manager.get_exp_for_level(10, 100)
	level_up_manager.add_exp("player1", exp_needed_for_level_10)
	
	# 检查角色信息
	var char_info = level_up_manager.get_character_info("player1")
	
	assert(char_info.level == 10, "角色应达到10级")
	assert(char_info.realm_index == 1, "角色应突破到筑基境界")
	assert(char_info.attribute_points >= 50, "角色应获得额外属性点")  # 9级*5 + 10级突破额外10点
	
	print("✓ 等级10境界突破测试通过")
	tests_passed += 3
	tests_total += 3

# 测试等级20时的境界突破
func test_realm_breakthrough_at_level_20():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player2", 19)
	
	# 添加足够的经验以达到20级
	var exp_needed_for_level_20 = level_up_manager.get_exp_for_level(20, 100)
	level_up_manager.add_exp("player2", exp_needed_for_level_20)
	
	# 检查角色信息
	var char_info = level_up_manager.get_character_info("player2")
	
	assert(char_info.level == 20, "角色应达到20级")
	assert(char_info.realm_index == 2, "角色应突破到金丹境界")
	assert(char_info.realm == "金丹", "角色境界名称应为金丹")
	
	print("✓ 等级20境界突破测试通过")
	tests_passed += 3
	tests_total += 3

# 测试多级境界突破
func test_realm_breakthrough_multiple_levels():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player3", 1)
	
	# 添加大量经验以跨越多个境界
	for i in range(1, 31):  # 从1级升到30级
		var exp_needed = level_up_manager.get_exp_for_level(i, 100)
		level_up_manager.add_exp("player3", exp_needed)
	
	# 检查角色信息
	var char_info = level_up_manager.get_character_info("player3")
	
	assert(char_info.level == 30, "角色应达到30级")
	assert(char_info.realm_index >= 2, "角色应至少突破到金丹境界")
	
	print("✓ 多级境界突破测试通过")
	tests_passed += 3
	tests_total += 3

# 测试属性点分配
func test_attribute_points_allocation():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player4", 1)
	
	# 添加经验以升级
	var exp_needed = level_up_manager.get_exp_for_level(2, 100)
	level_up_manager.add_exp("player4", exp_needed)
	
	# 检查属性点
	var char_info = level_up_manager.get_character_info("player4")
	
	assert(char_info.attribute_points == 5, "角色应获得5点属性点")
	
	print("✓ 属性点分配测试通过")
	tests_passed += 1
	tests_total += 1

# 测试天赋点分配
func test_talent_points_allocation():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player5", 1)
	
	# 添加经验以升级
	var exp_needed = level_up_manager.get_exp_for_level(3, 100)
	level_up_manager.add_exp("player5", exp_needed)
	
	# 检查天赋点
	var char_info = level_up_manager.get_character_info("player5")
	
	assert(char_info.talent_points == 3, "角色应获得3点天赋点（3级）")
	
	print("✓ 天赋点分配测试通过")
	tests_passed += 1
	tests_total += 1

# 测试境界突破时的额外点数分配
func test_points_allocation_on_realm_breakthrough():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player6", 9)
	
	# 添加经验以达到境界突破
	var exp_needed = level_up_manager.get_exp_for_level(10, 100)
	level_up_manager.add_exp("player6", exp_needed)
	
	# 检查境界突破时的额外点数
	var char_info = level_up_manager.get_character_info("player6")
	
	# 9级时已获得45点属性点(9*5)，10级时获得5点，境界突破时获得10点额外属性点，总计60点
	var expected_attribute_points = 60  # (9级*5) + (10级*5) + (境界突破额外10点) - (10级升级消耗5点)
	assert(char_info.attribute_points >= 55, "境界突破时应获得额外属性点")  # 9级*5 + 10级5点 + 突破10点额外
	
	print("✓ 境界突破点数分配测试通过")
	tests_passed += 1
	tests_total += 1

# 测试升级检查
func test_level_up_check():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player7", 1)
	
	# 检查是否可以升级（此时不应能升级）
	var can_level_up = level_up_manager.check_level_up("player7")
	assert(not can_level_up, "初始角色不应能升级")
	
	# 添加足够的经验
	var exp_needed = level_up_manager.get_exp_for_level(2, 100)
	level_up_manager.add_exp("player7", exp_needed)
	
	# 再次检查是否可以升级
	can_level_up = level_up_manager.check_level_up("player7")
	assert(can_level_up, "有足够经验的角色应能升级")
	
	print("✓ 升级检查测试通过")
	tests_passed += 2
	tests_total += 2

# 测试执行升级
func test_perform_level_up():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player8", 1)
	
	# 添加足够的经验
	var exp_needed = level_up_manager.get_exp_for_level(2, 100)
	level_up_manager.add_exp("player8", exp_needed)
	
	# 执行升级
	var success = level_up_manager.perform_level_up("player8")
	
	assert(success, "升级应成功执行")
	
	# 检查角色等级
	var char_info = level_up_manager.get_character_info("player8")
	assert(char_info.level == 2, "角色等级应为2")
	
	print("✓ 执行升级测试通过")
	tests_passed += 2
	tests_total += 2

# 测试多次升级
func test_multiple_level_ups():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player9", 1)
	
	# 添加大量经验以进行多次升级
	for i in range(1, 6):  # 从1级升到5级
		var exp_needed = level_up_manager.get_exp_for_level(i, 100)
		level_up_manager.add_exp("player9", exp_needed)
	
	# 检查角色等级
	var char_info = level_up_manager.get_character_info("player9")
	assert(char_info.level == 5, "角色等级应为5")
	assert(char_info.attribute_points >= 20, "角色应获得足够的属性点")  # 4次升级，每次5点属性点
	
	print("✓ 多次升级测试通过")
	tests_passed += 2
	tests_total += 2

# 测试角色信息获取
func test_character_info():
	var level_up_manager = LevelUpManager.new()
	
	# 初始化角色
	level_up_manager.initialize_character("player10", 1)
	
	# 添加一些经验
	var exp_needed = level_up_manager.get_exp_for_level(2, 100)
	level_up_manager.add_exp("player10", exp_needed)
	
	# 获取角色信息
	var char_info = level_up_manager.get_character_info("player10")
	
	# 验证返回的字典包含所有必要字段
	assert(char_info.has("level"), "角色信息应包含等级")
	assert(char_info.has("current_exp"), "角色信息应包含当前经验")
	assert(char_info.has("total_exp"), "角色信息应包含总经验")
	assert(char_info.has("realm"), "角色信息应包含境界")
	assert(char_info.has("realm_index"), "角色信息应包含境界索引")
	assert(char_info.has("attribute_points"), "角色信息应包含属性点")
	assert(char_info.has("talent_points"), "角色信息应包含天赋点")
	assert(char_info.has("exp_to_next_level"), "角色信息应包含到下级经验")
	
	assert(char_info.level == 2, "角色等级应为2")
	assert(char_info.attribute_points == 5, "角色应有5点属性点")
	assert(char_info.talent_points == 1, "角色应有1点天赋点")
	
	print("✓ 角色信息获取测试通过")
	tests_passed += 9
	tests_total += 9
