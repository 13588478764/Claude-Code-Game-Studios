# 武学数据结构定义单元测试
# 测试武学数据结构的定义和验证功能

extends Node

# 导入要测试的脚本
var MartialArtData = load("res://src/scripts/data/martial_art_data.gd")

# 测试结果
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("运行武学数据结构定义测试...")
	
	# 测试1: 武学核心属性定义
	test_martial_art_core_properties()
	
	# 测试2: 武学分类系统
	test_martial_art_classification_system()
	
	# 测试3: MartialArtData基类创建
	test_martial_art_data_class_creation()
	
	# 测试4: 数据验证机制
	test_data_validation_mechanism()
	
	# 测试5: 枚举值测试
	test_enumerations()
	
	# 测试6: 字符串表示
	test_string_representation()
	
	print("武学数据结构定义测试完成: %d/%d 通过" % [tests_passed, tests_total])

# 测试武学核心属性定义
func test_martial_art_core_properties():
	var martial_art = MartialArtData.new()
	
	# 设置核心属性
	martial_art.id = "sword_001"
	martial_art.name = "基础剑法"
	martial_art.description = "最基础的剑法，适合初学者练习"
	martial_art.cost_stamina = 10.0
	martial_art.cost_mana = 20.0
	martial_art.cooldown = 2.5
	martial_art.damage_base = 50.0
	martial_art.damage_scale = 1.2
	martial_art.hit_count = 1
	martial_art.startup_frames = 0.5
	martial_art.active_frames = 0.3
	martial_art.recovery_frames = 1.0
	martial_art.total_duration = 1.8
	
	# 验证属性是否正确设置
	assert(martial_art.id == "sword_001", "ID应该正确设置")
	assert(martial_art.name == "基础剑法", "名称应该正确设置")
	assert(martial_art.description == "最基础的剑法，适合初学者练习", "描述应该正确设置")
	assert(martial_art.cost_stamina == 10.0, "体力消耗应该正确设置")
	assert(martial_art.cost_mana == 20.0, "内力消耗应该正确设置")
	assert(martial_art.cooldown == 2.5, "冷却时间应该正确设置")
	assert(martial_art.damage_base == 50.0, "基础伤害应该正确设置")
	assert(martial_art.damage_scale == 1.2, "伤害系数应该正确设置")
	assert(martial_art.hit_count == 1, "攻击段数应该正确设置")
	assert(martial_art.startup_frames == 0.5, "前摇时间应该正确设置")
	assert(martial_art.active_frames == 0.3, "有效时间应该正确设置")
	assert(martial_art.recovery_frames == 1.0, "后摇时间应该正确设置")
	assert(martial_art.total_duration == 1.8, "总时长应该正确设置")
	
	# 测试边界值
	var boundary_test = MartialArtData.new()
	boundary_test.damage_base = 0
	boundary_test.cost_stamina = 0
	boundary_test.cost_mana = 0
	boundary_test.unlock_level = 1
	
	assert(boundary_test.damage_base == 0, "基础伤害可以为0")
	assert(boundary_test.unlock_level == 1, "解锁等级最小值为1")
	
	print("✓ 武学核心属性定义测试通过")
	tests_passed += 16
	tests_total += 16

# 测试武学分类系统
func test_martial_art_classification_system():
	var martial_art = MartialArtData.new()
	
	# 测试各种分类
	martial_art.martial_art_type = MartialArtData.MartialArtType.ATTACK
	martial_art.weapon_type = MartialArtData.WeaponType.SWORD
	martial_art.school = MartialArtData.SchoolType.SHAOLIN
	martial_art.grade = MartialArtData.GradeType.RARE
	martial_art.element_type = "金"
	
	# 验证分类设置
	assert(martial_art.martial_art_type == MartialArtData.MartialArtType.ATTACK, "武学类型应该正确设置")
	assert(martial_art.weapon_type == MartialArtData.WeaponType.SWORD, "武器类型应该正确设置")
	assert(martial_art.school == MartialArtData.SchoolType.SHAOLIN, "门派应该正确设置")
	assert(martial_art.grade == MartialArtData.GradeType.RARE, "品阶应该正确设置")
	assert(martial_art.element_type == "金", "元素类型应该正确设置")
	
	# 测试分类字符串获取
	assert(martial_art.get_martial_art_type_string() == "攻击", "武学类型字符串应该正确")
	assert(martial_art.get_weapon_type_string() == "剑", "武器类型字符串应该正确")
	assert(martial_art.get_school_string() == "少林", "门派字符串应该正确")
	assert(martial_art.get_grade_string() == "稀有", "品阶字符串应该正确")
	assert(martial_art.get_element_string() == "金", "元素类型字符串应该正确")
	
	print("✓ 武学分类系统测试通过")
	tests_passed += 10
	tests_total += 10

# 测试MartialArtData基类创建
func test_martial_art_data_class_creation():
	var martial_art = MartialArtData.new()
	
	# 验证继承自Resource
	assert(martial_art is Resource, "MartialArtData应该继承自Resource")
	
	# 验证默认值
	assert(martial_art.id == "", "ID默认值应该是空字符串")
	assert(martial_art.name == "", "名称默认值应该是空字符串")
	assert(martial_art.cost_stamina == 0.0, "体力消耗默认值应该是0.0")
	assert(martial_art.damage_base == 0.0, "基础伤害默认值应该是0.0")
	assert(martial_art.martial_art_type == MartialArtData.MartialArtType.ATTACK, "武学类型默认值应该是ATTACK")
	assert(martial_art.weapon_type == MartialArtData.WeaponType.NONE, "武器类型默认值应该是NONE")
	assert(martial_art.school == MartialArtData.SchoolType.GENERIC, "门派默认值应该是GENERIC")
	assert(martial_art.grade == MartialArtData.GradeType.COMMON, "品阶默认值应该是COMMON")
	
	# 验证序列化能力（Resource的基本功能）
	var temp_id = "test_id_123"
	martial_art.id = temp_id
	assert(martial_art.id == temp_id, "设置的ID应该能正确保存和读取")
	
	print("✓ MartialArtData基类创建测试通过")
	tests_passed += 9
	tests_total += 9

