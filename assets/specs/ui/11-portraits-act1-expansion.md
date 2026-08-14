# 11 — Act 1 区域扩展资产生成任务单

> 面向**商业 AI 图像工具**（Midjourney / 即梦 / 通义万相 / SD 云端等）的生成任务单。
> 覆盖 Act 1 四区域 LDD 落地所需的全部新增资产：**10 张 NPC 立绘 + 12 张敌人立绘 + 2 张补丁资产 + 20 张 VFX 特效纹理 + 6 张过场插图**。
> 提示词为中文工具无关描述；若工具对英文响应更佳，可直接机翻（风格关键词保留）。

**需求来源**: [design/levels/](../../../design/levels/) 四份 Act 1 LDD（§4 NPC 配置 / §6 敌人配置）
**风格基准**: [06-portraits-protagonist-allies.md](06-portraits-protagonist-allies.md) / [07-portraits-enemies.md](07-portraits-enemies.md) / [08-backgrounds.md](08-backgrounds.md)
**风格参考图（建议随提示词一并喂给工具）**:
- NPC 立绘风格：`assets/ui/portraits/portrait_wang_tiejiang.png`、`portrait_li_popo.png`
- 敌人立绘风格：`assets/ui/enemy_portraits/enemy_bandit_minion.png`

---

## 通用规格

| 项 | 值 |
|---|----|
| **立绘母版** | 1024×1024px，PNG-32，**透明背景**（工具不支持透明底则用纯黑/纯白底，后续抠图） |
| **立绘游戏图** | 512×512px，PNG-32，透明背景（由母版缩放，见文末「生成后处理」） |
| **背景** | 1920×1080px (16:9)，PNG/JPG，不透明 |
| **VFX 纹理** | 1024×1024px，PNG-32，透明背景（发光体置于纯黑底上，黑底后续抠除） |
| **过场插图** | 1920×1080px (16:9) 全屏，PNG/JPG，**不透明**（与背景同规格；工具只能出方图时用 16:9 最大尺寸，后处理放大） |
| **画风** | 中国仙侠工笔重彩 + 水墨晕染（半写实，忌日漫萌系/Q 版） |

## 放置路径速查表

| 类别 | 母版放置（1024） | 游戏图放置（512/1920） | 命名 |
|------|----------------|----------------------|------|
| NPC 立绘 | `assets/ui/_masters/npc_secondary_1024/` | `assets/ui/portraits/` | `portrait_[拼音].png` |
| 敌人立绘 | `assets/ui/_masters/portraits_enemies_1024/` | `assets/ui/enemy_portraits/` | `enemy_[英文名].png` |
| 血无恨（核心角色） | `assets/ui/_masters/portraits_allies_1024/` | `assets/ui/portraits/` | `portrait_xuewuhen.png` |
| 室内背景 | `assets/ui/_masters/backgrounds_1024/` | `assets/ui/backgrounds/` | `bg_player_home.png` |
| VFX 纹理 | `assets/ui/_masters/vfx_1024/`（新建） | `assets/ui/vfx/` | `vfx_[名称].png` |
| 过场插图 | `assets/ui/_masters/cutscene_frames_1024/`（新建） | `assets/ui/cutscene_frames/`（新建，1920×1080） | `cutscene_[名称].png` |

## 通用负面提示词（所有条目默认排除）

```
现代元素, 现代服装, 西方魔幻, 精灵, 矮人, 兽人, 科幻, 机甲, 枪械,
卡通低龄, Q版萌系, 日漫风, 美式漫画, 文字, 水印, 签名, logo,
低分辨率, 模糊, 失真, 多余手指, 比例错误, 解剖错误, 重复脸部,
背景色块, 水墨晕染背景, 山水画背景, 场景, 建筑物, 地面
```

## 立绘提示词通用结构

```
中国仙侠工笔重彩[人物/敌人/妖兽]立绘，[身份/年龄/性别]，[发型/服装/配饰]，
[体态姿势]，[五官/表情]，[手持物品]，需要时角色周身附带[煞气/祥云等氛围元素]。
水墨修真风格，工笔细腻，全身像居中，无背景（透明背景）。
```

## 背景规则（务必遵守）

立绘是叠加在场景背景/对话框之上的 sprite，**只画角色本体，禁止任何绘制背景**：

- ❌ 禁止出现"背景留白淡墨晕染 / 墨色烟雾 / 山林淡影"等措辞——AI 会据此画出无法抠除的色块，破坏透明底
- ✅ 结尾统一写"无背景（透明背景）"
- ✅ 工具不支持输出透明底时（如 Midjourney），改写"纯黑背景 solid black background"，后期抠图/去黑
- ✅ Boss 的煞气、灵兽的祥云等氛围元素可保留，但措辞必须是"**身周环绕 / 脚下踏着**"（附着于角色本体，抠图时可随角色保留），不得写"背景 XX"
- 场景氛围由场景背景层（如 `bg_town_street`）提供，不属于立绘职责

---
---

# Part A — 次要 NPC 立绘（10 张，P0）

> 均为单张默认表情（次要 NPC 不做表情变体，同第五批 13 张惯例）。
> 出处为各区域 LDD §4 NPC 配置表。

## A1. 守门弟子·陆平 (luping)

- **文件名**: `portrait_luping.png`
- **出处**: 青云山 LDD——玄霜宗外门守门弟子，恪尽职守

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，年轻男修士，约 18 岁，黑色短发束小髻以木簪固定，身着藏青色道袍外门弟子装束，袖口束紧干净利落，腰挂宗门令牌，手持一杆长枪立于身侧，五官端正略带青涩，神情认真负责，站姿笔直。水墨修真风格，无背景（透明背景）。

