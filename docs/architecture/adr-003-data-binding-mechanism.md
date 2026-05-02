# ADR-003: 数据绑定机制

## Status
Accepted

## Date
2026-04-30

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI |
| **Knowledge Risk** | LOW — 使用标准Godot信号系统,无post-cutoff特性依赖 |
| **References Consulted** | `docs/engine-reference/godot/modules/ui.md`, `docs/engine-reference/godot/VERSION.md` |
| **Post-Cutoff APIs Used** | None — 仅使用Godot 4.0+标准信号系统 |
| **Verification Required** | 验证所有信号参数类型正确,信号命名符合Godot命名规范 |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (HUD架构模式 — 必须先Accepted,本ADR实现其定义的GameEvents接口) |
| **Enables** | ADR-004 (性能优化策略 — 需要本ADR定义的信号结构来实现批量更新) |
| **Blocks** | Epic: hud-system — 所有HUD stories需要这些信号定义才能实现 |
| **Ordering Note** | 必须在ADR-002 Accepted后创建,必须在创建HUD stories前Accepted |

## Context

### Problem Statement

ADR-002确立了信号驱动架构,使用`GameEvents`全局信号总线作为游戏逻辑层和UI层之间的中介。现在需要定义:

1. **信号结构**:GameEvents应该包含哪些信号?如何组织?
2. **信号命名**:如何命名信号以保持一致性和可读性?
3. **参数类型**:每个信号应该传递什么参数?类型是什么?
4. **发射时机**:每个信号应该在什么时候发射?频率如何?
5. **信号分组**:如何组织信号以便维护和扩展?

这些定义将成为游戏系统和HUD组件之间的**接口契约**,必须清晰、完整、类型安全。

### Constraints

**技术约束**:
- 必须使用Godot 4.6的类型化信号(typed signals)
- 必须遵循Godot命名规范(snake_case)
- 信号参数必须使用强类型(避免Variant)
- 信号发射频率必须符合性能预算(<1ms/帧)

**设计约束**(来自design/ux/hud.md):
- 必须覆盖P0-P4所有优先级的HUD信息
- 必须支持战斗/探索两种模式
- 必须支持角色状态、战斗信息、探索导航、系统功能四大类信息

**架构约束**(来自ADR-002):
- 所有信号必须在GameEvents单例中定义
- 游戏系统通过GameEvents发射信号
- HUD组件通过GameEvents监听信号
- 避免直接引用,保持松耦合

### Requirements

**必须定义的信号类别**:

1. **角色状态信号**(P0级):
   - HP、Qi、Poise变化
   - 等级、经验变化
   - 境界变化
   - 队友状态变化

2. **战斗信息信号**(P1级):
   - 战斗开始/结束
   - 回合变化
   - 行动顺序更新
   - 连击值变化
   - 连携槽变化
   - 敌人选中/信息更新

3. **状态效果信号**(P1级):
   - Buff添加/移除/更新
   - Debuff添加/移除/更新
   - Down/Break状态变化

4. **探索导航信号**(P3级):
   - 任务更新/完成
   - 位置变化
   - 区域切换
   - 奇遇触发

5. **系统功能信号**(P3-P4级):
   - 物品获得/使用
   - 技能解锁/冷却
   - 成长提示(可用点数)
   - 通知消息

**性能要求**:
- 高频信号(HP/Qi/Poise): 可能每帧发射,必须轻量
- 中频信号(回合/连击): 每0.1-1秒发射
- 低频信号(任务/成就): 按需发射,可以携带更多数据

**类型安全要求**:
- 所有信号参数必须类型化
- 使用自定义类型(如EnemyData)而非Dictionary
- 避免使用Variant或Any类型

## Decision

**采用命名空间前缀的扁平化信号结构**

### 核心决策

1. **扁平化结构**:所有信号直接在GameEvents中定义,不使用嵌套类或分组对象
   - 优点:简单直接,易于访问(`GameEvents.player_hp_changed`)
   - 缺点:信号数量多时可能显得混乱
   - 缓解:使用命名空间前缀组织

2. **命名空间前缀**:使用前缀区分信号类别
   - `player_*`: 主角状态信号
   - `party_*`: 队友状态信号
   - `combat_*`: 战斗系统信号
   - `enemy_*`: 敌人相关信号
   - `buff_*`: 状态效果信号
   - `quest_*`: 任务系统信号
   - `nav_*`: 导航系统信号
   - `item_*`: 物品系统信号
   - `skill_*`: 技能系统信号
   - `system_*`: 系统级信号

