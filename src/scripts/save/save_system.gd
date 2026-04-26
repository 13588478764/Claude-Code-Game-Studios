# 武侠奇遇录 - 存档系统
# 负责管理游戏进度的保存和加载

extends Node

# 存档配置
var config = {
	"save_slots": 5,                    # 存档槽数量
	"auto_save_enabled": true,         # 自动存档启用
	"auto_save_interval": 300,        # 自动存档间隔（秒）
	"cloud_save_enabled": true,        # 云存档启用（Steam）
	"save_file_extension": ".wuxia",   # 存档文件扩展名
	"save_directory": "user://saves/", # 存档目录
	"backup_enabled": true,            # 备份启用
	"max_backups": 3                  # 最大备份数量
}

# 存档数据结构
class SaveData:
	var version = "1.0.0"
	var timestamp = 0
	var character_data = {}
	var equipment_data = {}
	var inventory_data = {}
	var quest_data = {}
	var encounter_data = {}
	var world_state = {}
	var settings = {}

# 当前存档状态
var current_save_slot = 0
var last_auto_save_time = 0
var is_saving = false
var is_loading = false

func _ready():
	print("存档系统初始化完成")
	setup_save_directory()

func setup_save_directory():
	"""设置存档目录"""
	var dir = DirAccess.open(config["save_directory"])
	if not dir:
		DirAccess.make_dir_recursive_absolute(config["save_directory"])
		print("创建存档目录: %s" % config["save_directory"])

func create_save_data():
	"""创建当前游戏状态的存档数据"""
	var save_data = SaveData.new()
	save_data.timestamp = Time.get_unix_time_from_system()
	
	# 保存角色数据
	save_data.character_data = get_character_data()
	
	# 保存装备数据
	save_data.equipment_data = get_equipment_data()
	
	# 保存背包数据
	save_data.inventory_data = get_inventory_data()
	
	# 保存任务数据
	save_data.quest_data = get_quest_data()
	
	# 保存奇遇数据
	save_data.encounter_data = get_encounter_data()
	
	# 保存世界状态
	save_data.world_state = get_world_state()
	
	# 保存设置
	save_data.settings = get_settings_data()
	
	return save_data

func get_character_data():
	"""获取角色数据"""
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system == null:
		push_warning("无法访问CharacterSystem")
		return {}
	return {
		"level": character_system.level,
		"experience": character_system.experience,
		"total_attribute_points": character_system.total_attribute_points,
		"allocated_attribute_points": character_system.allocated_attribute_points,
		"attributes": character_system.attributes.get_total(),
		"realm_index": character_system.realm_index,
		"realm_bonus": character_system.realm_bonus,
		"free_reset_count": character_system.free_reset_count
	}

func get_equipment_data():
	"""获取装备数据"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system == null:
		push_warning("无法访问EquipmentSystem")
		return {"equipped_items": {}, "gem_slots": {}, "appearance_overrides": {}}
	return {
		"equipped_items": equipment_system.equipped_items.duplicate(),
		"gem_slots": duplicate_gem_slots(),
		"appearance_overrides": equipment_system.appearance_overrides.duplicate()
	}

func duplicate_gem_slots():
	"""深度复制宝石槽位数据"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system == null:
		push_warning("无法访问EquipmentSystem")
		return {}
	var copied_slots = {}
	for slot in equipment_system.gem_slots:
		copied_slots[slot] = []
		for gem in equipment_system.gem_slots[slot]:
			copied_slots[slot].append(gem)
	return copied_slots

func get_inventory_data():
	"""获取背包数据"""
	# 这里应该从物品系统获取背包数据
	# 简化实现：返回空数据
	return {
		"items": {},
		"gold": 0,
		"materials": {}
	}

func get_quest_data():
	"""获取任务数据"""
	# 这里应该从任务系统获取任务数据
	# 简化实现：返回空数据
	return {
		"active_quests": [],
		"completed_quests": [],
		"quest_progress": {}
	}

