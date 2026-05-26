# ADR-009: Build Pipeline — Subpackage JSON Dual-Path Plugin

## Status

Accepted

## Date

2026-05-24

## Last Verified

2026-05-25

## Context

ADR-002 决定按职业分包：通用事件在主包、每职业 events JSON 在 subpackage（控制小程序主包 < 2MB 限制）。
运行时通过 `uni-event-loader` fetch `/subpackages/events/[job].json` 拉取。

但 uni-app 的默认资源管线只自动 copy `src/static/**` 到 dist —— `src/subpackages/**/*.json`
**不被识别**，导致：

- **production build (npm run build:mp-alipay 等)**：dist 缺 JSON → 运行时 404
- **dev:h5 (npm run dev:h5)**：vite dev server 不知道 src/subpackages/ → 浏览器 fetch 404
  → uni-event-loader fallback 到 5 个硬编码 fallback events → "每天都是相同 5 个事件"
  bug（b1c1021 修复前的实际症状）

约束：
- 不修改 uni-app 框架（避免 lock-in 升级风险）
- 不复制 JSON 到 src/static/（污染 source tree + ADR-002 分包路径无法对齐）
- dev:h5 / mp-weixin / mp-alipay / mp-toutiao 4 路径必须**用同一 plugin**（避免逻辑漂移）
- prod build 必须把 JSON 物理 copy 到 dist（小程序 runtime 无 server）
- dev:h5 不能 copy（vite dev 内存运行），必须通过 middleware 实时 serve

## Decision

**自定义 Vite plugin `copy-subpackage-data`，挂两个 hook：`configureServer` (dev) + `closeBundle` (build)，同时无 `apply` filter 确保 build/serve 双 mode 都注册。**

```ts
// vite.config.ts
import { defineConfig, type Plugin } from 'vite'
import uni from '@dcloudio/vite-plugin-uni'
import { readdirSync, statSync, mkdirSync, copyFileSync, existsSync, readFileSync } from 'node:fs'

function copySubpackageDataPlugin(): Plugin {
  return {
    name: 'copy-subpackage-data',
    // 关键：NO `apply` filter — 必须 dev 和 build 都生效

    // Dev mode — 拦截 /subpackages/**/*.json 实时从 src/ 读取
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        const url = req.url ?? ''
        if (!url.startsWith('/subpackages/') || !url.includes('.json')) return next()
        const clean = url.split('?')[0]!.split('#')[0]!
        const filePath = join(SRC_DIR, clean.replace(/^\//, ''))
        if (!existsSync(filePath)) return next()
        res.setHeader('Content-Type', 'application/json; charset=utf-8')
        res.end(readFileSync(filePath))
      })
    },

    // Production build — copy src/subpackages/**/*.json 到 dist
    closeBundle() {
      const subRoot = join(SRC_DIR, 'subpackages')
      if (!existsSync(subRoot)) return
      const outRoot = (this as any).environment?.config?.build?.outDir
      const distRoot = outRoot ?? process.env.UNI_OUTPUT_DIR
      if (!distRoot) return
      for (const src of walkAllFiles(subRoot)) {
        if (!src.endsWith('.json')) continue
        const dest = join(distRoot, relative(SRC_DIR, src))
        mkdirSync(dirname(dest), { recursive: true })
        copyFileSync(src, dest)
      }
    }
  }
}

export default defineConfig({
  plugins: [uni(), copySubpackageDataPlugin()]
})
```

**关键技术选择**：

1. **`closeBundle` 而非 `writeBundle`**：
   - `writeBundle` 在每个 output bundle 写完时触发（mini-program 单次构建有多 output → 多次触发）
   - `closeBundle` 整次构建结束触发一次 — 简化逻辑，避免 duplicate copy

2. **`environment?.config?.build?.outDir` + `process.env.UNI_OUTPUT_DIR` 双 fallback**：
   - vite 6 reuse-context API：`this.environment` 是新路径
   - uni-app build 通过 env var 注入 → fallback 保证多版本兼容

3. **`configureServer` middleware 顺序**：
   - 用 `server.middlewares.use` 注册全局 middleware，在 uni dev plugin 之前响应
   - 仅 intercept `/subpackages/` + `.json` 双前缀 → 不影响其他请求

4. **NO `apply: 'serve' | 'build'`**：
   - 默认 `apply` 没设 = 双 mode 都生效
   - 这是 b1c1021 fix 的核心 — 之前如果误加 `apply: 'build'` 就会导致 dev:h5 中 middleware 失效

## Consequences

**正面：**
- 单一 plugin 涵盖 4 构建路径（dev:h5 / mp-weixin / mp-alipay / mp-toutiao）+ dev/build 双 mode
- 与 ADR-002 分包策略对齐 — src/subpackages/ → dist/subpackages/ 路径 1:1
- 加新职业 JSON 零代码改动 — push 到 src/subpackages/events/ 即生效
- dev:h5 实测可玩到完整 382 events（修 b1c1021 前只能玩 5 fallback）
- 主包不增加 size（JSON 仍在 subpackage）
- 100% 可在 CI 复现 build：plugin 是纯 fs 操作，无外部依赖

**负面：**
- vite plugin 紧耦合 vite 6 `this.environment` API（vite 5 走 fallback env var 路径）
- copy 是同步 fs ops — 大量 JSON (~1MB) 时 build 时间略增（实测 ~50ms，忽略不计）
- middleware intercept 路径写死 `/subpackages/` 前缀 — 若未来重构路径需同步改

**缓解：**
- vite 升级时 plugin 改动小（仅 `closeBundle` API path）— 已用 fallback 兼容
- copy 性能问题不会在 MVP scale 出现（< 50 个 JSON）
- 路径前缀在 vite.config.ts / uni-event-loader.ts 各一处 — 改动可见

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Vite 6 + uni-app + Node.js |
| **Domain** | Build Pipeline |
| **Knowledge Risk** | MEDIUM |
| **References Consulted** | Vite plugin API docs（hooks: configureServer / closeBundle）; uni-app build output |
| **Post-Cutoff APIs Used** | Vite 6 `this.environment.config.build.outDir`（fallback to env var if absent） |
| **Verification Required** | npm run dev:h5 → 浏览器 F12 Network 验证 `/subpackages/events/programmer.json` 200；npm run build:mp-alipay → unzip dist 验证 subpackages/ 含 JSON |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (Subpackage Strategy) — 决定了 src/subpackages 物理布局 |
| **Enables** | K-1 (build pipeline 内容扩张) / 多职业内容加载 / dev:h5 完整可玩 |
| **Blocks** | 无 |

## GDD Requirements Addressed

- ADR-002 (subpackage strategy) 的运行时落地保证
- `design/gdd/event-data-engine.md` "数据驱动加载策略"——新增职业 JSON 无代码改动
- 修复 user-reported "每天都是相同 5 个事件" bug (commit b1c1021, 2026-05-25)

## Acceptance

- `npm run dev:h5` → F12 Network → `/subpackages/events/programmer.json` 返回 200 + JSON body
- `npm run build:mp-alipay` → `dist/build/mp-alipay/subpackages/events/programmer.json` 存在
- 同一 plugin 在 4 build target 下运行无 error
- 主包 size 检查：保持 < 2MB（subpackages 不计入主包）
- 加新职业 JSON 测试：push src/subpackages/events/new-job.json → dev:h5 立即可拉取，无 server restart
