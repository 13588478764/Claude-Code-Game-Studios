# S3-9: 被动技能系统 stub（厚脸皮 Lv1 示例）

> **Sprint**: 3 | **Status**: Done | **Layer**: Feature (Alpha) | **Type**: Logic | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **TR-ID**: pending | **Manifest Version**: N/A

## Quick-Spec（lite design）

**意图**：为 Sprint 4 完整被动技能系统做地基。本故事提供：
- PassiveSkillSystem service stub（pure TS）
- 1 个示例技能"厚脸皮 Lv1"（mood 损失 ×0.8 modifier）
- 集成到 ChoiceResolutionEngine 上游：与 status modifier 串行（status 后于 passive skill）

**Modifier 计算顺序**（v2.1 GDD Open Questions 已预定）：
```
choice.effect.value
  → passiveSkill.applyToEffect(target, raw)  ← 永久 modifier
  → status.applyToEffect(target, mid)         ← 临时 modifier
  → resourceManager.applyEffects(modified)
```

被动技能在外层（先应用），status 在内层（后应用）。Sprint 4 完整版会扩展。

## Context

**ADRs**:
- **ADR-001**（事件通信）— emit onSkillUnlocked
- **ADR-003**（Service emit → Store subscribe）

**Engine**: TypeScript strict | **Risk**: MEDIUM（修改 ChoiceResolutionEngine pipeline，可能影响 S2-3 测试）

## Acceptance Criteria

- [x] AC-1: `PassiveSkillSystem.applyToEffect(target, value): number` 同 statusSystem 接口（pure TS service）
- [x] AC-2: 内置示例技能"厚脸皮 Lv1"：moodMul = 0.8（PASSIVE_SKILLS in src/types/passive-skill.ts）
- [x] AC-3: 默认无技能 → applyToEffect 返回 rawValue 不变（22 unit tests 验证）
- [x] AC-4: SaveData 加 `passiveSkills?: string[]` 字段；passive-skill-store 模块加载时 init from save，解锁后回写
- [x] AC-5: progressionSystem.onProgressRecorded 触发 passiveSkillSystem.checkUnlocks(stats) → 通关 3 次解锁 thick-skin-1 + emit onSkillUnlocked
- [x] AC-6: ChoiceResolutionEngine.applyStatusModifiers 改为 raw → passiveApplyToEffect → statusApplyToEffect → resource（passiveApplyToEffect 是新 optional dep，向后兼容）
- [x] AC-7: Sprint 1+2 测试 0 退化（386/386 pass，passive default identity）
- [x] AC-8: 100% lines + 100% branches + 100% functions on `passive-skill-system.ts`

## Implementation Notes

### 文件
- `src/types/passive-skill.ts` — PassiveSkill 类型 + 内置技能列表
- `src/services/passive-skill/passive-skill-system.ts`
- `src/stores/passive-skill-store.ts`
- 修改 `src/services/choice-resolution/choice-resolution-engine.ts` — 加 passive 调用
- 修改 `src/types/save.ts` — SaveData 加 passiveSkills?: string[] 可选字段
- `tests/unit/passive-skill-system.test.ts`

### 接口
```typescript
interface PassiveSkill {
  id: string
  name: string
  description: string
  energyMul?: number
  moodMul?: number
  unlockCondition: { type: 'wins' | 'totalRuns', value: number }
}

class PassiveSkillSystem {
  applyToEffect(target, rawValue): number  // 累乘所有 unlocked skills 的 mul
  unlockSkill(id): void
  hasSkill(id): boolean
  checkUnlocks(stats): string[]  // 返回新解锁
  
  readonly onSkillUnlocked: TypedEventEmitter<{skillId}>
}
```

### Engine 集成（ChoiceResolutionEngine）
```typescript
// 当前：
const modifiedEffects = effects.map(fx => ({
  ...fx,
  value: this.deps.statusApplyToEffect(fx.target, fx.value)
}))

// 改为：
const modifiedEffects = effects.map(fx => {
  if (fx.target === 'money') return fx
  // 1. passive skill 永久 modifier
  let v = this.deps.passiveApplyToEffect?.(fx.target, fx.value) ?? fx.value
  // 2. status 临时 modifier
  v = this.deps.statusApplyToEffect(fx.target, v)
  return { ...fx, value: v }
})
```

注意 deps.passiveApplyToEffect 是新可选字段，向后兼容（无 passive system 时 chain 不变）。

## Out of Scope

- 完整被动技能列表（Sprint 4）
- 技能 UI（图鉴页 → S3-10 nice-to-have）
- 技能升级（Beta）
- 多 mul 互斥规则（仅累乘）

## QA Test Cases

