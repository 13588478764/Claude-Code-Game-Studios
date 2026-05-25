# Epic: AI 美术批量出图管线

> **Layer**: Polish (Production Pipeline)
> **GDD**: 无 (生产工具, 不属于游戏内容)
> **Architecture Module**: Tools / Asset Pipeline
> **Status**: IN PROGRESS (第一批 41 张 DONE; 第二批 54 张挂机中)
> **Created**: 2026-05-17 (Sprint 7 Polish 阶段)
> **Stories**:
> - story-001-comfyui-flux-bootstrap.md (DONE — 五行图标首批 5 张)
> - story-002-first-batch-41-icons.md (DONE — 战斗状态 5 + buff 16 + debuff 10 + 境界 10)
> - story-003-batch-pipeline-python-generator.md (DONE — 8 工作流 + Python 生成器 + 回流脚本)
> - story-004-second-batch-54-icons.md (IN PROGRESS — 天赋 16 + 武学 16 + 系统综合 22)

## Overview

使用 ComfyUI + FLUX 模型在本地批量生成 UI 图标 + 1024 母版, 解决传统美术外包流程的成本与周期问题。管线覆盖: 工作流模板生成 → 挂机渲染 → 自动回流到游戏目录 → 手动验收。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| (无) | Polish 阶段工具决策, 后续可补 ADR-008 (AI 资产管线) | LOW |

## 技术栈

| 组件 | 版本/配置 | 用途 |
|------|----------|------|
| ComfyUI | 本地部署 | 节点式 AI 生成引擎 |
| FLUX | flux1-dev-fp8.safetensors | 主模型 (FP8 量化, 适合本地) |
| Python 3.x | tools/comfyui/generate_batch_workflow.py | 工作流批量生成 |
| Bash | tools/comfyui/import_ai_assets.sh | 回流到游戏目录 |

## 工作流安全线

| 指标 | 上限 | 验证 |
|------|------|------|
| 节点数/工作流 | ≤150 | 第二批 119/119/98/77 均稳定 |
| 共享输出目录 | 同目录 + filename_prefix 区分 | 11a + 11b 共享 wuxia_system_1024/96 |
| 单批次图标数 | ≤30 张 | 防止挂机失败成本过高 |

## 5 套提示词模板 (Polish 期视觉差异化)

| 模板 | 边框风格 | 用途 |
|------|----------|------|
| TALENT | 紫色辉光圆角 | 天赋图标 |
| MARTIAL | 金边方框 | 武学图标 |
| SYSTEM_FLAT | 蓝灰扁平 | 系统综合图标 |
| QUEST_DIAMOND | 菱形外框 | 任务相关 |
| MAP_CIRCLE | 圆形外框 | 地图/位置相关 |

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| s001 | ComfyUI + FLUX bootstrap + 五行首批 | DONE | Infra | Polish |
| s002 | 第一批 41 张 (战斗状态/buff/debuff/境界) | DONE | Asset | Polish |
| s003 | Python 工作流生成器 + 8 工作流 + 回流脚本 | DONE | Tool | Polish |
| s004 | 第二批 54 张 (天赋/武学/系统综合) | IN PROGRESS | Asset | Polish |
| s005 | (PLANNED) 武器图标 Palm/Blade/Bow 补齐 | PENDING | Asset | Polish |
| s006 | (PLANNED) 角色立绘 + CG 首批 | PENDING | Asset | Polish |

## Definition of Done

This epic is complete when:
- 所有计划批次图标 100% 入库到 `assets/ui/{status,buff,debuff,realm,talent,martial,system,...}_icons/`
- 所有 1024 母版归档到 `assets/ui/_masters/`
- import_ai_assets.sh 支持所有类别的回流
- production/qa/ai-batch-{N}-expected.md 复选框 100% 勾选
- tools/comfyui/workflows/ 8+ 工作流可重复挂机
- (可选) ADR-008 落档定义管线规范

## Maintenance

- **挂机前**: 跑 dry-run import + JSON preflight
- **挂机后**: 跑 import_ai_assets.sh + 手动验收 expected 清单
- **失败补救**: 检查 ComfyUI log + 单图重跑

记忆同步: `feedback_ai_asset_batch_pipeline.md` (用户级记忆)
