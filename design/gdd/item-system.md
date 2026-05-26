# 道具系统 (Item System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 一局一笑 / 局内成长 / 永远有新的
> **Sprint**: S4-1 + G-1 (resume integration)

## Overview

道具系统是**局内消费 + 装备 modifier** 的双轨经济。玩家用 money 在事件 / 商店 buyItem，道具分两类生效：(1) **consumable** 立即触发 effect（如恢复体力 30） → 一次性消耗；(2) **equipment / housing / transport** 装备到对应 slot（tool / housing / transport / wearable）→ 持续提供 energy/mood mul（如"游戏机" moodMul 0.9，所有心情损失 ×0.9）。

装备 slot 互斥：同 slot 新装备替换旧装备（不丢失，回到 inventory）。系统 emit `onItemRefused` 解释失败原因（unknown-item / insufficient-funds / wrong-job / not-in-inventory），UI 用来弹气泡 / 红字。

## Player Fantasy

**直接幻想**："攒钱买装备 → 装上 → 接下来一周明显轻松"——典型 roguelike build 反馈。"廉价方便面"治标不治本（一次性），"按摩椅"是真正的资产（持久 mul）。

**自嘲调性**：道具命名贴合"打工人现实"（咖啡 / 游戏机 / 出租屋 / 共享单车 / Mac / 商务西装），让玩家在数值之外读到段子。

某些道具有 `jobRestriction`（如"专业相机" only 摄影 / 设计）—— 玩家手痒买了用不了 → `onItemRefused('wrong-job')` 提醒。

## Detailed Rules

### Item 数据结构（src/types/item.ts）

```typescript
interface Item {
  id: string
  name: string
  description: string
  price: number                      // 0 = 不可购买（事件赠送或固定持有）
  category: ItemCategory             // 'consumable' | 'equipment' | 'housing' | 'transport'
  slot?: ItemSlot                    // 'tool' | 'housing' | 'transport' | 'wearable'（equip 时必须）
  modifiers?: ItemModifiers          // { energyMul?, moodMul? }（equipment 持续效果）
  effect?: { target, value }         // consumable 立即效果
  jobRestriction?: string[]          // 仅限职业（空 = 通用）
  icon?: string
}
```

### buyItem 流程

```
buyItem(itemId):
  1. 查找 catalog → 未找到则 emit onItemRefused('unknown-item') return false
  2. checkJobRestriction → 不匹配 emit onItemRefused('wrong-job') return false
  3. 检查 getMoney() ≥ price → 不足 emit onItemRefused('insufficient-funds') return false
  4. applyEffects([{ target:'money', value:-price }]) ← 扣钱
  5. 加入 inventory（同 id 累加 count）
  6. emit onItemBought({ item, count })
  7. return true
```

### useItem 流程（consumable）

```
useItem(itemId):
  1. inventory 不含 → emit onItemRefused('not-in-inventory') return false
  2. checkJobRestriction → 不匹配 emit onItemRefused('wrong-job') return false
  3. inventory count -= 1（归零删除条目）
  4. 若 item.effect 存在 → applyEffects([effect])
  5. emit onItemUsed({ item })
  6. return true
```

### equipItem 流程（equipment / housing / transport）

```
equipItem(itemId):
  1. inventory 检查 + jobRestriction 检查（同 useItem 前两步）
  2. category === 'consumable' → return false（不可 equip）
  3. slot 必须存在 → 否则 return false
  4. 若 equipped[slot] 已有旧道具 → unequipItem(oldId)（旧的回 inventory）
  5. inventory count -= 1（归零删除），equipped[slot] = item
  6. emit onItemEquipped({ item, slot, replacedItem? })
  7. return true
```

### unequipItem 流程

```
unequipItem(itemId):
  1. 查找 equipped 中 itemId 所在 slot
  2. 道具加回 inventory（同 id 累加 count）
  3. equipped[slot] 删除
  4. emit onItemUnequipped({ item, slot })
```

### Modifier 管线位置（ADR-005）

```
choice.effect.value
  → PassiveSkillSystem.applyToEffect    ← 永久跨 run
  → ItemSystem.applyToEffect            ← per-run 装备（本系统）
  → StatusSystem.applyToEffect          ← per-run buff/debuff
  → ResourceManager.applyEffects        ← clamp + state machine
```

