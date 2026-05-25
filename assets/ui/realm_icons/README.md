# 境界图标资源

此目录包含**十大境界**图标，与 `src/scripts/character/character_system.gd` 的 `REALMS` 常量一一对应。

## 境界列表（与代码对齐）

| 序 | 境界 | 等级区间 | 文件名 | 视觉主体 |
|----|------|---------|--------|---------|
| 1  | 炼气 | 1–10  | `qi_refining.png`            | 灵气螺旋绕珠 |
| 2  | 筑基 | 11–20 | `foundation.png`             | 三阶石塔基座 |
| 3  | 金丹 | 21–30 | `golden_core.png`            | 金色发光球 |
| 4  | 元婴 | 31–40 | `nascent_soul.png`           | 球内打坐剪影 |
| 5  | 化神 | 41–50 | `spirit_transformation.png`  | 长袍人形 + 灵息辐射 |
| 6  | 返虚 | 51–60 | `void_reverting.png`         | 盘坐剪影下半身化烟 |
| 7  | 合道 | 61–70 | `dao_unity.png`              | 太极阴阳 |
| 8  | 大乘 | 71–80 | `great_vehicle.png`          | 莲台坐姿剪影 |
| 9  | 渡劫 | 81–90 | `heavenly_tribulation.png`   | 雷暴下立姿人影 |
| 10 | 真仙 | 91–99 | `true_immortal.png`          | 飞升羽翼剪影 |

## 命名规范

- 文件名：英文 snake_case，无 `realm_icon_` 前缀
- 规格：128×128 PNG，透明背景（已 BRIA 抠图）
- 1024 母版备份在 `assets/ui/_masters/realms_1024/`（不入游戏包）

## 加载规则

由 `src/scripts/ui/hud/player_status_panel.gd::_load_realm_icon()` 加载。
函数会对传入的境界名做规范化：剥离 `(早期)`/`(后期)` 括号、去掉 `期`/`境` 后缀，
所以三种格式都能正确映射：

- `"炼气"`           ← `character_system.gd`
- `"炼气期"` / `"真仙境"`  ← `level_up_manager.gd`
- `"炼气期(早期)"`   ← 历史遗留

## 生成管线

由 `tools/comfyui/workflows/05_realms_batch_flux.json` 一次性批量产出，
共享 FLUX seed + BRIA 抠图保证风格一致。重新出图后跑：

```bash
./tools/comfyui/import_ai_assets.sh           # 预览
./tools/comfyui/import_ai_assets.sh --commit  # 实际回流到本目录
```
