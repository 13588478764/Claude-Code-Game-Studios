# Class Name Registry

**Purpose**: 集中登记游戏代码中所有 `class_name` 声明, 避免重名冲突和孤儿类。
**Scope**: src/scripts/ + src/scenes/ (不含 src/addons/)
**Last Audit**: 2026-05-25 (Polish Week 2)
**Total Unique Classes**: 134

**关联**:
- milestone-alpha-review.md lessons #4 (class_name 命名空间未统一管理)
- polish-fixlist-2026-05-25 #5 (class_name 冲突修复)

---

## 添加规则

新增 `class_name` 前必须遵守:

1. **检查本表** — 确认无重名 (Ctrl+F 搜索打算用的类名)
2. **检查全局** — `grep -rEn "^class_name\s+<YourName>\s*$" src/` 确认无声明
3. **命名规范** — PascalCase, 与文件名 (snake_case) 一一对应
4. **prefix 区分** — 跨子系统的同名概念用 prefix 区分 (例: `EquipmentManager` vs `EnemyEquipmentManager`)
5. **新增后** — 把条目添加到本文件对应模块表中, 与 PR 一起提交

---

## ⚠️ 已知问题

### Intra-file class_name 重复声明 (5 处)

这些文件在同一文件内声明了两次 `class_name`, 是历史 stub 残留。Godot 4.6 解析时会忽略第二个声明 (静默), 但属于代码卫生 bug, 应在 Beta 早期清理。

| 文件 | 重复行 | 建议 |
|------|-------|------|
| src/scripts/ui/combat_feedback_manager.gd | 9, 38 | 删第 38 行 |
| src/scripts/data/consumable_data.gd | 13, 39 | 删第 39 行 |
| src/scripts/data/equipment_data.gd | 13, 39 | 删第 39 行 |
| src/scripts/data/item_data.gd | 13, 39 | 删第 39 行 |
| src/scripts/data/quest_item_data.gd | 13, 39 | 删第 39 行 |

> 不在本次 Polish 处理 — 单独发 PR + 测试通过后合并, 避免数据类回归。

### 已解决冲突 (历史记录)

| 时间 | 类名 | 冲突原因 | 解决方式 |
|------|------|--------|--------|
| 2026-05-25 | `DamageVisualization` (旧) vs `DamageVisualizationManager` (新) | combat 战斗反馈重构 | 旧版重命名为 Manager 后缀, class_name 全局唯一 |
| 2026-05-25 | `WorldStreamingManager` (像素版 旧) vs `WorldStreamingManager` (区域版 新) | 两套实现并存 | 新版禁用 class_name (tests 用 load() 不依赖符号), 旧版保留 (节点引用依赖) |

---

## 类名注册表 (按模块)

### audio (1)

| 类名 | 文件 |
|------|------|
| `AudioSystem` | audio/audio_system.gd |

### character (7)

| 类名 | 文件 |
|------|------|
| `AttributeAssignmentUI` | character/attribute_assignment_ui.gd |
| `AttributePointManager` | character/attribute_point_manager.gd |
| `AttributeValidationManager` | character/attribute_validation_manager.gd |
| `ExpAcquisitionManager` | character/exp_acquisition_manager.gd |
| `ExpCalculationManager` | character/exp_calculation_manager.gd |
| `LevelUpManager` | character/level_up_manager.gd |
| `LifespanManager` | character/lifespan_manager.gd |

### combat (16)

| 类名 | 文件 |
|------|------|
| `AiDecisionManager` | combat/ai_decision_manager.gd |
| `AiDifficultyManager` | combat/ai_difficulty_manager.gd |
| `CombatManager` | combat/combat_manager.gd |
| `CombatSystem` | combat/combat_system.gd |
| `DamageCalculator` | combat/damage_calculator.gd |
| `DamageMultiplierManager` | combat/damage_multiplier_manager.gd |
| `DamageVisualizationManager` | combat/damage_visualization_manager.gd |
| `DefenseMitigationManager` | combat/defense_mitigation_manager.gd |
| `EnemyBehaviorManager` | combat/enemy_behavior_manager.gd |
| `HealthPoiseManager` | combat/health_poise_manager.gd |
| `HitDetectionManager` | combat/hit_detection_manager.gd |
| `LinkSystem` | combat/link_system.gd |
| `MartialArtsComboSystem` | combat/martial_arts_combo_system.gd |
| `QiManager` | combat/qi_manager.gd |
| `RecoveryStatusManager` | combat/recovery_status_manager.gd |
| `WeaknessSystem` | combat/weakness_system.gd |