func get_encounter_data():
	"""获取奇遇数据"""
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	if encounter_system == null:
		push_warning("无法访问EncounterSystem")
		return {
			"completed_encounters": [],
			"consecutive_failures": 0,
			"current_move_count": 0,
			"last_trigger_move_count": 0
		}
	return {
		"completed_encounters": encounter_system.completed_encounters.duplicate(),
		"consecutive_failures": encounter_system.consecutive_failures,
		"current_move_count": encounter_system.current_move_count,
		"last_trigger_move_count": encounter_system.last_trigger_move_count
	}

func get_world_state():
	"""获取世界状态数据"""
	# 这里应该从世界系统获取世界状态
	# 简化实现：返回基本数据
	return {
		"current_location": "start_village",
		"discovered_locations": ["start_village"],
		"game_time": 0
	}

func get_settings_data():
	"""获取设置数据"""
	# 这里应该从设置系统获取设置数据
	# 简化实现：返回基本设置
	return {
		"music_volume": 0.8,
		"sfx_volume": 0.9,
		"language": "zh-CN",
		"graphics_quality": "high"
	}

func save_to_slot(slot_index):
	"""保存到指定槽位"""
	if is_saving:
		return false
	
	if slot_index < 0 or slot_index >= config["save_slots"]:
		push_warning("无效的存档槽位: %d" % slot_index)
		return false
	
	is_saving = true
	
	# 创建存档数据
	var save_data = create_save_data()
	
	# 将SaveData对象转换为字典以便JSON序列化
	var save_dict = {
		"version": save_data.version,
		"timestamp": save_data.timestamp,
		"character_data": save_data.character_data,
		"equipment_data": save_data.equipment_data,
		"inventory_data": save_data.inventory_data,
		"quest_data": save_data.quest_data,
		"encounter_data": save_data.encounter_data,
		"world_state": save_data.world_state,
		"settings": save_data.settings
	}
	
	# 序列化为JSON
	var json_string = JSON.stringify(save_dict, "\t")
	
	# 创建备份（如果启用）
	if config["backup_enabled"]:
		create_backup(slot_index)
	
	# 保存文件
	var save_path = get_save_path(slot_index)
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("无法创建存档文件: %s" % save_path)
		is_saving = false
		return false
	
	file.store_string(json_string)
	file.close()
	
	# 更新云存档（如果启用）
	if config["cloud_save_enabled"]:
		update_cloud_save(slot_index)
	
	current_save_slot = slot_index
	last_auto_save_time = Time.get_unix_time_from_system()
	is_saving = false
	
	print("存档成功: 槽位 %d" % slot_index)
	return true

func load_from_slot(slot_index):
	"""从指定槽位加载"""
	if is_loading:
		return null
	
	if slot_index < 0 or slot_index >= config["save_slots"]:
		push_warning("无效的存档槽位: %d" % slot_index)
		return null
	
	var save_path = get_save_path(slot_index)
	if not FileAccess.file_exists(save_path):
		push_warning("存档文件不存在: %s" % save_path)
		return null
	
	is_loading = true
	
	# 读取存档文件内容
	var file_content = FileAccess.get_file_as_string(save_path)
	
	# 检查file_content是否真的是字符串类型
	if typeof(file_content) != TYPE_STRING:
		push_error("存档文件读取失败: 读取的内容不是字符串类型，而是: %s" % typeof(file_content))
		is_loading = false
		return null
	
	# 将file_content赋值给json_string
	var json_string = file_content
	
	# 确保json_string不为空
	if json_string.length() == 0:
		push_error("存档文件读取失败: 文件内容为空")
		is_loading = false
		return null
	
	# 解析JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("存档文件解析失败: %s, 错误: %s" % [save_path, json.error_message])
		is_loading = false
		return null
	
	var save_data = json.data
	
	# 检查解析后的数据是否为有效的字典
	if typeof(save_data) != TYPE_DICTIONARY:
		push_error("存档文件格式错误: %s, 解析结果类型: %s, 原始内容: %s" % [save_path, typeof(save_data), json_string])
		is_loading = false
		return null
	
	# 应用存档数据
	apply_save_data(save_data)
	
	current_save_slot = slot_index
	is_loading = false
	
	print("加载成功: 槽位 %d" % slot_index)
	return save_data

