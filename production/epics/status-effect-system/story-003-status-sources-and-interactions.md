# Story 003: 状态来源与系统交互

> **Epic**: 状态效果系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Integration
> **Estimate**: 3-4 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/gdd/status-effect-system.md`
**Requirement**: `TR-status-eff-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: 选择Godot 4.6作为游戏引擎,采用场景树架构和节点系统,使用GDScript作为主要脚本语言,实现数据持久化和状态管理。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Godot 4.6的所有API均在LLM训练数据范围内,无需额外验证。使用信号系统实现跨系统通信,使用OS.get_static_memory_usage()检测内存使用。

**Control Manifest Rules (Feature Layer)**:
- Required: 使用Resource类定义状态效果数据,使用Node类管理状态效果实例,通过信号系统通知状态变化
- Forbidden: 禁止在Feature Layer直接访问底层引擎API,禁止硬编码状态效果数值
- Guardrail: 单个角色最多同时存在8个状态效果,状态效果计算每帧不超过1ms

---

## Acceptance Criteria

*From GDD `design/gdd/status-effect-system.md`, scoped to this story:*

- [ ] AC3: 内存不足降级处理 - 当可用内存<2GB时,禁用粒子特效和音频反馈,使用简化状态图标,保留核心状态逻辑(DoT/HoT/Buff/Debuff计算)
- [ ] AC6: 道具使用获得状态 - 使用"金创药"道具后,角色获得Regen状态(持续3回合,regen_coefficient=0.02),道具从背包移除,状态图标栏显示Regen图标

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

1. **内存监控与降级机制**:
   - 在游戏启动时和进入战斗场景时,检测可用内存:
     ```gdscript
     var available_memory = OS.get_static_memory_usage() / 1024 / 1024 / 1024  # 转换为GB
     if available_memory < 2.0:
         enable_low_memory_mode()
     ```
   - 创建`low_memory_mode`标志,控制特效和音频的启用/禁用

2. **降级配置**:
   - 低内存模式下:
     - 禁用粒子特效系统(设置`ParticleSystem.emitting = false`)
     - 禁用音频反馈(设置`AudioStreamPlayer.volume_db = -80`)
     - 使用简化状态图标(纯色矩形,无动画)
     - 保留核心状态逻辑(DoT/HoT/Buff/Debuff计算不受影响)
   - 正常模式下:
     - 启用所有视觉和音频反馈

3. **道具系统集成**:
   - 监听道具系统的`item_used(item_id, user)`信号
   - 在信号处理函数中,检查道具类型:
     ```gdscript
     func _on_item_used(item_id: String, user: Node):
         if item_id == "golden_wound_medicine":
             apply_regen_from_item(user)
     ```
   - 创建Regen状态效果并施加到使用者

4. **道具使用流程**:
   - 检查背包中是否有"金创药"
   - 使用道具后,从背包移除1个"金创药"
   - 创建Regen状态(持续3回合,regen_coefficient=0.02)
   - 施加状态到角色
   - 发射`status_applied`信号,通知UI更新

5. **跨系统通信**:
   - 使用信号系统与道具系统、UI系统通信
   - 定义清晰的接口和数据格式
   - 确保状态效果系统不直接依赖其他系统的内部实现

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- [Story 001]: 状态效果类型实现(Burn, Poison, Regen等)
- [Story 002]: 互斥状态处理、持续时间溢出保护
- [Story 004]: 状态UI显示、粒子特效、音频反馈的具体实现

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

### AC3: 内存不足降级处理
- **Test**: 内存不足时使用降级配置,保留核心功能
  - Given: 系统可用内存1.5GB (<2GB阈值)
  - When: 进入战斗场景,施加Burn状态
  - Then:
    - 状态逻辑正常执行(每回合造成伤害)
    - 粒子特效被禁用(无火焰粒子)
    - 音频反馈被禁用(无燃烧音效)
    - 状态图标栏显示简化图标(纯色,无动画)
    - 伤害计算结果与正常模式一致
  - Edge cases:
    - 内存2.1GB时,使用完整配置(有特效和音频)
    - 内存1.9GB时,使用降级配置
    - 降级模式下,所有状态类型(DoT/HoT/Buff/Debuff/CC)都能正常工作
    - 从降级模式切换回正常模式时,状态数据不丢失

### AC6: 道具使用获得状态
- **Test**: 使用金创药道具获得Regen状态
  - Given: 角色背包有1个"金创药",当前生命值500/1000,无Regen状态
  - When: 使用"金创药"道具
  - Then:
    - 角色获得Regen状态(持续3回合,regen_coefficient=0.02)
    - 道具从背包移除,数量变为0
    - 状态图标栏显示Regen图标,剩余回合数3
    - 下一回合开始时,恢复20点生命值(1000 × 0.02)
  - Edge cases:
    - 已有Regen状态时使用金创药,刷新持续时间为3回合
    - 背包无金创药时,使用按钮禁用
    - 生命值满时使用金创药,仍获得Regen状态(为后续受伤准备)
    - 战斗外使用金创药,Regen状态正常施加

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/status_effect/status_sources_test.gd`

Before `/story-done`:
- Automated test file must exist at the path above
- All test cases from QA Test Cases section must have corresponding test methods
- All tests must pass (green)
- Test coverage must include all edge cases listed above
- Integration tests must verify cross-system communication (status effect ↔ item system)

---

## Notes

- 内存检测应该在游戏启动时执行一次,并在进入战斗场景时再次检测
- 降级模式的切换应该是平滑的,不应该导致游戏卡顿或崩溃
- 道具系统的接口应该通过信号系统解耦,避免硬依赖
- 考虑添加配置选项,允许玩家手动启用/禁用低内存模式
- 记录详细的日志,包括内存使用情况和降级模式的启用/禁用

---

## Completion Notes

**Completed**: 2026-04-28  
**Criteria**: 2/2 passing  
**Deviations**: 无  
**Test Evidence**: Integration: tests/integration/status_effect/status_sources_test.gd (20个测试函数,100%覆盖)  
**Code Review**: Complete (APPROVED)  
**QA Coverage**: ADEQUATE

**Implementation Highlights**:
- GameConfigManager单例管理内存监控和降级模式
- ItemSystemBridge桥接器实现跨系统解耦通信
- 手动覆盖功能便于测试和玩家配置
- 集成测试验证跨系统交互和信号通信
- 低内存模式不影响核心状态逻辑