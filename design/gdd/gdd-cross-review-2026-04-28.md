# 跨GDD审查报告

**日期**: 2026-04-28  
**审查范围**: 7个核心系统GDD（采样策略）  
**审查模式**: 完整审查（一致性 + 设计理论 + 场景演练）  
**审查员**: AI代理

---

## 执行摘要

本次审查采用智能采样策略，重点审查了7个核心系统GDD：
- game-concept.md（游戏概念）
- systems-index.md（系统索引）
- world-streaming-system.md（世界流式加载）
- lod-system.md（LOD系统）
- martial-arts-database.md（武学数据库）
- item-database.md（物品数据库）
- combat-system.md（战斗系统）

同时参考了已有的consistency-check-report.md（涵盖33个GDD的详细一致性检查）。

**发现的问题总数**: 26个
- 🔴 **阻塞级问题**: 4个（必须在架构实施前解决）
- ⚠️ **警告级问题**: 18个（应该解决，但不阻塞）
- ℹ️ **信息级问题**: 4个（值得注意）

---

## 一、一致性问题

### 阻塞级问题（必须解决）

#### 🔴 B-01: 目标平台定义冲突

**涉及GDD**: game-concept.md, martial-arts-database.md, item-database.md, world-streaming-system.md, lod-system.md

**问题描述**:
- **game-concept.md** 明确定义目标平台为 **Steam (PC)**，技术考量为"目标60FPS在主流PC配置上运行"
- **martial-arts-database.md** 和 **item-database.md** 却大量提及"Web平台优化"、"浏览器内存管理"、"Web端异步加载"
- 验收标准中提到"Web平台内存有限（<100MB）"，但PC平台通常有>2GB内存

**影响**:
- 武学数据库和物品数据库的设计假设是Web平台（内存限制<100MB）
- 但游戏概念明确定义为Steam PC平台（内存通常>2GB）
- 这导致过度的内存优化（不必要的复杂性）和性能预算错配

**建议**:
统一平台定义。如果目标是Steam PC：
1. 将martial-arts-database.md和item-database.md中的"Web平台优化"改为"PC平台优化"
2. 调整内存预算：从<100MB提升到合理的PC范围（如<500MB）
3. 移除不必要的Web特定优化（如过度的资源分片）

**优先级**: 🔴 CRITICAL - 影响整体架构决策

---

#### 🔴 B-02: 伤害计算公式不统一

**涉及GDD**: martial-arts-database.md, combat-system.md

**问题描述**:

**martial-arts-database.md** 定义:
```
最终伤害 = 基础伤害 × 暴击系数 × 连击系数 × 弱点系数 × 破防系数 × 状态系数 × 随机浮动 × 元素克制倍率
```

**combat-system.md** 定义:
```
最终伤害 = 基础伤害 × 暴击系数 × 连击系数 × 弱点系数 × 破防系数 × 状态系数 × 随机浮动
```

**差异**: combat-system缺少"元素克制倍率"变量

**影响**:
- 两个系统对同一公式的定义不一致
- 实施时会产生混淆：到底应该包含元素克制倍率吗？
- 可能导致战斗平衡性问题

**建议**:
1. 确定权威公式版本（建议以combat-system.md为准，因为它是战斗的核心系统）
2. 统一更新所有相关GDD
3. 在control-manifest.md中明确记录最终公式

**优先级**: 🔴 CRITICAL - 影响核心战斗机制

---

#### 🔴 B-03: 等级上限冲突（来自已有报告）

**涉及GDD**: character-progression-system.md, experience-system.md, level-up-mechanism.md

**问题描述**:
- character-progression-system.md: 等级上限 **99级**，总属性点495（99×5）
- experience-system.md: 玩家等级范围 **1-99**
- level-up-mechanism.md: 最高境界化神期 **Lv 41-50**，硬上限 **50级**

**影响**:
- 角色成长和经验值系统定义99级，但等级提升机制定义50级
- 这是根本性冲突，影响整个数值体系
- 如果最高50级，"495总属性点"的计算完全失效

