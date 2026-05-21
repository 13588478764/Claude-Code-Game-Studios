/**
 * ChoiceResolutionEngine — coordinates the choice → effect → resource → status
 * pipeline. See `design/gdd/choice-resolution.md` and `design/gdd/status-system.md`
 * v2.1 for the architectural rationale.
 *
 * KEY INVARIANT (status-system.md v2.1):
 *   applyToEffect → resourceApplyEffects → addStatus
 *
 * The buff added by THIS choice must not modify THIS choice's effects.
 * If addStatus ran before applyEffects, a "drink coffee + lose energy" choice
 * would see its own coffee buff reduce its own energy loss, which is nonsense.
 *
 * Architecture (per ADR-001 + ADR-003):
 *  - Stateless service — every call is self-contained
 *  - Constructor-injected deps for testability
 *  - All cross-service interactions go through deps; engine doesn't reach into
 *    statusSystem / resourceManager / saveService directly
 */

import type {
  Choice,
  EventCard,
  BuffSpec,
  RiskOutcome as RiskOutcomeSpec
} from '@/types/event'
import type { ApplyResult, Effect } from '@/types/resource'
import type { StatusEffect, StatusModifierTarget } from '@/types/status'
import type { ResolveDelta, ResolveResult, RiskOutcome } from '@/types/resolve'

export interface ChoiceResolutionDeps {
  /** statusSystem.applyToEffect — modify energy/mood effect values */
  statusApplyToEffect: (target: StatusModifierTarget, rawValue: number) => number
  /** statusSystem.addStatus — add buff after effects applied */
  statusAddStatus: (status: StatusEffect) => void
  /** resourceManager.applyEffects — apply final effects atomically */
  resourceApplyEffects: (effects: Effect[]) => ApplyResult
  /** Persist the choice to choice history (best-effort, can be no-op for MVP) */
  recordChoice: (eventId: string, choiceKey: 'A' | 'B') => void
  /** Risk dice roll — defaults to Math.random; injectable for deterministic tests */
  randomRoll?: () => number
  /**
   * S3-9 — passive skill modifiers. Optional: when present, applied BEFORE
   * statusApplyToEffect so the order is raw → passive → status → resource.
   * Unset = identity (preserves Sprint 1+2 behavior).
   */
  passiveApplyToEffect?: (target: StatusModifierTarget, rawValue: number) => number
  /**
   * C-1 — equipment modifiers (item-system slot occupants). Optional: when
   * present, applied AFTER passive but BEFORE status:
   *   raw → passive → equipment → status → resource
   * Unset = identity.
   */
  equipmentApplyToEffect?: (target: StatusModifierTarget, rawValue: number) => number
}

export class ChoiceResolutionEngine {
  constructor(private deps: ChoiceResolutionDeps) {}

  resolveChoice(card: EventCard, key: 'A' | 'B'): ResolveResult {
    const choice = key === 'A' ? card.choiceA : card.choiceB

    // Step 1: Risk roll (if applicable). Determines which effects/buff apply.
    const { effectsToApply, buffToApply, riskOutcome } = this.resolveRisk(choice)

    // Step 2: Apply status modifiers to effects (energy/mood only, money pass-through).
    const { modifiedEffects, anyModifiedByTarget } =
      this.applyStatusModifiers(effectsToApply)

    // Step 3: Apply final effects to resources (atomic).
    const applyResult = this.deps.resourceApplyEffects(modifiedEffects)

    // Step 4: AFTER effects applied — add buff (preserves invariant).
    if (buffToApply) {
      this.deps.statusAddStatus(buffSpecToStatus(buffToApply))
    }

    // Step 5: Record the choice (best-effort).
    this.deps.recordChoice(card.id, key)

    // Step 6: Build ResolveResult.
    return this.buildResult(
      choice,
      effectsToApply,
      applyResult,
      anyModifiedByTarget,
      riskOutcome
    )
  }

  // ============== Pipeline steps ==============

