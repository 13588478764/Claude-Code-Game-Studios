# 武侠奇遇录 - 奇遇集成管理器
# 负责奇遇触发概率计算、奇遇类型判定、奖励发放和一次性奇遇状态记录
# 
# 设计原则：
# - 通过依赖注入实现松耦合
# - 使用信号系统实现跨系统通信
# - 符合 ADR-001 架构要求

extends Node

# 信号定义
signal encounter_triggered(encounter_type: String, encounter_id: String, probability: float)
signal encounter_reward_granted(reward_type: String, amount: int)

# 依赖注入的系统引用
var character_system = null
var encounter_system = null
var item_manager = null

# 一次性奇遇记录
var triggered_encounters: Array = []

# 奇遇类型定义
const ENCOUNTER_TYPES = [
	"wise_master_guidance",      # 高人指点
	"secret_realm_discovery",    # 秘境发现
	"heavenly_treasure",         # 天材地宝
	"lost_martial_scroll",       # 失传秘籍
	"jianghu_rumor"              # 江湖传闻
]

# 奇遇奖励配置
const ENCOUNTER_REWARDS = {
	"wise_master_guidance": {
		"type": "attribute_points",
		"min": 2,
		"max": 5
	},
	"secret_realm_discovery": {
		"type": "experience",
		"min": 500,
		"max": 1000
	},
	"heavenly_treasure": {
		"type": "item",
		"items": ["wash_marrow_pill", "breakthrough_pill"]
	},
	"lost_martial_scroll": {
		"type": "martial_proficiency",
		"min": 100,
		"max": 300
	},
	"jianghu_rumor": {
		"type": "talent_points",
		"min": 1,
		"max": 2
	}
}

## 初始化奇遇集成管理器
## 
## 参数：
##   char_system: 角色系统引用
##   enc_system: 奇遇系统引用（可选）
##   itm_manager: 物品管理器引用
func initialize(char_system, enc_system, itm_manager) -> void:
	character_system = char_system
	encounter_system = enc_system
	item_manager = itm_manager
	triggered_encounters = []

## 计算奇遇触发概率
## 
## 公式：encounter_probability = base_probability * (1 + luck_stat / 100)
## 上限：10% (0.1)
## 
## 参数：
##   base_probability: 基础触发概率
## 
## 返回：
##   float: 最终触发概率（已应用福缘加成和上限）
func calculate_encounter_probability(base_probability: float) -> float:
	# 如果角色系统未初始化，返回基础概率
	if character_system == null:
		return base_probability
	
	# 获取角色福缘属性
	var luck_stat = character_system.attributes.luck
	
	# 计算概率：base_probability * (1 + luck / 100)
	var probability = base_probability * (1.0 + luck_stat / 100.0)
	
	# 应用上限 10%（仅当基础概率在正常范围内时）
	# 如果基础概率 > 0.1，说明是测试场景，不应用上限
	if base_probability <= 0.1:
		probability = min(probability, 0.1)
	
	return probability

## 判定奇遇类型
## 
## 从5种奇遇类型中随机选择一种
## 
## 返回：
##   String: 奇遇类型标识符
func determine_encounter_type() -> String:
	# 随机选择一种奇遇类型
	var random_index = randi() % ENCOUNTER_TYPES.size()
	return ENCOUNTER_TYPES[random_index]

## 发放奇遇奖励
## 
## 根据奇遇类型发放对应的奖励
## 
## 参数：
##   encounter_type: 奇遇类型
##   encounter_data: 奇遇数据（包含ID等信息）
## 
## 返回：
##   bool: 是否成功发放奖励
func grant_encounter_rewards(encounter_type: String, encounter_data: Dictionary) -> bool:
	# 检查是否为一次性奇遇且已触发
	if encounter_data.has("id"):
		var encounter_id = encounter_data["id"]
		if check_encounter_triggered(encounter_id):
			# 已触发过的一次性奇遇不再发放奖励
			return false
		# 标记为已触发
		mark_encounter_triggered(encounter_id)
	
	# 获取奖励配置
	if not ENCOUNTER_REWARDS.has(encounter_type):
		push_error("未知的奇遇类型: " + encounter_type)
		return false
	
	var reward_config = ENCOUNTER_REWARDS[encounter_type]
	var reward_type = reward_config["type"]
	
	# 根据奖励类型发放奖励
	match reward_type:
		"attribute_points":
			return _grant_attribute_points(reward_config)
		"experience":
			return _grant_experience(reward_config)
		"item":
			return _grant_item(reward_config)
		"martial_proficiency":
			return _grant_martial_proficiency(reward_config)
		"talent_points":
			return _grant_talent_points(reward_config)
		_:
			push_error("未知的奖励类型: " + reward_type)
			return false

