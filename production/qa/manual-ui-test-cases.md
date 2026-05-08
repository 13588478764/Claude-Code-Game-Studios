# UI/HUD 手动测试用例

> **说明**: 以下测试用例因依赖场景树和视觉渲染，无法在 headless 模式下自动运行，需要手动验证。
> 
> **测试环境**: Godot 4.6 | 目标平台: Web/浏览器
> **输入方式**: 键盘/鼠标、手柄
> **创建日期**: 2026-05-03

---

## 场景说明

### 可用测试场景

| 场景路径 | 用途 | 包含系统 | 启动方式 |
|----------|------|----------|----------|
| `res://src/scenes/main_game_ui.tscn` | 主游戏入口（主菜单） | CharacterSystem, CombatSystem, EncounterSystem, EquipmentSystem, UIManager 等 | Godot 编辑器按 F5 运行 |
| `res://scenes/battle_test.tscn` | 战斗系统测试 | CombatSystem, CharacterSystem, DatabaseManager | Godot 编辑器打开后按 F6 运行当前场景 |
| `res://scenes/encounter_test.tscn` | 奇遇系统测试 | EncounterSystem, CharacterSystem, DatabaseManager | Godot 编辑器打开后按 F6 运行当前场景 |
| `res://scenes/ui_test.tscn` | UI 系统测试 | UIManager, CharacterSystem, EquipmentSystem, CombatSystem | Godot 编辑器打开后按 F6 运行当前场景 |
| `res://src/scenes/ui/hud/HUD.tscn` | HUD 界面（需配合主场景） | PlayerStatusPanel, PartyPanel, ActionQueueDisplay, HotbarController | 通过主场景调用 UIManager 显示 |
| `res://src/scenes/ui/character_growth_ui.tscn` | 角色成长界面 | TabContainer（角色面板、武学技能、属性等） | 通过主场景或 UIManager 调用 |
| `res://src/scenes/ui/encounter_ui.tscn` | 奇遇界面 | 奇遇触发和选择 UI | 通过 EncounterSystem 触发 |

### 场景依赖关系

```
main_game_ui.tscn (主入口)
├── character_panel.tscn (角色面板子场景)
└── 调用 UIManager 显示:
    └── HUD.tscn
        ├── player_status_panel.tscn (玩家状态)
        ├── party_panel.tscn (队伍状态)
        │   └── party_member_slot.tscn (队员槽位)
        ├── action_queue_display.tscn (行动队列)
        ├── enemy_info_panel.tscn (敌人信息)
        ├── hotbar (快捷栏)
        └── dialogue_box.tscn (对话)
```

### 测试启动步骤

**方式一：从主菜单开始（推荐）**
1. Godot 编辑器打开项目
2. 打开 `res://scenes/main_game_ui.tscn`
3. 按 F5 运行
4. 点击"开始新游戏"按钮初始化所有系统
5. 根据需要点击"测试所有系统"按钮

**方式二：直接运行测试场景**
1. Godot 编辑器打开对应测试场景（如 `battle_test.tscn`）
2. 按 F6 运行当前场景
3. 场景内按钮直接调用对应系统测试方法

---

## 资源状态说明

| 资源目录 | 状态 | 对测试的影响 |
|----------|------|-------------|
| `assets/ui/party_portraits/` | 空（只有 README.md） | 队友头像显示占位符，不影响布局测试 |
| `assets/ui/element_icons/` | 5 个五行图标 PNG | 敌人弱点图标可正常显示 |
| `assets/ui/realm_icons/` | TXT 占位符 | 境界图标显示文本或占位符 |

**结论**: 所有 UI 逻辑和布局测试可以正常进行，仅视觉图片使用占位符。

---

## 一、队友状态显示 (PartyStatusDisplay)

### AC-1: 队友头像正确显示 (60x60px)

