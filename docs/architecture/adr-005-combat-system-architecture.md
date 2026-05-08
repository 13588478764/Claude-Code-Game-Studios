# ADR-005: 战斗系统架构

## Status
Proposed

## Date
2026-05-04

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Gameplay Systems |
| **Knowledge Risk** | HIGH — Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — relies on stable Godot 4 core APIs (Node, signals, enums, typed arrays) |
| **Verification Required** | 1) 验证 CombatAttributes Resource 替代 meta 后类型安全性；2) 批次信号（unit_hp_changed 每行动一次）性能优于逐次信号；3) 验证 Manager 初始化树序正确性 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (Core Architecture — node system, signal patterns, dependency injection), ADR-002 (HUD Architecture — signal-driven UI + dirty flag), ADR-004 (Performance Optimization — object pooling, batch updates) |
| **Enables** | 战斗 UI 集成（HUD 监听战斗信号）、Encounter/Quest 系统集成（监听 combat_ended）、角色成长系统（读取属性数据用于战斗计算） |
| **Blocks** | None currently |
| **Ordering Note** | Combat system ADR builds on foundational patterns from ADR-001/002/004 |

## Context

### Problem Statement
战斗系统包含 17 个代码文件，涵盖回合制战斗流程、伤害计算、内力管理、架势系统、弱点打击、连携系统等核心玩法机制。在开发过程中缺乏统一的架构文档来记录设计决策、接口契约和替代方案评估，导致后续开发难以追溯设计意图，新系统接入缺乏明确规范。

### Constraints
- Godot 4.6 引擎，GDScript 语言
- 目标平台 Web/浏览器，内存上限 2GB
- 遵循 ADR-001 核心架构规范（节点系统、信号通信、依赖注入）
- GDD 定义了复杂的战斗公式和多资源交互机制

### Requirements
- 必须支持回合制战斗流程（遭遇→输入→执行→敌方→结束）
- 必须实现四大核心资源：内力(Qi)、架势(Poise)、连击(Combo)、连携(Link)
- 必须支持弱点打击系统（五行相克）
- 必须支持多伤害类型（物理/内功/真实伤害）
- 所有战斗数值必须从外部配置加载，禁止硬编码
- 战斗 UI 必须通过信号驱动更新，业务逻辑与 UI 分离

## Decision

采用 **Manager 分层架构模式（Manager Layered Architecture Pattern）**，以 `CombatSystem` 为顶层控制器，通过多个专职 Manager 类分管不同战斗子系统，使用信号驱动通信和依赖注入模式解耦。

### 架构设计

战斗系统分为三个层次：

**第一层：顶层控制器**
- `CombatSystem` — 战斗系统顶层控制器，管理战斗阶段(CombatPhase)、战斗状态(CombatState)、参与者(CombatParticipant)和资源(CombatResource)
- `CombatManager` — 战斗流程管理器，负责回合流转、行动队列、单位管理和战斗日志

**第二层：专职 Manager**
- `DamageCalculator` — 伤害计算器，处理基础伤害计算（物理/内功/真实伤害）
- `HealthPoiseManager` — 生命值与架势管理器，管理 HP/Poise 的消耗、恢复和破防/死亡状态
- `QiManager` — 内力管理器，实现内力池、恢复、消耗和过载机制
- `DamageMultiplierManager` — 伤害倍率管理器，计算暴击/连击/弱点/状态等多重乘区
- `EnemyBehaviorManager` — 敌方行为管理器，处理 AI 决策和行为
- `DefenseMitigationManager` — 防御减伤管理器，计算防御相关的伤害减免
- `HitDetectionManager` — 命中检测管理器，处理命中/闪避/格挡判定
- `WeaknessSystem` — 弱点系统，实现五行相克和弱点打击
- `LinkSystem` — 连携系统，处理队友间连携攻击和合体技
- `MartialArtsSystem` — 武学系统，管理武学技能和熟练度
- `MartialArtsComboSystem` — 武学连招系统，处理连段机制
- `RecoveryStatusManager` — 恢复状态管理器，处理持续恢复和状态效果
- `DamageVisualizationManager` — 伤害可视化管理器，处理伤害数字和特效

**第三层：辅助系统**
- `AIDecisionManager` — AI 决策管理器，处理 AI 决策树
- `AIDifficultyManager` — AI 难度管理器，根据难度调整 AI 行为

### 架构通信模式

