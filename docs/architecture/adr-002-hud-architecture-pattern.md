# ADR-002: HUD架构模式

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI |
| **Knowledge Risk** | MEDIUM — Godot 4.6 dual-focus system (mouse vs keyboard focus) is post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | Dual-focus system (4.6) — mouse/touch focus separate from keyboard/gamepad focus |
| **Verification Required** | Test HUD with both mouse and keyboard/gamepad to ensure focus behavior works correctly in 4.6 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (Core Architecture — signal system for loose coupling) |
| **Enables** | ADR-003 (Data Binding Mechanism — will define GameEvents signal bus structure) |
| **Blocks** | Epic: hud-system — cannot start implementation until architecture is decided |
| **Ordering Note** | Must be Accepted before ADR-003, as data binding depends on this architecture choice |

## Context

### Problem Statement

HUD系统需要实时显示大量游戏状态信息（HP、Qi、Poise、行动队列、连击值、经验等），这些数据来自多个不同的游戏系统（战斗系统、角色成长系统、装备系统等）。我们需要决定：

1. **数据流向**：游戏逻辑层如何将状态变化传递给UI层？
2. **更新时机**：UI何时更新显示？每帧？按需？
3. **耦合度**：HUD与游戏逻辑系统之间的依赖关系如何管理？
4. **性能**：如何确保HUD更新不影响游戏帧率（目标60FPS）？

### Constraints

**技术约束**：
- 必须使用Godot 4.6的Control节点和Theme系统（来自control-manifest.md）
- 必须遵循信号系统用于松耦合（ADR-001）
- 必须避免`$NodePath`在`_process()`中查找（性能）
- 必须使用`@onready`缓存节点引用（Godot 4.6最佳实践）

**性能约束**（来自design/ux/hud.md）：
- HUD draw calls < 100
- 战斗中HUD更新 < 1ms/帧
- 探索中HUD更新 < 0.5ms/帧
- 60FPS稳定
- 内存占用 < 50MB（所有HUD纹理）

**设计约束**：
- 信息分层显示（P0-P4优先级）
- 战斗/探索模式切换
- 支持键盘+鼠标和手柄输入

### Requirements

**必须支持**：
- 实时显示P0级信息（HP、Qi、Poise）— 每帧更新
- 战斗信息（行动队列、连击）— 每0.1秒更新
- 探索信息（任务、地图）— 按需更新
- 模式切换（探索 ↔ 战斗 ↔ 菜单）

**必须集成**：
- 战斗系统（HP、Qi、Poise、行动队列）
- 角色成长系统（等级、经验、境界）
- 装备系统（装备状态）
- 物品系统（快捷栏）

**性能要求**：
- 避免不必要的UI更新（脏标记）
- 批量更新多个变化
- 对象池复用UI元素

## Decision

**采用信号驱动架构 + 脏标记优化**

### 核心架构

```
游戏逻辑层 (src/scripts/)
    ↓ (发出信号)
GameEvents 全局信号总线 (autoload)
    ↓ (监听信号)
HUDManager (src/scenes/ui/hud/)
    ↓ (分发更新)
各UI面板 (PlayerStatusPanel, CombatInfoPanel等)
```

**关键决策**：

1. **全局信号总线模式**
   - 创建`GameEvents`单例（autoload）作为信号中介
   - 所有游戏系统通过`GameEvents`发出状态变化信号
   - HUD组件监听`GameEvents`信号并更新显示
   - 解耦游戏逻辑和UI层

2. **脏标记优化**
   - 每个UI组件维护缓存值
   - 仅当新值与缓存值不同时才更新显示
   - 避免重复绘制相同内容

3. **批量更新机制**
   - 收集同一帧内的多个更新请求
   - 在`_process()`末尾统一应用
   - 减少draw call

4. **分层更新频率**
   - P0级（HP/Qi/Poise）：信号驱动，立即更新
   - P1级（行动队列、连击）：信号驱动，立即更新
   - P2-P4级（任务、地图）：信号驱动，按需更新
   - 不使用轮询（`_process()`中查询状态）

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    GameEvents (Autoload)                 │
│  ┌────────────────────────────────────────────────────┐ │
│  │ Signals:                                           │ │
│  │  - player_hp_changed(current, max)                 │ │
│  │  - player_qi_changed(current, max)                 │ │
│  │  - player_poise_changed(current, max)              │ │
│  │  - combat_started()                                │ │
│  │  - combat_ended()                                  │ │
│  │  - turn_changed(turn_number)                       │ │
│  │  - combo_changed(count, multiplier)                │ │
│  │  - enemy_selected(enemy_data)                      │ │
│  │  - level_up(new_level)                             │ │
│  │  - exp_changed(current, to_next)                   │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
                          ↑ emit                ↓ connect