**用例 ID**: PARTY-001

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 游戏中有至少 1 名队友

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行
3. 点击"开始新游戏"按钮（初始化 CharacterSystem 和所有系统）
4. HUD 会自动显示，包含 PartyPanel 子场景（位于 `res://src/scenes/ui/hud/party_panel.tscn`）

**测试步骤**:
1. 查看 HUD 左上角的队友状态面板（PartyPanel）
2. 检查每个队友槽位的头像（`party_member_slot.tscn` 中的 portrait 节点，60x60）
3. 检查头像布局对齐

**预期结果**:
- [ ] 头像尺寸为 60x60 像素（PartyMemberSlot.portrait 节点）
- [ ] 头像显示灰色圆形占位符（因为 `assets/ui/party_portraits/` 目录为空）
- [ ] 头像与名字、HP 条对齐

---

**用例 ID**: PARTY-002

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 游戏中有队友

**启动步骤**: 同 PARTY-001

**测试步骤**:
1. 确认队友头像正常显示
2. 检查 `res://assets/ui/party_portraits/` 目录中是否有对应图片（预期：只有 README.md）

**预期结果**:
- [ ] 无图片时显示灰色圆形占位符
- [ ] 占位符不影响布局和尺寸

---

### AC-2: 队友 HP 条正确显示 (240x16px)

**用例 ID**: PARTY-003

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 游戏中有至少 1 名队友

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行
3. 点击"开始新游戏"按钮
4. 查看 HUD 左上角的队友状态面板

**测试步骤**:
1. 查看队友状态面板中的 HP 条（PartyMemberSlot.hp_bar，尺寸 240x16）
2. 检查 HP 条尺寸和数值显示（格式: "当前值 / 最大值"）

**预期结果**:
- [ ] HP 条尺寸为 240x16 像素
- [ ] HP 标签格式为 "当前值 / 最大值"（如 "75 / 100"）
- [ ] HP 条填充比例与数值一致

---

### AC-3: 倒地状态视觉标识

**用例 ID**: PARTY-004

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 队友倒地 (is_downed = true)

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行
3. 点击"开始新游戏"按钮
4. 通过控制台调用使队友倒地：`/root/CharacterSystem.party[0].is_downed = true`
5. 或调用战斗系统方法使队友受伤至倒地状态

**测试步骤**:
1. 使一名队友倒地
2. 观察 PartyPanel 中该队友槽位的视觉变化
3. 检查 `downed_overlay` 节点是否显示

**预期结果**:
- [ ] 头像和槽位显示灰色滤镜效果（PartyMemberSlot 的 downed_overlay 可见）
- [ ] HP 条隐藏不显示（hp_bar.visible = false）
- [ ] 有明显的倒地视觉区分

---

**用例 ID**: PARTY-005

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 队友从倒地状态复活

**启动步骤**:
1. 完成 PARTY-004 使队友倒地
2. 通过控制台恢复队友：`/root/CharacterSystem.party[0].is_downed = false`
3. 或调用治疗/复活方法

**测试步骤**:
1. 使倒地的队友复活
2. 观察 PartyPanel 中该队友槽位的视觉变化

**预期结果**:
- [ ] 灰色滤镜消失（downed_overlay 隐藏）
- [ ] HP 条重新显示（hp_bar.visible = true）
- [ ] 恢复正常状态显示

---

### AC-4: 最多显示 3 名队友

**用例 ID**: PARTY-006

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 游戏中有超过 3 名队友

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行，点击"开始新游戏"
3. 通过控制台添加队友：
   ```
   var cs = get_node("/root/CharacterSystem")
   cs.add_party_member(...) # 调用 5 次
   ```

**测试步骤**:
1. 添加 5 名队友到队伍
2. 观察 HUD 中的 PartyPanel（路径: HUD/PartyPanel）
3. 检查只显示的队友数量

**预期结果**:
- [ ] 只显示前 3 名队友（PartySlotsContainer 中最多 3 个 PartyMemberSlot）
- [ ] 第 4、5 名队友不在面板中显示
- [ ] 面板布局正常，不溢出

