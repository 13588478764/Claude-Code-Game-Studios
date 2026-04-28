# 境界解锁机制单元测试
# 验证根据角色境界解锁装备槽位的机制

extends Node

# 测试结果结构
class TestResult:
	var passed: bool
	var test_name: String
	var message: String

# 测试所有功能
func test_all() -> Array:
	var results = []
	
	results.append(test_realm_unlock_mechanism_correctly_implemented())
	results.append(test_slot_unlock_timing_correct())
	results.append(test_realm_locked_status_correctly_displayed())
	results.append(test_realm_change_updates_slot_status_dynamically())
	
	return results

# 测试1: 境界解锁机制正确实现
func test_realm_unlock_mechanism_correctly_implemented() -> TestResult:
	var result = TestResult.new()
	result.test_name = "境界解锁机制正确实现"
	
	# 创建境界解锁管理器实例
	var realm_manager = load("res://src/scripts/equipment/realm_unlock_manager.gd").new()
	var slot_manager = load("res://src/scripts/equipment/equipment_slot_manager.gd").new()
	
	# 测试炼气期解锁的槽位
	var liangqi_unlocked = realm_manager.unlock_slots_for_realm(realm_manager.RealmLevel.LIANG_QI)
	var has_weapon_main = realm_manager.SlotType.WEAPON_MAIN in liangqi_unlocked
	var has_body = realm_manager.SlotType.BODY in liangqi_unlocked
	var has_feet = realm_manager.SlotType.FEET in liangqi_unlocked
	
	if has_weapon_main and has_body and has_feet:
		result.passed = true
		result.message = "境界解锁机制正确实现"
	else:
		result.passed = false
		result.message = "境界解锁机制实现错误"
	
	return result

# 测试2: 槽位解锁时机正确
func test_slot_unlock_timing_correct() -> TestResult:
	var result = TestResult.new()
	result.test_name = "槽位解锁时机正确"
	
	# 创建境界解锁管理器实例
	var realm_manager = load("res://src/scripts/equipment/realm_unlock_manager.gd").new()
	
	# 测试筑基期解锁的槽位
	var zhuji_unlocked = realm_manager.unlock_slots_for_realm(realm_manager.RealmLevel.ZHU_JI)
	var has_head = realm_manager.SlotType.HEAD in zhuji_unlocked
	var has_hands = realm_manager.SlotType.HANDS in zhuji_unlocked
	
	# 检查这些槽位是否不应该在炼气期解锁
	var liangqi_unlocked = realm_manager.unlock_slots_for_realm(realm_manager.RealmLevel.LIANG_QI)
	var has_head_in_liangqi = realm_manager.SlotType.HEAD in liangqi_unlocked
	var has_hands_in_liangqi = realm_manager.SlotType.HANDS in liangqi_unlocked
	
	if has_head and has_hands and not has_head_in_liangqi and not has_hands_in_liangqi:
		result.passed = true
		result.message = "槽位解锁时机正确"
	else:
		result.passed = false
		result.message = "槽位解锁时机错误"
	
	return result

# 测试3: 境界锁定状态正确显示
func test_realm_locked_status_correctly_displayed() -> TestResult:
	var result = TestResult.new()
	result.test_name = "境界锁定状态正确显示"
	
	# 创建境界解锁管理器实例
	var realm_manager = load("res://src/scripts/equipment/realm_unlock_manager.gd").new()
	var slot_manager = load("res://src/scripts/equipment/equipment_slot_manager.gd").new()
	
	# 创建一个炼气期的角色
	var character = {"realm_level": realm_manager.RealmLevel.LIANG_QI}
	
	# 检查需要更高境界的槽位是否被锁定
	var is_ring2_unlocked = realm_manager.check_realm_requirements(realm_manager.SlotType.RING_2, character.realm_level)
	var is_inner_art1_unlocked = realm_manager.check_realm_requirements(realm_manager.SlotType.INNER_ART_1, character.realm_level)
	
	# 这些槽位应该被锁定
	if not is_ring2_unlocked and not is_inner_art1_unlocked:
		result.passed = true
		result.message = "境界锁定状态正确显示"
	else:
		result.passed = false
		result.message = "境界锁定状态显示错误"
	
	return result

# 测试4: 境界变化时槽位状态动态更新
func test_realm_change_updates_slot_status_dynamically() -> TestResult:
	var result = TestResult.new()
	result.test_name = "境界变化时槽位状态动态更新"
	
	# 创建境界解锁管理器实例
	var realm_manager = load("res://src/scripts/equipment/realm_unlock_manager.gd").new()
	var slot_manager = load("res://src/scripts/equipment/equipment_slot_manager.gd").new()
	
	# 创建一个炼气期的角色
	var character = {"realm_level": realm_manager.RealmLevel.LIANG_QI}
	
	# 检查初始状态
	var initial_status = realm_manager.update_slot_lock_status(character, slot_manager)
	var initial_ring2_locked = not initial_status.get(realm_manager.SlotType.RING_2, true)
	
	# 更新角色境界到真仙境
	character.realm_level = realm_manager.RealmLevel.ZHEN_XIAN
	
	# 检查更新后的状态
	var updated_status = realm_manager.update_slot_lock_status(character, slot_manager)
	var updated_ring2_unlocked = updated_status.get(realm_manager.SlotType.RING_2, false)
	
	if initial_ring2_locked and updated_ring2_unlocked:
		result.passed = true
		result.message = "境界变化时槽位状态动态更新"
	else:
		result.passed = false
		result.message = "境界变化时槽位状态更新错误"
	
	return result

# 运行测试并输出结果
func run_tests():
	var test_results = test_all()
	var passed_count = 0
	var total_count = test_results.size()
	
	print("开始运行境界解锁机制测试...")
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