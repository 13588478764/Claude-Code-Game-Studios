# Polish 阶段必修清单 — 2026-05-25 全方位审查产物

> 由 3 个 subagent (producer + lead-programmer + godot-gdscript-specialist) 并行审查产出。
> 本次会话已快修 4 项 (见末尾 "已完成") , 本文档列剩余必修项。

## 一、P0 — 影响玩家体验或工程稳定性, Polish 出口前必修

### 1. HUD 10 个信号全面哑火 (运行时 bug) ✅ 2026-05-28 (已有 emit)

**症状**: 玩家看不到 HP / 内力 / 架势 / 经验条变化, 看不到敌人 HP / 弱点暴露, 看不到行动队列更新。

**信号清单** (已 connect 但无 emit):

| 信号 | connect 位置 | 需要在哪里 emit |
|---|---|---|
| `player_hp_changed` | `player_status_panel.gd:104` | character_system 受伤/治疗时 |
| `player_qi_changed` | `player_status_panel.gd:105` | qi_manager 内力变化时 |
| `player_poise_changed` | `player_status_panel.gd:106` | health_poise_manager 架势变化时 |
| `player_level_up` | `player_status_panel.gd:107` | level_up_manager 升级时 |
| `player_exp_changed` | `player_status_panel.gd:108` | exp_acquisition_manager 加经验时 |
| `enemy_selected` | `enemy_info_panel.gd:65` | combat_manager 切换目标时 |
| `enemy_hp_changed` | `enemy_info_panel.gd:67` | 伤害结算后 |
| `enemy_weakness_revealed` | `enemy_info_panel.gd:69` | weakness_system 揭示弱点时 |
| `enemy_status_changed` | `enemy_info_panel.gd:72` | status_effect_manager 状态变化时 |
| `combat_action_queue_updated` | `action_queue_display.gd:81` | combat_manager 队列重排时 |

**修复模式**: 与 2026-05-25 已修复的 `player_realm_changed` 完全同型 — 在状态变更的源头方法末尾加 `GameEvents.<signal>.emit(...)`。

**工作量**: 每个 ≈ 10 min (找源头 + emit + 手动验证), 总计 1-2h。

**优先级**: P0 (玩家根本看不到游戏)

---

### 2. DamageCalculator 缺所有乘数 (战斗只有 atk-def) ✅ 2026-05-28 (已有完整实现)

**已实现**: `combat_manager.gd:843` `_apply_multipliers()` 调用 `DamageMultiplierManager.apply_all_multipliers()` 完整串入暴击×连击×弱点×破防×状态×随机浮动(0.95-1.05)。GDD 公式全部落地。

---

### 3. 境界数量 9 vs 10 跨系统不统一 ✅ 2026-05-26

**原现状**:
- `design/gdd/character-progression-system.md`: 9 境界 (含早期/后期分段格式, 终点化神期)
- `src/scripts/character/character_system.gd:82-93`: 10 境界 (扁平, 多出"真仙")
- 5-25 入库的 10 张境界图标按 10 个出 (含"真仙")

**实际审查后修正**: 不止数量分歧 — GDD 用 9 个"早期/后期"切分子境界 (Lv 1-99), 代码用 10 个扁平大境界。结构性差异。

**决策**: GDD 改齐代码 10 扁平 (代码 + 美术零改动)。
**已落地**: `design/gdd/character-progression-system.md` L18 + L44-53 改为 10 大境界 (炼气→筑基→...→真仙)。寿命系统 L80 narrative-only 段保留原 5 阶, 不属于本次结构对齐范围。

---

### 4. 暴击率与连击系数 (本会话已快修, 留作回归测试入口) ✅ 2026-05-28 (测试已有)

- ✅ `character_system.gd:467` 暴击率: `intelligence/20.0` → `agility*0.003 + luck*0.002`
- ✅ `combat_system.gd:37` 连击单位: `0.01` → `0.05`
- ✅ `martial_arts_system.gd:25` 熟练度上限: `10` → `15`
- ✅ 回归测试: `critical_rate_formula_test.gd` (4例) + `combo_damage_increment_test.gd` (5例) + `martial_arts_proficiency_cap_test.gd`

