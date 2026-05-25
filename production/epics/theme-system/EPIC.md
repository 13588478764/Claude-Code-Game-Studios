# Epic: 主题系统 (Theme System)

> **Layer**: Polish (UI Foundation)
> **GDD**: design/ux/theme-system.md (待补)
> **Architecture Module**: UI / Theme
> **Status**: IN PROGRESS (Theme 资源已就位, 全 UI 普及率统计中)
> **Created**: 2026-05-19 (Sprint 7 Polish 阶段)
> **Stories**:
> - story-001-main-theme-resource.md (DONE — main_theme.tres 已建)
> - story-002-theme-generator-tool.md (DONE — 程序化生成器)
> - story-003-ui-theme-adoption.md (IN PROGRESS — 全 UI 替换硬编码样式)

## Overview

统一 Godot 4.6 主题系统, 通过 main_theme.tres + 程序化生成器, 把全部 Control 节点的视觉表达统一到一个数据源, 消除"每个面板用一套样式"的散乱现状。这是 Polish 阶段美术统一性的基础。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| (无) | 后续可补 ADR-009 (Theme 系统规范) | LOW |

## 设计目标

| 目标 | 现状 | Beta 目标 |
|------|------|-----------|
| 全 UI 应用 main_theme.tres | 部分场景应用 (待统计) | ≥90% Control 节点 |
| 程序化生成主题变体 | 生成器就位 | 支持 5 套色彩主题 (普通/精英/Boss 等) |
| Theme 资源版本化 | 无版本管理 | _masters/themes/ 归档历史版本 |

## 文件结构

```
assets/ui/themes/
├── main_theme.tres          # 主主题 (基础所有 UI)
└── _masters/                # 母版归档 (待建)

tools/theme_generator/        # 程序化生成器 (位置待确认)
└── main.py / main.gd
```

## Stories

| ID | Title | Status | Type | Layer |
|----|-------|--------|------|-------|
| s001 | main_theme.tres 基础资源 | DONE | Asset | Polish |
| s002 | Theme 程序化生成器 | DONE | Tool | Polish |
| s003 | 全 UI 替换硬编码样式 | IN PROGRESS | Refactor | Polish |
| s004 | (PLANNED) 5 套色彩主题变体 | PENDING | Asset | Polish |
| s005 | (PLANNED) Theme 资源版本化 | PENDING | Infra | Polish |

## Definition of Done

This epic is complete when:
- 所有 src/scenes/ 下的 .tscn UI 场景 ≥90% 引用 main_theme.tres
- 0 处硬编码 `StyleBoxFlat.new()` 或 `add_theme_color_override()` (除非有特殊视觉需求并文档说明)
- 程序化生成器可输出 ≥3 套主题变体
- design/ux/theme-system.md 落档规范
- (可选) ADR-009 落档

## Maintenance

- **新 UI 场景**: 必须从 main_theme.tres 继承, 不允许独立样式
- **样式变更**: 改 theme, 不改场景
- **设计 review**: art-director 季度审查 theme 一致性
