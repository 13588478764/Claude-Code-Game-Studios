# 游戏主界面 (Game Main UI)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 三秒上手（UI即教程，零学习成本）+ 一局一笑（视觉反馈放大荒诞感）

## Overview

游戏主界面是玩家在对局中看到的唯一屏幕——整合了资源条、事件卡片、日期指示器和状态反馈。它不是一个"系统"而是所有系统的视觉表达层。设计原则：屏幕上同一时间只有一件事需要玩家关注。服务支柱"三秒上手"——新玩家看到界面的第一秒就知道该做什么（看文字→点按钮）。

## Player Fantasy

**直接幻想**：玩家感受到的是"我的打工桌面"——顶部是体力/心情/钱包的生命线，中间是今天的事儿，底部是选择。整个界面就像一个极简的"今日待办"，但内容是荒诞的。视觉反馈（资源条跳动、颜色变化、表情变化）让每个选择都有"手感"。

## Detailed Design

### Core Rules

1. **屏幕布局（竖屏, 750rpx宽）**：

```
┌──────────────────────────┐
│  [周X]  第N天/共5天       │  ← 顶栏: 日期指示器 (48rpx高)
├──────────────────────────┤
│  ⚡ ████████░░ 75        │  ← 资源条区域 (180rpx高)
│  😊 ██████░░░░ 45        │     三条并排, 带数字+图标
│  💰 120                  │     money无进度条,只显示数字
├──────────────────────────┤
│                          │
│   ┌────────────────┐     │  ← 卡片区域 (占剩余空间)
│   │  事件文案描述   │     │     居中显示事件卡
│   │  ...           │     │
│   │                │     │
│   └────────────────┘     │
│                          │
├──────────────────────────┤
│  ┌──────┐  ┌──────┐     │  ← 选项区域 (200rpx高)
│  │选项 A │  │选项 B │     │     两个按钮并排
│  └──────┘  └──────┘     │
└──────────────────────────┘
```