道具位于管线**第二层**——在 passive（永久）之后、status（短期）之前。multi-equip 的 mul **乘积累加**（同 PassiveSkill 模式）：例如游戏机 (moodMul 0.9) + 按摩椅 (moodMul 0.85) → moodMul = 0.9 × 0.85 = 0.765。

money 不参与 mul 管线（与 status / passive 一致）。

### Resume（G-1）

`loadInventory(snap)` / `loadEquipped(snap)`：从 SaveData 恢复 inventory + equipped state。**已知 SMELL**：当前 load 不重新触发 onItemBought / onItemEquipped（resume 不应"再买一次"），但也意味着 store 必须主动 getInventory()/getEquipped() pull 而非依赖 push。RunManager.resumeFromCheckpoint 已 cover。

### Snapshot 用于持久化

`getInventorySnapshot()` / `getEquippedSnapshot()` 返回 `Record<string, number>` 和 `Record<ItemSlot, string>`——SaveService 写入 currentRun。

## Formulas

### Modifier 应用

```
rawValue → signFloor(rawValue × ∏equipped[*].modifiers.targetMul)
```

**Variables**:
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| rawValue | int | -999..+999 | 进入本管线层时的 effect 值（已被 passive 处理） |
| equipped[*] | array<Item> | 0..4 | 当前装备道具（最多 4 slot） |
| targetMul | float | 0.5..1.2 | 单道具在该 target 上的 mul（typical 0.85-0.95） |
| ∏ | float | 0.1..1.5 | 所有装备 mul 乘积 |

**signFloor**: 向零取整（正数 floor / 负数 ceil）—— -10 × 0.9 = -9（损失变小），不是 -9.0 → -10。

**Identity 优化**: 若乘积为 1.0（无相关装备）→ 直接返回 rawValue。

**Example**: 已装 游戏机 (moodMul 0.9) + 按摩椅 (moodMul 0.85)
- choice effect: `{ target: 'mood', value: -8 }`
- applied: signFloor(-8 × 0.9 × 0.85) = signFloor(-6.12) = -6
- 心情仅扣 6 而非 8。

### Equipment slot 容量

固定 4 slot：tool / housing / transport / wearable。同 slot 互斥，无 multi-equip 同 slot。inventory 无容量限制（int counter）。

## Edge Cases

- **catalog 中无该 itemId**（buyItem 调用未知 id）→ `onItemRefused('unknown-item')`，不扣钱、不入 inventory。常见于：JSON 配置错误 / 事件 reward 引用了已删除 item。
- **money 不足**（buyItem）→ `onItemRefused('insufficient-funds')`，不扣钱。注意：不会"扣到负数"——price 检查在 applyEffects 之前。
- **jobRestriction 不匹配**（buyItem / useItem / equipItem）→ `onItemRefused('wrong-job')`。getCurrentJobId() 在 run 进行中应稳定返回；初始 null 时所有 restricted item 视为不允许。
- **useItem 道具不在 inventory**（重复使用 / 数据竞争）→ `onItemRefused('not-in-inventory')`。
- **equipItem 替换同 slot 旧道具**（合法 case）→ 触发 unequipItem 先；oldItem 回 inventory（count +1）；emit `onItemEquipped({ replacedItem: oldItem })`。**UI 应弹"已替换 XX"**——payload 已提供。
- **consumable 调用 equipItem**（错误用法）→ return false，无 emit、无副作用。
- **loadInventory / loadEquipped 收到非法 itemId**（save 中遗留旧版本 item）→ filter `getItemById(id) != null` 静默丢弃。**已知 SMELL**：丢弃不通知玩家，可能造成"我之前买的 XX 哪去了？"——后续若发现 issue 加 toast。
- **inventory count 归零**（useItem 用完最后一个）→ delete inventory[id] 而非保留 `{id: 0}`，避免 snapshot 累积空条目。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| RunManager | 启动新 run 时 init / resume 时 loadInventory + loadEquipped |
| ChoiceResolutionEngine | choice reward 含 buyItem trigger |
| EventEngine | 事件 effect 可触发 useItem 或 buyItem（间接） |

