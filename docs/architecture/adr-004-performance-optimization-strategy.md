# ADR-004: 性能优化策略

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI / Performance |
| **Knowledge Risk** | LOW — 使用标准Godot优化技术,无post-cutoff依赖 |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — 使用标准对象池、批量更新等通用优化模式 |
| **Verification Required** | 性能测试验证优化效果,确保符合预算(<1ms/帧战斗,<0.5ms/帧探索) |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (HUD架构模式 — 脏标记基础), ADR-003 (数据绑定机制 — 信号结构) |
| **Enables** | None — 这是优化层,不阻塞其他ADR |
| **Blocks** | None — HUD stories可以先实现基础功能,后续应用优化 |
| **Ordering Note** | 建议在基础HUD实现后应用,通过性能测试验证必要性 |

## Context

### Problem Statement

ADR-002和ADR-003定义了HUD的架构和数据绑定机制,但还需要具体的性能优化策略来确保符合严格的性能预算:

- **战斗中**: HUD更新 < 1ms/帧
- **探索中**: HUD更新 < 0.5ms/帧
- **目标帧率**: 60FPS稳定
- **平台**: Web/Browser (性能受限)

需要解决的性能问题:

1. **GC压力**: 频繁创建/销毁UI元素(Buff图标、伤害数字、通知面板)导致垃圾回收卡顿
2. **Draw Call过多**: 大量UI元素导致draw call超过预算(<100 draw calls)
3. **重复更新**: 同一帧内多个信号触发,导致重复绘制
4. **不必要的更新**: 数值未变化但仍然更新UI
5. **性能监控盲区**: 缺乏工具定位性能瓶颈

### Constraints

**性能约束**(来自design/ux/hud.md):
- HUD draw calls < 100
- 战斗中HUD更新 < 1ms/帧
- 探索中HUD更新 < 0.5ms/帧
- 60FPS稳定
- 内存占用 < 50MB (所有HUD纹理)

**技术约束**:
- 必须在Godot 4.6中实现
- 不能破坏信号驱动架构(ADR-002)
- 不能影响类型安全(ADR-003)
- 优化必须是可测量的

**设计约束**:
- 优化不能牺牲可读性
- 优化不能增加复杂度到难以维护的程度
- 必须提供性能监控工具

### Requirements

**必须实现的优化**:

1. **对象池**(Object Pooling):
   - Buff/Debuff图标复用
   - 伤害数字飘字复用
   - 通知面板复用
   - 减少GC压力

2. **批量更新**(Batch Updates):
   - 收集同一帧的多个更新请求
   - 在`_process()`末尾统一应用
   - 减少draw call

3. **脏标记优化**(Dirty Flag):
   - 已在ADR-002中定义
   - 避免重复更新相同值
   - 缓存上一次的值

4. **LOD策略**(Level of Detail):
   - 根据信息优先级调整更新频率
   - P0级: 每帧更新
   - P1级: 每0.1秒更新
   - P2-P4级: 按需更新

5. **性能监控工具**:
   - HUD性能分析器
   - 实时性能指标显示
   - 性能日志记录

## Decision

**采用分层优化策略: 对象池 + 批量更新 + 脏标记 + LOD + 性能监控**

### 核心决策

1. **对象池模式**:
   - 为频繁创建/销毁的UI元素实现对象池
   - 预分配固定数量的对象,循环复用
   - 避免运行时内存分配和GC

2. **批量更新机制**:
   - 在UI组件中收集更新请求
   - 延迟到`_process()`末尾统一应用
   - 合并重复更新,减少draw call

3. **脏标记优化**:
   - 继承ADR-002的脏标记模式
   - 每个UI组件维护缓存值
   - 仅当值变化时标记为dirty

4. **LOD更新频率**:
   - P0级(HP/Qi/Poise): 信号驱动,立即更新
   - P1级(战斗信息): 每0.1秒批量更新
   - P2-P4级(探索信息): 按需更新,最多每0.5秒

