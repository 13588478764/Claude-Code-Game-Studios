# Draft: Polish Phase Execution Plan

## Routing
- intent: UNCLEAR
- review_required: true (auto for UNCLEAR path)
- classified_as: Standard (multi-sprint, multi-system, 8-12 files)

## Gate State
- status: awaiting-approval
- pending_action: write .omo/plans/polish-execution.md
- approach: 基于现有 polish-fixlist + Sprint 7/8 产出 + Beta 门检, 制定 Sprint 8-10 的完整执行计划

## Open Assumptions (Adopted Defaults)
1. **优先级**: 性能 > UI 视觉 > 音频 > Playtest > 卫生 (采用业界标准: 性能数据决定后续优化投入)
2. **Sprint 8 重点**: 性能基线 + UI 布局统一 (当前 PENDING 项)
3. **Sprint 9 重点**: UI 资源接入 (品阶边框/系统图标) + 音频初步接入 + 第二轮 Playtest
4. **Sprint 10 重点**: 死信号清理 + 平衡微调 + 第三轮 Playtest + Beta 门检准备
5. **不新增功能**: 所有工作限定在现有实现范围内, 不添加 Beta 门检未要求的新系统

## Components Ledger
1. 性能基线建立 (s8-01)
2. UI 布局统一 (s8-02)
3. UI 资源接入 (品阶边框+系统图标+主题纹理)
4. 音频系统接入
5. Beta Playtest (3场)
6. 工程卫生 (死信号清理+测试路径修复+HUD场景补建)

## Findings
- 项目已完成 6 个开发 Sprint (Alpha), 现处 Polish 阶段
- Sprint 7: 13 Must-Have DONE, AI 美术管线+GDD 对齐
- Sprint 8: 5/11 DONE, 6 PENDING (性能/UI布局/Playtest/音频/头像/动画)
- polish-fixlist: 27 项, 23+ 已关闭
- 剩余 P0: 0 项 (全清)
- 剩余 P1: 30 个死信号标注 (#21)
- 剩余 P2: 3 个 HUD 场景缺失 (#smoke)
- 测试: 467/469 (99.6%), 2 pending = headless FPS 跳过
- 美术: 472 张全部入库
- 内容: 28 主线事件 + 30 奇遇 + 6 NPC 对话
- 风险: R-005 (性能基线 OPEN), R-006 (Playtest OPEN)
