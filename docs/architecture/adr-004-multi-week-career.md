# ADR-004: 多周职业架构

## Status

Accepted

## Date

2026-05-20

## Last Verified

2026-05-21

## Context

Sprint 1-3 的 MVP 设计是 "1 run = 1 周 5 天"。Sprint 4 用户首次手测后反馈："一周时间有点短，可以延长，增加可玩性"。需要把一个 run 扩展为多周 career，同时为升职机制（每周末打分 + 升 Lv）打地基。

约束：
- 不能破坏现有日内事件循环（DayCycleSystem + EventCardSystem 现状已稳）
- 升职是按"周"为节奏（而不是按"天"）— 周末打分决定是否升 Lv
- SETTLING 触发点需要从"周末"变为"career 末"
- 不同职业可能有不同节奏（实习 2 周，全职 4 周，未来管理岗可能 8 周）
- 现有 RunManager 状态机 + StatusSystem subscribeToDayEnded 等 wiring 不应被打破

## Decision

**`JobConfig.weeksPerCareer` 配置化 + DayCycleSystem 引入 `weekIndex` + 新事件 `onCareerCompleted` 替代 `onWeekCompleted` 触发 SETTLING**

具体改动：

1. **JobConfig 加 `weeksPerCareer?: number` 字段**（默认 `DEFAULT_WEEKS_PER_CAREER = 4`）
2. **DayCycleSystem 引入 weekIndex 维度**：
   - `configure(weeksPerCareer: number)` 设置 career 总长
   - `startWeek(n: number)` 进入第 N 周（重置 day 到 1）
   - `getWeekIndex() / getWeeksPerCareer() / isLastWeek()` 查询 API
   - 所有现有事件 payload 加 `weekIndex` 字段（onDayStarted/onDayEnded/onWeekCompleted）
3. **拆分 onWeekCompleted vs onCareerCompleted**：
   - `onWeekCompleted` 每周末（day 5 完成）都 fire — 用于周末 review event hook + 升职打分（CareerProgressionSystem.recordWeek）
   - `onCareerCompleted` 仅在最后一周末 fire — RunManager 通过 `subscribeToCareerCompleted` 监听以触发 SETTLING（原本是 subscribeToWeekCompleted）
4. **useGameSession 自动 advance**：周末（非 career 末）→ 自动 startWeek(+1) + startDay(1)
5. **useGameSession bootstrap**：configure → startWeek(1) → startDay(1)

数据流：
```
day 5 last event resolved
  → onDayEnded { day:5, weekIndex:N, salary }
  → onWeekCompleted { weekIndex:N, weekSalary }
    → CareerProgressionSystem.recordWeek(score) → 可能升职
    → weekend-review event 已触发（S4-3 在 onDayStarted 钩子里）
  → if weekIndex < weeksPerCareer: 自动 startWeek(N+1) startDay(1)
  → if weekIndex === weeksPerCareer: onCareerCompleted → RunManager SETTLING
```

## Consequences

**正面：**
- 一个 run 从 5 天扩到 20 天（4 周默认）— 解决"太短"反馈
- 升职机制有了天然的"打分节奏"（周末 review）
- 每职业 可配置不同节奏 — 未来 banker/intern 长度可不同
- onWeekCompleted 不再背两个职责（既是 SETTLING 又是周末 hook）— 关注点分离
- DayCycle 状态扩展是加法 — 现有 day-level 测试只需补 `weekIndex: 1` 字段不变行为

**负面：**
- 现有 21 day-cycle 测试需要更新 payload（小工作量）
- RunManager 整合点 rename（subscribeToWeekCompleted → subscribeToCareerCompleted）— 是 breaking 但局部
- 一个 run 20 天 → 1 局玩耍时间 5-10 分钟（vs 之前 1-2 分钟）— 接受为期望改变

**缓解：**
- weekIndex 字段在 payload 中标 required（不可选）— TypedEventEmitter invariant 强制 caller 一致
- 旧测试一次性 sed/手改完成，无后续维护
- 玩家中途关游戏：G-1 save resume 在 day-boundary checkpoint，可恢复

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | uni-app + Vue 3 |
| **Domain** | Core (game state machine) |
| **Knowledge Risk** | LOW |
| **References Consulted** | 现有 `services/day-cycle/day-cycle-system.ts` / `services/run-manager/run-manager.ts` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — 纯应用层 state 扩展 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TypedEventEmitter) |
| **Enables** | S4-2 升职 / S4-3 周末 review / G-1 save resume / ADR-007 |
| **Blocks** | Sprint 4 全部 must-have（S4-1 ~ S4-7） |

## GDD Requirements Addressed

- 用户 2026-05-20 设计文档：「职业模板由浅入深 + 进阶模板需解锁/广告观看」— 多周 career 支撑职级递进
- 用户反馈：「一周时间有点短，可以延长，增加可玩性」
- 用户设计：「升职加薪」需要"周末打分"节奏