---

### AC-5: 队友加入/离开时 UI 更新

**用例 ID**: PARTY-007

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 队伍初始为空

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行，点击"开始新游戏"
3. 确认 PartyPanel 中无队友（或显示空状态）

**测试步骤**:
1. 通过控制台或游戏事件添加一名队友：
   ```
   var cs = get_node("/root/CharacterSystem")
   cs.add_party_member(...) # 使用实际角色数据
   ```
2. 观察 PartyPanel 的变化

**预期结果**:
- [ ] 新队友槽位（PartyMemberSlot）出现在 PartySlotsContainer 中
- [ ] 空状态提示（如有）消失

---

**用例 ID**: PARTY-008

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 队伍中有队友

**启动步骤**:
1. 完成 PARTY-007 添加至少 1 名队友

**测试步骤**:
1. 通过控制台或游戏事件移除一名队友：
   ```
   var cs = get_node("/root/CharacterSystem")
   cs.remove_party_member(0) # 移除第一个队友
   ```
2. 观察 PartyPanel 的变化

**预期结果**:
- [ ] 被移除的队友槽位从 PartySlotsContainer 中消失
- [ ] 剩余队友槽位位置调整正确（VBoxContainer 自动布局）
- [ ] 如果队伍为空，显示空状态提示

---

### AC-6: 队伍为空时显示空状态

**用例 ID**: PARTY-009

**启动场景**: `res://scenes/main_game_ui.tscn` ✅ 已存在

**前置条件**: 队伍中没有队友

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/main_game_ui.tscn`
2. 按 F5 运行，点击"开始新游戏"
3. 确认 PartyPanel 中没有队友

**测试步骤**:
1. 观察 PartyPanel（路径: HUD/PartyPanel）
2. 检查空状态显示

**预期结果**:
- [ ] 显示空状态提示文本（或保持空白）
- [ ] 面板区域不显示任何 PartyMemberSlot 节点
- [ ] 布局正常，不显示错误

---

### AC-10: HP 变化平滑过渡动画 (0.1 秒)

**用例 ID**: PARTY-010

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 队伍中有队友

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/battle_test.tscn`
2. 按 F6 运行当前场景
3. 点击"开始战斗测试"按钮初始化战斗

**测试步骤**:
1. 使队友受到伤害（通过战斗系统或控制台调用）
2. 观察 PartyPanel 中该队友的 HP 条变化

**预期结果**:
- [ ] HP 条数值平滑过渡，非瞬间跳变（Tween 动画）
- [ ] 过渡时间约 0.1 秒
- [ ] HP 标签数值立即更新

---

**用例 ID**: PARTY-011

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 队伍中有队友，HP 为满

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/battle_test.tscn`
2. 按 F6 运行当前场景
3. 点击"开始战斗测试"按钮

**测试步骤**:
1. 使队友 HP 降至不同百分比（通过战斗系统或控制台）
2. 观察 HP 条颜色变化：
   - 先降至 20%（如 20/100）观察颜色
   - 再升至 50% 观察颜色
   - 最后恢复到 80% 观察颜色

**预期结果**:
- [ ] HP > 60% 时 HP 条为绿色
- [ ] HP 30-60% 时 HP 条为黄色
- [ ] HP < 30% 时 HP 条为红色

---

## 二、敌人信息面板 (EnemyInfoPanel)

### 场景说明

| 资源 | 路径 | 状态 |
|------|------|------|
| 主场景 | `res://scenes/battle_test.tscn` | ✅ 已存在 |
| 面板场景 | `res://src/scenes/ui/hud/enemy_info_panel.tscn` | ✅ 已存在 |
| HUD 场景 | `res://src/scenes/ui/hud/HUD.tscn` | ✅ 已存在（包含面板作为子节点） |
| 弱点图标 | `res://src/scenes/ui/hud/weakness_icon.tscn` | ✅ 已存在 |
| 五行图标 | `res://assets/ui/element_icons/` | ✅ 5 个 PNG 文件可用 |