```
[CombatManager] (顶层流程)
      │
      ├── 依赖注入 ──► [DamageCalculator]
      │                      │
      ├── 信号转发 ──► [GameEvents] (全局信号总线)
      │
      └── 组合使用 ──► [HealthPoiseManager]
                       [QiManager]
                       [DamageMultiplierManager]
                       [EnemyBehaviorManager]
                       ... (其他 Manager)
```

**通信规则**：
1. Manager 之间通过信号通信，禁止直接状态修改
2. `CombatManager` 作为局部信号源，转发到 `GameEvents` 全局总线
3. UI 层只监听信号，不直接调用 Manager 方法
4. 依赖通过 `_initialize_dependencies()` 注入，但 `DamageCalculator` 和 `GameEvents` 目前采用**服务定位器模式**（`get_node("/root/...")`），因它们可能作为 Autoload 注册。这是 ADR-001 "避免 Autoload 单例"的合理例外。
5. 禁止 Manager 在 `_ready()` 中创建其他 Manager 的实例（如 `add_child(DamageCalculator.new())`）

### 关键接口

**CombatManager 信号**：
- `battle_started()` — 战斗开始
- `battle_ended(result: Dictionary)` — 战斗结束
- `turn_started(unit: BattleUnit)` — 回合开始
- `turn_ended(unit: BattleUnit)` — 回合结束
- `action_executed(action_result: Dictionary)` — 行动执行
- `unit_hp_changed(unit_id: StringName, new_hp: int, max_hp: int, delta: int)` — 单位 HP 变化（批次信号，每次行动结束后发射一次，而非每次 HP 变化都发射）
- `unit_resource_changed(unit_id: StringName, resource_type: StringName, new_value: int, delta: int)` — 资源变化（批次信号）
- **信号粒度规则**：HP/资源信号在每次行动结算后发射一次（批量最终值），禁止在中间计算过程中频繁发射。UI 使用脏标志模式避免冗余更新。

**CombatSystem 信号**：
- `combat_started()` — 战斗系统启动
- `combat_ended()` — 战斗系统结束
- `phase_changed(new_phase: CombatPhase)` — 阶段变化
- `turn_order_generated(order: Array)` — 行动队列生成
- `participant_state_changed(participant, new_state)` — 参与者状态变化
- `resources_changed(participant)` — 资源变化

**DamageCalculator 接口**：
- `calculate_base_damage(attacker_attrs: CombatAttributes, defender_attrs: CombatAttributes, damage_type: int) -> int`
- `DamageType` 枚举: `PHYSICAL`, `ENERGY`, `TRUE_DAMAGE`
- **重要**：使用 `CombatAttributes` Resource 传递攻防属性，禁止使用 `set_meta/get_meta`（类型不安全，性能开销高）

**CombatAttributes Resource**（新数据结构 — 待实现）：
```gdscript
class_name CombatAttributes extends Resource
@export var strength: int = 10
@export var constitution: int = 10
@export var wisdom: int = 10
@export var weapon_attack: int = 0
@export var armor: int = 0
@export var qi_power: int = 0
@export var qi_resistance: int = 0
```

**核心数据结构**：
- `BattleUnit` (CombatManager 内部类) — 战斗单位，包含 HP、内力、架势、连击、连携、属性。用于战斗流程管理。
- `CombatParticipant` (CombatSystem 内部类) — 战斗参与者，包含名称、身法、状态、资源。用于战斗阶段和回合排序管理。
- `CombatResource` (CombatSystem 内部类) — 战斗资源，管理 Qi/Poise/Combo/Link。
- **注意**：`BattleUnit` 和 `CombatParticipant` 目前为内部类，如需跨文件引用应提取为独立 `.gd` 文件（`battle_unit.gd`、`combat_participant.gd`）

**数据结构职责边界**：

| 字段 | BattleUnit | CombatParticipant | 职责说明 |
|------|:----------:|:-----------------:|----------|
| HP | ✓ | - | BattleUnit 管理 HP 变化 |
| 内力/架势/连击/连携 | ✓ | ✓（通过 CombatResource）| CombatSystem 的资源副本用于回合恢复计算；BattleUnit 的资源用于战斗流程 |
| 身法(AGI) | - | ✓ | CombatParticipant 专有，用于行动队列排序 |
| 属性(STR/CON/WIS) | ✓ | - | BattleUnit 专有，用于伤害计算 |
| 战斗状态(Down/Break/Stun) | - | ✓ | CombatParticipant 专有，CombatSystem 管理 |