3. **类型化参数**:所有信号使用强类型参数
   - 基础类型:`int`, `float`, `bool`, `String`
   - 自定义类型:`EnemyData`, `BuffData`, `QuestData`等
   - 避免:`Variant`, `Dictionary`, `Array`(除非必要)

4. **信号命名规范**:
   - 动词过去式:`*_changed`, `*_added`, `*_removed`, `*_updated`
   - 事件式:`combat_started`, `combat_ended`, `level_up`
   - 状态式:`enemy_selected`, `quest_completed`

### Architecture Diagram

```
GameEvents (Autoload Singleton)
├── Player Signals (player_*)
│   ├── player_hp_changed(current: int, max_value: int)
│   ├── player_qi_changed(current: int, max_value: int)
│   ├── player_poise_changed(current: int, max_value: int)
│   ├── player_level_up(new_level: int, old_level: int)
│   ├── player_exp_changed(current: int, to_next: int)
│   ├── player_realm_changed(new_realm: String, old_realm: String)
│   └── player_attribute_points_changed(available: int)
│
├── Party Signals (party_*)
│   ├── party_member_hp_changed(member_id: String, current: int, max_value: int)
│   ├── party_member_added(member_id: String, member_name: String)
│   ├── party_member_removed(member_id: String)
│   └── party_member_downed(member_id: String, is_downed: bool)
│
├── Combat Signals (combat_*)
│   ├── combat_started()
│   ├── combat_ended(victory: bool, rewards: Dictionary)
│   ├── combat_turn_changed(turn_number: int)
│   ├── combat_action_queue_updated(queue: Array[ActionQueueEntry])
│   ├── combat_combo_changed(count: int, multiplier: float)
│   ├── combat_link_gauge_changed(current: int, max_value: int)
│   └── combat_mode_changed(mode: String)
│
├── Enemy Signals (enemy_*)
│   ├── enemy_selected(enemy: EnemyData)
│   ├── enemy_deselected()
│   ├── enemy_hp_changed(enemy_id: String, current: int, max_value: int)
│   ├── enemy_weakness_revealed(enemy_id: String, element: String)
│   ├── enemy_down_state_changed(enemy_id: String, is_down: bool)
│   └── enemy_break_state_changed(enemy_id: String, is_broken: bool)
│
├── Buff/Debuff Signals (buff_*)
│   ├── buff_added(target_id: String, buff: BuffData)
│   ├── buff_removed(target_id: String, buff_id: String)
│   ├── buff_updated(target_id: String, buff_id: String, remaining_turns: int)
│   ├── debuff_added(target_id: String, debuff: BuffData)
│   ├── debuff_removed(target_id: String, debuff_id: String)
│   └── debuff_updated(target_id: String, debuff_id: String, remaining_turns: int)
│
├── Quest Signals (quest_*)
│   ├── quest_started(quest: QuestData)
│   ├── quest_updated(quest_id: String, progress: Dictionary)
│   ├── quest_completed(quest_id: String, rewards: Dictionary)
│   ├── quest_failed(quest_id: String, reason: String)
│   └── quest_objective_updated(quest_id: String, objective_id: String, progress: int, total: int)
│
├── Navigation Signals (nav_*)
│   ├── nav_position_changed(position: Vector2)
│   ├── nav_area_entered(area_name: String, area_level: int)
│   ├── nav_area_exited(area_name: String)
│   ├── nav_poi_discovered(poi_id: String, poi_name: String, position: Vector2)
│   └── nav_encounter_triggered(encounter_type: String)
│
├── Item Signals (item_*)
│   ├── item_obtained(item_id: String, quantity: int)
│   ├── item_used(item_id: String, quantity: int)
│   ├── item_equipped(item_id: String, slot: String)
│   ├── item_unequipped(item_id: String, slot: String)
│   └── item_hotbar_changed(slot: int, item_id: String, quantity: int)
│
├── Skill Signals (skill_*)
│   ├── skill_unlocked(skill_id: String, skill_name: String)
│   ├── skill_cooldown_started(skill_id: String, cooldown_turns: int)
│   ├── skill_cooldown_updated(skill_id: String, remaining_turns: int)
│   ├── skill_cooldown_finished(skill_id: String)
│   └── skill_points_changed(available: int)
│
└── System Signals (system_*)
    ├── system_notification(message: String, type: String, duration: float)
    ├── system_mode_changed(mode: String)
    ├── system_save_completed()
    ├── system_save_failed(error: String)
    └── system_achievement_unlocked(achievement_id: String, achievement_name: String)
```

