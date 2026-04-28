# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-04-28
> **Manifest Version**: 2026-04-28
> **ADRs Covered**: ADR-001
> **Design Decisions**: design-decisions-2026-04-28.md
> **Status**: Active — regenerate with `/create-control-manifest` when ADRs change

`Manifest Version` is the date this manifest was generated. Story files embed
this date when created. `/story-readiness` compares a story's embedded version
to this field to detect stories written against stale rules. Always matches
`Last Updated` — they are the same date, serving different consumers.

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation*

### Required Patterns
- **Use Godot 4.6 Scene-Node architecture** — organize game objects as scenes with node hierarchies — source: ADR-001
- **Use signal system for loose coupling** — avoid direct object references where signals can decouple components — source: ADR-001
- **JSON format for local storage** — human-readable, cross-platform compatible, supports version migration — source: ADR-001
- **Optional cloud sync via Steam Cloud** — cloud save is optional, not required for core experience — source: ADR-001

### Forbidden Approaches
- **Never use string-based connect()** — use typed signal connections for type safety and refactoring — source: Godot 4.6 best practices
- **Never use `yield()`** — use `await signal` (GDScript 2.0 coroutine syntax) — source: deprecated-apis.md

### Performance Guardrails
- **Target platform: Steam (PC)** — optimize for PC hardware, not web browsers — source: design-decisions-2026-04-28
- **Memory budget: <1GB** — total game memory usage should stay under 1GB — source: design-decisions-2026-04-28

---

## Core Layer Rules

*Applies to: core gameplay loop, main player systems, physics, collision*

### Required Patterns
- **Component-based design** — implement functionality through script and node composition, not deep inheritance — source: ADR-001
- **Use Jolt Physics for 3D** — default physics engine since 4.6, better determinism and stability — source: Godot 4.6 best practices

### Forbidden Approaches
- **Never use `instance()`** — use `instantiate()` instead — source: deprecated-apis.md

---

## Cross-System Interaction Rules

*Applies to: scenarios where multiple systems interact simultaneously*

### Battle中升级处理

**规则**：
1. 升级时战斗**不暂停**，继续进行
2. 升级动画：简短的光效（0.5秒），不阻塞操作
3. 属性点分配：战斗结束后自动弹出分配界面
4. 境界突破：战斗中**不触发**，战斗结束后提示"可进行境界突破"

**理由**：
- 保持战斗流畅性
- 避免打断玩家的战斗节奏
- 境界突破是重要时刻，应在安全环境下进行

**Source**: design-theory-issues-quick-solutions.md (DT-05)

---

### 奇遇触发状态管理

**规则**：
1. 奇遇触发时，玩家**立即停止移动**（锁定输入）
2. 奇遇UI层级：**最高优先级**，覆盖所有其他UI
3. 战斗后触发奇遇：
   - 战斗UI淡出（0.5秒）
   - 奇遇UI淡入（0.5秒）
   - 无重叠，顺序播放
4. 奇遇完成后，解锁玩家输入

**UI层级优先级**（从高到低）：
1. 奇遇UI
2. 暂停菜单
3. 战斗UI
4. 角色面板
5. 游戏世界

**Source**: design-theory-issues-quick-solutions.md (DT-05)

---

### 属性计算优先级

当多个系统同时修改同一属性时，按以下顺序计算：

1. **基础属性**（角色面板分配的点数）
2. **境界加成**（全属性 +10% × 境界等级）
3. **装备加成**（装备提供的固定值）
4. **Buff/Debuff**（临时状态效果）
5. **天赋加成**（百分比加成）

**公式**：
```
最终属性 = ((基础属性 + 装备加成) × (1 + 境界加成) + Buff) × (1 + 天赋加成)
```

**示例**：
- 基础力道：100
- 装备加成：+50
- 境界加成：+30%（3个境界）
- Buff：+20
- 天赋加成：+15%
- **最终力道** = ((100 + 50) × 1.3 + 20) × 1.15 = **247**

**Source**: design-theory-issues-quick-solutions.md (DT-05)
- **Never use `get_world()`** — use `get_world_3d()` for explicit 2D/3D split — source: deprecated-apis.md