### 下游
| 系统 | 接口 |
|------|------|
| ChoiceResolutionEngine | `applyToEffect(target, rawValue): number` （pipeline 2nd layer） |
| ResourceManager | （间接）通过 ChoiceResolutionEngine 收到 mul 后的值 |
| SaveService | `getInventorySnapshot()` / `getEquippedSnapshot()` 持久化 |
| Vue Store (itemStore) | 订阅 onItemBought / Used / Equipped / Unequipped / Refused 推 UI |

### Dependency Injection（DI）

```typescript
interface ItemSystemDeps {
  getItemById: (id: string) => Item | undefined
  getMoney: () => number
  applyEffects: (effects: ResourceEffect[]) => void
  getCurrentJobId: () => string | null
}
```

production 注入 catalog + resourceManager + runManager；test 注入 mock，使本系统 100% 可单测。

### 公共接口

```typescript
class ItemSystem {
  constructor(deps: ItemSystemDeps)
  buyItem(itemId: string): boolean
  useItem(itemId: string): boolean
  equipItem(itemId: string): boolean
  unequipItem(itemId: string): boolean
  getInventory(): Record<string, number>
  getEquipped(): Record<ItemSlot, Item | null>
  applyToEffect(target: 'energy' | 'mood', rawValue: number): number
  getInventorySnapshot(): Record<string, number>
  getEquippedSnapshot(): Record<ItemSlot, string>
  loadInventory(snap: Record<string, number>): void
  loadEquipped(snap: Record<ItemSlot, string>): void
  readonly onItemBought: TypedEventEmitter<...>
  readonly onItemUsed: TypedEventEmitter<...>
  readonly onItemEquipped: TypedEventEmitter<...>
  readonly onItemUnequipped: TypedEventEmitter<...>
  readonly onItemRefused: TypedEventEmitter<{ itemId, reason }>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| ITEM_CATALOG | N entries | — | 加 item 只需 push entry，无代码改动 |
| item.price | 30-500 | 10-2000 | 道具定价——过低让经济失衡，过高让玩家买不起 |
| item.modifiers.energyMul/moodMul | 0.85-0.95 | 0.5-1.2 | 装备 mul 范围；> 1.0 为负面（暂未使用） |
| item.effect.value | ±10-50 | ±100 | consumable 单次回复/损失幅度 |
| jobRestriction | 1-3 jobs / 空 | — | 限制职业；空数组 = 通用 |

## Acceptance Criteria

- **GIVEN** money=200 / 无 inventory, **WHEN** `buyItem('coffee')` (price 30), **THEN** money=170, inventory={coffee:1}, emit onItemBought({item, count:1})。
- **GIVEN** money=10, **WHEN** `buyItem('coffee')` (price 30), **THEN** money 不变, emit onItemRefused({itemId:'coffee', reason:'insufficient-funds'})。
- **GIVEN** inventory={coffee:1} / consumable effect {target:'energy', value:+30}, **WHEN** `useItem('coffee')`, **THEN** inventory={}, energy +30, emit onItemUsed。
- **GIVEN** equipment 'game-console' (moodMul 0.9) in inventory, **WHEN** `equipItem('game-console')`, **THEN** equipped.tool='game-console', inventory 移除, emit onItemEquipped({item, slot:'tool', replacedItem:null})。
- **GIVEN** equipped.tool='laptop' / inventory={'mac':1}, **WHEN** `equipItem('mac')`, **THEN** equipped.tool='mac', inventory={'laptop':1}, emit onItemEquipped({replacedItem:laptop})。
- **GIVEN** equipped game-console (moodMul 0.9) + chair (moodMul 0.85), **WHEN** `applyToEffect('mood', -10)`, **THEN** 返回 signFloor(-10 × 0.9 × 0.85) = -7。
- **GIVEN** jobRestriction=['photographer'] / currentJob='programmer', **WHEN** `buyItem('camera')`, **THEN** emit onItemRefused({reason:'wrong-job'})。
- **GIVEN** snapshot {inventory:{coffee:2}, equipped:{tool:'laptop'}}, **WHEN** loadInventory + loadEquipped, **THEN** getInventory()={coffee:2}, getEquipped().tool=laptop item, 不 emit。