---

## 二、P1 — 重要但可缓 (Polish 阶段中段处理)

### 5. class_name 冲突清剩余 ✅ 2026-05-28

- ✅ 已删 `src/scripts/ui/damage_visualization_manager.gd` (281 行空壳)
- ✅ 删除新版 `src/scripts/world/world_streaming_manager.gd` (区域加载版, 412 行, 零产品代码引用) + 配套测试。旧版 (像素区块版) 被 player_position_tracker + memory_optimizer 深度依赖, 保留为唯一实现。
- ✅ `link_system.gd:30::COMBO_DAMAGE_INCREMENT` → `LINK_COMBO_DAMAGE_INCREMENT` (2026-05-26) — 同时把 ComboTracker.hit_target 内硬编码 `0.1` 改用本常量 (dead const 转 live const, 与 combat_system.gd 同名常量 0.05 彻底解耦). 41/41 link_system tests + 5/5 combo_damage_increment 快照通过.

### 6. character_system.gd 核心 Autoload 缺静态类型 ✅ 2026-05-26

- ✅ CharacterAttributes 内部类 6 个成员 (`strength/agility/...`) 加 `: int`; `get_total() -> Dictionary`; `add_points(points_dict: Dictionary) -> void` (含 int 转换防 dict 来自 JSON 等弱类型源).
- ✅ 主类 11 个成员 (level/experience/realm_index/realm_bonus/...) 全部 typed.
- ✅ 22 个函数全部加 typed 参数 + 返回类型 (init/level_up/breakthrough/get_combat_stats/...).
- ✅ 删 orphan `_on_test_button_pressed` UI 回调 (零外部引用).
- 验证: tests/unit/character/ 19/19 + 其余 character 套 24/24 + hud_signal_bridge_test 15/15 = **58/58 通过, API 零破坏**.

### 7. dialogue_data.gd 条件判定永远 `return true` ✅ 2026-05-28 (已有完整实现)

基类 `Condition.evaluate()` 返回 true 仅为默认值; 6 个子类 (RealmLevel/Relationship/DaoHeart/QuestStatus/ItemOwned/Flag) 均已实现真实判定逻辑, `DialogueNode.check_conditions()` 遍历所有条件并 AND 合并。

### 8. 装备 GDD 9 槽 vs 代码 15 槽, 强化/镶嵌/洗练/幻化 8 文件全空壳 ✅ 2026-05-28

