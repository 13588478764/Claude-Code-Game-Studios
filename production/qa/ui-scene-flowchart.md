# 游戏场景与UI状态流程图

## 1. 游戏启动流程

```
[游戏启动]
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  main_game_ui.tscn (入口场景, Z=0)                            │
│  ─────────────────────────────────────────                   │
│  子节点:                                                       │
│  ├── GameTitleLabel          "武侠奇遇录 - 游戏体验版"         │
│  ├── WelcomeLabel            "欢迎来到武侠奇遇录！"            │
│  ├── StartNewGameButton       点击 → 开始新游戏               │
│  ├── LoadGameButton           点击 → 加载游戏                 │
│  ├── GameEvents (Node)        全局信号总线                      │
│  ├── CharacterSystem (Node)   角色数据                          │
│  ├── CombatSystem (Node)      战斗逻辑                          │
│  ├── UIManager (Node)         UI状态管理                        │
│  ├── QuestSystem (Node)       任务管理                          │
│  ├── WorldSystem (Node)       世界管理                          │
│  ├── AudioSystem (Node)       音频管理                          │
│  ├── HUDLayer (CanvasLayer, Z=100, 默认hidden)                │
│  │   ├── HUDManager                                               │
│  │   │   ├── PlayerStatusPanel (玩家状态)                       │
│  │   │   ├── PartyPanel (队伍状态)                              │
│  │   │   ├── ActionQueueDisplay (行动队列)                      │
│  │   │   ├── EnemyInfoPanel (敌人信息)                          │
│  │   │   ├── MenuSystemFunctions (菜单入口)                     │
│  │   │   ├── HotbarController (快捷栏)                          │
│  │   │   └── NotificationManager (通知)                         │
│  │   ├── EncounterUI (默认hidden)                               │
│  │   └── DialogueBox (默认hidden)                               │
│  └── MainMenuPanel (Panel)                                      │
│                                                              │
│  ┌─ 点击"开始新游戏" ────────────────────────────────────┐   │
│  │ 1. hide(GameTitleLabel, WelcomeLabel, StartButton,   │   │
│  │           LoadButton)                                 │   │
│  │ 2. HUDLayer.visible = true                            │   │
│  │ 3. 初始化所有系统 (Character/Equipment/Encounter/     │   │
│  │     Economy/ActManager)                                │   │
│  │ 4. 显示角色面板 (CharacterPanelInstance)               │   │
│  │ 5. 触发开场对话 (ACT1_OPENING_001)                     │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌─ 点击"加载游戏" ─────────────────────────────────────┐   │
│  │ 1. 从 SaveSystem.load_from_slot(0) 读取存档           │   │
│  │ 2. 有存档 → 显示角色面板                               │   │
│  │ 3. 无存档 → 走"开始新游戏"流程                          │   │
│  └───────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 2. 游戏内UI面板状态机

```
┌─────────────────────────────────────────────────────────────┐
│  HUDLayer (Z=100) - 游戏进行时始终可见                       │
│  ───────────────────────────────────────────────────────     │
│  包含: 玩家状态 / 队伍状态 / 行动队列 / 敌人信息 / 快捷栏     │
│                                                              │
│  快捷键入口 (由 MenuSystemFunctions + 各面板自身 _input 处理) │
│  ┌────────────┬──────────────────────────────────────────┐  │
│  │ 快捷键      │ 功能                                      │  │
│  ├────────────┼──────────────────────────────────────────┤  │
│  │ ESC        │ 打开暂停菜单 (pause_menu)                  │  │
│  │ C          │ 打开角色面板 (character_panel)             │  │
│  │ M          │ 打开大地图 (world_map, Z=220)              │  │
│  │ F1         │ 打开帮助面板 (help_panel, Z=180)           │  │
│  │ I          │ 打开背包面板 (inventory_panel, Z=200)      │  │
│  │ E          │ 打开装备面板 (equipment_panel, Z=200)      │  │
│  └────────────┴──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

         ESC                    C           M          F1/I/E
          │                     │            │            │
          ▼                     ▼            ▼            ▼
   ┌──────────┐        ┌───────────┐  ┌──────────┐  ┌──────────┐
   │pause_menu│        │character_ │  │ world_   │  │inventory/│
   │  (Z=260) │        │  panel    │  │ map      │  │equipment │
   │          │        │           │  │ (Z=220)  │  │ (Z=200)  │
   │ 继续修炼  │        └───────────┘  └──────────┘  └──────────┘
   │ 保存进度  │              │             │            │
   │ 读取存档  │              │  ESC关闭    │ ESC/双击    │
   │ 设置 ────┼───打开─────►  │             │            │
   │          │   settings_  │              │            │
   │ 返回主菜单│   panel      │              │            │
   │ 退出游戏  │   (Z=250)    │              │            │
   └──────────┘              │              │            │
         │                   │              │            │
         │ ESC关闭           │              │            │
         │                   │              │            │
         ▼                   ▼              ▼            ▼
   ┌─────────────────────────────────────────────────────────┐
   │  返回 HUDLayer (游戏进行中)                               │
   └─────────────────────────────────────────────────────────┘
