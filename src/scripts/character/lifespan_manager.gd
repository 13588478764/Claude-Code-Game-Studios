## LifespanManager
## 寿命系统管理器
## 负责管理角色和NPC的寿命系统（主要作为叙事元素）
## 根据GDD设计文档，寿命系统主要用于支持修真世界观的真实感和NPC剧情设定
## 
## 主要功能：
## - 管理NPC的年龄和寿命上限
## - 根据境界计算寿命上限
## - 提供"寿命将尽"状态标记
## - 支持叙事系统的年龄相关剧情
##
## 设计定位：
## - 玩家角色不受寿命限制（游戏时间不会导致角色死亡）
## - NPC有年龄和寿命设定，用于剧情和对话
## - MVP阶段：仅在对话文本中体现，不需要复杂的系统实现
## - 完整版本：在NPC数据中添加age字段，用于某些剧情判定

extends Node

class_name LifespanManager

# ============================================================================
# 常量定义
# ============================================================================

# 境界与寿命对应关系（单位：年）
const REALM_LIFESPAN = {
	"炼气": {"min": 120, "max": 150},
	"筑基": {"min": 200, "max": 300},
	"金丹": {"min": 500, "max": 800},
	"元婴": {"min": 1000, "max": 1500},
	"化神": {"min": 3000, "max": 5000},
	"返虚": {"min": 5000, "max": 8000},
	"合道": {"min": 8000, "max": 12000},
	"大乘": {"min": 12000, "max": 20000},
	"渡劫": {"min": 20000, "max": 30000},
	"真仙": {"min": 50000, "max": 100000}
}

# 寿命将尽的阈值（剩余寿命百分比）
const LIFESPAN_WARNING_THRESHOLD = 0.1  # 剩余10%寿命时触发"寿命将尽"状态

# ============================================================================
# 信号定义
# ============================================================================

signal npc_lifespan_warning(npc_id: String, remaining_years: int)
signal npc_lifespan_expired(npc_id: String)

# ============================================================================
# NPC寿命数据结构
# ============================================================================

class NPCLifespanData:
	var npc_id: String = ""
	var current_age: int = 0  # 当前年龄
	var realm: String = "炼气"  # 当前境界
	var lifespan_max: int = 150  # 寿命上限
	var is_lifespan_warning: bool = false  # 是否处于"寿命将尽"状态
	
	func _init(id: String, age: int, realm_name: String):
		npc_id = id
		current_age = age
		realm = realm_name
		lifespan_max = calculate_lifespan_max(realm_name)
		update_warning_status()
	
	func calculate_lifespan_max(realm_name: String) -> int:
		"""根据境界计算寿命上限（取中间值）"""
		if REALM_LIFESPAN.has(realm_name):
			var lifespan_range = REALM_LIFESPAN[realm_name]
			return (lifespan_range["min"] + lifespan_range["max"]) / 2
		return 150  # 默认炼气期寿命
	
	func update_warning_status():
		"""更新寿命警告状态"""
		var remaining_ratio = float(lifespan_max - current_age) / float(lifespan_max)
		is_lifespan_warning = remaining_ratio <= LIFESPAN_WARNING_THRESHOLD
	
	func get_remaining_years() -> int:
		"""获取剩余寿命"""
		return max(0, lifespan_max - current_age)
	
	func get_lifespan_percentage() -> float:
		"""获取寿命百分比"""
		return float(current_age) / float(lifespan_max) * 100.0
	
	func to_dict() -> Dictionary:
		"""转换为字典（用于保存）"""
		return {
			"npc_id": npc_id,
			"current_age": current_age,
			"realm": realm,
			"lifespan_max": lifespan_max,
			"is_lifespan_warning": is_lifespan_warning
		}
	
	static func from_dict(data: Dictionary) -> NPCLifespanData:
		"""从字典创建（用于加载）"""
		var lifespan_data = NPCLifespanData.new(
			data.get("npc_id", ""),
			data.get("current_age", 0),
			data.get("realm", "炼气")
		)
		return lifespan_data

# ============================================================================
# 成员变量
# ============================================================================

# NPC寿命数据存储 {npc_id: NPCLifespanData}
var npc_lifespan_data: Dictionary = {}

# 游戏时间流逝速度（游戏内1年 = 现实X秒）
# MVP阶段不实现时间流逝，仅用于叙事
var time_scale: float = 0.0  # 0表示时间不流逝

# ============================================================================
# 生命周期方法
# ============================================================================

