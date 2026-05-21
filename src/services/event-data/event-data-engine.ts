/**
 * EventDataEngine — loads, validates, and serves event cards.
 * Implements ADR-001 (event-driven) and ADR-002 (subpackage strategy).
 */

import { TypedEventEmitter } from '../common/event-emitter'
import { validateEventList } from './event-schema'
import { FALLBACK_EVENTS } from './fallback-events'
import type {
  EventCard,
  EventCondition,
  EventDrawContext,
  EventFilter
} from '@/types/event'

export interface EventLoader {
  loadCommon(): Promise<unknown>
  loadJob(jobId: string): Promise<unknown>
}

// Buffer occupies ~75% of one week's events (16 total) so a single event
// can't repeat more than once per week with the current pool size. Smaller
// values (e.g. 5) made hot-weight events repeat 2-3× per playthrough.
const RECENT_BUFFER_SIZE = 12
const MAX_RETRIES = 3

export class EventDataEngine {
  private loader: EventLoader
  private commonEvents: EventCard[] = []
  private jobEvents: Map<string, EventCard[]> = new Map()
  private currentJobId: string | null = null
  private recent: string[] = []  // last N event IDs drawn

  readonly onLoadComplete = new TypedEventEmitter<{ jobId: string | 'common'; count: number }>()
  readonly onLoadFailed = new TypedEventEmitter<{ jobId: string | 'common'; reason: string }>()

  constructor(loader: EventLoader) {
    this.loader = loader
  }

  async loadCommon(): Promise<void> {
    const data = await this.tryLoad(() => this.loader.loadCommon(), 'common')
    if (data == null) {
      this.commonEvents = [...FALLBACK_EVENTS]
      this.onLoadComplete.emit({ jobId: 'common', count: this.commonEvents.length })
      return
    }
    this.commonEvents = validateEventList(data)
    if (this.commonEvents.length === 0) {
      this.commonEvents = [...FALLBACK_EVENTS]
    }
    this.onLoadComplete.emit({ jobId: 'common', count: this.commonEvents.length })
  }

  async loadJobEvents(jobId: string): Promise<void> {
    const data = await this.tryLoad(() => this.loader.loadJob(jobId), jobId)
    if (data == null) {
      // If job-specific load fails entirely, leave only common events as fallback
      this.jobEvents.set(jobId, [])
      this.currentJobId = jobId
      return
    }
    const valid = validateEventList(data)
    this.jobEvents.set(jobId, valid)
    this.currentJobId = jobId
    this.onLoadComplete.emit({ jobId, count: valid.length })
  }

  unload(): void {
    if (this.currentJobId) {
      this.jobEvents.delete(this.currentJobId)
      this.currentJobId = null
    }
    this.recent = []
  }

  /**
   * Draw an event using weighted random with recent-event filtering.
   * Pool = common events + current job events.
   */
  drawEvent(filter?: EventFilter): EventCard {
    const pool = this.buildPool(filter)
    if (pool.length === 0) {
      // Last-resort fallback
      return FALLBACK_EVENTS[Math.floor(Math.random() * FALLBACK_EVENTS.length)]!
    }

    const totalWeight = pool.reduce((sum, e) => sum + (e.weight ?? 1), 0)
    let target = Math.random() * totalWeight
    for (const e of pool) {
      target -= (e.weight ?? 1)
      if (target <= 0) {
        this.markRecent(e.id)
        return e
      }
    }
    // Numerical fallback (should not normally hit)
    const last = pool[pool.length - 1]!
    this.markRecent(last.id)
    return last
  }

  getEventById(id: string): EventCard | null {
    for (const e of this.commonEvents) if (e.id === id) return e
    for (const list of this.jobEvents.values()) {
      for (const e of list) if (e.id === id) return e
    }
    return null
  }

  getCommonCount(): number { return this.commonEvents.length }
  getJobCount(jobId: string): number { return this.jobEvents.get(jobId)?.length ?? 0 }

  private buildPool(filter?: EventFilter): EventCard[] {
    const recentExclude = new Set(this.recent)
    const explicitExclude = new Set(filter?.excludeIds ?? [])
    const jobId = filter?.jobId ?? this.currentJobId
    const context = filter?.context

    const matches = (e: EventCard, allowRecent: boolean): boolean => {
      if (explicitExclude.has(e.id)) return false
      if (!allowRecent && recentExclude.has(e.id)) return false
      if (filter?.tags && filter.tags.length > 0) {
        if (!e.tags || !e.tags.some((t) => filter.tags!.includes(t))) return false
      }
      // M-1: evaluate EventCondition entries against draw context. Cards
      // with no conditions always match. Missing context fields fall back
      // to "condition not enforced" (preserve old behavior for callers
      // that don't pass context).
      if (e.conditions && e.conditions.length > 0) {
        for (const cond of e.conditions) {
          if (!evaluateCondition(cond, context)) return false
        }
      }
      return true
    }

    const collect = (allowRecent: boolean): EventCard[] => {
      const out: EventCard[] = []
      for (const e of this.commonEvents) {
        if (matches(e, allowRecent)) out.push(e)
      }
      if (jobId) {
        const list = this.jobEvents.get(jobId) ?? []
        for (const e of list) {
          if (matches(e, allowRecent)) out.push(e)
        }
      }
      return out
    }

    // First try strict (excludes recent). If empty, relax recent filter
    // but still respect tag/explicit-exclude filters.
    const strict = collect(false)
    if (strict.length > 0) return strict
    return collect(true)
  }

  private markRecent(id: string): void {
    this.recent.push(id)
    if (this.recent.length > RECENT_BUFFER_SIZE) {
      this.recent.shift()
    }
  }

  private async tryLoad<T>(fn: () => Promise<T>, label: string): Promise<T | null> {
    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
      try {
        return await fn()
      } catch (err) {
        if (attempt === MAX_RETRIES) {
          this.onLoadFailed.emit({
            jobId: label as 'common' | string,
            reason: String(err)
          })
          return null
        }
      }
    }
    return null
  }
}

/**
 * M-1: pure evaluator for EventCondition against EventDrawContext.
 * Exported for testability. A missing context field means "don't enforce" —
 * conservative fallback so callers that don't yet pass context aren't
 * silently filtering cards.
 */
export function evaluateCondition(
  cond: EventCondition,
  ctx: EventDrawContext | undefined
): boolean {
  if (!ctx) return true
  const v = cond.value
  switch (cond.type) {
    case 'minDay':         return ctx.day == null || ctx.day >= (v as number)
    case 'maxDay':         return ctx.day == null || ctx.day <= (v as number)
    case 'minWeek':        return ctx.weekIndex == null || ctx.weekIndex >= (v as number)
    case 'maxWeek':        return ctx.weekIndex == null || ctx.weekIndex <= (v as number)
    case 'minMoney':       return ctx.money == null || ctx.money >= (v as number)
    case 'maxMoney':       return ctx.money == null || ctx.money <= (v as number)
    case 'minHealth':      return ctx.health == null || ctx.health >= (v as number)
    case 'maxHealth':      return ctx.health == null || ctx.health <= (v as number)
    case 'minCareerLevel': return ctx.careerLevel == null || ctx.careerLevel >= (v as number)
    case 'maxCareerLevel': return ctx.careerLevel == null || ctx.careerLevel <= (v as number)
    case 'job':            return ctx.jobId == null || ctx.jobId === v
    case 'hasBuff':        return ctx.activeBuffIds == null || ctx.activeBuffIds.includes(v as string)
    default:               return true
  }
}
