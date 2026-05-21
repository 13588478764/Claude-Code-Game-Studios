# 存档系统 (Save System)

> **Status**: Designed
> **Author**: user + agents
> **Last Updated**: 2026-05-16
> **Implements Pillar**: 随开随走、永远有新的

## Overview

存档系统是《打工轮回》的数据持久化基础设施。它为所有需要跨会话保存状态的系统（资源管理、职业轮回、永久进度、被动技能）提供统一的读写接口。

系统负责：
- **局内存档**：当前进行中的一局状态（精力/心情/钱/当前天数/事件历史），支持随时退出、无缝恢复
- **永久存档**：跨局积累的持久数据（已解锁职业、社会经验值、被动技能等级、成就、累计金币）
- **数据完整性**：防止写入失败导致的数据损坏（写前备份策略）

玩家不直接"使用"存档系统，但它是支柱"随开随走"的技术保障——如果存档系统不可靠，玩家打开游戏发现进度丢失，整个体验就崩塌了。

## Player Fantasy

**间接幻想**：玩家不会感知到存档系统的存在。他们的体验是——任何时刻合上手机，下次打开时一切都还在原来的位置。没有"请等待保存"提示，没有"是否保存进度"弹窗，没有丢失的恐惧。

这个系统做得好时，玩家的感受是"这个游戏好方便"；做得差时，玩家的感受是"我的进度去哪了！！！卸载。"

服务支柱：**随开随走** — "如果一个机制需要玩家'必须打完这一段'，砍掉它。"

## Detailed Design

### Core Rules

1. **双槽存储架构**：系统维护两个独立数据槽：
   - `runState`（局内状态）— 记录当前进行中的一局，只有1个槽位
   - `profile`（永久档案）— 记录所有跨局持久数据，只有1个槽位

2. **自动保存，无手动保存**：
   - `runState` 在每次玩家做出选择后自动写入（事件选择确认时）
   - `profile` 在每局结算后写入（解锁/经验/金币变化时）
   - 无"保存按钮"，无保存提示

3. **写前备份策略**：
   - 每次写入前，将当前数据复制到 `_backup` key
   - 写入完成后标记 `_valid = true`
   - 读取时：优先读主key；如果主key的 `_valid` 不为 true，回退到 `_backup`

4. **数据版本化**：
   - 每个存档带 `version` 字段
   - 新版本发布时通过迁移函数升级旧数据结构
   - 无法识别的版本不删除，标记为 `needsMigration`

### States and Transitions

| 状态 | 含义 | 转换条件 |
|------|------|---------|
| `NO_DATA` | 首次进入，无任何存档 | → `HAS_PROFILE`: 完成首次初始化 |
| `HAS_PROFILE` | 有永久档案，无进行中的局 | → `IN_RUN`: 开始新一局 |
| `IN_RUN` | 有进行中的局 | → `HAS_PROFILE`: 局结束（通关/失败）|
| `IN_RUN` | 有进行中的局 | → `IN_RUN`: 每次选择后自动保存 |
| `CORRUPTED` | 数据校验失败 | → `HAS_PROFILE`: 回退到backup成功 |
| `CORRUPTED` | backup也损坏 | → `NO_DATA`: 重置（极端情况） |

### Interactions with Other Systems

| 系统 | 方向 | 接口描述 |
|------|------|---------|
| 资源管理系统 | ← 写入 / → 读取 | 读写 `runState.resources {energy, mood, money}` |
| 职业轮回系统 | ← 写入 / → 读取 | 读写 `profile.unlockedJobs[]` 和 `runState.currentJob` |
| 永久进度系统 | ← 写入 / → 读取 | 读写 `profile.socialExp`, `profile.totalMoney` |
| 被动技能系统 | ← 写入 / → 读取 | 读写 `profile.passiveSkills[]` |
| 局管理器 | → 通知 | 局结束时通知存档系统清除 `runState` |
| 日周期系统 | ← 写入 | 写入 `runState.currentDay`, `runState.eventsToday[]` |
| 状态效果系统 | ← 写入 / → 读取 | 读写两个字段（均为 schema v1 可选字段，无需 bump）：(1) `runState.statuses?: StatusEffect[]` 当前局活跃状态，缺省=[]；(2) `profile.firstStatusShown?: boolean` 跨局首次教学标志（permanent slot，局结束不清空）。详见 `design/gdd/status-system.md` Save Migration |

## Formulas

存档系统无游戏平衡公式。关键技术约束如下：

### 存储容量估算

`totalStorage = runState + profile + backups ≈ 26 KB`

| 数据项 | 估计大小 |
|--------|---------|
| runState (单局) | ~3 KB |
| profile (永久) | ~10 KB (20职业全解锁状态) |
| profile_backup | ~10 KB |
| runState_backup | ~3 KB |
| **总计** | **~26 KB** |

小程序单key限制1MB，总存储限制10MB。当前设计远在安全范围内。