  private resolveRisk(choice: Choice): {
    effectsToApply: Effect[]
    buffToApply: BuffSpec | undefined
    riskOutcome: RiskOutcome | undefined
  } {
    if (!choice.risk) {
      return {
        effectsToApply: choice.effects,
        buffToApply: choice.buff,
        riskOutcome: undefined
      }
    }
    const roll = (this.deps.randomRoll ?? Math.random)()
    const outcome: RiskOutcome = roll < choice.risk.chance ? 'success' : 'fail'
    const outcomeSpec: RiskOutcomeSpec =
      outcome === 'success' ? choice.risk.success : choice.risk.fail
    return {
      effectsToApply: outcomeSpec.effects,
      // Risk outcome can carry its own buff; falls back to choice.buff if not.
      buffToApply: outcomeSpec.buff ?? choice.buff,
      riskOutcome: outcome
    }
  }

  /**
   * Apply passive → equipment → status modifiers per effect. Tracks whether
   * any effect for each target was modified by status — used to set
   * wasStatusModified on the per-target ResolveDelta in the final result.
   *
   * Pipeline (S3-9 + C-1): raw → passive → equipment → status → resource.
   * Money is pass-through for all three layers (per status-system.md v2.1).
   * wasStatusModified specifically tracks status (not passive nor equipment)
   * to preserve S2-3 chip-pulse semantics — passive + equipment are permanent
   * modifiers, no per-resolve UI cue.
   */
  private applyStatusModifiers(effects: Effect[]): {
    modifiedEffects: Effect[]
    anyModifiedByTarget: Map<string, boolean>
  } {
    const anyModifiedByTarget = new Map<string, boolean>()
    const modified: Effect[] = effects.map((fx) => {
      // J-2 fix: money + health bypass all modifier layers. Money has no
      // semantic notion of "boosted" (it's currency); health is an
      // irreversible vitality gauge (G-2 design — buffs don't restore it).
      // StatusModifierTarget only covers energy|mood so the cast below
      // would be unsafe for health.
      if (fx.target === 'money' || fx.target === 'health') {
        return fx
      }
      const target = fx.target as StatusModifierTarget
      // Step A: passive (permanent skills) modifier — outermost
      const afterPassive = this.deps.passiveApplyToEffect
        ? this.deps.passiveApplyToEffect(target, fx.value)
        : fx.value
      // Step B: equipment (worn / housing) modifier — middle
      const afterEquipment = this.deps.equipmentApplyToEffect
        ? this.deps.equipmentApplyToEffect(target, afterPassive)
        : afterPassive
      // Step C: status (per-run buff/debuff) modifier — innermost
      const afterStatus = this.deps.statusApplyToEffect(target, afterEquipment)
      if (afterStatus !== afterEquipment) {
        anyModifiedByTarget.set(fx.target, true)
      }
      return { target: fx.target, value: afterStatus }
    })
    return { modifiedEffects: modified, anyModifiedByTarget }
  }

  private buildResult(
    choice: Choice,
    originalEffects: Effect[],
    applyResult: ApplyResult,
    anyModifiedByTarget: Map<string, boolean>,
    riskOutcome: RiskOutcome | undefined
  ): ResolveResult {
    const deltas: ResolveDelta[] = applyResult.deltas.map((rd) => {
      const targetEffects = originalEffects.filter((e) => e.target === rd.target)
      const rawDelta = targetEffects.reduce((sum, e) => sum + e.value, 0)
      return {
        target: rd.target,
        before: rd.before,
        after: rd.after,
        delta: rd.delta,
        rawDelta,
        wasClamped: rd.wasModified,
        wasStatusModified: anyModifiedByTarget.get(rd.target) === true
      }
    })

    const result: ResolveResult = {
      choiceText: choice.text,
      deltas
    }
    if (applyResult.stateChanged) {
      result.stateChange = applyResult.newState
    }
    if (choice.followUpId) {
      result.followUpId = choice.followUpId
    }
    if (riskOutcome !== undefined) {
      result.riskOutcome = riskOutcome
    }
    return result
  }
}

/**
 * Convert BuffSpec (config shape with `days`) → StatusEffect (runtime shape with `daysLeft`).
 * Boundary conversion at addStatus call site; documented in status-system.md.
 */
function buffSpecToStatus(spec: BuffSpec): StatusEffect {
  return {
    id: spec.id,
    name: spec.name,
    icon: spec.icon,
    type: spec.type,
    daysLeft: spec.days,
    energyMul: spec.energyMul,
    moodMul: spec.moodMul
  }
}