func apply_save_data(save_data):
	"""应用存档数据到游戏系统"""
	# 检查save_data是否为有效字典
	if typeof(save_data) != TYPE_DICTIONARY or save_data == null:
		push_error("无效的存档数据: %s, 类型: %s" % [str(save_data), typeof(save_data)])
		return
	
	# 应用角色数据
	if save_data.has("character_data") and typeof(save_data["character_data"]) == TYPE_DICTIONARY:
		apply_character_data(save_data["character_data"])
	else:
		push_warning("存档数据中缺少或无效的character_data字段")
	
	# 应用装备数据
	if save_data.has("equipment_data") and typeof(save_data["equipment_data"]) == TYPE_DICTIONARY:
		apply_equipment_data(save_data["equipment_data"])
	else:
		push_warning("存档数据中缺少或无效的equipment_data字段")
	
	# 应用背包数据
	if save_data.has("inventory_data") and typeof(save_data["inventory_data"]) == TYPE_DICTIONARY:
		apply_inventory_data(save_data["inventory_data"])
	else:
		push_warning("存档数据中缺少或无效的inventory_data字段")
	
	# 应用任务数据
	if save_data.has("quest_data") and typeof(save_data["quest_data"]) == TYPE_DICTIONARY:
		apply_quest_data(save_data["quest_data"])
	else:
		push_warning("存档数据中缺少或无效的quest_data字段")
	
	# 应用奇遇数据
	if save_data.has("encounter_data") and typeof(save_data["encounter_data"]) == TYPE_DICTIONARY:
		apply_encounter_data(save_data["encounter_data"])
	else:
		push_warning("存档数据中缺少或无效的encounter_data字段")
	
	# 应用世界状态
	if save_data.has("world_state") and typeof(save_data["world_state"]) == TYPE_DICTIONARY:
		apply_world_state(save_data["world_state"])
	else:
		push_warning("存档数据中缺少或无效的world_state字段")
	
	# 应用设置
	if save_data.has("settings") and typeof(save_data["settings"]) == TYPE_DICTIONARY:
		apply_settings_data(save_data["settings"])
	else:
		push_warning("存档数据中缺少或无效的settings字段")

func apply_character_data(character_data):
	"""应用角色数据"""
	var character_system = get_node_or_null("/root/CharacterSystem")
	if character_system != null:
		character_system.level = character_data["level"]
		character_system.experience = character_data["experience"]
		character_system.total_attribute_points = character_data["total_attribute_points"]
		character_system.allocated_attribute_points = character_data["allocated_attribute_points"]
		character_system.realm_index = character_data["realm_index"]
		character_system.realm_bonus = character_data["realm_bonus"]
		character_system.free_reset_count = character_data["free_reset_count"]
		
		# 恢复属性
		var attrs = character_data["attributes"]
		character_system.attributes.strength = attrs["strength"]
		character_system.attributes.agility = attrs["agility"]
		character_system.attributes.constitution = attrs["constitution"]
		character_system.attributes.intelligence = attrs["intelligence"]
		character_system.attributes.willpower = attrs["willpower"]
		character_system.attributes.luck = attrs["luck"]

func apply_equipment_data(equipment_data):
	"""应用装备数据"""
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	if equipment_system != null:
		equipment_system.equipped_items = equipment_data["equipped_items"].duplicate()
		equipment_system.appearance_overrides = equipment_data["appearance_overrides"].duplicate()
		
		# 恢复宝石槽位
		equipment_system.gem_slots.clear()
		for slot in equipment_data["gem_slots"]:
			equipment_system.gem_slots[slot] = []
			for gem in equipment_data["gem_slots"][slot]:
				equipment_system.gem_slots[slot].append(gem)

