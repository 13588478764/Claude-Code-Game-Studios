/**
 * J-1 regression — decideResumeAction pure function.
 *
 * Bug it guards: if the player has an interrupted run as programmer and
 * reopens the app → goes to job-select → taps Sales card, the resume code
 * previously used snapshot.jobId blindly. So a stale snapshot would zombie
 * the player's freshly-chosen Sales run back into programmer.
 *
 * Contract:
 *  - no snapshot → 'ignore'
 *  - phase not waiting for resume → 'ignore'
 *  - direct re-launch (justChosenJob=null) + matching snapshot → 'resume'
 *  - player picked SAME job as snapshot → 'resume'
 *  - player picked DIFFERENT job than snapshot → 'discard'
 */

import { describe, test, expect } from 'vitest'
import { decideResumeAction } from '@/composables/useGameSession'
import type { RunSnapshot } from '@/types/save'

function makeSnapshot(jobId: string): RunSnapshot {
  return {
    jobId,
    weekIndex: 1,
    day: 3,
    doneInDay: 0,
    resources: { energy: 60, mood: 50, money: 100, health: 80 },
    totalChoices: 5,
    uniqueEventIds: [],
    depletionSource: null,
    startedAt: Date.now()
  }
}

describe('decideResumeAction — no snapshot', () => {
  test('null snapshot → ignore (no work to do)', () => {
    expect(decideResumeAction(null, 'JOB_SELECT', null)).toBe('ignore')
    expect(decideResumeAction(null, 'JOB_SELECT', 'programmer')).toBe('ignore')
  })

  test('undefined snapshot → ignore', () => {
    expect(decideResumeAction(undefined, 'JOB_SELECT', null)).toBe('ignore')
  })
})

describe('decideResumeAction — phase gating', () => {
  test('phase=PLAYING → ignore (already in a run)', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'PLAYING', null)).toBe('ignore')
  })

  test('phase=SETTLING → ignore', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'SETTLING', null)).toBe('ignore')
  })

  test('phase=JOB_SELECT → considered', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'JOB_SELECT', null)).toBe('resume')
  })

  test('phase=INITIALIZING → considered', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'INITIALIZING', null)).toBe('resume')
  })
})

describe('decideResumeAction — jobId matching (J-1 regression)', () => {
  test('direct app re-launch (no jobChosen) + snapshot → resume', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'JOB_SELECT', null)).toBe('resume')
  })

  test('player chose SAME job as snapshot → resume', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'JOB_SELECT', 'programmer')).toBe('resume')
  })

  test('player chose DIFFERENT job than snapshot → discard (J-1 fix)', () => {
    const snap = makeSnapshot('programmer')
    expect(decideResumeAction(snap, 'JOB_SELECT', 'sales')).toBe('discard')
  })

  test('discard works during INITIALIZING phase too', () => {
    const snap = makeSnapshot('intern')
    expect(decideResumeAction(snap, 'INITIALIZING', 'designer')).toBe('discard')
  })
})