### Key Interfaces

**GameEvents.gd** (完整信号定义):

```gdscript
extends Node
class_name GameEvents

# ============================================================================
# PLAYER SIGNALS (P0级 - 核心生存信息)
# ============================================================================

## 主角生命值变化
## @param current: 当前HP值
## @param max_value: 最大HP值
## 发射时机: HP值改变时(受伤、治疗、升级等)
## 发射频率: 高频(战斗中可能每帧)
signal player_hp_changed(current: int, max_value: int)

## 主角内力值变化
## @param current: 当前Qi值
## @param max_value: 最大Qi值
## 发射时机: Qi值改变时(使用技能、恢复、升级等)
## 发射频率: 高频(战斗中频繁)
signal player_qi_changed(current: int, max_value: int)

## 主角架势值变化
## @param current: 当前Poise值
## @param max_value: 最大Poise值
## 发射时机: Poise值改变时(受击、格挡、恢复等)
## 发射频率: 高频(战斗中频繁)
signal player_poise_changed(current: int, max_value: int)

## 主角升级
## @param new_level: 新等级
## @param old_level: 旧等级
## 发射时机: 经验值达到升级阈值时
## 发射频率: 低频(每次升级)
signal player_level_up(new_level: int, old_level: int)

## 主角经验值变化
## @param current: 当前经验值
## @param to_next: 距离下一级所需经验值
## 发射时机: 获得经验时
## 发射频率: 中频(战斗结束、任务完成等)
signal player_exp_changed(current: int, to_next: int)

## 主角境界变化
## @param new_realm: 新境界名称
## @param old_realm: 旧境界名称
## 发射时机: 境界突破成功时
## 发射频率: 极低频(重要里程碑)
signal player_realm_changed(new_realm: String, old_realm: String)

## 主角可用属性点变化
## @param available: 可用属性点数量
## 发射时机: 升级获得属性点或分配属性点时
## 发射频率: 低频
signal player_attribute_points_changed(available: int)

# ============================================================================
# PARTY SIGNALS (P0级 - 队友状态)
# ============================================================================

## 队友生命值变化
## @param member_id: 队友唯一ID
## @param current: 当前HP值
## @param max_value: 最大HP值
## 发射时机: 队友HP改变时
## 发射频率: 高频(战斗中)
signal party_member_hp_changed(member_id: String, current: int, max_value: int)

## 队友加入队伍
## @param member_id: 队友唯一ID
## @param member_name: 队友名称
## 发射时机: 队友加入队伍时
## 发射频率: 极低频
signal party_member_added(member_id: String, member_name: String)

## 队友离开队伍
## @param member_id: 队友唯一ID
## 发射时机: 队友离开队伍时
## 发射频率: 极低频
signal party_member_removed(member_id: String)

## 队友倒地状态变化
## @param member_id: 队友唯一ID
## @param is_downed: 是否倒地
## 发射时机: 队友倒地或复活时
## 发射频率: 低频(战斗中)
signal party_member_downed(member_id: String, is_downed: bool)

# ============================================================================
# COMBAT SIGNALS (P1级 - 战斗核心信息)
# ============================================================================

## 战斗开始
## 发射时机: 进入战斗状态时
## 发射频率: 低频(每次战斗开始)
signal combat_started()

## 战斗结束
## @param victory: 是否胜利
## @param rewards: 奖励数据(经验、金钱、物品等)
## 发射时机: 战斗结束时
## 发射频率: 低频(每次战斗结束)
signal combat_ended(victory: bool, rewards: Dictionary)

## 战斗回合变化
## @param turn_number: 当前回合数
## 发射时机: 回合开始时
## 发射频率: 中频(每回合)
signal combat_turn_changed(turn_number: int)

## 行动顺序队列更新
## @param queue: 行动队列数组,每个元素包含{unit_id, unit_name, is_player, icon_path}
## 发射时机: 行动顺序改变时(速度变化、插队等)
## 发射频率: 中频(战斗中)
signal combat_action_queue_updated(queue: Array[Dictionary])

## 连击值变化
## @param count: 当前连击数
## @param multiplier: 连击伤害倍率
## 发射时机: 连击数改变时
## 发射频率: 高频(战斗中每次攻击)
signal combat_combo_changed(count: int, multiplier: float)

## 连携槽变化
## @param current: 当前连携值
## @param max_value: 最大连携值
## 发射时机: 连携槽蓄力或消耗时
## 发射频率: 中频(战斗中)
signal combat_link_gauge_changed(current: int, max_value: int)

## 战斗模式变化(用于特殊战斗阶段,如Boss第二阶段)
## @param mode: 模式名称(如"normal", "boss_phase2")
## 发射时机: 战斗模式切换时
## 发射频率: 低频
signal combat_mode_changed(mode: String)

# ============================================================================
# ENEMY SIGNALS (P1级 - 敌人信息)
# ============================================================================

## 敌人被选中
## @param enemy: 敌人数据对象(包含id, name, hp, max_hp, weaknesses等)
## 发射时机: 玩家选中敌人时
## 发射频率: 中频(战斗中切换目标)
signal enemy_selected(enemy: Dictionary)

## 取消选中敌人
## 发射时机: 取消目标选择时
## 发射频率: 低频
signal enemy_deselected()

## 敌人生命值变化
## @param enemy_id: 敌人唯一ID
## @param current: 当前HP值
## @param max_value: 最大HP值
## 发射时机: 敌人HP改变时
## 发射频率: 高频(战斗中)
signal enemy_hp_changed(enemy_id: String, current: int, max_value: int)

## 敌人弱点揭示
## @param enemy_id: 敌人唯一ID
## @param element: 弱点元素("金"/"木"/"水"/"火"/"土")
## 发射时机: 玩家发现敌人弱点时
## 发射频率: 低频(每个敌人每个弱点只发射一次)
signal enemy_weakness_revealed(enemy_id: String, element: String)

## 敌人Down状态变化
## @param enemy_id: 敌人唯一ID
## @param is_down: 是否处于Down状态
## 发射时机: 敌人进入或退出Down状态时
## 发射频率: 低频(战斗中)
signal enemy_down_state_changed(enemy_id: String, is_down: bool)

## 敌人Break状态变化
## @param enemy_id: 敌人唯一ID
## @param is_broken: 是否处于Break状态
## 发射时机: 敌人进入或退出Break状态时
## 发射频率: 低频(战斗中)
signal enemy_break_state_changed(enemy_id: String, is_broken: bool)

# ============================================================================
# BUFF/DEBUFF SIGNALS (P1级 - 状态效果)
# ============================================================================

## Buff添加
## @param target_id: 目标ID(玩家/队友/敌人)
## @param buff: Buff数据{id, name, icon_path, duration, stacks}
## 发射时机: Buff添加到目标时
## 发射频率: 中频(战斗中)
signal buff_added(target_id: String, buff: Dictionary)

## Buff移除
## @param target_id: 目标ID
## @param buff_id: Buff唯一ID
## 发射时机: Buff持续时间结束或被驱散时
## 发射频率: 中频(战斗中)
signal buff_removed(target_id: String, buff_id: String)

## Buff更新(持续时间或层数变化)
## @param target_id: 目标ID
## @param buff_id: Buff唯一ID
## @param remaining_turns: 剩余回合数
## 发射时机: 每回合开始时
## 发射频率: 中频(战斗中每回合)
signal buff_updated(target_id: String, buff_id: String, remaining_turns: int)

## Debuff添加
## @param target_id: 目标ID
## @param debuff: Debuff数据{id, name, icon_path, duration, stacks}
## 发射时机: Debuff添加到目标时
## 发射频率: 中频(战斗中)
signal debuff_added(target_id: String, debuff: Dictionary)

## Debuff移除
## @param target_id: 目标ID
## @param debuff_id: Debuff唯一ID
## 发射时机: Debuff持续时间结束或被驱散时
## 发射频率: 中频(战斗中)
signal debuff_removed(target_id: String, debuff_id: String)

## Debuff更新(持续时间或层数变化)
## @param target_id: 目标ID
## @param debuff_id: Debuff唯一ID
## @param remaining_turns: 剩余回合数
## 发射时机: 每回合开始时
## 发射频率: 中频(战斗中每回合)
signal debuff_updated(target_id: String, debuff_id: String, remaining_turns: int)

# ============================================================================
# QUEST SIGNALS (P3级 - 任务系统)
# ============================================================================

## 任务开始
## @param quest: 任务数据{id, name, description, objectives}
## 发射时机: 接受任务时
## 发射频率: 低频
signal quest_started(quest: Dictionary)

## 任务更新
## @param quest_id: 任务ID
## @param progress: 进度数据{objective_id: progress_value}
## 发射时机: 任务目标进度改变时
## 发射频率: 中频
signal quest_updated(quest_id: String, progress: Dictionary)

## 任务完成
## @param quest_id: 任务ID
## @param rewards: 奖励数据{exp, gold, items}
## 发射时机: 任务所有目标完成时
## 发射频率: 低频
signal quest_completed(quest_id: String, rewards: Dictionary)

## 任务失败
## @param quest_id: 任务ID
## @param reason: 失败原因
## 发射时机: 任务失败条件触发时
## 发射频率: 低频
signal quest_failed(quest_id: String, reason: String)

## 任务目标更新
## @param quest_id: 任务ID
## @param objective_id: 目标ID
## @param progress: 当前进度
## @param total: 总目标数
## 发射时机: 单个目标进度改变时
## 发射频率: 中频
signal quest_objective_updated(quest_id: String, objective_id: String, progress: int, total: int)

# ============================================================================
# NAVIGATION SIGNALS (P3级 - 导航系统)
# ============================================================================

## 玩家位置变化
## @param position: 世界坐标
## 发射时机: 玩家移动时
## 发射频率: 高频(每帧或每N帧)
## 注意: 可能需要节流,避免过于频繁
signal nav_position_changed(position: Vector2)

## 进入新区域
## @param area_name: 区域名称
## @param area_level: 区域推荐等级
## 发射时机: 玩家进入新区域时
## 发射频率: 低频
signal nav_area_entered(area_name: String, area_level: int)

## 离开区域
## @param area_name: 区域名称
## 发射时机: 玩家离开区域时
## 发射频率: 低频
signal nav_area_exited(area_name: String)

## 发现兴趣点(POI)
## @param poi_id: 兴趣点ID
## @param poi_name: 兴趣点名称
## @param position: 兴趣点位置
## 发射时机: 玩家发现新的兴趣点时
## 发射频率: 低频
signal nav_poi_discovered(poi_id: String, poi_name: String, position: Vector2)

## 奇遇触发
## @param encounter_type: 奇遇类型("combat"/"treasure"/"npc"等)
## 发射时机: 奇遇触发时
## 发射频率: 低频
signal nav_encounter_triggered(encounter_type: String)

# ============================================================================
# ITEM SIGNALS (P2-P3级 - 物品系统)
# ============================================================================

## 获得物品
## @param item_id: 物品ID
## @param quantity: 数量
## 发射时机: 获得物品时(拾取、购买、奖励等)
## 发射频率: 中频
signal item_obtained(item_id: String, quantity: int)

## 使用物品
## @param item_id: 物品ID
## @param quantity: 使用数量
## 发射时机: 使用物品时
## 发射频率: 中频
signal item_used(item_id: String, quantity: int)

## 装备物品
## @param item_id: 物品ID
## @param slot: 装备槽位("weapon"/"armor"/"accessory"等)
## 发射时机: 装备物品时
## 发射频率: 低频
signal item_equipped(item_id: String, slot: String)

## 卸下装备
## @param item_id: 物品ID
## @param slot: 装备槽位
## 发射时机: 卸下装备时
## 发射频率: 低频
signal item_unequipped(item_id: String, slot: String)

## 快捷栏变化
## @param slot: 快捷栏槽位(0-9)
## @param item_id: 物品ID(空槽位为"")
## @param quantity: 物品数量
## 发射时机: 快捷栏内容改变时
## 发射频率: 低频
signal item_hotbar_changed(slot: int, item_id: String, quantity: int)

# ============================================================================
# SKILL SIGNALS (P2-P3级 - 技能系统)
# ============================================================================

## 技能解锁
## @param skill_id: 技能ID
## @param skill_name: 技能名称
## 发射时机: 学习新技能时
## 发射频率: 低频
signal skill_unlocked(skill_id: String, skill_name: String)

## 技能冷却开始
## @param skill_id: 技能ID
## @param cooldown_turns: 冷却回合数
## 发射时机: 使用技能后进入冷却时
## 发射频率: 中频(战斗中)
signal skill_cooldown_started(skill_id: String, cooldown_turns: int)

## 技能冷却更新
## @param skill_id: 技能ID
## @param remaining_turns: 剩余冷却回合数
## 发射时机: 每回合开始时
## 发射频率: 中频(战斗中每回合)
signal skill_cooldown_updated(skill_id: String, remaining_turns: int)

## 技能冷却结束
## @param skill_id: 技能ID
## 发射时机: 冷却时间结束时
## 发射频率: 中频(战斗中)
signal skill_cooldown_finished(skill_id: String)

## 可用技能点变化
## @param available: 可用技能点数量
## 发射时机: 获得或消耗技能点时
## 发射频率: 低频
signal skill_points_changed(available: int)

# ============================================================================
# SYSTEM SIGNALS (P4级 - 系统功能)
# ============================================================================

## 系统通知
## @param message: 通知消息内容
## @param type: 通知类型("info"/"warning"/"error"/"success")
## @param duration: 显示时长(秒),0表示需要手动关闭
## 发射时机: 需要向玩家显示通知时
## 发射频率: 中频
signal system_notification(message: String, type: String, duration: float)

## 系统模式变化
## @param mode: 模式名称("exploration"/"combat"/"menu"/"dialogue")
## 发射时机: 游戏模式切换时
## 发射频率: 低频
signal system_mode_changed(mode: String)

## 保存完成
## 发射时机: 游戏保存成功时
## 发射频率: 低频
signal system_save_completed()

## 保存失败
## @param error: 错误信息
## 发射时机: 游戏保存失败时
## 发射频率: 极低频
signal system_save_failed(error: String)

## 成就解锁
## @param achievement_id: 成就ID
## @param achievement_name: 成就名称
## 发射时机: 解锁成就时
## 发射频率: 低频
signal system_achievement_unlocked(achievement_id: String, achievement_name: String)
```

