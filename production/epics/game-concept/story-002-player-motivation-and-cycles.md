# Story 002: 玩家动机与循环

> **Epic**: 游戏概念
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Design
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/game-concept.md`
**Requirement**: `TR-game-concept-002`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的文档系统记录玩家动机和循环设计

**Control Manifest Rules (this layer)**:
- Required: 玩家动机和循环设计必须符合自我决定理论
- Forbidden: 禁止设计会降低玩家动机的功能
- Guardrail: 所有循环设计必须验证玩家参与度

---

## Acceptance Criteria

*From GDD `design/gdd/game-concept.md`, scoped to this story:*

- [x] 玩家动机分析完成（自主性、胜任感、关联性）
- [x] 核心循环设计明确（30秒、5分钟、30-120分钟、数天/数周循环）
- [x] 玩家类型验证完成（探索者、成就者等）
- [x] 循环设计文档化

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用PlayerMotivationDocument记录玩家动机分析
- 实现循环设计验证机制
- 实现玩家类型匹配度评估
- 与所有后续系统设计集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 001: 核心身份与支柱（处理核心身份和游戏支柱）
- Story 003: 视觉身份与技术愿景（处理视觉风格和技术实现）
- 具体系统实现（由其他史诗和故事处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Design stories — documentation specs]:**

- **AC-1**: 玩家动机分析完成
  - Given: 设计师需要验证新功能对玩家动机的影响
  - When: 参考玩家动机分析文档
  - Then: 能够评估功能对自主性、胜任感、关联性的影响
  - Edge cases: 不同玩家类型的动机差异、动机冲突

- **AC-2**: 核心循环设计明确
  - Given: 开发团队需要设计游戏循环
  - When: 参考核心循环设计文档
  - Then: 能够明确设计30秒、5分钟、30-120分钟、数天/数周循环
  - Edge cases: 循环间平衡、不同玩家时间偏好

- **AC-3**: 玩家类型验证完成
  - Given: 团队需要验证功能对目标玩家的吸引力
  - When: 参考玩家类型验证文档
  - Then: 能够评估功能对探索者、成就者等类型玩家的吸引力
  - Edge cases: 多类型玩家冲突、小众玩家类型

- **AC-4**: 循环设计文档化
  - Given: 新团队成员需要理解游戏循环设计
  - When: 查阅文档
  - Then: 能够快速理解各层级循环设计
  - Edge cases: 不同专业背景理解、外部合作者理解

---

## Test Evidence

**Story Type**: Design
**Required evidence**:
- Documentation: `docs/game-concept/player-motivation-and-cycles.md` — must exist and be comprehensive

**Status**: [x] Created and verified

---

## Dependencies

- Depends on: Story 001 (核心身份与支柱)
- Unlocks: Story 003 (视觉身份与技术愿景)