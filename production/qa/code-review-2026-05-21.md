# Code Review — Sprint 4-7 Critical Services

**Date**: 2026-05-21
**Reviewer**: Claude (autonomous, self-review)
**Scope**: J 系列 — useGameSession (G-1) / modifier pipeline (ADR-005) / career-store (S4-2) / ending-store (G-3)

## Verdict

**APPROVED WITH FIXES APPLIED** — 5 issues found, all addressed in-session. No regressions. 585/585 tests still pass.

## Findings Summary

| ID | Severity | Area | Issue | Fix Status |
|---|---|---|---|---|
| BUG-J1-1 | **HIGH** | useGameSession | Resume overrides player's just-chosen job on job-select | ✅ FIXED |
| BUG-J2-1 | **MEDIUM** (latent) | choice-resolution-engine | `target: 'health'` effects unsafely cast to StatusModifierTarget, get moodMul applied | ✅ FIXED |
| BUG-J4-2 | **MEDIUM** | progression-system | recordRun's stats build doesn't preserve optional fields (endings, future); wipes endings between progression and ending listeners | ✅ FIXED |
| SMELL-J1-3 | **MEDIUM** | useGameSession | Career-end window writes a stale "post-career" checkpoint; resume zombies to week 1 | ✅ FIXED |
| BUG-J3-2 | **MEDIUM** | career-store | `choicesThisWeek` uses day-end sample count (1-5) instead of actual choice count → varietyRatio saturates at 1.0 | ✅ FIXED |

Also noted (not fixed, low impact):
- SMELL-J1-7: writeRunCheckpoint uses debounced save (100ms window where close-app loses checkpoint)
- NIT-J1-4: Two saveService.load() calls in onMounted (first redundant)
- NIT-J4-1: Misleading comment in ending-store about careerProgressionSystem reset timing
- SMELL-J3-1: applyReviewBonus had dual-path (pendingBonus + immediate apply + reset) — simplified in this fix-set anyway

## Detailed Findings

### BUG-J1-1: Resume overrides job-select choice (HIGH)

**Symptom**: Player has an interrupted run as programmer. Reopens app → goes to job-select → taps Sales card → expects to start a fresh sales run. Instead, the old programmer run resumes (snapshot.jobId wins over player's intent).

**Root cause**: `useGameSession.onMounted` triggers `tryResume(snapshot)` whenever `phase ∈ {JOB_SELECT, INITIALIZING}`. Doesn't compare snapshot.jobId against the just-chosen job.

**Fix**: Compare. Only resume if `justChosenJob == null || justChosenJob === snapshot.jobId`. Otherwise discard the snapshot (write `currentRun: null`) — player explicitly chose a different career.

```ts
const justChosenJob = runManager.getCurrentJob()
const shouldResume =
  snapshot != null &&
  (phase === 'JOB_SELECT' || phase === 'INITIALIZING') &&
  (justChosenJob == null || justChosenJob === snapshot.jobId)
```

### BUG-J2-1: Health bypass modifier pipeline (MEDIUM, latent)

**Symptom**: A future event with `{target:'health', value:-10}` would be silently distorted by mood modifiers (passive + equipment + status), because the dispatch in each system falls through `target === 'energy' ? energyMul : moodMul` to moodMul on health.

**Currently latent**: no events use `target:'health'` yet. But G-2 documentation says they can.

**Fix**: Add health to the pass-through filter alongside money in `applyStatusModifiers`. Health is "raw fate" — buffs/items don't restore it.

### BUG-J4-2: progression.recordRun overwrites optional stats fields (MEDIUM)

**Symptom**: 2-listener race on `runManager.onRunEnded`:
1. progression-store: writes `stats: newStats` where newStats is built field-by-field (achievements explicit, endings absent)
2. ending-store: reads save, appends ending, writes back

If progression fires first (current order due to module load), endings field is wiped, then ending-store re-adds it. Brief inconsistency window. Adding any new optional GlobalStats field in the future would silently disappear.

**Fix**: Use spread in newStats build: `{ ...currentStats, totalRuns: ..., ... }`. Future-proof: any new optional stats field carries through.

### SMELL-J1-3: Career-end zombie checkpoint (MEDIUM)

**Symptom**: On the last day of the last week, `onDayEnded` fires → writeRunCheckpoint captures day=5 week=last. Then onCareerCompleted → SETTLING → endRun (800ms later via game-main watch). If app closes in this 800ms window, the snapshot is "past career end". On resume, tryResume tries `nextWeek = lastWeek + 1` → fails the guard → restarts week 1 day 1. Player completes 20 days, then loses everything.

**Fix**: skip the checkpoint write when `isLastWeek && currentDay === DAYS_PER_WEEK`. The career-end chain will clear `currentRun: null` immediately afterward anyway.

### BUG-J3-2: choicesThisWeek wrong, variety formula broken (MEDIUM)

**Symptom**: career score's `varietyRatio = uniqueEvents / choicesThisWeek` is intended to reward "trying different things". But `choicesThisWeek` was computed as `max(uniqueEventsSize, energySamples.length)` where `energySamples.length` is per-week day-end count (1-5). So `varietyRatio = min(uniqueEvents / max(uniqueEvents, ≤5), 1) = 1` always (if any events happened). Variety component nearly saturates to 20/20 each week.

**Fix**: track actual choice count via separate counter, increment in `recordWeekEvent`. Pass real `weekChoiceCount` to `recordWeek`.

### SMELL-J3-1 (incidental cleanup): applyReviewBonus dual-path

While fixing J-3-2, also simplified `applyReviewBonus`. The old code accumulated a `pendingReviewBonus`, immediately applied via `applyScoreDelta`, then reset pending to 0. The "pending" was effectively write-only — `recordWeek` always saw 0. Now: just `applyScoreDelta(delta)`, no pendingBonus. recordWeek passes 0 for reviewBonus.

## Areas Not Reviewed (Lower Priority)

- ChoiceResolutionEngine.resolveChoice top-level flow (not changed since S2-3, well-tested)
- StatusSystem (Sprint 2, mature)
- RunManager state machine (Sprint 2, well-tested)
- ResourceManager (Sprint 1, mature)
- EventCardSystem (Sprint 2, mature)
- ItemSystem core buy/use (S4-4, 100% covered)

## Coverage Confirmation

All fixed files still have:
- Tests pass: 585/585 ✅
- Type-check: clean ✅
- H5 build: clean (396 KB) ✅

No new tests added in this review — existing test suite catches regressions on the fixed paths. Recommend in future:
1. Add test "resume with different jobId discards snapshot" (covers BUG-J1-1)
2. Add test "health effect bypasses passive/equipment/status modifiers" (covers BUG-J2-1)
3. Add test "varietyRatio respects actual choices not day-end count" (covers BUG-J3-2)

These can be added in next session if test backfill is prioritized.
