# 武侠奇遇录 — 主架构文档

## 文档状态
- **版本**: 1.0
- **最后更新**: 2026-05-04
- **引擎**: Godot 4.6
- **GDD 覆盖**: 44+ 系统
- **ADR 引用**: ADR-001 至 ADR-004
- **技术总监签署**: 待审核
- **主程序员可行性**: 待审核

---

## 引擎知识差距摘要

**引擎**: Godot 4.6
**LLM 训练覆盖**: 最高约 Godot 4.3
**Post-Cutoff 版本**: 4.4 (中风险), 4.5 (高风险), 4.6 (高风险)

### 高风险领域
| 领域 | 关键变更 | 影响系统 |
|------|---------|---------|
| GDScript | 可变参数(...), @abstract 装饰器 | 核心架构模式 |
| 渲染 | Shader 预编译烘焙, SMAA, AgX 色色调映射, D3D12 默认 | 世界流式加载 |
| UI | 双焦点系统(鼠标/键盘分离), FoldableContainer | HUD 系统 |
| 物理 | Jolt Physics 默认 | 战斗系统 |

### 中风险领域
| 领域 | 关键变更 | 影响系统 |
|------|---------|---------|
| 物理 | 3D 插值重架构 | 移动平滑性 |
| 文件 | FileAccess.store_* 返回 bool | 存档系统 |
| 渲染 | draw_list_begin 参数更改 | 自定义后处理 |

---

## 系统层级映射

```
┌─────────────────────────────────────────────────────────────────────┐
│  表现层 (PRESENTATION LAYER)                                         │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • 战斗UI (Combat UI)              • 装备UI (Equipment UI)     │  │
│  │ • HUD 系统 (PlayerStatusPanel,    • 对话UI (Dialogue UI)      │  │
│  │   CombatInfoPanel 等)              • 奇遇UI (Encounter UI)     │  │
│  │ • 地图/小地图 (Minimap)           • 菜单系统 (Menu System)     │  │
│  │ • 音频系统 (Audio System)         • 性能监控器                 │  │
│  └───────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│  功能层 (FEATURE LAYER)                                              │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • 奇遇系统 (Encounter System)     • 奇遇条件检查              │  │
│  │ • 奖励分配系统                    • 奇遇历史记录              │  │
│  │ • 随机事件生成器                  • 对话系统                   │  │
│  │ • 对话树管理                      • 对话效果系统              │  │
│  │ • 角色关系系统                    • 关系值计算                │  │
│  │ • 道心系统                        • 关系事件触发              │  │
│  │ • 结局判定                        • 任务系统 (Quest System)   │  │
│  │ • 兴趣点追踪                      • 快速旅行系统              │  │
│  │ • 敌人AI系统                      • 敌人动态难度              │  │
│  │ • 经济系统                        • 装备系统                  │  │
│  └───────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│  核心层 (CORE LAYER)                                                 │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • 战斗系统 (Combat System)        • 伤害计算系统              │  │
│  │ • 生命值/防御系统                 • 命中检测系统              │  │
│  │ • 状态效果系统                    • 武学系统 (Martial Arts)   │  │
│  │ • 武学组合/连招系统               • 技能树/学习路径           │  │
│  │ • 内力/能量管理系统               • 角色成长系统              │  │
│  │ • 经验值系统                      • 等级提升机制              │  │
│  │ • 属性点分配系统                  • 开放世界探索系统          │  │
│  └───────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│  基础层 (FOUNDATION LAYER)                                           │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • 世界流式加载系统                • LOD 系统                  │  │
│  │ • 武学数据库                      • 物品数据库                │  │
│  │ • 对话数据库                      • 角色关系数据库            │  │
│  │ • 世界状态持久化                  • 成长数据持久化            │  │
│  │ • GameEvents 全局信号总线         • 性能优化框架              │  │
│  └───────────────────────────────────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────────────┤
│  平台层 (PLATFORM LAYER)                                             │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │ • Godot 4.6 引擎核心              • Jolt Physics 3D           │  │
│  │ • D3D12/Vulkan 渲染后端           • Steam SDK (成就/云存档)   │  │
│  │ • 输入系统 (键盘/鼠标, 手柄)                                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
```

