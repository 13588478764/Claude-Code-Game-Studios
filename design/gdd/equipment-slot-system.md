# 装备槽位系统

## 1. 概述

装备槽位系统定义了角色可以装备的物品位置和槽位类型。该系统为装备系统提供基础框架，支持不同品阶（普通-白色、稀有-蓝色、史诗-紫色、传说-金色）和类型的装备，并与角色成长系统中的境界突破机制集成。

## 2. 核心机制

### 2.1 槽位类型
- **武器槽**（主手/副手）：可装备剑、刀、枪、棍等武器
- **防具槽**：
  - 头部：帽子、头盔
  - 身体：衣服、铠甲  
  - 手部：手套、护腕
  - 腿部：裤子、护腿
  - 脚部：鞋子、靴子
- **饰品槽**：
  - 戒指（2个槽位）
  - 项链（1个槽位）
  - 腰带（1个槽位）
- **特殊槽**：
  - 内功心法（3个槽位）
  - 轻功秘籍（1个槽位）

### 2.2 境界解锁机制
- **炼气期**（1-9级）：基础槽位（武器×1、身体、脚部）
- **筑基期**（10-19级）：解锁头部、手部槽位
- **金丹期**（20-29级）：解锁腿部、戒指×1槽位
- **元婴期**（30-39级）：解锁副手武器、项链槽位
- **化神期**（40-49级）：解锁腰带槽位
- **返虚期**（50-59级）：解锁内功心法×1槽位
- **合道期**（60-69级）：解锁内功心法×2槽位
- **大乘期**（70-79级）：解锁轻功秘籍槽位
- **渡劫期**（80-89级）：解锁戒指×2槽位
- **真仙境**（90-99级）：解锁内功心法×3槽位

### 2.3 装备规则
- **品阶限制**：高品阶装备需要达到相应境界才能装备
  - 普通（白色）：无限制
  - 稀有（蓝色）：筑基期及以上
  - 史诗（紫色）：元婴期及以上  
  - 传说（金色）：大乘期及以上
- **职业限制**：某些装备仅限特定武学流派使用
- **性别限制**：部分外观装备有性别限制

## 3. 技术规格

### 3.1 数据结构
```yaml
EquipmentSlot:
  slotType: String  # "weapon_main", "weapon_offhand", "head", "body", "hands", "legs", "feet", "ring", "necklace", "belt", "inner_art", "light_art"
  equipmentId: String?  # 装备ID，null表示空槽
  isLocked: Boolean  # 是否被境界锁定
  requiredRealm: Integer  # 需要的境界等级（0-9对应10个大境界）
  maxEquipmentTier: Integer  # 最大装备品阶（1-4对应白蓝紫金）

CharacterEquipment:
  slots:
    weapon_main: EquipmentSlot
    weapon_offhand: EquipmentSlot  
    head: EquipmentSlot
    body: EquipmentSlot
    hands: EquipmentSlot
    legs: EquipmentSlot
    feet: EquipmentSlot
    ring_1: EquipmentSlot
    ring_2: EquipmentSlot
    necklace: EquipmentSlot
    belt: EquipmentSlot
    inner_art_1: EquipmentSlot
    inner_art_2: EquipmentSlot
    inner_art_3: EquipmentSlot
    light_art: EquipmentSlot
```

### 3.2 接口定义
- `equipItem(slotType: String, itemId: String)`: 装备物品到指定槽位
- `unequipItem(slotType: String)`: 卸下指定槽位的装备
- `getAvailableSlots()`: 获取当前可用的槽位列表
- `isSlotUnlocked(slotType: String)`: 检查槽位是否已解锁
- `canEquipItem(itemId: String)`: 检查是否可以装备指定物品

## 4. 平衡考虑

### 4.1 进度控制
- 槽位解锁与境界突破同步，确保玩家有明确的成长目标
- 高级槽位提供显著的属性提升，激励玩家追求更高境界
- 避免早期过度装备导致后期内容失去吸引力

### 4.2 Build多样性
- 不同槽位组合支持多样化的build策略
- 内功心法和轻功秘籍槽位支持武学流派定制
- 武器双持机制增加战斗策略深度

## 5. 依赖关系

- **依赖系统**：角色成长系统、装备系统、物品数据库
- **被依赖系统**：装备属性计算、装备UI、战斗系统

## 6. 验收标准

- [ ] 角色根据当前境界自动解锁相应装备槽位
- [ ] 装备品阶限制正确实施
- [ ] 支持所有定义的槽位类型（15个槽位）
- [ ] 装备/卸下操作实时更新角色属性
- [ ] 职业和性别限制正确应用
- [ ] 槽位数据正确保存和加载