┌──────────────────┐                  ┌──────────────────────┐
│  Game Systems    │                  │   HUDManager         │
│  - CombatSystem  │                  │   (CanvasLayer)      │
│  - PlayerData    │                  │  ┌────────────────┐  │
│  - EquipmentSys  │                  │  │ Mode: COMBAT   │  │
│  - QuestSystem   │                  │  │ Mode: EXPLORE  │  │
└──────────────────┘                  │  └────────────────┘  │
                                      │  ┌────────────────┐  │
                                      │  │ UI Panels:     │  │
                                      │  │ - PlayerStatus │  │
                                      │  │ - CombatInfo   │  │
                                      │  │ - Navigation   │  │
                                      │  │ - Hotbar       │  │
                                      │  └────────────────┘  │
                                      └──────────────────────┘
```

### Key Interfaces

**GameEvents.gd** (全局信号总线):
```gdscript
extends Node
class_name GameEvents

# 角色状态信号
signal player_hp_changed(current: int, max_value: int)
signal player_qi_changed(current: int, max_value: int)
signal player_poise_changed(current: int, max_value: int)
signal player_level_up(new_level: int)
signal player_exp_changed(current: int, to_next: int)

# 战斗状态信号
signal combat_started()
signal combat_ended()
signal turn_changed(turn_number: int)
signal combo_changed(count: int, multiplier: float)
signal link_gauge_changed(value: int, max_value: int)
signal enemy_selected(enemy: EnemyData)

# 任务信号
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String)
```

**HUDManager.gd** (主控制器):
```gdscript
extends CanvasLayer
class_name HUDManager

enum HUDMode { EXPLORATION, COMBAT, MENU }

@onready var player_status: PlayerStatusPanel = $PlayerStatusPanel
@onready var combat_info: CombatInfoPanel = $CombatInfoPanel
@onready var navigation: NavigationPanel = $NavigationPanel
@onready var hotbar: HotbarController = $HotbarController

var current_mode: HUDMode = HUDMode.EXPLORATION

func _ready() -> void:
    _connect_signals()
    set_mode(HUDMode.EXPLORATION)

func _connect_signals() -> void:
    # 角色状态
    GameEvents.player_hp_changed.connect(_on_hp_changed)
    GameEvents.player_qi_changed.connect(_on_qi_changed)
    GameEvents.player_poise_changed.connect(_on_poise_changed)
    
    # 战斗状态
    GameEvents.combat_started.connect(_on_combat_started)
    GameEvents.combat_ended.connect(_on_combat_ended)
    GameEvents.combo_changed.connect(_on_combo_changed)

func set_mode(mode: HUDMode) -> void:
    current_mode = mode
    match mode:
        HUDMode.EXPLORATION:
            combat_info.hide()
            navigation.show()
        HUDMode.COMBAT:
            combat_info.show()
            navigation.auto_collapse()
        HUDMode.MENU:
            # 保持当前显示，添加菜单覆盖层
            pass

func _on_hp_changed(current: int, max_value: int) -> void:
    player_status.update_hp(current, max_value)

func _on_combat_started() -> void:
    set_mode(HUDMode.COMBAT)
```

**PlayerStatusPanel.gd** (带脏标记的UI组件):
```gdscript
extends PanelContainer
class_name PlayerStatusPanel

@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var hp_label: Label = $VBox/HPBar/Label

# 脏标记和缓存
var _cached_hp: int = 0
var _cached_hp_max: int = 1
var _hp_dirty: bool = false

func update_hp(current: int, max_value: int) -> void:
    if _cached_hp != current or _cached_hp_max != max_value:
        _cached_hp = current
        _cached_hp_max = max_value
        _hp_dirty = true

func _process(_delta: float) -> void:
    if _hp_dirty:
        _apply_hp_update()
        _hp_dirty = false