### 引擎风险标记

| 层级 | 系统 | 风险域 | 风险级别 | 备注 |
|------|------|--------|---------|------|
| 核心层 | 战斗系统 | Jolt Physics 默认 | HIGH | 碰撞行为需验证 |
| 核心层 | 开放世界探索 | 3D 插值重架构 | MEDIUM | 移动平滑性需测试 |
| 基础层 | 世界流式加载 | D3D12 默认 | HIGH | 渲染后端切换需确认 |
| 基础层 | 世界状态持久化 | FileAccess 返回值变更 | MEDIUM | 错误处理需更新 |
| 表现层 | HUD 系统 | 双焦点系统 | HIGH | 键盘/鼠标焦点分离需测试 |
CONTENT_EOF < /dev/null
---

## 模块所有权

### 表现层

| 模块 | Owns | Exposes | Consumes | 引擎 API |
|------|------|---------|----------|---------|
| 战斗UI | 血条、伤害数字、连招显示 | `update_health()`, `show_damage()` | 战斗系统信号 | Control, Label, Tween |
| 装备UI | 装备栏、属性面板 | `equip_item()`, `unequip_item()` | 装备系统、物品数据库 | GridContainer, ItemList |
| HUD 系统 | 玩家状态面板、信息面板 | 全局 HUD 更新 | CharacterSystem 信号 | CanvasLayer, VBoxContainer |
| 对话UI | 对话气泡、选项列表 | `show_dialogue()`, `hide_dialogue()` | DialogueManager 信号 | RichTextLabel, Button |
| 奇遇UI | 奇遇事件展示、奖励面板 | `display_encounter()`, `show_reward()` | EncounterSystem 信号 | Control, AnimationPlayer |
| 音频系统 | 音频播放器、音效管理 | `play_sfx()`, `play_music()` | GameEvents 音频信号 | AudioStreamPlayer, AudioBus |

### 功能层

| 模块 | Owns | Exposes | Consumes | 引擎 API |
|------|------|---------|----------|---------|
| 奇遇系统 | 事件触发、奖励分配 | `trigger_encounter()`, `process_reward()` | 随机事件生成器, 世界状态 | Node, Timer, ResourceLoader |
| 对话系统 | 对话树、分支管理 | `start_dialogue()`, `select_option()` | 对话数据库, 对话效果系统 | Node, JSON |
| 角色关系系统 | 关系值、道心值管理 | `modify_relationship()`, `modify_dao_heart()` | 角色关系数据库, 游戏事件 | Node, Signal |
| 任务系统 | 任务跟踪、进度管理 | `accept_quest()`, `complete_quest()` | 世界状态, 游戏事件 | Node, Dictionary |
| 敌人AI | 行为树、状态机 | `update_ai()`, `set_target()` | 战斗系统, 角色系统 | Node, NavigationAgent2D |
| 装备系统 | 装备槽位、属性计算 | `equip()`, `unequip()`, `get_stats()` | 物品数据库, CharacterSystem | Resource, Dictionary |

### 核心层

| 模块 | Owns | Exposes | Consumes | 引擎 API |
|------|------|---------|----------|---------|
| 战斗系统 | 战斗状态、回合管理 | `start_combat()`, `end_combat()`, `execute_action()` | 伤害计算, 命中检测, 状态效果 | Node, Signal, Timer |
| 伤害计算 | 伤害公式、属性修正 | `calculate_damage()` | 角色属性, 武学数据 | Dictionary, float 运算 |
| 命中检测 | 碰撞检测、命中判定 | `check_hit()`, `get_hit_area()` | 战斗状态, 敌人位置 | Jolt Physics, Area2D/3D |
| 武学系统 | 武学学习、使用、组合 | `learn_martial_art()`, `use_martial_art()` | 武学数据库, 内力管理 | Resource, Dictionary |
| 角色成长 | 经验值、等级、属性 | `add_exp()`, `level_up()`, `allocate_points()` | 经验值系统, 属性点分配 | Node, Signal |

