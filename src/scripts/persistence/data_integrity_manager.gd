# 数据完整性管理器
# 实现数据完整性验证、防篡改机制、版本兼容性管理和错误恢复机制

extends Node

class_name DataIntegrityManager

# 信号定义
signal integrity_check_passed(file_path: String)
signal integrity_check_failed(file_path: String, error: String)
signal data_migrated(from_version: String, to_version: String)
signal recovery_attempted(original_file: String, source: String, success: bool)

# 常量定义
const CRC_POLYNOMIAL = 0xEDB88320
const BACKUP_DIR = "user://saves/"
const BACKUP_PATTERN = "save_slot_%d_backup_%d.json"

# 版本迁移映射
var version_migrations: Dictionary = {}

# 初始化
func _ready():
	# 初始化版本迁移函数
	_initialize_migrations()

# 初始化版本迁移函数
func _initialize_migrations():
	# 这里可以定义不同版本之间的迁移函数
	# 例如，从1.0.0迁移到1.1.0的函数
	version_migrations["1.0.0_to_1.1.0"] = Callable(self, "_migrate_1_0_0_to_1_1_0")

# 验证存档数据完整性
func validate_save_data(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		emit_signal("integrity_check_failed", file_path, "文件不存在")
		return false
	
	# 读取文件内容
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		emit_signal("integrity_check_failed", file_path, "无法打开文件")
		return false
	
	var file_content = file.get_as_text()
	file.close()
	
	# 计算CRC校验码
	var calculated_checksum = _calculate_crc32(file_content)
	
	# 解析JSON内容
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	if parse_result != OK:
		emit_signal("integrity_check_failed", file_path, "JSON解析失败")
		return false
	
	var save_data = json.data
	if not save_data is Dictionary:
		emit_signal("integrity_check_failed", file_path, "存档数据格式错误")
		return false
	
	# 检查元数据中的校验码
	if "metadata" in save_data and "checksum" in save_data["metadata"]:
		var stored_checksum = save_data["metadata"]["checksum"]
		if str(calculated_checksum) != stored_checksum:
			emit_signal("integrity_check_failed", file_path, "校验码不匹配")
			return false
	
	emit_signal("integrity_check_passed", file_path)
	return true

# 计算CRC32校验码
func _calculate_crc32(data: String) -> int:
	var crc = 0xFFFFFFFF
	var bytes = data.to_utf8_buffer()
	
	for byte in bytes:
		var table_index = (crc ^ byte) & 0xFF
		crc = (crc >> 8) ^ _get_crc_table_entry(table_index)
	
	return crc ^ 0xFFFFFFFF

# 获取CRC表条目（简化实现）
func _get_crc_table_entry(index: int) -> int:
	var entry = 0
	for i in range(8):
		if (index ^ entry) & 1:
			entry = (entry >> 1) ^ CRC_POLYNOMIAL
		else:
			entry >>= 1
		index >>= 1
	return entry

# 简单加密（防篡改）
func encrypt_data(data: Dictionary) -> Dictionary:
	# 这里实现简单的加密逻辑
	# 实际应用中应使用更安全的加密算法
	var encrypted_data = data.duplicate(true)
	
	# 对敏感数据进行简单变换
	if "progression" in encrypted_data:
		var prog = encrypted_data["progression"]
		if "experience" in prog:
			prog["experience"] = prog["experience"] ^ 0x5A5A  # XOR加密
		if "level" in prog:
			prog["level"] = prog["level"] ^ 0xA5A5  # XOR加密
	
	# 添加加密标记
	encrypted_data["_encrypted"] = true
	
	return encrypted_data

# 解密数据
func decrypt_data(data: Dictionary) -> Dictionary:
	if not data.get("_encrypted", false):
		return data  # 如果未加密，直接返回
	
	var decrypted_data = data.duplicate(true)
	
	# 对加密的数据进行解密
	if "progression" in decrypted_data:
		var prog = decrypted_data["progression"]
		if "experience" in prog:
			prog["experience"] = prog["experience"] ^ 0x5A5A  # XOR解密
		if "level" in prog:
			prog["level"] = prog["level"] ^ 0xA5A5  # XOR解密
	
	# 移除加密标记
	decrypted_data.erase("_encrypted")
	
	return decrypted_data

# 数据版本迁移
func migrate_save_data(old_data: Dictionary, target_version: String) -> Dictionary:
	var current_version = old_data.get("version", "1.0.0")
	
	if current_version == target_version:
		return old_data  # 版本相同，无需迁移
	
	# 查找迁移路径
	var migration_key = "%s_to_%s" % [current_version, target_version]
	if migration_key in version_migrations:
		var migration_func = version_migrations[migration_key]
		if migration_func and migration_func.is_valid():
			var migrated_data = migration_func.call(old_data)
			emit_signal("data_migrated", current_version, target_version)
			return migrated_data
		else:
			print("警告: 未找到有效的迁移函数: %s" % migration_key)
	else:
		print("警告: 未找到从 %s 到 %s 的迁移路径" % [current_version, target_version])
	
	# 如果找不到特定迁移路径，尝试通用迁移
	return _generic_migration(old_data, target_version)

# 通用迁移函数
func _generic_migration(data: Dictionary, target_version: String) -> Dictionary:
	# 确保版本号正确
	data["version"] = target_version
	
	# 确保所有必需的字段都存在
	if "progression" not in data:
		data["progression"] = {}
	if "attributes" not in data:
		data["attributes"] = {}
	if "martialArts" not in data:
		data["martialArts"] = {}
	if "equipment" not in data:
		data["equipment"] = {}
	if "encounters" not in data:
		data["encounters"] = {}
	
	return data

# 从1.0.0迁移到1.1.0的示例迁移函数
func _migrate_1_0_0_to_1_1_0(data: Dictionary) -> Dictionary:
	# 假设1.1.0版本添加了新的字段
	if "new_feature" not in data:
		data["new_feature"] = {}  # 添加新功能的默认数据
	
	# 更新版本号
	data["version"] = "1.1.0"
	
	return data

# 创建备份
func create_backup(save_slot: int, source_path: String) -> bool:
	var dir = DirAccess.open(BACKUP_DIR)
	if not dir:
		return false
	
	if not dir.file_exists(source_path):
		return false
	
	# 生成备份文件名（使用时间戳）
	var timestamp = Time.get_unix_time_from_system()
	var backup_filename = (BACKUP_PATTERN % [save_slot, timestamp])
	var backup_path = BACKUP_DIR + backup_filename
	
	# 复制文件
	var error = dir.copy(source_path, backup_path)
	if error != OK:
		return false
	
	# 清理旧备份
	_cleanup_old_backups(save_slot)
	
	return true

# 清理旧备份
func _cleanup_old_backups(save_slot: int):
	var dir = DirAccess.open(BACKUP_DIR)
	if not dir:
		return
	
	var backup_files = []
	var backup_pattern = "save_slot_%d_backup" % save_slot
	
	for file in dir.get_files():
		if file.begins_with(backup_pattern):
			backup_files.append(file)
	
	# 按文件名排序（时间戳）
	backup_files.sort()
	
	# 保留最新的3个备份，删除其余的
	var max_backups = 3
	while backup_files.size() > max_backups:
		var oldest_backup = backup_files[0]
		dir.remove(BACKUP_DIR + oldest_backup)
		backup_files.remove_at(0)

# 从备份恢复数据
func restore_from_backup(save_slot: int, target_path: String) -> bool:
	var dir = DirAccess.open(BACKUP_DIR)
	if not dir:
		return false
	
	# 查找最新的备份文件
	var backup_files = []
	var backup_pattern = "save_slot_%d_backup" % save_slot
	
	for file in dir.get_files():
		if file.begins_with(backup_pattern):
			backup_files.append(file)
	
	if backup_files.is_empty():
		emit_signal("recovery_attempted", target_path, "无备份可用", false)
		return false
	
	# 按时间戳排序，获取最新的备份
	backup_files.sort()
	var latest_backup = backup_files[-1]
	var source_path = BACKUP_DIR + latest_backup
	
	# 验证备份文件的完整性
	if not validate_save_data(source_path):
		emit_signal("recovery_attempted", target_path, source_path, false)
		return false
	
	# 复制备份到目标路径
	var error = dir.copy(source_path, target_path)
	if error != OK:
		emit_signal("recovery_attempted", target_path, source_path, false)
		return false
	
	emit_signal("recovery_attempted", target_path, source_path, true)
	return true

# 验证数据结构完整性
func validate_data_structure(data: Dictionary) -> bool:
	# 检查必需的顶级字段
	if "version" not in data:
		return false
	
	if "progression" not in data:
		return false
	
	if "attributes" not in data:
		return false
	
	# 验证进度数据
	var progression = data["progression"]
	if not progression is Dictionary:
		return false
	
	if "level" not in progression or progression["level"] < 1 or progression["level"] > 99:
		return false
	
	if "realm" not in progression or progression["realm"] < 0 or progression["realm"] > 9:
		return false
	
	# 验证属性数据
	var attributes = data["attributes"]
	if not attributes is Dictionary:
		return false
	
	if "values" not in attributes or not attributes["values"] is Dictionary:
		return false
	
	# 检查属性值是否为非负数
	for attr_name in attributes["values"]:
		var attr_value = attributes["values"][attr_name]
		if attr_value < 0:
			return false
	
	return true

# 生成校验码
func generate_checksum(data: Dictionary) -> String:
	var json_string = JSON.stringify(data)
	return str(_calculate_crc32(json_string))

# 验证文件是否被篡改
func is_file_tampered(file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		return true  # 文件不存在，视为被篡改
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return true  # 无法打开文件，视为被篡改
	
	var file_content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(file_content)
	if parse_result != OK:
		return true  # JSON解析失败，视为被篡改
	
	var save_data = json.data
	if not save_data is Dictionary:
		return true  # 数据格式错误，视为被篡改
	
	# 检查是否有加密标记
	if "_encrypted" in save_data:
		# 如果有加密标记，需要先解密再验证
		var decrypted_data = decrypt_data(save_data)
		var decrypted_json = JSON.stringify(decrypted_data)
		var calculated_checksum = _calculate_crc32(decrypted_json)
		
		if "metadata" in save_data and "checksum" in save_data["metadata"]:
			var stored_checksum = save_data["metadata"]["checksum"]
			return str(calculated_checksum) != stored_checksum
	else:
		# 没有加密，直接验证
		var calculated_checksum = _calculate_crc32(file_content)
		
		if "metadata" in save_data and "checksum" in save_data["metadata"]:
			var stored_checksum = save_data["metadata"]["checksum"]
			return str(calculated_checksum) != stored_checksum
	
	return false