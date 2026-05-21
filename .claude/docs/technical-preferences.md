# Technical Preferences

## Engine & Language

- **Framework**: uni-app (Vue 3 composition API)
- **Language**: TypeScript (strict mode)
- **Rendering**: DOM组件渲染（无Canvas）
- **State Management**: Pinia + uni.setStorageSync 持久化

## Input & Platform

- **Target Platforms**: 微信小程序、抖音小程序、支付宝小程序
- **Input Methods**: Touch（纯触屏）
- **Primary Input**: Touch（单手拇指操作）
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 所有交互区域最小44×44px，按钮在屏幕下半区方便单手操作。需适配不同屏幕尺寸和安全区。

## Naming Conventions

- **Components**: PascalCase (e.g., `EventCard.vue`, `ResourceBar.vue`)
- **Composables**: camelCase + use前缀 (e.g., `useGameState.ts`, `useEventDeck.ts`)
- **Variables/Functions**: camelCase (e.g., `playerEnergy`, `drawNextEvent()`)
- **Types/Interfaces**: PascalCase (e.g., `JobConfig`, `EventCard`, `GameState`)
- **Files (非组件)**: kebab-case (e.g., `game-config.ts`, `event-engine.ts`)
- **Data files**: kebab-case (e.g., `programmer-events.json`, `job-list.json`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_ENERGY`, `DAYS_PER_JOB`)
- **Events/Emits**: camelCase (e.g., `choiceSelected`, `dayEnded`)

## Performance Budgets

- **Target Framerate**: 60fps（小程序环境，以流畅交互为目标）
- **Package Size**: 主包 < 2MB，分包总计 < 20MB（小程序限制）
- **First Load**: < 3秒（冷启动到可交互）
- **Memory Ceiling**: < 128MB（低端安卓设备兼容）

## Testing

- **Framework**: Vitest (单元测试) + uni-app 条件编译测试
- **Minimum Coverage**: 核心游戏逻辑（事件引擎、资源计算）100%覆盖
- **Required Tests**: 事件权重抽取逻辑、资源变化计算、存档读写、职业解锁条件

## Forbidden Patterns

- 不使用 Canvas 渲染（本项目为UI驱动，DOM组件即可）
- 不硬编码游戏数值（所有数值来自JSON配置）
- 不使用 `any` 类型（strict TypeScript）
- 不在组件中直接写业务逻辑（抽取到 composables/services）

## Allowed Libraries / Addons

- [None configured yet — add as dependencies are approved]

## Architecture Decisions Log

- ADR-001: 事件通信机制 — 自实现 TypedEventEmitter (Accepted)
- ADR-002: 分包策略 — 按职业分包+通用事件在主包 (Accepted)
- ADR-003: Store-Service 同步模式 — Service emit → Store subscribe (Accepted)

## Specialists

- **Primary**: gameplay-programmer (核心游戏逻辑)
- **UI**: ui-programmer (Vue组件、页面布局、交互)
- **Systems Design**: systems-designer (事件平衡、数值设计)
- **Routing Notes**: 本项目无需引擎专家。前端架构问题由 lead-programmer 处理，游戏系统逻辑由 gameplay-programmer 处理，UI交互由 ui-programmer 处理。

### File Extension Routing

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| 游戏逻辑 (.ts composables/services) | gameplay-programmer |
| Vue组件 (.vue) | ui-programmer |
| 数据配置 (.json) | systems-designer |
| 样式文件 (.scss/.css) | ui-programmer |
| 类型定义 (.d.ts) | lead-programmer |
| 构建/部署配置 | devops-engineer |
| General architecture review | lead-programmer |
