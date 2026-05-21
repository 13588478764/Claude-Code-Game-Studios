# ADR-002: 分包策略

## Status

Accepted

## Context

小程序主包限制 2MB。事件 JSON 数据随职业数量增加会持续膨胀（每职业约 20-50KB）。MVP 阶段 2-3 个职业时数据量可控，但需要架构支持扩展到 20+ 个职业而不超限。

约束：
- 微信小程序主包 ≤ 2MB
- 分包单个 ≤ 2MB，总包 ≤ 20MB
- 每局只使用一个职业的事件数据
- 通用事件(common)每局都需要

## Decision

**按职业分包 + 通用事件在主包**

文件组织：
```
src/
├── config/events/
│   └── common-events.json          # 主包 (~10KB)
└── subpackages/
    └── events/
        ├── programmer-events.json   # 分包 (~30KB)
        ├── intern-events.json       # 分包 (~20KB)
        └── sales-events.json        # 分包 (~25KB)
```

`pages.json` 分包配置：
```json
{
  "subPackages": [
    {
      "root": "subpackages/events",
      "pages": []
    }
  ],
  "preloadRule": {
    "pages/job-select/index": {
      "packages": ["subpackages/events"],
      "network": "all"
    }
  }
}
```

加载策略：
1. 应用启动时：`common-events.json` 已在主包，同步可用
2. 进入职业选择页时：预下载事件分包（`preloadRule`）
3. 选择职业后：`EventLoader.loadJobEvents(jobId)` 从分包 require
4. 局结束时：`EventDataEngine.unload()` 释放内存

## Consequences

**正面：**
- 主包仅含 common 事件(~10KB)，远低于 2MB 限制
- 新增职业只加 JSON 文件到分包目录，零代码改动
- 预下载机制确保选职业后无加载等待
- 内存高效——每次只载入一个职业的事件

**负面：**
- 首次加载某职业需要网络（分包下载）
- 分包路径在条件编译时需注意跨平台差异
- 开发阶段需要模拟分包环境测试

**缓解：**
- preloadRule 在进入选择页时已提前下载
- EventDataEngine 有 3 次重试 + 5 个备用事件兜底（已在 GDD 中定义）
- 开发时可用 `uni.getSubPackageManager()` 模拟

## Engine Compatibility

uni-app 分包机制在微信/抖音/支付宝三端均支持。`preloadRule` 在微信基础库 2.3.0+、抖音小程序 1.0+ 可用。目标平台全部覆盖。

## GDD Requirements Addressed

- 事件数据引擎: 数据加载策略 — "小程序启动时加载当前职业的事件JSON（按需加载，非全量）"
- 事件数据引擎: "JSON文件放在分包中，不占主包空间"
- 事件数据引擎: "切换职业时卸载旧数据、加载新数据"
- 技术约束: 主包 < 2MB