### 代码结构验证

**用例 ID**: ENEMY-001

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 战斗场景中有敌人

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/battle_test.tscn`
2. 按 F6 运行当前场景
3. 点击"开始战斗测试"按钮

**测试步骤**:
1. 进入战斗场景并启动战斗
2. 查看 HUD 中的敌人信息面板（位于 `res://src/scenes/ui/hud/enemy_info_panel.tscn`）

**预期结果**:
- [ ] 面板正确实例化，无错误
- [ ] 文件命名符合 snake_case 规范（enemy_info_panel.gd）
- [ ] 类名使用 PascalCase（EnemyInfoPanel）

---

### 场景存在性检查

**用例 ID**: ENEMY-002

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 战斗场景已加载

**启动步骤**: 同 ENEMY-001

**测试步骤**:
1. 检查敌人信息面板的场景文件是否存在：`res://src/scenes/ui/hud/enemy_info_panel.tscn`
2. 确认 HUD 中正确实例化该面板
3. 检查节点路径：HUD > EnemyInfoPanel

**预期结果**:
- [ ] 场景文件存在于 `res://src/scenes/ui/hud/enemy_info_panel.tscn`
- [ ] 节点层级结构正确（Control > VBoxContainer > 各子节点）
- [ ] 无 "Node not found" 错误

---

### 命名规范

**用例 ID**: ENEMY-003

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 敌人信息面板已加载

**启动步骤**: 同 ENEMY-001

**测试步骤**:
1. 在 Godot 编辑器中打开 `res://src/scenes/ui/hud/enemy_info_panel.tscn`
2. 检查面板中所有子节点的命名：
   - EnemyNameLabel
   - EnemyLevelLabel
   - HPContainer
   - HPBar
   - HPLabel
   - WeaknessContainer
   - StatusContainer
   - DownIndicator
   - BreakIndicator
   - BossBorder
   - NoTargetLabel
   - FadeAnimation
3. 验证脚本中的变量命名规范

**预期结果**:
- [ ] 节点名称使用 PascalCase
- [ ] 变量使用 snake_case
- [ ] 信号使用 snake_case 过去式

---

### 公共接口验证

**用例 ID**: ENEMY-004

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 敌人信息面板已加载

**启动步骤**: 同 ENEMY-001

**测试步骤**:
1. 通过控制台调用公共接口方法：
   ```
   var panel = get_node("/root/...") # 获取面板实例
   panel.update_enemy(...) # 调用更新方法
   ```
2. 验证方法返回值

**预期结果**:
- [ ] 所有公共接口方法可调用
- [ ] 方法返回预期类型
- [ ] 无运行时错误

---

### 元素弱点图标显示

**用例 ID**: ENEMY-005

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 敌人有五行弱点

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/battle_test.tscn`
2. 按 F6 运行
3. 确保敌人有五行弱点数据（金/木/水/火/土）

**测试步骤**:
1. 进入有弱点的敌人战斗
2. 查看敌人信息面板中的 WeaknessContainer
3. 检查弱点图标（使用 `res://assets/ui/element_icons/` 中的 PNG）

**预期结果**:
- [ ] 弱点图标正确显示对应的五行元素（metal.png, wood.png, water.png, fire.png, earth.png）
- [ ] 图标尺寸为 32x32 像素
- [ ] 已发现的弱点有高亮效果

---

**用例 ID**: ENEMY-006

**启动场景**: `res://scenes/battle_test.tscn` ✅ 已存在

**前置条件**: 敌人有多个弱点

**启动步骤**: 同 ENEMY-005

**测试步骤**:
1. 使用有多个弱点的敌人
2. 观察 WeaknessContainer 中所有弱点图标的排列

**预期结果**:
- [ ] 多个弱点图标水平排列（HBoxContainer）
- [ ] 图标间距一致（separation = 4）
- [ ] 无重叠或溢出