### 基础层

| 模块 | Owns | Exposes | Consumes | 引擎 API |
|------|------|---------|----------|---------|
| 世界流式加载 | 场景加载、区块管理 | `load_sector()`, `unload_sector()` | LOD 系统, 游戏场景 | ResourceLoader, PackedScene |
| GameEvents 信号总线 | 全局信号定义、分发 | 所有系统事件信号 | 所有模块 | Node (autoload), Signal |
| 世界状态持久化 | 世界状态保存/加载 | `save_world()`, `load_world()` | 所有数据库, 奇遇/任务状态 | FileAccess, JSON |
| 成长数据持久化 | 角色成长数据保存 | `save_growth()`, `load_growth()` | 角色成长系统 | FileAccess, JSON |
| 武学数据库 | 武学技能数据 | `get_martial_art()`, `query_arts()` | 武学系统, 技能树 | Resource, Dictionary |

---

## 数据流

### 1. 帧更新路径

```
输入系统 → 核心系统 → 状态更新 → 表现层渲染
   ↓            ↓           ↓           ↓
键盘/鼠标    战斗/AI/    CharacterSystem  HUD/UI
手柄输入     武学处理     更新属性         刷新显示
```

**详细说明**:
- **输入处理**: 玩家输入通过 Godot 输入系统收集，转换为游戏内动作
- **核心处理**: 战斗、武学、AI 等核心系统处理游戏逻辑
- **状态更新**: CharacterSystem 统一管理角色状态，通过信号分发
- **渲染更新**: UI 层订阅信号，按需刷新显示

### 2. 事件/信号路径

```
GameEvents (全局信号总线)
├── 玩家事件: player_level_up, player_stats_changed
├── 队伍事件: party_member_joined, party_member_left
├── 战斗事件: combat_started, combat_ended, damage_dealt
├── 敌人事件: enemy_spawned, enemy_defeated
├── Buff/Debuff: buff_applied, debuff_expired
├── 任务事件: quest_accepted, quest_completed
├── 导航事件: waypoint_reached
├── 物品事件: item_acquired, item_used
├── 技能事件: skill_learned, skill_used
└── 系统事件: game_saved, game_loaded
```

**通信原则**: 系统间通过 GameEvents 信号通信，避免直接依赖，保持松耦合。

### 3. 存档/读档路径

```
保存流程:
世界状态 → 世界状态持久化 → JSON 序列化 → FileAccess → 磁盘
角色数据 → 成长数据持久化 → JSON 序列化 → FileAccess → 磁盘
奇遇/任务 → 奇遇历史记录 → JSON 序列化 → FileAccess → 磁盘

加载流程:
磁盘 → FileAccess → JSON 反序列化 → 世界状态持久化 → 世界状态
磁盘 → FileAccess → JSON 反序列化 → 成长数据持久化 → 角色数据
```

**存档格式**: JSON 文件，人类可读，便于调试和版本迁移。
**存档位置**: `user://saves/` 目录（Godot 用户数据目录）。

### 4. 初始化顺序

```
1. 平台层: Godot 4.6 引擎启动
2. 基础层: Autoload 初始化 (GameEvents, CharacterSystem 等 14 个 autoload)
3. 基础层: 数据库加载 (武学/物品/对话/关系数据库)
4. 核心层: 战斗系统、武学系统初始化
5. 功能层: 奇遇系统、任务系统、角色关系系统初始化
6. 表现层: HUD、UI 初始化
7. 场景加载: 主场景加载
```
CONTENT_EOF < /dev/null
---

## API 边界

### 核心战斗 API