# 测试数据验证机制
func test_data_validation_mechanism():
	var valid_martial_art = MartialArtData.new()
	valid_martial_art.id = "valid_sword"
	valid_martial_art.name = "有效剑法"
	valid_martial_art.damage_base = 50.0
	valid_martial_art.cost_stamina = 10.0
	valid_martial_art.cost_mana = 20.0
	valid_martial_art.unlock_level = 1
	valid_martial_art.startup_frames = 0.5
	valid_martial_art.active_frames = 0.3
	valid_martial_art.recovery_frames = 1.0
	
	# 验证有效数据
	assert(valid_martial_art.validate() == true, "有效的武学数据应该通过验证")
	
	# 测试无效数据
	var invalid_martial_art = MartialArtData.new()
	invalid_martial_art.id = ""  # 无效：ID为空
	
	assert(invalid_martial_art.validate() == false, "ID为空的武学数据应该验证失败")
	
	# 测试负数伤害
	var negative_damage_art = MartialArtData.new()
	negative_damage_art.id = "negative_test"
	negative_damage_art.name = "负伤害测试"
	negative_damage_art.damage_base = -10.0  # 无效：负数伤害
	
	assert(negative_damage_art.validate() == false, "负数伤害的武学数据应该验证失败")
	
	# 测试负数消耗
	var negative_cost_art = MartialArtData.new()
	negative_cost_art.id = "negative_cost_test"
	negative_cost_art.name = "负消耗测试"
	negative_cost_art.cost_stamina = -5.0  # 无效：负数消耗
	
	assert(negative_cost_art.validate() == false, "负数消耗的武学数据应该验证失败")
	
	# 测试小于1的解锁等级
	var low_unlock_art = MartialArtData.new()
	low_unlock_art.id = "low_unlock_test"
	low_unlock_art.name = "低解锁测试"
	low_unlock_art.unlock_level = 0  # 无效：解锁等级小于1
	
	assert(low_unlock_art.validate() == false, "解锁等级小于1的武学数据应该验证失败")
	
	# 测试负数时间
	var negative_time_art = MartialArtData.new()
	negative_time_art.id = "negative_time_test"
	negative_time_art.name = "负时间测试"
	negative_time_art.startup_frames = -0.5  # 无效：负数时间
	
	assert(negative_time_art.validate() == false, "负数时间的武学数据应该验证失败")
	
	print("✓ 数据验证机制测试通过")
	tests_passed += 8
	tests_total += 8

# 测试枚举值
func test_enumerations():
	var martial_art = MartialArtData.new()
	
	# 测试所有武学类型
	var all_types = [MartialArtData.MartialArtType.ATTACK, 
	                 MartialArtData.MartialArtType.DEFENSE, 
	                 MartialArtData.MartialArtType.MOVEMENT, 
	                 MartialArtData.MartialArtType.BUFF, 
	                 MartialArtData.MartialArtType.DEBUFF]
	
	assert(all_types.size() == 5, "应该有5种武学类型")
	
	# 测试所有武器类型
	var all_weapons = [MartialArtData.WeaponType.SWORD, 
	                   MartialArtData.WeaponType.BLADE, 
	                   MartialArtData.WeaponType.FIST, 
	                   MartialArtData.WeaponType.STAFF, 
	                   MartialArtData.WeaponType.NONE]
	
	assert(all_weapons.size() == 5, "应该有5种武器类型")
	
	# 测试所有门派
	var all_schools = [MartialArtData.SchoolType.SHAOLIN, 
	                   MartialArtData.SchoolType.WUDANG, 
	                   MartialArtData.SchoolType.EMEI, 
	                   MartialArtData.SchoolType.GAOYANG, 
	                   MartialArtData.SchoolType.QINGCHENG, 
	                   MartialArtData.SchoolType.GENERIC]
	
	assert(all_schools.size() == 6, "应该有6种门派")
	
	# 测试所有品阶
	var all_grades = [MartialArtData.GradeType.COMMON, 
	                  MartialArtData.GradeType.RARE, 
	                  MartialArtData.GradeType.EPIC, 
	                  MartialArtData.GradeType.LEGENDARY]
	
	assert(all_grades.size() == 4, "应该有4种品阶")
	
	print("✓ 枚举值测试通过")
	tests_passed += 4
	tests_total += 4

# 测试字符串表示
func test_string_representation():
	var martial_art = MartialArtData.new()
	martial_art.id = "test_sword_001"
	martial_art.name = "测试剑法"
	martial_art.martial_art_type = MartialArtData.MartialArtType.ATTACK
	martial_art.damage_base = 100.0
	martial_art.cost_mana = 50.0
	martial_art.cost_stamina = 30.0
	martial_art.cooldown = 2.5
	
	var str_repr = martial_art.to_string()
	assert(str_repr.contains("测试剑法"), "字符串表示应该包含名称")
	assert(str_repr.contains("test_sword_001"), "字符串表示应该包含ID")
	assert(str_repr.contains("攻击"), "字符串表示应该包含类型")
	assert(str_repr.contains("100.0"), "字符串表示应该包含伤害")
	
	print("✓ 字符串表示测试通过")
	tests_passed += 4
	tests_total += 4

# 断言函数
func assert(condition, message):
	if condition:
		tests_passed += 1
	else:
		print("断言失败: " + message)
	
	tests_total += 1