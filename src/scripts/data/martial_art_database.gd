## MartialArtDatabase
## 功法数据库管理器
## 负责加载、管理和查询所有功法数据

class_name MartialArtDatabase
extends Node

# 信号定义
signal database_loaded()
signal martial_art_added(martial_art_id: String)
signal martial_art_removed(martial_art_id: String)

# 数据存储
var _martial_arts: Dictionary = {}  # key: martial_art_id, value: MartialArtData
var _martial_arts_by_type: Dictionary = {}  # key: MartialArtType, value: Array[String]
var _martial_arts_by_school: Dictionary = {}  # key: SchoolType, value: Array[String]
var _martial_arts_by_grade: Dictionary = {}  # key: GradeType, value: Array[String]
var _martial_arts_by_weapon: Dictionary = {}  # key: WeaponType, value: Array[String]

# 数据路径配置
const MARTIAL_ARTS_DATA_PATH = "res://data/martial_arts/"
const MARTIAL_ARTS_EXTENSION = ".tres"

# 加载状态
var _is_loaded: bool = false
var _load_errors: Array[String] = []

## 初始化数据库
func _ready() -> void:
	_initialize_categories()
	load_all_martial_arts()

## 初始化分类字典
func _initialize_categories() -> void:
	# 按类型分类
	for type in MartialArtData.MartialArtType.values():
		_martial_arts_by_type[type] = []
	
	# 按门派分类
	for school in MartialArtData.SchoolType.values():
		_martial_arts_by_school[school] = []
	
	# 按品阶分类
	for grade in MartialArtData.GradeType.values():
		_martial_arts_by_grade[grade] = []
	
	# 按武器分类
	for weapon in MartialArtData.WeaponType.values():
		_martial_arts_by_weapon[weapon] = []