func apply_inventory_data(inventory_data):
	"""应用背包数据"""
	# 这里应该应用背包数据到物品系统
	# 简化实现：暂时不处理

func apply_quest_data(quest_data):
	"""应用任务数据"""
	# 这里应该应用任务数据到任务系统
	# 简化实现：暂时不处理

func apply_encounter_data(encounter_data):
	"""应用奇遇数据"""
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	if encounter_system != null:
		encounter_system.completed_encounters = encounter_data["completed_encounters"].duplicate()
		encounter_system.consecutive_failures = encounter_data["consecutive_failures"]
		encounter_system.current_move_count = encounter_data["current_move_count"]
		encounter_system.last_trigger_move_count = encounter_data["last_trigger_move_count"]

func apply_world_state(world_state):
	"""应用世界状态"""
	# 这里应该应用世界状态到世界系统
	# 简化实现：暂时不处理

func apply_settings_data(settings_data):
	"""应用设置数据"""
	# 这里应该应用设置数据到设置系统
	# 简化实现：暂时不处理

func get_save_path(slot_index):
	"""获取存档文件路径"""
	return config["save_directory"] + "save_" + str(slot_index) + config["save_file_extension"]

func create_backup(slot_index):
	"""创建备份"""
	var save_path = get_save_path(slot_index)
	if not FileAccess.file_exists(save_path):
		return
	
	# 删除旧备份
	for i in range(config["max_backups"] - 1, 0, -1):
		var old_backup = save_path + ".bak" + str(i)
		var new_backup = save_path + ".bak" + str(i + 1)
		if FileAccess.file_exists(old_backup):
			DirAccess.remove_absolute(old_backup)
			if FileAccess.file_exists(new_backup):
				DirAccess.rename_absolute(new_backup, old_backup)
	
	# 创建新备份
	var first_backup = save_path + ".bak1"
	# 使用DirAccess.copy()替代FileAccess.copy()
	var dir = DirAccess.open(config["save_directory"])
	if dir != null:
		dir.copy(save_path, first_backup)

func update_cloud_save(slot_index):
	"""更新云存档"""
	# 这里应该调用Steam API更新云存档
	# 简化实现：暂时只打印信息
	print("更新云存档: 槽位 %d" % slot_index)

func auto_save():
	"""自动存档"""
	if not config["auto_save_enabled"]:
		return
	
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_auto_save_time >= config["auto_save_interval"]:
		save_to_slot(current_save_slot)

func get_save_info(slot_index):
	"""获取存档信息"""
	var save_path = get_save_path(slot_index)
	if not FileAccess.file_exists(save_path):
		return {"exists": false}
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {"exists": false}
	
	# 正确读取文件内容
	var file_size = file.get_length()
	var file_bytes = file.get_buffer(file_size)
	var json_string = file_bytes.get_string_from_utf8()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return {"exists": false}
	
	var save_data = json.data
	return {
		"exists": true,
		"version": save_data.version,
		"timestamp": save_data.timestamp,
		"character_level": save_data.character_data["level"],
		"character_realm": save_data.character_data["realm_index"]
	}

func delete_save_slot(slot_index):
	"""删除存档槽位"""
	if slot_index < 0 or slot_index >= config["save_slots"]:
		return false
	
	var save_path = get_save_path(slot_index)
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		
		# 删除备份
		for i in range(1, config["max_backups"] + 1):
			var backup_path = save_path + ".bak" + str(i)
			if FileAccess.file_exists(backup_path):
				DirAccess.remove_absolute(backup_path)
		
		print("删除存档: 槽位 %d" % slot_index)
		return true
	
	return false

