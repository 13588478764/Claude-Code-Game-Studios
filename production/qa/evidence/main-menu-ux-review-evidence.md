# UX Review Evidence: 主菜单 (Main Menu)

> **File**: design/ux/main-menu.md
> **Review Date**: 2026-05-07
> **Reviewer**: UX Designer (via Claude Code)
> **Status**: REVIEW COMPLETE — Issues identified

---

## Issue Summary

| Priority | Count |
|----------|-------|
| HIGH | 2 |
| MEDIUM | 4 |
| LOW | 3 |
| **Total** | **9** |

---

## HIGH Priority Issues

### H1: "继续修炼"按钮无存档状态处理与描述不一致

**Location**: States & Variants — 无存档状态; Interaction Map

**Problem**: 文档中"无存档状态"描述为"'继续修炼'按钮置灰不可用"，但 Acceptance Criteria 第2条说"无存档时，'继续修炼'按钮置灰不可用，点击提示'无修炼记录'"。两者矛盾：
- 如果按钮置灰不可用 → 无法点击
- 如果可以点击 → 不应置灰不可用

**Impact**: 实现时可能出现两种行为，或者置灰后仍不可交互导致玩家困惑

**Fix Recommendation**:
1. 方案A：有存档时高亮可用，无存档时完全隐藏（不占位），减少无效选项
2. 方案B：有存档时高亮可用，无存档时置灰但仍可点击（提示"无修炼记录"）
3. 推荐方案B：按钮位置稳定，反馈清晰

---

### H2: 主菜单缺少Z-index和半模态定义

**Location**: Layout Specification; Navigation Position

**Problem**: 文档未定义：
- 主菜单的Z-index层级（与跨面板标准中的HUD=100、面板=200、奇遇=300、对话框=400是否一致？）
- 设置子菜单打开时，主菜单是否被遮罩覆盖、变暗百分比
- 设置面板关闭后主菜单是否恢复动画

**Impact**: 与其他面板的层级关系不明确，可能出现Z-index冲突

**Fix Recommendation**:
1. 主菜单根层级Z-index=0（作为全屏场景）
2. 主菜单UI按钮层Z-index=100（与HUD一致）
3. 设置子菜单打开时，主菜单按钮层Z-index=50（低于面板200），15%变暗遮罩
4. 明确在文档中添加Z-index规范

---

## MEDIUM Priority Issues

### M1: 设置子菜单打开方式与settings.md不一致

**Location**: States & Variants — 设置子菜单; Transitions & Animations

**Problem**: main-menu.md描述设置子菜单"从右侧滑入，主菜单变暗遮罩"，但settings.md定义设置面板为"居中显示 + 缩放进入（80% → 100%）"。两种不同的入场动画。

**Impact**: 实现时可能混用两种动画，或需要判断不同入口使用不同动画

**Fix Recommendation**:
1. 统一为居中缩放进入（遵循settings.md标准）
2. 或主菜单打开设置时使用侧滑，其他入口使用居中（需明确说明）
3. 推荐统一为居中缩放

---

### M2: 缺少"游戏内返回主菜单"后的存档行为说明

**Location**: Entry & Exit Points — 游戏内返回

**Problem**: "从暂停菜单选择'返回主菜单'"后到达"主菜单默认状态，无存档提示"，但未说明：
- 返回主菜单时当前游戏是否已自动存档？
- 玩家点击"继续修炼"是加载自动存档还是原存档？
- 是否需要"保存并返回"确认对话框？

**Impact**: 玩家可能丢失未保存的游戏进度

**Fix Recommendation**:
1. 明确"返回主菜单"时自动保存当前进度
2. 或弹出确认对话框："是否保存当前进度并返回主菜单？"
3. 在文档中说明存档时机

---

### M3: 制作人员界面缺少详细规格

**Location**: States & Variants — 制作人员; Interaction Map

**Problem**: 制作人员界面只有"屏幕中央滚动字幕，可跳过（按任意键）"的描述，缺少：
- 滚动速度（像素/秒）
- 是否支持手动滚动（鼠标滚轮/方向键）
- 跳过按钮的具体样式和位置
- 背景是什么（纯黑？游戏背景？）
- 是否有BGM
- 制作人员结束后如何返回主菜单（自动返回？手动点击？）

