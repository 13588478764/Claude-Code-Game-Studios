/**
 * useGameSession — bootstrapping coordinator for a fresh game session.
 *
 * Orchestrates cross-service wiring + save/resume (G-1).
 *
 * Day-end ordering contract: salary listener registered BEFORE status tick listener.
 * TypedEventEmitter preserves insertion order via Set iteration.
 */

import { onMounted } from 'vue'
import type { Effect } from '@/types/resource'
import { resourceManager } from '@/stores/resource-store'
import { saveService } from '@/stores/save-store'
import { statusSystem } from '@/stores/status-store'
import { eventDataEngine } from '@/stores/event-data-store'
import { eventCardSystem } from '@/stores/event-card-store'
import { runManager } from '@/stores/run-store'
import { dayCycleSystem } from '@/stores/day-cycle-store'
import { itemSystem } from '@/stores/item-store'
import {
  careerProgressionSystem,
  recordWeekEvent
} from '@/stores/career-store'
import { getJobById } from '@/config/jobs'
import { DAYS_PER_WEEK, DEFAULT_WEEKS_PER_CAREER } from '@/types/day-cycle'
import type { RunSnapshot, SaveData } from '@/types/save'

const NEW_DAY_TRANSITION_MS = 1200

let wired = false

/**
 * G-1 + J-1: pure decision for what to do with a stored snapshot at mount.
 *
 *   - 'resume'         — snapshot's jobId matches current intent → restore it
 *   - 'discard'        — player just chose a different job → wipe stale snapshot
 *   - 'ignore'         — no snapshot, or phase isn't waiting for one
 *
 * Extracted as pure function so the J-1 regression scenario is unit-testable
 * without mounting Vue / the singleton service graph.
 */
export type ResumeDecision = 'resume' | 'discard' | 'ignore'
export function decideResumeAction(
  snapshot: RunSnapshot | null | undefined,
  phase: string,
  justChosenJob: string | null
): ResumeDecision {
  if (snapshot == null) return 'ignore'
  if (phase !== 'JOB_SELECT' && phase !== 'INITIALIZING') return 'ignore'
  if (justChosenJob == null) return 'resume'
  if (justChosenJob === snapshot.jobId) return 'resume'
  return 'discard'  // player picked different job → start fresh
}

/**
 * G-1: Write current run state to SaveData.currentRun. Called at every
 * onDayEnded — captures the player's state at day-boundary checkpoint.
 * Only writes while runManager is PLAYING (skip during DYING/SETTLING).
 *
 * J-1 fix: skip on career-end (last day of last week). Otherwise the
 * snapshot points past career-end and resume zombie-restarts at week 1.
 * progression.recordRun will null out currentRun immediately after anyway.
 */
function writeRunCheckpoint(): void {
  if (runManager.getPhase() !== 'PLAYING') return
  const jobId = runManager.getCurrentJob()
  if (jobId == null) return
  if (dayCycleSystem.isLastWeek() && dayCycleSystem.getCurrentDay() === DAYS_PER_WEEK) {
    return  // career-end — let endRun clear currentRun
  }
  const snapshot: RunSnapshot = {
    jobId,
    weekIndex: dayCycleSystem.getWeekIndex(),
    day: dayCycleSystem.getCurrentDay(),
    doneInDay: dayCycleSystem.getProgress().done,
    resources: { ...resourceManager.getResources() },
    totalChoices: runManager.getRunStats().totalChoices,
    uniqueEventIds: [],  // not exposed; resume accepts a stale rating
    depletionSource: null,
    startedAt: Date.now(),
    career: careerProgressionSystem.getSnapshot(),
    statuses: statusSystem.getSnapshot(),
    inventory: itemSystem.getInventory(),
    equipped: itemSystem.getAllEquipped()
  }
  const cur = saveService.load()
  const base: SaveData = cur ?? {
    version: 1,
    jobUnlocks: ['intern', 'programmer'],
    currentRun: null,
    stats: {
      totalRuns: 0, totalWins: 0, totalDeaths: 0,
      totalMoneyEarned: 0, jobsPlayed: {}, achievements: []
    },
    updatedAt: 0
  }
  saveService.save({ ...base, currentRun: snapshot })
}