**关键词**: 藏青道袍, 长枪, 宗门令牌, 青涩认真

## A2. 传功长老·玄诚子 (xuanchengzi)

- **文件名**: `portrait_xuanchengzi.png`
- **出处**: 青云山 LDD——玄霜宗外门传功长老，三问三答考核主角

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，年长男修士，约 65 岁，白发束道髻以青玉簪固定，长眉垂颊，三缕长须，身着藏青色镶银边长老道袍，内衬雪白中衣，手持一卷竹简经书，五官清癯威严，眼含睿智精光，神情庄重中透慈祥，仙风道骨。水墨修真风格，无背景（透明背景）。

**关键词**: 白发道髻, 银边长老袍, 竹简, 威严慈祥

## A3. 切磋弟子·顾飞 (gufei)

- **文件名**: `portrait_gufei.png`
- **出处**: 青云山 LDD——好武爽朗的外门师兄，可与主角切磋

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，青年男修士，约 22 岁，黑色高马尾，身着藏青色短打武袍，袖口挽起露出小臂，腰束布带挂剑鞘，右手持长剑平伸作邀战姿态，剑眉星目，笑容爽朗好胜，浑身透着跃跃欲试的英气。水墨修真风格，无背景（透明背景）。

**关键词**: 高马尾, 短打武袍, 邀战姿态, 爽朗好胜

## A4. 扫地道人 (saodidaoren)

- **文件名**: `portrait_saodidaoren.png`
- **出处**: 青云山 LDD——扫地老道人，实为退隐长老（隐世高人）

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，年迈老道人，约 70 岁，花白头发随意挽起，几缕散发垂落，身着洗得发白的灰色粗布道袍打着补丁，脚蹬草鞋，微驼着背，双手持一把竹枝扫帚，眯着眼面容平凡祥和，但微睁的眼缝深处隐有精光闪过，大巧若拙。水墨修真风格，无背景（透明背景）。

**关键词**: 补丁灰袍, 竹扫帚, 驼背眯眼, 深藏不露

## A5. 船家·老周 (laozhou)

- **文件名**: `portrait_laozhou.png`
- **出处**: 水乡 LDD——码头摆渡老船夫

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，老年船夫，约 55 岁，皮肤黝黑满脸风吹日晒的深刻皱纹，花白短须，头戴旧斗笠，身着粗布短褐与草鞋，肩搭一条汗巾，手持一根长竹篙，笑容憨厚朴实，露出缺了一颗的门牙，江南水乡烟火气。水墨修真风格，无背景（透明背景）。

**关键词**: 斗笠, 竹篙, 黝黑皱纹, 憨厚船夫

## A6. 商会掌柜·金万贯 (jinwanguan)

- **文件名**: `portrait_jinwanguan.png`
- **出处**: 水乡 LDD——市侩精明的商会掌柜

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，中年富商，约 45 岁，富态圆脸双下巴，细眼含笑透着精明，头戴锦缎员外巾，身着绛紫色织金绸衫，腰束玉带挂玉佩与钱袋，右手大拇指一枚翠绿玉扳指，左手托着一把金算盘，一团和气中满是算计。水墨修真风格，无背景（透明背景）。

**关键词**: 富态, 织金绸衫, 金算盘, 玉扳指, 精明市侩

## A7. 神秘商人 (mystery_merchant)

- **文件名**: `portrait_mystery_merchant.png`
- **出处**: 水乡 LDD + 全区域奇遇 10「神秘商人」——行踪诡秘的游商

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，行踪诡秘的游商，全身罩在深棕色连帽斗篷中，宽大斗笠压得很低只露出尖削下巴与一抹神秘微笑，背负一个捆满包裹的巨大货架背篓，篓口露出卷轴、瓷瓶与奇异兽角，一只枯瘦的手伸出斗篷，指间挂着一串泛着微光的五彩珠串，气息莫测。水墨修真风格，无背景（透明背景）。

**关键词**: 连帽斗篷, 斗笠遮面, 货架背篓, 五彩珠串, 神秘

## A8. 唐门弟子·唐小七 (tangxiaoqi)

- **文件名**: `portrait_tangxiaoqi.png`
- **出处**: 水乡 LDD——唐门外围弟子，唐门分号机关铺伙计

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，机灵少年，约 16 岁，黑发扎小辫，身着靛蓝色唐门劲装，袖口与领口有暗紫色滚边，腰间皮带上挂满机关零件、小铜锤与一只袖珍连弩，手中逗弄着一只木制机关小鸟，歪着头笑得俏皮，眼睛滴溜溜透着聪明劲儿。水墨修真风格，无背景（透明背景）。

**关键词**: 靛蓝劲装, 机关零件, 机关小鸟, 机灵俏皮

## A9. 说书人·百晓生 (baixiaosheng)

- **文件名**: `portrait_baixiaosheng.png`
- **出处**: 水乡 LDD——消息灵通的说书人（暗示天机阁外围）

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，中年文士，约 40 岁，三缕山羊胡，头戴青色方巾，身着半旧青衫，左手持一柄折扇半开，右手持一块醒木，眉梢带笑眼神精明，仿佛知晓天下秘闻却只说三分，茶楼说书人气度。水墨修真风格，无背景（透明背景）。

**关键词**: 山羊胡, 青衫折扇, 醒木, 精明含笑

## A10. 丐帮卧底·孙二狗 (sunergou)

