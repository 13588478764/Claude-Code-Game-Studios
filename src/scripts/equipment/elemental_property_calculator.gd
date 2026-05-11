## ElementalPropertyCalculator
## 元素属性计算器
## 负责计算五行克制体系和元素伤害计算

extends Node

class_name ElementalPropertyCalculator

# 元素类型枚举
enum ELEMENT_TYPE {
	NONE = 0,
	METAL = 1,    # 金
	WOOD = 2,     # 木
	WATER = 3,    # 水
	FIRE = 4,     # 火
	EARTH = 5     # 土
}

# 元素属性结构
class ElementalAttributes:
	var fire: int = 0    # 火
	var water: int = 0   # 水
	var earth: int = 0   # 土
	var metal: int = 0  # 金
	var wood: int = 0   # 木

# 五行克制关系
# 金克木、木克土、土克水、水克火、火克金
const ELEMENTAL_ADVANTAGES = {
	ELEMENT_TYPE.METAL: ELEMENT_TYPE.WOOD,   # 金克木
	ELEMENT_TYPE.WOOD: ELEMENT_TYPE.EARTH,  # 木克土
	ELEMENT_TYPE.EARTH: ELEMENT_TYPE.WATER, # 土克水
	ELEMENT_TYPE.WATER: ELEMENT_TYPE.FIRE,   # 水克火
	ELEMENT_TYPE.FIRE: ELEMENT_TYPE.METAL    # 火克金
}

# 信号定义
signal elemental_calculated(source_element: int, target_element: int, damage_multiplier: float)

# 初始化
func _ready():
	print("元素属性计算器已初始化")

# 计算元素克制伤害
func calculate_elemental_damage(source_element: int, target_element: int, base_damage: int) -> int:
	var multiplier = get_elemental_advantage_multiplier(source_element, target_element)
	var final_damage = int(base_damage * multiplier)
	
	# 发出计算完成信号
	emit_signal("elemental_calculated", source_element, target_element, multiplier)
	
	return final_damage

# 获取克制倍数
func get_elemental_advantage_multiplier(attacker_element: int, defender_element: int) -> float:
	# 如果没有元素或元素相同，返回1.0（无加成或减益）
	if attacker_element == ELEMENT_TYPE.NONE or defender_element == ELEMENT_TYPE.NONE:
		return 1.0
	if attacker_element == defender_element:
		return 1.0
	
	# 检查是否为克制关系（攻击方克制防守方）
	if ELEMENTAL_ADVANTAGES.has(attacker_element) and ELEMENTAL_ADVANTAGES[attacker_element] == defender_element:
		return 1.5  # 克制时1.5倍伤害
	
	# 检查是否为被克制关系（攻击方被防守方克制）
	if ELEMENTAL_ADVANTAGES.has(defender_element) and ELEMENTAL_ADVANTAGES[defender_element] == attacker_element:
		return 0.5  # 被克制时0.5倍伤害
	
	# 无特殊关系，返回1.0
	return 1.0

# 应用装备元素属性
func apply_equipment_elemental_bonuses(equipped_items: Array) -> ElementalAttributes:
	var elemental_bonuses = ElementalAttributes.new()
	
	for item in equipped_items:
		if item.has("attributes") and item.attributes.has("elemental_bonuses"):
			var attr = item.attributes.elemental_bonuses
			elemental_bonuses.fire += attr.get("fire", 0)
			elemental_bonuses.water += attr.get("water", 0)
			elemental_bonuses.earth += attr.get("earth", 0)
			elemental_bonuses.metal += attr.get("metal", 0)
			elemental_bonuses.wood += attr.get("wood", 0)
	
	return elemental_bonuses

# 合并武学和装备元素属性
func combine_elemental_properties(martial_art_elements: ElementalAttributes, equipment_elements: ElementalAttributes) -> ElementalAttributes:
	var combined = ElementalAttributes.new()
	
	combined.fire = martial_art_elements.fire + equipment_elements.fire
	combined.water = martial_art_elements.water + equipment_elements.water
	combined.earth = martial_art_elements.earth + equipment_elements.earth
	combined.metal = martial_art_elements.metal + equipment_elements.metal
	combined.wood = martial_art_elements.wood + equipment_elements.wood
	
	return combined

