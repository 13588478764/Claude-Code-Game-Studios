# 平衡数据审查报告

**日期**: 2026-05-15
**审查范围**: items.json, npcs.json, combat_manager.gd, character_system.gd, relationship_data.gd

---

## 1. 物品数据 (src/data/items.json)

| 指标 | 值 |
|------|-----|
| 总物品数 | 69 |
| 类型分布 | weapon(4), armor(4), accessory(4), consumable(18), material(21), quest(9), gift(9) |

### 价格分布（字段: `value_gold`）

| 类型 | 数量 | 有价格 | 价格范围(银两) |
|------|------|--------|---------------|
| weapon | 4 | 4 | 50-5000 |
| armor | 4 | 4 | 30-4000 |
| accessory | 4 | 4 | 20-3000 |
| consumable | 18 | 18 | 15-1000 |
| material | 21 | 21 | 5-500 |
| gift | 9 | 9 | 5-500 |
| quest | 9 | 4 | 0-80 |

**状态**: OK — 64/69个物品有合理价格。5个quest物品价格为0（任务道具不可交易，符合设计）。价格按稀有度递增，经济系统可正常运作。

---

## 2. NPC数据 (src/data/npcs.json)

| NPC | 立场 | 恋爱候选 | 喜好配置 |
|-----|------|----------|----------|
| 云中鹤 | righteous | 否 | loves:2, likes:3, dislikes:1 |
| 柳如烟 | righteous | 是 | loves:2, likes:3, dislikes:2 |
| 玄机真人 | righteous | 否 | loves:2, likes:2, dislikes:2 |
| 萧寒夜 | evil | 否 | loves:2, likes:2, dislikes:2 |
| 血无痕 | evil | 否 | loves:2, likes:1, dislikes:3 |
| 慕容雪 | neutral | 是 | loves:2, likes:3, dislikes:1 |

**状态**: OK — 6个NPC配置完整，礼物偏好分布合理。2个恋爱候选（柳如烟+慕容雪）符合设计。

---

## 3. 战斗公式 (src/scripts/combat/combat_manager.gd)

| 公式 | 定义 |
|------|------|
| 基础伤害 | `max(1, attack_attr - defend_attr / 3) + randi_range(0, damage_random_range)` |
| 架势减伤 | `stance / max_stance * 0.3` (最高30%减伤) |
| 连招加成 | `1.0 + (combo_value / max_combo * max_combo_bonus)` |
| 技能伤害 | `max(1, power + attack_attr - defend_attr / 3)` |
| 最终伤害 | `max(1, int(damage))` (保底1点) |

**状态**: OK — 伤害保底1点防止0伤害；防御按1/3比例减免合理；架势系统最高30%减伤不会过强。

**注意**: `damage_random_range` 的值未在grep中找到明确定义，需确认是否为数据驱动。

---

## 4. 角色成长 (src/scripts/character/character_system.gd)

| 参数 | 值 |
|------|-----|
| 等级上限 | 99 |
| 经验基础值 | 100 |
| 经验指数 | 1.5 |
| 境界加成 | [1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0] |
| 初始属性点 | 5 |
| 初始天赋点 | 1 |

**经验曲线示例**:
- Lv2: 100 * 2^1.5 * 1.0 = 283 exp
- Lv10: 100 * 10^1.5 * 1.0 = 3162 exp
- Lv30: 100 * 30^1.5 * 1.5 = 24,657 exp (筑基期)
- Lv50: 100 * 50^1.5 * 2.5 = 88,388 exp (金丹期)
- Lv99: 100 * 99^1.5 * 5.0 = 492,555 exp (渡劫期)

**状态**: OK — 曲线合理，后期境界加成使升级逐渐变慢，符合修真设定。

---

## 5. 关系系统 (src/scripts/relationship/relationship_data.gd)

| 参数 | 值 |
|------|-----|
| 关系值范围 | [-100, 100] |
| 道心值范围 | [-100, 100] |
| 仇敌阈值 | ≤ -50 |
| 冷淡阈值 | ≤ -10 |
| 友好阈值 | ≥ 10 |
| 亲密阈值 | ≥ 50 |
| 挚友/恋人 | ≥ 80 |
| 魔道宗师 | ≤ -60 |
| 正道宗师 | ≥ 60 |

**状态**: OK — 阈值分布合理，正负对称。道心系统与关系系统独立运作。

---

## 总结

| 系统 | 状态 | 问题 |
|------|------|------|
| 物品数据 | OK | 64/69有价格，5个quest物品免费（合理） |
| NPC数据 | OK | 配置完整 |
| 战斗公式 | OK | 公式合理，保底防护到位 |
| 角色成长 | OK | 经验曲线平滑 |
| 关系系统 | OK | 阈值对称合理 |

**阻塞项**: 无。所有系统数据在合理范围内。
