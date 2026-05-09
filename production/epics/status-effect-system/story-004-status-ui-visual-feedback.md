# Story 004: 状态UI与视觉反馈

> **Epic**: 状态效果系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Visual/Feel
> **Estimate**: 4-6 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/status-effect-system.md`
**Requirement**: `TR-status-eff-004`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 选择Godot 4.6作为游戏引擎,采用场景树架构和节点系统,使用GDScript作为主要脚本语言,实现数据持久化和状态管理。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot 4.6的所有API均在LLM训练数据范围内,无需额外验证。使用Control节点实现UI,使用GPUParticles2D实现粒子特效,使用AudioStreamPlayer实现音频反馈。

**Control Manifest Rules (Feature Layer)**:
- Required: 使用Resource类定义状态效果数据,使用Node类管理状态效果实例,通过信号系统通知状态变化
- Forbidden: 禁止在Feature Layer直接访问底层引擎API,禁止硬编码状态效果数值
- Guardrail: 单个角色最多同时存在8个状态效果,状态效果计算每帧不超过1ms

---

## Acceptance Criteria

*From GDD `design/gdd/status-effect-system.md`, scoped to this story:*

- [ ] AC4: UI适配不同分辨率 - 在1920x1080、2560x1440、3440x1440分辨率下,状态图标栏、悬停提示、粒子特效正确缩放和定位,文字清晰可读(最小字号12px)

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

1. **状态图标栏UI**:
   - 创建`StatusIconBar` Control节点,使用HBoxContainer水平排列图标
   - 每个状态图标包含:
     - TextureRect显示状态图标(32x32 @ 1080p, 48x48 @ 1440p)
     - Label显示剩余回合数(右上角)
     - Label显示层数(右下角,如果支持堆叠)
   - 最多显示8个图标,超出部分使用ScrollContainer

2. **分辨率适配**:
   - 使用Godot的viewport缩放功能:
     ```gdscript
     func _ready():
         get_viewport().size_changed.connect(_on_viewport_size_changed)
         _update_ui_scale()
     
     func _update_ui_scale():
         var viewport_size = get_viewport().size
         var scale_factor = viewport_size.x / 1920.0  # 基准分辨率1920x1080
         scale = Vector2(scale_factor, scale_factor)
     ```
   - 确保文字最小字号为12px,在所有分辨率下清晰可读

3. **悬停提示**:
   - 创建`StatusTooltip` Control节点,使用PanelContainer + VBoxContainer布局
   - 显示内容:
     - 状态名称(粗体,大字号)
     - 状态类型(Buff/Debuff/CC)
     - 剩余回合数
     - 层数(如果支持堆叠)
     - 具体效果描述(如"每回合造成30点火属性伤害")
   - 鼠标悬停时显示,移开时隐藏

4. **粒子特效**:
   - 为每种状态类型创建对应的粒子特效:
     - Burn: 火焰粒子(红色/橙色,向上飘动)
     - Poison: 毒气粒子(绿色,环绕角色)
     - Freeze: 冰晶粒子(蓝色,闪烁)
     - Regen: 治愈粒子(绿色光芒,向上飘动)
   - 使用GPUParticles2D节点,挂载到角色节点上
   - 根据low_memory_mode标志启用/禁用粒子

5. **音频反馈**:
   - 为每种状态类型配置对应的音效:
     - Burn: 火焰燃烧声(循环播放)
     - Poison: 嘶嘶声(循环播放)
     - Freeze: 冰晶凝结声(单次播放)
     - Regen: 治愈声(循环播放)
   - 使用AudioStreamPlayer节点,根据low_memory_mode标志启用/禁用

6. **UI动效**:
   - 状态施加:图标旋转入场(Tween动画,0.3秒)
   - 状态刷新:图标闪烁(Tween动画,0.2秒)
   - 状态驱散:图标淡出消失(Tween动画,0.3秒)

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 状态效果类型实现(Burn, Poison, Regen等)
- [Story 002]: 互斥状态处理、持续时间溢出保护
- [Story 003]: 道具使用获得状态、内存不足降级处理的逻辑实现

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

### AC4: UI适配不同分辨率
- **Manual check**: UI元素正确适配屏幕尺寸,保持清晰可读
  - Setup: 
    1. 启动游戏,进入战斗场景
    2. 施加多个状态效果(Burn, Poison, Regen, Shield)
    3. 依次切换分辨率:1920x1080 → 2560x1440 → 3440x1440
  - Verify:
    - 状态图标栏位置正确(角色头像下方或血条旁)
    - 图标大小适配分辨率(1080p:32x32, 1440p:48x48, 21:9:48x48)
    - 悬停提示框文字清晰,最小字号12px
    - 粒子特效不超出屏幕边界
    - 状态图标栏最多显示8个图标,超出部分可滚动
    - 剩余回合数和层数数字清晰可读
  - Pass condition:
    - 所有分辨率下,UI元素无重叠、无裁剪、无模糊
    - 文字可读性测试:在3米外能识别状态名称
    - 切换分辨率时,UI即时重新布局,无延迟或闪烁
    - 21:9超宽屏下,状态图标栏不拉伸变形

---

## Test Evidence

**Story Type**: Visual/Feel
**Required evidence**: `production/qa/evidence/status-ui-visual-evidence.md`

Before `/story-done`:
- Manual evidence document must exist at the path above
- Evidence must include screenshots at all three resolutions (1920x1080, 2560x1440, 3440x1440)
- Evidence must show:
  - Status icon bar with multiple status effects
  - Hover tooltip displaying detailed information
  - Particle effects for different status types
  - UI scaling at different resolutions
- Evidence must include sign-off from QA or visual designer

---

## Notes

- 状态图标应该使用水墨风格,符合艺术圣经的视觉风格
- 颜色编码:蓝色/绿色=增益,红色/紫色=减益,黄色=控制
- 粒子特效应该轻量级,避免影响性能
- 音频反馈应该可以在设置中单独调节音量
- 考虑添加色盲模式,使用图案而非仅依赖颜色区分状态类型
- UI布局应该支持自定义,允许玩家调整状态图标栏的位置和大小