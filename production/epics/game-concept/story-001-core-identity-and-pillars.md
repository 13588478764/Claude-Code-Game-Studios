# Story 001: 核心身份与支柱

> **Epic**: 游戏概念
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Design
> **Manifest Version**: 2026-04-26

## Context

**GDD**: `design/gdd/game-concept.md`
**Requirement**: `TR-game-concept-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的文档系统记录核心身份和游戏支柱

**Control Manifest Rules (this layer)**:
- Required: 核心身份和支柱必须清晰定义并指导后续设计
- Forbidden: 禁止偏离核心身份和支柱进行设计
- Guardrail: 所有设计决策必须参考核心支柱

---

## Acceptance Criteria

*From GDD `design/gdd/game-concept.md`, scoped to this story:*

- [x] 游戏核心身份定义清晰（工作标题、电梯推销、核心动词）
- [x] 游戏支柱明确（深度武学系统、自由探索与发现、奇遇驱动的成长）
- [x] 反面支柱定义（游戏不是什么）
- [x] 核心身份与支柱文档化

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用GameConceptDocument记录核心身份和支柱
- 实现核心身份验证机制
- 实现支柱一致性检查
- 与所有后续系统设计集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 玩家动机与循环（处理玩家动机和循环设计）
- Story 003: 视觉身份与技术愿景（处理视觉风格和技术实现）
- 具体系统实现（由其他史诗和故事处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Design stories — documentation specs]:**

- **AC-1**: 游戏核心身份定义清晰
  - Given: 设计团队需要了解游戏核心身份
  - When: 查阅核心身份文档
  - Then: 能够清晰理解游戏的工作标题、电梯推销、核心动词等
  - Edge cases: 不同团队成员理解一致性、外部合作者理解

- **AC-2**: 游戏支柱明确
  - Given: 设计师需要验证新功能是否符合游戏方向
  - When: 参考游戏支柱
  - Then: 能够明确判断新功能是否符合深度武学系统、自由探索、奇遇驱动成长等支柱
  - Edge cases: 边界功能判断、多支柱冲突

- **AC-3**: 反面支柱定义
  - Given: 团队考虑添加新功能
  - When: 参考反面支柱
  - Then: 能够避免偏离核心体验的功能
  - Edge cases: 诱惑性但偏离主题的功能、团队成员不同理解

- **AC-4**: 核心身份与支柱文档化
  - Given: 新团队成员加入项目
  - When: 查阅文档
  - Then: 能够快速理解游戏的核心身份和支柱
  - Edge cases: 不同专业背景的团队成员、外部合作者

---

## Test Evidence

**Story Type**: Design
**Required evidence**:
- Documentation: `docs/game-concept/core-identity-and-pillars.md` — must exist and be comprehensive

**Status**: [x] Created and verified

---

## Dependencies

- Unlocks: Story 002 (玩家动机与循环), Story 003 (视觉身份与技术愿景)