/**
 * AchievementSystem (C-2) — permanent cross-run unlocks.
 *
 * Pure TS service. Mirrors PassiveSkillSystem (S3-9):
 *   - Catalog from types/achievement.ts ACHIEVEMENTS
 *   - Unlocked ids persisted via SaveData.stats.achievements (existing string[])
 *   - checkUnlocks(stats) called on progression.onProgressRecorded
 *
 * UnlockSkill direct API also available for save migration / event-driven
 * unlocks (e.g. special hidden achievements triggered by specific events).
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  ACHIEVEMENTS,
  evaluateAchievementCondition,
  getAchievementById,
  type Achievement
} from '@/types/achievement'
import type { GlobalStats } from '@/types/save'

export class AchievementSystem {
  private unlocked: Set<string> = new Set()

  readonly onAchievementUnlocked = new TypedEventEmitter<{
    achievementId: string
  }>()

  /** Initialize from save. Unknown ids in the save are silently dropped. */
  init(unlockedIds: string[] = []): void {
    this.unlocked = new Set(unlockedIds.filter((id) => getAchievementById(id)))
  }

  hasAchievement(id: string): boolean {
    return this.unlocked.has(id)
  }

  getUnlocked(): string[] {
    return Array.from(this.unlocked)
  }

  getUnlockedAchievements(): Achievement[] {
    return this.getUnlocked()
      .map((id) => getAchievementById(id))
      .filter((a): a is Achievement => a != null)
  }

  /**
   * Manual unlock — returns true if newly unlocked.
   * Used for special / hidden achievements not driven by stats.
   */
  unlockAchievement(id: string): boolean {
    if (!getAchievementById(id)) return false
    if (this.unlocked.has(id)) return false
    this.unlocked.add(id)
    this.onAchievementUnlocked.emit({ achievementId: id })
    return true
  }

  /**
   * Check every locked achievement against current stats; emit + return
   * newly-unlocked ids.
   */
  checkUnlocks(stats: GlobalStats): string[] {
    const newly: string[] = []
    for (const achievement of ACHIEVEMENTS) {
      if (this.unlocked.has(achievement.id)) continue
      if (evaluateAchievementCondition(achievement.unlockCondition, stats)) {
        this.unlocked.add(achievement.id)
        this.onAchievementUnlocked.emit({ achievementId: achievement.id })
        newly.push(achievement.id)
      }
    }
    return newly
  }
}