### Performance Guardrails
- **Frame rate target: 60 FPS** — maintain 60 FPS on mainstream PC hardware — source: ADR-001
- **World streaming unload distance: 4.5× screen width** — coordinate with LOD system — source: design-decisions-2026-04-28

---

## Feature Layer Rules

*Applies to: secondary mechanics, AI systems, secondary features*

### Required Patterns
- **Modular design** — features should be self-contained and independently testable — source: ADR-001

### Forbidden Approaches
(None specified at Feature layer)

### Performance Guardrails
(None specified at Feature layer)

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX, shaders, animations*

### Required Patterns
- **Use Godot Control nodes + Theme resources** — native UI system with CSS-like styling — source: ADR-001
- **Declarative UI via scene files** — define UI structure in .tscn files, not code — source: ADR-001
- **Cache node references with @onready** — avoid `$NodePath` lookups in `_process()` — source: Godot 4.6 best practices

### Forbidden Approaches
- **Never use `TileMap`** — use `TileMapLayer` (one node per layer) — source: deprecated-apis.md
- **Never use `VisibilityNotifier2D/3D`** — use `VisibleOnScreenNotifier2D/3D` — source: deprecated-apis.md
- **Never use `YSort` node** — use `Node2D.y_sort_enabled` property — source: deprecated-apis.md

### Performance Guardrails
(None specified at Presentation layer)

---

## Game Design Rules

### Character Progression
- **Level cap: 99** — maximum player level is 99 — source: design-decisions-2026-04-28
- **Attribute points per level: 5** — each level grants 5 free attribute points (total 495 points at level 99) — source: design-decisions-2026-04-28
- **Realm count: 9** — nine major cultivation realms from Lv 1-99 — source: design-decisions-2026-04-28
- **Realm structure**:
  - Early Qi Refining (Lv 1-11)
  - Late Qi Refining (Lv 12-22)
  - Early Foundation Building (Lv 23-33)
  - Late Foundation Building (Lv 34-44)
  - Early Golden Core (Lv 45-55)
  - Late Golden Core (Lv 56-66)
  - Early Nascent Soul (Lv 67-77)
  - Late Nascent Soul (Lv 78-88)
  - Spirit Transformation (Lv 89-99)
- **Realm breakthrough bonus: +10% all attributes** — percentage-based bonus per breakthrough — source: design-decisions-2026-04-28

### Attribute System
- **Six core attributes** — STR, AGI, CON, WIS, WILL, LUK — source: design-decisions-2026-04-28
- **Attribute definitions**:
  - **STR (Strength/力道)**: Physical damage +2, carry weight +5kg, armor penetration +1 per point
  - **AGI (Agility/身法)**: Evasion +0.5%, action speed +1%, movement speed +0.5%, crit rate +0.3% per point
  - **CON (Constitution/根骨)**: Max HP +20, physical defense +1, status resistance +0.5%, HP regen +0.5/sec per point
  - **WIS (Wisdom/悟性)**: Max Qi +15, Qi regen +0.3/sec, skill proficiency gain +1%, crit damage +1% per point
  - **WILL (Willpower/定力)**: Max Poise +10, block success rate +0.5%, control resistance +0.5%, mental defense +1 per point
  - **LUK (Luck/福缘)**: Encounter rate +0.3%, rare drop rate +0.5%, crafting success +0.5%, crit rate +0.2% per point

### Combat System
- **Damage formula**: `Final Damage = Base Damage × Crit Multiplier × Combo Multiplier × Weakness Multiplier × Break Multiplier × Status Multiplier × Random Variance × Element Multiplier`
- **Element system: Five Elements (Wu Xing)** — Metal, Wood, Water, Fire, Earth
- **Element counters**:
  - Metal counters Wood
  - Wood counters Earth
  - Earth counters Water
  - Water counters Fire
  - Fire counters Metal
- **Element multiplier: 1.5× damage** — when using counter element — source: design-decisions-2026-04-28
- **Qi recovery rate: 5%-10% per turn, default 5%** — adjustable for balance — source: design-decisions-2026-04-28
- **Poise system**: Poise max = Base Poise + (WILL × 10) — source: design-decisions-2026-04-28

