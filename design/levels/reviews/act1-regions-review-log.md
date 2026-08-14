# Act 1 区域 LDD 评审日志

> 评审对象：`design/levels/` 下 Act 1 四区域 LDD（青云镇 / 黑风寨 / 青云山 / 江南水乡）
> 评审流程：`.claude/skills/design-review/SKILL.md`

---

## Review — 2026-07-21 — Verdict: NEEDS REVISION（青云镇/黑风寨）；APPROVED（青云山/江南水乡）

Scope signal: 文档修订 S ｜ LDD 落地实现 XL（12 份新对话 JSON + 场景系统扩展 + 新 NPC 接入）
Specialists: 无（`--depth lean` 单会话评审；`production/review-mode.txt` 为 full，但当前环境无法 spawn 专家 agent 团队，game-designer/systems-designer/qa-lead 视角由主评审覆盖）
Blocking items: 2 | Recommended: 3
Summary: 四份 LDD 结构完整（§1-§11），区域数值与代码 `REGIONS`+`ENEMY_TEMPLATES` 逐项一致。阻断项集中在青云镇 §4 对话绑定的 6 处断裂引用（不存在的节点 ID 与错误文件名），以及黑风寨 §10.1 与 §10.3.2 的自相矛盾文本。
Prior verdict resolved: First review

### 阻断项（Blocking）与修订

| # | 问题 | 修订 |
|---|------|------|
| B1 | 青云镇 §4：`MARKET_WANG_001`/`MARKET_LI_001`/`MEET_YUN_001` 节点不存在；`tiewushuang_brotherhood.json`/`murongxue_past_life.json`/`liuruyan_righteous_path.json` 文件名错误 | ✅ 已修正为实际文件：`act1_event1_opening.json`（内嵌）、`act1_event2_cultivation.json`（初见）、`npc_*.json`（日常）；`MEET_TIE_001`/`VICTORY_001` 经验证保留 |
| B2 | 黑风寨 §10.1 残留"点位待补"旧文本，与 §10.3.2"已补齐"矛盾 | ✅ 已统一为"已补齐（2026-07-21）" |

### 建议项（Recommended）与修订

| # | 问题 | 修订 |
|---|------|------|
| R1 | 青云山 §5 灵草奇遇"可选"表述含糊 | ✅ 明确实装：07 灵草发现 8% 低配版入池，27 灵草园排除 |
| R2 | 青云镇 §5 奇遇 06"最低境界"列填"事件五后"，列语义混用 | ✅ 境界列改为"炼气"，"事件五后解锁"移入备注 |
| R3 | 黑风寨 §10.4"Boss 预警标识"UI 形式未定义 | ✅ 明确为场景名旁红色「⚠ Boss」角标，复用现有 Label 样式 |

### 附带发现（数据侧 bug）

1. **`npc_tiewushuang.json` 身份错误**：元数据为"铸剑大师/铁匠铺/打造兵器"，与剧本权威严重矛盾（Act 1 `MEET_TIE_001`"我是丐帮铁无双"、Act 2 降龙掌体修），疑与王铁匠角色混淆——✅ **已修复（2026-07-21）**：身份/位置/对话文本改为丐帮弟子（丐帮分舵、降龙掌、酒），`npcs.json` title/sect 同步；对话+关系测试 25/25 通过
2. **`npc_liuruyan.json` 门派错误**："翠微宫弟子"，叙事三处权威来源（Act 2"天剑盟少主"、Act 3"天剑盟愿为联盟效力"、character-quests"奉天剑盟之命"）均为天剑盟——✅ **已修复（2026-07-21）**：门派/对话文本改为天剑盟剑修（"剑为苍生而出"守护理念），`npcs.json` title"天剑盟少主"/sect 同步；测试同上
3. **`npc_yunzhonghe.json` location"青云门"**：非九州设定门派名，疑早期残留（轻微，未处理——待叙事侧确认云中鹤门派归属后统一清理）

### 修订后结论

**全部四份 LDD：APPROVED（2026-07-21 修订后）**
