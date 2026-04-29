## MartialArtsComboSystem
## 武学组合系统
##
## 实现武学组合/连招系统，包括协同效果检测、内力回流、连携槽管理。
##
## 功能：
## - 协同效果检测（标签协同、状态协同）
## - 内力回流计算（基于协同效果等级）
## - 连携槽管理（积累、消耗、检查）
## - 连招状态追踪（当前标签、上次标签、连招链）
##
## 依赖系统：
## - 无直接依赖

extends Node
class_name MartialArtsComboSystem

# ============================================================================
# 常量定义
# ============================================================================

const MAX_LINK_GAUGE: int = 100  # 最大连携槽
const COMBO_WINDOW_TIME: float = 3.0  # 连招窗口时间（秒）
const REFUND_RATIO_MIN: float = 0.2  # 最小回流比例
const REFUND_RATIO_MAX: float = 0.5  # 最大回流比例

const BASE_LINK_GAUGE_INCREMENT: int = 20  # 基础连携槽增量
const LINK_GAUGE_THRESHOLD: int = 30  # 连携触发阈值

const COMBO_CHAIN_MAX_LENGTH: int = 5  # 连招链最大长度
const BASIC_COMBO_MULTIPLIER: float = 1.0  # 普通连招倍率
const ADVANCED_COMBO_MULTIPLIER: float = 1.5  # 高阶连招倍率
const ULTIMATE_COMBO_MULTIPLIER: float = 2.0  # 终极连招倍率

# ============================================================================
# 信号定义
# ============================================================================

signal combo_triggered(combo_name: String, damage_multiplier: float)
signal synergy_detected(tag1: String, tag2: String)
signal link_gauge_updated(value: int, max_value: int)
signal internal_energy_refunded(amount: float)
signal combo_state_reset()

# 连招系统数据结构
var combo_state = {
	"current_tags": [],          # 当前已应用的标签
	"last_applied_tags": [],     # 上次应用的标签
	"last_status_effects": [],   # 上次施加的状态效果
	"combo_timer": 0.0,          # 连招计时器
	"link_gauge": 0,             # 连携槽
	"current_combo_chain": []    # 当前连招链
}

# 协同效果配置表
var synergy_table = {
	# 标签协同效果
	"破防_刚": {
		"name": "粉碎打击",
		"damage_multiplier": 2.0,
		"description": "对架势破碎的敌人造成200%伤害"
	},
	"湿_雷": {
		"name": "感电爆发",
		"damage_multiplier": 1.8,
		"aoe": true,
		"status_effect": "麻痹",
		"description": "对湿润目标造成感电，附加麻痹效果"
	},
	"浮空_坠击": {
		"name": "空中处决",
		"damage_multiplier": 2.5,
		"critical_hit": true,
		"description": "对浮空目标造成必杀效果"
	},
	"燃烧_水": {
		"name": "蒸汽爆炸",
		"damage_multiplier": 1.6,
		"knockback": true,
		"description": "对燃烧目标使用水系技能，造成击退效果"
	}
}

# 连招等级系数
var combo_tier_multipliers = {
	"basic": 1.0,    # 普通连招
	"advanced": 1.5, # 高阶连招
	"ultimate": 2.0  # 终极连招
}

# 初始化
func _ready():
	print("Martial Arts Combo System initialized")