```

## 3. 面板Z-index层级

```
Z=600  ┌─ loading_screen (最高层, 加载时覆盖全屏)
       │
Z=400  ├─ confirm_dialog (确认对话框)
       │
Z=300  ├─ encounter_ui (奇遇面板)
       │
Z=280  ├─ 存档列表面板 (TODO)
       │
Z=260  ├─ pause_menu (暂停菜单)
       │
Z=250  ├─ settings_panel (设置面板)
       │
Z=220  ├─ world_map (大地图)
       │
Z=200  ├─ inventory_panel (背包面板)
       ├─ equipment_panel (装备面板)
       │
Z=180  ├─ help_panel (帮助面板, 不暂停游戏)
       │
Z=100  ├─ HUDLayer (HUD层, 始终可见)
       │   ├── PlayerStatusPanel
       │   ├── PartyPanel
       │   ├── ActionQueueDisplay
       │   ├── EnemyInfoPanel
       │   ├── MenuSystemFunctions
       │   ├── HotbarController
       │   └── NotificationManager
       │
Z=0    └─ main_game_ui (主场景背景)
```

## 4. 每个面板的功能清单

### 4.1 main_game_ui.tscn (入口场景)
- 游戏启动后的第一个场景，project.godot 中配置为 `run/main_scene`
- 包含所有 autoload 风格的游戏系统节点
- 主菜单状态: 显示标题 + "开始新游戏" + "加载游戏" 按钮
- 游戏进行状态: 隐藏主菜单元素，显示 HUDLayer

### 4.2 HUDLayer (Z=100)
- **PlayerStatusPanel**: 玩家血量/内力/状态显示
- **PartyPanel**: 队伍成员状态
- **ActionQueueDisplay**: 战斗行动队列
- **EnemyInfoPanel**: 敌人信息 (血量/弱点)
- **MenuSystemFunctions**: ESC 打开主菜单, F1 打开帮助
- **HotbarController**: 快捷栏
- **NotificationManager**: 通知系统

### 4.3 DialogueBox (HUDLayer子节点)
- 显示NPC对话文本
- 显示说话人名称
- 显示选择按钮 (最多4个)
- ESC: 跳过对话文本 / 关闭对话框
- SPACE/ENTER: 继续下一段文本
- 由 DialogueManager 自动 show/hide

### 4.4 EncounterUI (HUDLayer子节点)
- 显示奇遇事件卡片
- 由 EncounterSystem 触发时 show()

### 4.5 pause_menu.tscn (Z=260)
- 按钮: 继续修炼 / 保存进度 / 读取存档 / 设置 / 返回主菜单 / 退出游戏
- ESC: 关闭 (如果子面板未打开) / 关闭子面板
- 打开时暂停游戏 (tree.paused = true)
- "设置" 按钮 → 打开 settings_panel (Z=250)
- "返回主菜单" → 确认后触发场景切换

### 4.6 world_map.tscn (Z=220)
- 三个Tab: 地图 / 传送 / 探索度
- M键: 打开/关闭
- ESC: 关闭
- 功能: 鼠标拖拽平移 / 滚轮缩放 / 传送点旅行 / 探索度显示

### 4.7 help_panel.tscn (Z=180)
- 四个Tab: 教程 / 系统说明 / 控制 / 五行与战斗
- F1键: 打开/关闭
- ESC: 关闭
- 情境提示Toast功能
- **打开时不暂停游戏**

### 4.8 settings_panel.tscn (Z=250)
- 四个Tab: 画面 / 音效 / 控制 / 无障碍
- ESC: 关闭
- 设置持久化到 user://settings.json
- 恢复默认设置功能

### 4.9 inventory_panel.tscn (Z=200)
- 三个Tab: 背包 / 货币 / 快捷操作
- 6×5=30 槽位网格
- I键: 打开/关闭
- ESC: 关闭
- 功能: 拖拽移动 / 出售 / 拆解 / 一键操作 / 锁定物品

### 4.10 equipment_panel.tscn (Z=200)
- 四个Tab: 穿戴 / 强化 / 镶嵌 / 幻化
- 9个装备槽位 (主手/副手/头/衣/手/靴/项链/戒左/戒右)
- E键: 打开/关闭
- ESC: 关闭

### 4.11 loading_screen.tscn (Z=600)
- 进度条 + 状态文字 + 提示轮换 (5条)
- 版本显示
- 加载失败时显示错误界面 (重试/返回按钮)
- 非首次启动时 ESC 可取消
- 由 loading 流程 show/hide

### 4.12 confirm_dialog.tscn (Z=400)
- 通用确认对话框
- ENTER/SPACE: 确认
- ESC: 取消
- 动态按钮数量和文字

### 4.13 main_menu.tscn (独立场景)
- loading_screen 返回时切换到的场景
- 5个按钮 (当前 main_game_ui.tscn 中已有主菜单功能，这个场景可能未使用)

## 5. 键盘快捷键总表

| 快捷键 | 面板 | 面板脚本 | 行为 |
|--------|------|---------|------|
| ESC | pause_menu | pause_menu.gd | 打开/关闭暂停菜单 |
| C | character_panel | (main_game_ui_script 处理) | 打开角色面板 |
| M | world_map | world_map.gd | 打开/关闭大地图 |
| F1 | help_panel | help_panel.gd | 打开/关闭帮助面板 |
| I | inventory_panel | inventory_panel.gd | 打开/关闭背包面板 |
| E | equipment_panel | equipment_panel.gd | 打开/关闭装备面板 |
| SPACE/ENTER | dialogue_box | dialogue_box_script.gd | 继续对话文本 |
| + / = | world_map | world_map.gd | 放大 (面板打开时) |
| - | world_map | world_map.gd | 缩小 (面板打开时) |

## 6. 面板互斥规则

1. **暂停菜单打开时**: 其他面板不可打开 (需实现)
2. **大地图打开时**: 其他面板不可打开 (需实现)
3. **设置面板打开时**: 其他面板不可打开 (需实现)
4. **帮助面板**: 打开时不暂停游戏，可与其他面板共存
5. **奇遇面板 (Z=300)**: 打开时覆盖所有面板

## 7. 场景切换

当前游戏只有 **一个场景** (main_game_ui.tscn)，所有UI面板都是这个场景的子节点或动态加载的实例。

场景切换仅在以下情况发生:
- pause_menu "返回主菜单" → change_scene_to_file("res://src/scenes/main_menu.tscn")
- loading_screen "返回" → change_scene_to_file("res://src/scenes/main_menu.tscn")
- act_manager → change_scene_to_file(动态路径)

## 8. 测试验证清单

基于以上流程图，UI测试需要验证的核心路径:

### Batch 1: 核心启动
- [ ] 游戏启动 → main_game_ui 正常显示
- [ ] 主菜单所有按钮可交互
- [ ] 点击"开始新游戏" → HUDLayer 显示，角色面板可见
- [ ] 点击"加载游戏" → 有存档走角色面板，无存档走新游戏

### Batch 2: 快捷键面板
- [ ] ESC → pause_menu 打开/关闭
- [ ] M → world_map 打开/关闭
- [ ] F1 → help_panel 打开/关闭
- [ ] I → inventory_panel 打开/关闭
- [ ] E → equipment_panel 打开/关闭
- [ ] 各面板 ESC 可关闭

### Batch 3: 面板互斥
- [ ] 暂停菜单打开时，其他面板不可打开
- [ ] 大地图打开时，其他面板不可打开
- [ ] 设置面板打开时，其他面板不可打开
- [ ] 帮助面板打开时不暂停游戏

### Batch 4: 面板内功能
- [ ] pause_menu: 继续/保存/设置/返回/退出
- [ ] world_map: 三个Tab / 缩放 / 传送
- [ ] help_panel: 四个Tab / 情境提示
- [ ] settings_panel: 四个Tab / 持久化
- [ ] inventory_panel: 三个Tab / 拖拽 / 出售
- [ ] equipment_panel: 四个Tab / 强化 / 镶嵌

### Batch 5: 对话系统
- [ ] 对话正常显示 (说话人名称 + 对话文本)
- [ ] 选择按钮正常显示和点击
- [ ] ESC 跳过文本 / SPACE 继续
- [ ] 对话结束后触发效果

### Batch 6: 奇遇系统
- [ ] 奇遇触发时 EncounterUI 正确显示
- [ ] 奇遇UI打开时覆盖所有面板