func _apply_hp_update() -> void:
    hp_bar.max_value = _cached_hp_max
    hp_bar.value = _cached_hp
    hp_label.text = "%d / %d" % [_cached_hp, _cached_hp_max]
    
    # 临界状态颜色
    var percentage := float(_cached_hp) / _cached_hp_max
    if percentage < 0.3:
        hp_bar.modulate = Color.RED
    elif percentage < 0.6:
        hp_bar.modulate = Color.YELLOW
    else:
        hp_bar.modulate = Color.GREEN
```

## Alternatives Considered

### Alternative 1: 轮询架构

**描述**：
- HUD在`_process()`中主动查询游戏状态
- 每帧检查所有需要显示的数据
- 发现变化时更新UI

**实现示例**：
```gdscript
func _process(_delta: float) -> void:
    var player = get_node("/root/PlayerData")
    if player.hp != _cached_hp:
        _update_hp_display(player.hp, player.hp_max)
```

**优点**：
- 实现简单，不需要信号系统
- UI组件完全自主，不依赖外部通知
- 容易理解和调试

**缺点**：
- 性能差：每帧查询所有状态，即使没有变化
- 紧耦合：HUD直接依赖游戏逻辑节点路径
- 难以维护：节点路径硬编码，重构困难
- 违反ADR-001：不使用信号系统进行松耦合

**拒绝原因**：
违反已确立的架构原则（ADR-001），性能不符合要求（每帧查询开销大），且与Godot最佳实践不符。

### Alternative 2: 直接引用架构

**描述**：
- 游戏系统直接持有HUD组件的引用
- 状态变化时直接调用HUD的更新方法
- 不使用信号，直接方法调用

**实现示例**：
```gdscript
# 在CombatSystem中
func take_damage(amount: int) -> void:
    player.hp -= amount
    hud_manager.player_status.update_hp(player.hp, player.hp_max)
```

**优点**：
- 性能最优：直接方法调用，无信号开销
- 实时性好：状态变化立即反映到UI
- 代码路径清晰：直接看到调用链

**缺点**：
- 强耦合：游戏逻辑依赖UI层
- 难以测试：无法独立测试游戏逻辑
- 违反单一职责：游戏系统需要知道UI细节
- 违反ADR-001：不使用信号系统

**拒绝原因**：
严重违反架构分层原则，游戏逻辑不应依赖UI层。测试困难，维护性差。

### Alternative 3: 观察者模式（自定义）

**描述**：
- 实现自定义的观察者模式
- HUD组件注册为游戏状态的观察者
- 状态变化时通知所有观察者

**实现示例**：
```gdscript
class_name Observable:
    var observers: Array[Callable] = []
    
    func add_observer(callback: Callable) -> void:
        observers.append(callback)
    
    func notify(value: Variant) -> void:
        for observer in observers:
            observer.call(value)
