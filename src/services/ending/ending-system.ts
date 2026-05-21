/**
 * EndingSystem (G-3) — tracks unlocked endings per save.
 *
 * Pure TS service. Mirrors AchievementSystem pattern. Resolution itself
 * (which ending fires for a given run) lives in types/ending.resolveEnding
 * — this service only handles persistence + emit.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  getEndingById,
  resolveEnding,
  type Ending,
  type EndingContext
} from '@/types/ending'

export class EndingSystem {
  private unlocked: Set<string> = new Set()

  readonly onEndingUnlocked = new TypedEventEmitter<{
    endingId: string
    isFirstTime: boolean
  }>()
  readonly onRunEnded = new TypedEventEmitter<{
    endingId: string
    ending: Ending
  }>()

  /** Initialize from save. Unknown ids dropped silently. */
  init(unlockedIds: string[] = []): void {
    this.unlocked = new Set(unlockedIds.filter((id) => getEndingById(id)))
  }

  hasEnding(id: string): boolean {
    return this.unlocked.has(id)
  }

  getUnlocked(): string[] {
    return Array.from(this.unlocked)
  }

  getUnlockedCount(): number {
    return this.unlocked.size
  }

  /**
   * Resolve + record the ending for a finished run.
   * Always fires onRunEnded; fires onEndingUnlocked only on first-time unlock.
   * Returns the resolved ending.
   */
  recordEnding(ctx: EndingContext): Ending {
    const ending = resolveEnding(ctx)
    const isFirstTime = !this.unlocked.has(ending.id)
    if (isFirstTime) {
      this.unlocked.add(ending.id)
    }
    this.onRunEnded.emit({ endingId: ending.id, ending })
    this.onEndingUnlocked.emit({ endingId: ending.id, isFirstTime })
    return ending
  }
}