### World Streaming
- **Chunk size: 2048×2048 pixels** — standard world chunk size
- **Load distance: 1.5× screen width** — preload chunks at this distance
- **Unload distance: 4.5× screen width** — unload chunks beyond this distance — source: design-decisions-2026-04-28
- **Max loaded chunks: 16** — maximum simultaneous loaded chunks on PC

## Global Rules (All Layers)

### Naming Conventions
| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `PlayerController` |
| Variables | snake_case | `move_speed` |
| Signals/Events | snake_case past tense | `health_changed` |
| Files | snake_case matching class | `player_controller.gd` |
| Scenes/Prefabs | PascalCase matching root node | `PlayerController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_HEALTH` |

### Performance Budgets
| Target | Value |
|--------|-------|
| Framerate | 60 FPS |
| Frame budget | 16.6 ms |
| Draw calls | < 2000 (web deployment) |
| Memory ceiling | < 2GB (web deployment) |

### Approved Libraries / Addons
- **GUT (Godot Unit Test)** — approved for unit and integration testing
- (Add more as dependencies are approved)

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or have better alternatives:

**Nodes & Classes:**
- `TileMap` → use `TileMapLayer` (since 4.3)
- `VisibilityNotifier2D` → use `VisibleOnScreenNotifier2D` (since 4.0)
- `VisibilityNotifier3D` → use `VisibleOnScreenNotifier3D` (since 4.0)
- `YSort` → use `Node2D.y_sort_enabled` property (since 4.0)
- `Navigation2D` / `Navigation3D` → use `NavigationServer2D` / `NavigationServer3D` (since 4.0)

**Methods & Properties:**
- `yield()` → use `await signal` (since 4.0)
- `connect("signal", obj, "method")` → use `signal.connect(callable)` (since 4.0)
- `instance()` → use `instantiate()` (since 4.0)
- `PackedScene.instance()` → use `PackedScene.instantiate()` (since 4.0)
- `get_world()` → use `get_world_3d()` (since 4.0)
- `OS.get_ticks_msec()` → use `Time.get_ticks_msec()` (since 4.0)
- `duplicate()` for nested resources → use `duplicate_deep()` (since 4.5)

**Patterns:**
- String-based `connect()` → use typed signal connections
- `$NodePath` in `_process()` → use `@onready var` cached reference
- Untyped `Array` / `Dictionary` → use `Array[Type]`, typed variables
- Manual post-process viewport chains → use `Compositor` + `CompositorEffect` (4.3+)
- GodotPhysics3D for new projects → use Jolt Physics 3D (default since 4.6)

### Recommended Patterns (Godot 4.6)

**GDScript:**
- Use variadic arguments for flexible function signatures
- Use `@abstract` for abstract classes and methods
- Enable static typing for compiler optimizations

**Physics:**
- Use Jolt Physics 3D for new 3D projects (better determinism)
- Note: Some HingeJoint3D properties only work with GodotPhysics

**Rendering:**
- Use AgX tonemapper for better white point and contrast control
- Use SMAA 1x for sharper AA than FXAA, cheaper than TAA
- Pre-compile shaders with Shader Baker to eliminate startup hitching

**Resources:**
- Use `duplicate_deep()` for per-instance copies of nested resources

**UI:**
- Consider dual-focus system (mouse/touch vs keyboard/gamepad)
- Use FoldableContainer for accordion-style collapsible sections

### Cross-Cutting Constraints
- **Web deployment optimization** — all systems must respect draw call and memory budgets for web platform
- **Keyboard/Mouse primary input** — all UI must be responsive to keyboard/mouse navigation
- **Gamepad support partial** — gamepad is recommended but not required
- **No touch support** — do not implement touch-specific controls
- **Test coverage minimum 70%** — core gameplay systems require automated tests via GUT framework

---

## Engine Specialist Routing

When spawning specialists for code review or validation:

| File Type | Specialist to Spawn |
|-----------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |

---

## Maintenance Notes

- **When to regenerate**: Run `/create-control-manifest` after any ADR is accepted, revised, or deprecated
- **Version tracking**: The `Manifest Version` date is embedded in story files to detect stale rules
- **Expansion**: As more ADRs are created, this manifest will grow with layer-specific rules
- **Current coverage**: 1 ADR (ADR-001: Core Architecture Decisions)

---

**Last regenerated**: 2026-04-28
**Next review**: When new ADRs are accepted or existing ADRs are revised