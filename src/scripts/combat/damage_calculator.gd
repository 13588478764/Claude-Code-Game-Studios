## DamageCalculator
## 武侠奇遇录 - 伤害计算系统
##
## 负责计算所有伤害类型的伤害值，包括外功、内功和真实伤害。
## 遵循GDD中定义的减法公式和规则。
##
## 依赖关系：
## - 属性系统：获取角色属性（力道、根骨、悟性等）
## - 装备系统：获取武器攻击力和护甲值
##
## 主要功能：
## - 基础伤害计算（外功、内功、真实伤害）
## - 伤害类型处理（不同伤害类型的规则应用）
## - 防御减伤计算（根据防御值减少伤害）
## - 最终伤害输出（确保最小伤害为 1）

extends Node

class_name DamageCalculator

# ============================================================================
# 常量定义
# ============================================================================

## 最小伤害值
const MIN_DAMAGE: int = 1

## 物理伤害类型
enum DamageType {
	PHYSICAL,      ## 外功伤害（力道 vs 根骨）
	ENERGY,        ## 内功伤害（悟性 vs 悟性）
	TRUE_DAMAGE    ## 真实伤害（无视防御）
}

# ============================================================================
# 信号定义
# ============================================================================

## 伤害计算完成信号
signal damage_calculated(attacker: Node, defender: Node, damage_type: int, final_damage: int)

## 伤害类型应用信号
signal damage_type_applied(damage_type: int, base_damage: int, modified_damage: int)

## 属性获取信号
signal attribute_retrieved(node: Node, attribute_name: String, value: int)

# ============================================================================
# 公共方法
# ============================================================================

## 计算基础伤害
## @param attacker: 攻击者节点
## @param defender: 防御者节点
## @param damage_type: 伤害类型 (DamageType 枚举)
## @return 基础伤害值 (最小为 1)
func calculate_base_damage(attacker: Node, defender: Node, damage_type: int) -> int:
	var attack_power: int = 0
	var defense_value: int = 0
	
	# 根据伤害类型获取攻防值
	match damage_type:
		DamageType.PHYSICAL:
			# 外功伤害: 力道(STR) + 武器攻击力 vs 根骨(CON) + 护甲
			attack_power = _get_physical_attack_power(attacker)
			defense_value = _get_physical_defense_value(defender)
		
		DamageType.ENERGY:
			# 内功伤害: 悟性(WIS) + 内力强度 vs 悟性(WIS) + 内力抗性
			attack_power = _get_energy_attack_power(attacker)
			defense_value = _get_energy_defense_value(defender)
		
		DamageType.TRUE_DAMAGE:
			# 真实伤害: 无视防御，直接使用攻击力
			attack_power = _get_true_damage_power(attacker)
			defense_value = 0
		
		_:
			push_error("DamageCalculator: 未知的伤害类型: %d" % damage_type)
			return MIN_DAMAGE
	
	# 基础伤害 = 攻击力 - 防御力
	var base_damage: int = attack_power - defense_value
	
	# 应用伤害类型规则
	base_damage = apply_damage_type_rules(damage_type, base_damage)
	
	# 确保最小伤害为 1
	base_damage = enforce_minimum_damage(base_damage)
	
	# 发射信号
	emit_signal("damage_calculated", attacker, defender, damage_type, base_damage)
	
	return base_damage

## 应用伤害类型规则
## @param damage_type: 伤害类型
## @param base_damage: 基础伤害值
## @return 应用规则后的伤害值
func apply_damage_type_rules(damage_type: int, base_damage: int) -> int:
	var modified_damage: int = base_damage
	
	match damage_type:
		DamageType.PHYSICAL:
			# 外功伤害规则: 无特殊规则，直接返回
			pass
		
		DamageType.ENERGY:
			# 内功伤害规则: 无特殊规则，直接返回
			pass
		
		DamageType.TRUE_DAMAGE:
			# 真实伤害规则: 无视防御，已在 calculate_base_damage 中处理
			pass
		
		_:
			push_warning("DamageCalculator: 未知的伤害类型: %d" % damage_type)
	
	emit_signal("damage_type_applied", damage_type, base_damage, modified_damage)
	return modified_damage

## 确保最小伤害为 1
## @param final_damage: 最终伤害值
## @return 至少为 1 的伤害值
func enforce_minimum_damage(final_damage: int) -> int:
	return max(MIN_DAMAGE, final_damage)


# ============================================================================
# 属性获取方法
# ============================================================================

## 获取物理攻击力
## @param attacker: 攻击者节点
## @return 力道(STR) + 武器攻击力
func _get_physical_attack_power(attacker: Node) -> int:
	var str_value: int = _get_attribute(attacker, "strength")
	var weapon_attack: int = _get_weapon_attack(attacker)
	return str_value + weapon_attack

## 获取物理防御力
## @param defender: 防御者节点
## @return 根骨(CON) + 护甲
func _get_physical_defense_value(defender: Node) -> int:
	var con_value: int = _get_attribute(defender, "constitution")
	var armor: int = _get_armor(defender)
	return con_value + armor

## 获取内功攻击力
## @param attacker: 攻击者节点
## @return 悟性(WIS) + 内力强度
func _get_energy_attack_power(attacker: Node) -> int:
	var wis_value: int = _get_attribute(attacker, "wisdom")
	var qi_power: int = _get_qi_power(attacker)
	return wis_value + qi_power

## 获取内功防御力
## @param defender: 防御者节点
## @return 悟性(WIS) + 内力抗性
func _get_energy_defense_value(defender: Node) -> int:
	var wis_value: int = _get_attribute(defender, "wisdom")
	var qi_resistance: int = _get_qi_resistance(defender)
	return wis_value + qi_resistance

## 获取真实伤害力
## @param attacker: 攻击者节点
## @return 基础真实伤害值
func _get_true_damage_power(attacker: Node) -> int:
	# 真实伤害通常来自特定效果或技能
	# 这里返回一个基础值，具体值由技能或效果提供
	return _get_attribute(attacker, "strength")

# ============================================================================
# 元数据获取方法
# ============================================================================

## 获取属性值
## @param node: 目标节点
## @param attribute_name: 属性名称
## @return 属性值，如果不存在则返回 0
func _get_attribute(node: Node, attribute_name: String) -> int:
	if node.has_meta(attribute_name):
		var value: int = node.get_meta(attribute_name)
		emit_signal("attribute_retrieved", node, attribute_name, value)
		return value
	return 0

## 获取武器攻击力
## @param attacker: 攻击者节点
## @return 武器攻击力
func _get_weapon_attack(attacker: Node) -> int:
	if attacker.has_meta("weapon_attack"):
		return attacker.get_meta("weapon_attack")
	return 0

## 获取护甲值
## @param defender: 防御者节点
## @return 护甲值
func _get_armor(defender: Node) -> int:
	if defender.has_meta("armor"):
		return defender.get_meta("armor")
	return 0

## 获取内力强度
## @param attacker: 攻击者节点
## @return 内力强度
func _get_qi_power(attacker: Node) -> int:
	if attacker.has_meta("qi_power"):
		return attacker.get_meta("qi_power")
	return 0

## 获取内力抗性
## @param defender: 防御者节点
## @return 内力抗性
func _get_qi_resistance(defender: Node) -> int:
	if defender.has_meta("qi_resistance"):
		return defender.get_meta("qi_resistance")
	return 0