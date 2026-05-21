# S1-11: 富文本事件内容（联调 + 内容基线）

> **Sprint**: 1 | **Priority**: Nice to Have（升级版） | **Owner**: systems-designer | **Estimate**: 0.5 → 1.5 day
> **Status**: backlog

## Goal

为联调撰写**真正的事件内容基线**：30+ 通用事件（适用全职业）+ 80+ 程序员专属事件，覆盖 2026 当下职场热点和痛点。原计划"10 个占位事件"升级为"内容基线"，给 Sprint 2 真正可玩的素材，且为后续 systems-designer 的批量产出建立模板。

## GDD Requirements Addressed

- event-data-engine GDD: 配置文件结构与 schema
- ADR-002: common 在主包，job 专属在分包
- 内容方向参考 game-concept 的"一局一笑"支柱

## Technical Approach

### 文件

- `src/static/events/common-events.json` — 30+ 通用事件（厕所/午饭/通勤/同事八卦等任意职业都能遇到）
- `src/subpackages/events/programmer-events.json` — 80+ 程序员专属事件

### Schema 示例

```json
{
  "id": "prog-001-pm-bug",
  "text": "下午3点你发现昨晚上线的代码有个bug。用户已经在群里@你了。",
  "tags": ["bug", "urgent"],
  "weight": 1.0,
  "choiceA": {
    "text": "先修bug再说",
    "icon": "🔧",
    "effects": [
      { "target": "energy", "value": -20 },
      { "target": "money", "value": 5 }
    ]
  },
  "choiceB": {
    "text": "先去接杯咖啡冷静一下",
    "icon": "☕",
    "effects": [
      { "target": "energy", "value": 5 },
      { "target": "mood", "value": -15 }
    ]
  }
}
```

### 内容方向（2026 当下热点）

**程序员痛点**：
- AI 抢饭碗（GPT/Claude/Cursor 写代码）
- 35 岁危机
- HC 冻结、降本增效
- 大厂裁员潮
- 居家办公被叫回
- 调休奇葩日历
- 双休变单休
- 副业焦虑（接私活）
- 末位淘汰、PIP
- 内卷绩效（OKR 翻倍）
- 周报/日报内卷
- 代码合规审查
- 信创/国产替代
- 被反诈/微信加客户
- 跳槽降薪
- 飞书钉钉报表

**通用痛点**：
- 食堂排队
- 厕所抢位
- 团建逃避
- 通勤地狱
- 同事八卦
- 老板情商低
- HR 突然找你
- 公司 KPI 大会
- 年终奖缩水
- 五险一金降基数

## Acceptance Criteria

- [ ] common-events.json 至少 30 张事件
- [ ] programmer-events.json 至少 80 张事件
- [ ] 至少 10 张含 followUp 链
- [ ] 至少 8 张含 buff/debuff 应用
- [ ] 至少 6 张含 risk 概率分支
- [ ] 全部通过 schema 校验
- [ ] 没有重复 ID
- [ ] 文案符合"中年职场人能笑出来"的判断标准

## Test Evidence

- **Type**: Config/Data
- **Path**: smoke check 中验证 schema 解析全部通过

## Dependencies

- 前置：S1-4（schema 定义）
- 阻塞：Sprint 2 事件卡系统联调
