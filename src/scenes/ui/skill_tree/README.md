# 技能树可视化UI组件

## 概述

本目录包含技能树/学习路径系统的可视化界面实现,提供水墨卷轴风格的技能树展示和交互功能。

## 文件结构

```
skill_tree/
├── README.md                      # 本文件
├── SkillTreeUI.tscn              # 主场景文件
├── skill_tree_ui.gd              # 主控制脚本
├── SkillNode.tscn                # 技能节点组件场景
├── skill_node.gd                 # 节点交互逻辑
├── NodeDetailPanel.tscn          # 节点详情面板场景
├── node_detail_panel.gd          # 详情面板逻辑
├── BranchDialog.tscn             # 分支选择对话框场景
└── branch_dialog.gd              # 对话框逻辑
```

## 核心组件

### 1. SkillTreeUI (主控制器)
**文件**: `skill_tree_ui.gd`, `SkillTreeUI.tscn`

**功能**:
- 管理整体布局和视图控制
- 处理缩放、平移交互
- 加载技能树数据
- 协调各子组件

**信号**:
- `node_selected(node_id: String)` - 节点被选中
- `node_unlocked(node_id: String)` - 节点解锁成功
- `branch_chosen(node_id: String, branch_index: int)` - 分支被选择

**使用示例**:
```gdscript
# 在游戏主场景中实例化
var skill_tree_ui = preload("res://scenes/ui/skill_tree/SkillTreeUI.tscn").instantiate()
add_child(skill_tree_ui)

# 初始化技能树
var tree_manager = SkillTreeManager.new()
var unlock_manager = SkillUnlockManager.new()
skill_tree_ui.initialize(tree_manager, unlock_manager)

# 连接信号
skill_tree_ui.node_unlocked.connect(_on_skill_unlocked)
```

### 2. SkillNode (节点组件)
**文件**: `skill_node.gd`, `SkillNode.tscn`

**功能**:
- 显示节点图标和状态
- 处理悬停和点击事件
- 播放解锁动画

**信号**:
- `hovered()` - 鼠标悬停超过0.5秒
- `clicked()` - 节点被点击
- `unlock_requested()` - 请求解锁节点

**视觉特性**:
- 品阶颜色区分 (黄/蓝/紫/金)
- 状态透明度变化
- 墨水晕染粒子效果

### 3. NodeDetailPanel (详情面板)
**文件**: `node_detail_panel.gd`, `NodeDetailPanel.tscn`

**功能**:
- 显示节点详细信息
- 动态更新内容
- 提供解锁按钮

**信号**:
- `unlock_button_pressed(node_id: String)` - 解锁按钮被点击

**显示内容**:
- 招式名称和描述
- 品阶信息
- 属性数据 (伤害系数、内力消耗等)
- 前置条件和缺失条件

### 4. BranchDialog (分支对话框)
**文件**: `branch_dialog.gd`, `BranchDialog.tscn`

**功能**:
- 显示分支选项
- 处理用户选择
- 提供不可逆警告

**信号**:
- `branch_selected(node_id: String, branch_index: int)` - 分支被选择
- `dialog_closed()` - 对话框关闭

## 交互功能

### 缩放和平移
- **鼠标滚轮**: 缩放视图 (0.5x - 2.0x)
- **鼠标拖拽**: 平移视图
- **WASD键**: 方向移动
- **空格键**: 居中视图

### 节点交互
- **悬停0.5秒**: 显示详情面板
- **点击**: 选中节点
- **点击可解锁节点**: 触发解锁流程

### 分支选择
- 当节点有多个分支时,自动弹出选择对话框
- 显示每个分支的属性要求和效果差异
- 选择后不可更改

## 性能优化

### 节点实例缓存
```gdscript
var node_instances: Dictionary = {}  # 缓存节点实例
```

### 预加载场景
```gdscript
const SKILL_NODE_SCENE = preload("res://scenes/ui/skill_tree/SkillNode.tscn")
```

### 性能目标
- **帧率**: 60 FPS
- **绘制调用**: < 2000 draw calls
- **内存**: < 2GB

## 样式定制

### 水墨风格主题
如果存在主题资源,会自动应用:
```gdscript
if ResourceLoader.exists("res://assets/themes/ink_scroll_theme.tres"):
    var theme = load("res://assets/themes/ink_scroll_theme.tres")
    bg_panel.theme = theme
```

### 品阶颜色
在 `skill_node.gd` 中定义:
```gdscript
const TIER_COLORS = {
    1: Color(0.8, 0.7, 0.2, 1.0),  # 黄阶 - 黄色
    2: Color(0.2, 0.5, 0.9, 1.0),  # 玄阶 - 蓝色
    3: Color(0.6, 0.2, 0.8, 1.0),  # 地阶 - 紫色
    4: Color(0.9, 0.7, 0.1, 1.0)   # 天阶 - 金色
}
```

## 依赖系统

### Story 001: 学习路径类型
提供技能树数据结构:
- `SkillTreeManager`
- `SkillTree` 类
- `SkillNode` 类

### Story 002: 解锁机制
提供解锁验证逻辑:
- `SkillUnlockManager`
- `verify_unlock_conditions()` 方法

## 音效占位符

当前实现包含音效占位符函数:
- `_play_hover_sound()` - 悬停音效
- `_play_unlock_sound()` - 解锁音效

这些将在音频系统实现后替换为实际音效。

## 测试

### 手动测试
参考测试证据文档:
```
production/qa/evidence/skill-tree-visualization-evidence.md
```

### 测试要点
1. 水墨卷轴风格背景
2. 节点品阶颜色区分
3. 悬停显示详情面板
4. 解锁动画和视觉反馈
5. 分支选择对话框
6. 缩放和平移操作

## 已知限制

1. **音效**: 当前仅为占位符,需要音频系统支持
2. **主题**: 需要创建 `ink_scroll_theme.tres` 资源文件
3. **粒子纹理**: 需要创建 `ink_particle.png` 纹理资源

## 未来改进

1. 添加节点动画过渡效果
2. 实现节点搜索和过滤功能
3. 添加技能树导出/导入功能
4. 支持自定义布局算法
5. 添加无障碍功能支持

## 维护者

- **实现**: UI Programmer
- **Story**: Story 003: 可视化与交互
- **Epic**: 技能树/学习路径系统
- **日期**: 2026-04-28