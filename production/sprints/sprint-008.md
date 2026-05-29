# Sprint 8 -- 2026-05-30 to 2026-06-12 (Polish Week 3-4)

## Sprint Goal
性能基线建立 + UI 布局统一调整 + 第七批 AI 资源接入 + 首轮 Beta Playtest。

## Capacity
- **Total days**: 14 (2026-05-30 ~ 2026-06-12)
- **Buffer (20%)**: 3 days
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Task | Owner | Est. Days | Status | Acceptance Criteria |
|----|------|-------|-----------|--------|---------------------|
| s8-01 | 性能基线建立 | Performance Analyst | 1 | PENDING | 主菜单/探索/战斗三场景 FPS 基准落档, 确认 60FPS 达标或标记优化项 |
| s8-02 | UI 布局统一调整 | UI Programmer | 3 | PENDING | 探索/对话/战斗/角色/背包面板在 1920×1080 下布局合理, 截图验证 |
| s8-03 | 第六七批 AI 资源回流+接入 | Asset Pipeline | 1 | PENDING | W23-W27 共 40 张回流+代码接入 (按钮纹理/战斗背景/时段变体/表情/突破) |
| s8-04 | 战斗背景按区域切换 | Gameplay Programmer | 0.5 | PENDING | 4 区域各使用对应战斗背景 (village/fortress/mountain/water) |

**Must Have Total**: 5.5 days

### Should Have

| ID | Task | Owner | Est. Days | Status | Acceptance Criteria |
|----|------|-------|-----------|--------|---------------------|
| s8-05 | NPC 表情变体接入对话系统 | UI Programmer | 1 | PENDING | 对话中根据对话节点 emotion 字段切换立绘变体 |
| s8-06 | 境界突破插图接入 | UI Programmer | 0.5 | PENDING | 突破时全屏显示对应境界的突破插图 2 秒 |
| s8-07 | Beta Playtest 第一场 (新玩家) | QA Lead | 1.5 | PENDING | 全新玩家从开场到第一次境界突破的完整体验记录 |
| s8-08 | 队伍头像生成 (ImageMagick) | Asset Pipeline | 0.5 | PENDING | 12 张 60×60 头像生成到 party_portraits/ |

**Should Have Total**: 3.5 days

### Nice to Have

| ID | Task | Owner | Est. Days | Status | Acceptance Criteria |
|----|------|-------|-----------|--------|---------------------|
| s8-09 | 按钮纹理横向裁剪+接入 | UI Programmer | 1 | PENDING | crop_buttons.sh 执行, 主菜单按钮使用新纹理 |
| s8-10 | 音效系统初步接入 | Audio | 1 | PENDING | 至少 3 个音效 (按钮点击/战斗攻击/境界突破) 有声音 |
| s8-11 | 伤害数字+抖动动画验证调优 | UI Programmer | 0.5 | PENDING | 战斗中伤害数字清晰可见, 抖动感觉舒适 |

**Nice to Have Total**: 2.5 days

---

## Carryover from Sprint 7
| Task | Reason | New Estimate |
|------|--------|--------------|
| s7-14 性能基线 | 需要编辑器运行 | → s8-01 |
| s7-16 Playtest | 需要内容+UI 就位 | → s8-07 |

## Risks
| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| AI 纹理不适合 NinePatch (已验证) | HIGH | Low | 改用整体缩放或裁剪, 不做九宫格 |
| UI 布局调整涉及多个 .tscn 文件 | Medium | Medium | 逐个面板调整, 每改一个截图验证 |
| 性能测试发现严重瓶颈 | Low | High | 优先优化最慢场景, 推迟其他任务 |

## Dependencies on External Factors
- ComfyUI 第六七批出图完成 (今晚挂机)
- ImageMagick 安装 (brew install imagemagick)

## Definition of Done for this Sprint
- [ ] All Must Have tasks completed
- [ ] 性能基线文档存在 (production/qa/perf-baseline.md)
- [ ] 至少 1 个面板 UI 布局截图验证通过
- [ ] 第六七批资源回流完成
