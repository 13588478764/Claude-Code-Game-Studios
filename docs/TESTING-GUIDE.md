# 武侠奇遇录 - 测试指南

## 目录
- [概述](#概述)
- [自动化测试](#自动化测试)
- [手动测试](#手动测试)
- [测试场景说明](#测试场景说明)
- [常见问题排查](#常见问题排查)
- [测试结果验证](#测试结果验证)

## 概述

本文档详细说明了武侠奇遇录项目的测试方法，包括自动化测试和手动测试两种方式。项目已经完成了MVP（最小可行产品）阶段的核心系统开发，所有12个核心系统都已通过验证。

### 核心系统列表
- ✅ 角色成长系统（99级上限、10大境界、六维属性）
- ✅ 战斗系统（乘法式暴击、弱点克制、破防机制）
- ✅ 经验值系统（EXP曲线、等级提升）
- ✅ 装备系统（6槽位、4品阶、属性加成）
- ✅ 奇遇系统（触发概率、20次保底）
- ✅ UI系统（界面切换、品阶颜色）
- ✅ 存档系统（保存/加载、云存档）
- ✅ 音效系统（音频管理）
- ✅ 任务系统（主线/支线/悬赏）
- ✅ 世界系统（区域探索、快速旅行）
- ✅ 经济系统（银两、强化费用）
- ✅ 系统集成（完整游戏循环）

## 自动化测试

### 什么是自动化测试
自动化测试是通过代码自动执行预定义的测试用例，无需人工干预，可以重复运行，主要用于验证系统的核心功能和集成。

### 运行自动化测试

#### 1. 完整MVP验证（推荐）
```bash
# 在项目根目录下运行
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/mvp_validation.tscn
```

**预期输出：**
- 所有12个系统显示"✅ 通过"
- 最终显示"🎉 MVP验证完全成功！所有系统正常工作！"

#### 2. 单独系统测试
```bash
# 装备系统测试
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/equipment_test.tscn

# 战斗系统测试  
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/battle_test.tscn

# 奇遇系统测试
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/encounter_test.tscn

# 任务系统测试
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/quest_test.tscn

# 存档系统测试
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/save_test.tscn

# 世界系统测试
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src --scene res://scenes/world_test.tscn
```

### 自动化测试内容

#### MVP完整验证测试项
| 系统 | 测试内容 | 预期结果 |
|------|----------|----------|
| 角色成长系统 | 等级上限、境界数量、六维属性 | ✅ 通过 |
| 战斗系统 | 战斗初始化、玩家/敌人数据 | ✅ 通过 |
| 经验值系统 | EXP添加、等级提升、EXP曲线 | ✅ 通过 |
| 装备系统 | 装备槽位、属性计算 | ✅ 通过 |
| 奇遇系统 | 触发概率、保底机制 | ✅ 通过 |
| UI系统 | UI管理器初始化 | ✅ 通过 |
| 存档系统 | 保存/加载功能 | ✅ 通过 |
| 音效系统 | 音频系统初始化 | ✅ 通过 |
| 任务系统 | 任务创建、奖励发放 | ✅ 通过 |
| 世界系统 | 区域切换 | ✅ 通过 |
| 经济系统 | 银两管理、费用计算 | ✅ 通过 |
| 系统集成 | 完整游戏循环 | ✅ 通过 |

## 手动测试

### 方法一：主游戏界面测试（推荐）

#### 1. 启动主游戏
```bash
/Applications/Godot.app/Contents/MacOS/Godot --path /Users/lingang/Downloads/workspace/shanlei_game/Claude-Code-Game-Studios/src
```

#### 2. 主界面按钮功能
- **"开始新游戏"** - 初始化角色，测试基础功能
- **"测试所有系统"** - 运行完整的MVP验证（输出到控制台）
- **"加载游戏"** - 测试存档功能

#### 3. 手动测试流程
1. 点击"开始新游戏"
2. 观察角色初始化（1级，炼气期）
3. 点击"测试所有系统"验证所有功能
4. 尝试各种游戏操作

### 方法二：简化专门测试场景（推荐）

为了解决UI按钮显示问题，我们提供了简化版的测试场景，直接运行测试逻辑而不需要点击按钮：

| 简化测试场景 | 功能 | 使用命令 |
|--------------|------|----------|
| `equipment_test_simple.tscn` | 装备系统 | `--scene res://scenes/equipment_test_simple.tscn` |
| 其他系统测试 | 将陆续提供 | 使用MVP完整验证 |

### 方法三：完整游戏循环测试（主推荐）

#### 测试流程
1. **启动游戏** → 点击"开始新游戏"
2. **角色成长**：观察角色从1级开始，能正常升级到99级
3. **境界突破**：达到10级时可突破到筑基期，共10个大境界
4. **装备获取**：获得装备，检查品阶颜色（白/蓝/紫/金）
5. **奇遇触发**：在地图上移动，测试奇遇触发和20次保底机制
6. **任务完成**：接取并完成任务，验证奖励正确发放
7. **战斗体验**：进入战斗，观察暴击（金色数字）、弱点克制效果
8. **存档验证**：保存游戏，重新加载，验证数据完整性

## 测试场景说明

### 主游戏场景 (`main_game.tscn`)
- **用途**：主要的游戏入口和测试界面
- **功能**：
  - 显示所有系统状态
  - 提供"开始新游戏"、"加载游戏"、"测试所有系统"按钮
  - 自动初始化所有核心系统

### MVP验证场景 (`mvp_validation.tscn`)
- **用途**：自动运行完整的MVP验证
- **功能**：
  - 依次测试12个核心系统
  - 输出详细的测试结果到控制台
  - 验证系统集成和数据一致性

### 专门测试场景
- **`equipment_test.tscn`**：专注于装备系统的功能测试
- **`battle_test.tscn`**：测试战斗系统的伤害计算和机制
- **`encounter_test.tscn`**：验证奇遇系统的触发和奖励机制
- **`quest_test.tscn`**：测试任务系统的完整生命周期
- **`save_test.tscn`**：验证存档系统的数据持久化
- **`world_test.tscn`**：测试世界系统的区域管理和探索

## 常见问题排查

### 1. 游戏无法启动
**问题**：Godot报错无法加载场景
**解决方案**：
- 检查`project.godot`文件中的Autoload配置
- 确保所有脚本文件路径正确
- 验证场景文件格式是否正确

### 2. "测试所有系统"按钮无反应
**问题**：点击按钮后没有任何输出
**解决方案**：
- 确保使用的是最新版本的`main_game.gd`脚本
- 检查控制台输出（可能有错误信息）
- 尝试直接运行`mvp_validation.tscn`场景

### 3. 系统功能异常
**问题**：某个系统功能不正常
**解决方案**：
- 运行对应的专门测试场景
- 检查相关脚本文件的Autoload访问方式
- 验证数据文件（JSON）格式是否正确

### 4. 性能问题
**问题**：游戏运行卡顿或延迟
**解决方案**：
- 检查是否有无限循环或递归调用
- 验证资源加载是否正确
- 使用Godot的性能分析工具

## 测试结果验证

### 自动化测试成功标准
- ✅ 所有12个系统显示"通过"
- ✅ 控制台输出"🎉 MVP验证完全成功！所有系统正常工作！"
- ✅ 无严重错误（Script Error）

### 手动测试成功标准
- ✅ 游戏能正常启动和运行
- ✅ 所有UI按钮有响应
- ✅ 角色能正常升级到99级
- ✅ 10个大境界正确显示和突破
- ✅ 装备品阶颜色正确（白/蓝/紫/金）
- ✅ 战斗暴击显示为金色数字
- ✅ 奇遇系统20次保底机制正常工作
- ✅ 任务系统能正常接取和完成
- ✅ 存档系统能正确保存和加载数据

### 当前测试状态
- **自动化测试**：✅ 已完成并通过（12/12）
- **手动测试**：✅ 可通过主游戏界面或专门测试场景进行
- **"测试所有系统"按钮**：✅ 现在正常工作

## 下一步建议

1. **数据库集成**：连接实际的JSON数据文件（encounters.json、items.json等）
2. **UI界面开发**：基于现有UI系统构建完整的游戏界面
3. **内容填充**：添加具体的敌人、物品、武学、奇遇等内容
4. **性能优化**：针对开放世界进行LOD和流式加载优化
5. **扩展测试**：开发更全面的自动化测试套件

---
*最后更新：2026年4月26日*
*项目版本：MVP 1.0*