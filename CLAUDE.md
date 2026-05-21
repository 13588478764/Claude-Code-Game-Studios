# Claude Code Game Studios -- Game Studio Agent Architecture

Indie game development managed through 48 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: 无传统游戏引擎（Web小程序项目）
- **Framework**: uni-app (Vue 3 + TypeScript)
- **Language**: TypeScript
- **Version Control**: Git with trunk-based development
- **Build System**: HBuilderX / Vite
- **Asset Pipeline**: 静态资源 + JSON数据驱动配置
- **Target Platforms**: 微信小程序、抖音小程序、支付宝小程序

> **Note**: 本项目不使用传统游戏引擎。技术栈为前端框架 uni-app，
> 编译为多平台小程序。不需要引擎专家代理。

## Project Structure

@.claude/docs/directory-structure.md

## Framework Reference

> uni-app 文档: https://uniapp.dcloud.net.cn/
> Vue 3 文档: https://cn.vuejs.org/
> 框架版本在 training data 范围内，无需额外 reference docs。

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

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md