**建议**:
1. 立即确定最终等级上限（建议50级，符合传统武侠"化神期"为最高境界的设定）
2. 更新character-progression-system.md和experience-system.md
3. 重新计算总属性点数（50×5=250点或50×1=50点，取决于每级属性点数）

**优先级**: 🔴 CRITICAL - 影响整个数值体系

---

#### 🔴 B-04: 属性维度冲突（来自已有报告）

**涉及GDD**: character-progression-system.md, level-up-mechanism.md, damage-calculation-system.md, combat-system.md

**问题描述**:
- character-progression-system.md: **六维**（力道、身法、根骨、悟性、**定力**、福缘）
- level-up-mechanism.md: **五维**（力道、身法、根骨、悟性、福缘，无定力）
- damage-calculation-system.md: **五维**（STR、WIS、AGI、CON、LUK，无定力）
- combat-system.md: 无定力相关描述

**影响**:
- character-progression-system独有"定力"属性（影响架势条上限、格挡成功率）
- 但所有其他系统均不引用此属性
- 这意味着要么定力属性在其他文档中被遗漏，要么角色成长系统多定义了一个不存在的属性

**建议**:
1. 确定是否保留"定力"属性
2. 如果保留，必须在所有相关系统中添加定力的影响（特别是combat-system和health-defense-system）
3. 如果移除，更新character-progression-system.md

**优先级**: 🔴 CRITICAL - 影响角色属性体系

---

### 警告级问题（应该解决）

#### ⚠️ W-01: 依赖关系不对称

**涉及GDD**: systems-index.md, combat-system.md

**问题描述**:
- combat-system.md声明依赖：角色成长系统、武学系统、装备系统、任务系统
- systems-index.md声明combat-system依赖：武学系统、装备系统（缺少角色成长系统和任务系统）

**影响**:
依赖关系不完整会导致实施顺序错误，可能在角色成长系统或任务系统未完成时就开始实施战斗系统

**建议**:
更新systems-index.md，添加完整的依赖关系

**优先级**: ⚠️ WARNING

---

#### ⚠️ W-02: 卸载距离不一致

**涉及GDD**: world-streaming-system.md, lod-system.md

**问题描述**:
- world-streaming-system.md: 卸载距离 = 屏幕宽度 × **3.0**
- lod-system.md: 低→卸载距离 = 屏幕宽度 × **4.5**

**影响**:
两个紧密协作的系统对卸载距离的定义不一致，可能导致资源管理混乱

**建议**:
统一卸载距离定义。建议使用4.5倍屏宽（lod-system的值），因为这样可以确保LOD系统完全卸载后，world-streaming才卸载区块

**优先级**: ⚠️ WARNING

---

#### ⚠️ W-03: 每级属性点数冲突（来自已有报告）

**涉及GDD**: character-progression-system.md, level-up-mechanism.md, experience-system.md

**问题描述**:
- character-progression-system.md: 每级获得 **5点**属性点 + **1点**天赋点
- level-up-mechanism.md: 每级获得 **1点**自由属性点
- experience-system.md: 每升1小级获得 **1个**自由属性点

**影响**:
这是5倍的数值差异。如果采用5点方案，99级制下总共495点，角色极其强大；如果采用1点方案，50级制下仅50点，属性分配非常稀缺

**建议**:
确定最终方案（建议1点/级，符合传统RPG设计），统一更新所有GDD

**优先级**: ⚠️ WARNING

---

#### ⚠️ W-04: 境界突破加成方式冲突（来自已有报告）

**涉及GDD**: character-progression-system.md, level-up-mechanism.md

**问题描述**:
- character-progression-system.md: 全属性 **+10%**（百分比乘法式）
- level-up-mechanism.md: **HP上限+200、内力上限+100**（固定加成）+ 5个自由属性点

**影响**:
一个是百分比加成（后期越来越强），一个是固定值加成（后期增量占比越来越小），两者属于完全不同的数值成长曲线

