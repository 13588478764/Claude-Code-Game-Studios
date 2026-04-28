# 地点发现管理器
# 实现传送点解锁机制、解锁状态持久化、地图标记更新和主线强制解锁功能

extends Node

# 信号定义
signal location_discovered(location_id: String, location_name: String)
signal location_unlocked(location_id: String, location_name: String)
signal map_marker_updated(location_id: String)

# 常量定义
const SAVE_FILE_PATH = "user://discovered_locations.save"

# 地点数据结构
class LocationData:
	var id: String
	var name: String
	var region: String
	var is_discovered: bool
	var is_unlocked: bool
	var discovery_date: String
	var unlock_date: String
	
	func _init(p_id: String, p_name: String, p_region: String):
		id = p_id
		name = p_name
		region = p_region
		is_discovered = false
		is_unlocked = false
		discovery_date = ""
		unlock_date = ""

# 存储所有地点数据
var locations: Dictionary = {}

# 存储已发现的地点ID
var discovered_locations: Array = []

# 存储已解锁的地点ID
var unlocked_locations: Array = []

# 初始化
func _ready():
	# 添加示例地点
	add_location("qingyun_mountain", "青云山", "青州")
	add_location("jiangnan_town", "江南水乡", "江南")
	add_location("beast_mountain", "兽王山", "西域")
	add_location("dragon_temple", "龙王庙", "东海")
	add_location("heaven_peak", "天剑峰", "剑域")
	
	# 设置起始位置为已发现和已解锁
	if locations.has("qingyun_mountain"):
		var start_location = locations["qingyun_mountain"]
		start_location.is_discovered = true
		start_location.is_unlocked = true
		start_location.discovery_date = get_current_date()
		start_location.unlock_date = get_current_date()
		discovered_locations.append("qingyun_mountain")
		unlocked_locations.append("qingyun_mountain")
	
	# 尝试加载已保存的解锁状态
	load_discovered_locations()

# 添加地点
func add_location(location_id: String, name: String, region: String):
	var location = LocationData.new(location_id, name, region)
	locations[location_id] = location

# 发现地点
func discover_location(location_id: String) -> bool:
	if not locations.has(location_id):
		print("错误: 地点 %s 不存在" % location_id)
		return false
	
	var location = locations[location_id]
	
	# 如果地点已经发现，直接返回
	if location.is_discovered:
		print("地点 %s 已经被发现" % location.name)
		return true
	
	# 标记为已发现
	location.is_discovered = true
	location.discovery_date = get_current_date()
	
	# 添加到已发现列表
	if not discovered_locations.has(location_id):
		discovered_locations.append(location_id)
	
	# 发射发现信号
	location_discovered.emit(location_id, location.name)
	
	# 自动解锁地点
	unlock_location(location_id)
	
	return true

# 解锁地点
func unlock_location(location_id: String) -> bool:
	if not locations.has(location_id):
		print("错误: 地点 %s 不存在" % location_id)
		return false
	
	var location = locations[location_id]
	
	# 如果地点已经解锁，直接返回
	if location.is_unlocked:
		print("地点 %s 已经被解锁" % location.name)
		return true
	
	# 检查地点是否已发现（解锁前必须先发现）
	if not location.is_discovered:
		print("错误: 地点 %s 必须先被发现才能解锁" % location.name)
		return false
	
	# 标记为已解锁
	location.is_unlocked = true
	location.unlock_date = get_current_date()
	
	# 添加到已解锁列表
	if not unlocked_locations.has(location_id):
		unlocked_locations.append(location_id)
	
	# 发射解锁信号
	location_unlocked.emit(location_id, location.name)
	
	# 发射地图标记更新信号
	map_marker_updated.emit(location_id)
	
	return true

# 检查地点是否已解锁
func is_location_unlocked(location_id: String) -> bool:
	if not locations.has(location_id):
		return false
	
	return locations[location_id].is_unlocked

# 检查地点是否已发现
func is_location_discovered(location_id: String) -> bool:
	if not locations.has(location_id):
		return false
	
	return locations[location_id].is_discovered

