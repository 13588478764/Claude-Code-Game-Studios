# S2-6: 事件 schema lint at build time

> **Sprint**: 2 | **Status**: Complete | **Layer**: Foundation/Infrastructure | **Type**: Config/Data | **Owner**: devops-engineer | **Estimate**: 0.5 day
> **Completed**: 2026-05-19
> **TR-ID**: pending | **Manifest Version**: N/A

## Context

**GDD**: `design/gdd/status-system.md` v2.1 Tuning Knobs 段（Schema validation 规则）+ `design/gdd/event-data-engine.md` schema 部分
**Requirement Summary**: 在 build time 校验所有事件 JSON 的 schema：合法性 + buff/debuff mul 方向 + days 范围。坏数据 → 阻塞 build；输出 friendly 报错（含文件 + entry id）。

**Governing ADRs**:
- **ADR-002 分包策略** — 校验 src/static/events/*.json + src/subpackages/events/*.json

**Engine**: vite plugin 或 npm prebuild hook（任选）| **Risk**: LOW（fallback：直接降级为 npm prebuild script）

---

## Acceptance Criteria

- [ ] AC-1: 现有 4 个 events JSON（common/programmer/intern/sales 共 163 张）通过校验
- [ ] AC-2: `type:'buff' && energyMul > 1.0` 或 `moodMul > 1.0` → warn（不阻塞 build）
- [ ] AC-3: `type:'debuff' && energyMul < 1.0` 或 `moodMul < 1.0` → warn
- [ ] AC-4: `days > BUFF_MAX_DAYS (2)` → warn
- [ ] AC-5: `days <= 0` → ERROR（阻塞 build）
- [ ] AC-6: id 重复 → ERROR
- [ ] AC-7: choiceA 或 choiceB 缺失 → ERROR
- [ ] AC-8: effect.target 不在 [energy, mood, money] → ERROR
- [ ] AC-9: 错误输出含文件路径 + entry id + 字段名（friendly format）
- [ ] AC-10: 集成到 `npm run build:mp-weixin`（vite plugin 或 prebuild）
- [ ] AC-11: validator 单元测试覆盖

---

## Implementation Notes

### 文件
- `tools/event-schema-validator.ts` — validator 主逻辑（已有 src/services/event-data/event-schema.ts，可复用扩展）
- `tools/build-validate-events.ts` — npm prebuild 入口（如选 prebuild 路径）
- 或 `vite.config.ts` 内联 plugin（如选 vite plugin 路径）
- `package.json` 添加 `prebuild:mp-weixin` script（如 prebuild 路径）
- `tests/unit/event-schema-validator.test.ts`

### 推荐路径：npm prebuild script（更简单可靠）

```json
// package.json
{
  "scripts": {
    "prebuild:mp-weixin": "tsx tools/build-validate-events.ts",
    "prebuild:mp-toutiao": "tsx tools/build-validate-events.ts",
    "prebuild:mp-alipay": "tsx tools/build-validate-events.ts"
  }
}
```

```typescript
// tools/build-validate-events.ts
import { validateEventList } from '../src/services/event-data/event-schema'
// 扩展现有 validator 增加 buff/debuff 方向检查 + days 范围
// 扫描 src/static/events/*.json + src/subpackages/events/*.json
// 全部通过 → exit 0；任何 ERROR → exit 1（阻塞 build）；warn 仅打印
```

### 关键实现要点
- 复用现有 `src/services/event-data/event-schema.ts` 的 `validateEventList`，扩展增加 buff 方向 + days 范围检查
- 友好输出：`[ERROR] src/subpackages/events/programmer-events.json :: prog-001 :: choiceA.effects[0].target='xxx' (must be one of energy/mood/money)`
- 测试 fixture 用临时 JSON 文件或内联对象

---

## Out of Scope

- runtime schema 校验（已在 S1-4 EventDataEngine 中存在，运行时仅作兜底）
- 数据迁移（无）
- IDE-side validation（VSCode JSON schema） — 未来 nice-to-have

---

## QA Test Cases

### Validator Unit Tests

**AC-1: 现有数据通过**
- Given: 4 个真实 events JSON 文件
- When: validator 跑全部
- Then: ERROR count === 0（warn 可能有，不阻塞）

**AC-5/6/7/8: ERROR 触发**
- Given: 构造含 days=0 / id 重复 / 缺 choiceA / target='xxx' 的 fixture
- When: validator 跑
- Then: 每种情况 ERROR count >= 1，错误信息含正确 entry id

**AC-2/3/4: WARN 触发（不阻塞）**
- Given: buff energyMul=1.5（应为 ≤1） / debuff moodMul=0.5（应为 ≥1） / days=10（>2）
- When: validator 跑
- Then: warn 输出，但 exit code 仍 0

### Build Integration（手测）

**AC-10: build 拦截**
- Setup: 临时改一个 events JSON 加 days=0
- When: `npm run build:mp-weixin`
- Then: build 失败（exit 1），错误信息含文件名 + entry id
- After: 还原数据 → build 成功

---

## Test Evidence

**Story Type**: Config/Data
**Required**:
- `tests/unit/event-schema-validator.test.ts` — 覆盖全部 ERROR + WARN 情况
- `production/qa/smoke-2026-06-XX.md` smoke check 含 build 拦截手测记录

**Status**: [x] Created 2026-05-19 — 32 unit tests + 手动 build interception 验证

## Completion Notes

**Files created**:
- `tools/validate-events.ts` — Build-time validator script，扫描 src/static/events + src/subpackages/events
- `tests/unit/event-schema-validator.test.ts` — 32 测试（全部 ERROR + WARN 场景）

**Files modified**:
- `src/services/event-data/event-schema.ts` — 加 `validateEventForBuild` / `validateEventArrayForBuild` / `formatIssue` + BUFF_MAX_DAYS 常量（保留原 runtime 校验函数不变）
- `package.json` — 加 `validate:events` 脚本 + `build:mp-*` 链入 `npm run validate:events && uni build`
- 安装 `tsx` dev dep（运行 TS 构建脚本）

**Verification**:
- npm test: 279/279 pass（前 247 + 新 32）
- npm run type-check: pass
- npm run validate:events: 4 个真实 events JSON 全部通过 ✓
- npm run build:mp-weixin: 好数据 → DONE Build complete；坏数据 → "✗ Validation failed: Build aborted." ✓

**手动验证 (build chain interception)**：
```
[validate-events] Validating 5 event file(s)...
[ERROR] src/static/events/bad-test.json :: bad :: choiceA.effects[0].target: target must be one of energy/mood/money (got "mana")

✗ Validation failed: 1 error(s), 0 warning(s).
Build aborted. Fix the errors above and re-run.
```

**Deviations**:
- npm `prebuild:*` 自动钩子仅对 "build" 这个标准脚本名生效，对 `build:mp-weixin` 等自定义不生效。改用显式 `&&` 链式：`npm run validate:events && uni build -p mp-weixin`
- 安装 tsx 作为 dev dep（运行 TypeScript 构建脚本无需预编译）

Ready for: `/code-review` → `/story-done`

---

## Dependencies

- 前置: S1-1（项目脚手架），S1-4（已有 event-schema.ts）
- 阻塞: S2-8（smoke check 需要 build 通过）
