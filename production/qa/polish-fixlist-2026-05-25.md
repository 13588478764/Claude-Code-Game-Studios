# Polish 阶段必修清单 — 2026-05-25 全方位审查产物

> 由 3 个 subagent (producer + lead-programmer + godot-gdscript-specialist) 并行审查产出。
> 本次会话已快修 4 项 (见末尾 "已完成") , 本文档列剩余必修项。

## 一、P0 — 影响玩家体验或工程稳定性, Polish 出口前必修

### 1. HUD 10 个信号全面哑火 (运行时 bug)

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

### 2. DamageCalculator 缺所有乘数 (战斗只有 atk-def)

**症状**: 暴击 / 弱点 / 连击 / 随机浮动 (0.95-1.05) 全部没串进伤害公式。

**修复方向**: 
- 在 `combat_manager.gd` 的伤害结算路径里, 调用 `damage_multiplier_manager.gd::apply_modifiers()` 后再传给 `damage_calculator.gd`
- 或直接把 `damage_calculator.gd` 改成接受 multiplier dict, 内部应用

**工作量**: 2h, 必须配套单元测试。

**前置**: 需要 game-designer 确认每个乘数的具体公式 (GDD 已有, 但要拍最终值)。

---

### 3. 境界数量 9 vs 10 跨系统不统一

**现状**:
- `design/gdd/character-progression-system.md`: 9 境界 (炼气→筑基→金丹→元婴→化神→返虚→合道→大乘→渡劫)
- `src/scripts/character/character_system.gd:82-93`: 10 境界 (多出"真仙")
- `src/scripts/equipment/equipment_slot_manager.gd:81`: 10 境界 (与 character_system 一致)
- 5-25 入库的 10 张境界图标也按 10 个出 (含"真仙")

**决策需求**: GDD 加"真仙" → 9 改 10; 还是代码改回 9 + 图标删一张?

**推荐**: GDD 加"真仙", 因为代码+美术都 10 个, 改 GDD 成本最低。

**工作量**: 30 min (GDD + cross-check)

---

### 4. 暴击率与连击系数 (本会话已快修, 留作回归测试入口)

- ✅ `character_system.gd:467` 暴击率: `intelligence/20.0` → `agility*0.003 + luck*0.002`
- ✅ `combat_system.gd:37` 连击单位: `0.01` → `0.05`
- ✅ `martial_arts_system.gd:25` 熟练度上限: `10` → `15`

**回归测试需求**: 在 `tests/unit/character/` 与 `tests/unit/combat/` 下补 3 个测试用例 (公式快照)。

---

## 二、P1 — 重要但可缓 (Polish 阶段中段处理)

### 5. class_name 冲突清剩余

- ✅ 已删 `src/scripts/ui/damage_visualization_manager.gd` (281 行空壳)
- ⚠️ 剩余: `src/scripts/world_streaming_manager.gd` (旧版, 基于像素区块) vs `src/scripts/world/world_streaming_manager.gd` (新版, 简化区域加载) — 需评估合并/删旧, 不能盲删 (新版功能可能不全)
- ⚠️ `combat_system.gd:37::COMBO_DAMAGE_INCREMENT` (战斗连击 0.05) vs `link_system.gd:30::COMBO_DAMAGE_INCREMENT` (连携槽 0.10) 同名不同义, 建议 link_system 那个重命名为 `LINK_COMBO_DAMAGE_INCREMENT`

### 6. character_system.gd 核心 Autoload 缺静态类型

`CharacterAttributes` 内部类 6 个成员全部 untyped; `add_points(points_dict)` / `get_total()` 无类型签名。性能损失 + 重构安全为零。**1h** 全文加类型。

### 7. dialogue_data.gd 条件判定永远 `return true`

所有对话分支无条件可见 — `dialogue_data.gd` 有 3 处 "暂时" 标记, 必须实现真实条件判定才能上线主线对话。

### 8. 装备 GDD 9 槽 vs 代码 15 槽, 强化/镶嵌/洗练/幻化 8 文件全空壳

需要 systems-designer 决策: 删多出的 6 槽 (LEGS / INNER_ART × 3 / LIGHT_ART) 还是 GDD 补齐到 15? 强化/镶嵌/洗练/幻化 4 子系统是否进 Beta?

### 9. EXP 后期指数 GDD 1.8 vs 代码 2.5

