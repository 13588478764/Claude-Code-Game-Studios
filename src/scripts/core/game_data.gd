# 武侠奇遇录 - 游戏数据管理器
# 负责管理全局游戏数据和常量

extends Node

# 游戏版本
const GAME_VERSION = "1.0.0"

# 游戏常量
const MAX_LEVEL = 99
const MAX_REALMS = 10
const REALM_NAMES = [
	"炼气", "筑基", "金丹", "元婴", "化神", 
	"返虚", "合道", "大乘", "渡劫", "真仙"
]

# 属性名称映射
const ATTRIBUTE_NAMES = {
	"strength": "力道",
	"agility": "身法", 
	"constitution": "根骨",
	"intelligence": "悟性",
	"willpower": "定力",
	"luck": "福缘"
}

# 品阶颜色映射
const TIER_COLORS = {
	"common": Color.WHITE,
	"rare": Color(0.0, 0.5, 1.0),      # 蓝色
	"epic": Color(0.7, 0.0, 1.0),      # 紫色  
	"legendary": Color(1.0, 0.8, 0.0)  # 金色
}

# 五行元素
const ELEMENTS = {
	"fire": "火",
	"water": "水", 
	"wood": "木",
	"metal": "金",
	"earth": "土"
}

# 元素克制关系 (攻击方 -> 被攻击方)
const ELEMENT_WEAKNESS = {
	"fire": ["wood", "metal"],
	"water": ["fire", "earth"],
	"wood": ["water", "earth"],
	"metal": ["wood", "earth"],
	"earth": ["water", "fire"]
}

func _ready():
	print("游戏数据管理器初始化完成")
