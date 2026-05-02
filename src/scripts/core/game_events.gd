extends Node
## GameEvents - 全局信号总线 (Autoload Singleton)
##
## 作为游戏逻辑层和UI层之间的中介,采用信号驱动架构实现松耦合。
## 所有HUD相关的状态变化通过此单例的信号传递。
##
## 架构来源: ADR-002 (HUD架构模式), ADR-003 (数据绑定机制)
##
## 使用规范:
## - 游戏系统通过 GameEvents.signal_name.emit(...) 发射信号
## - HUD组件通过 GameEvents.signal_name.connect(callback) 监听信号
## - 信号命名遵循: 命名空间前缀 + 动词过去式 (snake_case)
##
## 性能要求 (来自 design/ux/hud.md):
## - HUD更新 < 1ms/帧 (战斗中)
## - HUD更新 < 0.5ms/帧 (探索中)
## - 60FPS 稳定

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
signal player_attribute_points_changed(available: int)

# ============================================================================
# PARTY SIGNALS (P0级 - 队友状态)
# ============================================================================

## 队友生命值变化
signal party_member_hp_changed(member_id: String, current: int, max_value: int)

## 队友加入队伍
signal party_member_added(member_id: String, member_name: String)

## 队友离开队伍
signal party_member_removed(member_id: String)

## 队友倒地状态变化
signal party_member_downed(member_id: String, is_downed: bool)

# ============================================================================
# COMBAT SIGNALS (P1级 - 战斗核心信息)
# ============================================================================

## 战斗开始
signal combat_started()

## 战斗结束
## @param victory: 是否胜利
## @param rewards: 奖励数据(经验、金钱、物品等)
signal combat_ended(victory: bool, rewards: Dictionary)

## 战斗回合变化
signal combat_turn_changed(turn_number: int)

## 行动顺序队列更新
## @param queue: 行动队列数组,每个元素包含{unit_id, unit_name, is_player, icon_path}
signal combat_action_queue_updated(queue: Array)

## 连击值变化
signal combat_combo_changed(count: int, multiplier: float)

## 连携槽变化
signal combat_link_gauge_changed(current: int, max_value: int)

## 战斗模式变化(用于特殊战斗阶段,如Boss第二阶段)
signal combat_mode_changed(mode: String)

# ============================================================================
# ENEMY SIGNALS (P1级 - 敌人信息)
# ============================================================================

## 敌人被选中
signal enemy_selected(enemy: Dictionary)

## 取消选中敌人
signal enemy_deselected()

## 敌人生命值变化
signal enemy_hp_changed(enemy_id: String, current: int, max_value: int)

## 敌人弱点揭示
signal enemy_weakness_revealed(enemy_id: String, element: String)

## 敌人Down状态变化
signal enemy_down_state_changed(enemy_id: String, is_down: bool)

## 敌人Break状态变化
signal enemy_break_state_changed(enemy_id: String, is_broken: bool)

# ============================================================================
# BUFF/DEBUFF SIGNALS (P1级 - 状态效果)
# ============================================================================

## Buff添加
signal buff_added(target_id: String, buff: Dictionary)

## Buff移除
signal buff_removed(target_id: String, buff_id: String)

## Buff更新(持续时间或层数变化)
signal buff_updated(target_id: String, buff_id: String, remaining_turns: int)

## Debuff添加
signal debuff_added(target_id: String, debuff: Dictionary)

## Debuff移除
signal debuff_removed(target_id: String, debuff_id: String)

## Debuff更新(持续时间或层数变化)
signal debuff_updated(target_id: String, debuff_id: String, remaining_turns: int)

# ============================================================================
# QUEST SIGNALS (P3级 - 任务系统)
# ============================================================================

## 任务开始
signal quest_started(quest: Dictionary)

## 任务更新
signal quest_updated(quest_id: String, progress: Dictionary)

## 任务完成
signal quest_completed(quest_id: String, rewards: Dictionary)

## 任务失败
signal quest_failed(quest_id: String, reason: String)

## 任务目标更新
signal quest_objective_updated(quest_id: String, objective_id: String, progress: int, total: int)

# ============================================================================
# NAVIGATION SIGNALS (P3级 - 导航系统)
# ============================================================================

## 玩家位置变化
signal nav_position_changed(position: Vector2)

## 进入新区域
signal nav_area_entered(area_name: String, area_level: int)

## 离开区域
signal nav_area_exited(area_name: String)

## 发现兴趣点(POI)
signal nav_poi_discovered(poi_id: String, poi_name: String, position: Vector2)

## 奇遇触发
signal nav_encounter_triggered(encounter_type: String)

# ============================================================================
# ITEM SIGNALS (P2-P3级 - 物品系统)
# ============================================================================

## 获得物品
signal item_obtained(item_id: String, quantity: int)

## 使用物品
signal item_used(item_id: String, quantity: int)

## 装备物品
signal item_equipped(item_id: String, slot: String)

## 卸下装备
signal item_unequipped(item_id: String, slot: String)

## 快捷栏变化
signal item_hotbar_changed(slot: int, item_id: String, quantity: int)

# ============================================================================
# SKILL SIGNALS (P2-P3级 - 技能系统)
# ============================================================================

## 技能解锁
signal skill_unlocked(skill_id: String, skill_name: String)

## 技能冷却开始
signal skill_cooldown_started(skill_id: String, cooldown_turns: int)

## 技能冷却更新
signal skill_cooldown_updated(skill_id: String, remaining_turns: int)

## 技能冷却结束
signal skill_cooldown_finished(skill_id: String)

## 可用技能点变化
signal skill_points_changed(available: int)

# ============================================================================
# SYSTEM SIGNALS (P4级 - 系统功能)
# ============================================================================

## 系统通知
## @param message: 通知消息内容
## @param type: 通知类型("info"/"warning"/"error"/"success")
## @param duration: 显示时长(秒),0表示需要手动关闭
signal system_notification(message: String, type: String, duration: float)

## 系统模式变化
signal system_mode_changed(mode: String)

## 保存完成
signal system_save_completed()

## 保存失败
signal system_save_failed(error: String)

## 成就解锁
signal system_achievement_unlocked(achievement_id: String, achievement_name: String)


func _ready() -> void:
	# GameEvents是autoload单例,在游戏启动时第一个加载
	# 不依赖其他系统,确保其他系统可以在_ready()中安全访问
	print("[GameEvents] Initialized - Global signal bus ready")


## 获取所有定义的信号列表(用于测试和调试)
## @return: 信号名称数组
func get_all_signal_names() -> Array[String]:
	var signal_names: Array[String] = []
	for signal_info in get_signal_list():
		signal_names.append(signal_info.name)
	return signal_names


## 获取信号总数(用于验证AC-2: 至少50个信号)
## @return: 信号数量
func get_signal_count() -> int:
	return get_signal_list().size()