**Impact**: 实现时可能做出不符合UX标准的设计决策

**Fix Recommendation**:
1. 补充制作人员界面详细规格（滚动速度、交互、背景、BGM、返回方式）
2. 或引用interaction-patterns.md中的通用滚动字幕规范

---

### M4: 焦点导航默认焦点不明确

**Location**: Interaction Map — 导航顺序

**Problem**: 文档标注"开始新修炼 ← 默认焦点"，但"回头玩家"的核心需求是"继续修炼"。对于有存档的玩家，默认焦点应该在"继续修炼"而非"开始新修炼"。

**Impact**: 回头玩家需要额外一次按键才能到达最常用的选项

**Fix Recommendation**:
1. 有存档时：默认焦点在"继续修炼"
2. 无存档时：默认焦点在"开始新修炼"
3. 在文档中明确说明条件默认焦点逻辑

---

## LOW Priority Issues

### L1: Zone百分比分配加总不足100%

**Location**: Layout Specification — Layout Zones

**Problem**: Zone A=30%, Zone B=40%, Zone C=10%，加总=80%。剩余20%未定义。

**Impact**: 实现时可能出现布局空白区域不确定的问题

**Fix Recommendation**:
1. 明确Zone B实际占30%（中左部），Zone之间留有间距
2. 或标注"背景填充剩余空间"

---

### L2: 缺少手柄肩键导航支持

**Location**: Accessibility — 手柄导航

**Problem**: 手柄导航只提到"方向键/摇杆"，未提及肩键（L1/R1）是否支持上下快速导航。设置面板已支持L1/R1，主菜单也应保持一致。

**Impact**: 与其他面板的手柄导航不一致

**Fix Recommendation**:
1. 补充肩键（L1/R1）支持：L1=上一项，R1=下一项
2. 或明确主菜单按钮数量少（5个），不需要肩键

---

### L3: 缺少面板宽度/高度尺寸定义

**Location**: Layout Specification

**Problem**: 文档未定义主菜单面板的宽度、高度、对齐方式。其他面板（settings.md）已定义40%屏幕宽度、80%高度、居中对齐。

**Impact**: 主菜单作为全屏场景可能不需要面板尺寸规范，但应明确说明"全屏布局"

**Fix Recommendation**:
1. 明确主菜单为全屏布局，不适用面板宽度标准
2. Zone A/B/C的布局基于全屏参考

---

## Cross-Panel Consistency Check

| 标准 | 是否符合 | 说明 |
|------|---------|------|
| Z-index层级 | ❌ 未定义 | 主菜单UI层应为100 |
| 半模态 | ❌ 未定义 | 设置子菜单打开时主菜单变暗百分比未说明 |
| 焦点样式 | ❌ 未提及 | 应引用金色边框#FFD700标准 |
| 确认对话框 | ✅ 符合 | 遵循interaction-patterns.md模板 |
| 键盘导航 | ✅ 符合 | 完整的↑↓键循环支持 |
| 手柄导航 | ⚠️ 部分符合 | 缺少肩键支持 |
| 减少运动支持 | ✅ 符合 | 完整的动画禁用逻辑 |
| 本地化 | ✅ 符合 | 40%文本扩展支持 |

---

## Open Questions (新增)

1. **"继续修炼"无存档时应隐藏还是置灰可点击？**
2. **主菜单的Z-index层级？** 根场景 vs UI按钮层
3. **设置子菜单入场动画：** 侧滑还是居中缩放？
4. **游戏内返回主菜单时是否自动存档？**
5. **制作人员界面详细规格：** 滚动速度、背景、BGM、返回方式
6. **有存档时默认焦点是否在"继续修炼"？**
7. **主菜单是否定义为全屏布局？** 不适用面板宽度标准

---

## Next Steps

1. 修复HIGH优先级问题（H1, H2）
2. 修复MEDIUM优先级问题（M1-M4）
3. 可选修复LOW优先级问题（L1-L3）
4. 补充制作人员界面详细规格
5. 标记为Ready for Implementation
