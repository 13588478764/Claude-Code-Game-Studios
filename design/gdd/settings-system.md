# 设置系统 (Settings System)

> **Status**: In Design
> **Author**: 系统设计师
> **Last Updated**: 2026-05-06
> **Implements Pillar**: 技术基础设施
> **Cross-Reference**: `design/ux/settings.md` (UX规格)

## Overview

设置系统是《武侠奇遇录》的技术基础设施，负责统一管理所有玩家可自定义的配置选项，包括画面、音效、控制和无障碍设置。系统提供配置的读取、修改、验证、持久化功能，并确保设置变更安全可靠地应用到游戏中。

**技术层面**：设置系统基于配置文件（JSON格式）和内存缓存的双层架构。配置数据在游戏启动时加载到内存缓存，运行时修改首先更新缓存，关闭设置界面或触发确认时持久化到配置文件。系统支持配置验证、回滚和恢复默认值功能。

**玩家体验层面**：玩家通过设置界面（修炼设置）快速调整游戏体验，音效调整即时生效，画面设置需确认后应用以避免黑屏或不可操作。无障碍设置（色盲模式、文本缩放、减少运动）即时生效，确保玩家可以紧急调整不适。

## Player Fantasy

**核心幻想：掌控自己的修真环境，让游戏完全符合个人需求**

设置系统虽然不直接贡献于游戏的核心玩法循环，但它是玩家与游戏之间的"桥梁"——让玩家能够根据自己的硬件条件、个人偏好和无障碍需求，定制最舒适的修真体验。

**玩家应该感受到**：

1. **控制权**：每个设置项都可调整，没有"黑盒"配置。玩家清楚知道每个选项的作用和后果。

2. **安全感**：画面设置变更时有5秒倒计时确认，超时自动恢复，避免黑屏或无法操作的风险。

3. **即时反馈**：音效调整立即听到变化，无障碍设置立即生效，减少等待和确认步骤。

4. **个性化**：键鼠/手柄绑定完全可自定义，色盲模式覆盖3种类型，UI/文本缩放支持100%~175%，满足不同玩家需求。

**参考体验**：
- 《巫师3》的画面设置确认机制——调整分辨率后有倒计时恢复
- 《战神4》的无障碍选项——丰富且即时无需确认
- 《英雄联盟》的按键绑定——支持自定义和冲突检测

## Detailed Rules

### Core Rules

#### 1. 设置数据结构

设置系统管理以下分类的配置数据：

**画面设置 (GraphicsSettings)**:
| 字段 | 类型 | 默认值 | 可选项 | 生效模式 |
|------|------|--------|--------|----------|
| resolution | String | "1920x1080" | ["1920x1080", "1280x720", "1600x900", "2560x1440"] | 需确认 |
| fullscreen | bool | true | [true, false] | 需确认 |
| quality | String | "高" | ["低", "中", "高", "极高"] | 需确认 |
| ui_scale | int | 100 | 100~175 (step: 25) | 即时生效 |
| reduce_motion | bool | false | [true, false] | 即时生效 |

**音效设置 (AudioSettings)**:
| 字段 | 类型 | 默认值 | 范围 | 生效模式 |
|------|------|--------|------|----------|
| master_volume | int | 80 | 0~100 | 即时生效 |
| bgm_volume | int | 80 | 0~100 | 即时生效 |
| sfx_volume | int | 80 | 0~100 | 即时生效 |
| ui_volume | int | 80 | 0~100 | 即时生效 |
| ambient_volume | int | 60 | 0~100 | 即时生效 |

**控制设置 (ControlSettings)**:
| 字段 | 类型 | 默认值 | 说明 | 生效模式 |
|------|------|--------|------|----------|
| key_bindings | Dictionary | 见预设 | 键鼠操作映射 | 即时生效 |
| gamepad_bindings | Dictionary | 见预设 | 手柄操作映射 | 即时生效 |
| mouse_sensitivity | String | "中" | ["低", "中", "高"] | 即时生效 |