# 处理技能释放（主入口函数）
func process_skill_usage(skill_data: Dictionary, target_status: Array = []) -> Dictionary:
	var result = {
		"damage_multiplier": 1.0,
		"synergy_triggered": false,
		"synergy_name": "",
		"internal_energy_refund": 0.0,
		"link_gauge_change": 0,
		"additional_effects": []
	}
	
	# 检查是否存在协同效果
	var synergy_result = check_synergy(skill_data.tags, target_status)
	
	if synergy_result.found:
		# 应用协同效果
		result.damage_multiplier = synergy_result.multiplier
		result.synergy_triggered = true
		result.synergy_name = synergy_result.name
		
		# 计算内力回流
		result.internal_energy_refund = calculate_internal_energy_refund(skill_data.internal_energy_cost)
		
		# 计算连携槽增加
		result.link_gauge_change = calculate_link_gauge_increase(synergy_result.tier)
		
		# 添加额外效果
		if synergy_result.has("status_effect"):
			result.additional_effects.append({
				"type": "status",
				"value": synergy_result.status_effect
			})
		
		# 触发协同信号
		emit_signal("synergy_detected", synergy_result.tag1, synergy_result.tag2)
		emit_signal("combo_triggered", synergy_result.name, synergy_result.multiplier)
		emit_signal("internal_energy_refunded", result.internal_energy_refund)
		emit_signal("link_gauge_updated", combo_state.link_gauge, MAX_LINK_GAUGE)
	else:
		# 没有协同效果，正常使用技能
		result.link_gauge_change = calculate_link_gauge_increase("basic")
	
	# 更新连招状态
	update_combo_state(skill_data.tags)
	
	# 更新连携槽
	combo_state.link_gauge = clamp(combo_state.link_gauge + result.link_gauge_change, 0, MAX_LINK_GAUGE)
	
	return result

# 检查协同效果
func check_synergy(current_tags: Array, target_status: Array = []) -> Dictionary:
	var result = {
		"found": false,
		"multiplier": 1.0,
		"name": "",
		"tag1": "",
		"tag2": "",
		"tier": "basic"
	}
	
	# 检查当前标签与上次标签的协同
	for current_tag in current_tags:
		for last_tag in combo_state.last_applied_tags:
			var synergy_key = "%s_%s" % [last_tag, current_tag]
			var reverse_synergy_key = "%s_%s" % [current_tag, last_tag]
			
			if synergy_table.has(synergy_key):
				var synergy = synergy_table[synergy_key]
				result.found = true
				result.multiplier = synergy.damage_multiplier
				result.name = synergy.name
				result.tag1 = last_tag
				result.tag2 = current_tag
				result.tier = calculate_combo_tier(synergy_key)
				
				# 添加协同效果的额外属性
				if synergy.has("status_effect"):
					result.status_effect = synergy.status_effect
				if synergy.has("aoe"):
					result.aoe = synergy.aoe
				if synergy.has("critical_hit"):
					result.critical_hit = synergy.critical_hit
				if synergy.has("knockback"):
					result.knockback = synergy.knockback
				
				return result
			elif synergy_table.has(reverse_synergy_key):
				var synergy = synergy_table[reverse_synergy_key]
				result.found = true
				result.multiplier = synergy.damage_multiplier
				result.name = synergy.name
				result.tag1 = current_tag
				result.tag2 = last_tag
				result.tier = calculate_combo_tier(reverse_synergy_key)
				
				# 添加协同效果的额外属性
				if synergy.has("status_effect"):
					result.status_effect = synergy.status_effect
				if synergy.has("aoe"):
					result.aoe = synergy.aoe
				if synergy.has("critical_hit"):
					result.critical_hit = synergy.critical_hit
				if synergy.has("knockback"):
					result.knockback = synergy.knockback
				
				return result
	
	# 检查基于目标状态的协同
	for tag in current_tags:
		for status in target_status:
			if (tag == "雷" and status == "湿润") or (tag == "湿" and "湿润" in target_status):
				if synergy_table.has("湿_雷"):
					var synergy = synergy_table["湿_雷"]
					result.found = true
					result.multiplier = synergy.damage_multiplier
					result.name = synergy.name
					result.tag1 = "湿"
					result.tag2 = "雷"
					result.tier = calculate_combo_tier("湿_雷")
					
					if synergy.has("status_effect"):
						result.status_effect = synergy.status_effect
					
					return result
	
	return result

# 计算内力回流
func calculate_internal_energy_refund(internal_energy_cost: float) -> float:
	var refund_ratio = randf_range(REFUND_RATIO_MIN, REFUND_RATIO_MAX)
	return internal_energy_cost * refund_ratio

