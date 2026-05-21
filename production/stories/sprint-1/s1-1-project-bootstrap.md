# S1-1: 项目脚手架搭建

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: devops-engineer | **Estimate**: 1.0 day
> **Status**: ready-for-dev

## Goal

搭建 uni-app + Vue 3 + TypeScript strict + Pinia + Vitest 的开发环境，让 `npm run dev:mp-weixin` 能在微信开发者工具运行，`npm test` 能跑测试。

## GDD Requirements Addressed

- 全部 9 个 MVP GDD 都依赖此基础设施

## Governing ADRs

- 此故事不直接涉及 ADR，但为 ADR-001/002/003 的实施提供运行环境

## Technical Approach

### 依赖

- `vue@^3.4`
- `pinia@^2.1`
- `@dcloudio/uni-app@^3.0`
- `@dcloudio/uni-mp-weixin`、`@dcloudio/uni-mp-toutiao`、`@dcloudio/uni-mp-alipay`
- `typescript@^5.4`（strict mode）
- `vitest@^1.5`、`@vue/test-utils@^2.4`

### 文件清单

- `package.json` — 依赖 + scripts (`dev:mp-weixin`, `dev:mp-toutiao`, `dev:mp-alipay`, `test`, `test:cov`, `build:mp-weixin`)
- `tsconfig.json` — strict mode + path alias `@/*` → `src/*`
- `vite.config.ts`、`vitest.config.ts`
- `src/main.ts`、`src/App.vue`、`src/manifest.json`、`src/pages.json`
- `src/env.d.ts` — uni 类型声明
- `src/pages/index/index.vue` — 占位首页（S1-7 替换）
- 目录骨架：`src/{services,stores,components,pages,types,config,utils}/`
- `.gitignore` — 已存在则补充 dist/ unpackage/

## Acceptance Criteria

- [ ] `npm install` 成功（无 peer 警告残留）
- [ ] `npm run dev:mp-weixin` 编译产物到 `dist/dev/mp-weixin/`
- [ ] 微信开发者工具导入 `dist/dev/mp-weixin/` 后能预览
- [ ] 占位首页显示 "打工轮回 - Sprint 1"
- [ ] `npm test` 启动 Vitest（即使无测试也能跑通）
- [ ] `tsc --noEmit` 通过（strict mode）
- [ ] Git 忽略 `node_modules/`、`dist/`、`unpackage/`、`*.local`

## Test Evidence

- **Type**: Config/Data
- **Path**: `production/qa/smoke-2026-05-19.md`（首日 smoke check）

## Out of Scope

- 多端真机测试（Sprint 3）
- CI/CD 配置（独立故事，未排入 Sprint 1）
- 性能优化（Polish 阶段）

## Dependencies

- 前置：无
- 阻塞：S1-2 ~ S1-11（所有故事都依赖此脚手架）
