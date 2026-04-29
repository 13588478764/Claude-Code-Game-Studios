## DamageCalculator
## 伤害计算系统
##
## 负责计算所有伤害类型的伤害值，包括外功、内功和真实伤害。
## 遵循GDD中定义的减法公式和规则。
##
## 主要功能：
## - 基础伤害计算
## - 伤害类型处理
## - 防御减伤计算
## - 最终伤害输出

extends Node
class_name DamageCalculator

# ============================================================================
# 常量定义
# ============================================================================

enum DamageType {
	PHYSICAL,      # 外功伤害
	ENERGY,        # 内功伤害
	TRUE_DAMAGE    # 真实伤害
}

# ============================================================================
# 信号定义
# ============================================================================

signal damage_calculated(attacker: Node, defender: Node, damage_type: int, final_damage: int)

# ============================================================================
# 公共方法
# ============================================================================
REPLACE

## 计算基础伤害
## 参数:
##   - attacker: 攻击者节点
##   - defender: 防御者节点
##   - damage_type: 伤害类型 (DamageType 枚举)
## 返回: 基础伤害值 (最小为 1)
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
	
	# 基础伤害 = 攻击力 - 防御力
	var base_damage: int = attack_power - defense_value
	
	# 应用伤害类型规则
	base_damage = apply_damage_type_rules(damage_type, base_damage)
	
	# 确保最小伤害为 1
	base_damage = enforce_minimum_damage(base_damage)
	
	return base_damage


## 应用伤害类型规则
## 参数:
##   - damage_type: 伤害类型
##   - base_damage: 基础伤害值
## 返回: 应用规则后的伤害值
func apply_damage_type_rules(damage_type: int, base_damage: int) -> int:
	match damage_type:
		DamageType.PHYSICAL:
			# 外功伤害规则: 无特殊规则，直接返回
			return base_damage
		
		DamageType.ENERGY:
			# 内功伤害规则: 无特殊规则，直接返回
			return base_damage
		
		DamageType.TRUE_DAMAGE:
			# 真实伤害规则: 无视防御，已在 calculate_base_damage 中处理
			return base_damage
	
	return base_damage


## 确保最小伤害为 1
## 参数:
##   - final_damage: 最终伤害值
## 返回: 至少为 1 的伤害值
func enforce_minimum_damage(final_damage: int) -> int:
	return max(1, final_damage)


# ============================================================================
# 私有方法 - 属性获取
# ============================================================================

## 获取物理攻击力
## 返回: 力道(STR) + 武器攻击力
func _get_physical_attack_power(attacker: Node) -> int:
	var str_value: int = _get_attribute(attacker, "strength")  # 力道
	var weapon_attack: int = _get_weapon_attack(attacker)
	return str_value + weapon_attack


## 获取物理防御力
## 返回: 根骨(CON) + 护甲
func _get_physical_defense_value(defender: Node) -> int:
	var con_value: int = _get_attribute(defender, "constitution")  # 根骨
	var armor: int = _get_armor(defender)
	return con_value + armor


## 获取内功攻击力
## 返回: 悟性(WIS) + 内力强度
func _get_energy_attack_power(attacker: Node) -> int:
	var wis_value: int = _get_attribute(attacker, "wisdom")  # 悟性
	var qi_power: int = _get_qi_power(attacker)
	return wis_value + qi_power


## 获取内功防御力
## 返回: 悟性(WIS) + 内力抗性
func _get_energy_defense_value(defender: Node) -> int:
	var wis_value: int = _get_attribute(defender, "wisdom")  # 悟性
	var qi_resistance: int = _get_qi_resistance(defender)
	return wis_value + qi_resistance


## 获取真实伤害力
## 返回: 基础真实伤害值
func _get_true_damage_power(attacker: Node) -> int:
	# 真实伤害通常来自特定效果或技能
	# 这里返回一个基础值，具体值由技能或效果提供
	return _get_attribute(attacker, "strength")  # 使用力道作为基础


## 获取属性值
## 参数:
##   - node: 目标节点
##   - attribute_name: 属性名称
## 返回: 属性值，如果不存在则返回 0
func _get_attribute(node: Node, attribute_name: String) -> int:
	if node.has_meta(attribute_name):
		return node.get_meta(attribute_name)
	return 0


## 获取武器攻击力
func _get_weapon_attack(attacker: Node) -> int:
	if attacker.has_meta("weapon_attack"):
		return attacker.get_meta("weapon_attack")
	return 0


## 获取护甲值
func _get_armor(defender: Node) -> int:
	if defender.has_meta("armor"):
		return defender.get_meta("armor")
	return 0


## 获取内力强度
func _get_qi_power(attacker: Node) -> int:
	if attacker.has_meta("qi_power"):
		return attacker.get_meta("qi_power")
	return 0


## 获取内力抗性
func _get_qi_resistance(defender: Node) -> int:
	if defender.has_meta("qi_resistance"):
		return defender.get_meta("qi_resistance")
	return 0