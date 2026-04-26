# 装备属性计算

## 1. 概述

装备属性计算系统负责计算装备对角色六维属性（力道、身法、根骨、悟性、定力、福缘）和战斗属性的影响。该系统与装备槽位系统、武学系统和伤害计算系统集成，确保装备效果正确应用到角色能力上。

## 2. 核心机制

### 2.1 属性类型
- **基础属性加成**：直接增加六维属性值
  - 力道、身法、根骨、悟性、定力、福缘
- **战斗属性加成**：
  - 攻击力、防御力、生命值上限
  - 暴击率、暴击伤害、命中率、闪避率
  - 内力上限、内力回复率
- **特殊效果**：
  - 元素伤害加成（金/木/水/火/土）
  - 状态效果抗性（中毒、眩晕、冰冻等）
  - 武学技能效果增强

### 2.2 品阶属性计算
- **普通（白色）**：仅提供基础属性加成
  - 基础属性：+1~5点
- **稀有（蓝色）**：基础属性 + 1个战斗属性
  - 基础属性：+3~8点
  - 战斗属性：+1%~5%
- **史诗（紫色）**：基础属性 + 2个战斗属性 + 1个特殊效果
  - 基础属性：+6~12点
  - 战斗属性：+3%~8%
  - 特殊效果：固定数值或百分比效果
- **传说（金色）**：基础属性 + 3个战斗属性 + 2个特殊效果 + 唯一特效
  - 基础属性：+10~20点
  - 战斗属性：+5%~12%
  - 特殊效果：强力效果
  - 唯一特效：独特的被动或主动技能

### 2.3 计算公式
- **总属性值** = 基础属性 + 装备加成 + 境界加成 + 武学加成
- **装备加成叠加**：
  - 同类属性线性叠加（如多个装备都加力道，则力道值相加）
  - 百分比属性乘法叠加（如暴击率：(1+装备1加成)×(1+装备2加成)-1）
- **属性转换**：
  - 力道 → 物理攻击力：1点力道 = 2点物理攻击力
  - 身法 → 闪避率：10点身法 = 1%闪避率
  - 根骨 → 生命值：1点根骨 = 10点生命值上限
  - 悟性 → 暴击率：20点悟性 = 1%暴击率
  - 定力 → 命中率：15点定力 = 1%命中率
  - 福缘 → 掉落率：5点福缘 = 1%稀有物品掉落率提升

### 2.4 元素克制计算
- 装备提供的元素伤害遵循统一的五行克制体系：
  - 金克木、木克土、土克水、水克火、火克金
  - 克制伤害：1.5倍伤害
  - 被克伤害：0.5倍伤害
  - 装备元素属性可与武学元素属性叠加

## 3. 技术规格

### 3.1 数据结构
```yaml
EquipmentAttribute:
  baseAttributes:
    strength: Integer?
    agility: Integer?
    constitution: Integer?
    intelligence: Integer?
    willpower: Integer?
    luck: Integer?
  combatAttributes:
    attack: Integer?
    defense: Integer?
    maxHealth: Integer?
    criticalRate: Float?  # 百分比，如0.05表示5%
    criticalDamage: Float?  # 倍数，如0.25表示25%额外暴击伤害
    hitRate: Float?
    evasion: Float?
    maxInternalEnergy: Integer?
    internalEnergyRegen: Float?  # 如0.05表示5%内力回复率
  elementalBonuses:
    fire: Integer?
    water: Integer?
    earth: Integer?
    metal: Integer?
    wood: Integer?
  statusResistances:
    poison: Float?
    stun: Float?
    freeze: Float?
    burn: Float?
  martialArtBonuses:
    skillPower: Float?  # 武学技能效果增强百分比
    cooldownReduction: Float?  # 冷却时间减少百分比

CharacterTotalAttributes:
  base:  # 六维基础属性
    strength: Integer
    agility: Integer
    constitution: Integer
    intelligence: Integer
    willpower: Integer
    luck: Integer
  combat:  # 战斗属性（已转换）
    physicalAttack: Integer
    magicalAttack: Integer
    defense: Integer
    maxHealth: Integer
    criticalRate: Float
    criticalDamage: Float
    hitRate: Float
    evasion: Float
    maxInternalEnergy: Integer
    internalEnergyRegen: Float
  elemental:  # 元素属性
    fire: Integer
    water: Integer
    earth: Integer
    metal: Integer
    wood: Integer
  resistances:  # 状态抗性
    poison: Float
    stun: Float
    freeze: Float
    burn: Float
```

### 3.2 接口定义
- `calculateTotalAttributes(character: Character, equippedItems: List[Item])`: 计算角色总属性
- `getEquipmentBonuses(itemId: String)`: 获取指定装备的属性加成
- `applyAttributeConversion(baseAttributes: BaseAttributes)`: 应用属性转换公式
- `calculateElementalDamage(sourceElement: String, targetElement: String, baseDamage: Integer)`: 计算元素克制伤害

## 4. 平衡考虑

### 4.1 数值平衡
- 确保装备属性加成与角色等级和境界相匹配
- 高品阶装备提供显著但不过分的优势
- 避免属性膨胀导致后期数值失控

### 4.2 Build多样性
- 不同装备组合支持多样化的build策略
- 特殊效果鼓励特定的武学流派搭配
- 元素属性支持针对特定敌人的战术选择

### 4.3 新手友好性
- 属性效果显示清晰直观
- 提供装备对比功能
- 自动计算最佳装备搭配建议

## 5. 依赖关系

- **依赖系统**：装备系统、装备槽位系统、武学系统、伤害计算系统、角色成长系统
- **被依赖系统**：战斗系统、战斗UI、装备UI

## 6. 验收标准

- [ ] 装备属性正确应用到角色六维属性
- [ ] 属性转换公式正确实施
- [ ] 品阶属性差异明显且平衡
- [ ] 元素克制计算正确
- [ ] 特殊效果正确触发和应用
- [ ] 总属性计算实时更新
- [ ] 装备属性数据正确保存和加载