## 加载所有功法数据
func load_all_martial_arts() -> void:
	_is_loaded = false
	_load_errors.clear()
	
	# 检查数据目录是否存在
	if not DirAccess.dir_exists_absolute(MARTIAL_ARTS_DATA_PATH):
		push_error("功法数据目录不存在: " + MARTIAL_ARTS_DATA_PATH)
		_load_errors.append("功法数据目录不存在")
		return
	
	# 扫描目录加载所有.tres文件
	var dir = DirAccess.open(MARTIAL_ARTS_DATA_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(MARTIAL_ARTS_EXTENSION):
				var file_path = MARTIAL_ARTS_DATA_PATH + file_name
				_load_martial_art_from_file(file_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		push_error("无法打开功法数据目录: " + MARTIAL_ARTS_DATA_PATH)
		_load_errors.append("无法打开功法数据目录")
		return
	
	_is_loaded = true
	print("功法数据库加载完成，共加载 %d 个功法" % _martial_arts.size())
	
	if _load_errors.size() > 0:
		print("加载过程中出现 %d 个错误" % _load_errors.size())
		for error in _load_errors:
			print("  - " + error)
	
	database_loaded.emit()

## 从文件加载单个功法数据
func _load_martial_art_from_file(file_path: String) -> void:
	var martial_art = load(file_path) as MartialArtData
	
	if martial_art == null:
		var error_msg = "无法加载功法数据: " + file_path
		push_error(error_msg)
		_load_errors.append(error_msg)
		return
	
	# 验证数据
	if not martial_art.validate():
		var error_msg = "功法数据验证失败: " + file_path
		push_error(error_msg)
		_load_errors.append(error_msg)
		return
	
	# 添加到数据库
	add_martial_art(martial_art)

## 添加功法到数据库
func add_martial_art(martial_art: MartialArtData) -> bool:
	if martial_art == null or martial_art.id.is_empty():
		push_error("无效的功法数据")
		return false
	
	# 检查是否已存在
	if _martial_arts.has(martial_art.id):
		push_warning("功法ID已存在，将覆盖: " + martial_art.id)
		remove_martial_art(martial_art.id)
	
	# 添加到主字典
	_martial_arts[martial_art.id] = martial_art
	
	# 添加到分类索引
	_martial_arts_by_type[martial_art.martial_art_type].append(martial_art.id)
	_martial_arts_by_school[martial_art.school].append(martial_art.id)
	_martial_arts_by_grade[martial_art.grade].append(martial_art.id)
	_martial_arts_by_weapon[martial_art.weapon_type].append(martial_art.id)
	
	martial_art_added.emit(martial_art.id)
	return true

## 移除功法
func remove_martial_art(martial_art_id: String) -> bool:
	if not _martial_arts.has(martial_art_id):
		return false
	
	var martial_art = _martial_arts[martial_art_id]
	
	# 从分类索引中移除
	_martial_arts_by_type[martial_art.martial_art_type].erase(martial_art_id)
	_martial_arts_by_school[martial_art.school].erase(martial_art_id)
	_martial_arts_by_grade[martial_art.grade].erase(martial_art_id)
	_martial_arts_by_weapon[martial_art.weapon_type].erase(martial_art_id)
	
	# 从主字典移除
	_martial_arts.erase(martial_art_id)
	
	martial_art_removed.emit(martial_art_id)
	return true

## 获取功法数据
func get_martial_art(martial_art_id: String) -> MartialArtData:
	return _martial_arts.get(martial_art_id, null)

## 检查功法是否存在
func has_martial_art(martial_art_id: String) -> bool:
	return _martial_arts.has(martial_art_id)

## 获取所有功法ID
func get_all_martial_art_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_martial_arts.keys())
	return ids

## 获取所有功法数据
func get_all_martial_arts() -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	for martial_art in _martial_arts.values():
		arts.append(martial_art)
	return arts

## 按类型获取功法
func get_martial_arts_by_type(type: MartialArtData.MartialArtType) -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	var ids = _martial_arts_by_type.get(type, [])
	for id in ids:
		var martial_art = get_martial_art(id)
		if martial_art:
			arts.append(martial_art)
	return arts

## 按门派获取功法
func get_martial_arts_by_school(school: MartialArtData.SchoolType) -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	var ids = _martial_arts_by_school.get(school, [])
	for id in ids:
		var martial_art = get_martial_art(id)
		if martial_art:
			arts.append(martial_art)
	return arts

## 按品阶获取功法
func get_martial_arts_by_grade(grade: MartialArtData.GradeType) -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	var ids = _martial_arts_by_grade.get(grade, [])
	for id in ids:
		var martial_art = get_martial_art(id)
		if martial_art:
			arts.append(martial_art)
	return arts

## 按武器类型获取功法
func get_martial_arts_by_weapon(weapon: MartialArtData.WeaponType) -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	var ids = _martial_arts_by_weapon.get(weapon, [])
	for id in ids:
		var martial_art = get_martial_art(id)
		if martial_art:
			arts.append(martial_art)
	return arts

## 按解锁等级筛选功法
func get_martial_arts_by_unlock_level(max_level: int) -> Array[MartialArtData]:
	var arts: Array[MartialArtData] = []
	for martial_art in _martial_arts.values():
		if martial_art.unlock_level <= max_level:
			arts.append(martial_art)
	return arts

## 多条件查询功法
func query_martial_arts(filters: Dictionary) -> Array[MartialArtData]:
	var results: Array[MartialArtData] = []
	
	for martial_art in _martial_arts.values():
		var is_match = true
		
		# 检查类型
		if filters.has("type") and martial_art.martial_art_type != filters["type"]:
			is_match = false
		
		# 检查门派
		if filters.has("school") and martial_art.school != filters["school"]:
			is_match = false
		
		# 检查品阶
		if filters.has("grade") and martial_art.grade != filters["grade"]:
			is_match = false
		
		# 检查武器
		if filters.has("weapon") and martial_art.weapon_type != filters["weapon"]:
			is_match = false
		
		# 检查解锁等级
		if filters.has("max_unlock_level") and martial_art.unlock_level > filters["max_unlock_level"]:
			is_match = false
		
		# 检查元素类型
		if filters.has("element") and martial_art.element_type != filters["element"]:
			is_match = false
		
		if is_match:
			results.append(martial_art)
	
	return results

## 获取数据库统计信息
func get_statistics() -> Dictionary:
	var stats = {
		"total_count": _martial_arts.size(),
		"by_type": {},
		"by_school": {},
		"by_grade": {},
		"by_weapon": {},
		"is_loaded": _is_loaded,
		"load_errors": _load_errors.size()
	}
	
	# 统计各类型数量
	for type in MartialArtData.MartialArtType.values():
		stats["by_type"][type] = _martial_arts_by_type[type].size()
	
	# 统计各门派数量
	for school in MartialArtData.SchoolType.values():
		stats["by_school"][school] = _martial_arts_by_school[school].size()
	
	# 统计各品阶数量
	for grade in MartialArtData.GradeType.values():
		stats["by_grade"][grade] = _martial_arts_by_grade[grade].size()
	
	# 统计各武器类型数量
	for weapon in MartialArtData.WeaponType.values():
		stats["by_weapon"][weapon] = _martial_arts_by_weapon[weapon].size()
	
	return stats

## 打印数据库统计信息
func print_statistics() -> void:
	var stats = get_statistics()
	print("=== 功法数据库统计 ===")
	print("总功法数: %d" % stats["total_count"])
	print("加载状态: %s" % ("已加载" if stats["is_loaded"] else "未加载"))
	print("加载错误: %d" % stats["load_errors"])
	
	print("\n按类型统计:")
	for type in stats["by_type"]:
		var type_name = MartialArtData.MartialArtType.keys()[type]
		print("  %s: %d" % [type_name, stats["by_type"][type]])
	
	print("\n按门派统计:")
	for school in stats["by_school"]:
		var school_name = MartialArtData.SchoolType.keys()[school]
		print("  %s: %d" % [school_name, stats["by_school"][school]])
	
	print("\n按品阶统计:")
	for grade in stats["by_grade"]:
		var grade_name = MartialArtData.GradeType.keys()[grade]
		print("  %s: %d" % [grade_name, stats["by_grade"][grade]])
	
	print("\n按武器统计:")
	for weapon in stats["by_weapon"]:
		var weapon_name = MartialArtData.WeaponType.keys()[weapon]
		print("  %s: %d" % [weapon_name, stats["by_weapon"][weapon]])

## 清空数据库
func clear() -> void:
	_martial_arts.clear()
	_initialize_categories()
	_is_loaded = false
	_load_errors.clear()
	print("功法数据库已清空")

## 重新加载数据库
func reload() -> void:
	clear()
	load_all_martial_arts()

## 获取加载错误列表
func get_load_errors() -> Array[String]:
	return _load_errors.duplicate()

## 数据库是否已加载
func is_loaded() -> bool:
	return _is_loaded