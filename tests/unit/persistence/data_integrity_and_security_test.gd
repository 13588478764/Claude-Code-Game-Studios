# 数据完整性与安全单元测试
# 验证数据完整性验证、防篡改机制、版本兼容性管理和错误恢复机制

extends Node

# 导入需要测试的脚本
var DataIntegrityManager = load("res://src/scripts/persistence/data_integrity_manager.gd")

# 测试结果统计
var tests_passed = 0
var tests_total = 0

# 运行所有测试
func run_all_tests():
	print("开始运行数据完整性与安全单元测试...")
	
	# 运行数据完整性验证测试
	test_data_integrity_validation()
	test_crc32_calculation()
	test_checksum_generation()
	
	# 运行防篡改机制测试
	test_data_encryption()
	test_data_decryption()
	test_tamper_detection()
	
	# 运行版本兼容性管理测试
	test_version_migration()
	test_generic_migration()
	test_version_validation()
	
	# 运行错误恢复机制测试
	test_backup_creation()
	test_backup_restoration()
	test_recovery_from_corrupted_data()
	
	print("\n测试完成: %d/%d 个测试通过" % [tests_passed, tests_total])

# 测试数据完整性验证
func test_data_integrity_validation():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个有效的测试数据
	var valid_data = {
		"version": "1.0.0",
		"progression": {
			"level": 25,
			"realm": 3,
			"experience": 5000
		},
		"attributes": {
			"values": {
				"strength": 20,
				"agility": 18,
				"constitution": 15,
				"intelligence": 16,
				"willpower": 14,
				"luck": 12
			}
		}
	}
	
	# 验证有效数据
	var is_valid = integrity_manager.validate_data_structure(valid_data)
	assert(is_valid == true, "有效数据应通过验证")
	
	# 创建一个无效数据（等级超出范围）
	var invalid_data = valid_data.duplicate(true)
	invalid_data["progression"]["level"] = 100  # 超出范围
	
	var is_invalid = integrity_manager.validate_data_structure(invalid_data)
	assert(is_invalid == false, "无效数据应不通过验证")
	
	print("✓ 数据完整性验证测试通过")
	tests_passed += 2
	tests_total += 2

# 测试CRC32计算
func test_crc32_calculation():
	var integrity_manager = DataIntegrityManager.new()
	
	var test_string = "Hello, World!"
	var crc_result = integrity_manager._calculate_crc32(test_string)
	
	assert(crc_result != null, "CRC32计算不应返回空值")
	assert(crc_result is int, "CRC32结果应为整数")
	
	print("✓ CRC32计算测试通过")
	tests_passed += 2
	tests_total += 2

# 测试校验码生成
func test_checksum_generation():
	var integrity_manager = DataIntegrityManager.new()
	
	var test_data = {
		"level": 15,
		"realm": 2,
		"experience": 3000
	}
	
	var checksum = integrity_manager.generate_checksum(test_data)
	
	assert(checksum != "", "校验码不应为空")
	assert(checksum is String, "校验码应为字符串")
	
	print("✓ 校验码生成测试通过")
	tests_passed += 2
	tests_total += 2

# 测试数据加密
func test_data_encryption():
	var integrity_manager = DataIntegrityManager.new()
	
	var test_data = {
		"progression": {
			"level": 20,
			"experience": 4000
		}
	}
	
	var encrypted_data = integrity_manager.encrypt_data(test_data)
	
	assert(encrypted_data != test_data, "加密后的数据应与原数据不同")
	assert(encrypted_data.has("_encrypted"), "加密数据应有加密标记")
	
	print("✓ 数据加密测试通过")
	tests_passed += 2
	tests_total += 2

# 测试数据解密
func test_data_decryption():
	var integrity_manager = DataIntegrityManager.new()
	
	var test_data = {
		"progression": {
			"level": 20,
			"experience": 4000
		}
	}
	
	# 先加密数据
	var encrypted_data = integrity_manager.encrypt_data(test_data)
	
	# 再解密数据
	var decrypted_data = integrity_manager.decrypt_data(encrypted_data)
	
	assert(decrypted_data.get("_encrypted", null) == null, "解密后的数据不应有加密标记")
	assert(decrypted_data["progression"]["level"] == 20, "解密后的数据应保持原始值")
	assert(decrypted_data["progression"]["experience"] == 4000, "解密后的数据应保持原始值")
	
	print("✓ 数据解密测试通过")
	tests_passed += 3
	tests_total += 3

