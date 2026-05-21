# S1-3: 存档系统 service + store

> **Sprint**: 1 | **Priority**: Must Have | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Status**: ready-for-dev

## Goal

实现存档系统 service，封装 `uni.setStorageSync/getStorageSync`，支持 schema 版本化迁移、防抖写入、异常恢复。

## GDD Requirements Addressed

- save-system GDD 全部接口实现
- 资源管理依赖此服务做持久化
- 职业轮回依赖此服务存解锁状态

## Governing ADRs

- **ADR-001** — SaveService 通过 TypedEventEmitter 暴露 `onSaved`/`onLoadFailed`
- **ADR-003** — Store 订阅 SaveService 事件，UI 不直接调存档

## Technical Approach

### 文件

- `src/types/save.ts` — `SaveData`、`SaveSchema` 类型
- `src/services/save/save-service.ts`
- `src/stores/save-store.ts`
- `tests/unit/save-service.test.ts`

### 接口

```typescript
export interface SaveData {
  version: number
  resources: ResourceSnapshot
  jobUnlocks: string[]
  currentRun: RunSnapshot | null
  stats: GlobalStats
  updatedAt: number
}

export class SaveService {
  load(): SaveData | null
  save(data: SaveData): void  // debounced 100ms
  saveImmediate(data: SaveData): void
  clear(): void
  migrate(oldData: any, fromVersion: number): SaveData
  readonly onSaved: TypedEventEmitter<{ at: number }>
  readonly onLoadFailed: TypedEventEmitter<{ reason: string }>
}
```

### 关键实现要点

- 存储 key: `wlb:save:v1`
- 当前 schema version: 1
- 迁移函数链：`migrate1to2`, `migrate2to3` 等（Sprint 1 只有 v1，迁移逻辑预留接口）
- 防抖：100ms 内多次 save 合并为一次实际写入
- 异常恢复：load 失败时 emit `onLoadFailed`，返回 `null`，调用方决定 fallback

## Acceptance Criteria

- [ ] 全部 10 个 test case 通过（见 QA plan）
- [ ] 100% 行覆盖率
- [ ] 防抖逻辑通过 fake timer 测试验证
- [ ] schema 版本不匹配时正确触发迁移路径
- [ ] uni 平台 API 通过 mock 注入，测试不依赖真实小程序环境

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/save-service.test.ts`

## Dependencies

- 前置：S1-1, S1-2
- 阻塞：S1-5（资源管理需要持久化）
