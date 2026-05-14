# ADR-006: 奇遇事件系统架构

## Status

Accepted

## Date

2026-05-14

## Last Verified

2026-05-14

## Decision Makers

Gameplay Programmer, Architecture

## Summary

奇遇事件系统需要将30个数据驱动的 JSON 奇遇文件接入游戏循环。决定复用 DialogueManager 作为奇遇对话引擎，通过 EncounterDataLoader 加载并注册奇遇数据，避免构建独立的奇遇 UI/交互系统。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — 纯 GDScript 逻辑，无 post-cutoff API 依赖 |
| **References Consulted** | 无需引擎特定参考 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (核心架构), ADR-007 (对话系统架构) |
| **Enables** | 奇遇内容扩展、新奇遇类型添加 |
| **Blocks** | None |
| **Ordering Note** | EncounterDataLoader 必须在 DialogueManager 之后初始化 |

## Context

### Problem Statement

`data/encounters/` 目录下有30个精心设计的奇遇事件 JSON 文件，包含完整的对话树（nodes/choices/effects）、触发条件、道心倾向等数据。这些数据需要一个加载、查询、触发的架构来接入游戏循环。

### Current State

EncounterDataLoader (Autoload) 已实现，负责加载全部30个 JSON 并注册到 DialogueManager。GameLoopManager 通过 EncounterDataLoader 选取奇遇并启动对话。

### Constraints

- 奇遇 JSON 格式必须兼容 DialogueManager 的 nodes→choices→effects 对话树结构
- 奇遇触发概率受角色福缘属性影响
- 一次性奇遇需要持久化触发记录

### Requirements

- 30个奇遇全部可触发、可交互
- 奖励通过对话 effects 自动发放
- 支持按区域/类型过滤可用奇遇
- 冷却和去重机制防止重复触发

## Decision

采用 EncounterDataLoader + DialogueManager 复用架构。

### Architecture

```
data/encounters/*.json
    |
    v
EncounterDataLoader (Autoload)
    |-- _ready(): 递归加载目录下所有 .json
    |-- _encounters[]: 存储元数据 (trigger_conditions, probability, type)
    |-- select_random_encounter(region): 按条件选取
    |-- mark_triggered(id): 标记已触发
    |
    +-- DialogueManager.load_dialogue_from_dict()
            |
            v
        DialogueManager (Autoload)
            |-- 存储对话树
            |-- start_dialogue(encounter_id)
            |
            v
        DialogueBox (UI)
            |-- 显示对话文本和选项
            |-- 选项 → effects 自动执行
```

### Key Interfaces

```gdscript
## EncounterDataLoader
func get_encounter_count() -> int
func select_random_encounter(region_id: String) -> Dictionary
func mark_triggered(encounter_id: String) -> void
func get_encounters_by_type(type: String) -> Array

## 触发入口 (GameLoopManager)
func _check_non_combat_encounter() -> Dictionary:
    # 概率检定 → EncounterDataLoader.select_random_encounter()
    # → DialogueManager.start_dialogue(enc_id)
```

### Implementation Guidelines

1. 奇遇 JSON 的 `nodes` 字段直接作为 DialogueManager 的对话树节点
2. 奖励通过 `effects` 字段的 `item_give`, `skill_give`, `dao_heart_change` 等类型自动处理
3. `trigger_conditions` 字段中的 `min_realm` 等条件暂不过滤（全部可触发）
4. `skill_check` 和 `combat_check` 效果类型暂为 stub（always pass）

## Alternatives Considered

### Alternative 1: 独立奇遇交互系统

- **Description**: 为奇遇事件构建独立的 UI 和交互系统，不复用 DialogueManager
- **Pros**: 可以为奇遇定制更丰富的 UI 表现
- **Cons**: 大量重复工作（对话显示、选项处理、效果执行都需要重新实现）
- **Rejection Reason**: 奇遇 JSON 的格式与对话树几乎相同，复用 DialogueManager 可省去大量重复代码

### Alternative 2: 硬编码奇遇

- **Description**: 在代码中硬编码5种奇遇类型和固定奖励
- **Pros**: 实现简单
- **Cons**: 无法利用30个精心设计的 JSON 数据，内容扩展困难
- **Rejection Reason**: 已有高质量数据资产，不应浪费

## Consequences

### Positive

- 30个奇遇全部接入，内容丰富度大幅提升
- 新增奇遇只需添加 JSON 文件，无需修改代码
- 复用 DialogueManager 减少代码量和维护成本

### Negative

- 奇遇 UI 表现受限于 DialogueBox 的通用对话展示
- `skill_check` 等高级条件暂为 stub，需后续完善

### Neutral

- EncounterDataLoader 作为 Autoload 增加了启动时的加载时间（30个 JSON < 100KB）

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| JSON 格式与 DialogueManager 不兼容 | LOW | HIGH | load_dialogue_from_dict() 已实现兼容转换 |
| 大量奇遇同时加载影响启动 | LOW | LOW | 30个文件总量 < 100KB，可忽略 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Memory | +0 | +~200KB (30个对话树) | 8GB |
| Load Time | +0 | +~50ms (30个 JSON) | 5s |

## Validation Criteria

- [x] 游戏启动日志输出 `[EncounterDataLoader] Loaded 30 encounters`
- [x] 30个 encounter 全部注册到 DialogueManager（无 parse 错误）
- [x] 探索中可触发奇遇对话并获得奖励

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/encounter-system.md` | 奇遇 | 数据驱动的随机奇遇事件 | EncounterDataLoader 加载 JSON 数据，按区域/概率/条件选取 |
| `design/gdd/encounter-system.md` | 奇遇 | 奇遇结果影响角色属性 | 对话 effects 自动执行奖励/惩罚 |

## Related

- ADR-007: 对话系统架构（奇遇系统的对话引擎依赖）
- `src/scripts/encounter/encounter_data_loader.gd` — 数据加载器
- `src/scripts/core/game_loop_manager.gd` — 触发入口
- `src/scripts/dialogue/dialogue_manager.gd` — 对话引擎