代码后期升级远比设计陡。改 1 行即可, 但需要 game-designer 确认是不是已经调过参。

### 10. 武器类型不匹配

代码出现 "Palm"(掌法) GDD 无; GDD 的 "Blade"(刀) / "Bow"(弓) 数据库无对应武学。需要 systems-designer + 数据库补齐。

### 11. 奇遇触发概率 GDD 自身矛盾

`character-progression-system.md:160` 说 15% / `encounter-system.md:51` 说 20% / 代码 20%。 需要 game-designer 统一 GDD, 代码已经对了 20%。

### 12. 福缘软上限未实现

GDD 说 100 点后边际递减, 代码用简单 `1 + luck/100` 无拐点。高福缘角色奇遇收益远超设计。

---

## 三、项目状态体系缺口 (producer 范畴)

### 13. sprint-007 不存在

05-15 后 11+ commit (主题系统 / UI 重构 / 主菜单切换 / AI 管线 / 三幕大纲 / 境界 bug / 本次审查快修) 全部悬空在 git log 里, 未归入任何 sprint。**P0**

### 14. milestone-beta.md + Polish→Release 门检表都不存在

Polish 已进入 10 天但下一站没定义。**P0**

### 15. epics/index.md 失修 + 缺 3 个 polish epic 目录

- index.md 仅 20 行 vs 实际 40 个 epic 目录
- 缺 `ai-asset-pipeline` / `theme-system` / `narrative-act2-3` 三个 epic 文件夹

### 16. project-stage-report.md 05-23 快照已过时

美术 40% 未含 56 张图标入库, 未提主题系统/启动场景切换/三幕大纲。

### 17. session-state 缺 4 个完工记录

近 10 天: AI 管线第一批 / 主题系统 / 启动场景切换 / 境界广播 bug — 都无 completion 文件。

### 18. risk-register/ 目录不存在

active.md 中"工作流节点超标 / 菱形外框崩坏 / 挂机重启"等风险散落, 未集中维护。

---

## 四、P2 — 卫生类

### 19. 8 个测试文件混在 src/ (打包会进生产包)

- `src/test_attribute_manager.gd` + `.tscn`
- `src/scripts/test_mvp_validation.gd`
- `src/scripts/test/simple_equipment_test.gd`
- `src/scripts/test/equipment_test_script.gd`
- `src/scripts/validation/mvp_validation.gd`
- `src/scripts/ui/equipment_ui_test.gd`
- `src/scenes/status_ui_test_controller.gd`
- `src/scenes/attribute_allocation_test_script.gd`

应批量 `mv` 到 `tests/` 对应子目录, 同时排查 import path 连锁。**预估 1h, 但有回归风险**, 必须在白天有时间排查。

### 20. 25 处 "暂时" stub 实现

- fast_travel_manager.gd 5 处 (快旅功能全部 stub)
- dialogue_data.gd 3 处 (见 #7)
- character_system.gd:237 (境界突破跳过玩家交互)
- audio_system.gd:123 (音效播放空实现)
- equipment_ui.gd:210 (装备界面静态显示)

### 21. 30+ 预留信号定义了从未 emit 也从未 connect

party / buff / debuff / quest / nav / item / skill 分类信号 — 不构成 bug 但误导后人, Beta 前应清理或加注释 "// 预留, 待 vX.Y 接入"。

### 22. src/scripts/documentation/ 三个空壳类无 GDD 对应

`document_consistency_analyzer.gd` / `conflict_resolution_planner.gd` / `document_alignment_implementer.gd` — 疑似误生成的冗余代码, 待 lead-programmer 确认是否安全删除。

### 23. 缺 milestone-alpha-review.md

alpha 标 COMPLETE 但无回顾 (velocity / 范围变更 / lessons learned)。

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

## 六、推荐执行顺序

1. **明早**: HUD 10 信号哑火 (#1) — 这是玩家最早会注意到的 bug
2. **本周内**: 境界 9/10 决策 (#3) + sprint-007 创建 (#13) + class_name 剩余清理 (#5)
3. **本月内**: DamageCalculator 重构 (#2) + 装备系统设计决策 (#8) + 测试文件迁移 (#19)
4. **Beta 前**: 全部 P1 + P2

> 维护责任: producer 拉本清单进 sprint-007 backlog, 按 sprint 周期消化。
