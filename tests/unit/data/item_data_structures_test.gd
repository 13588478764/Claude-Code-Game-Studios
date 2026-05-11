# Item Data Structures Unit Test
# Tests for the item data structures implementation

extends Node

# Import the scripts to test
var ItemData = load("res://src/scripts/data/item_data.gd")
var EquipmentData = load("res://src/scripts/data/equipment_data.gd")
var ConsumableData = load("res://src/scripts/data/consumable_data.gd")
var QuestItemData = load("res://src/scripts/data/quest_item_data.gd")

# Test results
var tests_passed = 0
var tests_total = 0

# Run all tests
func run_all_tests():
	print("Running Item Data Structures tests...")
	
	# Test 1: ItemData base functionality
	test_item_data_base_functionality()
	
	# Test 2: EquipmentData functionality
	test_equipment_data_functionality()
	
	# Test 3: ConsumableData functionality
	test_consumable_data_functionality()
	
	# Test 4: QuestItemData functionality
	test_quest_item_data_functionality()
	
	# Test 5: Item validation
	test_item_validation()
	
	# Test 6: Rarity handling
	test_rarity_handling()
	
	# Test 7: Equipment slot handling
	test_equipment_slot_handling()
	
	# Test 8: Effect type handling
	test_effect_type_handling()
	
	print("Item Data Structures tests completed: %d/%d passed" % [tests_passed, tests_total])

# Test ItemData base functionality
func test_item_data_base_functionality():
	var item = ItemData.new("sword_001", "青铜剑", "一把普通的青铜剑")
	
	# Test basic properties
	assert(item.id == "sword_001", "Item ID should be set correctly")
	assert(item.name == "青铜剑", "Item name should be set correctly")
	assert(item.description == "一把普通的青铜剑", "Item description should be set correctly")
	
	# Test default values
	assert(item.rarity == 0, "Default rarity should be 0 (COMMON)")
	assert(item.max_stack == 1, "Default max stack should be 1")
	assert(len(item.tags) == 0, "Default tags array should be empty")
	
	print("✓ ItemData base functionality test passed")
	tests_passed += 5
	tests_total += 5

# Test EquipmentData functionality
func test_equipment_data_functionality():
	var equipment = EquipmentData.new("armor_001", "铁甲", "一件坚固的铁制胸甲")
	
	# Test inheritance
	assert(equipment.get_item_type() == "Equipment", "Equipment should return correct type")
	assert(equipment.name == "铁甲", "Equipment should inherit name from base class")
	
	# Test equipment-specific properties
	equipment.slot = 4  # ARMOR_CHEST
	equipment.level_requirement = 5
	equipment.add_base_stat("defense", 15.0)
	
	assert(equipment.slot == 4, "Equipment slot should be set correctly")
	assert(equipment.level_requirement == 5, "Level requirement should be set correctly")
	assert(equipment.get_base_stat("defense") == 15.0, "Base stat should be added and retrieved correctly")
	
	# Test slot name
	assert(equipment.get_slot_name() == "胸部护甲", "Slot name should return correct translation")
	
	print("✓ EquipmentData functionality test passed")
	tests_passed += 6
	tests_total += 6

# Test ConsumableData functionality
func test_consumable_data_functionality():
	var consumable = ConsumableData.new("potion_001", "生命药水", "恢复一定量的生命值")
	
	# Test inheritance
	assert(consumable.get_item_type() == "Consumable", "Consumable should return correct type")
	assert(consumable.name == "生命药水", "Consumable should inherit name from base class")
	
	# Test consumable-specific properties
	consumable.effect_type = 0  # HEAL_HP
	consumable.effect_value = 50.0
	consumable.duration = 0.0
	
	assert(consumable.effect_type == 0, "Effect type should be set correctly")
	assert(consumable.effect_value == 50.0, "Effect value should be set correctly")
	assert(consumable.duration == 0.0, "Duration should be set correctly")
	
	# Test effect type name
	assert(consumable.get_effect_type_name() == "生命恢复", "Effect type name should return correct translation")
	
	print("✓ ConsumableData functionality test passed")
	tests_passed += 6
	tests_total += 6

# Test QuestItemData functionality
func test_quest_item_data_functionality():
	var quest_item = QuestItemData.new("quest_001", "神秘信件", "一封带有封印的神秘信件")
	
	# Test inheritance
	assert(quest_item.get_item_type() == "QuestItem", "QuestItem should return correct type")
	assert(quest_item.name == "神秘信件", "QuestItem should inherit name from base class")
	
	# Test quest item-specific properties
	quest_item.quest_id = "quest_delivery_01"
	quest_item.is_consumable_on_use = true
	quest_item.required_for_quest = true
	
	assert(quest_item.get_related_quest_id() == "quest_delivery_01", "Quest ID should be set and retrieved correctly")
	assert(quest_item.is_consumed_on_use() == true, "Consumable on use flag should be set correctly")
	assert(quest_item.is_required_for_quest() == true, "Required for quest flag should be set correctly")
	
	print("✓ QuestItemData functionality test passed")
	tests_passed += 5
	tests_total += 5

