# S1-8: Sprint 1 收尾 smoke check

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: qa-tester | **Estimate**: 0.5 day
> **Status**: ready-for-dev

## Goal

Sprint 1 结尾运行完整 smoke check：Vitest 全测试通过 + 三端联调首页 + 存档持久化验证。

## Test Plan

### 1. Vitest 全量

```bash
npm run test:cov
```

期望：
- 全部测试通过
- 核心 service 行覆盖率 100%（event-emitter、save-service、event-data-engine、resource-manager；day-cycle、job-rotation 如完成则也 100%）

### 2. 三端联调

| 平台 | 启动 | 资源条响应 | 存档持久化 |
|------|------|----------|----------|
| 微信开发者工具 | ☐ | ☐ | ☐ |
| 抖音模拟器 | ☐ | ☐ | ☐ |
| 支付宝模拟器 | ☐ | ☐ | ☐ |

### 3. 关键路径

- [ ] 启动到首屏 < 3 秒（占位首页）
- [ ] 状态机切换正确（多次 applyEffects 触发 NORMAL → WARNING → CRISIS）
- [ ] 关闭重启后数值恢复
- [ ] 触发死亡后状态显示正确

## Acceptance Criteria

- [ ] 所有 Logic 故事单元测试通过
- [ ] 三端模拟器至少微信通过
- [ ] 没有 console error
- [ ] smoke check 报告写入 `production/qa/smoke-2026-05-31.md`

## Test Evidence

- **Type**: Integration
- **Path**: `production/qa/smoke-2026-05-31.md`

## Dependencies

- 前置：S1-2, S1-3, S1-4, S1-5, S1-6, S1-7（应到此完成所有 Must Have）
- 阻塞：Sprint 1 进入 sign-off