5. **性能监控**:
   - 开发模式下显示性能指标
   - 记录性能日志用于分析
   - 提供性能分析工具

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Performance Layer                         │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Object Pools (预分配,循环复用)                          │ │
│  │  - BuffIconPool (20个Buff图标)                         │ │
│  │  - DamageNumberPool (30个伤害数字)                     │ │
│  │  - NotificationPool (5个通知面板)                      │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Batch Update Manager (收集+延迟应用)                   │ │
│  │  - 收集同一帧的多个更新请求                            │ │
│  │  - 在_process()末尾统一应用                            │ │
│  │  - 合并重复更新                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Dirty Flag System (缓存+比较)                          │ │
│  │  - 每个UI组件维护缓存值                                │ │
│  │  - 新值与缓存值比较                                    │ │
│  │  - 仅当不同时标记dirty                                 │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ LOD Update Scheduler (分级更新频率)                    │ │
│  │  - P0级: 立即更新                                      │ │
│  │  - P1级: 每0.1秒批量更新                               │ │
│  │  - P2-P4级: 按需更新,最多每0.5秒                       │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Performance Monitor (监控+分析)                        │ │
│  │  - 实时性能指标(FPS, 更新时间, draw calls)             │ │
│  │  - 性能日志记录                                        │ │
│  │  - 性能分析工具                                        │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                          ↓ 应用于
┌─────────────────────────────────────────────────────────────┐
│                    HUD Components                            │
│  - PlayerStatusPanel (使用脏标记+批量更新)                  │
│  - CombatInfoPanel (使用对象池+LOD)                         │
│  - BuffDisplayPanel (使用对象池+批量更新)                   │
│  - DamageNumberManager (使用对象池)                         │
│  - NotificationManager (使用对象池+批量更新)                │
└─────────────────────────────────────────────────────────────┘
```

### Key Interfaces

**1. ObjectPool.gd** (通用对象池基类):

```gdscript
class_name ObjectPool
extends Node

## 对象池容量
@export var pool_size: int = 10

## 对象场景
@export var object_scene: PackedScene

## 池中的对象
var _pool: Array[Node] = []

## 活跃的对象
var _active: Array[Node] = []

func _ready() -> void:
    _initialize_pool()

## 初始化对象池
func _initialize_pool() -> void:
    for i in range(pool_size):
        var obj := object_scene.instantiate()
        obj.hide()
        add_child(obj)
        _pool.append(obj)

## 从池中获取对象
func acquire() -> Node:
    var obj: Node
    
    if _pool.is_empty():
        # 池已空,创建新对象(或复用最老的活跃对象)
        if _active.is_empty():
            obj = object_scene.instantiate()
            add_child(obj)
        else:
            # 复用最老的活跃对象
            obj = _active[0]
            _active.remove_at(0)
    else:
        obj = _pool.pop_back()
    
    _active.append(obj)
    obj.show()
    return obj

## 归还对象到池
func release(obj: Node) -> void:
    if obj not in _active:
        return
    
    _active.erase(obj)
    obj.hide()
    _reset_object(obj)
    _pool.append(obj)

## 重置对象状态(子类重写)
func _reset_object(obj: Node) -> void:
    pass

## 释放所有活跃对象
func release_all() -> void:
    for obj in _active.duplicate():
        release(obj)
```

**2. BuffIconPool.gd** (Buff图标对象池):

```gdscript
class_name BuffIconPool
extends ObjectPool

func _ready() -> void:
    pool_size = 20  # 最多同时显示20个Buff
    object_scene = preload("res://src/scenes/ui/hud/buff_icon.tscn")
    super._ready()

func _reset_object(obj: Node) -> void:
    # 重置Buff图标状态
    if obj.has_method("reset"):
        obj.reset()
```

**3. BatchUpdateManager.gd** (批量更新管理器):

```gdscript
class_name BatchUpdateManager
extends Node

## 待更新的组件和数据
var _pending_updates: Dictionary = {}

## 注册更新请求
func request_update(component: Node, update_data: Dictionary) -> void:
    if component not in _pending_updates:
        _pending_updates[component] = []
    
    _pending_updates[component].append(update_data)

## 在_process()末尾调用,应用所有更新
func apply_updates() -> void:
    for component in _pending_updates:
        var updates := _pending_updates[component] as Array
        
        # 合并重复更新
        var merged := _merge_updates(updates)
        
        # 应用合并后的更新
        if component.has_method("apply_batch_update"):
            component.apply_batch_update(merged)
    
    _pending_updates.clear()

## 合并重复更新(保留最新值)
func _merge_updates(updates: Array) -> Dictionary:
    var merged := {}
    
    for update in updates:
        for key in update:
            merged[key] = update[key]  # 后面的值覆盖前面的
    
    return merged
