# ADR-007: 对话系统架构

## Status

Accepted

## Date

2026-05-14

## Last Verified

2026-05-14

## Decision Makers

Gameplay Programmer, Architecture

## Summary

游戏需要一个通用的对话系统来支持 NPC 对话和奇遇交互。决定采用节点式对话树架构（DialogueManager + DialogueData + DialogueBox），使用 JSON 定义对话内容，通过 effects 系统在对话中自动执行游戏逻辑。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI |
| **Knowledge Risk** | LOW — 纯 GDScript 逻辑 + 标准 Control 节点 |
| **References Consulted** | 无需引擎特定参考 |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (核心架构) |
| **Enables** | ADR-006 (奇遇系统), NPC 对话扩展, 任务系统对话 |
| **Blocks** | None |
| **Ordering Note** | DialogueManager 必须在 EncounterDataLoader 之前初始化 |

## Context

### Problem Statement

修真武侠 RPG 需要对话系统支持多种场景：NPC 交谈、奇遇事件交互、任务触发、商店对话等。对话内容需要数据驱动以方便扩展，且对话过程中需要触发游戏效果（给予物品、改变属性、触发任务等）。

### Current State

DialogueManager (Autoload) 已实现，统一管理对话树的加载、推进和效果执行。DialogueBox (UI) 已挂载在主游戏场景中，自动响应 DialogueManager 的信号。

### Constraints

- 对话数据必须为 JSON 格式，便于策划编辑
- 对话 UI 必须支持多选项分支
- 效果系统需可扩展以支持新的 effect 类型

### Requirements

- 支持线性对话和分支对话
- 对话中可触发游戏效果（奖励、消耗、状态变化）
- 支持运行时动态加载对话树（用于奇遇系统）
- 对话 UI 响应键盘/手柄操作

## Decision

采用三层架构：DialogueManager (逻辑) + DialogueData (数据) + DialogueBox (UI)。

### Architecture

```
JSON 对话文件 (.json)
    |
    v
DialogueManager (Autoload)
    |-- load_dialogue(path) / load_dialogue_from_dict(data)
    |-- _dialogue_trees{id: DialogueTree}
    |-- start_dialogue(id) → 推进节点
    |-- select_choice(index) → 分支跳转
    |
    |-- signals: node_displayed, dialogue_ended
    |
    v
DialogueData (数据解析)                DialogueBox (UI)
    |-- _parse_dialogue_tree()              |-- _on_node_displayed()
    |-- _parse_node()                       |-- 显示文本 + 选项按钮
    |-- _parse_effect()                     |-- _on_choice_selected()
    |-- Effect.execute()                    |-- 键盘: Space/Enter/ESC
    |
    v
游戏系统 (通过 Autoload 访问)
    |-- CharacterSystem: 属性/经验
    |-- InventorySystem: 物品
    |-- CurrencyManager: 银两
    |-- QuestManager: 任务
    |-- MartialArtsSystem: 武学
```

### Key Interfaces

```gdscript
## DialogueManager (Autoload)
func load_dialogue(file_path: String) -> bool
func load_dialogue_from_dict(data: Dictionary) -> bool
func has_dialogue(dialogue_id: String) -> bool
func start_dialogue(dialogue_id: String) -> void
func select_choice(choice_index: int) -> void
func end_dialogue() -> void

signal node_displayed(node_data: Dictionary)
signal dialogue_ended(dialogue_id: String)

## DialogueData — Effect 类型
# item_give: 给予物品
# item_cost: 消耗物品
# skill_give: 给予武学
# dao_heart_change: 道心倾向变化
# quest_trigger: 触发任务
# reputation_change: 声望变化
# time_cost / time_advance: 时间消耗
# map_mark: 地图标记
# shop_open: 打开商店
```

### Implementation Guidelines

1. **对话树结构**: 每个 JSON 文件包含 `id`, `title`, `nodes` 字段。`nodes` 是节点数组，每个节点有 `id`, `speaker`, `text`, `choices` 字段
2. **选项分支**: 每个 choice 有 `text`, `next_node`, `effects` 字段。选择后跳转到指定节点并执行 effects
3. **效果执行**: `_parse_effect()` 将 effect 字典转为 Effect 对象，对话推进时自动调用 `execute()`
4. **运行时注册**: `load_dialogue_from_dict()` 允许 EncounterDataLoader 在运行时注册奇遇对话树
5. **角色名映射**: DialogueBox 维护 speaker ID → 中文名的映射表（云中鹤、铁无双、柳如烟等）

## Alternatives Considered

### Alternative 1: 可视化对话编辑器 (如 Dialogic)

- **Description**: 使用 Godot 插件 Dialogic 构建对话系统
- **Pros**: 可视化编辑，策划友好
- **Cons**: 引入外部依赖，定制 effects 系统困难，与奇遇 JSON 格式不兼容
- **Rejection Reason**: 项目已有大量 JSON 对话数据，自建系统更灵活且无依赖风险

### Alternative 2: 纯代码对话

- **Description**: 对话内容直接写在 GDScript 中
- **Pros**: 无需解析，直接执行
- **Cons**: 内容修改需改代码，无法数据驱动，策划无法独立工作
- **Rejection Reason**: 违反数据驱动原则

## Consequences

### Positive

- 对话内容完全数据驱动，策划可独立编辑 JSON
- effects 系统可扩展，新增效果类型只需添加解析分支
- DialogueManager 作为统一入口，NPC 对话和奇遇共享同一套基础设施

### Negative

- JSON 编辑缺乏可视化，复杂分支对话的编辑体验不如专用工具
- Effect 类型需要手动添加解析代码

### Neutral

- DialogueBox UI 采用固定布局（4个选项按钮），大量选项需分页

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| JSON 格式错误导致对话无法加载 | MEDIUM | LOW | load 时 push_warning，不影响其他对话 |
| Effect 执行失败（目标系统不存在） | LOW | LOW | get_node_or_null 保护，失败静默跳过 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Memory | +0 | +~300KB (全部对话树) | 8GB |
| CPU per dialogue step | +0 | <1ms | 16.6ms |

## Validation Criteria

- [x] DialogueManager 可加载 JSON 文件和字典数据
- [x] DialogueBox 正确显示文本、选项、角色名
- [x] Effects 在选择后自动执行
- [x] 奇遇系统通过 load_dialogue_from_dict() 注册30个对话树

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/dialogue-system.md` | 对话 | 支持分支对话和选项 | nodes→choices→next_node 的对话树结构 |
| `design/gdd/dialogue-system.md` | 对话 | 对话可触发游戏效果 | effects 系统自动执行 item_give/quest_trigger 等 |
| `design/gdd/encounter-system.md` | 奇遇 | 奇遇交互复用对话系统 | load_dialogue_from_dict() 支持运行时注册 |

## Related

- ADR-006: 奇遇系统架构（复用 DialogueManager 的主要消费者）
- `src/scripts/dialogue/dialogue_manager.gd` — 对话管理器
- `src/scripts/dialogue/dialogue_data.gd` — 数据解析和效果定义
- `src/scripts/ui/dialogue_box_script.gd` — 对话 UI
