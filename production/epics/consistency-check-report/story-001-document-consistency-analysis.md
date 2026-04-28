# Story 001: 文档一致性分析

> **Epic**: GDD文档一致性检查报告
> **Status**: Pending Test
> **Layer**: Meta
> **Type**: Analysis
> **Manifest Version**: 2026-04-27

## Context

**GDD**: `design/gdd/consistency-check-report.md`
**Requirement**: `TR-consistency-check-001`

**ADR Governing Implementation**: ADR-001: 核心架构决策
**ADR Decision Summary**: Godot 4.6引擎选择，数据持久化

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: 使用Godot的文件系统和数据处理功能分析GDD文档

**Control Manifest Rules (this layer)**:
- Required: 分析结果必须准确识别所有文档矛盾
- Forbidden: 禁止忽略严重数值冲突
- Guardrail: 分析过程不应影响现有文档

---

## Acceptance Criteria

*From GDD `design/gdd/consistency-check-report.md`, scoped to this story:*

- [x] 识别所有严重矛盾（系统核心数值冲突）
- [x] 识别所有数值不一致（伤害与战斗系统公式冲突）
- [x] 识别所有状态效果数值不一致
- [x] 识别所有分类与命名体系不一致

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

- 使用DocumentConsistencyAnalyzer节点管理文档一致性分析
- 实现analyze_gdd_documents()方法分析GDD文档
- 实现identify_severe_contradictions()方法识别严重矛盾
- 实现identify_numerical_inconsistencies()方法识别数值不一致
- 实现identify_naming_inconsistencies()方法识别命名体系不一致
- 实现analysis_completed信号通知其他系统
- 与DocumentationSystem和AnalysisSystem系统集成

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: 冲突解决方案规划（处理冲突解决方案）
- Story 003: 文档对齐实施（处理文档对齐实施）
- 核心游戏逻辑（由其他系统处理）

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

**[For Analysis stories — evidence specs]:**

- **AC-1**: 识别所有严重矛盾
  - Given: GDD文档集合
  - When: 文档一致性分析运行
  - Then: 识别出所有严重矛盾（如等级上限、境界数量、属性点数等）
  - Edge cases: 新增文档、文档更新、临时注释

- **AC-2**: 识别所有数值不一致
  - Given: 战斗相关GDD文档
  - When: 数值一致性检查运行
  - Then: 识别出所有数值不一致（如伤害公式、暴击系数等）
  - Edge cases: 不同公式表达方式、单位转换、默认值

- **AC-3**: 识别所有状态效果数值不一致
  - Given: 状态效果相关GDD文档
  - When: 状态效果一致性检查运行
  - Then: 识别出所有状态效果数值不一致
  - Edge cases: 不同状态效果类型、复合状态效果、临时状态

- **AC-4**: 识别所有分类与命名体系不一致
  - Given: 分类和命名相关GDD文档
  - When: 分类命名一致性检查运行
  - Then: 识别出所有分类与命名体系不一致
  - Edge cases: 多语言支持、缩写形式、别名

---

## Test Evidence

**Story Type**: Analysis
**Required evidence**:
- Evidence: `production/qa/evidence/document-consistency-analysis-evidence.md` — must exist and pass

**Status**: [x] Completed

---

## Dependencies

- Unlocks: Story 002 (冲突解决方案规划)