```gdscript
# 战斗系统入口
class_name CombatManager extends Node

## 开始战斗，接收敌人配置
func start_combat(enemy_config: Dictionary) -> void:
    # 验证配置 -> 初始化战斗状态 -> 发射 combat_started 信号
    pass

## 执行玩家动作
func execute_action(action_id: String, target_id: String) -> Dictionary:
    # 返回: {damage: float, status_effects: Array, critical: bool}
    # 内部调用: 伤害计算 -> 命中检测 -> 状态效果应用
    pass

## 结束战斗
func end_combat(victory: bool) -> void:
    # 结算奖励 -> 发射 combat_ended 信号
    pass
```

### 角色管理 API

```gdscript
# 角色系统入口 (Autoload: CharacterSystem)
class_name CharacterSystemClass extends Node

## 修改角色属性
func modify_stat(stat_name: String, delta: float, is_percent: bool = false) -> void:
    # 验证边界 -> 更新属性 -> 发射 stats_changed 信号
    pass

## 获取角色当前状态
func get_character_state() -> Dictionary:
    # 返回: {health: float, internal_energy: float, stats: Dictionary}
    pass

## 角色升级
func level_up() -> void:
    # 计算属性提升 -> 发射 level_up 信号
    pass
```

### 奇遇系统 API

```gdscript
# 奇遇系统 (Autoload: EncounterSystem)
class_name EncounterTriggerManager extends Node

## 检查并触发奇遇
func check_and_trigger_encounter(context: Dictionary) -> bool:
    # 条件检查 -> 权重选择 -> 触发事件
    # 返回: true 如果触发了奇遇
    pass

## 处理奇遇结果
func process_encounter_result(encounter_id: String, choices: Array) -> Dictionary:
    # 应用奖励/惩罚 -> 更新世界状态 -> 记录历史
    pass
```

### 存档系统 API

```gdscript
# 世界状态持久化
class_name WorldStateSaver extends Node

## 保存世界状态
func save_world(slot: int = 1) -> bool:
    # 收集所有系统状态 -> JSON 序列化 -> 写入文件
    # Godot 4.4+ 注意: FileAccess.store_* 返回 bool，需检查返回值
    pass

## 加载世界状态
func load_world(slot: int = 1) -> Dictionary:
    # 读取文件 -> JSON 反序列化 -> 分发到各系统
    pass
```

### 信号总线 API

```gdscript
# GameEvents (Autoload)
class_name GameEventsClass extends Node

# 玩家信号
signal player_level_up(old_level: int, new_level: int)
signal player_stats_changed(stat: String, new_value: float)

# 战斗信号
signal combat_started(enemy_name: String)
signal combat_ended(victory: bool)
signal damage_dealt(target: Node, damage: float, is_critical: bool)

# 奇遇信号
signal encounter_triggered(encounter_id: String)
signal encounter_completed(encounter_id: String, rewards: Dictionary)

# 任务信号
signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)
```

---

## ADR 审计

### ADR 质量检查

| ADR | 引擎兼容 | 版本记录 | GDD 关联 | 冲突 | 有效 |
|-----|---------|---------|---------|------|------|
| ADR-001: 核心架构决策 | ✅ | ✅ Godot 4.6 | ✅ 基础架构 | 无 | ✅ |
| ADR-002: HUD 架构模式 | ✅ | ✅ Godot 4.6 | ✅ HUD 系统 | 无 | ✅ |
| ADR-003: 数据绑定机制 | ✅ | ✅ Godot 4.6 | ✅ UI 绑定 | 无 | ✅ |
| ADR-004: 性能优化策略 | ✅ | ✅ Godot 4.6 | ✅ 性能预算 | 无 | ✅ |

### 可追溯性覆盖检查

| 需求来源 | ADR 覆盖 | 状态 |
|---------|---------|------|
| 核心架构 (scene management, signals) | ADR-001 | ✅ |
| HUD 架构 | ADR-002 | ✅ |
| 数据绑定 | ADR-003 | ✅ |
| 性能优化 | ADR-004 | ✅ |
| 战斗系统架构 | — | ❌ 缺口 |
| 存档系统架构 | — | ❌ 缺口 |
| 世界流式加载 | — | ❌ 缺口 |

**统计**: 4 个已覆盖, 3 个缺口

---

## 所需 ADR

