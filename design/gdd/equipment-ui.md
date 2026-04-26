# 装备UI

## 1. 概述

装备UI系统为玩家提供直观的装备管理和查看界面。该系统与装备槽位系统、装备属性计算系统和战斗UI集成，支持装备的装备/卸下、属性对比、品阶显示等功能，并遵循统一的4级品阶颜色编码（普通-白色、稀有-蓝色、史诗-紫色、传说-金色）。

## 2. 核心机制

### 2.1 界面布局
- **角色面板**：显示角色模型和已装备物品的可视化展示
- **装备槽位区域**：按类别分组显示所有装备槽位
  - 武器区域（主手/副手）
  - 防具区域（头部、身体、手部、腿部、脚部）
  - 饰品区域（戒指×2、项链、腰带）
  - 特殊区域（内功心法×3、轻功秘籍）
- **背包区域**：显示可装备的物品列表
- **属性对比面板**：显示当前装备与选中装备的属性差异

### 2.2 交互功能
- **装备操作**：
  - 点击空槽位从背包选择装备
  - 点击已装备物品卸下到背包
  - 拖拽装备到对应槽位
  - 右键点击装备快速装备/卸下
- **属性查看**：
  - 鼠标悬停显示详细属性信息
  - 点击装备打开详细信息面板
  - 属性对比高亮显示增益/损失
- **筛选和排序**：
  - 按品阶筛选（白/蓝/紫/金）
  - 按类型筛选（武器/防具/饰品/特殊）
  - 按属性排序（攻击力/防御力/六维属性等）

### 2.3 视觉反馈
- **品阶颜色编码**：
  - 普通（白色）：白色文字和边框
  - 稀有（蓝色）：蓝色文字和发光边框
  - 史诗（紫色）：紫色文字和动态发光效果
  - 传说（金色）：金色文字和粒子特效
- **状态指示**：
  - 绿色高亮：可装备且属性提升
  - 红色高亮：不可装备（等级/境界不足）
  - 黄色高亮：可装备但属性下降
  - 锁定图标：槽位未解锁（境界不足）
- **动画效果**：
  - 装备成功：绿色闪光动画
  - 装备失败：红色震动动画
  - 品阶升级：对应颜色的粒子爆发效果

### 2.4 特殊功能
- **一键装备**：自动选择最佳装备组合
- **装备推荐**：基于当前武学流派推荐装备
- **套装效果显示**：显示激活的套装效果
- **元素属性可视化**：显示装备的五行元素属性

## 3. 技术规格

### 3.1 UI组件
```yaml
EquipmentUIComponents:
  CharacterModelPanel:
    characterModel: GameObject
    equippedItemsVisuals: Map[String, GameObject]  # 槽位类型 -> 装备模型
  
  EquipmentSlotGrid:
    slots: List[EquipmentSlotComponent]
    layoutType: String  # "weapons", "armor", "accessories", "special"
  
  EquipmentSlotComponent:
    slotType: String
    currentEquipment: EquipmentData?
    isLocked: Boolean
    visualState: String  # "normal", "highlight_positive", "highlight_negative", "locked"
  
  BackpackPanel:
    items: List[BackpackItemComponent]
    filters: EquipmentFilter
    sortMode: String
  
  BackpackItemComponent:
    equipmentData: EquipmentData
    visualTier: String  # "common", "rare", "epic", "legendary"
    canEquip: Boolean
  
  AttributeComparisonPanel:
    currentStats: CharacterTotalAttributes
    newStats: CharacterTotalAttributes
    differences: AttributeDifferences
```

### 3.2 数据绑定
- 实时监听装备槽位变化事件
- 自动更新角色总属性显示
- 背包物品状态实时同步
- 境界变化时自动刷新槽位解锁状态

### 3.3 性能优化
- 装备图标使用图集（Sprite Atlas）
- 角色模型使用LOD（细节层次）
- 大量物品时使用虚拟滚动
- 粒子特效使用对象池

## 4. 用户体验考虑

### 4.1 新手引导
- 首次打开装备UI时显示引导提示
- 高亮显示可装备的物品
- 提供装备基础教程
- 显示推荐装备标记

### 4.2 可访问性
- 支持键盘导航（Tab键切换槽位）
- 支持屏幕阅读器（ARIA标签）
- 颜色盲友好模式（形状+颜色双重标识）
- 字体大小可调节

### 4.3 移动端适配
- 触摸友好的大按钮设计
- 手势支持（滑动切换标签页）
- 自适应布局（横屏/竖屏）
- 简化操作流程

## 5. 依赖关系

- **依赖系统**：装备系统、装备槽位系统、装备属性计算、角色成长系统
- **被依赖系统**：无（UI层为终端系统）

## 6. 验收标准

- [ ] 装备槽位正确显示并按境界解锁
- [ ] 装备品阶颜色编码正确应用
- [ ] 装备/卸下操作流畅且有视觉反馈
- [ ] 属性对比功能准确显示差异
- [ ] 筛选和排序功能正常工作
- [ ] 一键装备和推荐功能有效
- [ ] UI在不同分辨率下正常显示
- [ ] 性能优化措施有效（60FPS）
- [ ] 支持键盘和触摸操作
- [ ] 装备数据正确保存和加载