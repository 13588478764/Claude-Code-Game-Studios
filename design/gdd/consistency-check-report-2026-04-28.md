# Consistency Check Report

**Date**: 2026-04-28
**Registry Version**: 1
**Scope**: Full scan (all GDDs)
**Registry Status**: Empty (needs population)

---

## Executive Summary

The entity registry (`design/registry/entities.yaml`) is currently empty. This is expected for a new project or after major design updates. Before running a full consistency check, the registry must be populated with cross-system entities, items, formulas, and constants.

**Verdict**: ⚠️ **REGISTRY EMPTY** — Cannot perform consistency check until registry is populated.

---

## Registry Statistics

- **Entities**: 0 registered
- **Items**: 0 registered
- **Formulas**: 0 registered
- **Constants**: 0 registered

**Total entries**: 0

---

## GDDs Scanned

Found 39 GDD files in `design/gdd/`:

### Core System GDDs (Recently Updated 2026-04-28)
1. ✅ martial-arts-database.md
2. ✅ item-database.md
3. ✅ character-progression-system.md
4. ✅ level-up-mechanism.md
5. ✅ combat-system.md
6. ✅ world-streaming-system.md
7. ✅ experience-system.md
8. ✅ health-defense-system.md

### Other System GDDs
9. attribute-point-allocation-system.md
10. combat-ui.md
11. damage-calculation-system.md
12. economy-system.md
13. encounter-condition-check-system.md
14. encounter-history-record-system.md
15. encounter-system.md
16. enemy-ai-system.md
17. equipment-attribute-calculation.md
18. equipment-slot-system.md
19. equipment-system.md
20. equipment-ui.md
21. fast-travel-system.md
22. growth-data-persistence.md
23. hit-detection-system.md
24. internal-energy-management-system.md
25. lod-system.md
26. martial-arts-combo-system.md
27. martial-arts-system.md
28. minimap-system.md
29. open-world-exploration-system.md
30. point-of-interest-tracking-system.md
31. quest-system.md
32. random-event-generator.md
33. reward-distribution-system.md
34. skill-tree-learning-path-system.md
35. status-effect-system.md
36. world-state-persistence-system.md

### Meta Documents (Excluded from scan)
- game-concept.md
- systems-index.md
- gdd-cross-review-2026-04-28.md
- consistency-check-report.md

---

## Recommended Next Steps

### 1. Populate the Registry

The registry should be populated with cross-system facts from the GDDs. Based on the recent design decisions (2026-04-28), the following categories need registration:

#### **Constants to Register**

From `design-decisions-2026-04-28.md` and updated GDDs:

| Constant Name | Value | Unit | Source GDD | Referenced By |
|---------------|-------|------|------------|---------------|
| `MAX_LEVEL` | 99 | levels | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `ATTRIBUTE_POINTS_PER_LEVEL` | 5 | points | character-progression-system.md | level-up-mechanism.md |
| `TOTAL_ATTRIBUTE_POINTS` | 495 | points | character-progression-system.md | level-up-mechanism.md |
| `REALM_COUNT` | 9 | realms | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `REALM_BREAKTHROUGH_BONUS` | 0.10 | percentage | character-progression-system.md | level-up-mechanism.md |
| `ELEMENT_COUNTER_MULTIPLIER` | 1.5 | multiplier | combat-system.md | damage-calculation-system.md, martial-arts-system.md |
| `QI_RECOVERY_RATE_MIN` | 0.05 | percentage | combat-system.md | internal-energy-management-system.md |
| `QI_RECOVERY_RATE_MAX` | 0.10 | percentage | combat-system.md | internal-energy-management-system.md |
| `WORLD_CHUNK_SIZE` | 2048 | pixels | world-streaming-system.md | lod-system.md, minimap-system.md |
| `LOAD_DISTANCE_MULTIPLIER` | 1.5 | screen_width | world-streaming-system.md | lod-system.md |
| `UNLOAD_DISTANCE_MULTIPLIER` | 4.5 | screen_width | world-streaming-system.md | lod-system.md |
| `MAX_LOADED_CHUNKS` | 16 | chunks | world-streaming-system.md | lod-system.md |
| `MEMORY_BUDGET` | 1024 | MB | control-manifest.md | All systems |
| `TARGET_FPS` | 60 | fps | control-manifest.md | All systems |

#### **Formulas to Register**

From `combat-system.md` and `damage-calculation-system.md`:

| Formula Name | Variables | Output Range | Source GDD | Referenced By |
|--------------|-----------|--------------|------------|---------------|
| `final_damage_formula` | base_damage, crit_multiplier, combo_multiplier, weakness_multiplier, break_multiplier, status_multiplier, random_variance, element_multiplier | [5, 3000] | combat-system.md | damage-calculation-system.md, martial-arts-system.md |
| `max_hp_formula` | base_hp, con_stat, hp_coefficient, equipment_bonus | [100, 2000] | health-defense-system.md | character-progression-system.md |
| `max_poise_formula` | base_poise, will_stat, poise_coefficient, equipment_bonus | [50, 800] | health-defense-system.md | combat-system.md, character-progression-system.md |
| `exp_to_level_formula` | base_value, level, exponent_coefficient | [100, 50000] | experience-system.md | level-up-mechanism.md |

#### **Entities to Register**

From `character-progression-system.md`:

| Entity Name | Type | Attributes | Source GDD | Referenced By |
|-------------|------|------------|------------|---------------|
| `Realm_Early_Qi_Refining` | realm | level_range: [1, 11], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Late_Qi_Refining` | realm | level_range: [12, 22], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Early_Foundation_Building` | realm | level_range: [23, 33], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Late_Foundation_Building` | realm | level_range: [34, 44], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Early_Golden_Core` | realm | level_range: [45, 55], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Late_Golden_Core` | realm | level_range: [56, 66], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Early_Nascent_Soul` | realm | level_range: [67, 77], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Late_Nascent_Soul` | realm | level_range: [78, 88], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |
| `Realm_Spirit_Transformation` | realm | level_range: [89, 99], bonus: 0.10 | character-progression-system.md | level-up-mechanism.md, experience-system.md |

#### **Attributes to Register**

From `character-progression-system.md` and `control-manifest.md`:

| Attribute Name | Abbreviation | Effects | Source GDD | Referenced By |
|----------------|--------------|---------|------------|---------------|
| `Strength` | STR | physical_damage: +2, carry_weight: +5kg, armor_penetration: +1 | character-progression-system.md | combat-system.md, equipment-system.md |
| `Agility` | AGI | evasion: +0.5%, action_speed: +1%, movement_speed: +0.5%, crit_rate: +0.3% | character-progression-system.md | combat-system.md, health-defense-system.md |
| `Constitution` | CON | max_hp: +20, physical_defense: +1, status_resistance: +0.5%, hp_regen: +0.5/sec | character-progression-system.md | health-defense-system.md |
| `Wisdom` | WIS | max_qi: +15, qi_regen: +0.3/sec, skill_proficiency: +1%, crit_damage: +1% | character-progression-system.md | combat-system.md, martial-arts-system.md |
| `Willpower` | WILL | max_poise: +10, block_success: +0.5%, control_resistance: +0.5%, mental_defense: +1 | character-progression-system.md | health-defense-system.md, combat-system.md |
| `Luck` | LUK | encounter_rate: +0.3%, rare_drop: +0.5%, crafting_success: +0.5%, crit_rate: +0.2% | character-progression-system.md | encounter-system.md, reward-distribution-system.md |

### 2. Run Consistency Check Again

After populating the registry with the above entries, run `/consistency-check` again to verify cross-document consistency.

### 3. Resolve Any Conflicts

If conflicts are found, resolve them by:
1. Identifying the authoritative source GDD (the one that "owns" the fact)
2. Updating other GDDs to match the source
3. Updating the registry if the source GDD has changed

---

## Manual Population Instructions

To populate the registry manually:

1. Open `design/registry/entities.yaml`
2. Add entries following the format shown in the file's comments
3. For each entry, specify:
   - `name`: The entity/item/formula/constant name
   - `status`: `active` or `deprecated`
   - `source`: The authoritative GDD file path
   - `referenced_by`: List of all GDD files that reference this entry
   - Relevant attributes (varies by type)
   - `added`: Today's date (2026-04-28)
   - `revised`: Empty string initially

4. Save the file and run `/consistency-check` again

---

## Automated Population Option

Alternatively, you can use the `/design-system` skill to write new GDDs, which automatically populates the registry as part of Phase 5 (after GDD sections are approved).

For existing GDDs that were written before the registry existed, manual population is required.

---

## Conclusion

**Current Status**: Registry is empty, consistency check cannot proceed.

**Action Required**: Populate `design/registry/entities.yaml` with cross-system facts from the GDDs listed above.

**Next Step**: After population, run `/consistency-check` to verify cross-document consistency.

---

**Report Generated**: 2026-04-28
**Skill Used**: consistency-check
**Verdict**: ⚠️ REGISTRY EMPTY — Manual population required before consistency check can run