**信号映射表**（CombatManager → GameEvents 参数转换）：

| CombatManager 信号 | GameEvents 信号 | 参数转换规则 |
|--------------------|-----------------|-------------|
| `battle_started()` | `combat_started()` | 无参数，直接转发 |
| `battle_ended(result)` | `combat_ended(victory: bool, result: Dictionary)` | 提取 `result.victory` |
| `turn_started(unit)` | `combat_turn_changed(turn: int)` | 递增 `_turn_counter`，不传递 unit 对象 |
| `unit_hp_changed(unit, old_hp, new_hp)` | 待定义 | 提取 unit 标识符，传递 new_hp/max_hp |
| `unit_resource_changed(...)` | 待定义 | 提取资源类型和最终值 |

**注意**：GameEvents 中已存在的 `player_hp_changed(current: int, max_value: int)` 信号与 CombatManager 的 `unit_hp_changed` 签名不一致，需在集成时统一。

### 配置管理

所有战斗数值通过 `data/combat_config.json` 外部配置加载，包含：
- `resource_recovery` — 资源回复配置
- `combat_action_values` — 战斗行动数值
- `damage_formulas` — 伤害公式参数
- `resource_defaults` — 资源上限默认值

## Alternatives Considered

### Alternative 1: ECS 组件架构 (Entity Component System)
- **Description**: 将战斗实体拆分为独立的组件（HealthComponent, QiComponent, PoiseComponent 等），通过系统处理组件交互
- **Pros**: 数据驱动、易于批量处理、性能潜力高、组合灵活
- **Cons**: Godot 4.6 GDScript 对 ECS 支持有限、开发复杂度高、学习曲线陡峭、不利于快速迭代战斗逻辑
- **Rejection Reason**: 项目规模（17 个文件、单机 RPG）不需要 ECS 的性能优势；团队对 Godot 节点模式更熟悉；GDD 中复杂的状态交互用 Manager 模式更容易实现

### Alternative 2: 状态机驱动架构 (State Machine Driven)
- **Description**: 以有限状态机为核心，每个战斗实体有明确的状态转换图，所有行为由状态转换触发
- **Pros**: 状态流转清晰、易于调试、适合回合制流程
- **Cons**: 多资源交互（Qi+Poise+Combo+Link 同时影响伤害）会导致状态爆炸；难以处理并发的资源变化事件
- **Rejection Reason**: 战斗系统有四个独立资源系统同时运作，纯状态机会产生 N×M 状态组合，维护成本远高于 Manager 模式。状态机适合作为单个 Manager 内部的实现细节（如 CombatState 管理），但不适合作为整体架构

## Consequences

### Positive
- ✅ 职责清晰：每个 Manager 只关注一个子系统
- ✅ 易于测试：Manager 可独立单元测试（如 DamageCalculator 纯计算逻辑）
- ✅ 易于扩展：新增战斗机制只需添加新的 Manager，不修改现有代码
- ✅ 信号解耦：Manager 间无直接依赖，通过信号通信
- ✅ 配置驱动：战斗数值外部化，策划可调优无需改代码
- ✅ 符合 ADR-001 规范：节点系统、信号通信、依赖注入

### Negative
- ⚠️ Manager 数量较多（17 个文件），新成员需要时间理解全貌
- ⚠️ 信号调试不如直接调用直观，需要良好的日志系统
- ⚠️ BattleUnit 与 CombatParticipant 两套数据结构存在冗余风险
- ⚠️ 三层层级信号链（CombatManager → GameEvents → UI）增加调试复杂度

### Risks
- **风险 1**: 两个顶层控制器（CombatSystem 和 CombatManager）职责边界可能模糊
  - **缓解**: 在代码注释和 ADR 中明确分工 — CombatSystem 管理参与者/资源/阶段，CombatManager 管理回合流程/行动队列/战斗日志
- **风险 2**: 信号链路过长可能导致性能问题
  - **缓解**: 遵循 ADR-004 的批处理更新策略，UI 层使用脏标志模式减少更新频率；信号按行动批次发射（非逐次发射）
- **风险 3**: DamageCalculator 当前仍使用 `set_meta/get_meta` 传递属性（代码未迁移到 CombatAttributes Resource），类型安全性弱
  - **待实现**: 创建 `CombatAttributes` Resource 类并替换 meta 模式。预计完成时间：下一个 Sprint