# 获取地点信息
func get_location_info(location_id: String) -> Dictionary:
	if not locations.has(location_id):
		return {}
	
	var location = locations[location_id]
	return {
		"id": location.id,
		"name": location.name,
		"region": location.region,
		"is_discovered": location.is_discovered,
		"is_unlocked": location.is_unlocked,
		"discovery_date": location.discovery_date,
		"unlock_date": location.unlock_date
	}

# 获取所有已发现的地点
func get_all_discovered_locations() -> Array:
	var result = []
	for location_id in discovered_locations:
		if locations.has(location_id):
			result.append(locations[location_id])
	return result

# 获取所有已解锁的地点
func get_all_unlocked_locations() -> Array:
	var result = []
	for location_id in unlocked_locations:
		if locations.has(location_id):
			result.append(locations[location_id])
	return result

# 获取所有地点
func get_all_locations() -> Array:
	var result = []
	for location_id in locations:
		result.append(locations[location_id])
	return result

# 保存已发现的地点状态
func save_discovered_locations():
	var save_data = {
		"discovered": discovered_locations,
		"unlocked": unlocked_locations,
		"timestamp": get_current_date()
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("已保存地点发现状态")
	else:
		print("错误: 无法保存地点发现状态")

# 加载已发现的地点状态
func load_discovered_locations():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("无已保存的地点发现状态")
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(content)
		
		if parse_result == OK and json.data is Dictionary:
			var save_data = json.data
			
			# 恢复已发现的地点
			if save_data.has("discovered"):
				discovered_locations = save_data.discovered
				for location_id in discovered_locations:
					if locations.has(location_id):
						locations[location_id].is_discovered = true
						# 如果之前没有发现日期，设置为当前日期
						if locations[location_id].discovery_date == "":
							locations[location_id].discovery_date = get_current_date()
			
			# 恢复已解锁的地点
			if save_data.has("unlocked"):
				unlocked_locations = save_data.unlocked
				for location_id in unlocked_locations:
					if locations.has(location_id):
						locations[location_id].is_unlocked = true
						# 如果之前没有解锁日期，设置为当前日期
						if locations[location_id].unlock_date == "":
							locations[location_id].unlock_date = get_current_date()
			
			print("已加载地点发现状态")
			return true
		else:
			print("错误: 无法解析保存的地点发现状态")
			return false
	else:
		print("错误: 无法加载地点发现状态")
		return false

# 获取当前日期字符串
func get_current_date() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]

# 强制解锁地点（用于主线任务）
func force_unlock_location_by_quest(location_id: String) -> bool:
	if not locations.has(location_id):
		print("错误: 地点 %s 不存在" % location_id)
		return false
	
	var location = locations[location_id]
	
	# 即使未发现，也强制解锁
	if not location.is_discovered:
		# 先标记为已发现
		location.is_discovered = true
		location.discovery_date = get_current_date()
		if not discovered_locations.has(location_id):
			discovered_locations.append(location_id)
	
	# 然后解锁
	return unlock_location(location_id)

# 更新地图标记
func update_map_markers():
	# 这里会通知地图系统更新标记
	# 暂时只打印信息
	for location_id in unlocked_locations:
		map_marker_updated.emit(location_id)
	
	print("地图标记已更新")

# 获取可旅行的地点（已解锁的地点）
func get_traversable_locations() -> Array:
	var result = []
	for location_id in unlocked_locations:
		if locations.has(location_id):
			result.append(locations[location_id])
	return result

# 重置发现状态（仅用于测试）
func reset_discovery_status():
	discovered_locations.clear()
	unlocked_locations.clear()
	
	for location_id in locations:
		var location = locations[location_id]
		location.is_discovered = false
		location.is_unlocked = false
		location.discovery_date = ""
		location.unlock_date = ""
	
	# 重新设置起始位置
	if locations.has("qingyun_mountain"):
		var start_location = locations["qingyun_mountain"]
		start_location.is_discovered = true
		start_location.is_unlocked = true
		start_location.discovery_date = get_current_date()
		start_location.unlock_date = get_current_date()
		discovered_locations.append("qingyun_mountain")
		unlocked_locations.append("qingyun_mountain")
	
	print("发现状态已重置")