### core/performance (7)

| 类名 | 文件 |
|------|------|
| `BatchUpdateManager` | core/performance/batch_update_manager.gd |
| `BuffIconPool` | core/performance/buff_icon_pool.gd |
| `DamageNumberPool` | core/performance/damage_number_pool.gd |
| `LODUpdateScheduler` | core/performance/lod_update_scheduler.gd |
| `NotificationPool` | core/performance/notification_pool.gd |
| `ObjectPool` | core/performance/object_pool.gd |
| `PerformanceMonitor` | core/performance/performance_monitor.gd |

### data (6)

| 类名 | 文件 |
|------|------|
| `ConsumableData` | data/consumable_data.gd (⚠️ 重复声明, 见已知问题) |
| `EquipmentData` | data/equipment_data.gd (⚠️ 重复声明, 见已知问题) |
| `ItemData` | data/item_data.gd (⚠️ 重复声明, 见已知问题) |
| `MartialArtData` | data/martial_art_data.gd |
| `MartialArtDatabase` | data/martial_art_database.gd |
| `QuestItemData` | data/quest_item_data.gd (⚠️ 重复声明, 见已知问题) |

### dialogue (1)

| 类名 | 文件 |
|------|------|
| `DialogueData` | dialogue/dialogue_data.gd |

### economy (3)

| 类名 | 文件 |
|------|------|
| `ItemManager` | economy/item_manager.gd |
| `PriceBalancingManager` | economy/price_balancing_manager.gd |
| `TradeManager` | economy/trade_manager.gd |

### encounter (10)

| 类名 | 文件 |
|------|------|
| `ConditionEvaluator` | encounter/condition_evaluator.gd |
| `EncounterDataStructures` | encounter/encounter_data_structures.gd |
| `EncounterRecordManager` | encounter/encounter_record_manager.gd |
| `EncounterRewardManager` | encounter/encounter_reward_manager.gd |
| `EncounterTriggerManager` | encounter/encounter_trigger_manager.gd |
| `HistoryDisplayManager` | encounter/history_display_manager.gd |
| `HistoryLogger` | encounter/history_logger.gd |
| `HistoryPersistenceManager` | encounter/history_persistence_manager.gd |
| `LogicTreeManager` | encounter/logic_tree_manager.gd |
| `TriggerMechanismManager` | encounter/trigger_mechanism_manager.gd |

### enemy_scaling (9)

| 类名 | 文件 |
|------|------|
| `DynamicDifficulty` | enemy_scaling/dynamic_difficulty.gd |
| `EdgeCaseHandler` | enemy_scaling/edge_cases.gd |
| `EnemyGenerator` | enemy_scaling/enemy_generator.gd |
| `EnemyMultipliers` | enemy_scaling/multipliers.gd |
| `EnemyScalingConfigLoader` | enemy_scaling/config_loader.gd |
| `EnemyScalingDebugVisualizer` | enemy_scaling/debug_visualizer.gd |
| `LevelCoefficient` | enemy_scaling/level_coefficient.gd |
| `PerformanceOptimizer` | enemy_scaling/performance_optimizer.gd |
| `RealmCoefficient` | enemy_scaling/realm_coefficient.gd |

### equipment (8)

