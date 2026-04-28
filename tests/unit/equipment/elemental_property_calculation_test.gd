# 元素属性计算单元测试
# 验证五行克制体系和元素伤害计算的正确性

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_five_elements_restraint_system_calculation_correctly())
	results.append(test_elemental_damage_multiplier_calculation_correctly())
	results.append(test_equipment_elemental_attributes_correctly_applied())
	results.append(test_elemental_attributes_correctly_combined_with_martial_arts())
	
	return results

# 测试1: 五行克制计算正确
func test_five_elements_restraint_system_calculation_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "五行克制计算正确"
	
	# 创建元素属性计算器实例
	var calculator = load("res://src/scripts/equipment/elemental_property_calculator.gd").new()
	
	# 测试所有克制关系
	var metal_to_wood = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.METAL, calculator.ELEMENT_TYPE.WOOD)
	var wood_to_earth = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.WOOD, calculator.ELEMENT_TYPE.EARTH)
	var earth_to_water = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.EARTH, calculator.ELEMENT_TYPE.WATER)
	var water_to_fire = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.WATER, calculator.ELEMENT_TYPE.FIRE)
	var fire_to_metal = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.FIRE, calculator.ELEMENT_TYPE.METAL)
	
	# 测试被克制关系
	var wood_to_metal = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.WOOD, calculator.ELEMENT_TYPE.METAL)
	var earth_to_wood = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.EARTH, calculator.ELEMENT_TYPE.WOOD)
	var water_to_earth = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.WATER, calculator.ELEMENT_TYPE.EARTH)
	var fire_to_water = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.FIRE, calculator.ELEMENT_TYPE.WATER)
	var metal_to_fire = calculator.get_elemental_advantage_multiplier(calculator.ELEMENT_TYPE.METAL, calculator.ELEMENT_TYPE.FIRE)
	
	# 验证克制关系（1.5倍）
	if abs(metal_to_wood - 1.5) < 0.001 and abs(wood_to_earth - 1.5) < 0.001 and abs(earth_to_water - 1.5) < 0.001 and abs(water_to_fire - 1.5) < 0.001 and abs(fire_to_metal - 1.5) < 0.001:
		# 验证被克制关系（0.5倍）
		if abs(wood_to_metal - 0.5) < 0.001 and abs(earth_to_wood - 0.5) < 0.001 and abs(water_to_earth - 0.5) < 0.001 and abs(fire_to_water - 0.5) < 0.001 and abs(metal_to_fire - 0.5) < 0.001:
			result.passed = true
			result.message = "五行克制计算正确"
		else:
			result.passed = false
			result.message = "五行被克制关系计算错误"
	else:
		result.passed = false
		result.message = "五行克制关系计算错误"
	
	return result

# 测试2: 克制伤害倍数正确
func test_elemental_damage_multiplier_calculation_correctly() -> TestResult:
	var result = TestResult.new()
	result.test_name = "克制伤害倍数正确"
	
	# 创建元素属性计算器实例
	var calculator = load("res://src/scripts/equipment/elemental_property_calculator.gd").new()
	
	# 测试基础伤害
	var base_damage = 100
	
	# 测试克制伤害（1.5倍）
	var fire_to_metal_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.FIRE, calculator.ELEMENT_TYPE.METAL, base_damage)
	var water_to_fire_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.WATER, calculator.ELEMENT_TYPE.FIRE, base_damage)
	var earth_to_water_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.EARTH, calculator.ELEMENT_TYPE.WATER, base_damage)
	var wood_to_earth_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.WOOD, calculator.ELEMENT_TYPE.EARTH, base_damage)
	var metal_to_wood_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.METAL, calculator.ELEMENT_TYPE.WOOD, base_damage)
	
	# 测试被克伤害（0.5倍）
	var metal_to_fire_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.METAL, calculator.ELEMENT_TYPE.FIRE, base_damage)
	var fire_to_water_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.FIRE, calculator.ELEMENT_TYPE.WATER, base_damage)
	var water_to_earth_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.WATER, calculator.ELEMENT_TYPE.EARTH, base_damage)
	var earth_to_wood_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.EARTH, calculator.ELEMENT_TYPE.WOOD, base_damage)
	var wood_to_metal_damage = calculator.calculate_elemental_damage(calculator.ELEMENT_TYPE.WOOD, calculator.ELEMENT_TYPE.METAL, base_damage)
	
	# 验证伤害计算
	if fire_to_metal_damage == 150 and water_to_fire_damage == 150 and earth_to_water_damage == 150 and wood_to_earth_damage == 150 and metal_to_wood_damage == 150:
		if metal_to_fire_damage == 50 and fire_to_water_damage == 50 and water_to_earth_damage == 50 and earth_to_wood_damage == 50 and wood_to_metal_damage == 50:
			result.passed = true
			result.message = "克制伤害倍数正确"
		else:
			result.passed = false
			result.message = "被克伤害倍数计算错误"
	else:
		result.passed = false
		result.message = "克制伤害倍数计算错误"
	
	return result