func _ready():
	print("[LifespanManager] 寿命系统初始化完成")
	# MVP阶段：仅初始化核心NPC的寿命数据
	initialize_core_npcs()

# ============================================================================
# 公共方法 - NPC寿命管理
# ============================================================================

func register_npc(npc_id: String, age: int, realm: String) -> bool:
	"""注册NPC的寿命数据"""
	if npc_lifespan_data.has(npc_id):
		push_warning("[LifespanManager] NPC %s 已经注册过寿命数据" % npc_id)
		return false
	
	var lifespan_data = NPCLifespanData.new(npc_id, age, realm)
	npc_lifespan_data[npc_id] = lifespan_data
	
	# 检查是否需要触发寿命警告
	if lifespan_data.is_lifespan_warning:
		npc_lifespan_warning.emit(npc_id, lifespan_data.get_remaining_years())
	
	print("[LifespanManager] 注册NPC: %s, 年龄: %d, 境界: %s, 寿命上限: %d" % 
		[npc_id, age, realm, lifespan_data.lifespan_max])
	
	return true

func get_npc_age(npc_id: String) -> int:
	"""获取NPC当前年龄"""
	if npc_lifespan_data.has(npc_id):
		return npc_lifespan_data[npc_id].current_age
	return 0

func get_npc_lifespan_max(npc_id: String) -> int:
	"""获取NPC寿命上限"""
	if npc_lifespan_data.has(npc_id):
		return npc_lifespan_data[npc_id].lifespan_max
	return 0

func get_npc_remaining_years(npc_id: String) -> int:
	"""获取NPC剩余寿命"""
	if npc_lifespan_data.has(npc_id):
		return npc_lifespan_data[npc_id].get_remaining_years()
	return 0

func is_npc_lifespan_warning(npc_id: String) -> bool:
	"""检查NPC是否处于"寿命将尽"状态"""
	if npc_lifespan_data.has(npc_id):
		return npc_lifespan_data[npc_id].is_lifespan_warning
	return false

func update_npc_realm(npc_id: String, new_realm: String) -> bool:
	"""更新NPC境界（会重新计算寿命上限）"""
	if not npc_lifespan_data.has(npc_id):
		push_warning("[LifespanManager] NPC %s 未注册" % npc_id)
		return false
	
	var lifespan_data = npc_lifespan_data[npc_id]
	lifespan_data.realm = new_realm
	lifespan_data.lifespan_max = lifespan_data.calculate_lifespan_max(new_realm)
	lifespan_data.update_warning_status()
	
	print("[LifespanManager] 更新NPC %s 境界为 %s, 新寿命上限: %d" % 
		[npc_id, new_realm, lifespan_data.lifespan_max])
	
	return true

func get_npc_lifespan_info(npc_id: String) -> Dictionary:
	"""获取NPC完整的寿命信息（用于UI显示）"""
	if not npc_lifespan_data.has(npc_id):
		return {}
	
	var lifespan_data = npc_lifespan_data[npc_id]
	return {
		"npc_id": npc_id,
		"current_age": lifespan_data.current_age,
		"realm": lifespan_data.realm,
		"lifespan_max": lifespan_data.lifespan_max,
		"remaining_years": lifespan_data.get_remaining_years(),
		"lifespan_percentage": lifespan_data.get_lifespan_percentage(),
		"is_lifespan_warning": lifespan_data.is_lifespan_warning
	}

# ============================================================================
# 公共方法 - 境界与寿命计算
# ============================================================================

func get_lifespan_range_by_realm(realm: String) -> Dictionary:
	"""根据境界获取寿命范围"""
	if REALM_LIFESPAN.has(realm):
		return REALM_LIFESPAN[realm]
	return {"min": 120, "max": 150}  # 默认炼气期

func calculate_average_lifespan(realm: String) -> int:
	"""计算境界的平均寿命"""
	var lifespan_range = get_lifespan_range_by_realm(realm)
	return (lifespan_range["min"] + lifespan_range["max"]) / 2

func get_appearance_age(actual_age: int, realm: String) -> int:
	"""根据实际年龄和境界计算外貌年龄（用于叙事描述）"""
	# 修真者外貌年龄增长速度随境界降低
	var realm_factor = {
		"炼气": 1.0,    # 外貌年龄 = 实际年龄
		"筑基": 0.8,    # 外貌年龄增长速度降低20%
		"金丹": 0.5,    # 外貌年龄增长速度降低50%
		"元婴": 0.3,    # 外貌年龄增长速度降低70%
		"化神": 0.2,    # 外貌年龄增长速度降低80%
		"返虚": 0.15,
		"合道": 0.1,
		"大乘": 0.05,
		"渡劫": 0.03,
		"真仙": 0.01
	}
	
	var factor = realm_factor.get(realm, 1.0)
	var appearance_age = int(actual_age * factor)
	
	# 限制外貌年龄在合理范围内
	return clamp(appearance_age, 20, 80)