```

**优点**：
- 解耦：游戏逻辑不知道具体观察者
- 灵活：可以动态添加/移除观察者
- 类型安全：可以使用强类型回调

**缺点**：
- 重复造轮子：Godot已有信号系统
- 维护成本：需要自己管理观察者生命周期
- 学习成本：团队需要学习自定义模式
- 不符合Godot惯例：违背引擎设计哲学

**拒绝原因**：
Godot的信号系统已经是成熟的观察者模式实现，无需自己实现。使用引擎内置功能更符合最佳实践。

## Consequences

### Positive

1. **松耦合**：游戏逻辑和UI完全解耦，可以独立开发和测试
2. **可维护性**：信号接口清晰，修改一方不影响另一方
3. **可测试性**：可以mock GameEvents来测试HUD，可以独立测试游戏逻辑
4. **符合Godot惯例**：使用引擎推荐的信号系统
5. **性能可控**：脏标记避免不必要的更新，批量更新减少draw call
6. **易于扩展**：新增UI组件只需监听相应信号

### Negative

1. **信号开销**：信号连接和发射有轻微性能开销（但可忽略）
2. **间接性**：数据流经过GameEvents中介，调试时需要追踪信号链
3. **学习曲线**：新开发者需要理解信号系统和脏标记模式
4. **内存占用**：GameEvents单例常驻内存（但开销很小）

### Risks

**风险1：信号连接泄漏**
- **描述**：UI组件销毁时未断开信号连接，导致内存泄漏
- **缓解**：
  - 使用Godot的自动断开机制（节点销毁时自动断开）
  - 在`_exit_tree()`中显式断开关键信号
  - 代码审查检查信号连接/断开配对

**风险2：信号风暴**
- **描述**：短时间内大量信号发射，导致性能下降
- **缓解**：
  - 使用脏标记，避免重复发射相同值的信号
  - 批量更新机制，合并同一帧的多个变化
  - 性能测试验证信号频率

**风险3：信号顺序依赖**
- **描述**：多个信号的处理顺序影响结果
- **缓解**：
  - 设计无状态的信号处理函数
  - 避免信号处理函数之间的依赖
  - 文档明确说明信号处理的独立性要求

**风险4：Godot 4.6双焦点系统兼容性**
- **描述**：4.6的鼠标/键盘分离焦点可能影响HUD交互
- **缓解**：
  - 测试HUD在鼠标和键盘/手柄下的行为
  - 确保两种输入方式都能正确触发信号
  - 参考`docs/engine-reference/godot/modules/ui.md`的最佳实践

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| design/ux/hud.md | 性能预算：HUD更新 < 1ms/帧（战斗），< 0.5ms/帧（探索） | 信号驱动 + 脏标记避免不必要更新，批量更新减少开销 |
| design/ux/hud.md | 信息分层显示（P0-P4优先级） | 不同优先级信息使用不同信号，HUD可选择性监听 |
| design/ux/hud.md | 战斗/探索模式切换 | HUDManager统一管理模式，通过信号响应模式变化 |
| design/ux/hud.md | 松耦合架构，易于维护 | GameEvents中介解耦游戏逻辑和UI层 |
| control-manifest.md | 使用信号系统进行松耦合 | 核心架构基于Godot信号系统 |
| control-manifest.md | 避免`$NodePath`在`_process()`中 | 使用`@onready`缓存引用，信号驱动更新 |

## Performance Implications

**CPU**：
- 信号发射开销：~0.01ms/信号（可忽略）
- 脏标记检查：~0.001ms/组件（极小）
- 预期总开销：< 0.5ms/帧（符合预算）

**Memory**：
- GameEvents单例：~1KB（常驻）
- 信号连接：~100字节/连接 × 约50个连接 = ~5KB
- 缓存值：~10字节/值 × 约30个值 = ~300字节
- 预期总开销：< 10KB（可忽略）

**Load Time**：
- 无影响（信号连接在运行时建立）

**Network**：
- 不适用（单机游戏）

## Migration Plan

**阶段1：创建GameEvents单例**（Story 001）
1. 创建`src/scripts/core/game_events.gd`
2. 定义所有HUD相关信号
3. 在`project.godot`中注册为autoload

**阶段2：实现HUDManager**（Story 001）
1. 创建`src/scenes/ui/hud/HUD.tscn`
2. 实现`HUDManager.gd`主控制器
3. 连接GameEvents信号

**阶段3：实现各UI面板**（Story 002-008）
1. 逐个实现UI组件（PlayerStatusPanel、CombatInfoPanel等）
2. 每个组件实现脏标记优化
3. 连接相应的GameEvents信号

**阶段4：集成游戏系统**（Story 009）
1. 修改游戏系统（CombatSystem、PlayerData等）发出信号
2. 测试信号流和UI更新
3. 性能验证

## Validation Criteria

**功能验证**：
- [ ] GameEvents单例正确注册并可访问
- [ ] 所有定义的信号可以正常发射和接收
- [ ] HUD组件正确响应信号并更新显示
- [ ] 模式切换（探索/战斗/菜单）正常工作

**性能验证**：
- [ ] HUD更新时间 < 1ms/帧（战斗中）
- [ ] HUD更新时间 < 0.5ms/帧（探索中）
- [ ] 无信号连接泄漏（运行1小时内存稳定）
- [ ] 60FPS稳定（战斗和探索场景）

**代码质量验证**：
- [ ] 所有信号使用类型化连接（不使用字符串）
- [ ] 所有节点引用使用`@onready`缓存
- [ ] 所有UI组件实现脏标记优化
- [ ] 代码审查通过（无直接耦合）

**兼容性验证**（Godot 4.6）：
- [ ] 鼠标输入正确触发HUD交互
- [ ] 键盘/手柄输入正确触发HUD交互
- [ ] 双焦点系统不影响HUD功能

## Related Decisions

- **ADR-001**: Core Architecture Decisions — 确立了信号系统用于松耦合的原则
- **ADR-003** (待创建): Data Binding Mechanism — 将定义GameEvents的具体信号结构
- **ADR-004** (待创建): Performance Optimization Strategy — 将详细定义对象池和批量更新机制