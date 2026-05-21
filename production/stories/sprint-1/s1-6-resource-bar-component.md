# S1-6: ResourceBar Vue 组件

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: ui-programmer | **Estimate**: 0.5 day
> **Status**: ready-for-dev

## Goal

实现 ResourceBar 单组件，纯展示性，颜色按阈值切换，过渡动画 600ms。

## GDD Requirements Addressed

- game-main-ui GDD: 资源条三条（energy/mood/money）

## Governing ADRs

- **ADR-003** — 组件用 `storeToRefs` 订阅，不直接调 service

## Technical Approach

### 文件

- `src/components/ResourceBar.vue`
- 视觉品质参考 `prototypes/core-loop/index.html` v2 — 渐变 + 高光 + 发光描边

### Props

```typescript
defineProps<{
  value: number          // 当前值
  max?: number           // 默认 100
  type: 'energy' | 'mood' | 'money'
  showIcon?: boolean     // 默认 true
  showValue?: boolean    // 默认 true
}>()
```

### 颜色阈值

| Type | ≤20 | ≤30 | ≤50 | >50 |
|------|-----|-----|-----|-----|
| energy | 红 #FF6B6B | 红 #FF6B6B | 黄 #FFCC00 | 绿 #4CD964 |
| mood | 紫 #9B6BFF | 灰 #8E8E93 | 橙 #FF9500 | 橙 #FF9500 |
| money | 数值 < 0 红字，否则金色 #FFCC00（无条形） |

### 视觉细节

- 高度 14px，圆角 999px
- 内嵌阴影 + 50% 高光层
- 过渡：`width 0.6s cubic-bezier(0.4, 0, 0.2, 1)`
- 颜色变化平滑 300ms

## Acceptance Criteria

- [ ] 三种类型在三端模拟器渲染一致
- [ ] 颜色阈值切换正确（手动验证表格）
- [ ] 过渡动画无跳变
- [ ] money 类型不显示条形，只显示数字
- [ ] 触控区域 ≥ 44×44px（accessibility）

## Test Evidence

- **Type**: Visual/UI
- **Path**: `production/qa/evidence/s1-6-resource-bar.md`（手动测试 + 截图）

## Dependencies

- 前置：S1-1, S1-5
- 阻塞：S1-7