**信号使用示例**:

```gdscript
# 游戏系统发射信号
# 在CombatSystem.gd中
func apply_damage(target: Character, amount: int) -> void:
    target.hp -= amount
    
    if target.is_player:
        GameEvents.player_hp_changed.emit(target.hp, target.max_hp)
    elif target.is_party_member:
        GameEvents.party_member_hp_changed.emit(target.id, target.hp, target.max_hp)
    else:
        GameEvents.enemy_hp_changed.emit(target.id, target.hp, target.max_hp)

# HUD组件监听信号
# 在PlayerStatusPanel.gd中
func _ready() -> void:
    GameEvents.player_hp_changed.connect(_on_hp_changed)
    GameEvents.player_qi_changed.connect(_on_qi_changed)
    GameEvents.player_poise_changed.connect(_on_poise_changed)

func _on_hp_changed(current: int, max_value: int) -> void:
    # 脏标记检查
    if _cached_hp != current or _cached_hp_max != max_value:
        _cached_hp = current
        _cached_hp_max = max_value
        _hp_dirty = true
```

## Alternatives Considered

### Alternative 1: 分组信号结构

**描述**:
使用嵌套类或对象来组织信号,例如:
```gdscript
# GameEvents.gd
var player: PlayerSignals = PlayerSignals.new()
var combat: CombatSignals = CombatSignals.new()
var enemy: EnemySignals = EnemySignals.new()

# PlayerSignals.gd
class_name PlayerSignals
signal hp_changed(current: int, max_value: int)
signal qi_changed(current: int, max_value: int)
```

