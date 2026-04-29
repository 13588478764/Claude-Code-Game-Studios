# Smoke Test: Critical Paths

**Purpose**: Run these 15-20 checks in under 15 minutes before any QA hand-off.  
**Run via**: `/smoke-check` (which reads this file)  
**Update**: Add new entries when new core systems are implemented.  
**Last Updated**: 2026-04-28

---

## Core Stability (Always Run)

These tests verify that the game can launch and basic functionality works.

- [ ] **1. Game launches to main menu without crash**
  - Action: Start the game
  - Expected: Main menu appears without errors
  - Notes: Check console for any error messages

- [ ] **2. New game can be started from main menu**
  - Action: Click "New Game" button
  - Expected: Game loads to first scene without crash
  - Notes: Verify character creation or initial scene loads

- [ ] **3. Main menu responds to all inputs without freezing**
  - Action: Click all buttons, navigate menus
  - Expected: Responsive UI, no freezing or lag
  - Notes: Check for input lag or unresponsive buttons

- [ ] **4. Game can be paused and resumed**
  - Action: Press ESC or pause button during gameplay
  - Expected: Game pauses, UI shows pause menu, can resume
  - Notes: Verify pause state is properly managed

- [ ] **5. Settings menu is accessible and functional**
  - Action: Open settings from main menu
  - Expected: Can adjust volume, graphics, controls
  - Notes: Verify settings persist after closing

---

## Core Mechanics (Update Per Sprint)

These tests verify the primary game mechanics for the current sprint.

### Sprint 1: Character Progression & Combat

- [ ] **6. Character can gain experience and level up**
  - Action: Defeat enemies or complete quests to gain experience
  - Expected: Character level increases, attributes update
  - Notes: Verify level cap (99) is enforced

- [ ] **7. Attribute points are awarded on level up**
  - Action: Level up character
  - Expected: Character receives 5 attribute points per level
  - Notes: Verify points are available for allocation

- [ ] **8. Attributes can be allocated to six dimensions**
  - Action: Open attribute allocation UI, allocate points
  - Expected: Points decrease, attributes increase
  - Notes: Verify all six attributes (力道、身法、根骨、悟性、定力、福缘) work

- [ ] **9. Combat system initiates and completes**
  - Action: Encounter an enemy, complete combat
  - Expected: Combat UI appears, actions execute, combat ends
  - Notes: Verify turn order, damage calculation, victory/defeat

- [ ] **10. Equipment can be equipped and affects stats**
  - Action: Equip an item, check character stats
  - Expected: Equipment bonus applies to attributes
  - Notes: Verify stat calculation is correct

---

## Data Integrity (Always Run)

These tests verify that game data is saved and loaded correctly.

- [ ] **11. Game can be saved without error**
  - Action: Play for a few minutes, save game
  - Expected: Save completes without error message
  - Notes: Check save file exists in expected location

- [ ] **12. Game can be loaded and restores correct state**
  - Action: Load saved game
  - Expected: Character level, attributes, inventory match saved state
  - Notes: Verify all data is correctly restored

- [ ] **13. Multiple save slots work independently**
  - Action: Create saves in different slots, load each
  - Expected: Each slot has independent data
  - Notes: Verify no data corruption between slots

- [ ] **14. Game state persists across scene changes**
  - Action: Move between scenes/areas
  - Expected: Character data, inventory, progress maintained
  - Notes: Verify no data loss on scene transitions

---

## Performance (Always Run)

These tests verify that the game runs smoothly without performance issues.

- [ ] **15. Game maintains 60 FPS during normal gameplay**
  - Action: Play for 5 minutes, monitor frame rate
  - Expected: Consistent 60 FPS (or target frame rate)
  - Notes: Check for frame drops or stuttering

- [ ] **16. No memory leaks over 10 minutes of play**
  - Action: Monitor memory usage while playing
  - Expected: Memory usage remains stable
  - Notes: Use Godot profiler to check memory

- [ ] **17. UI responds smoothly without lag**
  - Action: Open/close menus, interact with UI elements
  - Expected: Instant response, smooth animations
  - Notes: Check for input lag or animation stuttering

- [ ] **18. No console errors or warnings**
  - Action: Play through smoke test, check console
  - Expected: No error messages in console
  - Notes: Warnings are acceptable, errors are not

---

## Optional: System-Specific Tests

Add system-specific smoke tests as new systems are implemented.

### Combat System (When Implemented)
- [ ] Combat initiates without crash
- [ ] Damage calculation produces expected values
- [ ] Status effects apply and expire correctly

### Quest System (When Implemented)
- [ ] Quest can be accepted and tracked
- [ ] Quest objectives update correctly
- [ ] Quest rewards are distributed on completion

### Economy System (When Implemented)
- [ ] Currency can be earned and spent
- [ ] Prices are calculated correctly
- [ ] Inventory limits are enforced

### World Exploration (When Implemented)
- [ ] Player can move freely in world
- [ ] Camera follows player correctly
- [ ] Collision detection works properly

---

## Smoke Test Execution Checklist

Before running smoke tests:

- [ ] Latest code is pulled from repository
- [ ] Project builds without errors
- [ ] All dependencies are installed
- [ ] Test environment is clean (no leftover save files)

During smoke tests:

- [ ] Run tests in order (core stability first)
- [ ] Document any failures with screenshots
- [ ] Note any warnings or unexpected behavior
- [ ] Record frame rate and memory usage

After smoke tests:

- [ ] All tests passed: ✅ **PASS** — Ready for QA
- [ ] Some tests failed: ⚠️ **PASS WITH WARNINGS** — Document issues
- [ ] Critical tests failed: ❌ **FAIL** — Fix issues before QA

---

## Failure Documentation

If any smoke test fails, document:

1. **Test Name**: Which test failed
2. **Steps to Reproduce**: Exact steps that caused failure
3. **Expected Result**: What should have happened
4. **Actual Result**: What actually happened
5. **Screenshot**: Visual evidence of failure
6. **Console Output**: Any error messages
7. **Severity**: Critical / High / Medium / Low

---

## Smoke Test Results Template

```
# Smoke Test Results - [Date]

**Tester**: [Name]  
**Build**: [Version/Commit]  
**Duration**: [Time taken]  
**Overall Result**: [PASS / PASS WITH WARNINGS / FAIL]

## Test Results

| # | Test | Result | Notes |
|---|------|--------|-------|
| 1 | Game launches | ✅ PASS | — |
| 2 | New game starts | ✅ PASS | — |
| ... | ... | ... | ... |

## Issues Found

[List any failures or warnings]

## Performance Metrics

- **Average FPS**: [Value]
- **Memory Usage**: [Value]
- **Load Time**: [Value]

## Sign-Off

- [ ] All critical tests passed
- [ ] No blocking issues found
- [ ] Ready for QA hand-off

**Signed**: [Name] | **Date**: [Date]
```

---

## Quick Reference

**Smoke Test Duration**: 10-15 minutes  
**Frequency**: Before every QA hand-off  
**Responsibility**: QA Lead or Developer  
**Escalation**: If FAIL, notify development team immediately

---

**Last Updated**: 2026-04-28  
**Next Review**: 2026-05-11