**建议**:
统一加成方式。建议使用百分比加成（更符合武侠"境界突破"的概念），但需要平衡后期数值膨胀

**优先级**: ⚠️ WARNING

---

#### ⚠️ W-05至W-18: 其他数值不一致

参考已有的consistency-check-report.md中的详细问题列表：
- 弱点修正值冲突（2.0 vs 1.5）
- 破防伤害加成不统一（1.5 vs 1.5-2.0）
- 内力回复率冲突（10% vs 5%-10%）
- 暴击系数表示冲突
- 身法属性范围冲突
- 伤害颜色编码冲突
- Focus命中加成不一致
- Vulnerable伤害加成不一致
- 装备品阶分级冲突（6级 vs 4级 vs 5级）
- 元素体系冲突（火冰雷毒 vs 金木水火土）
- 武器适配系数不一致
- 奇遇触发概率公式冲突
- 奇遇奖励数值冲突
- 武学伤害公式多版本

**优先级**: ⚠️ WARNING（每个问题单独评估）

---

## 二、游戏设计整体性问题

### 警告级问题

#### ⚠️ D-01: 认知负荷风险

**问题描述**:
在核心战斗循环中，玩家需要同时管理5个活跃系统：

1. **战斗系统**: 行动顺序、指令选择、弱点判断、连击管理
2. **内力管理系统**: 内力消耗、回复策略
3. **架势系统**: 架势值监控、破防时机
4. **连携系统**: 连携槽积累、连携时机
5. **装备系统**（间接）: 装备属性影响、武器类型匹配

**影响**:
根据认知心理学研究，3-4个同时活跃系统是舒适上限。当前设计超过了这个阈值，可能导致玩家认知过载

**建议**:
1. 将架势系统设为被动（自动显示，无需主动管理）
2. 简化连携系统的触发条件（例如自动触发而非手动选择）
3. 或者将内力管理简化为自动回复，减少玩家需要主动管理的资源类型

**优先级**: ⚠️ WARNING - 影响玩家体验

---

#### ⚠️ D-02: 经济循环不完整

**问题描述**:

**物品来源（Sources）**:
- 战斗掉落
- 奇遇奖励
- 商店购买

**物品消耗（Sinks）**:
- 消耗品使用
- 装备磨损？（未明确定义）
- 制作材料？（game-concept反面支柱明确说"不包含复杂经济系统"）

**影响**:
装备类物品缺少明确的消耗机制。如果玩家不断获得装备但没有消耗途径，会导致：
- 背包膨胀
- 装备贬值（后期装备过剩）
- 探索奖励失去意义

**建议**:
即使不包含复杂经济系统，也应该定义简单的装备sink：
1. 装备分解系统（获得少量材料）
2. 装备出售上限（商店拒绝收购过多同类装备）
3. 装备升级消耗（用旧装备强化新装备）

**优先级**: ⚠️ WARNING - 影响长期游戏平衡

---

### 信息级问题

#### ℹ️ I-01: 支柱对齐良好

**观察**:
所有已读取系统都明确服务于游戏支柱：
- world-streaming, lod → 支柱2：自由探索与发现
- martial-arts-database, combat-system → 支柱1：深度武学系统
- item-database → 支柱3：奇遇驱动的成长

**结论**: 没有发现支柱漂移或反支柱违反

**优先级**: ℹ️ INFO - 正面发现

---

#### ℹ️ I-02: Entity Registry为空

**观察**:
design/registry/entities.yaml当前为空，没有注册任何实体、物品、公式或常量

**影响**:
- 一致性检查依赖全GDD读取，无法利用registry加速
- 跨GDD引用无法快速验证

**建议**:
在解决上述一致性问题后，运行/consistency-check技能填充registry

**优先级**: ℹ️ INFO - 流程改进建议

---

## 三、跨系统场景问题

### 场景1: 玩家在战斗中升级并获得装备

**触发**: 玩家击杀精英敌人，经验值达到升级阈值