访问方式:`GameEvents.player.hp_changed.connect(...)`

**优点**:
- 更好的组织性,信号按类别分组
- 避免命名空间污染
- 更容易找到相关信号

**缺点**:
- 访问路径更长(`GameEvents.player.hp_changed` vs `GameEvents.player_hp_changed`)
- 需要额外的类定义和实例化
- Godot信号系统不原生支持嵌套,需要自定义实现
- 增加复杂度,不符合Godot惯例

**拒绝原因**:
Godot的信号系统设计为扁平化使用,嵌套结构增加了不必要的复杂度。命名空间前缀已经足够提供组织性,同时保持简单性。

### Alternative 2: 单一通用信号

**描述**:
使用少量通用信号,通过参数区分类型:
```gdscript
signal state_changed(category: String, key: String, value: Variant)
signal event_triggered(event_type: String, data: Dictionary)
```

使用方式:
```gdscript
GameEvents.state_changed.emit("player", "hp", {"current": 80, "max": 100})
GameEvents.event_triggered.emit("combat_started", {})
```

**优点**:
- 信号数量少,易于管理
- 高度灵活,可以传递任意数据
- 易于扩展,不需要修改GameEvents

**缺点**:
- 失去类型安全,参数为Variant或Dictionary
- 难以发现可用的信号和参数结构
- 监听者需要字符串匹配,容易出错
- 性能差,需要解析Dictionary
- 违反Godot最佳实践(强类型)

