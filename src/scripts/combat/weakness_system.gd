# 武侠奇遇录 - 弱点系统
# 实现属性克制、弱点打击判定、击倒机制和总攻击触发等功能

extends Node

# 信号定义
signal weakness_hit_triggered(attacker, target, damage_multiplier)
signal target_knocked_down(target)
signal all_out_attack_available()

# 属性类型枚举
enum ElementType {
	NONE = -1,
	METAL = 0,    # 金
	WOOD = 1,     # 木
	WATER = 2,    # 水
	FIRE = 3,     # 火
	EARTH = 4     # 土
}

# 属性克制关系表：key为被克制的属性，value为克制它的属性
var elemental_weaknesses = {
	ElementType.FIRE: ElementType.METAL,    # 火克金
	ElementType.METAL: ElementType.WOOD,     # 金克木
	ElementType.WOOD: ElementType.EARTH,    # 木克土
	ElementType.EARTH: ElementType.WATER,   # 土克水
	ElementType.WATER: ElementType.FIRE     # 水克火
}

# 战斗状态枚举
enum BattleStatus {
	NORMAL = 0,   # 正常状态
	DOWN = 1,     # 击倒状态
	BREAK = 2,    # 破防状态
	STUN = 3      # 眩晕状态
}

# 弱点系统配置
var weakness_damage_multiplier = 1.5  # 弱点伤害倍率
var down_state_duration = 1           # 击倒状态持续回合数
var break_damage_multiplier = 1.5     # 破防伤害倍率

# 引用其他系统
var combat_manager = null

func _ready():
	print("弱点系统初始化完成")

func initialize(combat_mgr):
	"""初始化弱点系统"""
	combat_manager = combat_mgr
	print("弱点系统已连接到战斗管理器")

# 检查是否存在属性克制
func check_elemental_weakness(attacker_element: ElementType, target_element: ElementType) -> bool:
	"""检查攻击者属性是否克制目标属性"""
	if attacker_element == ElementType.NONE or target_element == ElementType.NONE:
		return false
	
	var weakness_element = elemental_weaknesses.get(target_element, ElementType.NONE)
	return attacker_element == weakness_element

# 计算弱点伤害
func calculate_weakness_damage(base_damage: int, is_weakness_hit: bool) -> int:
	"""计算弱点伤害"""
	if is_weakness_hit:
		return int(base_damage * weakness_damage_multiplier)
	else:
		return base_damage

# 处理弱点打击
func process_weakness_hit(attacker, target, attack_element: ElementType, target_weakness_element: ElementType) -> Dictionary:
	"""处理弱点打击逻辑"""
	var result = {
		"is_weakness_hit": false,
		"damage_multiplier": 1.0,
		"should_knock_down": false,
		"message": ""
	}
	
	# 检查是否为弱点打击
	if check_elemental_weakness(attack_element, target_weakness_element):
		result.is_weakness_hit = true
		result.damage_multiplier = weakness_damage_multiplier
		result.message = "触发弱点打击！"
		
		# 发射弱点打击信号
		emit_signal("weakness_hit_triggered", attacker, target, weakness_damage_multiplier)
		
		# 检查是否应该击倒目标
		if randf() < 0.7:  # 70%概率击倒
			result.should_knock_down = true
			result.message += " 目标被击倒！"
	
	return result

# 应用击倒状态
func apply_knock_down_effect(target) -> bool:
	"""应用击倒效果到目标"""
	if target and target.get("current_hp", 1) > 0:
		# 设置目标为击倒状态
		if target.has_method("set_status"):
			target.set_status(BattleStatus.DOWN)
		else:
			# 如果目标没有状态设置方法，直接设置属性
			target.status = BattleStatus.DOWN
			if target.has_method("skip_next_turn"):
				target.skip_next_turn()
		
		# 发射击倒信号
		emit_signal("target_knocked_down", target)
		return true
	
	return false

# 检查总攻击条件
func check_all_out_attack_condition(targets: Array) -> bool:
	"""检查是否满足总攻击条件（所有敌人都处于Down状态）"""
	if targets.is_empty():
		return false
	
	for target in targets:
		# 检查目标是否为敌人且处于Down状态
		var is_enemy = target.get("is_enemy", false)
		var is_down = false
		
		if target.has_method("get_status"):
			is_down = target.get_status() == BattleStatus.DOWN
		else:
			is_down = target.get("status", BattleStatus.NORMAL) == BattleStatus.DOWN
		
		if is_enemy and not is_down:
			return false
	
	# 如果所有敌人都处于Down状态，触发总攻击
	emit_signal("all_out_attack_available")
	return true

# 获取属性名称
func get_element_name(element: ElementType) -> String:
	"""获取属性名称"""
	match element:
		ElementType.METAL: return "金"
		ElementType.WOOD: return "木"
		ElementType.WATER: return "水"
		ElementType.FIRE: return "火"
		ElementType.EARTH: return "土"
		_: return "无"

# 获取克制属性
func get_weakness_element(target_element: ElementType) -> ElementType:
	"""获取克制指定属性的元素"""
	return elemental_weaknesses.get(target_element, ElementType.NONE)

# 处理总攻击
func execute_all_out_attack(targets: Array, attacker) -> Dictionary:
	"""执行总攻击"""
	var result = {
		"success": false,
		"damage_dealt": [],
		"message": "总攻击未执行"
	}
	
	if not check_all_out_attack_condition(targets):
		return result
	
	# 对所有Down状态的敌人造成固定伤害
	var damage_results = []
	for target in targets:
		if target.get("is_enemy", false):
			var is_down = false
			if target.has_method("get_status"):
				is_down = target.get_status() == BattleStatus.DOWN
			else:
				is_down = target.get("status", BattleStatus.NORMAL) == BattleStatus.DOWN
			
			if is_down:
				# 固定高伤害
				var fixed_damage = 50 + randi_range(10, 20)
				if target.get("current_hp", 0) > 0:
					target.current_hp = max(0, target.current_hp - fixed_damage)
					damage_results.append({
						"target": target,
						"damage": fixed_damage,
						"remaining_hp": target.get("current_hp", 0)
					})
	
	result.success = true
	result.damage_dealt = damage_results
	result.message = "总攻击发动！对所有Down状态的敌人造成大量伤害"
	
	return result

# 获取属性克制关系
func get_elemental_advantage(attacker_element: ElementType, target_element: ElementType) -> float:
	"""获取属性克制优势值，返回伤害倍率"""
	if check_elemental_weakness(attacker_element, target_element):
		return weakness_damage_multiplier  # 克制时的伤害倍率
	else:
		return 1.0  # 无克制关系时的普通伤害