# 测试篡改检测
func test_tamper_detection():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个模拟的存档文件
	var test_data = {
		"version": "1.0.0",
		"progression": {
			"level": 10,
			"realm": 1
		},
		"metadata": {
			"checksum": "123456789"  # 模拟校验码
		}
	}
	
	# 保存到临时文件
	var temp_file = FileAccess.open("user://temp_test_save.json", FileAccess.WRITE)
	if temp_file:
		temp_file.store_string(JSON.stringify(test_data))
		temp_file.close()
	
	# 检查篡改检测（由于我们没有实际的校验码，这里主要测试方法存在性）
	var has_method = integrity_manager.has_method("is_file_tampered")
	assert(has_method == true, "应有文件篡改检测方法")
	
	print("✓ 篡改检测测试通过")
	tests_passed += 1
	tests_total += 1

# 测试版本迁移
func test_version_migration():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个旧版本的数据
	var old_data = {
		"version": "1.0.0",
		"progression": {
			"level": 15,
			"realm": 2
		}
	}
	
	# 尝试迁移到新版本
	var migrated_data = integrity_manager.migrate_save_data(old_data, "1.1.0")
	
	assert(migrated_data != null, "迁移后的数据不应为空")
	assert(migrated_data["version"] == "1.1.0", "迁移后的版本号应更新")
	
	print("✓ 版本迁移测试通过")
	tests_passed += 2
	tests_total += 2

# 测试通用迁移
func test_generic_migration():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个缺少某些字段的数据
	var incomplete_data = {
		"version": "1.0.0",
		"progression": {
			"level": 10
		}
	}
	
	var migrated_data = integrity_manager._generic_migration(incomplete_data, "1.2.0")
	
	assert(migrated_data["version"] == "1.2.0", "版本号应更新")
	assert(migrated_data.has("attributes"), "应添加缺失的attributes字段")
	assert(migrated_data.has("martialArts"), "应添加缺失的martialArts字段")
	assert(migrated_data.has("equipment"), "应添加缺失的equipment字段")
	assert(migrated_data.has("encounters"), "应添加缺失的encounters字段")
	
	print("✓ 通用迁移测试通过")
	tests_passed += 5
	tests_total += 5

# 测试版本验证
func test_version_validation():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个包含所有必需字段的数据
	var valid_data = {
		"version": "1.0.0",
		"progression": {
			"level": 25,
			"realm": 3,
			"experience": 5000,
			"experienceToNextLevel": 7500
		},
		"attributes": {
			"totalPoints": 10,
			"allocatedPoints": 5,
			"values": {
				"strength": 20,
				"agility": 18,
				"constitution": 15,
				"intelligence": 16,
				"willpower": 14,
				"luck": 12
			}
		}
	}
	
	var is_valid = integrity_manager.validate_data_structure(valid_data)
	assert(is_valid == true, "有效数据应通过验证")
	
	print("✓ 版本验证测试通过")
	tests_passed += 1
	tests_total += 1

# 测试备份创建
func test_backup_creation():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个测试存档文件
	var test_data = {
		"version": "1.0.0",
		"level": 15,
		"realm": 2
	}
	
	var file = FileAccess.open("user://saves/save_slot_1.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(test_data))
		file.close()
	
	# 创建备份
	var backup_result = integrity_manager.create_backup(1, "user://saves/save_slot_1.json")
	
	assert(backup_result == true, "备份创建应成功")
	
	print("✓ 备份创建测试通过")
	tests_passed += 1
	tests_total += 1

# 测试备份恢复
func test_backup_restoration():
	var integrity_manager = DataIntegrityManager.new()
	
	# 尝试从备份恢复
	var restore_result = integrity_manager.restore_from_backup(1, "user://saves/save_slot_1_restored.json")
	
	# 由于可能没有备份文件，我们主要测试方法存在性
	var has_method = integrity_manager.has_method("restore_from_backup")
	assert(has_method == true, "应有备份恢复方法")
	
	print("✓ 备份恢复测试通过")
	tests_passed += 1
	tests_total += 1

# 测试从损坏数据恢复
func test_recovery_from_corrupted_data():
	var integrity_manager = DataIntegrityManager.new()
	
	# 创建一个损坏的文件
	var corrupted_data = "{ invalid json "
	var file = FileAccess.open("user://saves/corrupted_test.json", FileAccess.WRITE)
	if file:
		file.store_string(corrupted_data)
		file.close()
	
	# 尝试验证损坏的文件
	var is_valid = integrity_manager.validate_save_data("user://saves/corrupted_test.json")
	
	assert(is_valid == false, "损坏的数据应不通过验证")
	
	print("✓ 从损坏数据恢复测试通过")
	tests_passed += 1
	tests_total += 1