- **风险 4**: 17 个 Manager 同时启用 `_process()` 会导致帧时间开销
  - **缓解**: 不需要逐帧更新的 Manager 必须在 `_ready()` 中调用 `set_process(false)` 和 `set_physics_process(false)`
- **风险 5**: 依赖注入初始化顺序错误导致 Manager 获取空引用
  - **缓解**: 初始化顺序：CombatSystem → CombatManager → DamageCalculator → 其他 Manager。每个 Manager 在 `_initialize_dependencies()` 中获取依赖，父节点优先于子节点初始化（Godot 树序保证）
- **风险 6**: UI 直接监听 GameEvents 导致信号来源难以追踪
  - **缓解**: 战斗 UI 优先直接连接 CombatManager 信号（同场景树内）；GameEvents 仅用于跨场景/全局通信。在代码注释中标注信号来源

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| combat-system.md | 回合制战斗流程（遭遇→输入→执行→敌方→结束） | CombatManager.set_phase() + CombatSystem.set_phase() 实现阶段管理 |
| combat-system.md | 行动顺序 = 身法 × 随机修正 | CombatSystem.generate_turn_order() 按 AGI 排序，可加入随机因子 |
| combat-system.md | 内力 Qi 系统（恢复/消耗/过载） | QiManager 实现内力池、自然恢复、行动恢复、过载转换 |
| combat-system.md | 架势 Poise 系统（归零破防） | HealthPoiseManager + CombatResource 管理架势，is_broken() 检测 |
| combat-system.md | 连击 Combo 系统（最高+30%伤害） | CombatResource.combo_count + DamageMultiplierManager 计算倍率 |
| combat-system.md | 连携 Link 系统（队友配合） | LinkSystem 管理连携槽积累和触发 |
| combat-system.md | 五行相克弱点打击 | WeaknessSystem 实现金木水火土克制关系 |
| combat-system.md | 伤害公式 = 基础 × 暴击 × 连击 × 弱点 × 破防 × 状态 × 随机 | DamageCalculator + DamageMultiplierManager 分层计算 |
| combat-system.md | 外部配置调优 | combat_config.json 加载所有可调参数 |
| health-defense-system.md | HP/破防/死亡状态 | HealthPoiseManager 管理状态转换 |

## Performance Implications
- **CPU**: 信号通信比直接调用有轻微开销（可忽略）；17 个 Manager 在战斗场景中同时存在，初始化成本需关注
- **Memory**: 每个 Manager 作为独立 Node 存在，内存占用低（< 1MB 总计）；对象池用于频繁创建的特效/伤害数字
- **Load Time**: 战斗场景加载需实例化所有 Manager，可通过延迟加载优化
- **Network**: 不适用（单机游戏）

## Migration Plan
当前战斗系统已按此架构实现，无需迁移。本 ADR 为现有实现提供文档化记录。

后续优化方向（TD Review 清单）：
1. [ ] 创建 `CombatAttributes` Resource 类并替换 meta 传递模式（Engine Specialist 建议 — BLOCKING）
2. [ ] 统一 BattleUnit 和 CombatParticipant 数据结构，提取为独立 `battle_participant.gd`（TD 建议）
3. [ ] 修改 `unit_hp_changed` 和 `unit_resource_changed` 信号为批次信号（每行动结束后发射一次）
4. [ ] 增加战斗系统集成测试覆盖
5. [ ] 确保所有非逐帧 Manager 在 `_ready()` 中禁用 `set_process(false)`
6. [ ] 统一 GameEvents 信号签名：`player_hp_changed` 与 `unit_hp_changed` 参数对齐（ADR-002 集成）
7. [ ] 定义跨系统集成接口：角色成长系统 → 战斗属性读取，战斗 → 经济奖励输出

## Validation Criteria
1. 所有 17 个战斗 Manager 文件存在且遵循命名规范
2. CombatManager 不直接修改 UI，所有状态变化通过信号发射
3. 战斗数值无硬编码，全部从 combat_config.json 加载
4. DamageCalculator 可独立于 CombatManager 进行单元测试
5. 战斗信号通过 GameEvents 全局总线转发
6. 新增战斗机制只需添加新 Manager，无需修改现有 Manager 代码

## Related Decisions
- ADR-001: 核心架构决策（节点系统、信号通信、依赖注入）
- ADR-002: HUD 架构模式（信号驱动 + 脏标志 UI 更新）
- ADR-004: 性能优化策略（对象池、批处理更新）