# Test item validation
func test_item_validation():
	# Test valid item
	var valid_item = ItemData.new("valid_item", "Valid Item", "A valid test item")
	assert(valid_item.validate() == true, "Valid item should pass validation")
	
	# Test invalid item (no ID)
	var invalid_item = ItemData.new("", "No ID Item", "An item with no ID")
	assert(invalid_item.validate() == false, "Item with no ID should fail validation")
	
	# Test invalid item (no name)
	var invalid_item2 = ItemData.new("no_name_item", "", "An item with no name")
	assert(invalid_item2.validate() == false, "Item with no name should fail validation")
	
	# Test equipment validation
	var valid_equipment = EquipmentData.new("eq_valid", "Valid Equipment", "A valid equipment item")
	valid_equipment.slot = 0
	assert(valid_equipment.validate() == true, "Valid equipment should pass validation")
	
	# Test quest item validation
	var valid_quest = QuestItemData.new("quest_valid", "Valid Quest", "A valid quest item")
	valid_quest.quest_id = "some_quest_id"
	assert(valid_quest.validate() == true, "Valid quest item with quest ID should pass validation")
	
	var invalid_quest = QuestItemData.new("quest_invalid", "Invalid Quest", "An invalid quest item")
	assert(invalid_quest.validate() == false, "Quest item without quest ID should fail validation")
	
	print("✓ Item validation test passed")
	tests_passed += 6
	tests_total += 6

# Test rarity handling
func test_rarity_handling():
	var item = ItemData.new("rarity_test", "Rarity Test", "Testing rarity functionality")
	
	# Test default rarity (COMMON)
	assert(item.rarity == 0, "Default rarity should be 0")
	assert(item.get_rarity_name() == "普通", "Default rarity name should be '普通'")
	assert(item.get_rarity_color() == Color.WHITE, "Common rarity color should be white")
	
	# Test RARE rarity
	item.rarity = 1
	assert(item.get_rarity_name() == "稀有", "Rare rarity name should be '稀有'")
	assert(item.get_rarity_color() == Color.BLUE, "Rare rarity color should be blue")
	
	# Test EPIC rarity
	item.rarity = 2
	assert(item.get_rarity_name() == "史诗", "Epic rarity name should be '史诗'")
	assert(item.get_rarity_color() == Color.PURPLE, "Epic rarity color should be purple")
	
	# Test LEGENDARY rarity
	item.rarity = 3
	assert(item.get_rarity_name() == "传说", "Legendary rarity name should be '传说'")
	assert(item.get_rarity_color() == Color.GOLD, "Legendary rarity color should be gold")
	
	print("✓ Rarity handling test passed")
	tests_passed += 8
	tests_total += 8

# Test equipment slot handling
func test_equipment_slot_handling():
	var equipment = EquipmentData.new("slot_test", "Slot Test", "Testing slot functionality")
	
	# Test WEAPON_MAIN slot
	equipment.slot = 0
	assert(equipment.get_slot_name() == "主手武器", "Main weapon slot name should be correct")
	
	# Test ARMOR_CHEST slot
	equipment.slot = 4
	assert(equipment.get_slot_name() == "胸部护甲", "Chest armor slot name should be correct")
	
	# Test ACCESSORY_RING slot
	equipment.slot = 6
	assert(equipment.get_slot_name() == "戒指", "Ring accessory slot name should be correct")
	
	# Test level requirement check
	equipment.level_requirement = 10
	assert(equipment.meets_level_requirement(10) == true, "Should meet requirement when level equals requirement")
	assert(equipment.meets_level_requirement(5) == false, "Should not meet requirement when level is less than requirement")
	assert(equipment.meets_level_requirement(15) == true, "Should meet requirement when level exceeds requirement")
	
	# Test adding multiple stats
	equipment.add_base_stat("attack", 10.0)
	equipment.add_base_stat("defense", 5.0)
	equipment.add_base_stat("speed", 2.5)
	
	assert(equipment.get_base_stat("attack") == 10.0, "Attack stat should be retrieved correctly")
	assert(equipment.get_base_stat("defense") == 5.0, "Defense stat should be retrieved correctly")
	assert(equipment.get_base_stat("speed") == 2.5, "Speed stat should be retrieved correctly")
	assert(equipment.get_base_stat("nonexistent") == 0.0, "Non-existent stat should return 0.0")
	
	print("✓ Equipment slot handling test passed")
	tests_passed += 9
	tests_total += 9

# Test effect type handling
func test_effect_type_handling():
	var consumable = ConsumableData.new("effect_test", "Effect Test", "Testing effect functionality")
	
	# Test HEAL_HP effect
	consumable.effect_type = 0
	assert(consumable.get_effect_type_name() == "生命恢复", "Heal HP effect name should be correct")
	
	# Test RESTORE_MANA effect
	consumable.effect_type = 1
	assert(consumable.get_effect_type_name() == "内力恢复", "Restore mana effect name should be correct")
	
	# Test BUFF_TEMP effect
	consumable.effect_type = 2
	assert(consumable.get_effect_type_name() == "临时增益", "Temporary buff effect name should be correct")
	
	# Test STATUS_CURE effect
	consumable.effect_type = 3
	assert(consumable.get_effect_type_name() == "状态治愈", "Status cure effect name should be correct")
	
	# Test ATTRIBUTE_BOOST effect
	consumable.effect_type = 4
	assert(consumable.get_effect_type_name() == "属性提升", "Attribute boost effect name should be correct")
	
	# Test usability flags
	assert(consumable.usable_in_combat == true, "Default combat usability should be true")
	assert(consumable.usable_out_of_combat == true, "Default out of combat usability should be true")
	
	consumable.usable_in_combat = false
	assert(consumable.usable_in_combat == false, "Combat usability should be settable to false")
	
	print("✓ Effect type handling test passed")
	tests_passed += 8
	tests_total += 8
