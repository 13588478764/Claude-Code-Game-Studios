# Game Concept: 打工轮回

*Created: 2026-05-16*
*Status: Draft*

---

## Elevator Pitch

> 一款Roguelike打工模拟器——每局随机一个职业，遭遇荒诞夸张的职场事件，
> 通过二选一的决策管理精力、心情和钱包，燃尽或被炒就重开人生，解锁下一份"工"。
> 打工人的自黑解压神器。

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 模拟经营 + Roguelike + 卡片抉择 |
| **Platform** | 移动端小程序（微信 / 抖音 / 支付宝），多平台同时发布 |
| **Target Audience** | 18-35岁上班族/大学生，碎片化时间用户 |
| **Player Count** | 单人 |
| **Session Length** | 1-3分钟/单局，可连续游玩 |
| **Monetization** | F2P + 激励广告（看广告获得续命/双倍奖励/提前解锁） |
| **Estimated Scope** | Small（MVP 1-2周，完整版8周，solo） |
| **Comparable Titles** | Reigns、中国式家长、打工生活模拟器、王富贵的垃圾站 |

---

## Core Fantasy

"这辈子打了一百份工，每份都是离谱的。"

玩家在一个荒诞夸张的平行世界里体验各种职业的"真实痛点"——但以极度
夸张、黑色幽默的方式呈现。你不是在逃避现实，而是在用笑声消解现实。
每次被炒/燃尽都不是失败，而是解锁了"又一种离谱的打工方式"。

---

## Unique Hook

像Roguelike一样重开人生，但死亡不是被怪物杀死——而是被老板的奇葩要求
逼到燃尽。每个职业都是对现实痛点的荒诞放大镜。

"像Reigns的二选一决策，AND ALSO 每次死亡是一种全新的离谱职业体验。"

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 4 | 荒诞事件文案的冲击感、夸张动画反馈 |
| **Fantasy** (make-believe) | 3 | 扮演各种职业、体验不同人生 |
| **Narrative** (drama) | 5 | 每局自动生成"打工日记"小故事 |
| **Challenge** (mastery) | 6 | 学会平衡资源、撑更多天 |
| **Fellowship** (social) | 7 | 分享搞笑截图给朋友 |
| **Discovery** (exploration) | 2 | 解锁新职业、遇到新的荒诞事件 |
| **Expression** (self-expression) | 1 | 选择自己的应对方式、塑造独特打工人设 |
| **Submission** (relaxation) | 3 | 低门槛、碎片时间、无压力重开 |

### Key Dynamics (Emergent player behaviors)

- 玩家会故意选"最骚"的选项来看会发生什么荒诞结果
- 玩家会截图最离谱的事件分享到社交媒体
- 玩家会重复挑战同一职业试图达成"升职"结局
- 玩家会主动解锁所有职业来"收集"所有荒诞体验

### Core Mechanics (Systems we build)

1. **事件卡系统** — 随机抽取职业相关事件，每张卡提供二选一决策
2. **资源管理** — 精力/心情/钱包三维资源平衡
3. **职业轮回系统** — 每局选择/随机一个职业，失败后解锁新职业
4. **永久进度系统** — 跨局积累社会经验值、解锁被动技能和职业

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 选职业、选应对方式、选发展路线，每个选择影响结局 | Core |
| **Competence** (mastery, skill growth) | 从撑3天到撑满升职，学会每个职业的生存技巧 | Supporting |
| **Relatedness** (connection, belonging) | 事件引发"这不就是我"的共鸣，分享日记创造社交话题 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — 解锁所有职业、收集成就、达成升职结局
- [x] **Explorers** — 发现新事件、新结局、隐藏彩蛋
- [ ] **Socializers** — 仅通过分享功能间接满足
- [ ] **Killers/Competitors** — 不服务此类型

### Flow State Design

- **Onboarding curve**: 第一局强制"实习生"职业，事件简单、选项后果透明，3秒学会操作
- **Difficulty scaling**: 后期职业事件更复杂、资源更紧张、隐藏选项需要经验判断
- **Feedback clarity**: 每次选择立即显示资源变化动画 + 一句吐槽文案
- **Recovery from failure**: 失败即重开，0等待时间，失败本身就是内容（解锁新职业/新成就）

---

## Core Loop

### Moment-to-Moment (30 seconds)

事件卡弹出 → 阅读荒诞描述 → 选择A或B → 看到资源变化 + 搞笑反馈文案。
每个事件2-3秒可完成，快速、轻松、有反馈。核心满足感来自：
1. 文案本身的搞笑
2. 看到自己选择的后果（意料之外又情理之中）
3. 资源条的紧张感（快没了！）

### Short-Term (5-15 minutes)

一个"工作日" = 3-5个事件卡，约1-2分钟。每天结束结算日薪，随机触发
"下班后"事件。一份工作持续5-15个工作日，取决于生存能力。