```
Logic:

AC-3: 默认无技能 → 无影响
- Setup: passiveSkillSystem 无解锁技能
- When: applyToEffect('mood', -10)
- Then: 返回 -10

AC-2: 厚脸皮 Lv1 减 mood 损失
- Setup: 解锁"thick-skin-1"
- When: applyToEffect('mood', -10)
- Then: 返回 -8（floor(-10 × 0.8) = -8）

AC-5: 解锁触发
- Setup: stats.totalWins=2
- When: checkUnlocks(stats)
- Then: 返回 []
- When: stats.totalWins=3
- When: checkUnlocks(stats)
- Then: 返回 ['thick-skin-1']

AC-6: ChoiceResolutionEngine 集成
- Setup: passive 解锁 thick-skin-1 + status emo(moodMul=1.5)
- When: choice effect mood=-10 → resolveChoice
- Then: passive 先应用：-10 × 0.8 = -8
- Then: status 后应用：-8 × 1.5 = -12
- Then: resourceManager.applyEffects([{target:'mood', value:-12}])
- Verify: 实际 mood 减 12

AC-7: 回归
- Run sprint 1+2 tests
- Verify: 全部通过（默认 deps 不传 passiveApplyToEffect → behavior 不变）
```

## Test Evidence

**Story Type**: Logic
**Required**: `tests/unit/passive-skill-system.test.ts` — pass + 100% 行覆盖
**Status**: [x] Created — 22 tests, 100% lines/branches/functions

## Dependencies

- 前置: S1-5（ResourceManager）✓ + S2-3（ChoiceResolutionEngine）✓ + S3-1（progressionSystem 触发解锁）✓
- 阻塞: 无（nice-to-have，Sprint 4 完整版才用）

## Completion Notes (2026-05-19)

**Files created**:
- `src/types/passive-skill.ts` — `PassiveSkill` 类型 + `PASSIVE_SKILLS` 内置列表（含 thick-skin-1）+ `getPassiveSkillById` + `evaluateUnlockCondition` 4 种条件类型（wins / totalRuns / totalDeaths / totalMoney）
- `src/services/passive-skill/passive-skill-system.ts` — pure TS service：init / hasSkill / getUnlocked / getUnlockedSkills / applyToEffect / unlockSkill / checkUnlocks + onSkillUnlocked emitter
- `src/stores/passive-skill-store.ts` — 模块级 wiring：模块加载时 init from saveService.load()?.passiveSkills；订阅 progressionSystem.onProgressRecorded → checkUnlocks(stats) → 回写 saveService
- `tests/unit/passive-skill-system.test.ts` — 22 tests across 6 describe blocks (identity / thick-skin-1 / checkUnlocks / unlockSkill / persistence / regression)

**Files modified**:
- `src/types/save.ts` — 添加 `passiveSkills?: string[]` optional 字段（schema v1 backward-compatible）
- `src/services/choice-resolution/choice-resolution-engine.ts` — `ChoiceResolutionDeps.passiveApplyToEffect` optional dep；`applyStatusModifiers` 改名延续但内部新 pipeline：raw → passive → status → resource
- `src/stores/choice-resolution-store.ts` — engine 实例化时传入 passiveApplyToEffect: passiveSkillSystem.applyToEffect

**Modifier 计算顺序**（v2.1 GDD Open Question 已解决）：
```
choice.effect.value
  → passiveSkill.applyToEffect(target, raw)   ← 永久 modifier (S3-9)
  → status.applyToEffect(target, mid)          ← 临时 modifier (S2-1)
  → resourceManager.applyEffects(modified)     ← 最终落盘 (S1-5)
```

**Design decisions**:
- **passive 是 optional dep**：旧 deps 配置（无 passiveApplyToEffect）行为不变 — Sprint 1+2 测试 0 退化（386/386 pass）。
- **wasStatusModified 仅追踪 status 不追踪 passive**：保留 S3-7 chip-pulse 语义。passive 是永久的，无每次 resolve 视觉反馈需求。
- **getMulForTarget 用 getUnlockedSkills() 替代直接遍历 unlocked Set**：getUnlockedSkills 已经过滤未知 id，避免 dead defensive `if (!skill)` 分支（覆盖率清洁）。
- **module-level wiring in store**：与 progression-store 一致风格，避免 Pinia 激活时序问题；模块顶层订阅 progressionSystem.onProgressRecorded 一次。

**Gates**:
- 386/386 tests pass（364 → 386，+22 新 unit 测试 — passive-skill-system 完整覆盖）
- type-check clean
- mp-weixin build 432KB（仍 <500KB AC，<2MB 硬限）
- passive-skill-system.ts: 100% lines / 100% branches / 100% functions（isolated 测试验证）

**Sprint 4 hooks**: PASSIVE_SKILLS 列表是单点 authoring surface，添加新技能只需 push entry。多 mul 累乘 product 已支持（getMulForTarget 内置）。完整版要 UI（图鉴页）+ 解锁动画 + 多 condition type 测试。