- **文件名**: `portrait_sunergou.png`
- **出处**: 黑风寨 LDD——丐帮卧底，混迹匪寨（主角内应）

**生成提示词**:
> 中国仙侠工笔重彩人物立绘，青年男子，约 25 岁，蓬乱油腻的短发，脸上沾着灰，身着打满补丁的破烂短打，外罩一件不合身的赃旧皮褂，肩上扛着一只鼓鼓囊囊的布袋，缩肩弓背一副小喽啰相，但滴溜溜的眼睛里透着机灵劲儿，咧嘴一笑带着痞气。水墨修真风格，无背景（透明背景）。

**关键词**: 蓬乱短发, 破烂短打, 布袋, 痞气机灵

---
---

# Part B — 区域敌人立绘（12 张，P0）

> 出处为各区域 LDD §6 敌人配置表。视觉基调与同区已有敌人统一（如山贼系沿用褐色皮甲头巾）。

## B1. 野狼 (wild_wolf)

- **文件名**: `enemy_wild_wolf.png`
- **出处**: 青云镇 LDD（区别于灵兽火狼：普通野兽，无火焰元素）

**生成提示词**:
> 中国仙侠工笔重彩野兽立绘，一头灰色野狼，瘦削精悍，灰黑相间的粗硬毛皮，眼瞳幽黄泛着饥光，獠牙外露涎水滴落，低伏前身呈扑击姿态。水墨修真风格，无背景（透明背景）。

**关键词**: 灰狼, 幽黄眼, 低伏扑击, 普通野兽

## B2. 山中野人 (mountain_wildman)

- **文件名**: `enemy_mountain_wildman.png`
- **出处**: 青云镇 LDD

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，魁梧山中野人，约 2 米高，乱发虬髯纠结如枯草，以兽皮胡乱裹身，皮肤黝黑布满尘垢与旧疤，手持一根粗大的狼牙木棒，双眼赤红神情狂乱，张口咆哮。水墨修真风格，无背景（透明背景）。

**关键词**: 兽皮, 狼牙木棒, 乱发虬髯, 狂乱

## B3. 流浪修士 (rogue_cultivator)

- **文件名**: `enemy_rogue_cultivator.png`
- **出处**: 青云镇 LDD——拦路打劫的落魄散修

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，落魄散修，约 40 岁，头发散乱以草绳束起，面色蜡黄眼窝深陷，身着打满补丁的破旧道袍，腰挂裂纹的劣质玉符，手持一柄锈迹斑斑的铁剑斜指前方，眼神狠厉中透着贪婪。水墨修真风格，无背景（透明背景）。

**关键词**: 破旧道袍, 锈剑, 狠厉贪婪, 落魄散修

## B4. 匪寨弓手 (bandit_archer)

- **文件名**: `enemy_bandit_archer.png`
- **出处**: 黑风寨 LDD（与山贼喽啰同族视觉）

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，山贼弓手，约 30 岁，黑布头巾包头，身着褐色破皮甲配深色粗布裤，背负箭壶插满雕翎箭，双手持一张猎弓拉弦满月起势，眯着一只眼睛瞄准，神情凶悍专注。水墨修真风格，无背景（透明背景）。

**关键词**: 头巾皮甲, 猎弓满月, 箭壶, 凶悍瞄准

## B5. 匪寨刺客 (bandit_assassin)

- **文件名**: `enemy_bandit_assassin.png`
- **出处**: 黑风寨 LDD——精英，偷袭脆皮

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，蒙面刺客，黑布蒙面只露出一双阴冷的眼睛，身着贴身黑色夜行衣，身形精瘦矫健，反手持一柄泛着幽绿毒光的匕首横于身前，身体微弓如蓄势的猎豹。水墨修真风格，无背景（透明背景）。

**关键词**: 黑布蒙面, 夜行衣, 淬毒匕首, 阴冷

## B6. 黑风寨头目 (bandit_leader) — **Boss**

- **文件名**: `enemy_bandit_leader.png`
- **出处**: 黑风寨 LDD——区域 Boss（自愈+激怒）

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，匪寨头目，壮硕巨汉约 40 岁，满脸横肉，一道刀疤从左额斜贯至右颌，赤裸的上身肌肉虬结布满旧伤，肩披一张完整虎皮，腰挂骷髅串饰，双手将一柄鬼头大刀扛在肩上，仰天狂笑凶威滔天，身周环绕金红色煞气烟雾（Boss 标识，烟雾附着角色本体，抠图时保留）。水墨修真风格，无背景（透明背景）。

**关键词**: 虎皮披肩, 鬼头大刀, 刀疤, 狂笑, Boss 金红烟雾

## B7. 水贼 (water_bandit)

- **文件名**: `enemy_water_bandit.png`
- **出处**: 水乡 LDD

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，水乡水贼，约 30 岁，头扎湿漉漉的青布巾，皮肤黝黑泛着水光，身着紧身短打水靠，手持一对分水峨嵋刺，脚下踏着墨色水花纹（附着角色本体），咧嘴狞笑露出一口黄牙，水性十足的悍匪气质。水墨修真风格，无背景（透明背景）。

**关键词**: 青布头巾, 水靠, 分水刺, 水花纹

## B8. 江湖浪人 (wandering_swordsman)

- **文件名**: `enemy_wandering_swordsman.png`
- **出处**: 水乡 LDD——拦路挑战的流浪武人