function wireServices(): void {
  if (wired) return
  wired = true

  // Day-end ordering contract: salary FIRST, then status tick.
  // S4-2 + S4-10: salary = base × jobConfig.salaryMul × careerLevel multiplier.
  dayCycleSystem.onDayEnded.on((event) => {
    const jobId = runManager.getCurrentJob()
    const job = jobId != null ? getJobById(jobId) : undefined
    const jobMul = job?.salaryMul ?? 1.0
    const careerMul = careerProgressionSystem.getSalaryMultiplier()
    const scaledSalary = Math.round(event.salary * jobMul * careerMul)
    const effects: Effect[] = [{ target: 'money', value: scaledSalary }]
    // G-2: CRISIS state at day end → -5 health (overwork penalty).
    if (resourceManager.getState() === 'CRISIS') {
      effects.push({ target: 'health', value: -5 })
    }
    resourceManager.applyEffects(effects)
  })
  statusSystem.subscribeToDayEnded(dayCycleSystem.onDayEnded)

  // Event-card per-queue advance → drive dayCycleSystem
  eventCardSystem.onQueueCardAdvanced.on(() => {
    dayCycleSystem.eventCompleted()
  })

  // S4-2: feed event ids into career store for weekly variety scoring
  eventCardSystem.onChoiceMade.on((event) => {
    recordWeekEvent(event.card.id)
  })

  // S4-1: RunManager subscribes to career-completed
  runManager.subscribeToCareerCompleted(dayCycleSystem.onCareerCompleted)

  // Status tracking: every successful resolve increments choice count
  eventCardSystem.onChoiceMade.on((event) => {
    runManager.trackChoice(event.card.id)
  })

  // G-1: write checkpoint at every day boundary (subscribed LAST so all
  // prior listeners — salary, status tick, autoplay scheduling — have
  // executed and state is settled before snapshot capture).
  dayCycleSystem.onDayEnded.on(() => {
    writeRunCheckpoint()
  })

  // S4-1: Auto-advance to next day OR next week after current day completes.
  dayCycleSystem.onDayEnded.on((event) => {
    if (event.day < DAYS_PER_WEEK) {
      setTimeout(() => {
        if (runManager.getPhase() === 'PLAYING') {
          dayCycleSystem.startDay(event.day + 1)
        }
      }, NEW_DAY_TRANSITION_MS)
      return
    }
    if (!dayCycleSystem.isLastWeek()) {
      setTimeout(() => {
        if (runManager.getPhase() === 'PLAYING') {
          dayCycleSystem.startWeek(dayCycleSystem.getWeekIndex() + 1)
          dayCycleSystem.startDay(1)
        }
      }, NEW_DAY_TRANSITION_MS)
    }
  })

  // S4-3: last day of every week, force the last event slot to a
  // weekend-review-tagged event.
  dayCycleSystem.onDayStarted.on((event) => {
    // M-1: pass live draw context so conditional events can fire when their
    // criteria match (low-money crisis, late-career milestone, etc.)
    const resources = resourceManager.getResources()
    const ctx = {
      day: event.day,
      weekIndex: dayCycleSystem.getWeekIndex(),
      money: resources.money,
      health: resources.health,
      careerLevel: careerProgressionSystem.getLevel(),
      jobId: runManager.getCurrentJob() ?? undefined,
      activeBuffIds: [
        statusSystem.getBuff()?.id,
        statusSystem.getDebuff()?.id
      ].filter((id): id is string => id != null)
    }
    eventCardSystem.prepareDay(event.day, event.total, { context: ctx })
    if (event.day === DAYS_PER_WEEK) {
      eventCardSystem.swapLastQueueCard(['weekend-review'])
    }
  })
}

/**
 * G-1: attempt to resume from a saved checkpoint. Returns true if resumed
 * (and bootstrap should be skipped); false if save was empty/invalid and
 * caller should bootstrap normally.
 */