```

**4. LODUpdateScheduler.gd** (LOD更新调度器):

```gdscript
class_name LODUpdateScheduler
extends Node

## 更新频率配置
const UPDATE_INTERVALS := {
    "P0": 0.0,      # 立即更新
    "P1": 0.1,      # 每0.1秒
    "P2": 0.3,      # 每0.3秒
    "P3": 0.5,      # 每0.5秒
    "P4": 1.0,      # 每1秒
}

## 注册的组件和优先级
var _registered_components: Dictionary = {}

## 上次更新时间
var _last_update_times: Dictionary = {}

## 注册组件
func register_component(component: Node, priority: String) -> void:
    _registered_components[component] = priority
    _last_update_times[component] = 0.0

## 检查是否应该更新
func should_update(component: Node, delta: float) -> bool:
    if component not in _registered_components:
        return false
    
    var priority := _registered_components[component] as String
    var interval := UPDATE_INTERVALS.get(priority, 0.0)
    
    # P0级立即更新
    if interval == 0.0:
        return true
    
    # 检查是否到达更新间隔
    _last_update_times[component] += delta
    
    if _last_update_times[component] >= interval:
        _last_update_times[component] = 0.0
        return true
    
    return false
```

**5. PerformanceMonitor.gd** (性能监控器):

```gdscript
class_name PerformanceMonitor
extends CanvasLayer

## 是否启用监控
@export var enabled: bool = false

## 性能指标
var _fps: float = 0.0
var _hud_update_time: float = 0.0
var _draw_calls: int = 0

## UI标签
@onready var _fps_label: Label = $Panel/VBox/FPSLabel
@onready var _update_time_label: Label = $Panel/VBox/UpdateTimeLabel
@onready var _draw_calls_label: Label = $Panel/VBox/DrawCallsLabel

func _ready() -> void:
    visible = enabled

func _process(_delta: float) -> void:
    if not enabled:
        return
    
    # 更新FPS
    _fps = Engine.get_frames_per_second()
    _fps_label.text = "FPS: %.1f" % _fps
    
    # 更新HUD更新时间
    _update_time_label.text = "HUD Update: %.2f ms" % (_hud_update_time * 1000.0)
    
    # 更新Draw Calls
    _draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
    _draw_calls_label.text = "Draw Calls: %d" % _draw_calls
    
    # 性能警告
    if _hud_update_time > 0.001:  # > 1ms
        _update_time_label.modulate = Color.RED
    elif _hud_update_time > 0.0005:  # > 0.5ms
        _update_time_label.modulate = Color.YELLOW
    else:
        _update_time_label.modulate = Color.GREEN

## 记录HUD更新时间
func record_hud_update_time(time: float) -> void:
    _hud_update_time = time

## 导出性能日志
func export_performance_log(file_path: String) -> void:
    var file := FileAccess.open(file_path, FileAccess.WRITE)
    if file:
        file.store_line("Performance Log - %s" % Time.get_datetime_string_from_system())
        file.store_line("FPS: %.1f" % _fps)
        file.store_line("HUD Update Time: %.2f ms" % (_hud_update_time * 1000.0))
        file.store_line("Draw Calls: %d" % _draw_calls)
        file.close()
```

**6. 优化后的PlayerStatusPanel.gd** (应用所有优化):

```gdscript
extends PanelContainer
class_name PlayerStatusPanel

@onready var hp_bar: ProgressBar = $VBox/HPBar
@onready var hp_label: Label = $VBox/HPBar/Label

# 脏标记和缓存(ADR-002)
var _cached_hp: int = 0
var _cached_hp_max: int = 1
var _hp_dirty: bool = false

# 批量更新管理器
var _batch_manager: BatchUpdateManager

# LOD调度器
var _lod_scheduler: LODUpdateScheduler

func _ready() -> void:
    # 获取全局管理器
    _batch_manager = get_node("/root/BatchUpdateManager")
    _lod_scheduler = get_node("/root/LODUpdateScheduler")
    
    # 注册为P0级组件(立即更新)
    _lod_scheduler.register_component(self, "P0")
    
    # 连接信号
    GameEvents.player_hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: int, max_value: int) -> void:
    # 脏标记检查
    if _cached_hp != current or _cached_hp_max != max_value:
        # 请求批量更新
        _batch_manager.request_update(self, {
            "hp": current,
            "hp_max": max_value
        })

