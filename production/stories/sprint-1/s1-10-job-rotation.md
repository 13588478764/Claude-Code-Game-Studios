# S1-10: 职业轮回系统

> **Sprint**: 1 | **Priority**: Should Have | **Owner**: gameplay-programmer | **Estimate**: 1.0 day
> **Status**: backlog

## Goal

实现职业轮回系统：管理职业解锁、推荐算法（最近玩 ×0.1、新职业 ×5.0）、emit 解锁/选择事件。

## GDD Requirements Addressed

- job-rotation GDD 全部接口
- 局管理器依赖此系统提供当前职业 metadata
- 事件数据引擎依赖 jobId 加载分包

## Technical Approach

### 文件

- `src/types/job.ts` — `JobConfig`, `JobUnlockState`
- `src/config/jobs.json` — 静态职业配置（id/name/icon/salaryMul/eventPack）
- `src/services/job-rotation/job-rotation-system.ts`
- `src/stores/job-store.ts`
- `tests/unit/job-rotation-system.test.ts`

### 接口

```typescript
export class JobRotationSystem {
  init(saveData: SaveData | null): void
  getAllJobs(): JobConfig[]
  getAvailableJobs(): JobConfig[]
  getRecommendedJobs(count: number): JobConfig[]
  selectJob(jobId: string): void
  checkUnlocks(stats: GlobalStats): string[]  // 返回新解锁的 jobIds

  readonly onJobUnlocked: TypedEventEmitter<{ jobId: string }>
  readonly onJobSelected: TypedEventEmitter<{ jobId: string }>
}
```

### 初始职业

- `intern`（实习生，salaryMul 0.5，初始解锁）
- `programmer`（程序员，salaryMul 2.0，初始解锁）
- `sales`（销售，salaryMul 3.0，需通关 1 次解锁）
- `designer`（设计师，salaryMul 1.8，需赚到 200 元解锁）
- `runner`（外卖员，salaryMul 1.0，需"暴走离职" 3 次解锁）

### 推荐算法

```
weight(job) = base_weight
            × (recently_played(job) ? 0.1 : 1.0)
            × (never_played(job) ? 5.0 : 1.0)
            × (locked(job) ? 0 : 1.0)

recommended = top N by weight, tie-break random
```

## Acceptance Criteria

- [ ] 8 个 test case 通过
- [ ] 100% 行覆盖率

## Test Evidence

- **Type**: Logic
- **Path**: `tests/unit/job-rotation-system.test.ts`

## Dependencies

- 前置：S1-2, S1-3
- 阻塞：Sprint 2 局管理器、职业选择页