# 测试3: 装备元素属性正确应用
func test_equipment_elemental_attributes_correctly_applied() -> TestResult:
	var result = TestResult.new()
	result.test_name = "装备元素属性正确应用"
	
	# 创建测试装备
	var test_equipment = [
		{
			"id": "fire_sword",
			"attributes": {
				"elemental_bonuses": {
					"fire": 15,
					"water": 0,
					"earth": 0,
					"metal": 0,
					"wood": 0
				}
			}
		},
		{
			"id": "water_ring",
			"attributes": {
				"elemental_bonuses": {
					"fire": 0,
					"water": 10,
					"earth": 0,
					"metal": 0,
					"wood": 0
				}
			}
		},
		{
			"id": "earth_amulet",
			"attributes": {
				"elemental_bonuses": {
					"fire": 0,
					"water": 0,
					"earth": 5,
					"metal": 0,
					"wood": 0
				}
			}
		}
	]
	
	# 创建元素属性计算器实例
	var calculator = load("res://src/scripts/equipment/elemental_property_calculator.gd").new()
	
	# 应用装备元素属性
	var equipment_bonuses = calculator.apply_equipment_elemental_bonuses(test_equipment)
	
	# 验证元素属性正确应用
	if equipment_bonuses.fire == 15 and equipment_bonuses.water == 10 and equipment_bonuses.earth == 5:
		result.passed = true
		result.message = "装备元素属性正确应用"
	else:
		result.passed = false
		result.message = "装备元素属性应用错误"
	
	return result

# 测试4: 元素属性与武学属性正确叠加
func test_elemental_attributes_correctly_combined_with_martial_arts() -> TestResult:
	var result = TestResult.new()
	result.test_name = "元素属性与武学属性正确叠加"
	
	# 创建武学元素属性
	var martial_art_elements = load("res://src/scripts/equipment/elemental_property_calculator.gd").ElementalAttributes.new()
	martial_art_elements.fire = 20
	martial_art_elements.water = 5
	martial_art_elements.earth = 0
	martial_art_elements.metal = 0
	martial_art_elements.wood = 0
	
	# 创建装备元素属性
	var equipment_elements = load("res://src/scripts/equipment/elemental_property_calculator.gd").ElementalAttributes.new()
	equipment_elements.fire = 10
	equipment_elements.water = 15
	equipment_elements.earth = 8
	equipment_elements.metal = 0
	equipment_elements.wood = 0
	
	# 创建元素属性计算器实例
	var calculator = load("res://src/scripts/equipment/elemental_property_calculator.gd").new()
	
	# 合并元素属性
	var combined_elements = calculator.combine_elemental_properties(martial_art_elements, equipment_elements)
	
	# 验证元素属性正确叠加
	if combined_elements.fire == 30 and combined_elements.water == 20 and combined_elements.earth == 8:
		result.passed = true
		result.message = "元素属性与武学属性正确叠加"
	else:
		result.passed = false
		result.message = "元素属性叠加错误"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行元素属性计算测试...")
	print("================================")
	
	for result in test_results:
		if result.passed:
			print("✅ %s: %s" % [result.test_name, result.message])
			passed_count += 1
		else:
			print("❌ %s: %s" % [result.test_name, result.message])
	
	print("================================")
	print("测试结果: %d/%d 项测试通过" % [passed_count, total_count])
	
	if passed_count == total_count:
		print("🎉 所有测试都通过了！")
	else:
		print("⚠️  有 %d 项测试失败" % [total_count - passed_count])
	
	return passed_count == total_count