"再来一天"心理：每天结束可预览明天的第一个事件，制造悬念。

### Session-Level (1-3 minutes per run)

一次完整的"打工生涯"：选职业 → 每天应对事件 → 直到通关(升职)或失败
(被炒/燃尽/暴走)。结算时显示"打工日记"一句话总结 + 获得奖励。

自然停止点：任何一局结束都是完美的停止点。
回来的理由：还有没解锁的职业、没见过的事件、没达成的成就。

### Long-Term Progression

- **职业图鉴**：解锁收集20+职业
- **社会经验值**：跨局积累，解锁永久被动技能（"厚脸皮Lv2"、"摸鱼大师Lv3"）
- **成就系统**：荒诞成就收集（"连续7天摸鱼未被发现"、"被同一个甲方炒3次"）
- **累计存款**：跨局攒钱解锁装饰/皮肤

### Retention Hooks

- **Curiosity**: 还没见过的职业和事件（"医生职业会有什么离谱事件？"）
- **Investment**: 已解锁的职业图鉴和升级的被动技能
- **Social**: 搞笑打工日记分享到朋友圈/抖音引发讨论
- **Mastery**: 挑战更难的职业、尝试达成稀有结局

---

## Game Pillars

### Pillar 1: 三秒上手
任何玩家打开游戏3秒内就知道该怎么玩。

*Design test*: 如果我们纠结于"加教程"还是"不加教程"，这个支柱说——
不需要教程，界面本身就是教程。

### Pillar 2: 一局一笑
每一局至少产生一个让玩家想截图/分享的荒诞瞬间。

*Design test*: 如果我们纠结于"这个事件够不够搞笑"，答案是——
不够搞笑就不要上线。

### Pillar 3: 随开随走
玩家可以在任何时刻放下手机，下次打开无缝继续。

*Design test*: 如果一个机制需要玩家"必须打完这一段"，砍掉它。

### Pillar 4: 永远有新的
职业、事件、结局的扩展不需要改代码结构，数据驱动即可。

*Design test*: 如果加一个新职业需要写新逻辑而不是新数据，说明架构有问题。

### Anti-Pillars (What This Game Is NOT)

- **NOT 深度策略**: 不会有复杂的数值构筑或需要计算器的最优解——会违背"三秒上手"
- **NOT 社交竞争**: 不会有排行榜压力或PVP——打工人已经够累了，违背解压初心
- **NOT 重度剧情**: 不会有需要连续阅读的长篇故事——每个事件独立成立，违背"随开随走"
- **NOT 付费墙**: 所有内容免费可达，广告只加速不阻断——付费墙会劝退碎片时间用户

---

## Visual Identity Anchor

> *Note: 视觉方向待 `/art-bible` 正式确定。以下为初步锚定。*

- **风格方向**: 扁平插画/表情包风，线条简洁，表情夸张
- **视觉规则**: 一切为搞笑服务——角色表情必须过度夸张，场景细节藏梗
- **色彩哲学**: 高饱和度、明快配色，让人在碎片时间里感到轻松而非压抑
- **设计测试**: 如果一个视觉元素不能在1秒内让人看懂或笑出来，重做

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Reigns | 左右滑动二选一机制、资源平衡玩法 | 职业轮回结构，不是管理王国而是管理打工人生 | 验证了极简操作+深度决策在移动端的可行性 |
| 中国式家长 | 中国社会题材自嘲、事件式叙事 | 更碎片化（1-3分钟vs30+分钟）、更荒诞夸张 | 验证了国内自嘲题材的市场规模 |
| 模拟医院 (Two Point Hospital) | 荒诞幽默的经营模拟、夸张的视觉表现 | 极简化为卡片抉择，去掉空间经营 | 验证了荒诞+模拟的搭配能产生持久乐趣 |
| 王富贵的垃圾站 | 小程序平台经营+幽默的成功案例 | 多职业轮回而非单一线性成长 | 验证了小程序生态对此品类的接受度 |

**Non-game inspirations**: 打工人表情包文化、微博/抖音职场吐槽段子、"摸鱼"亚文化

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-35岁 |
| **Gaming experience** | 休闲/轻度，平时玩小程序游戏或手游 |
| **Time availability** | 等公交3分钟、午休10分钟、睡前摸鱼15分钟 |
| **Platform preference** | 手机，微信/抖音小程序 |
| **Current games they play** | 羊了个羊、合成大西瓜、小程序休闲游戏 |
| **What they're looking for** | 不用动脑、随开随玩、能笑一下、有共鸣感 |
| **What would turn them away** | 复杂操作、强制付费、太耗时间、无法碎片化 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | 纯前端框架（Taro 或 uni-app），不需要传统游戏引擎 |
| **Key Technical Challenges** | 多平台小程序适配（微信/抖音/支付宝广告SDK差异）；事件数据驱动架构 |
| **Art Style** | 扁平插画/表情包风，2D |
| **Art Pipeline Complexity** | Low（简洁风格，可快速批量产出） |
| **Audio Needs** | Minimal（轻快BGM + 选择音效 + 结算音效） |
| **Networking** | None（纯本地，存档用平台云存储） |
| **Content Volume** | MVP: 1职业×20事件；完整版: 20+职业×40事件+50通用事件 |
| **Procedural Systems** | 事件随机抽取+权重系统，非完全程序生成 |