---

## 三、角色成长 UI (CharacterGrowthUI)

### 场景说明

| 资源 | 路径 | 状态 |
|------|------|------|
| 主场景 | `res://src/scenes/ui/character_growth_ui.tscn` | ✅ 已存在 |
| 角色面板 | `res://scenes/ui/character_panel.tscn` | ✅ 已存在（main_game_ui.tscn 已实例化） |
| 技能树 UI | `res://src/scenes/ui/skill_tree/SkillTreeUI.tscn` | ✅ 已存在 |
| 技能节点 | `res://src/scenes/ui/skill_tree/SkillNode.tscn` | ✅ 已存在 |
| 节点详情 | `res://src/scenes/ui/skill_tree/NodeDetailPanel.tscn` | ✅ 已存在 |

### AC: 境界显示

**用例 ID**: GROWTH-001

**启动场景**: `res://src/scenes/ui/character_growth_ui.tscn` ✅ 已存在

**前置条件**: 角色已创建

**启动步骤**:
1. Godot 编辑器打开 `res://src/scenes/ui/character_growth_ui.tscn`
2. 按 F6 运行当前场景
3. 或从 `res://scenes/main_game_ui.tscn` 启动后通过 UIManager 调用

**测试步骤**:
1. 打开角色成长 UI
2. 查看 TabContainer 中的"角色面板"标签页
3. 查看 LevelContainer 中的 LevelLabel 和境界显示

**预期结果**:
- [ ] 境界名称正确显示（如"炼气"、"筑基"）
- [ ] 境界进度条显示当前进度
- [ ] 数值显示格式正确

---

### AC: 武学技能列表

**用例 ID**: GROWTH-002

**启动场景**: `res://src/scenes/ui/character_growth_ui.tscn` ✅ 已存在

**前置条件**: 角色已学会至少一个武学

**启动步骤**:
1. Godot 编辑器打开 `res://src/scenes/ui/character_growth_ui.tscn`
2. 按 F6 运行
3. 确保角色系统已初始化并有武学数据

**测试步骤**:
1. 打开角色成长 UI
2. 切换到武学/技能标签页（TabContainer 中）
3. 查看技能列表（SkillTreeUI 中的 SkillNode 列表）

**预期结果**:
- [ ] 技能名称正确显示
- [ ] 技能品阶有颜色区分（普通/稀有/史诗/传说）
- [ ] 技能等级显示正确

---

### AC: 属性面板

**用例 ID**: GROWTH-003

**启动场景**: `res://src/scenes/ui/character_growth_ui.tscn` ✅ 已存在

**前置条件**: 角色有属性数据

**启动步骤**: 同 GROWTH-002

**测试步骤**:
1. 打开角色成长 UI
2. 查看属性面板（TabContainer 中对应的标签页）
3. 检查所有基础属性显示

**预期结果**:
- [ ] 所有基础属性显示（力量、敏捷、体质等）
- [ ] 福缘属性正确显示
- [ ] 装备加成有标识

---

## 四、奇遇 UI (EncounterUI)

### 场景说明

| 资源 | 路径 | 状态 |
|------|------|------|
| 测试场景 | `res://scenes/encounter_test.tscn` | ✅ 已存在 |
| 奇遇 UI | `res://src/scenes/ui/encounter_ui.tscn` | ✅ 已存在 |
| 对话系统 | `res://src/scenes/ui/dialogue_box.tscn` | ✅ 已存在（HUD.tscn 子场景） |

### AC: 奇遇触发提示

**用例 ID**: ENCOUNTER-001

**启动场景**: `res://scenes/encounter_test.tscn` ✅ 已存在