**拒绝原因**:
失去类型安全是致命缺陷。Godot 4.6强调类型化,使用Variant和Dictionary违背了引擎设计哲学,且容易引入运行时错误。

### Alternative 3: 直接使用自定义Resource类

**描述**:
为每种数据类型创建Resource类,信号传递Resource对象:
```gdscript
class_name PlayerState extends Resource
var hp: int
var max_hp: int
var qi: int
var max_qi: int
# ...

signal player_state_changed(state: PlayerState)
```

**优点**:
- 强类型,类型安全
- 可以一次传递多个相关数据
- Resource可以序列化,便于保存

**缺点**:
- 过度设计,简单的数值变化不需要完整对象
- 性能开销大,每次变化都创建新Resource实例
- 监听者难以判断具体哪个字段变化了
- 违反单一职责,一个信号承载过多信息

**拒绝原因**:
对于简单的数值变化(如HP从80变为75),创建完整的Resource对象是过度设计。信号应该传递最小必要信息,让监听者决定如何处理。

## Consequences

### Positive

1. **类型安全**:所有信号参数强类型,编译时检查,减少运行时错误
2. **清晰的接口契约**:每个信号的用途、参数、发射时机都有明确文档
3. **易于发现**:IDE自动补全可以列出所有可用信号
4. **命名一致性**:命名空间前缀提供清晰的组织结构
5. **性能可控**:每个信号独立,可以精确控制监听和发射
6. **易于测试**:可以mock特定信号进行单元测试
7. **符合Godot惯例**:使用引擎推荐的信号模式