| 类名 | 文件 |
|------|------|
| `ElementalPropertyCalculator` | equipment/elemental_property_calculator.gd |
| `EquipmentAttributeCalculator` | equipment/equipment_attribute_calculator.gd |
| `EquipmentBonusApplier` | equipment/equipment_bonus_applier.gd |
| `EquipmentManager` | equipment/equipment_manager.gd |
| `EquipmentRuleValidator` | equipment/equipment_rule_validator.gd |
| `EquipmentSlotManager` | equipment/equipment_slot_manager.gd |
| `EquipmentWearer` | equipment/equipment_wearer.gd |
| `RealmUnlockManager` | equipment/realm_unlock_manager.gd |

### fast_travel (3)

| 类名 | 文件 |
|------|------|
| `FastTravelManager` | fast_travel/fast_travel_manager.gd |
| `LocationDiscoveryManager` | fast_travel/location_discovery_manager.gd |
| `TravelCostManager` | fast_travel/travel_cost_manager.gd |

### npc (1)

| 类名 | 文件 |
|------|------|
| `NPCInteractionTrigger` | npc/npc_interaction_trigger.gd |

### persistence (3)

| 类名 | 文件 |
|------|------|
| `DataIntegrityManager` | persistence/data_integrity_manager.gd |
| `GrowthDataStructureManager` | persistence/growth_data_structure_manager.gd |
| `SaveLoadManager` | persistence/save_load_manager.gd |

### quest (3)

| 类名 | 文件 |
|------|------|
| `QuestManager` | quest/quest_manager.gd |
| `QuestRewardManager` | quest/quest_reward_manager.gd |
| `QuestTracker` | quest/quest_tracker.gd |

### relationship (2)

| 类名 | 文件 |
|------|------|
| `EndingDetermination` | relationship/ending_determination.gd |
| `RelationshipData` | relationship/relationship_data.gd |

### rendering (1)

| 类名 | 文件 |
|------|------|
| `LodManager` | rendering/lod_manager.gd |

### reward_distribution (3)

| 类名 | 文件 |
|------|------|
| `RewardBalanceManager` | reward_distribution/reward_balance_manager.gd |
| `RewardDistributionManager` | reward_distribution/reward_distribution_manager.gd |
| `RewardTypeManager` | reward_distribution/reward_type_manager.gd |

### skill_tree (2)

| 类名 | 文件 |
|------|------|
| `SkillTreeManager` | skill_tree/skill_tree_manager.gd |
| `SkillUnlockManager` | skill_tree/skill_unlock_manager.gd |

### ui (20)

| 类名 | 文件 |
|------|------|
| `CharacterGrowthUiScript` | ui/character_growth_ui_script.gd |
| `CharacterPanelScript` | ui/character_panel_script.gd |
| `CombatFeedbackManager` | ui/combat_feedback_manager.gd (⚠️ 重复声明) |
| `CombatHud` | ui/combat_hud.gd |
| `CombatMenuManager` | ui/combat_menu_manager.gd |
| `EncounterUiScript` | ui/encounter_ui_script.gd |
| `EquipmentUi` | ui/equipment_ui.gd |
| `EquipmentUiEffects` | ui/equipment_ui_effects.gd |
| `EquipmentUiInteraction` | ui/equipment_ui_interaction.gd |
| `EquipmentUiTest` | ui/equipment_ui_test.gd |
| `ExploreManager` | ui/explore_manager.gd |
| `Minimap` | ui/minimap.gd |
| `NavigationMarker` | ui/navigation_marker.gd |
| `OffscreenIndicator` | ui/offscreen_indicator.gd |
| `PoiMarker` | ui/poi_marker.gd |
| `StatusIcon` | ui/status_icon.gd |
| `StatusIconBar` | ui/status_icon_bar.gd |
| `StatusTooltip` | ui/status_tooltip.gd |
| `StatusVisualFeedback` | ui/status_visual_feedback.gd |
| `UiManager` | ui/ui_manager.gd |

### ui/hud (10)