**生成提示词**:
> 中国仙侠工笔重彩敌人立绘，落魄江湖浪人，约 35 岁，斗笠压得很低遮住眉眼，满脸风霜胡茬，身披破旧的灰色斗篷，内衬褪色武袍，手持一柄无鞘旧刀刀尖垂地，站姿松散却隐含锋芒，神情桀骜疲惫。水墨修真风格，无背景（透明背景）。

**关键词**: 斗笠压眉, 破斗篷, 无鞘旧刀, 桀骜风霜

## B9. 河妖 (river_demon)

- **文件名**: `enemy_river_demon.png`
- **出处**: 水乡 LDD——毒系水系妖怪

**生成提示词**:
> 中国仙侠工笔重彩妖怪立绘，半人半鱼的河妖，青绿色鳞皮湿滑，背脊生有鳍状骨刺，指间有蹼，指甲乌黑发亮，眼瞳幽绿竖瞳，手持一柄珊瑚骨叉，周身环绕青黑色水汽毒雾（附着角色本体）。水墨修真风格，保持东方水怪韵味，无背景（透明背景）。

**关键词**: 青绿鳞皮, 鳍刺蹼爪, 珊瑚骨叉, 毒雾水怪

## B10. 妖兽 (demon_beast)

- **文件名**: `enemy_demon_beast.png`
- **出处**: 青云山 LDD——后山妖化的野兽（区别于普通野狼）

**生成提示词**:
> 中国仙侠工笔重彩妖兽立绘，一头狼形妖兽，体型远大于普通野狼，黑毛根根竖立如钢针，背脊生出一排灰白骨刺，眼瞳赤红如血，口中獠牙交错滴着黑色涎液，四爪缠绕淡淡的黑色妖气，呈低吼扑击姿态。水墨修真风格，无背景（透明背景）。

**关键词**: 黑毛狼形, 背脊骨刺, 赤红眼, 黑色妖气

## B11. 山精 (mountain_spirit)

- **文件名**: `enemy_mountain_spirit.png`
- **出处**: 青云山 LDD——自愈型山岭精怪（区别于山妖：矮小灵秀）

**生成提示词**:
> 中国仙侠工笔重彩精怪立绘，山岭石精，矮小身形约 1 米高，身体由灰褐色山石堆叠而成，缝隙间长满青苔与小蕨，五官似眯眼微笑的老翁由岩石纹理天然构成，双手捧着一颗泛着翠绿微光的石珠（治愈灵气），头顶一株小树苗，憨拙中透着灵性。水墨修真风格，无背景（透明背景）。

**关键词**: 石堆小身, 青苔蕨叶, 翠绿石珠, 憨拙灵性

## B12. 护山灵兽 (mountain_guardian) — **Boss**

- **文件名**: `enemy_mountain_guardian.png`
- **出处**: 青云山 LDD——玄霜宗护山灵兽（威严正派，非邪恶）

**生成提示词**:
> 中国仙侠工笔重彩灵兽立绘，一头麒麟状护山灵兽，通体青白色长毛如流云披拂，头生一只温润白玉独角，金色眼瞳威严而悲悯，四蹄踏着淡青色祥云，鬃毛无风自动，体型雄壮气势磅礴，昂首俯视姿态威压如山，神圣不可侵犯。水墨修真风格，无背景（透明背景）。

**关键词**: 麒麟, 青白长毛, 白玉独角, 祥云, 威严正派

---
---

# Part C — 补丁资产（2 张，P1/P2）

## C1. 血无恨默认立绘 (xuewuhen) — P1

- **文件名**: `portrait_xuewuhen.png`
- **问题**: 现有 `portrait_xuewuhen_angry.png` / `portrait_xuewuhen_happy.png`，**缺默认表情**
- **放置**: 母版 → `assets/ui/_masters/portraits_allies_1024/`；游戏图 → `assets/ui/portraits/`

**生成方式（角色一致性关键）**:
> 必须使用**角色参考功能**（Midjourney `--cref` / 即梦参考图 / SD IP-Adapter），以 `assets/ui/portraits/portrait_xuewuhen_angry.png` 为角色参考图，权重调高（如 `--cw 100`），仅将表情改为平静中性。

**生成提示词**:
> 中国仙侠工笔重彩人物立绘（与参考图为同一角色），神情平静中性，双唇轻闭，目光沉静直视前方，姿态放松自然站立，服装发型配饰与参考图完全一致。水墨修真风格。透明背景。

## C2. 玩家家室内背景 (player_home) — P2

- **文件名**: `bg_player_home.png`
- **出处**: 青云镇 LDD §11 已决策——玩家家为独立背景
- **放置**: 母版 → `assets/ui/_masters/backgrounds_1024/`；游戏图 → `assets/ui/backgrounds/`（1920×1080）

**生成提示词**:
> 宋代山水画风格的全屏室内场景，修真者的简朴家居：画面左侧一张木床铺着素色被褥，中央一张旧木桌，桌上有点燃的烛台与几卷书册，右侧墙上挂着一柄带鞘长剑，窗棂透入清晨微光，墙角一只小药炉冒着轻烟。色调米白暖黄，朴素温馨，左侧与中央大面积留白以容纳 UI。水墨工笔，古韵静谧。

**关键词**: 简朴木床, 烛台书卷, 墙上挂剑, 窗棂晨光

---
---

# Part D — VFX 战斗特效纹理（20 张，P1）