**系统激活顺序**:
1. combat-system: 敌人死亡 → 发出enemy_killed信号
2. 角色成长系统: 接收信号 → add_exp() → 检查升级
3. 角色成长系统: 触发level_up事件 → 弹出升级UI
4. combat-system: 战斗仍在进行（其他敌人存在）
5. item-database: 生成掉落物品
6. 装备系统: 玩家拾取装备

**⚠️ 问题**: 时序冲突

combat-system.md没有明确说明"升级UI弹出时战斗是否暂停"。如果不暂停，玩家可能在查看升级选项时被敌人攻击。如果暂停，需要明确定义暂停机制。

**建议**:
在combat-system.md中添加明确规则：
- "战斗中升级时，时间暂停，玩家分配属性点后继续战斗"
- 或"战斗中升级时，升级UI延迟到战斗结束后显示"

**优先级**: ⚠️ WARNING

---

### 场景2: 玩家快速移动触发区块加载和LOD切换

**触发**: 玩家使用轻功快速移动

**系统激活顺序**:
1. 开放世界探索系统: 检测玩家位置变化
2. world-streaming-system: 检查加载距离 → 触发预加载
3. lod-system: 检查LOD切换距离 → 调整细节级别
4. world-streaming-system: 检查卸载距离 → 卸载远处区块

**✅ 设计良好**: 两个系统的距离阈值基本协调

**⚠️ 小问题**: 卸载距离不一致（已在W-02中记录）

**优先级**: ℹ️ INFO - 整体设计良好

---

## 四、GDD标记建议

### 需要修订的GDD

| GDD | 原因 | 类型 | 优先级 |
|-----|------|------|--------|
| martial-arts-database.md | 平台定义冲突（Web vs PC） | 一致性 | 阻塞 |
| item-database.md | 平台定义冲突（Web vs PC） | 一致性 | 阻塞 |
| combat-system.md | 伤害公式缺少元素克制倍率 | 一致性 | 阻塞 |
| character-progression-system.md | 等级上限、属性维度、每级属性点数冲突 | 一致性 | 阻塞 |
| level-up-mechanism.md | 等级上限、境界加成方式冲突 | 一致性 | 阻塞 |
| systems-index.md | 依赖关系不完整 | 一致性 | 警告 |
| world-streaming-system.md | 卸载距离不一致 | 一致性 | 警告 |

---

## 五、最终裁决

### 裁决: 🔴 FAIL

**原因**: 存在4个阻塞级一致性问题，必须在架构实施前解决

### 必须解决的问题（按优先级）:

1. **B-01: 目标平台定义冲突** - 统一为Steam PC平台
2. **B-03: 等级上限冲突** - 确定为50级或99级
3. **B-04: 属性维度冲突** - 确定五维或六维
4. **B-02: 伤害计算公式不统一** - 统一公式定义

### 建议的解决顺序:

**第一步**: 召开设计会议，确定以下核心决策：
- 最终等级上限（建议50级）
- 属性维度（建议五维，移除定力或将定力整合到其他属性）
- 每级属性点数（建议1点/级）
- 境界突破加成方式（建议百分比加成）

**第二步**: 更新受影响的GDD：
- character-progression-system.md
- level-up-mechanism.md
- experience-system.md
- martial-arts-database.md（平台改为PC）
- item-database.md（平台改为PC）
- combat-system.md（补充元素克制倍率）

**第三步**: 更新systems-index.md的依赖关系

**第四步**: 运行/consistency-check填充entity registry

**第五步**: 重新运行/review-all-gdds验证修复

---

## 六、参考文档

本报告整合了以下来源：
1. 本次跨GDD审查（7个核心系统采样）
2. design/gdd/consistency-check-report.md（33个GDD的详细一致性检查）
3. 游戏设计理论（认知负荷、经济循环、支柱对齐）

---

**报告生成时间**: 2026-04-28  
**下次审查建议**: 在解决阻塞问题并更新GDD后，重新运行完整审查