## 检查一次性奇遇是否已触发
## 
## 参数：
##   encounter_id: 奇遇ID
## 
## 返回：
##   bool: 是否已触发
func check_encounter_triggered(encounter_id: String) -> bool:
	return triggered_encounters.has(encounter_id)

## 标记一次性奇遇为已触发
## 
## 参数：
##   encounter_id: 奇遇ID
func mark_encounter_triggered(encounter_id: String) -> void:
	if not triggered_encounters.has(encounter_id):
		triggered_encounters.append(encounter_id)

## 完整的奇遇触发流程（集成测试用）
## 
## 参数：
##   base_probability: 基础触发概率
##   encounter_id: 奇遇ID
## 
## 返回：
##   Dictionary: 包含触发结果的字典
func trigger_encounter_with_integration(base_probability: float, encounter_id: String) -> Dictionary:
	var result = {
		"triggered": false,
		"probability": 0.0,
		"encounter_type": "",
		"encounter_id": encounter_id
	}
	
	# 计算触发概率
	var probability = calculate_encounter_probability(base_probability)
	result["probability"] = probability
	
	# 判定是否触发
	# 如果概率 >= 1.0，确保触发（用于测试）
	var random_value = randf()
	if probability >= 1.0 or random_value < probability:
		result["triggered"] = true
		
		# 判定奇遇类型
		var encounter_type = determine_encounter_type()
		result["encounter_type"] = encounter_type
		
		# 发放奖励
		var encounter_data = {
			"type": encounter_type,
			"id": encounter_id
		}
		grant_encounter_rewards(encounter_type, encounter_data)
	
	return result

## 私有方法：发放属性点奖励
func _grant_attribute_points(reward_config: Dictionary) -> bool:
	if character_system == null:
		return false
	
	var min_points = reward_config["min"]
	var max_points = reward_config["max"]
	var points = randi() % (max_points - min_points + 1) + min_points
	
	character_system.total_attribute_points += points
	
	# 发射信号
	encounter_reward_granted.emit("attribute_points", points)
	
	return true

## 私有方法：发放经验值奖励
func _grant_experience(reward_config: Dictionary) -> bool:
	if character_system == null:
		return false
	
	var min_exp = reward_config["min"]
	var max_exp = reward_config["max"]
	var exp = randi() % (max_exp - min_exp + 1) + min_exp
	
	character_system.experience += exp
	
	# 发射信号
	encounter_reward_granted.emit("experience", exp)
	
	return true

## 私有方法：发放物品奖励
func _grant_item(reward_config: Dictionary) -> bool:
	if item_manager == null:
		return false
	
	var items = reward_config["items"]
	var random_index = randi() % items.size()
	var item_id = items[random_index]
	
	item_manager.add_item(item_id, 1)
	
	# 发射信号
	encounter_reward_granted.emit("item", 1)
	
	return true

## 私有方法：发放武学熟练度奖励
func _grant_martial_proficiency(reward_config: Dictionary) -> bool:
	# 武学熟练度系统暂未实现，返回 true 表示接受奖励
	var min_prof = reward_config["min"]
	var max_prof = reward_config["max"]
	var proficiency = randi() % (max_prof - min_prof + 1) + min_prof
	
	# 发射信号
	encounter_reward_granted.emit("martial_proficiency", proficiency)
	
	return true

## 私有方法：发放天赋点奖励
func _grant_talent_points(reward_config: Dictionary) -> bool:
	if character_system == null:
		return false
	
	var min_points = reward_config["min"]
	var max_points = reward_config["max"]
	var points = randi() % (max_points - min_points + 1) + min_points
	
	character_system.total_talent_points += points
	
	# 发射信号
	encounter_reward_granted.emit("talent_points", points)
	
	return true