| 类名 | 文件 |
|------|------|
| `ActionQueueDisplay` | ui/hud/action_queue_display.gd |
| `ActionQueueUnit` | ui/hud/action_queue_unit.gd |
| `EnemyInfoPanel` | ui/hud/enemy_info_panel.gd |
| `HUDManager` | ui/hud/hud_manager.gd |
| `MenuSystemFunctions` | ui/hud/menu_system_functions.gd |
| `NotificationManager` | ui/hud/notification_manager.gd |
| `PartyMemberSlot` | ui/hud/party_member_slot.gd |
| `PartyStatusDisplay` | ui/hud/party_status_display.gd |
| `PlayerStatusPanel` | ui/hud/player_status_panel.gd |
| `WeaknessIconDisplay` | ui/hud/weakness_icon_display.gd |

### validation (1)

| 类名 | 文件 |
|------|------|
| `MvpValidation` | validation/mvp_validation.gd |

### world (4)

| 类名 | 文件 |
|------|------|
| `ExplorationTracker` | world/exploration_tracker.gd |
| `PlayerMovementController` | world/player_movement_controller.gd |
| `PoiManager` | world/poi_manager.gd |
| `WorldSystem` | world/world_system.gd |

### scenes/ui/hud (3)

| 类名 | 文件 |
|------|------|
| `ComboLinkDisplay` | scenes/ui/hud/ComboLinkDisplay.gd |
| `HotbarController` | scenes/ui/hud/HotbarController.gd |
| `HotbarSlot` | scenes/ui/hud/HotbarSlot.gd |

### src/scripts/ (根, 10) — 历史遗留, 建议逐步迁移到模块子目录

| 类名 | 文件 | 建议归位 |
|------|------|--------|
| `GameConfigManager` | game_config_manager.gd | core/ |
| `MVPValidationTest` | test_mvp_validation.gd | tests/ 或删除 |
| `MemoryOptimizer` | memory_optimizer.gd | core/performance/ |
| `PlayerPositionTracker` | player_position_tracker.gd | world/ |
| `ProgressManager` | progress_manager.gd | persistence/ 或 character/ |
| `StatusEffect` | status_effect.gd | combat/ |
| `StatusEffectManager` | status_effect_manager.gd | combat/ |
| `WorldStateLoader` | world_state_loader.gd | persistence/ |
| `WorldStateSaver` | world_state_saver.gd | persistence/ |
| `WorldStreamingManager` | world_streaming_manager.gd | world/ (旧版, 与 world/world_streaming_manager.gd 冲突待决) |

### 显式未注册的类 (DEPRECATED / 待清理)

以下文件保留代码但已 disable class_name, **不占用全局符号**:

| 文件 | 原 class_name | 禁用原因 |
|------|--------------|--------|
| src/scripts/world/world_streaming_manager.gd | `WorldStreamingManager` | 与旧版同名冲突 (polish #5) |
| src/scripts/documentation/document_consistency_analyzer.gd | `DocumentConsistencyAnalyzer` | 0 引用空壳, 待 lead-programmer 决策 (polish #22) |
| src/scripts/documentation/conflict_resolution_planner.gd | `ConflictResolutionPlanner` | 同上 |
| src/scripts/documentation/document_alignment_implementer.gd | `DocumentAlignmentImplementer` | 同上 |

---

## 维护清单 (给 lead-programmer)

| 项 | 优先级 | 描述 |
|----|------|------|
| Beta 早期 | P1 | 修复 5 处 intra-file 重复声明 (单 PR) |
| Beta 早期 | P1 | 决策 4 个 DEPRECATED 文件 (删 / 迁移 / 重启) |
| Beta 中期 | P2 | 评估 src/scripts/ 根目录 10 个类迁移到子模块 (单独 PR per 模块) |
| 持续 | P0 | 新增 class_name 时同步更新本文件 |

---

## 自动化建议

考虑加 pre-commit hook 检测 class_name 冲突:

```bash
# scripts/check-class-name-duplicates.sh
grep -hrE "^class_name\s+\w+" src/scripts/ src/scenes/ | \
  sort | uniq -d | \
  if read -r line; then
    echo "ERROR: Duplicate class_name found: $line"
    exit 1
  fi
```

> 当前未实施, alpha-review action #6 建议在 Sprint 8 落地。