> **形态**：静态单帧 PNG（**非序列帧/动画**）。进游戏后由 `CombatVFXManager` 用代码驱动作画：武器层 `TextureRect`+Tween 飞行缩放淡出、元素层 `GPUParticles2D` 把纹理当粒子贴图爆发、受击层粒子爆裂+全屏元素色闪光。
> **染色机制**：武器纹理运行时会被 `modulate` 染成当前元素色（剑气+火元素=橙红剑气）——**武器 4 张必须是白色/浅色系**，染色后才正；元素 12 张保持各自本色即可。

## 统一规格

| 项 | 规格 |
|----|------|
| 生成尺寸 | ≥1024×1024（母版 1024；游戏图 256，代码中最大显示 180px） |
| 底色 | **推荐纯黑底**（提示词已写 `solid black background`）：发光特效黑底质量最高，交付后脚本"去黑转透明"（亮度即透明度，几乎无损）。⚠️ 当前代码为普通 alpha 混合，**黑底必须去黑**，否则显示黑方块；若工具支持直接出透明底 PNG 则免此步 |
| 你交付的位置 | 原图放入 **`assets/ui/_masters/vfx_1024/`**（新建目录），文件名严格按下表 |
| 后续处理 | 交付后告知，脚本批量：备份 → 去黑/trim → 1024 母版 → **256 游戏图按子目录分发** |
| 游戏图目录 | `assets/ui/vfx/weapon/`（4 张）、`assets/ui/vfx/element/`（12 张）、`assets/ui/vfx/common/`（4 张）——**三个子目录为代码硬编码路径**（combat_vfx_manager.gd），不可改动 |

## D1-D4 武器类（→ `vfx/weapon/`）

> 会被 `modulate` 染色，务必白/浅色系（D3 青色较浅可接受，追求通用可把 `cyan` 改 `white`）。

### D1. 剑气斩痕 `vfx_slash_arc.png`
- **代码引用**：Sword / Blade 武器
- **内容**：白色月牙剑气斩痕

**生成提示词**:
> single game visual effect texture, white crescent sword slash arc trail, sharp curved blade energy, luminous white-blue sweep motion, horizontal slash mark, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D2. 拳劲冲击波 `vfx_fist_wave.png`
- **代码引用**：Fist 武器
- **内容**：金色拳劲冲击波环

**生成提示词**:
> single game visual effect texture, circular shockwave fist impact ring, expanding concentric force waves, golden-white energy burst, martial arts qi punch explosion, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D3. 螺旋掌风 `vfx_palm_wind.png`
- **代码引用**：None / 空武器（默认拳脚）
- **内容**：青色螺旋掌风

**生成提示词**:
> single game visual effect texture, spiraling wind palm energy vortex, swirling cyan qi force, ethereal palm strike wind gust, flowing energy streams, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D4. 棍击碎石 `vfx_staff_impact.png`
- **代码引用**：Staff 武器
- **内容**：棍棒砸地碎石冲击

**生成提示词**:
> single game visual effect texture, ground impact shockwave from staff strike, radial crack pattern, upward debris and dust explosion, brown-golden earth force, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

## D5-D16 元素类（→ `vfx/element/`）

> 保持本色（modulate 为同色系元素色，不改变色相）。元素→文件名为代码 `_element_to_filename()` 硬编码映射。

### D5. 火焰爆发 `vfx_fire_burst.png`（火）

**生成提示词**:
> single game visual effect texture, fierce fire explosion burst, orange-red flames erupting outward, intense heat glow, martial arts fire technique, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D6. 冰晶冻结 `vfx_ice_crystal.png`（冰）

**生成提示词**:
> single game visual effect texture, shattering ice crystal formation, blue-white frozen shards exploding, frost mist particles, freezing cold energy, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D7. 闪电劈落 `vfx_lightning_bolt.png`（雷）

**生成提示词**:
> single game visual effect texture, crackling lightning bolt strike, branching purple-white electric arcs, thunder energy discharge, electrifying sparks, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D8. 毒雾弥漫 `vfx_poison_cloud.png`（毒）

**生成提示词**:
> single game visual effect texture, toxic poison cloud spreading, sickly green miasma with bubbles, venomous gas particles, dark green toxic mist, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D9. 金属锐光 `vfx_metal_glint.png`（金）

**生成提示词**:
> single game visual effect texture, sharp metallic golden sword qi blade, gleaming gold metal energy lines, shining golden light rays, metal element cultivation power, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D10. 黑暗漩涡 `vfx_dark_vortex.png`（暗）

**生成提示词**:
> single game visual effect texture, dark purple shadow vortex swirl, sinister demonic energy spiral, dark cultivation technique, black-purple malevolent force, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

> ⚠️ 黑紫色调在黑底上对比度低：去黑时暗紫边缘会被吃掉（视觉反而更干净），介意的话此张可直接出透明底。

### D11. 光芒爆发 `vfx_light_burst.png`（光）

**生成提示词**:
> single game visual effect texture, radiant holy light burst, white-golden divine rays expanding outward, buddhist cultivation golden light, sacred illumination, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D12. 水花溅射 `vfx_water_splash.png`（水）

**生成提示词**:
> single game visual effect texture, water splash wave impact, blue water droplets and spray, flowing aqua energy streams, water element cultivation, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D13. 藤蔓荆棘 `vfx_wood_thorns.png`（木）

**生成提示词**:
> single game visual effect texture, green vine thorns erupting from ground, living wood tendrils, nature energy growth burst, wood element cultivation, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D14. 大地龟裂 `vfx_earth_crack.png`（土）

**生成提示词**:
> single game visual effect texture, earth crack ground rupture, brown rocky fragments flying upward, stone debris explosion, earth element cultivation power, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D15. 旋风螺旋 `vfx_wind_spiral.png`（风）