func _process(delta: float) -> void:
    # LOD检查
    if not _lod_scheduler.should_update(self, delta):
        return
    
    # 批量更新会在BatchUpdateManager中统一应用
    pass

## 应用批量更新
func apply_batch_update(data: Dictionary) -> void:
    if "hp" in data:
        _cached_hp = data["hp"]
    if "hp_max" in data:
        _cached_hp_max = data["hp_max"]
    
    _apply_hp_update()

func _apply_hp_update() -> void:
    var start_time := Time.get_ticks_usec()
    
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
    
    # 记录性能
    var end_time := Time.get_ticks_usec()
    var update_time := (end_time - start_time) / 1_000_000.0
    
    var perf_monitor := get_node_or_null("/root/PerformanceMonitor")
    if perf_monitor:
        perf_monitor.record_hud_update_time(update_time)
```

## Alternatives Considered

### Alternative 1: 仅对象池优化

**描述**:
只实现对象池,不实现批量更新和LOD

**优点**:
- 实现简单
- 减少GC压力
- 内存占用可控

**缺点**:
- 不解决draw call过多问题
- 不解决重复更新问题
- 性能提升有限

**拒绝原因**:
对象池只解决了内存分配问题,但HUD的主要性能瓶颈是draw call和重复更新。需要综合优化方案。

### Alternative 2: 仅批量更新优化

**描述**:
只实现批量更新,不实现对象池和LOD

**优点**:
- 减少draw call
- 合并重复更新
- 实现相对简单

**缺点**:
- 不解决GC压力
- 不解决不必要的更新(需要脏标记)
- 所有组件同等对待,无优先级

**拒绝原因**:
批量更新解决了draw call问题,但不解决内存问题。且没有LOD会导致低优先级信息也频繁更新。

### Alternative 3: 完全手动优化

**描述**:
不使用通用优化框架,每个组件手动优化

**优点**:
- 最大灵活性
- 可以针对性优化
- 无框架开销

**缺点**:
- 维护成本高
- 容易遗漏优化
- 代码重复
- 难以统一性能监控

**拒绝原因**:
手动优化难以维护且容易出错。通用框架提供一致的优化模式,更易于理解和维护。

## Consequences

### Positive

1. **性能提升**:预期HUD更新时间减少50-70%
2. **GC压力降低**:对象池避免频繁内存分配
3. **Draw Call减少**:批量更新合并重复绘制
4. **可测量**:性能监控工具提供实时反馈
5. **可维护**:通用框架易于理解和扩展
6. **分级优化**:LOD确保关键信息优先更新

### Negative

1. **复杂度增加**:引入多个优化层
2. **学习曲线**:开发者需要理解优化机制
3. **调试难度**:批量更新延迟可能影响调试
4. **内存占用**:对象池预分配内存

### Risks

**风险1:过度优化**
- **描述**:优化增加的复杂度超过性能收益
- **缓解**:
  - 先实现基础HUD,性能测试后再应用优化
  - 逐步应用优化,测量每步的收益
  - 如果性能已满足预算,跳过部分优化

**风险2:对象池大小不足**
- **描述**:池容量不足导致频繁创建新对象
- **缓解**:
  - 根据实际使用情况调整池大小
  - 实现动态扩容机制
  - 性能测试验证池大小

**风险3:批量更新延迟**
- **描述**:批量更新导致UI响应延迟
- **缓解**:
  - P0级信息(HP/Qi/Poise)立即更新,不批量
  - 批量更新仅用于P1-P4级信息
  - 延迟不超过一帧(16.6ms)

**风险4:LOD更新频率不当**
- **描述**:更新频率过低导致信息滞后
- **缓解**:
  - 根据玩家反馈调整更新间隔
  - 提供配置选项让玩家自定义
  - 性能测试验证不同频率的影响

**风险5:性能监控开销**
- **描述**:性能监控本身消耗性能
- **缓解**:
  - 仅在开发模式下启用
  - 使用轻量级监控方法
  - 发布版本完全禁用

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| design/ux/hud.md | HUD更新 < 1ms/帧(战斗) | 批量更新+脏标记+LOD综合优化,预期减少50-70%更新时间 |
| design/ux/hud.md | HUD更新 < 0.5ms/帧(探索) | LOD调度器降低探索模式更新频率,P2-P4级最多每0.5秒更新 |
| design/ux/hud.md | HUD draw calls < 100 | 批量更新合并重复绘制,对象池复用减少节点数量 |
| design/ux/hud.md | 60FPS稳定 | 所有优化综合确保帧率稳定,性能监控实时验证 |
| design/ux/hud.md | 内存占用 < 50MB | 对象池预分配固定内存,避免运行时分配 |
| design/ux/hud.md | Buff/Debuff显示 | BuffIconPool复用图标,避免频繁创建/销毁 |
| design/ux/hud.md | 伤害数字飘字 | DamageNumberPool复用飘字对象 |
| design/ux/hud.md | 通知系统 | NotificationPool复用通知面板 |

## Performance Implications

**CPU**:
- 对象池开销:~0.01ms/帧(acquire/release)
- 批量更新开销:~0.05ms/帧(收集+合并+应用)
- LOD调度开销:~0.01ms/帧(检查更新间隔)
- 性能监控开销:~0.02ms/帧(仅开发模式)
- **预期总开销**:~0.07ms/帧(优化收益远大于开销)
- **预期优化收益**:减少0.5-1.0ms/帧(50-70%提升)

**Memory**:
- BuffIconPool:~200KB(20个图标 × 10KB/个)
- DamageNumberPool:~150KB(30个数字 × 5KB/个)
- NotificationPool:~100KB(5个面板 × 20KB/个)
- BatchUpdateManager:~10KB(更新队列)
- LODUpdateScheduler:~5KB(时间记录)
- **预期总开销**:~465KB(可接受)

**Load Time**:
- 对象池预分配:+0.1秒(启动时一次性)

**Network**:
- 不适用(单机游戏)

## Migration Plan

**阶段1:创建优化框架**(Story 009的一部分)
1. 创建`src/scripts/core/performance/`目录
2. 实现ObjectPool基类
3. 实现BatchUpdateManager
4. 实现LODUpdateScheduler
5. 实现PerformanceMonitor
6. 在`project.godot`中注册autoload

**阶段2:实现对象池**(Story 009)
1. 创建BuffIconPool
2. 创建DamageNumberPool
3. 创建NotificationPool
4. 修改相应UI组件使用对象池
5. 测试对象池功能

**阶段3:应用批量更新**(Story 009)
1. 修改HUD组件使用BatchUpdateManager
2. 在HUDManager中统一调用apply_updates()
3. 测试批量更新效果

**阶段4:应用LOD调度**(Story 009)
1. 为每个HUD组件注册优先级
2. 在组件的_process()中检查should_update()
3. 测试不同优先级的更新频率

**阶段5:性能验证**(Story 009)
1. 启用PerformanceMonitor
2. 运行性能测试场景
3. 验证性能指标符合预算
4. 调整优化参数

**向后兼容性**:
- 优化是可选的,可以逐步应用
- 不破坏现有信号驱动架构
- 组件可以选择性使用优化

## Validation Criteria

**功能验证**:
- [ ] ObjectPool正确分配和回收对象
- [ ] BatchUpdateManager正确收集和应用更新
- [ ] LODUpdateScheduler按预期频率调度更新
- [ ] PerformanceMonitor正确显示性能指标
- [ ] 所有优化不影响UI功能正确性

**性能验证**:
- [ ] 战斗中HUD更新 < 1ms/帧
- [ ] 探索中HUD更新 < 0.5ms/帧
- [ ] HUD draw calls < 100
- [ ] 60FPS稳定(战斗和探索场景)
- [ ] 内存占用 < 50MB

**压力测试**:
- [ ] 100个敌人同时存在
- [ ] 50个Buff/Debuff同时显示
- [ ] 30个伤害数字同时飘字
- [ ] 连续战斗1小时无性能下降

**优化收益验证**:
- [ ] 对象池减少GC次数 > 80%
- [ ] 批量更新减少draw call > 50%
- [ ] LOD减少低优先级更新 > 60%
- [ ] 总体性能提升 > 50%

## Related Decisions

- **ADR-001**: Core Architecture Decisions — 确立了性能优先的原则
- **ADR-002**: HUD架构模式 — 定义了脏标记基础,本ADR扩展优化
- **ADR-003**: Data Binding Mechanism — 定义了信号结构,本ADR优化信号处理