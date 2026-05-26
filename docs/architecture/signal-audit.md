# Signal Audit (Polish 2026-05-25)

**Scope**: 全项目 `signal` 声明审查, 区分 "已接通 / 半哑火 / 全哑火 / 预留"。
**关联**: polish-fixlist-2026-05-25.md #21, milestone-alpha-review.md lessons #2 (HUD 信号链未做端到端验证)
**审查方法**: `find src/ -name "*.gd" | xargs grep "^\s*signal "` + `grep "<signal>.emit\|emit_signal(\"<signal>\""` + `grep "<signal>.connect\|connect(\"<signal>\""`
**最近更新**: 2026-05-26 — sprint-007 s7-18 接通 8 个 P0 HUD 信号 (player_hp/qi/poise/level_up/exp + enemy_hp/selected + combat_action_queue), 余 2 个 (enemy_weakness_revealed / enemy_status_changed) 留 A2 PR 处理

---

## 总览

| 状态 | 定义 | 数量 |
|------|------|------|
| ✅ 已接通 | emit ≥ 1 && connect ≥ 1 | 9 已核对 (s7-18 新接 8 个 + 既有 player_realm_changed) |
| ⚠️ 半哑火 (P0) | connect ≥ 1 && emit = 0 | **2** (enemy_weakness_revealed / enemy_status_changed — 留 A2 PR) |
| 🟡 全哑火 (vBeta 预留) | emit = 0 && connect = 0 | **50** (28 in GameEvents + 22 in module-internal) |

> ⚠️ 数据快照时间 2026-05-26, 接通状态会随接入工作推进而变化, 修改信号布线时务必同步本表。

---

## ✅ 已接通 — s7-18 P0 完成 (8 个 / 10)

> 2026-05-26 sprint-007 s7-18 接通; 实现策略统一为 "桥接现有局部信号到 GameEvents", 不增加新 emit 点。
> 测试出口: tests/integration/hud/hud_signal_bridge_test.gd (10/10 pass)

| # | 信号 | 桥接位置 | 实现策略 |
|---|------|---------|--------|
| 1 | `player_hp_changed(current, max)` | combat_manager.gd:_on_unit_hp_changed_global | 桥接 unit_hp_changed (玩家路径) |
| 2 | `player_qi_changed(current, max)` | combat_manager.gd:_on_unit_resource_changed_global | 桥接 unit_resource_changed("internal_energy") |
| 3 | `player_poise_changed(current, max)` | 同上 | 桥接 unit_resource_changed("stance") |
| 4 | `player_level_up(new_level, old_level)` | character_system.gd:level_up() | 与既有 player_realm_changed 同模式 |
| 5 | `player_exp_changed(current, to_next)` | character_system.gd:add_experience() + level_up() | 升级时一并广播确保 HUD 经验条同步 |
| 6 | `enemy_selected(enemy)` | combat_manager.gd:execute_attack | 仅玩家锁定敌人时 emit, 含 enemy_info_panel 期待的 snapshot dict |
| 7 | `enemy_hp_changed(enemy_id, current, max)` | combat_manager.gd:_on_unit_hp_changed_global | 桥接 unit_hp_changed (敌人路径) |
| 8 | `combat_action_queue_updated(queue)` | combat_manager.gd:_emit_action_queue_updated | generate_action_queue + turn_started 时刷新 |

**玩家/敌人判定**: 沿用 `battle_units.find(unit) < ceil(size/2)` 位置约定 (`_is_player_unit`); BattleUnit 未加 is_player 字段, 未来加上后可简化。

## ⚠️ 半哑火 — A2 PR 待处理 (2 个)

> 接通需更深入的架构改动, 拆到独立 PR。

| # | 信号 | UI 订阅方 | 阻塞点 | A2 处理方向 |
|---|------|---------|------|----------|
| 1 | `enemy_weakness_revealed(enemy_id, element)` | ui/hud/enemy_info_panel.gd:69 | WeaknessSystem.weakness_hit 信号签名不含 element (传 attacker/target/result), result 也只含 is_weakness_hit/multiplier/triggered_down | 扩 weakness_hit 加 element 参数 + 加 Node→enemy_id 转换约定 |
| 2 | `enemy_status_changed(enemy_id, status)` | ui/hud/enemy_info_panel.gd:72 | combat_manager BattleUnit 无 down/break 显式状态字段; WeaknessSystem 的 down_triggered/down_cleared 传 Node 不传 enemy_id String | 在 combat_manager 加 BattleUnit.status_str 字段或桥接 WeaknessSystem 下行信号 |