### 保存频率

`savesPerMinute ≈ 3-5次/分钟`（每次事件选择触发一次保存）

每次写入量 < 5KB，uni.setStorageSync 对此量级无性能问题。

## Edge Cases

- **If 玩家在写入过程中强杀小程序**：下次打开时检测 `_valid` 标记，若为 false 则回退到 `_backup`。备份始终是上一次成功写入的完整状态。

- **If `_backup` 也损坏（主key和backup都无法解析）**：将 `profile` 重置为初始状态。`runState` 直接清除（损失当前局，不损失永久进度）。记录错误日志供后续分析。

- **If 小程序Storage被用户手动清除**：等同于全新安装。所有数据丢失，从 `NO_DATA` 状态重新开始。无法防御此情况。

- **If 存档版本低于当前代码版本**：触发迁移函数链（v1→v2→v3...），逐版本升级数据结构。迁移前先备份原始数据。

- **If 存档版本高于当前代码版本**（降级安装）：不修改数据，标记为 `needsMigration`，提示用户更新小程序。

- **If 玩家在多个设备登录同一账号**：MVP不处理多设备同步。每个设备独立本地存储。Alpha阶段引入平台云存储时再设计冲突解决策略。

- **If Storage写入失败**（设备存储满）：捕获异常，向UI层发出 `saveError` 事件。游戏继续运行（内存中状态不丢），但显示提示"存储空间不足，进度可能无法保存"。

## Dependencies

### 上游依赖（本系统依赖的）

无。存档系统是Foundation层，不依赖任何其他游戏系统。

仅依赖平台API：`uni.setStorageSync` / `uni.getStorageSync` / `uni.removeStorageSync`

### 下游依赖（依赖本系统的）

| 系统 | 依赖类型 | 接口 |
|------|---------|------|
| 资源管理系统 | Hard | `loadRunState()`, `saveRunState(data)` |
| 职业轮回系统 | Hard | `loadProfile()`, `saveProfile(data)` |
| 永久进度系统 | Hard | `loadProfile()`, `saveProfile(data)` |
| 被动技能系统 | Hard | `loadProfile()`, `saveProfile(data)` |
| 局管理器 | Hard | `clearRunState()`, `hasActiveRun()` |
| 日周期系统 | Soft | `saveRunState(data)` (每天结束时保存) |

### 公共接口定义

```typescript
interface SaveService {
  loadProfile(): Profile
  saveProfile(data: Profile): void
  loadRunState(): RunState | null
  saveRunState(data: RunState): void
  clearRunState(): void
  hasActiveRun(): boolean
  getDataVersion(): number
}
```

## Tuning Knobs

| 调参项 | 默认值 | 安全范围 | 过高风险 | 过低风险 |
|--------|--------|---------|---------|---------|
| `SAVE_DEBOUNCE_MS` | 0 (立即) | 0-1000ms | 延迟过高→退出时来不及保存 | 无风险（0=最安全） |
| `MAX_BACKUP_COUNT` | 1 | 1-3 | 存储空间占用翻倍 | 1个备份已够用 |
| `DATA_VERSION` | 1 | 递增整数 | — | — |
| `MIGRATION_TIMEOUT_MS` | 3000 | 1000-10000 | 用户等待过久 | 大数据迁移超时 |

存档系统的调参项很少——这是对的。它应该"设好就不用管"，不是经常调的系统。

## Acceptance Criteria

- **GIVEN** 首次进入游戏, **WHEN** 无任何本地存储数据, **THEN** 系统初始化默认 profile 并写入 Storage，状态变为 `HAS_PROFILE`。

- **GIVEN** 一局进行中（已做出3次选择）, **WHEN** 强杀小程序并重新打开, **THEN** `hasActiveRun()` 返回 true，`loadRunState()` 返回包含3次选择后状态的数据。

- **GIVEN** 一局进行中, **WHEN** 玩家做出选择, **THEN** `runState` 在选择确认后500ms内写入 Storage。

- **GIVEN** 主key数据被人为破坏（`_valid` = false）, **WHEN** 下次读取, **THEN** 系统回退到 `_backup` 数据，游戏正常继续，玩家无感知。

- **GIVEN** 主key和backup都被破坏, **WHEN** 下次读取, **THEN** profile 重置为初始状态，`runState` 清除，界面正常加载（不崩溃）。

- **GIVEN** 存档版本为 v1, **WHEN** 代码升级到 v2, **THEN** 迁移函数自动执行，数据结构更新为 v2 格式，原有数据值保留。

- **GIVEN** Storage 写入失败, **WHEN** 触发保存, **THEN** 游戏不崩溃，发出 `saveError` 事件，内存状态不丢失。

- **GIVEN** 一局通关结算完成, **WHEN** 局管理器调用 `clearRunState()`, **THEN** `hasActiveRun()` 返回 false，`loadRunState()` 返回 null。