### Negative

1. **信号数量多**:GameEvents包含50+个信号,可能显得冗长
2. **维护成本**:新增HUD信息需要添加新信号
3. **文档负担**:每个信号都需要详细文档说明
4. **学习曲线**:新开发者需要熟悉所有信号

### Risks

**风险1:信号命名冲突**
- **描述**:未来新增信号可能与现有信号命名冲突
- **缓解**:
  - 使用命名空间前缀减少冲突
  - 代码审查检查新信号命名
  - 维护信号命名规范文档

**风险2:信号参数变化导致兼容性问题**
- **描述**:修改信号参数类型或数量会破坏现有监听者
- **缓解**:
  - 信号参数一旦定义,尽量不修改
  - 如需修改,创建新信号并标记旧信号为deprecated
  - 使用可选参数(默认值)实现向后兼容

**风险3:高频信号性能影响**
- **描述**:某些信号(如player_hp_changed)可能每帧发射,影响性能
- **缓解**:
  - 在发射端实现脏标记,避免重复发射相同值
  - 在监听端实现脏标记,避免重复处理
  - 性能测试验证高频信号开销
  - 必要时实现信号节流(throttle)

**风险4:信号发射顺序依赖**
- **描述**:某些场景下多个信号的发射顺序可能影响结果
- **缓解**:
  - 设计无状态的信号处理函数
  - 避免信号处理函数之间的依赖
  - 文档明确说明信号发射顺序(如有必要)

**风险5:Dictionary参数缺乏类型安全**
- **描述**:某些信号使用Dictionary参数(如quest, enemy),失去部分类型安全
- **缓解**:
  - 在文档中明确Dictionary的结构
  - 考虑未来创建自定义类型(如QuestData, EnemyData)替代Dictionary
  - 在发射端验证Dictionary结构
  - 在监听端进行防御性检查

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| design/ux/hud.md | P0级信息(HP/Qi/Poise)必须始终可见 | 定义player_hp_changed, player_qi_changed, player_poise_changed高频信号 |
| design/ux/hud.md | P1级战斗信息(行动队列、连击)战斗中显示 | 定义combat_action_queue_updated, combat_combo_changed等战斗信号 |
| design/ux/hud.md | P2级战术辅助(敌人信息、技能冷却)按需显示 | 定义enemy_selected, skill_cooldown_*等按需信号 |
| design/ux/hud.md | P3级探索辅助(任务、导航)可折叠 | 定义quest_*, nav_*等探索信号 |
| design/ux/hud.md | P4级系统功能(菜单、通知) | 定义system_*系统级信号 |
| design/ux/hud.md | 战斗/探索模式切换 | 定义combat_started, combat_ended, system_mode_changed信号 |
| design/ux/hud.md | Buff/Debuff状态显示 | 定义buff_added, buff_removed, debuff_*等状态效果信号 |
| design/ux/hud.md | 队友状态显示 | 定义party_member_*系列信号 |
| design/ux/hud.md | 敌人弱点和Down/Break状态 | 定义enemy_weakness_revealed, enemy_down_state_changed等信号 |
| design/ux/hud.md | 成长提示(升级、境界、可用点数) | 定义player_level_up, player_realm_changed, player_attribute_points_changed等信号 |