**生成提示词**:
> single game visual effect texture, swirling wind tornado spiral, cyan-white air current vortex, graceful wind blades cutting, wind element cultivation, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D16. 默认能量 `vfx_energy_default.png`（无元素兜底）
- **代码引用**：`_element_to_filename()` 默认分支（含"无"元素）

**生成提示词**:
> single game visual effect texture, generic white qi energy burst, neutral cultivation power explosion, white-blue spiritual energy radiating outward, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

## D17-D20 通用类（→ `vfx/common/`）

### D17. 粒子光点 `vfx_particle_dot.png` — ⭐ 20 张中最关键
- **代码引用**：`_particle_texture`——**全部元素粒子 + 受击粒子的贴图**，缺它所有粒子显示为默认方块

**生成提示词**:
> single game visual effect texture, single soft glowing energy orb, smooth gradient circle, white-center to transparent-edge, simple particle dot, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D18. 命中火花 `vfx_hit_spark.png` — 储备（代码暂未引用）

**生成提示词**:
> single game visual effect texture, impact hit spark explosion, white-yellow sharp spark particles, collision flash effect, quick burst of light, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D19. 暴击闪光 `vfx_critical_flash.png` — 储备（代码暂未引用）

**生成提示词**:
> single game visual effect texture, critical strike star flash, bright white starburst with red edges, intense power flash effect, radial light explosion, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

### D20. 光环扩散 `vfx_glow_ring.png` — 储备（代码暂未引用）

**生成提示词**:
> single game visual effect texture, expanding circular glow ring, thin luminous halo circle, white energy ring expanding outward, ripple effect, glowing energy effect, solid black background, 2D game VFX sprite, centered composition, high contrast, vibrant colors, no text, 8k quality

## Part D 交付清单

| # | 文件名 | 子目录 | 代码引用 |
|---|--------|--------|---------|
| D1 | `vfx_slash_arc.png` | weapon | Sword/Blade |
| D2 | `vfx_fist_wave.png` | weapon | Fist |
| D3 | `vfx_palm_wind.png` | weapon | None/默认 |
| D4 | `vfx_staff_impact.png` | weapon | Staff |
| D5 | `vfx_fire_burst.png` | element | 火 |
| D6 | `vfx_ice_crystal.png` | element | 冰 |
| D7 | `vfx_lightning_bolt.png` | element | 雷 |
| D8 | `vfx_poison_cloud.png` | element | 毒 |
| D9 | `vfx_metal_glint.png` | element | 金 |
| D10 | `vfx_dark_vortex.png` | element | 暗 |
| D11 | `vfx_light_burst.png` | element | 光 |
| D12 | `vfx_water_splash.png` | element | 水 |
| D13 | `vfx_wood_thorns.png` | element | 木 |
| D14 | `vfx_earth_crack.png` | element | 土 |
| D15 | `vfx_wind_spiral.png` | element | 风 |
| D16 | `vfx_energy_default.png` | element | 无/兜底 |
| D17 | `vfx_particle_dot.png` | common | 粒子贴图 ⭐ |
| D18 | `vfx_hit_spark.png` | common | 储备 |
| D19 | `vfx_critical_flash.png` | common | 储备 |
| D20 | `vfx_glow_ring.png` | common | 储备 |

> 提示词来源：[tools/comfyui/generate_vfx_workflow.py](../../../tools/comfyui/generate_vfx_workflow.py)（`transparent black background` 已统一修订为 `solid black background`，原因见「统一规格」底色行）。

---
---

# Part E — 过场插图（6 张，P0×5 + P1×1）

> **用途**：CutscenePlayer 系统的全屏帧图（静态图序列 + 引擎内淡入淡出/运镜 + 旁白字幕）。
> **来源**：飞升之战记忆碎片分镜见 [act1-qingyun-town-crisis.md](../../../design/narrative/story/act1-qingyun-town-crisis.md) §5.3（事件五触碰记忆水晶后播放，Act 1 核心伏笔）；赶路过场见 [fast-travel-system.md](../../../design/gdd/fast-travel-system.md)。
> **⚠️ 负面提示词注意**：过场插图**就是场景画**，通用负面提示词中的「背景色块, 水墨晕染背景, 山水画背景, 场景, 建筑物, 地面」**不适用于本 Part**（那是给立绘用的）。

## 统一规格与基调

| 项 | 规格 |
|----|------|
| 生成尺寸 | 16:9 最大可用尺寸（≥1024×576，母版 1024×576；游戏图 1920×1080 后处理放大） |
| 底色 | **不透明全屏画面**（无需抠图、无需透明底） |
| 放置 | 母版 `assets/ui/_masters/cutscene_frames_1024/`；游戏图 `assets/ui/cutscene_frames/`（新建） |
| 画风 | 宋代山水画风格 + 仙侠工笔，与背景资产一致 |

**E1-E5 统一基调（记忆质感，与现实场景区分）**：古旧壁画/褪色绢本质感，画面边缘带灵幻青蓝辉光，如同从记忆水晶中浮现的上古残影——5 张作为一组必须有统一识别度。提示词统一后缀：`, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere`。

## E1. 记忆碎片·修士集结 (cutscene_ascension_gathering)

- **文件名**: `cutscene_ascension_gathering.png`
- **对应分镜**: 画面1「数十名化神期修士在飞升台前集结」

**中文内容描述**: 云海之巅的巨大石制飞升台，数十名衣袂飘飘的上古修士背影列阵于台前，仰望天穹，庄严肃穆，山雨欲来。