function tryResume(snapshot: RunSnapshot): boolean {
  const job = getJobById(snapshot.jobId)
  if (!job) return false  // job removed from catalog — abandon snapshot

  // Restore resources (handles old saves that pre-date health field)
  resourceManager.init({
    energy: snapshot.resources.energy,
    mood: snapshot.resources.mood,
    money: snapshot.resources.money,
    health: snapshot.resources.health ?? 100
  })
  // Restore status slots
  if (snapshot.statuses) {
    statusSystem.loadSnapshot(snapshot.statuses)
  }
  // Restore career
  if (snapshot.career) {
    careerProgressionSystem.loadSnapshot(snapshot.career)
  }
  // Restore inventory + equipped
  if (snapshot.inventory) {
    itemSystem.loadInventory(snapshot.inventory)
  }
  if (snapshot.equipped) {
    itemSystem.loadEquipped(snapshot.equipped)
  }

  // RunManager transition: JOB_SELECT → INITIALIZING → PLAYING
  if (runManager.getPhase() === 'JOB_SELECT') {
    runManager.selectJob(snapshot.jobId)
  }
  runManager.startPlaying()

  // DayCycle: configure career, jump to next day after checkpoint
  dayCycleSystem.configure(job.weeksPerCareer ?? DEFAULT_WEEKS_PER_CAREER)
  const savedWeek = snapshot.weekIndex ?? 1
  const savedDay = snapshot.day
  // Snapshot captured AT end of day N → resume at day N+1 (or week+1, day 1)
  let nextWeek = savedWeek
  let nextDay = savedDay + 1
  if (nextDay > DAYS_PER_WEEK) {
    nextWeek += 1
    nextDay = 1
  }
  // Safety: if save was at very end of career, treat as fresh week 1 day 1
  if (nextWeek > (job.weeksPerCareer ?? DEFAULT_WEEKS_PER_CAREER)) {
    nextWeek = 1
    nextDay = 1
  }
  dayCycleSystem.startWeek(nextWeek)
  dayCycleSystem.startDay(nextDay)
  return true
}

/**
 * Hook for the GameMain page. Wires services, loads data, and either resumes
 * from a checkpoint or bootstraps a fresh run.
 */
export function useGameSession() {
  wireServices()

  onMounted(async () => {
    saveService.load()

    const jobId = runManager.getCurrentJob() ?? 'programmer'

    try {
      await eventDataEngine.loadCommon()
    } catch (err) {
      console.error('[useGameSession] common events load failed:', err)
    }

    // G-1 + J-1 fix: try resume only if the snapshot's jobId matches what
    // the player just chose on job-select (or there was no choice — i.e.
    // direct app re-launch). If player chose a DIFFERENT job, treat as
    // intentional "start fresh" and discard the stale snapshot.
    const save = saveService.load()
    const snapshot = save?.currentRun ?? null
    const phase = runManager.getPhase()
    const justChosenJob = runManager.getCurrentJob()  // null if direct launch

    const decision = decideResumeAction(snapshot, phase, justChosenJob)

    if (decision === 'resume' && snapshot) {
      try {
        await eventDataEngine.loadJobEvents(snapshot.jobId)
      } catch (err) {
        console.error(`[useGameSession] ${snapshot.jobId} resume events load failed:`, err)
      }
      const resumed = tryResume(snapshot)
      if (resumed) return
    } else if (decision === 'discard' && save) {
      // Player explicitly picked a different job — abandon old run cleanly.
      saveService.save({ ...save, currentRun: null })
    }

    // Fresh bootstrap path
    try {
      await eventDataEngine.loadJobEvents(jobId)
    } catch (err) {
      console.error(`[useGameSession] ${jobId} events load failed:`, err)
    }

    if (phase === 'JOB_SELECT' || phase === 'INITIALIZING') {
      const job = getJobById(jobId)
      resourceManager.init({
        energy: job?.initialEnergy ?? 80,
        mood: job?.initialMood ?? 60,
        money: 0,
        health: 100
      })
      if (runManager.getPhase() === 'JOB_SELECT') {
        runManager.selectJob(jobId)
      }
      runManager.startPlaying()
      dayCycleSystem.configure(job?.weeksPerCareer ?? DEFAULT_WEEKS_PER_CAREER)
      dayCycleSystem.startWeek(1)
      dayCycleSystem.startDay(1)
    }
  })
}