**无障碍设置 (AccessibilitySettings)**:
| 字段 | 类型 | 默认值 | 可选项 | 生效模式 |
|------|------|--------|--------|----------|
| colorblind_mode | String | "关闭" | ["关闭", "红色盲", "绿色盲", "蓝黄色盲"] | 即时生效 |
| text_scale | int | 100 | 100~175 (step: 25) | 即时生效 |
| subtitles_enabled | bool | true | [true, false] | 即时生效 |
| reduce_motion | bool | false | [true, false] | 即时生效 |

> **注意**: `reduce_motion` 在画面设置页和无障碍设置页同时出现，但两者引用同一底层数据，修改任一处都会同步更新。

#### 2. 默认按键绑定预设

**键鼠绑定 (key_bindings) 默认值**:
```json
{
  "move_up": "W",
  "move_down": "S",
  "move_left": "A",
  "move_right": "D",
  "interact": "E",
  "jump": "Space",
  "open_menu": "Escape",
  "open_help": "F1",
  "open_map": "M",
  "toggle_minimap": "N",
  "open_character": "C",
  "open_skill_tree": "K",
  "open_inventory": "I",
  "hotbar_1": "1",
  "hotbar_2": "2",
  "hotbar_3": "3",
  "hotbar_4": "4",
  "hotbar_5": "5",
  "hotbar_6": "6",
  "hotbar_7": "7",
  "hotbar_8": "8",
  "confirm": "Enter",
  "cancel": "Backspace",
  "target_next": "Right",
  "target_prev": "Left",
  "switch_up": "Up",
  "switch_down": "Down"
}
```

**手柄绑定 (gamepad_bindings) 默认值**:
```json
{
  "move": "left_stick",
  "cursor": "right_stick",
  "confirm": "a",
  "cancel": "b",
  "use_item": "x",
  "open_menu": "y",
  "target_up": "dpad_up",
  "target_down": "dpad_down",
  "hotbar_prev": "dpad_left",
  "hotbar_next": "dpad_right",
  "prev_hotbar_slot": "lb",
  "next_hotbar_slot": "rb",
  "open_skill_menu": "lt",
  "open_inventory_menu": "rt",
  "open_main_menu": "start",
  "open_map": "select",
  "toggle_minimap": "l3",
  "lock_target": "r3",
  "mouse_sensitivity": "中"
}
```

#### 3. 配置文件格式与存储路径

