## StatusEffect Resource类
## 定义状态效果的数据结构
## 
## 用于存储状态效果的类型、持续时间、层数、系数等属性
## 遵循ADR-001: 使用Resource类实现数据持久化和序列化

class_name StatusEffect
extends Resource

## 状态效果类型枚举
enum EffectType {
	BURN,        ## 燃烧 - 持续火属性伤害
	POISON,      ## 中毒 - 持续毒素伤害
	BLEED,       ## 流血 - 受击时额外真实伤害
	REGEN,       ## 再生 - 持续生命恢复
	STRENGTH_UP, ## 力量提升 - 攻击力+20%
	FOCUS,       ## 专注 - 命中率+20%,暴击率+5%
	SHIELD,      ## 护盾 - 吸收伤害
	WEAKEN,      ## 虚弱 - 攻击力-20%
	VULNERABLE,  ## 易伤 - 受到伤害+20%-50%
	BLIND,       ## 致盲 - 命中率-30%
	STUN,        ## 眩晕 - 跳过行动
	ROOT,        ## 定身 - 无法移动
	SILENCE,     ## 沉默 - 无法使用技能
	FREEZE,      ## 冻结 - 无法行动,受击必暴击
	BREAK,       ## 破防 - 架势值归零,易伤
	MARK         ## 标记 - 特定来源伤害增加
}

## 触发时机枚举
enum TriggerTiming {
	START_OF_TURN,  ## 回合开始时触发
	END_OF_TURN,    ## 回合结束时触发
	ON_HIT,         ## 受击时触发
	INSTANT         ## 立即生效
}

## 伤害类型枚举
enum DamageType {
	NONE,      ## 无伤害
	FIRE,      ## 火属性
	POISON,    ## 毒素
	PHYSICAL,  ## 物理
	TRUE       ## 真实伤害
}

## 状态效果类型
@export var effect_type: EffectType = EffectType.BURN

## 持续时间(回合数)
@export var duration: int = 3

## 层数(可堆叠状态)
@export var stacks: int = 1

## 系数(用于计算伤害/恢复量)
@export var coefficient: float = 0.03

## 基础数值(用于固定数值的状态,如中毒)
@export var base_value: float = 10.0

## 触发时机
@export var trigger_timing: TriggerTiming = TriggerTiming.END_OF_TURN

## 伤害类型
@export var damage_type: DamageType = DamageType.FIRE

## 是否可堆叠
@export var stackable: bool = true

## 最大层数
@export var max_stacks: int = 5

## 状态效果名称
@export var effect_name: String = "Burn"

## 状态效果描述
@export var description: String = "每回合结束造成火属性伤害"

## 持续时间最小值常量
const MIN_DURATION: int = 1

## 持续时间最大值常量
const MAX_DURATION: int = 8

## 构造函数
func _init(
	p_effect_type: EffectType = EffectType.BURN,
	p_duration: int = 3,
	p_stacks: int = 1,
	p_coefficient: float = 0.03,
	p_base_value: float = 10.0
) -> void:
	effect_type = p_effect_type
	# AC7: 持续时间溢出保护 - 钳制到[1,8]范围
	duration = clamp(p_duration, MIN_DURATION, MAX_DURATION)
	stacks = p_stacks
	coefficient = p_coefficient
	base_value = p_base_value
	
	# 根据类型设置默认值
	match effect_type:
		EffectType.BURN:
			trigger_timing = TriggerTiming.END_OF_TURN
			damage_type = DamageType.FIRE
			stackable = true
			max_stacks = 5
			effect_name = "Burn"
			description = "每回合结束造成火属性伤害"
		
		EffectType.POISON:
			trigger_timing = TriggerTiming.END_OF_TURN
			damage_type = DamageType.POISON
			stackable = true
			max_stacks = 5
			effect_name = "Poison"
			description = "每回合结束造成毒素伤害,无视部分防御"
		
		EffectType.REGEN:
			trigger_timing = TriggerTiming.START_OF_TURN
			damage_type = DamageType.NONE
			stackable = false
			max_stacks = 1
			effect_name = "Regen"
			description = "每回合开始恢复生命值"
		
		_:
			trigger_timing = TriggerTiming.INSTANT
			damage_type = DamageType.NONE
			stackable = false
			max_stacks = 1

## 计算燃烧伤害
## @param max_hp: 目标最大生命值
## @return: 计算后的伤害值
func calculate_burn_damage(max_hp: float) -> float:
	if effect_type != EffectType.BURN:
		push_warning("calculate_burn_damage called on non-BURN effect")
		return 0.0
	
	# 公式: damage = max_hp × coefficient × stacks
	var damage = max_hp * coefficient * stacks
	return damage

## 计算中毒伤害
## @param defense: 目标防御值
## @return: 计算后的伤害值(已考虑防御穿透)
func calculate_poison_damage(defense: float) -> float:
	if effect_type != EffectType.POISON:
		push_warning("calculate_poison_damage called on non-POISON effect")
		return 0.0
	
	# 公式: damage = base_value × stacks
	# 防御减免50%
	var raw_damage = base_value * stacks
	var defense_reduction = defense * 0.5  # 无视50%防御
	var final_damage = max(raw_damage - defense_reduction, 0.0)
	
	return final_damage

## 计算再生恢复量
## @param max_hp: 目标最大生命值
## @return: 计算后的恢复量
func calculate_regen_heal(max_hp: float) -> float:
	if effect_type != EffectType.REGEN:
		push_warning("calculate_regen_heal called on non-REGEN effect")
		return 0.0
	
	# 公式: heal = max_hp × coefficient
	var heal = max_hp * coefficient
	return heal

## 增加层数
## @param amount: 增加的层数
## @return: 是否成功增加
func add_stacks(amount: int = 1) -> bool:
	if not stackable:
		return false
	
	var new_stacks = stacks + amount
	if new_stacks > max_stacks:
		stacks = max_stacks
		return false  # 达到上限
	
	stacks = new_stacks
	return true

## 减少持续时间
## @return: 剩余持续时间
func decrease_duration() -> int:
	duration = max(duration - 1, 0)
	return duration

## 是否已过期
## @return: true表示已过期
func is_expired() -> bool:
	return duration <= 0

## 刷新持续时间
## @param new_duration: 新的持续时间
func refresh_duration(new_duration: int) -> void:
	duration = new_duration

## 复制状态效果
## @return: 新的StatusEffect实例
func duplicate_effect() -> StatusEffect:
	var new_effect = StatusEffect.new(effect_type, duration, stacks, coefficient, base_value)
	new_effect.trigger_timing = trigger_timing
	new_effect.damage_type = damage_type
	new_effect.stackable = stackable
	new_effect.max_stacks = max_stacks
	new_effect.effect_name = effect_name
	new_effect.description = description
	return new_effect