**前置条件**: 奇遇系统已初始化

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/encounter_test.tscn`
2. 按 F6 运行当前场景（包含 DatabaseManager, EncounterSystem, CharacterSystem）
3. 点击"测试触发概率"按钮测试奇遇触发逻辑

**测试步骤**:
1. 点击"测试触发概率"按钮
2. 观察 DebugLabel 的输出信息
3. 或使用控制台调用奇遇触发方法
4. 观察是否出现奇遇预警提示（通过 UIManager 或 NotificationManager）

**预期结果**:
- [ ] 预警提示在奇遇触发前出现
- [ ] 预警时间为 2-3 秒
- [ ] 提示文本清晰易懂

---

### AC: 奇遇选择界面

**用例 ID**: ENCOUNTER-002

**启动场景**: `res://scenes/encounter_test.tscn` ✅ 已存在

**前置条件**: 奇遇已触发

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/encounter_test.tscn`
2. 按 F6 运行
3. 点击"测试奇遇选择"按钮

**测试步骤**:
1. 触发奇遇后观察奇遇选择界面（`res://src/scenes/ui/encounter_ui.tscn`）
2. 查看可用的选项按钮
3. 检查奇遇描述文本

**预期结果**:
- [ ] 奇遇描述文本正确显示
- [ ] 选项按钮可用（可点击）
- [ ] 界面布局合理

---

### AC: 奇遇结果反馈

**用例 ID**: ENCOUNTER-003

**启动场景**: `res://scenes/encounter_test.tscn` ✅ 已存在

**前置条件**: 玩家已做出奇遇选择

**启动步骤**:
1. 完成 ENCOUNTER-002 触发奇遇选择
2. 点击"测试奖励执行"按钮测试奖励逻辑

**测试步骤**:
1. 选择一个奇遇选项
2. 观察结果反馈（通过 DebugLabel 或 UI 更新）
3. 检查角色属性/经验/物品是否正确更新

**预期结果**:
- [ ] 结果文本描述清晰
- [ ] 奖励/惩罚正确应用
- [ ] UI 正确更新显示数值

---

## 五、Hotbar 系统

### 场景说明

| 资源 | 路径 | 状态 |
|------|------|------|
| HUD 场景 | `res://src/scenes/ui/hud/HUD.tscn` | ✅ 已存在（包含 HotbarController 节点） |
| 快捷栏脚本 | `res://src/scripts/ui/hud/HotbarController.gd` | ✅ 已存在 |
| 快捷栏槽位 | `res://src/scripts/ui/hud/HotbarSlot.gd` | ✅ 已存在 |
| 快捷栏场景 | 无独立 .tscn 文件 | ⚠️ 作为 HUD.tscn 的子节点存在 |

**注意**: HotbarController 是 HUD.tscn 中的一个 PanelContainer 子节点，位于屏幕底部中央。
位置: `HUD/HotbarController`，锚点设置在底部中央（anchor_left=0.5, anchor_top=1.0）
尺寸: offset_left=-280, offset_top=-90, offset_right=280, offset_bottom=-20（560x70 像素）

### AC: 快捷栏显示

**用例 ID**: HOTBAR-001

**启动场景**: `res://scenes/ui_test.tscn` ✅ 已存在

**前置条件**: 玩家有可用的技能/物品

**启动步骤**:
1. Godot 编辑器打开 `res://scenes/ui_test.tscn`
2. 按 F6 运行当前场景（包含 UIManager, CharacterSystem, EquipmentSystem, CombatSystem）
3. 点击"测试战斗界面"按钮进入战斗模式
4. HUD 会显示 HotbarController（位于屏幕底部中央）

**测试步骤**:
1. 查看屏幕底部的快捷栏（路径: HUD/HotbarController）
2. 检查槽位数量和布局
3. 检查快捷键标签（1-9）

**预期结果**:
- [ ] 槽位数量正确（根据 HotbarController 配置）
- [ ] 快捷栏位于屏幕底部中央（560x70 像素区域）
- [ ] 快捷键标签显示（1-9）
- [ ] 槽位间距一致

---

### AC: 快捷键激活

**用例 ID**: HOTBAR-002

