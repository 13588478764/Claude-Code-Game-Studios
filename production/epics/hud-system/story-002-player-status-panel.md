# Story 002: 角色状态显示面板

> **Epic**: HUD系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: 4-6 hours
> **Manifest Version**: 2026-04-28

## Context

**GDD**: `design/ux/hud.md`
**Requirement**: `TR-HUD-002` (主角状态显示 - P0级信息)
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**ADR Governing Implementation**: ADR-002: HUD架构模式, ADR-003: 数据绑定机制
**ADR Decision Summary**: 使用信号驱动更新,实现脏标记优化避免重复更新。监听GameEvents的player_hp_changed, player_qi_changed, player_poise_changed等信号。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用标准Control节点和ProgressBar,无post-cutoff API依赖。

**Control Manifest Rules (Presentation Layer)**:
- Required: 使用@onready缓存节点引用,使用信号系统进行松耦合
- Forbidden: 禁止在_process()中使用$NodePath查找
- Guardrail: 确保UI更新响应时间<16.67ms(60FPS)

---

## Acceptance Criteria

*From GDD `design/ux/hud.md`, scoped to this story:*

- [ ] AC-1: HP条正确显示当前值/最大值
- [ ] AC-2: HP<30%时条形图变红色(#DC143C)
- [ ] AC-3: Qi条正确显示当前值/最大值
- [ ] AC-4: Poise条正确显示当前值/最大值
- [ ] AC-5: Poise<20%时条形图闪烁(2Hz频率)
- [ ] AC-6: 等级显示正确(Lv.XX格式)
- [ ] AC-7: 经验条显示当前/下一级所需经验
- [ ] AC-8: 境界图标和名称正确显示
- [ ] AC-9: HP=0时条形图完全空白,数值显示"0/最大值"
- [ ] AC-10: HP=最大值时条形图完全填充,颜色为正常绿色(#2E8B57)
- [ ] AC-11: HP数值变化时UI在下一帧内更新(响应时间<16.67ms)
- [ ] AC-12: Poise<20%时闪烁频率为2Hz(每秒2次),持续到Poise恢复
- [ ] AC-13: 数值显示格式为"当前值/最大值",超过9999时使用K单位(如"12.5K/15K")
- [ ] AC-14: 所有境界图标资源存在于res://assets/ui/realm_icons/目录

---

## Implementation Notes

*Derived from ADR-002 and ADR-003 Implementation Guidelines:*

1. **场景结构**:
   - 创建`src/scenes/ui/hud/player_status_panel.tscn`
   - 根节点为PanelContainer
   - 包含VBoxContainer组织HP/Qi/Poise条
   - 每个条包含ProgressBar + Label(数值显示)
   - 底部包含等级、经验、境界显示

2. **脚本实现**:
   - 创建`src/scripts/ui/hud/player_status_panel.gd`
   - 使用@onready缓存所有节点引用
   - 实现脏标记:_cached_hp, _cached_qi, _cached_poise
   - 连接GameEvents信号:player_hp_changed, player_qi_changed, player_poise_changed

3. **脏标记优化**:
   - 在信号处理函数中比较新值与缓存值
   - 仅当值变化时标记为dirty
   - 在_process()中检查dirty标记并应用更新

4. **临界状态处理**:
   - HP<30%: 条形图modulate = Color.RED (#DC143C)
   - HP 30-60%: 条形图modulate = Color.YELLOW
   - HP>60%: 条形图modulate = Color.GREEN (#2E8B57)
   - Poise<20%: 使用Tween实现2Hz闪烁(0.5秒周期)

5. **数值格式化**:
   - 实现_format_number()函数
   - 小于10000: 直接显示"1234/5000"
   - 大于等于10000: 转换为K单位"12.5K/15K"

6. **境界显示**:
   - 从res://assets/ui/realm_icons/加载境界图标
   - 使用TextureRect显示图标
   - 使用Label显示境界名称

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: 队友状态显示
- Story 009: 性能优化(批量更新、LOD)

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

### MV-002-01: HP条显示验证
- **Setup**: 角色HP为500/1000
- **Steps**:
  1. 启动游戏并进入HUD显示状态
  2. 观察PlayerStatusPanel左下角
  3. 检查HP条填充度约为50%
  4. 检查HP数值显示为"500/1000"
  5. 检查条形图颜色为正常绿色
- **Pass Condition**: HP条正确显示,颜色正常

### MV-002-02: HP临界状态警告验证
- **Setup**: 角色HP为250/1000 (25%)
- **Steps**:
  1. 观察HP条颜色
  2. 确认条形图变为红色(#DC143C)
  3. 使用颜色拾取工具验证颜色值
- **Pass Condition**: HP<30%时条形图为深红色

### MV-002-03: Poise闪烁效果验证
- **Setup**: 角色Poise为15/100 (15%)
- **Steps**:
  1. 观察Poise条
  2. 使用秒表计时,记录闪烁频率
  3. 确认每秒闪烁2次(0.5秒一个周期)
  4. 确认闪烁在Poise恢复到20%以上时停止
- **Pass Condition**: Poise<20%时以2Hz频率闪烁

### MV-002-04: 等级和经验显示验证
- **Setup**: 角色等级10,经验1500/2000
- **Steps**:
  1. 检查等级显示格式为"Lv.10"
  2. 检查经验条填充度约为75%
  3. 检查经验数值显示为"1500/2000"
- **Pass Condition**: 等级和经验正确显示

### MV-002-05: 境界显示验证
- **Setup**: 角色境界为"筑基期"
- **Steps**:
  1. 检查境界图标是否显示
  2. 检查境界名称文本为"筑基期"
  3. 验证图标资源路径正确
- **Pass Condition**: 境界图标和名称正确显示

### MV-002-06: 边界值测试 - HP为0
- **Setup**: 角色HP为0/1000
- **Steps**:
  1. 观察HP条完全空白
  2. 检查数值显示为"0/1000"
  3. 确认条形图为红色
- **Pass Condition**: HP=0时UI正确显示

### MV-002-07: 边界值测试 - HP满值
- **Setup**: 角色HP为1000/1000
- **Steps**:
  1. 观察HP条完全填充
  2. 检查数值显示为"1000/1000"
  3. 确认条形图为正常绿色
- **Pass Condition**: HP满值时UI正确显示

### MV-002-08: 数值更新响应性
- **Setup**: 角色HP为500/1000
- **Steps**:
  1. 触发HP变化事件(受到伤害-100)
  2. 使用帧率监控工具记录UI更新时间
  3. 确认HP条和数值在下一帧内更新
- **Pass Condition**: UI更新延迟<16.67ms (60FPS)

### MV-002-09: 大数值格式化验证
- **Setup**: 角色HP为12500/15000
- **Steps**:
  1. 检查数值显示为"12.5K/15K"
  2. 确认格式化正确,保留一位小数
- **Pass Condition**: 大数值使用K单位显示

### MV-002-10: Qi条显示验证
- **Setup**: 角色Qi为300/500
- **Steps**:
  1. 观察Qi条填充度约为60%
  2. 检查Qi数值显示为"300/500"
  3. 检查条形图尺寸为280x20px
- **Pass Condition**: Qi条正确显示

### MV-002-11: Poise条显示验证
- **Setup**: 角色Poise为80/100
- **Steps**:
  1. 观察Poise条填充度约为80%
  2. 检查Poise数值显示为"80/100"
  3. 检查条形图尺寸为280x20px
- **Pass Condition**: Poise条正确显示

### MV-002-12: 境界图标资源验证
- **Setup**: 游戏启动
- **Steps**:
  1. 检查res://assets/ui/realm_icons/目录存在
  2. 确认所有境界图标文件存在
  3. 尝试加载每个图标,确认无错误
- **Pass Condition**: 所有境界图标资源存在且可加载

### MV-002-13: HP颜色过渡验证
- **Setup**: 角色HP从100%逐渐降低
- **Steps**:
  1. HP>60%时确认为绿色
  2. HP降到50%时确认为黄色
  3. HP降到25%时确认为红色
- **Pass Condition**: HP颜色根据百分比正确过渡

### MV-002-14: Poise闪烁停止验证
- **Setup**: 角色Poise为15/100,正在闪烁
- **Steps**:
  1. 触发Poise恢复到25/100
  2. 确认闪烁立即停止
  3. 确认Poise条恢复正常显示
- **Pass Condition**: Poise恢复到20%以上时闪烁停止

---

## Test Evidence

**Story Type**: UI
**Required evidence**:
- UI: `production/qa/evidence/player-status-panel-evidence.md` + 截图/录屏

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (HUD场景结构和管理器 - 必须DONE)
- Unlocks: Story 003 (队友状态显示)