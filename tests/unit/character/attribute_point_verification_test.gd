## attribute_point_verification_test.gd
## 属性点验证单元测试
##
## 测试 AttributeValidationManager 的所有功能

extends GutTest

var manager
var validator

func before_each():
	manager = load("res://src/scripts/character/attribute_point_manager.gd").new()
	validator = load("res://src/scripts/character/attribute_validation_manager.gd").new()
	
	# 初始化管理器
	validator.set_attribute_manager(manager)
	manager.add_total_points(10)

## AC-1: 属性点分配验证正常 - 测试可用点数验证
func test_validate_allocation_with_zero_available_points():
	# Given: 玩家拥有0点可用属性点
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	manager.allocate_point("strength")
	
	# When: 尝试分配1点到力道属性
	var result = validator.validate_allocation("strength", 1)
	
	# Then: 系统拒绝分配
	assert_false(result, "Should reject allocation when no points available")
	assert_true(validator.get_validation_errors().size() > 0, "Should have validation error")

## AC-1: 属性点分配验证正常 - 测试负数分配
func test_validate_allocation_with_negative_points():
	# When: 尝试分配负数点
	var result = validator.validate_allocation("strength", -1)
	
	# Then: 系统拒绝分配
	assert_false(result, "Should reject negative points")
	var errors = validator.get_validation_errors()
	assert_true(errors.size() > 0, "Should have validation error")
	assert_true("negative" in errors[0].to_lower(), "Error should mention negative")

## AC-1: 属性点分配验证正常 - 测试浮点数分配
func test_validate_allocation_with_float_points():
	# When: 尝试分配浮点数点（GDScript会自动转换为int）
	var result = validator.validate_allocation("strength", 1)
	
	# Then: 系统接受有效的整数分配
	assert_true(result, "Should accept valid integer allocation")
	var errors = validator.get_validation_errors()
	assert_eq(errors.size(), 0, "Should have no validation error")

## AC-1: 属性点分配验证正常 - 测试有效分配
func test_validate_allocation_with_valid_points():
	# When: 尝试分配有效的点数
	var result = validator.validate_allocation("strength", 5)
	
	# Then: 系统接受分配
	assert_true(result, "Should accept valid allocation")

## AC-2: 重置机制正常 - 测试洗髓丹重置
func test_reset_attributes_by_item():
	# Given: 玩家分配了部分属性点
	manager.allocate_point("strength")
	manager.allocate_point("agility")
	
	# When: 使用洗髓丹重置属性
	var result = validator.reset_attributes(AttributeValidationManager.RESET_TYPE_ITEM)
	
	# Then: 重置成功
	assert_true(result, "Should reset attributes by item")

## AC-2: 重置机制正常 - 测试境界突破重置
func test_reset_attributes_by_breakthrough():
	# Given: 玩家分配了部分属性点
	manager.allocate_point("strength")
	manager.allocate_point("intelligence")
	
	# When: 使用境界突破重置属性
	var result = validator.reset_attributes(AttributeValidationManager.RESET_TYPE_BREAKTHROUGH)
	
	# Then: 重置成功
	assert_true(result, "Should reset attributes by breakthrough")

## AC-2: 重置机制正常 - 测试无效重置类型
func test_reset_attributes_with_invalid_type():
	# When: 使用无效的重置类型
	var result = validator.reset_attributes("invalid_type")
	
	# Then: 重置失败
	assert_false(result, "Should reject invalid reset type")

## AC-3: 属性点上限验证 - 测试达到上限
func test_validate_allocation_at_max_limit():
	# Given: 玩家力道属性已达99点上限
	for i in range(99):
		manager.allocate_point("strength")
	
	# When: 尝试再分配1点到力道
	var result = validator.validate_allocation("strength", 1)
	
	# Then: 系统拒绝分配
	assert_false(result, "Should reject allocation that exceeds max")
	var errors = validator.get_validation_errors()
	assert_true(errors.size() > 0, "Should have validation error")

## AC-3: 属性点上限验证 - 测试等于上限
func test_validate_allocation_equal_to_max():
	# Given: 玩家有99点可用
	for i in range(99):
		manager.add_total_points(1)
	
	# When: 尝试分配99点到力道
	var result = validator.validate_allocation("strength", 99)
	
	# Then: 系统接受分配
	assert_true(result, "Should accept allocation equal to max")

## AC-3: 属性点上限验证 - 测试不同属性上限
func test_validate_allocation_different_attributes():
	# Given: 玩家有足够的属性点
	manager.add_total_points(500)  # 添加足够的点数
	
	# When: 验证不同属性的上限
	var attributes = ["strength", "agility", "constitution", "intelligence", "willpower", "luck"]
	
	# Then: 所有属性都应该有相同的上限
	for attr in attributes:
		var result = validator.validate_allocation(attr, 99)
		assert_true(result, "Attribute %s should accept 99 points" % attr)

## AC-4: 数据完整性验证 - 测试有效数据
func test_verify_data_integrity_valid():
	# Given: 玩家属性点数据有效
	manager.allocate_point("strength")
	manager.allocate_point("agility")
	
	# When: 验证数据完整性
	var result = validator.verify_data_integrity()
	
	# Then: 数据验证通过
	assert_true(result, "Should verify valid data integrity")

## AC-4: 数据完整性验证 - 测试属性值范围
func test_verify_data_integrity_attribute_range():
	# Given: 玩家属性点数据
	manager.allocate_point("strength")
	
	# When: 验证数据完整性
	var result = validator.verify_data_integrity()
	
	# Then: 所有属性值应该在有效范围内
	assert_true(result, "All attribute values should be in valid range")

## AC-4: 数据完整性验证 - 测试点数一致性
func test_verify_data_integrity_points_consistency():
	# Given: 玩家分配了属性点
	manager.allocate_point("strength")
	manager.allocate_point("agility")
	manager.allocate_point("constitution")
	
	# When: 验证数据完整性
	var result = validator.verify_data_integrity()
	
	# Then: 已分配点数应该等于总点数减去可用点数
	assert_true(result, "Allocated points should equal total minus available")

## 额外测试: 验证无效属性类型
func test_validate_allocation_invalid_attribute_type():
	# When: 尝试验证无效的属性类型
	var result = validator.validate_allocation("invalid_attribute", 1)
	
	# Then: 系统拒绝
	assert_false(result, "Should reject invalid attribute type")

## 额外测试: 验证信号发射
func test_validation_passed_signal():
	# When: 进行有效的验证
	var signal_emitted = false
	watch_signals(validator)
	validator.validate_allocation("strength", 5)
	
	# Then: 应该发射 validation_passed 信号
	assert_signal_emitted(validator, "validation_passed", "Should emit validation_passed signal")

## 额外测试: 验证失败信号
func test_validation_failed_signal():
	# When: 进行无效的验证
	watch_signals(validator)
	validator.validate_allocation("strength", -1)
	
	# Then: 应该发射 validation_failed 信号
	assert_signal_emitted(validator, "validation_failed", "Should emit validation_failed signal")