# ============================================================================
# 公共方法 - 叙事支持
# ============================================================================

func get_lifespan_description(npc_id: String) -> String:
	"""获取NPC寿命的叙事描述（用于对话和UI）"""
	if not npc_lifespan_data.has(npc_id):
		return "未知"
	
	var lifespan_data = npc_lifespan_data[npc_id]
	var remaining_years = lifespan_data.get_remaining_years()
	
	if lifespan_data.is_lifespan_warning:
		return "寿命将尽（剩余约%d年）" % remaining_years
	elif remaining_years < 100:
		return "寿元不多（剩余约%d年）" % remaining_years
	elif remaining_years < 500:
		return "寿元充足（剩余约%d年）" % remaining_years
	else:
		return "寿元悠长（剩余约%d年）" % remaining_years

func get_age_description(npc_id: String) -> String:
	"""获取NPC年龄的叙事描述"""
	if not npc_lifespan_data.has(npc_id):
		return "年龄未知"
	
	var lifespan_data = npc_lifespan_data[npc_id]
	var appearance_age = get_appearance_age(lifespan_data.current_age, lifespan_data.realm)
	
	return "实际年龄%d岁，外貌约%d岁" % [lifespan_data.current_age, appearance_age]

# ============================================================================
# 公共方法 - 数据持久化
# ============================================================================

func save_lifespan_data() -> Dictionary:
	"""保存所有NPC的寿命数据"""
	var save_data = {}
	for npc_id in npc_lifespan_data:
		save_data[npc_id] = npc_lifespan_data[npc_id].to_dict()
	return save_data

func load_lifespan_data(save_data: Dictionary) -> bool:
	"""加载NPC寿命数据"""
	npc_lifespan_data.clear()
	
	for npc_id in save_data:
		var data = save_data[npc_id]
		var lifespan_data = NPCLifespanData.from_dict(data)
		npc_lifespan_data[npc_id] = lifespan_data
	
	print("[LifespanManager] 加载了 %d 个NPC的寿命数据" % npc_lifespan_data.size())
	return true

# ============================================================================
# 私有方法 - 初始化
# ============================================================================

func initialize_core_npcs():
	"""初始化核心NPC的寿命数据（根据角色档案）"""
	# 根据 design/narrative/characters/character-profiles.md 中的设定
	
	# 1. 云中鹤 - 元婴中期，约800岁
	register_npc("yunzhonghe", 800, "元婴")
	
	# 2. 柳如烟 - 金丹后期，约150岁
	register_npc("liuruyan", 150, "金丹")
	
	# 3. 萧寒夜 - 金丹后期，约180岁
	register_npc("xiaohanye", 180, "金丹")
	
	# 4. 慕容雪 - 表面筑基初期（实际化神期转世），外表20岁
	register_npc("murongxue", 20, "筑基")  # 使用表面境界
	
	# 5. 铁无双 - 筑基后期，约80岁
	register_npc("tiewushuang", 80, "筑基")
	
	# 6. 玄机真人 - 化神后期，约1500岁（寿命将尽）
	register_npc("xuanji_zhenren", 1500, "化神")
	
	# 7. 血无痕 - 化神初期，约1000岁
	register_npc("xuewuhen", 1000, "化神")
	
	print("[LifespanManager] 核心NPC寿命数据初始化完成")

# ============================================================================
# 调试方法
# ============================================================================

func debug_print_all_npcs():
	"""打印所有NPC的寿命信息（调试用）"""
	print("=== NPC寿命信息 ===")
	for npc_id in npc_lifespan_data:
		var info = get_npc_lifespan_info(npc_id)
		print("NPC: %s" % npc_id)
		print("  年龄: %d岁 (外貌约%d岁)" % [info["current_age"], 
			get_appearance_age(info["current_age"], info["realm"])])
		print("  境界: %s" % info["realm"])
		print("  寿命: %d / %d (%.1f%%)" % [info["current_age"], info["lifespan_max"], 
			info["lifespan_percentage"]])
		print("  剩余: %d年" % info["remaining_years"])
		print("  状态: %s" % get_lifespan_description(npc_id))
		print("  描述: %s" % get_age_description(npc_id))
		print("---")
	print("==================")