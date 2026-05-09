# Story 003: 队友状态显示

> **Epic**: HUD系统
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/ux/hud.md`
**Requirement**: `TR-HUD-003` (队友状态显示 - P0级信息)

**ADR Governing Implementation**: ADR-002: HUD架构模式, ADR-003: 数据绑定机制
**ADR Decision Summary**: 监听GameEvents的party_member_hp_changed, party_member_added, party_member_removed, party_member_downed信号。

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (Presentation Layer)**:
- Required: 使用@onready缓存节点引用
- Forbidden: 禁止在_process()中使用$NodePath查找
- Guardrail: 确保UI更新响应时间<16.67ms

---

## Acceptance Criteria

- [ ] AC-1: 队友头像正确显示(60x60px)
- [ ] AC-2: 队友HP条正确显示当前值/最大值(240x16px)
- [ ] AC-3: 倒地状态有明显视觉标识
- [ ] AC-4: 支持最多3名队友同时显示
- [ ] AC-5: 队友加入/离开时UI正确更新
- [ ] AC-6: 队友数量为0时PartyPanel不显示或显示空状态提示
- [ ] AC-7: 队友数量超过3时只显示前3名,其余队友不显示
- [ ] AC-8: 队友顺序变化时UI在0.3秒内平滑重排
- [ ] AC-9: 队友加入时有淡入动画(0.2秒),离开时有淡出动画(0.2秒)
- [ ] AC-10: 队友HP变化时条形图有0.1秒的平滑过渡动画
- [ ] AC-11: 所有队友头像资源存在于res://assets/ui/party_portraits/目录

---

## QA Test Cases

### MV-003-01: 队友头像显示验证
- **Setup**: 队伍有2名队友
- **Steps**: 1. 观察PartyPanel显示2个队友槽位 2. 检查每个头像为60x60px 3. 验证头像图片清晰无失真
- **Pass Condition**: 队友头像正确显示

### MV-003-02: 队友HP条显示验证
- **Setup**: 队友1 HP为300/500
- **Steps**: 1. 观察队友1的HP条填充度约为60% 2. 检查HP条尺寸为240x16px
- **Pass Condition**: 队友HP条正确显示

### MV-003-03: 倒地状态标识验证
- **Setup**: 队友2处于倒地状态
- **Steps**: 1. 观察队友2的槽位 2. 确认有明显的倒地标识(如灰色滤镜、骷髅图标等) 3. 确认HP条显示为0或隐藏
- **Pass Condition**: 倒地状态有明显视觉标识

### MV-003-04: 队友加入更新验证
- **Setup**: 队伍有1名队友
- **Steps**: 1. 触发队友加入事件 2. 观察PartyPanel新增一个槽位 3. 确认新队友信息正确显示
- **Pass Condition**: 队友加入时UI正确更新

### MV-003-05: 队友离开更新验证
- **Setup**: 队伍有2名队友
- **Steps**: 1. 触发队友离开事件 2. 观察PartyPanel移除对应槽位 3. 确认剩余队友信息正确显示
- **Pass Condition**: 队友离开时UI正确更新

### MV-003-06: 队友数量为0验证
- **Setup**: 队伍只有主角,无队友
- **Steps**: 1. 观察PartyPanel状态 2. 确认不显示任何队友槽位或显示"无队友"提示
- **Pass Condition**: 0个队友时UI正确处理

### MV-003-07: 队友数量超过3验证
- **Setup**: 队伍有4名队友
- **Steps**: 1. 观察PartyPanel只显示3个槽位 2. 确认显示的是前3名队友 3. 确认第4名队友不显示
- **Pass Condition**: 超过3名队友时只显示前3名

### MV-003-08: 队友加入动画验证
- **Setup**: 队伍有1名队友
- **Steps**: 1. 触发队友加入事件 2. 观察新槽位的淡入动画 3. 使用秒表确认动画时长约0.2秒
- **Pass Condition**: 队友加入有0.2秒淡入动画

---

## Test Evidence

**Story Type**: UI
**Required evidence**: `production/qa/evidence/party-status-display-evidence.md` + 截图/录屏

**Status**: [ ] Not yet created

---

## Out of Scope

本Story不包含以下内容:

- **队友详细属性面板** — 仅显示HP条和头像,不显示Qi/Poise等详细属性
- **队友切换功能** — 不实现队友上场/下场的切换机制
- **队友技能显示** — 不显示队友的技能冷却或可用技能
- **队友Buff/Debuff** — 不显示队友身上的状态效果(由Story 006处理)
- **队友头像资源创建** — 仅创建占位符目录,实际头像由美术团队提供
- **队友排序/重新排列** — 队友顺序固定,不支持拖拽重排

---

## Design Decisions

### 资源缺失处理

当队友头像资源不存在时,UI将显示以下fallback机制:

1. **首先尝试加载**: `res://assets/ui/party_portraits/party_member_{member_id}.png`
2. **如果不存在**: 显示默认占位符(灰色圆形 + 队友ID文本)
3. **错误日志**: 记录缺失资源到控制台,便于美术团队跟踪

```gdscript
# PartyStatusDisplay.gd中的加载逻辑
func _load_member_portrait(member_id: String) -> Texture2D:
    var portrait_path = "res://assets/ui/party_portraits/party_member_%s.png" % member_id
    if ResourceLoader.exists(portrait_path):
        return load(portrait_path)
    else:
        push_warning("Missing party portrait: %s" % portrait_path)
        return _create_default_portrait(member_id)
```

### 倒地状态视觉标识

倒地状态通过以下方式标识:

1. **灰色滤镜**: 倒地时头像应用50%灰度滤镜
2. **HP条隐藏**: 倒地时HP条隐藏或显示为0
3. **骷髅图标**: 在头像右下角显示小骷髅图标(可选)

---

## Estimate

**Est: 4-6 hours**

- 实现PartyStatusDisplay脚本: 2小时
- 创建PartyPanel场景: 1小时
- 实现动画(淡入/淡出/HP过渡): 1.5小时
- 测试和调试: 1.5小时

---

## Dependencies

- Depends on: Story 001 (HUD场景结构和管理器 - 必须DONE)
- Unlocks: Story 004 (行动顺序队列显示)