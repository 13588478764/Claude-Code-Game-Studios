# 被动技能系统 (Passive Skill System)

> **Status**: Designed (Retrofit 2026-05-25)
> **Author**: gameplay-programmer + user
> **Last Updated**: 2026-05-25
> **Implements Pillar**: 永远有新的 / 局外成长
> **Sprint**: S3-9 (stub) → Sprint 4+ (扩展)

## Overview

被动技能系统提供**跨局永久成长**。玩家累计游玩数据（通关数 / 总局数 / 总死亡 / 总金钱 / 特定职业游玩数）解锁被动技能，技能在所有后续 run 中**永远生效**，对资源 effect 做乘法 modifier（如 "厚脸皮 Lv1" 心情损失 ×0.8）。

技能解锁条件纯数据驱动（`unlockCondition` in `src/types/passive-skill.ts`），玩家无需手动学习——满足条件即自动解锁 + emit `onSkillUnlocked` 触发 UI 通知。

## Player Fantasy

**间接幻想**：玩家感觉"我越玩越强，被炒一次也不亏，每次失败都在变厉害"。即使本局崩盘，回到主菜单会看到"解锁新技能"通知，让"再玩一局"的冲动持续存在。

技能命名走口语化荒诞向（厚脸皮 / 钢铁体魄 / 销售之魂 / 凤凰涅槃）——与游戏整体"打工人自嘲"的调性一致。

## Detailed Rules

### Catalog 结构

```typescript
interface PassiveSkill {
  id: string
  name: string
  description: string
  energyMul?: number   // 体力 effect 乘数（默认 1.0）
  moodMul?: number     // 心情 effect 乘数（默认 1.0）
  unlockCondition: PassiveSkillUnlockCondition
}

type PassiveSkillUnlockCondition =
  | { type: 'wins'; value: number }
  | { type: 'totalRuns'; value: number }
  | { type: 'totalDeaths'; value: number }
  | { type: 'totalMoney'; value: number }
  | { type: 'jobPlays'; jobId: string; value: number }
```

### 当前 catalog（7 个 skill，src/types/passive-skill.ts:40-91）

| ID | Name | 效果 | 解锁条件 |
|----|------|------|---------|
| thick-skin-1 | 厚脸皮 Lv1 | moodMul 0.8 | wins ≥ 3 |
| iron-stomach-1 | 钢铁体魄 Lv1 | energyMul 0.85 | totalRuns ≥ 5 |
| thick-skin-2 | 厚脸皮 Lv2 | moodMul 0.85 | wins ≥ 10 |
| caffeine-tolerance | 咖啡因抗体 | energyMul 0.9 | programmer plays ≥ 3 |
| salesman-charm | 销售之魂 | moodMul 0.88 | sales plays ≥ 3 |
| workplace-veteran | 职场老兵 | energyMul/moodMul 0.92 | totalRuns ≥ 15 |
| phoenix-rising | 凤凰涅槃 | moodMul 0.75 | totalDeaths ≥ 10 |

### Modifier 管线位置（ADR-005）

```
choice.effect.value
  → PassiveSkillSystem.applyToEffect    ← 永久跨 run（本系统）
  → ItemSystem.applyToEffect            ← per-run 装备
  → StatusSystem.applyToEffect          ← per-run buff/debuff
  → ResourceManager.applyEffects        ← clamp + state machine
```

被动技能位于管线**最外层**——先于装备/状态生效。原因：永久成长应反映在所有后续计算的基线上。

### 多技能叠乘

同 target 多技能：**乘积累加**。  例如同时拥有 thick-skin-1 (0.8) + thick-skin-2 (0.85) + workplace-veteran (0.92) → moodMul = 0.8 × 0.85 × 0.92 ≈ 0.6256（即心情损失只剩 62.56%）。

money target **不参与 mul 管线**（与 status-system 不变量一致）：getMulForTarget 仅对 'energy' / 'mood' 生效。

### 解锁触发点

`PassiveSkillSystem.checkUnlocks(stats)` 由 `ProgressionSystem.recordRun` 在每局结束累计 stats 后调用。新解锁的 skill：
1. 加入 `this.unlocked` set
2. emit `onSkillUnlocked({ skillId })`（UI 弹 toast）
3. 不立即持久化——由 `progressionSystem.recordRun` 的统一 `saveServiceUpdate` 一次性写入（避免多次 storage 写入）

## Formulas

### Modifier 应用

```
rawValue → signFloor(rawValue × ∏skill.targetMul)
```