**提示词**:
```
epic wide scene of dozens of ancient Chinese cultivators in flowing robes gathered in formation before a colossal stone ascension platform above the sea of clouds, backs to viewer, gazing up at the heavens, solemn and majestic atmosphere, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere, cinematic composition, no text no watermark
```

**关键词**: 飞升台, 修士列阵, 云海, 记忆质感

## E2. 记忆碎片·雷霆封印 (cutscene_ascension_thunder)

- **文件名**: `cutscene_ascension_thunder.png`
- **对应分镜**: 画面2「天空中降下雷霆，封印阵法启动」

**中文内容描述**: 天穹裂开，万道紫色雷霆自九天劈落，地面巨型封印阵法亮起环形符文光带，修士们惊骇四散。

**提示词**:
```
dramatic scene of purple lightning bolts raining down from a torn sky onto a giant glowing sealing formation circle on the ground, ancient runes lighting up in concentric rings, cultivators scattering in shock, apocalyptic atmosphere, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere, cinematic composition, no text no watermark
```

**关键词**: 紫色雷霆, 封印阵法, 符文光环, 天穹裂开

## E3. 记忆碎片·黑衣主持 (cutscene_ascension_ritual)

- **文件名**: `cutscene_ascension_ritual.png`
- **对应分镜**: 画面3「一名神秘黑衣人主持封印仪式」

**中文内容描述**: 黑袍兜帽人影立于阵法正中央，双手结印，兜帽下看不清面容，周身黑雾缭绕，与青蓝符文光形成冷暖对冲，压迫感极强。

**提示词**:
```
mysterious hooded figure in black robes standing at the center of a glowing sealing formation, hands forming an arcane seal gesture, face hidden under the hood, black mist swirling around the body, cold cyan rune light contrasting against dark silhouette, oppressive ominous atmosphere, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere, cinematic composition, no text no watermark
```

**关键词**: 黑袍兜帽, 结印, 黑雾, 冷暖对冲

## E4. 记忆碎片·通道关闭 (cutscene_ascension_closing)

- **文件名**: `cutscene_ascension_closing.png`
- **对应分镜**: 画面4「飞升通道缓缓关闭，修士们绝望呼喊」

**中文内容描述**: 天穹上的金色光门正在缓缓合拢，只剩一线光缝，地面修士们伸手向天、跪地呼喊，绝望与不甘。

**提示词**:
```
tragic scene of a golden gate of light in the sky slowly closing with only a narrowing slit of radiance remaining, cultivators on the ground below reaching up toward the heavens, kneeling and crying out in despair, epic sorrow, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere, cinematic composition, no text no watermark
```

**关键词**: 金色光门, 合拢, 绝望呼喊, 一线光缝

## E5. 记忆碎片·符文印记 (cutscene_ascension_rune)

- **文件名**: `cutscene_ascension_rune.png`
- **对应分镜**: 画面5「碎片结束，只留下一个模糊的符文印记」

**中文内容描述**: 黑暗虚空正中央，悬浮一枚古老的发光符文印记，青蓝色微光，边缘模糊虚化如将熄的记忆，极简构图，神秘悠远。

**提示词**:
```
minimalist scene of a single ancient glowing rune sigil floating in the center of dark void, faint cyan-blue light, edges blurred and fading like a dying memory, mysterious and distant, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, ancient mural painting texture, faded silk scroll tones, ethereal cyan glow at edges, memory fragment atmosphere, cinematic composition, no text no watermark
```

**关键词**: 符文印记, 黑暗虚空, 青蓝微光, 极简

## E6. 赶路过场 (cutscene_travel_scroll) — P1

- **文件名**: `cutscene_travel_scroll.png`
- **对应需求**: 快速旅行 2 秒过场（GDD：水墨山水画卷展开 + 马蹄声 + 路线连线动画）——引擎侧叠加虚线路径动画，底图只需一幅山水长卷

**中文内容描述**: 横向山水长卷视角，古道蜿蜒穿过层叠群山，一人一骑剪影策马远行，马蹄扬起轻尘，大量留白，「千里江陵一日还」意境。注意：此张为**现实场景**（非记忆质感），不加 E1-E5 的壁画后缀。

**提示词**:
```
wide panoramic handscroll scene of an ancient winding road through layered misty mountains, a lone rider on horseback in silhouette traveling into the distance, light dust kicked up by hooves, generous negative space, journey atmosphere of a thousand miles in a single day, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, misty mountains, cinematic composition, no text no watermark
```

**关键词**: 山水长卷, 古道, 一骑远行, 留白

## Part E 交付清单

| 文件名 | 内容 | 分镜 |
|--------|------|------|
| `cutscene_ascension_gathering.png` | 修士集结 | 画面1 |
| `cutscene_ascension_thunder.png` | 雷霆封印 | 画面2 |
| `cutscene_ascension_ritual.png` | 黑衣主持 | 画面3 |
| `cutscene_ascension_closing.png` | 通道关闭 | 画面4 |
| `cutscene_ascension_rune.png` | 符文印记 | 画面5 |
| `cutscene_travel_scroll.png` | 赶路过场 | 快速旅行 |

**缺失兜底**：CutscenePlayer 对缺失帧图显示「黑底 + 帧标题」占位，资产未齐时系统即可联调；生成完成后放入 `assets/ui/_masters/cutscene_frames_1024/` 并告知，统一执行后处理（缩放 1920×1080 → `assets/ui/cutscene_frames/`）。