### 基础层（编码前必须创建）
- `/architecture-decision save-system-architecture` → 存档系统架构，定义文件格式、加密策略、版本迁移
- `/architecture-decision world-streaming-architecture` → 世界流式加载策略，定义场景切换方式

### 核心层
- `/architecture-decision combat-system-architecture` → 战斗系统架构，定义回合/实时模式选择

### 可推迟到实现阶段
- `/architecture-decision specific-shader-techniques` → 特定 Shader 技术选择
- `/architecture-decision audio-implementation-details` → 音频实现细节

---

## 架构原则

1. **信号驱动**: 系统间通过 GameEvents 全局信号总线通信，避免直接依赖。每个系统只关注自己需要的信号。

2. **依赖注入**: 系统通过 `initialize()` 方法接收依赖，避免在 `_ready()` 中查找其他节点。所有 Manager 节点作为 Autoload 注册。

3. **数据驱动**: 所有游戏数值来自外部配置（JSON/Resource），不在代码中硬编码。战斗公式、经验曲线、属性计算均可配置。

4. **分层隔离**: 表现层、功能层、核心层、基础层严格分层。上层可以依赖下层，下层不依赖上层。跨层通信必须通过明确的 API。

5. **性能优先**: 60 FPS 目标，Web 平台内存上限 2GB。使用对象池管理频繁创建/销毁的对象，避免在 `_process()` 中进行复杂计算。

---

## 开放问题

| 问题 | 层级 | 需解决时间 | 负责人 |
|------|------|-----------|--------|
| 存档文件格式是否需要加密 | 基础层 | 存档系统实现前 | 技术总监 |
| 世界流式加载使用分块场景还是动态资源加载 | 基础层 | 世界系统实现前 | 主程序员 |
| 战斗系统采用回合制还是半实时制 | 核心层 | 战斗系统实现前 | 游戏设计师 |
| Web 平台性能预算是否需要调整 | 平台层 | 性能测试后 | 性能分析师 |
| Steam SDK 集成的优先级 | 平台层 | 发布前 | 制作人 |

---

## 技术风险登记

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|---------|
| Jolt Physics 行为变化导致战斗碰撞异常 | 中 | 高 | 编写专门的碰撞测试，验证 Godot 4.6 Jolt 默认行为 |
| FileAccess 返回值变更导致存档失败 | 低 | 高 | 更新所有存档代码检查 store_* 返回值，增加错误处理 |
| D3D12 默认导致 Web 渲染问题 | 中 | 中 | 在 Web 导出时切换渲染后端，测试兼容性 |
| 双焦点系统导致 HUD 交互异常 | 低 | 中 | 编写 UI 交互测试，验证键盘/鼠标焦点分离 |

---

## 性能预算与监控

| 指标 | 预算 | 监控方式 |
|------|------|---------|
| 目标帧率 | 60 FPS | 性能监控器实时显示 |
| 绘制调用 | < 2000 | 引擎调试面板监控 |
| 内存上限 | 2GB (Web) | 内存优化器定期检查 |
| 场景加载时间 | < 2 秒 | 流式加载系统计时 |

---

## 开发指南

### 命名规范
- **文件和类名**: PascalCase (`CombatManager`, `PlayerStatusPanel`)
- **变量**: snake_case (`move_speed`, `current_health`)
- **信号**: snake_case 过去时 (`health_changed`, `level_up`)
- **常量**: UPPER_SNAKE_CASE (`MAX_HEALTH`, `COMBAT_STATE_NORMAL`)

### 禁止模式
1. **禁止直接 UI 修改**: 业务逻辑不应直接修改 UI，使用信号通知
2. **禁止全局变量**: 使用 Manager 节点和依赖注入
3. **禁止硬编码值**: 使用配置文件或常量

### 必需模式
1. **依赖注入**: 系统通过 `initialize()` 方法接收依赖
2. **信号驱动**: 系统间通信使用 GameEvents 信号
3. **文档注释**: 所有公共方法使用 `##` 注释
CONTENT_EOF < /dev/null