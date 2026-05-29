# 音效资源目录

## 目录结构

```
assets/audio/
├── bgm/              # 背景音乐 (循环, .ogg)
│   ├── bgm_main_menu.ogg      # 主菜单
│   ├── bgm_exploration.ogg    # 探索/大地图
│   ├── bgm_battle_normal.ogg  # 普通战斗
│   ├── bgm_battle_boss.ogg    # Boss 战斗
│   └── bgm_breakthrough.ogg   # 境界突破
│
├── sfx/              # 音效 (单次, .ogg/.wav)
│   ├── ui/           # UI 交互音效
│   │   ├── btn_click.ogg       # 按钮点击
│   │   ├── btn_hover.ogg       # 按钮悬停
│   │   ├── panel_open.ogg      # 面板打开
│   │   ├── panel_close.ogg     # 面板关闭
│   │   └── notification.ogg    # 系统通知
│   ├── combat/       # 战斗音效
│   │   ├── hit_normal.ogg      # 普通攻击命中
│   │   ├── hit_critical.ogg    # 暴击命中
│   │   ├── defend.ogg          # 防御格挡
│   │   ├── dodge.ogg           # 闪避
│   │   ├── skill_cast.ogg      # 技能释放
│   │   └── battle_win.ogg      # 战斗胜利
│   ├── environment/  # 环境音效
│   │   ├── wind.ogg            # 风声
│   │   └── water.ogg           # 水声
│   └── skills/       # 技能专属音效 (按 skill_id)
│       ├── sword_basic_01.ogg
│       ├── fist_basic_01.ogg
│       └── palm_basic_01.ogg
│
└── voice/            # 语音 (预留, 暂不使用)
```

## 技术规格

| 属性 | BGM | SFX |
|------|-----|-----|
| 格式 | .ogg (Vorbis) | .ogg 或 .wav |
| 采样率 | 44100 Hz | 44100 Hz |
| 位深 | 16-bit | 16-bit |
| 声道 | 立体声 | 单声道 (定位) 或立体声 (全局) |
| 循环 | 是 (loop=true) | 否 |
| 响度 | -14 LUFS (标准化) | -10 LUFS (SFX 稍响) |

## 接入方式

音效通过 `AudioSystem` (Autoload) 统一管理:
- `AudioSystem.play_bgm(track_name)` — 播放背景音乐 (淡入淡出)
- `AudioSystem.play_sfx(sfx_name)` — 播放一次性音效
- 路径约定: `res://assets/audio/{type}/{filename}.ogg`

## 音效来源建议

- **免费素材**: freesound.org, opengameart.org, kenney.nl
- **AI 生成**: Suno AI (BGM), ElevenLabs (配音)
- **自制**: Audacity + 音效合成插件

## 优先级

1. UI 音效 (btn_click + panel_open) — 最小可感知的音频反馈
2. 战斗音效 (hit_normal + skill_cast + battle_win) — 打击感核心
3. BGM (exploration + battle_normal) — 氛围营造
4. 技能专属音效 — 差异化体验
