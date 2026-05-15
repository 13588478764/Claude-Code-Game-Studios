## QA Sign-Off Report: Sprint 6 — 端到端可玩体验
**Date**: 2026-05-15
**QA Lead**: gate-check (automated)
**Scope**: 11 stories (s6-01 through s6-11)
**Engine**: Godot 4.6
**Sprint Goal**: 接通设置面板实际功能、补全新游戏/加载流程、接入NPC对话触发、实现音频总线控制

---

### Test Coverage Summary

| Story | Description | Type | Auto Test | Manual Evidence | Result |
|-------|-------------|------|-----------|-----------------|--------|
| s6-01 | 设置面板功能接通 | Integration | settings_persistence_test.gd (7 tests) | ConfigFile持久化+5总线控制 | PASS |
| s6-02 | 新游戏开场流程 | Integration | new_game_flow_test.gd (4 tests) | 系统重置→intro对话→探索 | PASS |
| s6-03 | 加载游戏流程 | Integration | load_game_flow_test.gd (7 tests) | has_save检测+错误处理 | PASS |
| s6-04 | NPC对话触发接入 | Integration | npc_dialogue_trigger_test.gd (8 tests) | 6个NPC按钮+metadata匹配 | PASS |
| s6-05 | 音频总线控制 | Logic | audio_bus_control_test.gd (8 tests) | AudioServer 5总线+静音 | PASS |
| s6-06 | 支线任务触发验证 | Integration | side_quest_trigger_test.gd (10 tests) | register_all_npc_questlines自动调用 | PASS |
| s6-07 | 暂停菜单功能完善 | UI | N/A | _return_to_main_menu+状态重置 | PASS |
| s6-08 | 主菜单制作人员/帮助入口 | UI | N/A | credits_panel.gd滚动字幕 | PASS |
| s6-09 | 装备面板孔洞数据接通 | UI | N/A | socket_count/sockets数据读取 | PASS |
| s6-10 | HotbarSlot tooltip | UI | N/A | _update_tooltip从InventorySystem获取 | PASS |
| s6-11 | 集成测试补充 | Integration | sprint6_e2e_test.gd (4 tests) | 设置/状态/存档/返回菜单E2E | PASS |

### Implementation Evidence

- **设置面板**: `src/scripts/ui/settings_panel.gd` — ConfigFile持久化 + `_set_bus_volume()` 5总线实时控制
- **音频总线**: `src/default_bus_layout.tres` — 5总线布局（Master/Music/SFX/Voice/UI）
- **新游戏流程**: `src/scripts/ui/main_menu.gd` — `_start_new_game()` 系统重置→intro对话→探索
- **加载游戏**: `src/scripts/ui/main_menu.gd` — `_on_continue_pressed()` SaveSystem集成
- **NPC对话**: `src/scripts/ui/exploration_panel.gd` — `_build_npc_buttons()` 动态创建6个NPC按钮
- **支线触发**: `src/scripts/quest/quest_trigger_manager.gd` — `_ready()` 自动调用注册
- **暂停菜单**: `src/scripts/ui/pause_menu.gd` — `_return_to_main_menu()` 完整状态重置
- **制作人员**: `src/scripts/ui/credits_panel.gd` + `src/scenes/ui/credits_panel.tscn`
- **装备孔洞**: `src/scripts/ui/equipment_panel.gd` — 从_equipped_items读取socket数据
- **Hotbar tooltip**: `src/scenes/ui/hud/HotbarSlot.gd` — `_update_tooltip()` 显示物品信息

### Automated Test Files

| Test File | Test Count | Coverage |
|-----------|-----------|----------|
| tests/integration/settings/settings_persistence_test.gd | 7 | 默认值/静音/最大音量/持久化/损坏配置/不存在总线/音量映射 |
| tests/unit/audio/audio_bus_control_test.gd | 8 | linear_to_db/set_get_volume/mute/负数/超限/不存在总线 |
| tests/integration/game_flow/new_game_flow_test.gd | 4 | 进入探索/隐藏菜单/双击防护/安全enter |
| tests/integration/game_flow/load_game_flow_test.gd | 7 | has_save false/true/无效槽/不存在存档/info/signal |
| tests/integration/dialogue/npc_dialogue_trigger_test.gd | 8 | 缺失NPC/has_dialogue/注册/metadata匹配/信号/阻塞/重启/字典加载 |
| tests/integration/quest/side_quest_trigger_test.gd | 10 | 阈值/3NPC/不足/精确/多任务/注册全部/未注册/缺失条件 |
| tests/integration/e2e/sprint6_e2e_test.gd | 4 | 设置持久化/状态转换/存档循环/返回菜单 |

### Verdict: APPROVED

**条件**: Sprint 6全部11个story已实现并验证。7个新测试文件共48个测试用例覆盖所有Logic和Integration类story。Sprint目标"端到端可玩体验"已达成 — 从启动→设置→开始→探索→NPC对话→战斗→存档的完整链路已接通。

**关键指标**:
- 新增代码: +1204/-241 行（20个文件）
- 新增测试: 7个文件，48个测试用例
- 覆盖系统: 设置/音频/游戏流程/对话/任务/E2E
- Commit: 7485c19 `feat(sprint6): 实现端到端可玩体验`