GDD 已改为 9 槽对齐代码 (polish-fixlist #8 2026-05-27)。装备系统 8 文件均有 200-300 行实现, 非空壳。强化/镶嵌/洗练/幻化子系统文件未创建, 属 Beta 范畴。

### 9. EXP 后期指数 GDD 分段 1.0/1.5/1.8 vs 代码扁平 1.5 ✅ 2026-05-26

**原描述过时修正**: polish-fixlist 写"GDD 1.8 vs 代码 2.5", 实际 commit 7a96c95 已把代码从 2.5 改到 1.5。
真实分歧: GDD `experience-system.md` L170-172 规定**分段函数** (Lv1-33=1.0 / Lv34-66=1.5 / Lv67-99=1.8); 代码用扁平 1.5。

**已落地**: `character_system.gd` 加 `_get_exp_exponent(target_level: int) -> float` 私有方法, `get_exp_required_for_level` 改调它。
**回归测试**: `tests/unit/character/exp_exponent_piecewise_test.gd` (5 用例, 含边界 + 接入验证)。

### 10. 武器类型不匹配 ✅ 2026-05-26 (GDD 一半)

**已落地**: `design/gdd/martial-arts-system.md` L63 补 "Palm 掌法" (对应丐帮"降龙十八掌"); Blade/Exotic/Bow 留待 Beta 由 systems-designer + 数据填武学条目, 已加注释说明。

### 11. 奇遇触发概率 GDD 自身矛盾 ✅ 2026-05-26

**已落地**: `character-progression-system.md` L160 + L162 统一改成 20% (与 `encounter-system.md` L51/L113/L167 一致); 代码已对齐 20%, 零代码改动。

### 12. 福缘软上限未实现 ✅ 2026-05-26

**已落地**:
- `character_system.gd` 新增 `static func get_luck_bonus_coefficient(luck_stat: float) -> float`, 实现 GDD L146-152 软上限公式 (100 点拐点, 后段斜率 1/300)
- 迁移 5 个 call site 全部改用单一真值: `encounter_integration.gd:122` / `encounter_trigger_manager.gd:98` / `game_loop_manager.gd:231` / `price_balancing_manager.gd:86` / `currency_manager.gd:144`
- 回归测试: `tests/unit/character/luck_bonus_coefficient_test.gd` (6 用例, 含边界/拐点/递减段/斜率验证)
- 更新 `test_encounter_trigger.gd::test_probability_cap_at_twenty_percent` snapshot (luck=200 旧 0.15 → 新 0.1167, 反映软上限正确生效)
- 198/198 character + encounter + economy + combat 回归测试通过

---

## 三、项目状态体系缺口 (producer 范畴)

### 13. sprint-007 不存在 ✅ 2026-05-28 (已创建)

`production/sprints/sprint-007.md` 已存在, 2026-05-15 ~ 2026-05-29, 包含 Polish 阶段所有 commit。

### 14. milestone-beta.md + Polish→Release 门检表都不存在 ✅ 2026-05-28 (已创建)

`production/milestones/milestone-beta.md` 已存在, 含硬性要求表 + 目标日期 2026-07-15。

### 15. epics/index.md 失修 + 缺 3 个 polish epic 目录 ✅ 2026-05-28

index.md 已完整列出 44 个 epic (97 行), 3 个 polish epic 目录已存在, 状态已更新至最新 (HUD/对话/装备/伤害乘数均标为 DONE)。

### 16. project-stage-report.md 05-23 快照已过时 ✅ 2026-05-28

已由 `/project-stage-detect` 全面重写, 反映 236 张图标入库 + 21/27 fixlist 闭环 + Beta 门检距离。

### 17. session-state 缺 4 个完工记录

近 10 天: AI 管线第一批 / 主题系统 / 启动场景切换 / 境界广播 bug — 都无 completion 文件。

### 18. risk-register/ 目录不存在 ✅ 2026-05-28

`production/risk-register/active.md` 已创建, 6 个活跃风险 (内容进度/美术覆盖/ComfyUI 稳定性/测试通过率/性能基线/Playtest 组织)。

---

## 四、P2 — 卫生类

### 19. 8 个测试文件混在 src/ (打包会进生产包) ✅ 2026-05-26

- ✅ `src/test_attribute_manager.gd` + `.tscn` + `.uid` → `tests/manual/attribute_manager/` (修正 ext_resource 路径 `res://test_attribute_manager.gd` → `res://tests/manual/attribute_manager/test_attribute_manager.gd`, 顺手修了原本就 broken 的引用)
- ✅ 完全 orphan 删除 (zero refs in .tscn / .gd / project.godot, 仅 `.godot/` 编辑器缓存有 cache 条目): `src/scripts/test_mvp_validation.gd` (542) / `src/scripts/test/simple_equipment_test.gd` (131) / `src/scripts/test/equipment_test_script.gd` (176) / `src/scripts/validation/mvp_validation.gd` (~600) / `src/scripts/ui/equipment_ui_test.gd` (213) / `src/scenes/status_ui_test_controller.gd` (123) / `src/scenes/attribute_allocation_test_script.gd` (211)
- 共减 ~2000 行 src/ 死代码; 134/134 GUT 测试无 loading regression (1 pre-existing `test_constants` 熟练度等级 fail 与本变动无关).

### 20. 25 处 "暂时" stub 实现 ✅ 2026-05-27

所有 stub 注释已标准化为 `TODO(beta):` 格式 (10 个存活 TODO)。dialogue_data.gd 条件已有真实实现 (见 #7)。

### 21. 30+ 预留信号定义了从未 emit 也从未 connect

party / buff / debuff / quest / nav / item / skill 分类信号 — 不构成 bug 但误导后人, Beta 前应清理或加注释 "// 预留, 待 vX.Y 接入"。

### 22. src/scripts/documentation/ 三个空壳类无 GDD 对应 ✅ 2026-05-27

已删除 3 个文件 (943 行, 零外部引用)。

### 23. 缺 milestone-alpha-review.md ✅ 2026-05-28 (已创建)

`production/milestones/milestone-alpha-review.md` 已存在, 含总览数据 + velocity + 范围变更 + 经验教训。

---

## 五、本会话已完成 (2026-05-25)

| # | 动作 | 文件 | Commit |
|---|---|---|---|
| 1 | 暴击率公式: `intelligence/20.0` → `agility*0.003 + luck*0.002` | `character_system.gd:467` | (本次) |
| 2 | 连击单位: `0.01` → `0.05` (6 击 ×5% = 30% 上限) | `combat_system.gd:37` | (本次) |
| 3 | 武学熟练度上限: `10` → `15` (与本文件实际上限对齐) | `martial_arts_system.gd:25` | (本次) |
| 4 | 删 281 行空壳, 消除 class_name 冲突 | `src/scripts/ui/damage_visualization_manager.gd` (rm) | (本次) |
| 5 | 写本清单 | `production/qa/polish-fixlist-2026-05-25.md` | (本次) |

---

## 五-B、UI 资源接入遗留 (2026-05-28 审查)

> 以下资源已存在于 `assets/ui/` 但尚未被代码加载，需后续在编辑器中或代码中接入。

### 24. 品阶边框 frame_rarity_*.png (5张) 未接入物品槽

**现状**: `assets/ui/frames/` 有 `frame_rarity_common/fine/epic/legendary/immortal.png`，但 inventory 用 ItemList 无法为单项设独立边框。
**修复方向**: 将 ItemList 改为 GridContainer + 自定义 ItemSlot.tscn (TextureRect 边框 + TextureRect 图标 + Label 数量)，根据 tier 加载对应品阶边框。
**工作量**: 4-6h (含 .tscn 布局 + 脚本适配)

### 25. 进度条/按钮纹理 (progress_bar_*.png, button_*.png) 未接入 Theme

**现状**: `progress_bar_bg.png` / `progress_bar_fill.png` / `button_standard.png` / `button_close.png` / `button_main_menu.png` 存在但 UI 用 Godot 默认 StyleBox。
**修复方向**: 创建 `assets/ui/theme/game_theme.tres` (Godot Theme 资源), 在 ProgressBar / Button 的 StyleBox 中设置这些纹理, 项目根场景统一引用。
**工作量**: 2-3h (含 NinePatch margin 调试)

### 26. system_icons/ (23张地图/任务图标) 未接入

**现状**: `map_icon_*.png` (6张) + `quest_icon_*.png` (6张) + `system_icon_*.png` (11张) 已有, 但 `world_map.gd` / `quest_log_panel.gd` / `minimap.gd` 中未加载。
**修复方向**: 
- `world_map.gd`: 用 `map_icon_*.png` 替代当前 ColorRect 标记
- `quest_log_panel.gd`: 任务类型图标 (主线/支线/完成)
- `minimap.gd`: POI 标记用 `map_icon_*.png`
**工作量**: 3-4h

### 27. title_banner.png / divider_horizontal.png / scrollbar_handle.png 装饰未接入

**现状**: 面板标题栏、分隔线、滚动条均使用默认样式。
**修复方向**: 纳入 #25 的统一 Theme 资源中一并处理。
**工作量**: 含在 #25 中

---

## 六、推荐执行顺序

1. **明早**: HUD 10 信号哑火 (#1) — 这是玩家最早会注意到的 bug
2. **本周内**: 境界 9/10 决策 (#3) + sprint-007 创建 (#13) + class_name 剩余清理 (#5)
3. **本月内**: DamageCalculator 重构 (#2) + 装备系统设计决策 (#8) + 测试文件迁移 (#19)
4. **Beta 前**: 全部 P1 + P2

> 维护责任: producer 拉本清单进 sprint-007 backlog, 按 sprint 周期消化。
