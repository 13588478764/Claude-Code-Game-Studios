# 武侠奇遇录 - 数据库管理器
# 负责加载和管理所有游戏数据：武学、物品、敌人等

extends Node

# 数据库字典
var martial_arts_db = {}  # 武学数据库
var items_db = {}         # 物品数据库  
var enemies_db = {}       # 敌人数据库
var encounters_db = {}    # 奇遇数据库

# 加载状态
var is_loaded = false

func _ready():
	# 在游戏启动时自动加载数据库
	load_all_databases()

func load_all_databases():
	"""加载所有数据库"""
	if is_loaded:
		return
	
	# 加载武学数据库
	martial_arts_db = load_database("res://data/martial_arts.json")
	
	# 加载物品数据库  
	items_db = load_database("res://data/items.json")
	
	# 加载敌人数据库
	enemies_db = load_database("res://data/enemies.json")
	
	# 加载奇遇数据库
	encounters_db = load_database("res://data/encounters.json")
	
	is_loaded = true
	print("所有数据库加载完成")

func load_database(file_path):
	"""通用数据库加载函数"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开数据库文件: " + file_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	if parse_result != OK:
		push_error("JSON解析失败: " + file_path + " - " + str(json.get_error_line()) + " - " + json.get_error_message())
		return {}
	
	return json.data

func get_martial_art(martial_art_id):
	"""获取指定武学"""
	if martial_arts_db.has(martial_art_id):
		return martial_arts_db[martial_art_id]
	else:
		push_warning("武学未找到: " + martial_art_id)
		return null

func get_item(item_id):
	"""获取指定物品"""
	if items_db.has(item_id):
		return items_db[item_id]
	else:
		push_warning("物品未找到: " + item_id)
		return null

func get_enemy(enemy_id):
	"""获取指定敌人"""
	if enemies_db.has(enemy_id):
		return enemies_db[enemy_id]
	else:
		push_warning("敌人未找到: " + enemy_id)
		return null

func get_encounter(encounter_id):
	"""获取指定奇遇"""
	if encounters_db.has(encounter_id):
		return encounters_db[encounter_id]
	else:
		push_warning("奇遇未找到: " + encounter_id)
		return null

# 获取所有武学ID列表
func get_all_martial_art_ids():
	return martial_arts_db.keys()

# 获取所有物品ID列表  
func get_all_item_ids():
	return items_db.keys()

# 获取所有敌人ID列表
func get_all_enemy_ids():
	return enemies_db.keys()

# 获取所有奇遇ID列表
func get_all_encounter_ids():
	return encounters_db.keys()