### Technology Stack

| Layer | Choice | Reason |
| ---- | ---- | ---- |
| **Framework** | Taro 3.x / uni-app | 一套代码编译微信/抖音/支付宝小程序 |
| **Language** | TypeScript | 类型安全，适合数据驱动架构 |
| **UI** | 组件渲染（非Canvas） | 游戏以文字+UI为主，不需要Canvas性能 |
| **State** | 本地Storage + 平台云存储 | 持久化进度，跨设备同步 |
| **Data** | JSON配置文件 | 职业/事件/结局全部数据驱动 |
| **Ad SDK** | 各平台原生激励广告API | 微信wx.createRewardedVideoAd等 |

---

## Risks and Open Questions

### Design Risks
- 文案不够好笑 → 核心体验崩塌（最大风险）
- 事件重复感太强 → 玩两局就腻
- 资源平衡过于简单 → 没有策略深度

### Technical Risks
- 多平台广告SDK差异导致适配工作量超预期
- 小程序包体限制影响内容量
- 各平台审核标准不一致（讽刺内容可能被限制）

### Market Risks
- "打工"题材已有竞品，差异化不够明显
- 讽刺尺度把握不当可能引发争议
- 小程序游戏获客成本持续上升

### Scope Risks
- 高质量搞笑文案产出速度跟不上消耗
- 多职业扩展的事件设计工作量被低估

### Open Questions
- "二选一 + 3资源条"是否足够有趣？→ MVP原型验证
- 每个职业需要多少事件才能避免重复感？→ 玩测数据
- 哪些职业最有共鸣？→ 社交平台调研/投票
- 讽刺尺度的红线在哪里？→ 各平台审核规则研究

---

## MVP Definition

**Core hypothesis**: "玩家觉得通过二选一决策应对荒诞职场事件、管理资源
撑过工作日这个循环是有趣的，并且会想再来一局。"

**Required for MVP**:
1. 1个完整职业（程序员）—— 20个职业专属事件
2. 3个资源条（精力/心情/钱包）+ 二选一决策
3. 通关（撑到发薪日）+ 失败（燃尽/被炒）两种结局
4. 基础UI（事件卡 + 选项按钮 + 资源条 + 结算页）
5. 本地存档（当前进度持久化）

**Explicitly NOT in MVP**:
- 多职业解锁系统
- 永久升级/被动技能
- 广告变现接入
- 成就系统
- 分享功能
- 多平台适配（先做微信一个平台）

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1职业(程序员)×20事件 | 核心循环+本地存档 | 1-2周 |
| **Alpha** | 3职业×20事件+10通用事件 | 职业解锁+广告接入 | 3-4周 |
| **Beta** | 5职业×30事件+30通用事件 | 成就+分享+永久升级 | 5-6周 |
| **Full Vision** | 8+职业×40事件+50通用事件 | 多平台+全功能+运营工具 | 8周 |

---

## Monetization Design (Rewarded Ads)

| Ad Placement | Trigger | Player Value | Frequency Cap |
| ---- | ---- | ---- | ---- |
| **续命** | 精力归零时 | 回复50%精力再撑一天 | 每局1次 |
| **双倍日薪** | 通关结算时 | 本局收入翻倍 | 每局1次 |
| **提前解锁** | 职业图鉴页 | 提前体验未解锁职业 | 每天3次 |
| **每日buff** | 每日首次进入 | 随机增益（"今天老板心情好"） | 每天1次 |

**原则**: 广告只加速、不阻断。不看广告的玩家只是慢一点，不会被卡住。

---

## Next Steps

- [ ] Run `/setup-engine` to configure tech stack (Taro/uni-app for mini-programs)
- [ ] Run `/art-bible` to create visual identity specification
- [ ] Use `/design-review design/gdd/game-concept.md` to validate concept completeness
- [ ] Decompose into systems with `/map-systems`
- [ ] Author per-system GDDs with `/design-system`
- [ ] Plan technical architecture with `/create-architecture`
- [ ] Record architectural decisions with `/architecture-decision`
- [ ] Validate readiness with `/gate-check`
- [ ] Prototype core mechanic with `/prototype core-loop`
- [ ] Run `/playtest-report` after prototype
- [ ] Plan first sprint with `/sprint-plan new`