## Performance Implications

**CPU**:
- 信号发射开销:~0.01ms/信号(Godot内置优化)
- 高频信号(HP/Qi/Poise):可能每帧发射,总开销~0.03ms/帧
- 中频信号(回合/连击):每0.1-1秒发射,开销可忽略
- 低频信号(任务/成就):按需发射,开销可忽略
- **预期总开销**:< 0.1ms/帧(符合<1ms预算)

**Memory**:
- GameEvents单例:~2KB(信号定义)
- 信号连接:~100字节/连接 × 约100个连接 = ~10KB
- 信号参数(临时):基础类型开销极小,Dictionary参数~1KB/次
- **预期总开销**:< 15KB(可忽略)

**Load Time**:
- 无影响(信号在运行时连接)

**Network**:
- 不适用(单机游戏)

**优化建议**:
1. 在发射端实现脏标记,避免重复发射相同值
2. 高频信号(如nav_position_changed)考虑节流,每N帧发射一次
3. Dictionary参数尽量精简,只传递必要数据
4. 考虑对象池复用Dictionary对象(如果性能测试发现瓶颈)

## Migration Plan

**阶段1:创建GameEvents单例**(Story 001的一部分)
1. 创建`src/scripts/core/game_events.gd`
2. 定义所有信号(复制本ADR的Key Interfaces部分)
3. 在`project.godot`中注册为autoload:`GameEvents`
4. 验证:在测试场景中发射和监听一个信号

**阶段2:游戏系统集成**(各Story实现时)
1. 修改游戏系统(CombatSystem, PlayerData等)发射相应信号
2. 在状态变化时调用`GameEvents.signal_name.emit(...)`
3. 实现脏标记,避免重复发射相同值
4. 单元测试验证信号正确发射

**阶段3:HUD组件集成**(Story 002-008)
1. 在HUD组件的`_ready()`中连接信号
2. 实现信号处理函数,更新UI显示
3. 实现脏标记,避免重复更新
4. 手动测试验证UI正确响应信号

**阶段4:性能验证**(Story 009)
1. 使用Godot Profiler测量信号开销
2. 验证高频信号不超过性能预算
3. 必要时实现节流或批量更新
4. 压力测试(大量敌人、大量Buff等)

**向后兼容性**:
- 这是新系统,无需考虑向后兼容
- 未来如需修改信号,遵循deprecation流程

## Validation Criteria

**功能验证**:
- [ ] GameEvents单例正确注册并可全局访问
- [ ] 所有50+个信号定义正确,参数类型正确
- [ ] 每个信号都有完整的文档注释
- [ ] 信号命名符合命名规范(前缀+动词过去式)
- [ ] 游戏系统正确发射信号
- [ ] HUD组件正确监听和响应信号

**类型安全验证**:
- [ ] 所有信号参数使用强类型(int, float, String, Dictionary等)
- [ ] 无Variant类型参数(除非必要)
- [ ] Dictionary参数有明确的结构文档
- [ ] IDE自动补全正确显示信号和参数类型

**性能验证**:
- [ ] 高频信号(HP/Qi/Poise)开销 < 0.05ms/帧
- [ ] 总信号开销 < 0.1ms/帧
- [ ] 无内存泄漏(运行1小时内存稳定)
- [ ] 压力测试通过(100个敌人,50个Buff同时存在)

**文档验证**:
- [ ] 每个信号有完整的文档注释
- [ ] 文档包含:用途、参数说明、发射时机、发射频率
- [ ] 信号分组清晰(通过注释分隔)
- [ ] 使用示例代码正确且可运行

**集成验证**:
- [ ] 所有HUD组件正确响应信号
- [ ] 战斗/探索模式切换正常工作
- [ ] 无信号连接泄漏
- [ ] 无信号发射顺序问题

## Related Decisions

- **ADR-001**: Core Architecture Decisions — 确立了信号系统用于松耦合的原则
- **ADR-002**: HUD架构模式 — 定义了GameEvents作为信号总线的架构,本ADR实现其接口
- **ADR-004** (待创建): Performance Optimization Strategy — 将使用本ADR定义的信号实现批量更新和对象池