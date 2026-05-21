# S1-7: 占位首页（联调用）

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **Status**: ready-for-dev

## Goal

实现一个最小首页，用 ResourceBar 显示三资源 + 测试按钮触发 applyEffects，验证 Service → Store → UI 的响应式链路通畅。

## GDD Requirements Addressed

- 不直接对应 GDD（Sprint 2 用真正的 game-main-ui 替换）
- 此页面只是 Foundation 层 smoke test 的载体

## Technical Approach

### 文件

- `src/pages/index/index.vue`

### 布局

```
+----------------------+
|   打工轮回 Sprint 1   |
+----------------------+
| ⚡ ════════ 80      |
| 😊 ══════   60      |
| 💰          0 元    |
+----------------------+
| [+10 精力]  [-5 心情]|
| [+20 钱]   [-15 精力]|
| [重置]               |
+----------------------+
| 状态: NORMAL         |
+----------------------+
```

### 关键实现要点

- 用 `storeToRefs(useResourceStore())` 订阅状态
- 按钮调用 `resourceStore.applyEffects([{ target: 'energy', value: +10 }])`
- 显示 `getState()` 当前状态（NORMAL/WARNING/CRISIS）
- App 启动时尝试 `saveStore.load()` 恢复数据，失败则用默认值

## Acceptance Criteria

- [ ] 在微信开发者工具运行成功
- [ ] 资源条响应按钮变化（< 100ms 视觉反馈）
- [ ] 关闭重启后资源数值恢复（验证存档系统集成）
- [ ] 状态文字随阈值切换正确
- [ ] 按钮触控区域 ≥ 44×44px

## Test Evidence

- **Type**: Integration
- **Path**: `production/qa/evidence/s1-7-placeholder-home.md`

## Dependencies

- 前置：S1-1, S1-3, S1-5, S1-6
- 阻塞：S1-8
