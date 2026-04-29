## MartialArtData
## MartialArtData
martial art data
数据定义模块
武学数据资源定义
定义游戏中所有武学技能的数据结构和属性
##
## 主要功能：
## - 待补充

extends Node

class_name MartialArtData

# ============================================================================
# 常量定义
# ============================================================================

# ============================================================================
# 信号定义
# ============================================================================

# ============================================================================
# 成员变量
# ============================================================================

# ============================================================================
# 生命周期方法
# ============================================================================

# ============================================================================
# 公共方法
# ============================================================================

# ============================================================================
# 私有方法
# ============================================================================

extends Resource

# 枚举定义
enum MartialArtType { ATTACK, DEFENSE, MOVEMENT, BUFF, DEBUFF }
enum WeaponType { SWORD, BLADE, FIST, STAFF, NONE }
enum SchoolType { SHAOLIN, WUDANG, EMEI, GAOYANG, QINGCHENG, GENERIC }
enum GradeType { COMMON, RARE, EPIC, LEGENDARY }

# 基础信息
@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null

# 消耗与限制
@export var cost_stamina: float = 0.0
@export var cost_mana: float = 0.0
@export var cooldown: float = 0.0
@export var unlock_level: int = 1

# 战斗参数
@export var damage_base: float = 0.0
@export var damage_scale: float = 1.0
@export var hit_count: int = 1
@export var element_type: String = "无"  # 金木水火土/无

# 时序控制
@export var startup_frames: float = 0.0  # 前摇/发动时间（秒）
@export var active_frames: float = 0.0   # 有效判定持续时间（秒）
@export var recovery_frames: float = 0.0 # 后摇/硬直时间（秒）
@export var total_duration: float = 0.0  # 总时长

# 视觉与听觉
@export var vfx_prefab: PackedScene = null  # 特效场景引用
@export var sfx_hit: AudioStream = null    # 命中音效
@export var sfx_cast: AudioStream = null   # 释放音效
@export var camera_shake: Vector2 = Vector2.ZERO  # 相机震动强度

# 分类信息
@export var martial_art_type: MartialArtType = MartialArtType.ATTACK
@export var weapon_type: WeaponType = WeaponType.NONE
@export var school: SchoolType = SchoolType.GENERIC
@export var grade: GradeType = GradeType.COMMON

# 连招相关属性
@export var can_cancel_from_frame: float = -1.0  # 取消窗口开始时间，-1表示不能取消
@export var combo_chain: Array[String] = []      # 可以连接的后续武学ID列表

# 验证方法
func validate() -> bool:
	var errors = []
	
	if id.is_empty():
		errors.append("ID不能为空")
	
	if name.is_empty():
		errors.append("名称不能为空")
	
	if damage_base < 0:
		errors.append("基础伤害不能为负数")
	
	if cost_stamina < 0:
		errors.append("体力消耗不能为负数")
	
	if cost_mana < 0:
		errors.append("内力消耗不能为负数")
	
	if cooldown < 0:
		errors.append("冷却时间不能为负数")
	
	if unlock_level < 1:
		errors.append("解锁等级必须大于等于1")
	
	if startup_frames < 0:
		errors.append("前摇时间不能为负数")
	
	if active_frames < 0:
		errors.append("有效判定时间不能为负数")
	
	if recovery_frames < 0:
		errors.append("后摇时间不能为负数")
	
	if errors.size() > 0:
		print("武学数据验证错误: ", id, " - ", errors)
		return false
	
	return true

# 获取武学类型字符串
func get_martial_art_type_string() -> String:
	match martial_art_type:
		MartialArtType.ATTACK: return "攻击"
		MartialArtType.DEFENSE: return "防御"
		MartialArtType.MOVEMENT: return "移动"
		MartialArtType.BUFF: return "增益"
		MartialArtType.DEBUFF: return "减益"
		_: return "未知"

# 获取武器类型字符串
func get_weapon_type_string() -> String:
	match weapon_type:
		WeaponType.SWORD: return "剑"
		WeaponType.BLADE: return "刀"
		WeaponType.FIST: return "拳掌"
		WeaponType.STAFF: return "棍杖"
		WeaponType.NONE: return "无武器"
		_: return "未知"

# 获取门派类型字符串
func get_school_string() -> String:
	match school:
		SchoolType.SHAOLIN: return "少林"
		SchoolType.WUDANG: return "武当"
		SchoolType.EMEI: return "峨眉"
		SchoolType.GAOYANG: return "高阳"
		SchoolType.QINGCHENG: return "青城"
		SchoolType.GENERIC: return "通用"
		_: return "未知"

# 获取品阶字符串
func get_grade_string() -> String:
	match grade:
		GradeType.COMMON: return "普通"
		GradeType.RARE: return "稀有"
		GradeType.EPIC: return "史诗"
		GradeType.LEGENDARY: return "传说"
		_: return "未知"

# 获取元素类型字符串
func get_element_string() -> String:
	return element_type

# 字符串表示
func to_string() -> String:
	return "武学[%s] ID:%s 类型:%s 伤害:%.1f 消耗:%.1f内力 %.1f体力 CD:%.1fs" % [
		name, id, get_martial_art_type_string(), 
		damage_base, cost_mana, cost_stamina, cooldown
	]