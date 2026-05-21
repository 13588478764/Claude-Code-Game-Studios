/**
 * PassiveSkillSystem — permanent, save-persisted modifiers stacked outside
 * the per-run status system.
 *
 * Modifier order at choice resolution (per S3-9 GDD):
 *   raw → passiveSkill.applyToEffect → status.applyToEffect → applyEffects
 *
 * Sprint 3 ships a single example skill ("厚脸皮 Lv1"); Sprint 4 expands the
 * full tree. Passives stack multiplicatively across all unlocked skills:
 *   value' = signFloor(raw × ∏skill.targetMul)
 *
 * Architecture: pure TS service, no Vue/Pinia imports. Mutations happen via
 * unlockSkill / checkUnlocks; Vue layer subscribes via PassiveSkillStore.
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  PASSIVE_SKILLS,
  evaluateUnlockCondition,
  getPassiveSkillById,
  type PassiveSkill,
  type PassiveSkillTarget
} from '@/types/passive-skill'
import type { GlobalStats } from '@/types/save'

/**
 * Sign-aware floor — rounds toward zero on both sides. Mirrors status-system's
 * signFloor (avoids JS Math.round's "round half toward +∞" asymmetry).
 */
function signFloor(value: number): number {
  if (value === 0) return 0
  const result = value > 0 ? Math.floor(value) : Math.ceil(value)
  return result === 0 ? 0 : result
}

export class PassiveSkillSystem {
  private unlocked: Set<string> = new Set()

  readonly onSkillUnlocked = new TypedEventEmitter<{ skillId: string }>()

  /**
   * Initialize from save. Called by store on app launch.
   * Unknown ids in the save (e.g. from a future build) are silently dropped.
   */
  init(unlockedIds: string[] = []): void {
    this.unlocked = new Set(unlockedIds.filter((id) => getPassiveSkillById(id)))
  }

  hasSkill(id: string): boolean {
    return this.unlocked.has(id)
  }

  getUnlocked(): string[] {
    return Array.from(this.unlocked)
  }

  getUnlockedSkills(): PassiveSkill[] {
    return this.getUnlocked()
      .map((id) => getPassiveSkillById(id))
      .filter((s): s is PassiveSkill => s != null)
  }

  /**
   * Apply all unlocked passives' modifiers for a target.
   * Money is pass-through (per status-system invariant — money has no Mul).
   * Identity (no skills, or no skills with this target's Mul) returns rawValue.
   */
  applyToEffect(target: PassiveSkillTarget, rawValue: number): number {
    const mul = this.getMulForTarget(target)
    if (mul === 1.0) return rawValue
    return signFloor(rawValue * mul)
  }

  /**
   * Mark a skill as unlocked + emit. No-op if id is unknown or already unlocked.
   * Returns true if newly unlocked.
   */
  unlockSkill(id: string): boolean {
    if (!getPassiveSkillById(id)) return false
    if (this.unlocked.has(id)) return false
    this.unlocked.add(id)
    this.onSkillUnlocked.emit({ skillId: id })
    return true
  }

  /**
   * Check every locked skill against current stats; emit for each newly unlocked.
   * Returns the list of newly-unlocked skill ids (parallel to JobRotationSystem).
   */
  checkUnlocks(stats: GlobalStats): string[] {
    const newly: string[] = []
    for (const skill of PASSIVE_SKILLS) {
      if (this.unlocked.has(skill.id)) continue
      if (evaluateUnlockCondition(skill.unlockCondition, stats)) {
        this.unlocked.add(skill.id)
        this.onSkillUnlocked.emit({ skillId: skill.id })
        newly.push(skill.id)
      }
    }
    return newly
  }

  private getMulForTarget(target: PassiveSkillTarget): number {
    const field: 'energyMul' | 'moodMul' =
      target === 'energy' ? 'energyMul' : 'moodMul'

    // Invariant (init + unlockSkill): every id in `unlocked` is registered.
    let product = 1.0
    for (const skill of this.getUnlockedSkills()) {
      const mul = skill[field]
      if (mul != null) product *= mul
    }
    return product
  }
}
