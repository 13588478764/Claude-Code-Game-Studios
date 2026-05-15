# Changelog — 武侠奇遇录

所有重要的项目变更记录在此文件中。

---

## [Alpha 0.6.0] — 2026-05-15

### 新增
- **端到端可玩体验** (Sprint 6): 从启动→设置→新游戏→探索→NPC对话→战斗→存档的完整链路
- ConfigFile持久化设置系统（替代JSON方案）
- 5总线音频布局（Master/Music/SFX/Voice/UI）+ 实时音量控制
- 新游戏开场流程：系统重置 → intro_yunzhonghe对话 → 进入探索
- 加载游戏流程：SaveSystem.has_save() + load_from_slot + 错误处理
- NPC对话触发：6个NPC动态按钮 + DialogueManager.start_dialogue_with_npc()
- 支线任务自动注册（register_all_npc_questlines 在 _ready 调用）
- 暂停菜单"返回主菜单"完整状态重置
- 制作人员滚动字幕面板
- 装备面板孔洞数据接通
- HotbarSlot tooltip显示物品信息
- 7个新测试文件（48个测试用例）
- Sprint 3-6 QA签收报告
- 里程碑计划 + 发布清单

### 修复
- 3个脚本文件的重复 extends 声明（status_icon_bar.gd, status_icon.gd, combat_hud.gd）
- 2个random_event测试的缺失路径引用
- status_icon_bar.gd 路径前缀错误（res://scenes/ → res://src/scenes/）

### 新增场景
- src/default_bus_layout.tres — 音频总线布局
- src/scenes/ui/credits_panel.tscn — 制作人员面板
- src/scenes/ui/status_icon.tscn — 状态图标
- src/scenes/ui/character_status.tscn — 角色状态
- src/scenes/ui/turn_order.tscn — 回合顺序

---

## [Alpha 0.5.0] — 2026-05-14

### 新增
- **角色关系系统** (Sprint 5): 完整的NPC关系循环
- 6个核心NPC数据配置（云中鹤/柳如烟/玄机真人/萧寒夜/血无痕/慕容雪）
- 礼物系统：4档偏好（最爱/喜欢/普通/讨厌）+ 新鲜度衰减
- 对话效果系统集成（modify_relationship/modify_dao_heart）
- 关系事件触发系统（阈值10/50/80触发专属剧情）
- 关系UI面板（快捷键R）
- 结局判定系统（4种结局：隐世/逍遥/正道/魔道）
- 存档系统集成关系数据
- 5个关系系统专用测试文件

---

## [Alpha 0.4.0] — 2026-05-14

### 新增
- **深化战斗与探索** (Sprint 4): 武学/连招/奇遇/对话接入
- 武学技能接入战斗（3+种武学可用，替代硬编码气剑术）
- 战斗连招系统（连续特定武学组合触发加成）
- 奇遇事件接入探索循环（30个JSON奇遇数据）
- 对话系统接入探索（NPC对话选项影响结果）
- 任务日志UI面板（快捷键J）
- 多存档槽位UI（3槽位 + 覆盖确认）
- 内力/气系统接入战斗UI
- 战斗结算面板
- ADR-006 奇遇架构 + ADR-007 对话架构

### 修复
- combo_system_test.gd 中 func assert() 与内置函数冲突
- 3个测试问题：MartialArtsSystem实例化/金创药数据/FPS基准

---

## [Alpha 0.3.0] — 2026-05-13

### 新增
- **UI接入游戏循环** (Sprint 3): 面板系统/战斗操作/存档
- 探索面板快捷键系统（I/E/ESC/M/F1，面板互斥）
- 暂停菜单接入游戏循环
- 背包/装备面板数据绑定
- 战斗操作UI（攻击/技能/防御替代自动战斗）
- 存档/读档系统接入
- 角色面板/大地图数据绑定
- MVP核心游戏循环串联（探索→战斗→奖励→成长→探索）

---

## [Alpha 0.2.0] — 2026-05-09

### 新增
- **UI场景实现** (Sprint 2): 8个核心UI面板
- 暂停菜单/大地图/帮助教程/加载界面
- 主菜单/设置面板/背包面板/装备面板
- 确认对话框组件 + 情境提示Toast
- 8个UI场景加载单元测试
- Sprint 2 QA签收报告

---

## [Alpha 0.1.0] — 2026-04-30

### 新增
- **核心系统验证** (Sprint 1): 战斗/经济/角色/奇遇
- 战斗机制（攻击/防御/弱点系统/连携）
- 经济系统（银两/物品交易）
- 角色成长（经验/属性/境界）
- 奇遇系统（条件检查/奖励分配/历史记录）
- 55+ GDD设计文档
- 7个ADR架构决策记录
- 基础测试框架
- QA计划 + 签收报告