2. **资源条组件**：
   - 三条水平进度条，左侧图标+右侧数字
   - 颜色规则：
     - energy: 绿色(#4CD964) → 黄色(≤50) → 红色(≤30)
     - mood: 橙色(#FF9500) → 灰色(≤30) → 紫黑色(≤20, CRISIS)
     - money: 金色(#FFCC00)，负数时变红
   - 变化动画：数值变化时进度条弹性过渡(300ms ease-out)
   - 变化飘字："+20"或"-15"从数字位置飘出并消失

3. **日期指示器**：
   - 显示"周X · 第N天"（如"周三 · 第3天"）
   - 下方显示小圆点进度(●●●○○ = 5天中过了3天)
   - 每天开始时有"翻页"过渡动画

4. **事件卡片组件**：
   - 白色圆角卡片，居中，带轻微阴影
   - 文案区域自适应高度（最小200rpx，最大400rpx）
   - 入场：从底部滑入+轻微放大(scale 0.95→1.0)
   - 退场：向上淡出+缩小

5. **选项按钮组件**：
   - 两个等宽按钮，间距24rpx
   - 按钮内显示选项文案（最多2行，超出省略）
   - 点击态：按下缩小(scale 0.95) + 颜色加深
   - 选中后：被选按钮高亮，未选按钮灰出
   - 禁用态（RESOLVING期间）：降低透明度，不响应点击

6. **状态反馈层**：
   - WARNING：资源条区域轻微闪红（脉冲动画，不阻挡操作）
   - CRISIS：屏幕边缘红色渐晕 + 资源条持续抖动
   - DEAD：全屏灰色遮罩 + 死因文案居中显示
   - 日薪发放：顶部弹出"+10💰 日薪到账"横幅(2s消失)

### States and Transitions

| UI状态 | 对应系统状态 | 显示内容 |
|--------|-------------|---------|
| `CARD_DISPLAY` | 事件卡SHOWING | 卡片+选项按钮可交互 |
| `RESOLVING` | 事件卡RESOLVING | 选项灰出+资源变化动画 |
| `DAY_TRANSITION` | 日周期DAY_END→DAY_START | 日期翻页动画+日薪横幅 |
| `DEATH_OVERLAY` | 局管理器DYING | 灰色遮罩+死因+续命按钮 |
| `LOADING` | 局管理器INITIALIZING | 简单加载提示 |

### Interactions with Other Systems

| 系统 | 方向 | UI响应 |
|------|------|--------|
| 资源管理系统 | ← 监听 onResourceChanged | 更新资源条数值+动画 |
| 资源管理系统 | ← 监听 onStateChanged | 切换WARNING/CRISIS视觉效果 |
| 事件卡系统 | ← 监听 onCardShown | 渲染新卡片 |
| 事件卡系统 | → 用户输入 | 点击选项 → `selectChoice('A'/'B')` |
| 日周期系统 | ← 监听 onDayStarted/onDayEnded | 日期指示器更新+过渡动画 |
| 状态效果系统 | ← 监听 onStatusChanged | 渲染顶部状态胶囊条（最多 2 个）+ status 触发修正时该 chip pulse 动画。详见 `design/gdd/status-system.md` |
| 局管理器 | ← 监听 onPhaseChanged | DYING→显示死亡遮罩 |

## Formulas

### 资源条颜色插值

`color = interpolate(colorStops, value / MAX)`

| 阈值 | energy颜色 | mood颜色 |
|------|-----------|---------|
| 100-51 | #4CD964 (绿) | #FF9500 (橙) |
| 50-31 | #FFCC00 (黄) | #8E8E93 (灰) |
| 30-0 | #FF3B30 (红) | #5856D6 (紫黑) |

### 卡片文案字号自适应

`fontSize = max(MIN_FONT, BASE_FONT - (lineCount - 3) × 2)`

| Variable | Value | Description |
|----------|-------|-------------|
| BASE_FONT | 32rpx | 基础字号(≤3行) |
| MIN_FONT | 26rpx | 最小字号 |
| lineCount | 1-5+ | 文案行数 |

## Edge Cases

- **If 屏幕过小(宽<320px)**：选项按钮改为上下堆叠而非左右并排。

- **If 资源变化动画未播完时又来新变化**：中断当前动画，直接跳到最终值后播放新动画。

- **If 事件文案包含特殊字符/emoji**：正常渲染，emoji作为文案幽默的一部分。

- **If 网络断开时需要展示广告续命按钮**：显示按钮但点击后提示"网络不可用"，3秒后自动进入结算。

- **If 玩家快速连点（100ms内多次点击同一按钮）**：第一次点击生效，后续忽略（debounce 300ms）。

- **If 小程序被系统回收后恢复**：重新加载页面，读取存档恢复UI状态。卡片区域可能需要重新渲染当前事件。

## Dependencies

### 上游

| 系统 | 依赖类型 | 说明 |
|------|---------|------|
| 事件卡系统 | Hard | 提供当前卡片数据和阶段状态 |
| 资源管理系统 | Hard | 提供资源值和状态变化事件 |
| 日周期系统 | Hard | 提供日期信息和日切事件 |
| 状态效果系统 | Hard | 提供 active statuses（≤2 个）+ status 修正触发的 chip pulse 信号 |
| 选择结算引擎 | Soft | 间接(通过事件卡系统获取结果) |
| 局管理器 | Hard | 提供局阶段(死亡/加载等) |

### 下游

无（终端展示层）。

### 公共接口

```typescript
// 游戏主界面是Vue组件，不暴露传统接口
// 通过响应式数据绑定和事件监听与系统交互

// 组件Props/Inject:
interface GameMainProps {
  // 通过Pinia store响应式获取:
  // - resourceStore.resources
  // - resourceStore.state
  // - eventCardStore.currentCard
  // - eventCardStore.phase
  // - dayCycleStore.currentDay
  // - runStore.phase
}

// 组件Emit:
interface GameMainEmits {
  choiceSelected: (key: 'A' | 'B') => void
  reviveRequested: () => void
  settlementClosed: () => void
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 说明 |
|--------|--------|---------|------|
| `RESOURCE_BAR_ANIM_MS` | 300 | 150-500 | 资源条变化动画时长 |
| `FLOAT_TEXT_DURATION_MS` | 800 | 500-1500 | 飘字动画持续时长 |
| `BUTTON_DEBOUNCE_MS` | 300 | 200-500 | 按钮防连点间隔 |
| `WARNING_PULSE_MS` | 1000 | 500-2000 | WARNING闪烁周期 |
| `CARD_MAX_HEIGHT_RPX` | 400 | 300-500 | 卡片最大高度 |

## Acceptance Criteria

- **GIVEN** 游戏进入PLAYING阶段, **WHEN** 界面加载完成, **THEN** 资源条显示正确初始值，日期显示"周一 · 第1天"，卡片区域显示第一个事件。

- **GIVEN** 玩家点击选项A, **WHEN** 按钮未处于禁用态, **THEN** 按钮显示点击动画，300ms后进入RESOLVING（按钮灰出），资源条播放变化动画。

- **GIVEN** energy从45变为21, **WHEN** 值≤30, **THEN** energy进度条颜色变红，WARNING脉冲动画开始。

- **GIVEN** 一天结束, **WHEN** 日薪发放, **THEN** 顶部弹出"+10💰"横幅，money数字递增动画。

- **GIVEN** 局管理器进入DYING, **WHEN** energy=0, **THEN** 全屏灰色遮罩，中央显示死因文案+"看广告续命"按钮。

- **GIVEN** 100ms内连续点击同一按钮3次, **WHEN** debounce生效, **THEN** 只处理第一次点击。