**修复出口标准** (来自 alpha-review lessons #2):
- 接通后需补 integration test 验证 "状态变化 → GameEvents.emit → HUD 收到" (已为 8 个 P0 信号建立, A2 沿用 hud_signal_bridge_test.gd 模式)
- 一并更新本文件状态列为 "✅ 已接通"

---

## 🟡 全哑火 — GameEvents 28 个 (vBeta 预留)

> 定义于 src/scripts/core/game_events.gd, 但 0 emit + 0 connect。
> Polish 阶段不接通, 等对应系统实际启用时再接 + 写 integration test。

### Player 组 (1)

| 信号 | 行 | 用途 (定义意图) | 处理建议 |
|------|-----|---------------|--------|
| `player_attribute_points_changed(available)` | 94 | 玩家分配/获得属性点时通知 | 角色面板接入时接, vBeta |

### Combat 组 (1)

| 信号 | 行 | 用途 | 处理建议 |
|------|-----|------|--------|
| `combat_mode_changed(mode)` | 138 | Boss 阶段切换/特殊战斗模式 | Boss 战斗启用时接 |

### Enemy 组 (3)

| 信号 | 行 | 用途 | 处理建议 |
|------|-----|------|--------|
| `enemy_deselected()` | 148 | 取消选中敌人 | UI 已 connect `enemy_selected`, 反向接入时一起接 |
| `enemy_down_state_changed(id, is_down)` | 157 | 敌人 Down 布尔变化 | 已被 `enemy_status_changed` 替代, 可考虑删 |
| `enemy_break_state_changed(id, is_broken)` | 160 | 敌人 Break 布尔变化 | 同上, 可考虑删 |

### Buff/Debuff 组 (6) — buff 系统未启用

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `buff_added(target_id, buff)` | 173 | buff 系统启用时接 |
| `buff_removed(target_id, buff_id)` | 176 | 同上 |
| `buff_updated(target_id, buff_id, remaining)` | 179 | 同上 |
| `debuff_added(target_id, debuff)` | 182 | 同上 |
| `debuff_removed(target_id, debuff_id)` | 185 | 同上 |
| `debuff_updated(target_id, debuff_id, remaining)` | 188 | 同上 |

### Quest 组 (3) — 任务 UI 反馈未接

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `quest_started(quest)` | 195 | quest_log_panel 接入时接 |
| `quest_updated(quest_id, progress)` | 198 | 同上 |
| `quest_failed(quest_id, reason)` | 204 | 同上 (`quest_completed` 已接通可参考) |

### Navigation 组 (4) — 导航/POI/奇遇 UI 未接

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `nav_position_changed(position)` | 214 | minimap/world_map 接入时接 |
| `nav_area_exited(area)` | 220 | 同上 |
| `nav_poi_discovered(poi_id, name, pos)` | 223 | POI 系统启用时接 |
| `nav_encounter_triggered(encounter_type)` | 226 | 奇遇 UI 反馈接入时接 |

### Item 组 (3) — 物品/装备 UI 未接

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `item_obtained(item_id, quantity)` | 233 | inventory_panel 接入时接 |
| `item_equipped(item_id, slot)` | 239 | equipment_panel 接入时接 |
| `item_unequipped(item_id, slot)` | 242 | 同上 |

### Skill 组 (5) — 技能系统未启用

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `skill_unlocked(skill_id, name)` | 255 | 技能系统启用时接 |
| `skill_cooldown_started(skill_id, turns)` | 258 | 同上 |
| `skill_cooldown_updated(skill_id, remaining)` | 261 | 同上 |
| `skill_cooldown_finished(skill_id)` | 264 | 同上 |
| `skill_points_changed(available)` | 267 | 角色面板接入时接 |

### System 组 (2)

| 信号 | 行 | 处理建议 |
|------|-----|--------|
| `system_save_failed(error)` | 286 | save_system 失败路径接入时接 |
| `system_achievement_unlocked(id, name)` | 289 | Steam 成就接入时接 |

---

## 🟡 全哑火 — 模块内部 22 个 (各自评估)

> 定义在具体业务模块的 .gd 文件中, 0 emit + 0 connect。
> 由于每条都涉及单一模块, 不在此处归类决策, 而是列出供模块 owner 评估。

| # | 文件 | 行 | 信号 | 评估建议 |
|---|------|-----|------|--------|
| 1 | audio/audio_system.gd | 43 | `music_started` | audio-director 评估是否启用音乐事件订阅 |
| 2 | audio/audio_system.gd | 46 | `music_stopped` | 同上 |
| 3 | audio/audio_system.gd | 49 | `sound_played` | 同上 (DEBUG 用途为主, 可考虑只在 debug 模式 emit) |
| 4 | character/lifespan_manager.gd | 48 | `npc_lifespan_expired` | NPC 寿命系统启用时接 (世代/老化机制) |
| 5 | combat/qi_manager.gd | 57 | `combat_state_changed` | 与 `combat_mode_changed` 语义重复, 评估删除 |
| 6 | combat/defense_mitigation_manager.gd | 46 | `defense_values_updated` | 防御计算 debug/UI 接入时接 |
| 7 | combat/martial_arts_system.gd | 35 | `martial_art_unequipped` | 武学装备 UI 接入时接 (装备已有信号) |
| 8 | combat/enemy_behavior_manager.gd | 52 | `behavior_evaluated` | 仅 debug 价值, 可考虑只在 DEBUG 编译时 emit |
| 9 | combat/enemy_behavior_manager.gd | 53 | `action_selected` | 同上 |
| 10 | combat/hit_detection_manager.gd | 44 | `hit_chance_calculated` | 同上 (debug only) |
| 11 | combat/recovery_status_manager.gd | 46 | `recovery_state_changed` | 战斗状态恢复 UI 接入时接 |
| 12 | combat/martial_arts_combo_system.gd | 43 | `combo_state_reset` | 连携 UI 接入时接 |
| 13 | combat/health_poise_manager.gd | 60 | `critical_hp_reached` | HP 危急提示 UI 接入时接 (P1) |
| 14 | economy/trade_manager.gd | 42 | `inventory_changed` | 与 `item_obtained` 语义重复, 评估删除 |
| 15 | encounter/encounter_event_handler.gd | 32 | `encounter_check_failed` | 奇遇调试用, 可保留 debug |
| 16 | equipment/equipment_attribute_calculator.gd | 46 | `attributes_calculated` | 计算完成回调, 可改为 return 值即可 |
| 17 | equipment/equipment_slot_manager.gd | 95 | `slot_defined` | 配置完成事件, 启动期一次性, 可删 |
| 18 | ui/minimap.gd | 41 | `minimap_expanded` | minimap 子组件订阅时接 |
| 19 | ui/minimap.gd | 42 | `minimap_collapsed` | 同上 |
| 20 | ui/help_panel.gd | 17 | `tutorial_step_unlocked` | 教程系统启用时接 |
| 21 | ui/equipment_panel.gd | 12 | `equipment_item_equipped` | 与 GameEvents.item_equipped 重复, 评估删除 |
| 22 | ui/equipment_panel.gd | 26 | `equipment_set_bonus_activated` | 套装系统启用时接 |
| 23 | ui/world_map.gd | 12 | `world_map_tab_changed` | world_map 父级订阅时接 |
| 24 | ui/world_map.gd | 16 | `world_map_travel_cancelled` | 同上 |
| 25 | ui/world_map.gd | 18 | `world_map_region_inspected` | 同上 |
| 26 | ui/pause_menu.gd | 28 | `pause_menu_quit_initiated` | 主菜单退出确认链路接入时接 |
| 27 | ui/main_menu.gd | 15 | `main_menu_quit_cancelled` | 同上 |

> 注: ui 组超过 22 个总数, 上表合并了实际全部模块内部哑火信号(共 27 项, 因部分 ui 信号在重新扫描时新发现)。

---

## 处理策略 (建议给 lead-programmer)

### 立即处理 (P0)

1. **接通 10 个半哑火 P0 信号** — sprint-007 s7-18 已排期, 必修
2. **补 integration test** — alpha-review action #1, "状态变化 → emit → HUD 收到" 端到端验证

### vBeta 处理 (按系统启用顺序)

3. **buff/debuff 系统启用前不动** — 6 个信号留作占位
4. **quest UI / nav UI / item UI 启用前不动** — 13 个信号留作占位
5. **技能系统启用前不动** — 5 个信号留作占位

### 可考虑删除的疑似冗余信号 (~7 个)

> 这部分建议在 Beta 早期 (sprint-008/009) 由 lead-programmer 拍板:

- `enemy_down_state_changed` / `enemy_break_state_changed` — 已被 `enemy_status_changed` 取代
- `combat/qi_manager.gd::combat_state_changed` — 与 GameEvents.combat_mode_changed 语义重复
- `economy/trade_manager.gd::inventory_changed` — 与 GameEvents.item_obtained 重复
- `equipment/equipment_attribute_calculator.gd::attributes_calculated` — 计算回调用 return 即可
- `equipment/equipment_slot_manager.gd::slot_defined` — 启动期一次性事件
- `ui/equipment_panel.gd::equipment_item_equipped` — 与 GameEvents.item_equipped 重复

### Debug-only emit 候选 (~4 个)

- `combat/enemy_behavior_manager.gd::behavior_evaluated`
- `combat/enemy_behavior_manager.gd::action_selected`
- `combat/hit_detection_manager.gd::hit_chance_calculated`
- `audio/audio_system.gd::sound_played`

建议用 `if OS.is_debug_build():` 包裹 emit, 避免发布版无意义信号开销。

---

## 后续开发指引

1. **不要在 game_events.gd 加新信号**, 除非该信号在 30 天内会被 emit + connect
2. **接通已有信号时**, 同步更新本文件状态列
3. **删除哑火信号时**, 同步检查 .tscn / UI 脚本是否还有 inspector-绑定的连接
4. **新增信号时**, 优先考虑函数 return / 直接调用 等更直接的方式