**配置文件格式**: JSON
**存储路径**:
- **Web平台**: `user://settings.json` (Godot user:// 目录，浏览器 localStorage)
- **文件结构**:

```json
{
  "version": "1.0",
  "last_modified": "2026-05-06T12:00:00Z",
  "graphics": {
    "resolution": "1920x1080",
    "fullscreen": true,
    "quality": "高",
    "ui_scale": 100,
    "reduce_motion": false
  },
  "audio": {
    "master_volume": 80,
    "bgm_volume": 80,
    "sfx_volume": 80,
    "ui_volume": 80,
    "ambient_volume": 60
  },
  "controls": {
    "key_bindings": { ... },
    "gamepad_bindings": { ... },
    "mouse_sensitivity": "中"
  },
  "accessibility": {
    "colorblind_mode": "关闭",
    "text_scale": 100,
    "subtitles_enabled": true,
    "reduce_motion": false
  },
  "ui_state": {
    "last_opened_tab": "画面"
  }
}
```

### Edge Cases

#### 1. 配置文件损坏或不存在

**触发条件**: 配置文件JSON解析失败，或文件不存在
**处理流程**:
1. 系统检测到配置文件损坏：记录警告日志
2. 使用出厂默认值初始化内存缓存
3. 设置界面显示错误状态："修炼环境配置损坏，请恢复默认设置"
4. 提供"恢复默认"按钮，点击后重新写入默认配置文件
**数据丢失处理**: 不尝试修复损坏文件，直接使用默认值覆盖

#### 2. 分辨率切换黑屏

**触发条件**: 玩家选择当前显示器不支持的分辨率
**处理流程**:
1. 立即应用新分辨率
2. 弹出5秒倒计时确认对话框
3. 如果玩家在5秒内点击"确认保留"：保存新分辨率
4. 如果超时未操作：自动恢复原分辨率
5. 如果恢复也失败：强制使用"1280x720"安全分辨率

#### 3. 按键冲突

**触发条件**: 玩家将按键A从功能X重新绑定到功能Y，但按键A已被功能Z使用
**处理流程**:
1. 检测到冲突，弹出冲突警告对话框
2. 显示："该按键已被「功能Z」使用，是否覆盖？"
3. 玩家选择"覆盖"：解除功能Z的绑定，绑定按键A到功能Y
4. 玩家选择"取消"：取消本次重映射操作

#### 4. 设置持久化失败

**触发条件**: 写入配置文件时发生I/O错误（磁盘满、权限不足等）
**处理流程**:
1. 捕获I/O异常，记录错误日志
2. 触发 `settings_apply_failed` 事件
3. 显示错误提示："设置无法保存，请检查存储空间"
4. 内存缓存保持不变（设置仍然生效，但下次启动会丢失）

#### 5. UI缩放到175%时布局溢出

**触发条件**: 玩家设置UI缩放到175%，某些设置项超出屏幕
**处理流程**:
1. 使用Godot ScrollContainer自动处理溢出
2. 确保内容区域可滚动查看所有设置项
3. 焦点导航仍然可达所有控件

### Dependencies

| 依赖系统 | 依赖类型 | 说明 |
|----------|----------|------|
| Godot Engine - DisplayServer | 技术依赖 | 分辨率、全屏模式切换API |
| Godot Engine - AudioServer | 技术依赖 | 音量通道控制API |
| Godot Engine - InputMap | 技术依赖 | 按键绑定API |
| Godot Engine - FileAccess | 技术依赖 | 配置文件读写API |
| Audio System | 系统依赖 | 各音量通道的音量应用 |
| Input System | 系统依赖 | 键鼠/手柄输入映射 |
| Accessibility System | 系统依赖 | 色盲模式、文本缩放应用 |
| Settings UI (UX) | 界面依赖 | 设置界面读取和修改配置 |

### Tuning Knobs

| 可调参数 | 当前值 | 可调范围 | 影响 |
|----------|--------|----------|------|
| 分辨率确认倒计时 | 5秒 | 3~10秒 | 过短玩家来不及判断，过长等待烦躁 |
| 分辨率预设列表 | 4个 | 3~6个 | 覆盖主流分辨率，不要过多 |
| UI缩放步进 | 25% | 10%~50% | 过小选项过多，过大调节不精确 |
| 音量默认值 | 80 | 50~100 | 80是舒适的初始音量 |
| 环境变量音 | 60 | 40~80 | 环境音不应盖过BGM和音效 |
| 最大节点访问数 | 100 | 50~200 | 防止对话/配置循环的保护机制 |

### Acceptance Criteria

- [ ] 游戏启动时正确加载 `user://settings.json` 配置文件
- [ ] 配置文件不存在时使用出厂默认值初始化
- [ ] 配置文件损坏时显示错误提示并提供恢复默认选项
- [ ] 音效设置滑块拖动时音量即时变化，玩家可听到变化
- [ ] 画面设置修改后"应用"按钮高亮，点击后配置持久化
- [ ] 分辨率切换后显示5秒倒计时，超时自动恢复
- [ ] 全屏模式切换后显示5秒倒计时，超时自动恢复
- [ ] 按键重映射正确保存到配置文件，下次启动生效
- [ ] 按键冲突时弹出冲突警告对话框
- [ ] 点击"恢复默认"后所有设置重置为默认值并持久化
- [ ] 色盲模式切换后屏幕色彩立即变化
- [ ] UI/文本缩放调整到175%时所有文字不截断、不重叠
- [ ] 减少运动启用时所有动画和过渡效果禁用
- [ ] 设置界面关闭时正确持久化所有未保存的变更
- [ ] `reduce_motion` 在画面页和无障碍页联动，修改一处同步更新
