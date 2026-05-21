# QA Plan — Sprint 1

> **Sprint**: 1 (2026-05-18 → 2026-05-31)
> **Goal**: Foundation + Core layer (5 MVP systems)
> **Generated**: 2026-05-18

## Test Strategy

Sprint 1 大量为 Logic 类故事（service 层逻辑），覆盖率要求 100%（核心 service 层）。
UI 类故事（ResourceBar / 占位首页）以手动验证 + 截图为主。

## Story Test Classification

| Story | Type | Test Evidence | Coverage Target |
|-------|------|---------------|-----------------|
| S1-1 项目脚手架 | Config/Data | smoke check `production/qa/smoke-2026-05-19.md` | 三端模拟器跑通 hello world |
| S1-2 TypedEventEmitter | Logic | `tests/unit/event-emitter.test.ts` | 100% 行覆盖 + 100% 分支覆盖 |
| S1-3 存档系统 | Logic | `tests/unit/save-service.test.ts` | 100% 行覆盖（含 schema 迁移） |
| S1-4 事件数据引擎 | Logic | `tests/unit/event-data-engine.test.ts` | 100% 行覆盖（含 fallback 路径） |
| S1-5 资源管理系统 | Logic | `tests/unit/resource-manager.test.ts` | 100% 行覆盖（含状态机所有边界） |
| S1-6 ResourceBar 组件 | Visual/UI | 手动截图 + 交互测试文档 `production/qa/evidence/s1-6-resource-bar.md` | 颜色阈值视觉验证 |
| S1-7 占位首页 | Integration | 手动联调测试文档 `production/qa/evidence/s1-7-placeholder-home.md` | Service→Store→UI 链路通畅 |
| S1-8 收尾测试 | Integration | smoke check 通过报告 | 全部 Logic 故事覆盖率达标 |
| S1-9 日周期系统 | Logic | `tests/unit/day-cycle-system.test.ts` | 100% 行覆盖 |
| S1-10 职业轮回系统 | Logic | `tests/unit/job-rotation-system.test.ts` | 100% 行覆盖（推荐算法） |
| S1-11 占位事件 | Config/Data | smoke check（schema 校验通过） | 100 张事件全部解析成功 |

## Required Unit Test Cases

### S1-2 TypedEventEmitter

```
test('on() registers handler')
test('emit() invokes registered handlers in order')
test('emit() with no handlers is no-op')
test('off() unregisters specific handler')
test('off() with unknown handler is no-op')
test('once() invokes handler only once')
test('clear() removes all handlers')
test('handler exception does not block other handlers')
test('payload typing is preserved')
test('emit during emit (re-entrancy) does not double-invoke')
```

### S1-3 SaveService

```
test('save() persists to uni.setStorageSync with correct key')
test('load() returns parsed object from storage')
test('load() returns null when key not exists')
test('save() includes schema version in payload')
test('load() triggers migration when schema version differs')
test('migrate() chains across versions correctly')
test('clear() removes data from storage')
test('save() debounces rapid calls (within 100ms)')
test('emit onSaved after successful save')
test('emit onLoadFailed when storage corrupted')
```

### S1-4 EventDataEngine

```
test('loadCommon() loads common-events.json from main package')
test('loadJobEvents(jobId) loads from subpackage path')
test('schema validation rejects malformed events')
test('retry up to 3 times on network failure')
test('fallback to 5 hardcoded events after retries exhausted')
test('drawEvent() respects weight distribution')
test('drawEvent() avoids recently used events (last 5)')
test('unload() clears job-specific events from memory')
test('emit onLoadComplete with event count')
test('emit onLoadFailed with reason on permanent failure')
```

### S1-5 ResourceManager

```
test('init() sets initial values from config')
test('applyEffects() clamps energy 0-100')
test('applyEffects() clamps mood 0-100')
test('money has no clamp (can go negative)')
test('state transitions: NORMAL → WARNING when energy ≤ 30')
test('state transitions: NORMAL → WARNING when mood ≤ 30')
test('state transitions: WARNING → CRISIS when mood ≤ 20')
test('state transitions: → DEAD when energy = 0')
test('state transitions: → DEAD when mood = 0')
test('emit onResourceChanged with before/after values')
test('emit onStateChanged when transitioning')
test('emit onResourceDepleted with which resource')
test('multiple effects in one applyEffects call are atomic')
test('passive modifier applies before clamp')
test('reset() returns to initial state')
```

### S1-9 DayCycleSystem

```
test('startDay(1) sets eventsToday from config')
test('eventCompleted() increments and emits onEventCompleted')
test('eventCompleted() at last event triggers onDayEnded')
test('day 5 last event triggers onWeekCompleted (not onDayEnded)')
test('getCurrentDay() returns correct value')
test('reset() returns to day 1')
```

### S1-10 JobRotationSystem

```
test('initial unlocks: intern + programmer')
test('selectJob(unknown) throws')
test('checkUnlocks() unlocks based on save data')
test('recommend weight: recently played × 0.1')
test('recommend weight: never played × 5.0')
test('recommend weight: locked excluded')
test('emit onJobUnlocked when criteria met')
test('emit onJobSelected when player picks')
```

## Manual Test Checklists

### S1-6 ResourceBar Manual Test

```
[ ] 微信开发者工具：3 条资源条正确显示
[ ] 抖音模拟器：3 条资源条正确显示
[ ] 支付宝模拟器：3 条资源条正确显示
[ ] energy = 80 → 绿色
[ ] energy = 40 → 黄色
[ ] energy = 20 → 红色
[ ] mood = 70 → 橙色
[ ] mood = 25 → 灰色
[ ] mood = 15 → 紫色
[ ] money = -10 → 红色文字
[ ] 触发 applyEffects 后过渡动画 600ms 无跳变
```

### S1-7 占位首页联调测试

```
[ ] 启动后 3 秒内显示首页
[ ] 资源条初始值：energy 80 / mood 60 / money 0
[ ] 点击"测试 +energy" 按钮 → 资源条上涨
[ ] 点击"测试 -mood" 按钮 → 资源条下降
[ ] 资源条颜色按阈值切换
[ ] 关闭重启 → 数值持久化（存档系统验证）
[ ] 点击"重置" → 回到初始值
```

## Smoke Check Gate

Sprint 1 收尾时运行 `/smoke-check sprint`，必须通过：

- 所有 Logic 故事单元测试 100% 行覆盖
- 占位首页能在三端模拟器启动到可交互
- 资源管理 service → store → UI 完整链路工作
- 存档读写持久化验证（关闭重启后数据恢复）

## Sign-off Criteria

Sprint 1 进入 sign-off 需要：

- [ ] 8 个 Must Have 故事全部 Done 状态
- [ ] 测试覆盖率报告达标
- [ ] 没有 S1/S2 级 bug
- [ ] 三端兼容性已验证（最低微信开发者工具）
- [ ] 任何架构偏离已写入 ADR

## Out of Scope (Sprint 2+)

- Performance profiling（首屏 < 3s 等指标）— 在 Sprint 2 完整 UI 完成后做
- 真机测试 — Sprint 2 联调阶段
- 多端兼容真机测试 — Sprint 3
- 安全审计 — Polish 阶段
