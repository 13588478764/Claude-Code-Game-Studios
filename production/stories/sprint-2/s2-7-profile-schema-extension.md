# S2-7: Profile schema 扩展（firstStatusShown 字段）

> **Sprint**: 2 | **Status**: Complete | **Layer**: Foundation | **Type**: Logic | **Owner**: gameplay-programmer | **Estimate**: 0.25 day
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/status-system.md` v2.1 Save Migration 段（v1 → v2 评审 #1 修正）
**Requirement Summary**: 在 ProfileData 添加 `firstStatusShown?: boolean` 可选字段（permanent slot，跨局保留）。Schema v1 兼容，无需 migration shim 或 schema bump。

**Governing ADRs**:
- 无新 ADR — 此故事是 ADR-003（Service emit → Store subscribe）的应用，runtime 行为不变

**Engine**: TypeScript strict | **Risk**: LOW

---

## Acceptance Criteria

- [ ] AC-1: `src/types/save.ts` ProfileData 接口添加 `firstStatusShown?: boolean`
- [ ] AC-2: 旧存档无此字段 → load 后 `profile.firstStatusShown === undefined`（不是 false 也不是 null）
- [ ] AC-3: 设为 true → save → load → 仍为 true
- [ ] AC-4: SaveService 不需要新代码，schema v1 兼容
- [ ] AC-5: 单元测试追加到 `tests/unit/save-service.test.ts`
- [ ] AC-6: 不破坏 Sprint 1 已有 14 个 SaveService 测试

---

## Implementation Notes

### 文件
- `src/types/save.ts` — 修改 ProfileData 接口（如已存在）或扩展 SaveData.profile 子结构
- `tests/unit/save-service.test.ts` — 追加 3 个测试

### 修改要点
```typescript
// src/types/save.ts
export interface ProfileData {
  // ...existing fields...
  firstStatusShown?: boolean  // v2 新增可选（permanent，跨局保留）
}
```

> **关键**：Sprint 1 的 SaveService.load/save 是泛型化处理 SaveData object，新增字段自动 round-trip，无需修改 service。本故事仅是类型层面的扩展 + 测试覆盖。

---

## Out of Scope

- 教学气泡 UI 实现（S2-10）
- profile 其他字段扩展（按需在后续故事添加）

---

## QA Test Cases

### Logic Tests（追加到 save-service.test.ts）

**AC-2: 旧存档兼容**
- Given: storage 中已有的 profile JSON 不含 `firstStatusShown` 字段
- When: SaveService.load()
- Then: 返回的 SaveData.profile.firstStatusShown === undefined
- Edge: 字段为 null → 仍当作 undefined 处理

**AC-3: round-trip**
- Given: profile.firstStatusShown=true
- When: save → 再 load
- Then: profile.firstStatusShown === true

**AC-1: 类型校验（编译期）**
- When: `npm run type-check`
- Then: 无 TS 错误，新字段类型正确

---

## Test Evidence

**Story Type**: Logic
**Required**: 追加到 `tests/unit/save-service.test.ts`，跑 `npm test` 通过 + sprint-1 全套不退化
**Status**: [x] 4 测试追加 2026-05-19 — 全部通过

## Completion Notes

**Files modified**:
- `src/types/save.ts` — `SaveData` 添加可选 `firstStatusShown?: boolean`（顶层字段，文档说明为永久 UI 标志）
- `tests/unit/save-service.test.ts` — 追加 4 个测试

**Verification**:
- npm test: 247/247 pass（前 243 + 新 4）
- npm run type-check: pass
- Sprint 1 SaveService 14 个测试全部回归通过 ✓

**Design choice**:
- save.ts 没有独立 ProfileData 接口（设计本来就是 flat SaveData），所以字段加在 SaveData 顶层而非嵌套 profile 子对象
- 字段语义：跨局保留 = 不在 currentRun 中，而是在 SaveData 顶层（类似 jobUnlocks/stats）。currentRun 清空时不影响

**Deviations**: None

Ready for: `/code-review` → `/story-done`

---

## Dependencies

- 前置: S1-3（SaveService）
- 阻塞: S2-10（教学气泡 UI 需要读取 profile.firstStatusShown）
- 可与 S2-1 ~ S2-5 并行
