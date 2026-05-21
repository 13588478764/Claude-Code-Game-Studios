# Core Loop Prototype — 打工轮回

> Single-file HTML prototype validating the binary-choice card + resource management core loop.

## Hypothesis

二选一事件卡 + 资源管理的核心循环是否有趣？3 分钟内能否产生紧张感和笑点？

## How to Run

直接在浏览器中打开 `index.html` 即可。无需安装、无需启动服务、无需联网。

```bash
open prototypes/core-loop/index.html  # macOS
# or just double-click the file
```

## Status

**CONCLUDED — PROCEED to production**

详细发现与建议见 [REPORT.md](./REPORT.md)。

## Findings (Summary)

- 核心循环验证通过 ✓
- 4 个深度机制（后果链 / Buff / 风险 / 消费）全部 work ✓
- 视觉品质显著影响玩法评价（素界面 → 误判机制简单）
- 内容广度瓶颈是生产任务，不是原型该解决的

## What This Prototype Demonstrates

1. 二选一卡片 UI 流程
2. 三资源（精力/心情/金钱）平衡张力
3. 5 天工作周节奏
4. followUp 后果链事件
5. Buff/Debuff 状态系统
6. 风险概率事件（骰子动画）
7. 局内消费（小卖部）
8. 视觉品质基线（渐变、状态头像、舞台过场）

## Important Constraints

- **Prototype code MUST NOT be migrated to production** — 生产代码必须从零按架构重写
- **Production code MUST NOT import from this directory**
- 此目录在概念验证完成后保留供参考，不再扩展

## Files

- `index.html` — 原型代码（HTML + CSS + 内联 JS + 硬编码事件数据）
- `REPORT.md` — 完整原型报告（hypothesis / approach / result / metrics / recommendation / lessons）
- `README.md` — 本文件
