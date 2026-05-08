# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Version Control**: Git with trunk-based development
- **Build System**: SCons (engine), Godot Export Templates
- **Asset Pipeline**: Godot Import System + custom resource pipeline

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## 🌏 Language & Communication Protocol (语言与沟通协议)

**CRITICAL RULE**: All interactions, explanations, documentation, and comments MUST be in **Simplified Chinese (简体中文)**.

1. **Conversation Language**: Always respond to the user in Simplified Chinese.
2. **Code Comments**: All code comments must be in Simplified Chinese.
3. **Documentation**: All GDD and narrative texts must be in Simplified Chinese.
4. **Technical Terms**: Keep code classes/keywords in English; translate game concepts per Terminology Standards.


## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Terminology Standards

### Core Game Terminology

**Official Game Genre**: 修真武侠RPG (Cultivation Wuxia RPG)

**Unified Terminology** (use consistently across all documents and code):

| 概念 | 标准术语 | 英文 | 说明 |
|------|---------|------|------|
| 游戏类型 | 修真武侠 | Cultivation Wuxia | 融合修仙与武侠元素 |
| 世界设定 | 修真界 / 九州修真界 | Cultivation World | 主要使用"修真界"，详细时用"九州修真界" |
| 功法系统 | 修真功法 / 武学 | Martial Arts / Cultivation Techniques | 代码中用"martial_arts"，叙事中用"修真功法" |
| 随机事件 | 仙缘 / 奇遇 | Encounter / Fortuitous Encounter | 叙事中用"仙缘"，系统中用"encounter" |
| 等级系统 | 境界 | Realm | 九大境界：炼气→筑基→金丹→元婴→化神→返虚→合道→大乘→渡劫 |
| 修炼者 | 修士 / 修真者 | Cultivator | 可互换使用 |
| 能量系统 | 灵气 | Spiritual Energy | 天地间的修真能量 |
| 内力 | 内力 / 真元 | Internal Energy / Qi | 代码中用"internal_energy"，叙事中可用"真元" |
| 宗门 | 修真宗门 / 宗门 | Sect / Cultivation Sect | 九大修真势力 |

**术语使用规则**:

1. **GDD文档**: 优先使用技术术语（如"武学系统"、"奇遇系统"），但需在概述中说明这是"修真武侠"背景
2. **叙事文档**: 优先使用世界观术语（如"修真功法"、"仙缘"、"修真界"）
3. **代码注释**: 使用中文术语 + 英文变量名，如 `// 境界突破 (Realm Breakthrough)`
4. **变量命名**: 使用英文，如 `realm_index`, `martial_arts`, `encounter_system`
5. **UI文本**: 使用玩家友好的术语（如"修真功法"、"仙缘奇遇"）

**禁止混用**:
- ❌ 不要在同一文档中混用"江湖"和"修真界"
- ❌ 不要在叙事文档中使用纯技术术语（如"encounter"）
- ❌ 不要在GDD中完全避免提及"修真"背景

**示例**:
- ✅ GDD: "武学系统采用修真境界体系，分为九大境界..."
- ✅ 叙事: "玩家在修真界中通过仙缘获得强大的修真功法..."
- ✅ 代码: `// 修真功法数据 (Martial Arts Data)`
- ✅ UI: "修真功法", "仙缘奇遇", "境界突破"

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md