**Variables**:
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| rawValue | int | -999..+999 | 原始 effect 值（来自 choice / item） |
| targetMul | float | 0.5-1.0（典型） | 每个已解锁 skill 在该 target 上的 mul |
| ∏skill.targetMul | float | 0.1-1.0 | 所有解锁 skill 的 mul 乘积 |

**signFloor**: 向零取整（正数 Math.floor / 负数 Math.ceil）——保证 -3 × 0.8 = -2（损失变小），而不是 -3 → -3。

**Identity 优化**: 若乘积为 1.0（没有相关 skill），直接返回 rawValue（避免无意义 signFloor）。

**Example**: 已解锁 thick-skin-1 (moodMul 0.8) + workplace-veteran (moodMul 0.92)
- choice effect: `{ target: 'mood', value: -10 }`
- applied: signFloor(-10 × 0.8 × 0.92) = signFloor(-7.36) = -7
- 心情仅扣 7 而非 10。

## Edge Cases

- **若 save 中有未知 skillId**（旧版本删除的 skill / 未来版本的 skill）→ `init()` 阶段 `getPassiveSkillById(id)` 返回 null，filter 静默丢弃。不抛错、不报警。
- **若 skill 没有 energyMul / moodMul**（理论上不应发生，但 schema 允许）→ `getMulForTarget` 中 `mul == null` → 不参与乘积（视为 1.0）。
- **若同一 skill 重复解锁**（例如手动调用 `unlockSkill` 两次）→ `unlockSkill` 返回 false，不 emit、不变更。
- **若 unlockCondition.type 是未来添加的新类型**（前向兼容）→ `evaluateUnlockCondition` 走 default 分支返回 false（保守地不解锁）。
- **若 stats 中 jobsPlayed[jobId] 不存在**（玩家从未玩过该职业）→ `?? 0`，jobPlays 条件不满足。

## Dependencies

### 上游
| 系统 | 用途 |
|------|------|
| 存档系统 | `SaveData.passiveSkills: string[]` 读写 |
| ProgressionSystem | 每局结束 emit + 调用 `checkUnlocks(stats)` |

### 下游
| 系统 | 接口 |
|------|------|
| ChoiceResolutionEngine | `applyToEffect(target, rawValue): number` |
| ItemSystem | （间接）ChoiceResolutionEngine 之后调用 |
| Vue Store (passiveSkillStore) | 订阅 `onSkillUnlocked` 推 UI |

### 公共接口

```typescript
class PassiveSkillSystem {
  init(unlockedIds: string[]): void
  hasSkill(id: string): boolean
  getUnlocked(): string[]
  getUnlockedSkills(): PassiveSkill[]
  applyToEffect(target: 'energy' | 'mood', rawValue: number): number
  unlockSkill(id: string): boolean
  checkUnlocks(stats: GlobalStats): string[]   // 返回 newly unlocked
  readonly onSkillUnlocked: TypedEventEmitter<{ skillId: string }>
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| PASSIVE_SKILLS catalog | 7 entries | — | 加 skill 只需 push entry，无代码改动 |
| skill.energyMul / moodMul | 0.75-0.92 | 0.5-1.0 | 过低（< 0.5）破坏数值平衡；> 1.0 视为 buff（暂未使用） |
| skill.unlockCondition.value | 3-15 | 1-50 | 解锁门槛——过低让 skill 太普遍，过高让玩家放弃 |

## Acceptance Criteria

- **GIVEN** 新玩家（stats 全 0）, **WHEN** `getUnlocked()`, **THEN** 返回 `[]`。
- **GIVEN** 玩家通关 3 次, **WHEN** `recordRun(win)` 第 3 次, **THEN** `onSkillUnlocked` emit `thick-skin-1`，且 `getUnlocked()` 包含 `thick-skin-1`。
- **GIVEN** 已解锁 thick-skin-1 (moodMul 0.8), **WHEN** `applyToEffect('mood', -10)`, **THEN** 返回 -8。
- **GIVEN** 已解锁 thick-skin-1 + thick-skin-2 (0.8 × 0.85), **WHEN** `applyToEffect('mood', -10)`, **THEN** 返回 signFloor(-10 × 0.8 × 0.85) = -6。
- **GIVEN** money effect, **WHEN** `applyToEffect('money', -100)`, **THEN** （此调用不发生，因为接口签名限制为 energy / mood）。
- **GIVEN** save 含未知 id "future-skill", **WHEN** `init(['future-skill', 'thick-skin-1'])`, **THEN** `getUnlocked()` 仅含 `thick-skin-1`。
- **GIVEN** stats.totalWins=5, **WHEN** `checkUnlocks(stats)`, **THEN** 返回 newly unlocked = `['thick-skin-1']`（一次解锁，第二次返回 `[]`）。