# 获取主要元素类型
func get_primary_element(elemental_attrs: ElementalAttributes) -> int:
	var elements = [
		{"type": ELEMENT_TYPE.FIRE, "value": elemental_attrs.fire},
		{"type": ELEMENT_TYPE.WATER, "value": elemental_attrs.water},
		{"type": ELEMENT_TYPE.EARTH, "value": elemental_attrs.earth},
		{"type": ELEMENT_TYPE.METAL, "value": elemental_attrs.metal},
		{"type": ELEMENT_TYPE.WOOD, "value": elemental_attrs.wood}
	]
	
	# 按值排序，找到最大值
	elements.sort_custom(func(a, b): return a.value > b.value)
	
	# 如果最大值大于0，返回对应元素类型，否则返回NONE
	return elements[0].type if elements[0].value > 0 else ELEMENT_TYPE.NONE
}

# 测试函数
func test_elemental_calculation():
	print("开始测试元素属性计算...")
	
	# 测试元素克制关系
	print("测试元素克制关系:")
	
	# 金克木
	var metal_to_wood = get_elemental_advantage_multiplier(ELEMENT_TYPE.METAL, ELEMENT_TYPE.WOOD)
	print("金克木倍数: ", metal_to_wood)  # 应该是1.5
	
	# 木克土
	var wood_to_earth = get_elemental_advantage_multiplier(ELEMENT_TYPE.WOOD, ELEMENT_TYPE.EARTH)
	print("木克土倍数: ", wood_to_earth)  # 应该是1.5
	
	# 土克水
	var earth_to_water = get_elemental_advantage_multiplier(ELEMENT_TYPE.EARTH, ELEMENT_TYPE.WATER)
	print("土克水倍数: ", earth_to_water)  # 应该是1.5
	
	# 水克火
	var water_to_fire = get_elemental_advantage_multiplier(ELEMENT_TYPE.WATER, ELEMENT_TYPE.FIRE)
	print("水克火倍数: ", water_to_fire)  # 应该是1.5
	
	# 火克金
	var fire_to_metal = get_elemental_advantage_multiplier(ELEMENT_TYPE.FIRE, ELEMENT_TYPE.METAL)
	print("火克金倍数: ", fire_to_metal)  # 应该是1.5
	
	# 被克制测试
	var wood_to_metal = get_elemental_advantage_multiplier(ELEMENT_TYPE.WOOD, ELEMENT_TYPE.METAL)
	print("木被金克倍数: ", wood_to_metal)  # 应该是0.5
	
	# 测试伤害计算
	var base_damage = 100
	var fire_damage_to_metal = calculate_elemental_damage(ELEMENT_TYPE.FIRE, ELEMENT_TYPE.METAL, base_damage)
	print("火系武学对金系目标伤害: ", fire_damage_to_metal)  # 应该是150 (100 * 1.5)
	
	var water_damage_to_fire = calculate_elemental_damage(ELEMENT_TYPE.WATER, ELEMENT_TYPE.FIRE, base_damage)
	print("水系武学对火系目标伤害: ", water_damage_to_fire)  # 应该是150 (100 * 1.5)
	
	var fire_damage_to_water = calculate_elemental_damage(ELEMENT_TYPE.FIRE, ELEMENT_TYPE.WATER, base_damage)
	print("火系武学对水系目标伤害: ", fire_damage_to_water)  # 应该是50 (100 * 0.5)
	
	# 测试装备元素属性应用
	var test_equipment = [
		{
			"id": "fire_sword",
			"attributes": {
				"elemental_bonuses": {
					"fire": 10,
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
					"water": 5,
					"earth": 0,
					"metal": 0,
					"wood": 0
				}
			}
		}
	]
	
	var equipment_bonuses = apply_equipment_elemental_bonuses(test_equipment)
	print("装备元素属性加成:")
	print("  火: ", equipment_bonuses.fire)
	print("  水: ", equipment_bonuses.water)
	print("  土: ", equipment_bonuses.earth)
	print("  金: ", equipment_bonuses.metal)
	print("  木: ", equipment_bonuses.wood)
	
	# 测试元素属性合并
	var martial_art_elements = ElementalAttributes.new()
	martial_art_elements.fire = 20
	martial_art_elements.water = 5
	
	var combined_elements = combine_elemental_properties(martial_art_elements, equipment_bonuses)
	print("合并后元素属性:")
	print("  火: ", combined_elements.fire)  # 20 + 10 = 30
	print("  水: ", combined_elements.water)  # 5 + 5 = 10
	print("  土: ", combined_elements.earth)  # 0 + 0 = 0
	print("  金: ", combined_elements.metal)  # 0 + 0 = 0
	print("  木: ", combined_elements.wood)  # 0 + 0 = 0
	
	# 测试主要元素获取
	var primary_element = get_primary_element(combined_elements)
	print("主要元素类型: ", primary_element)  # 应该是火元素
	
	print("元素属性计算测试完成")