# 调试函数
func debug_print_save_info():
	"""打印存档信息用于调试"""
	print("=== 存档系统信息 ===")
	print("当前槽位: %d" % current_save_slot)
	print("最后自动存档时间: %d" % last_auto_save_time)
	print("正在保存: %s" % ("是" if is_saving else "否"))
	print("正在加载: %s" % ("是" if is_loading else "否"))
	
	# 打印所有槽位信息
	for i in range(config["save_slots"]):
		var info = get_save_info(i)
		if info["exists"]:
			print("槽位 %d: 等级 %d, 境界 %d, 时间 %d" % [
				i, info["character_level"], info["character_realm"], info["timestamp"]
			])
		else:
			print("槽位 %d: 空" % i)
	
	print("====================")

# UI回调函数
func _on_test_save_load_pressed():
	"""测试存档加载按钮回调"""
	print("=== 存档加载测试 ===")
	
	# 初始化测试数据
	var character_system = get_node_or_null("/root/CharacterSystem")
	var equipment_system = get_node_or_null("/root/EquipmentSystem")
	var encounter_system = get_node_or_null("/root/EncounterSystem")
	
	if character_system != null:
		character_system.initialize_character()
		character_system.add_experience(1000)  # 升级到10级
	
	if equipment_system != null:
		equipment_system.equip_item("common_sword", 10, 1)
		equipment_system.equip_item("rare_helmet", 10, 1)
	
	if encounter_system != null:
		encounter_system.completed_encounters = ["jianghu_rumor", "heavenly_treasure"]
		encounter_system.consecutive_failures = 5
		encounter_system.current_move_count = 10
	
	# 保存到槽位0
	var save_success = save_to_slot(0)
	print("保存结果: %s" % ("成功" if save_success else "失败"))
	
	# 修改当前数据
	if character_system != null:
		character_system.level = 1
		character_system.experience = 0
	
	if equipment_system != null:
		equipment_system.equipped_items[equipment_system.EquipmentSlot.WEAPON_MAIN] = null
	
	if encounter_system != null:
		encounter_system.completed_encounters.clear()
	
	# 从槽位0加载
	var loaded_data = load_from_slot(0)
	if loaded_data != null:
		print("加载成功！")
		if character_system != null:
			print("加载的角色等级: %d" % character_system.level)
		if equipment_system != null:
			print("加载的装备: %s" % equipment_system.equipped_items[equipment_system.EquipmentSlot.WEAPON_MAIN])
		if encounter_system != null:
			print("加载的奇遇完成数: %d" % encounter_system.completed_encounters.size())
	else:
		print("加载失败！")
	
	print("====================")

func _on_test_auto_save_pressed():
	"""测试自动存档按钮回调"""
	print("=== 自动存档测试 ===")
	
	# 设置上次存档时间为很久以前
	last_auto_save_time = Time.get_unix_time_from_system() - config["auto_save_interval"] - 10
	
	# 触发自动存档
	auto_save()
	
	# 检查是否成功
	var info = get_save_info(current_save_slot)
	print("自动存档结果: %s" % ("成功" if info["exists"] else "失败"))
	if info["exists"]:
		print("存档时间: %d" % info["timestamp"])
	
	print("====================")

func _on_test_backup_pressed():
	"""测试备份功能按钮回调"""
	print("=== 备份功能测试 ===")
	
	# 先保存一次
	save_to_slot(1)
	
	# 再保存一次（应该创建备份）
	save_to_slot(1)
	
	# 检查备份文件是否存在
	var save_path = get_save_path(1)
	var backup_path = save_path + ".bak1"
	
	if FileAccess.file_exists(backup_path):
		print("备份创建成功: %s" % backup_path)
	else:
		print("备份创建失败")
	
	# 测试删除存档
	var delete_success = delete_save_slot(1)
	print("删除存档结果: %s" % ("成功" if delete_success else "失败"))
	
	print("====================")