**启动场景**: `res://scenes/ui_test.tscn` ✅ 已存在

**前置条件**: 快捷栏有技能/物品

**启动步骤**:
1. 完成 HOTBAR-001 启动场景
2. 确保快捷栏中有可用的技能/物品槽位

**测试步骤**:
1. 按下数字键 1-9（对应快捷栏槽位）
2. 观察对应槽位的视觉反馈
3. 检查控制台输出确认技能激活

**预期结果**:
- [ ] 对应槽位有高亮反馈（HotbarSlot 的视觉变化）
- [ ] 技能/物品正确激活（通过 HotbarController.gd 的输入处理）
- [ ] 冷却时间显示正确（如有冷却系统）

---

## 六、控制台调试命令

### 常用调试命令

在 Godot 编辑器运行时按 `~` 键打开控制台，可以输入以下命令：

| 命令 | 用途 | 测试用例 |
|------|------|----------|
| `var cs = get_node("/root/CharacterSystem")` | 获取角色系统实例 | PARTY-007, PARTY-008 |
| `cs.party` | 查看当前队伍列表 | PARTY-006 |
| `cs.party[0].is_downed = true` | 设置队友倒地状态 | PARTY-004 |
| `cs.party[0].is_downed = false` | 恢复队友状态 | PARTY-005 |
| `cs.party[0].current_hp` | 查看当前 HP | PARTY-010, PARTY-011 |
| `var es = get_node("/root/EncounterSystem")` | 获取奇遇系统实例 | ENCOUNTER-001~003 |
| `var hud = get_node("/root/HUD")` | 获取 HUD 实例 | HOTBAR-001, HOTBAR-002 |
| `hud.current_mode` | 查看当前 HUD 模式 | HOTBAR-001 |

### 获取 UI 节点实例

```gdscript
# 获取队友面板
var party_panel = get_node("/root/HUD/PartyPanel")

# 获取敌人信息面板
var enemy_panel = get_node("/root/HUD/EnemyInfoPanel")

# 获取快捷栏控制器
var hotbar = get_node("/root/HUD/HotbarController")

# 获取角色成长 UI
var growth_ui = get_node("/root/CharacterGrowthUI")
```

---

## 测试执行记录

| 用例 ID | 测试日期 | 测试结果 | 备注 | 测试人 |
|---------|----------|----------|------|--------|
| PARTY-001 | | ☐ 通过 ☐ 失败 | | |
| PARTY-002 | | ☐ 通过 ☐ 失败 | | |
| PARTY-003 | | ☐ 通过 ☐ 失败 | | |
| PARTY-004 | | ☐ 通过 ☐ 失败 | | |
| PARTY-005 | | ☐ 通过 ☐ 失败 | | |
| PARTY-006 | | ☐ 通过 ☐ 失败 | | |
| PARTY-007 | | ☐ 通过 ☐ 失败 | | |
| PARTY-008 | | ☐ 通过 ☐ 失败 | | |
| PARTY-009 | | ☐ 通过 ☐ 失败 | | |
| PARTY-010 | | ☐ 通过 ☐ 失败 | | |
| PARTY-011 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-001 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-002 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-003 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-004 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-005 | | ☐ 通过 ☐ 失败 | | |
| ENEMY-006 | | ☐ 通过 ☐ 失败 | | |
| GROWTH-001 | | ☐ 通过 ☐ 失败 | | |
| GROWTH-002 | | ☐ 通过 ☐ 失败 | | |
| GROWTH-003 | | ☐ 通过 ☐ 失败 | | |
| ENCOUNTER-001 | | ☐ 通过 ☐ 失败 | | |
| ENCOUNTER-002 | | ☐ 通过 ☐ 失败 | | |
| ENCOUNTER-003 | | ☐ 通过 ☐ 失败 | | |
| HOTBAR-001 | | ☐ 通过 ☐ 失败 | | |
| HOTBAR-002 | | ☐ 通过 ☐ 失败 | | |
