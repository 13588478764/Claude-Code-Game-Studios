# 成长数据保存

## 1. 概述

成长数据保存系统负责持久化存储角色成长相关的所有数据，包括等级、境界、属性点分配、技能学习状态等。该系统与角色成长系统、世界状态持久化系统和装备系统集成，确保玩家进度在游戏重启后能够正确恢复。

## 2. 核心机制

### 2.1 数据范围
- **基础成长数据**：
  - 当前等级（1-99）
  - 当前境界（0-9对应10个大境界）
  - 经验值进度
  - 已获得属性点数和已分配属性点数
- **属性分配数据**：
  - 六维属性值（力道、身法、根骨、悟性、定力、福缘）
  - 免费重置次数（境界突破获得）
- **技能学习数据**：
  - 已学习武学列表
  - 武学熟练度
  - 内功心法配置
  - 轻功秘籍配置
- **装备数据**：
  - 当前装备配置（9个槽位：主手、副手、头饰、衣袍、护手、靴子、项链、左戒、右戒）
  - 背包中的可装备物品
- **奇遇历史数据**：
  - 已完成奇遇记录
  - 奇遇相关属性变更

### 2.2 保存时机
- **自动保存**：
  - 角色升级时
  - 境界突破时
  - 属性点分配时
  - 装备变更时
  - 武学学习/遗忘时
  - 奇遇完成时
- **手动保存**：玩家主动选择保存游戏
- **周期保存**：每5分钟自动保存一次（防丢失）

### 2.3 数据格式
- **主存档格式**：JSON格式，人类可读，便于调试
- **备份机制**：保留最近3个自动备份
- **云同步**：支持云端存档同步（可选）
- **版本兼容**：支持向后兼容的数据版本管理

### 2.4 加密和安全
- **数据完整性**：使用CRC32校验码验证数据完整性
- **防篡改**：关键数据使用简单加密（非DRM，仅防意外修改）
- **隐私保护**：不包含个人身份信息

## 3. 技术规格

### 3.1 数据结构
```yaml
GrowthData:
  version: String  # 数据版本号
  characterId: String  # 角色唯一标识
  timestamp: Integer  # 保存时间戳
  
  progression:
    level: Integer  # 1-99
    realm: Integer  # 0-9 (炼气-真仙)
    experience: Integer
    experienceToNextLevel: Integer
    
  attributes:
    totalPoints: Integer
    allocatedPoints: Integer
    resetCount: Integer
    values:
      strength: Integer
      agility: Integer
      constitution: Integer
      intelligence: Integer
      willpower: Integer
      luck: Integer
      
  martialArts:
    learnedSkills: List[String]  # 武学ID列表
    skillProficiencies: Map[String, Integer]  # 武学ID -> 熟练度
    innerArts: List[String?]  # [slot1, slot2, slot3]
    lightArt: String?
    
  equipment:
    slots: Map[String, String?]  # 槽位类型 -> 装备ID
    backpack: List[String]  # 装备ID列表
    
  encounters:
    completedEncounters: List[String]  # 奇遇ID列表
    encounterEffects: Map[String, EncounterEffect]  # 奇遇ID -> 效果数据

SaveMetadata:
  saveSlot: Integer  # 存档槽位（1-3）
  playerName: String
  playTime: Integer  # 游戏时间（秒）
  lastLocation: String  # 最后位置
  checksum: String  # CRC32校验码
```

### 3.2 接口定义
- `saveGrowthData(character: Character)`: 保存角色成长数据
- `loadGrowthData(saveSlot: Integer): GrowthData?`: 加载指定存档槽的成长数据
- `getAvailableSaves(): List[SaveMetadata]`: 获取可用存档列表
- `deleteSave(saveSlot: Integer)`: 删除指定存档
- `validateSaveData(data: GrowthData): Boolean`: 验证存档数据完整性
- `migrateSaveData(oldData: Any, targetVersion: String): GrowthData`: 数据版本迁移

### 3.3 存储位置
- **本地存储**：
  - Windows: `%APPDATA%/WuxiaAdventure/saves/`
  - macOS: `~/Library/Application Support/WuxiaAdventure/saves/`
  - Linux: `~/.local/share/WuxiaAdventure/saves/`
- **文件命名**：`save_slot_{1-3}.json`
- **备份文件**：`save_slot_{1-3}_backup_{timestamp}.json`

## 4. 性能和可靠性考虑

### 4.1 性能优化
- **异步保存**：保存操作在后台线程执行，不影响主线程
- **增量保存**：只保存发生变化的数据部分
- **内存缓存**：频繁访问的数据保持内存缓存
- **压缩存储**：大型数据使用轻量级压缩

### 4.2 可靠性保障
- **原子写入**：先写临时文件，验证成功后再替换原文件
- **错误恢复**：保存失败时自动回滚到上一个有效状态
- **备份策略**：自动保留多个时间点的备份
- **损坏检测**：加载时自动检测并尝试修复损坏数据

### 4.3 跨平台兼容
- **字节序无关**：使用文本格式避免字节序问题
- **路径兼容**：使用跨平台路径分隔符
- **编码统一**：UTF-8编码确保多语言支持
- **大小写敏感**：统一使用小写文件名

## 5. 依赖关系

- **依赖系统**：角色成长系统、世界状态持久化系统、装备系统、武学系统、奇遇系统
- **被依赖系统**：无（数据持久化为终端服务）

## 6. 验收标准

- [ ] 所有角色成长数据正确保存和加载
- [ ] 自动保存时机覆盖所有关键事件
- [ ] 手动保存功能正常工作
- [ ] 备份机制有效防止数据丢失
- [ ] 数据版本迁移支持向后兼容
- [ ] 存档数据完整性验证通过
- [ ] 跨平台存档兼容性测试通过
- [ ] 异步保存不影响游戏性能
- [ ] 错误恢复机制有效
- [ ] 云同步功能（如果实现）正常工作