# 计算连携槽增加
func calculate_link_gauge_increase(combo_tier: String) -> int:
	var base_increment = 20  # 基础增量
	var tier_multiplier = combo_tier_multipliers.get(combo_tier, 1.0)
	
	return int(base_increment * tier_multiplier)

# 更新连招状态
func update_combo_state(current_tags: Array):
	# 更新上次应用的标签
	combo_state.last_applied_tags = combo_state.current_tags.duplicate()
	
	# 更新当前标签
	combo_state.current_tags = current_tags.duplicate()
	
	# 重置连招计时器
	combo_state.combo_timer = COMBO_WINDOW_TIME
	
	# 添加到连招链
	combo_state.current_combo_chain.append({
		"tags": current_tags.duplicate(),
		"timestamp": Time.get_ticks_msec()
	})
	
	# 限制连招链长度
	if combo_state.current_combo_chain.size() > 5:
		combo_state.current_combo_chain.pop_front()

# 检查连携槽是否足够触发连携
func is_link_available() -> bool:
	return combo_state.link_gauge >= 30  # 至少30点才能触发连携

# 消耗连携槽
func consume_link_gauge(amount: int) -> bool:
	if combo_state.link_gauge >= amount:
		combo_state.link_gauge -= amount
		emit_signal("link_gauge_updated", combo_state.link_gauge, MAX_LINK_GAUGE)
		return true
	return false

# 重置连招状态
func reset_combo_state():
	combo_state.current_tags.clear()
	combo_state.last_applied_tags.clear()
	combo_state.last_status_effects.clear()
	combo_state.combo_timer = 0.0
	combo_state.current_combo_chain.clear()

# 获取当前连招状态
func get_current_combo_state() -> Dictionary:
	return {
		"current_tags": combo_state.current_tags,
		"last_applied_tags": combo_state.last_applied_tags,
		"link_gauge": combo_state.link_gauge,
		"max_link_gauge": MAX_LINK_GAUGE,
		"combo_chain_length": combo_state.current_combo_chain.size()
	}

# 计算连招等级
func calculate_combo_tier(synergy_key: String) -> String:
	var synergy = synergy_table[synergy_key]
	var multiplier = synergy.damage_multiplier
	
	if multiplier >= 2.0:
		return "ultimate"
	elif multiplier >= 1.6:
		return "advanced"
	else:
		return "basic"

# 更新连招计时器（在_process中调用）
func _process(delta):
	# 更新连招窗口计时器
	if combo_state.combo_timer > 0:
		combo_state.combo_timer -= delta
		if combo_state.combo_timer <= 0:
			# 连招窗口结束，重置部分状态
			combo_state.last_applied_tags.clear()

# 获取可用的协同效果（用于UI显示）
func get_available_synergies(current_tags: Array, target_status: Array = []) -> Array:
	var available = []
	
	# 检查与上次标签的协同
	for current_tag in current_tags:
		for last_tag in combo_state.last_applied_tags:
			var synergy_key = "%s_%s" % [last_tag, current_tag]
			var reverse_synergy_key = "%s_%s" % [current_tag, last_tag]
			
			if synergy_table.has(synergy_key):
				var synergy = synergy_table[synergy_key]
				available.append({
					"name": synergy.name,
					"description": synergy.description,
					"damage_multiplier": synergy.damage_multiplier,
					"tags_used": [last_tag, current_tag]
				})
			elif synergy_table.has(reverse_synergy_key):
				var synergy = synergy_table[reverse_synergy_key]
				available.append({
					"name": synergy.name,
					"description": synergy.description,
					"damage_multiplier": synergy.damage_multiplier,
					"tags_used": [current_tag, last_tag]
				})
	
	# 检查基于目标状态的协同
	for tag in current_tags:
		for status in target_status:
			if (tag == "雷" and status == "湿润") or (tag == "湿" and "湿润" in target_status):
				if synergy_table.has("湿_雷"):
					var synergy = synergy_table["湿_雷"]
					available.append({
						"name": synergy.name,
						"description": synergy.description,
						"damage_multiplier": synergy.damage_multiplier,
						"tags_used": ["湿", "雷"],
						"requires_status": "湿润"
					})
	
	return available