> ✅ **Part E 已完成**（2026-07-21）：6 张全部生成（2048×1152 精确 16:9），已后处理——原图备份 `_masters/cutscene_frames_2048_src/`，母版 1024×576 `_masters/cutscene_frames_1024/`，游戏图 1920×1080 `assets/ui/cutscene_frames/`（含 .import）。过场数据 `data/cutscenes/act1_ascension_memory.json`（E1-E5）与 `travel_montage.json`（E6）已接入，快速旅行过场已替换模拟计时器；测试 `tests/unit/ui/test_cutscene_manager.gd` 12/12 通过。

# Part F — 开场过场插图（1 张，P1）

> **用途**：Act 1 开场过场（`data/cutscenes/act1_opening.json`）帧1 建立镜头，挂接于 `act1_event1_opening.json` 的 WAKEUP_001 节点——游戏新档的第一眼画面。帧2 复用 `bg_player_home`，无需新图。

| 项 | 值 |
|----|----|
| 生成尺寸 | 16:9 最大可用尺寸（≥1024×576） |
| 底色 | **不透明全屏画面** |
| 放置 | 母版 `assets/ui/_masters/cutscene_frames_1024/`；游戏图 `assets/ui/cutscene_frames/`（1920×1080 后处理） |
| 画风 | 宋代山水画风格 + 仙侠工笔，与背景资产一致；**现实场景**（非记忆质感，不加 E1-E5 壁画后缀） |

## F1. 青云镇晨景全景 (cutscene_town_morning)

- **文件名**: `cutscene_town_morning.png`
- **对应分镜**: 剧本 §1.1「清晨的青云镇，炊烟袅袅…今天是青云镇一年一度的春集市」——establishing shot 大全景

**中文内容描述**: 清晨薄雾中的中国古镇大全景，青瓦白墙依山而建，家家户户炊烟袅袅升起，镇中春集市彩旗招展、人影攒动，远处青山如黛、晨光曚微，宁静祥和的仙侠小镇氛围。

**提示词**:
```
panoramic establishing shot of an ancient Chinese mountain town at dawn, blue-tiled roofs and white walls nestled against verdant mountains, cooking smoke rising gently from every chimney, colorful spring market banners and bustling tiny figures in the streets, misty morning light, serene and peaceful xianxia town atmosphere, Song Dynasty Chinese landscape painting style, shanshui ink wash technique, cinematic wide composition, no text no watermark
```

**关键词**: 晨景, 古镇全景, 炊烟, 春集市, 建立镜头

## Part F 交付清单

| 文件名 | 内容 | 分镜 |
|--------|------|------|
| `cutscene_town_morning.png` | 青云镇晨景全景 | 开场帧1 |

**缺失兜底**：未生成时 CutscenePlayer 对该帧显示「黑底 + 青云镇·春集之晨」占位，过场其余帧（bg_player_home 复用帧）正常播放，不阻塞联调。生成后放入 `assets/ui/_masters/cutscene_frames_1024/` 并告知，统一后处理。

# 生成后处理流程

## 1. 命名与放置

按「放置路径速查表」放入对应 `_masters/` 目录（1024 原图），逐一核对文件名与上表完全一致（snake_case，不得有中文/空格）。

## 2. 缩放生成游戏图（512）

macOS 原生命令（无需安装依赖）：

```bash
# 示例：NPC 立绘批量缩放
for f in assets/ui/_masters/npc_secondary_1024/portrait_{luping,xuanchengzi,gufei,saodidaoren,laozhou,jinwanguan,mystery_merchant,tangxiaoqi,baixiaosheng,sunergou}.png; do
  sips -Z 512 "$f" --out "assets/ui/portraits/$(basename "$f")"
done

# 敌人立绘同样：_masters/portraits_enemies_1024/ → enemy_portraits/
# VFX：_masters/vfx_1024/ → vfx/{weapon,element,common}/（256，子目录按 Part D 交付清单）
# 背景 bg_player_home：sips -z 1080 1920 母版 → backgrounds/
```

## 3. 透明底检查

若工具输出为白/黑底：用工具自带抠图或 macOS「预览 → 即时 Alpha」处理；VFX 黑底可用混合模式 `add` 直接免抠（集成时确认）。

## 4. Godot 集成验证

1. 打开 Godot 编辑器，等待自动导入生成 `.import` 文件
2. 对话系统：NPC 立绘在 `data/dialogues/npc_*.json` 的 metadata 或对话节点中引用立绘 ID
3. 游戏内验证：进入对应区域触发对话/战斗，截图留档至 `production/qa/evidence/ui-assets/`

## 5. 验收清单

- [ ] 10 张 NPC 立绘（A1-A10）母版 + 512 游戏图就位
- [ ] 12 张敌人立绘（B1-B12）母版 + 512 游戏图就位
- [ ] 血无恨默认立绘与 angry/happy 变体角色一致
- [ ] bg_player_home 1920×1080 就位
- [ ] 20 张 VFX 就位，透明/黑底处理确认
- [ ] 5 张记忆碎片过场图（E1-E5）基调统一（壁画质感 + 青蓝辉光边缘）
- [ ] 赶路过场图（E6）为现实场景质感（无记忆滤镜）
- [ ] 过场图 1920×1080 就位 `assets/ui/cutscene_frames/`
- [ ] 风格与既有资产一致（对照参考图）
- [ ] 游戏内截图留档

---

**任务单版本**: v1.0
**创建日期**: 2026-07-21
**依据**: Act 1 四区域 LDD（2026-07-21 APPROVED）+ 资产现状盘点（734 项已有）
