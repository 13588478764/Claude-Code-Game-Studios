/**
 * StatusSystem — slot-based buff/debuff manager (1 buff slot + 1 debuff slot).
 * Strongest-wins modifier (no multiplicative stacking).
 * See `design/gdd/status-system.md` v2.1 for the full design.
 *
 * Architecture (per ADR-001 + ADR-003):
 *  - Pure TS service, no Vue/Pinia imports
 *  - Communicates via TypedEventEmitter
 *  - Status modifications happen UPSTREAM in ChoiceResolutionEngine via
 *    applyToEffect(), NOT inside ResourceManager (preserves Sprint 1 code).
 */

import { TypedEventEmitter } from '../common/event-emitter'
import type {
  StatusEffect,
  StatusSlot,
  StatusModifierTarget,
  StatusReplacedEvent,
  StatusRefreshedEvent,
  StatusLoadCorrectedEvent
} from '@/types/status'
import type { PhaseChangedPayload } from '@/types/run-phase'

/**
 * Shape of DayCycleSystem's onDayEnded payload. Kept here (not imported from
 * day-cycle to avoid service→service dependency) and must match exactly.
 * weekIndex was added in S4-1; StatusSystem doesn't read it but must accept it
 * because TypedEventEmitter is invariant in its payload type.
 */
export type DayEndedPayload = {
  day: number
  weekIndex: number
  salary: number
}

/**
 * Sign-aware floor: rounds toward zero on both sides.
 *  - signFloor(-19.95) === -19   (Math.ceil for negatives)
 *  - signFloor(19.95)  === 19    (Math.floor for positives)
 *  - signFloor(0)      === 0
 *
 * Avoids JS Math.round's "round half toward +∞" asymmetry (per ECMA-262).
 * Designed to be consistently player-friendly: less loss on negatives, less
 * gain on positives.
 */
export function signFloor(x: number): number {
  const result = x >= 0 ? Math.floor(x) : Math.ceil(x)
  // Normalize negative zero to positive zero — Math.ceil(-0.99) === -0
  // which is === 0 but Object.is(-0, 0) is false.
  return result === 0 ? 0 : result
}

export class StatusSystem {
  private buffSlot: StatusEffect | null = null
  private debuffSlot: StatusEffect | null = null

  readonly onStatusAdded = new TypedEventEmitter<StatusEffect>()
  readonly onStatusReplaced = new TypedEventEmitter<StatusReplacedEvent>()
  readonly onStatusRefreshed = new TypedEventEmitter<StatusRefreshedEvent>()
  readonly onStatusExpired = new TypedEventEmitter<StatusEffect>()
  readonly onStatusesCleared = new TypedEventEmitter<void>()
  readonly onLoadCorrected = new TypedEventEmitter<StatusLoadCorrectedEvent>()
  /** Aggregated UI notification — fires on any state change. */
  readonly onStatusChanged = new TypedEventEmitter<StatusEffect[]>()

  // ============== Mutation ==============

  /**
   * Add a status. Behavior:
   *  - empty matching slot → fresh add + emit onStatusAdded
   *  - same slot, same id  → refresh (replace days + mul fully) + emit onStatusRefreshed
   *  - same slot, different id → replace + emit onStatusReplaced
   *
   * Schema rejection: daysLeft <= 0 → console.warn, no state change.
   */
  addStatus(spec: StatusEffect): void {
    if (spec.daysLeft <= 0) {
      console.warn(
        `[StatusSystem] rejected: status "${spec.id}" has invalid daysLeft=${spec.daysLeft}`
      )
      return
    }

    const slot: StatusSlot = spec.type
    const existing = this.getSlot(slot)
    const fresh: StatusEffect = { ...spec }

    if (existing && existing.id === spec.id) {
      const oldDays = existing.daysLeft
      this.setSlot(slot, fresh)
      this.onStatusRefreshed.emit({
        id: spec.id,
        oldDays,
        newDays: spec.daysLeft
      })
      this.emitChanged()
      return
    }

    if (existing) {
      const oldStatus = existing
      this.setSlot(slot, fresh)
      this.onStatusReplaced.emit({ slot, old: oldStatus, new: fresh })
      this.emitChanged()
      return
    }

    this.setSlot(slot, fresh)
    this.onStatusAdded.emit(fresh)
    this.emitChanged()
  }

  /**
   * Clear both slots. Idempotent — emits onStatusesCleared only when
   * something was actually cleared.
   */
  clearAll(): void {
    if (this.buffSlot === null && this.debuffSlot === null) return
    this.buffSlot = null
    this.debuffSlot = null
    this.onStatusesCleared.emit()
    this.emitChanged()
  }

  // ============== Query ==============

  getBuff(): StatusEffect | null {
    return this.buffSlot
  }

  getDebuff(): StatusEffect | null {
    return this.debuffSlot
  }

  hasStatus(id: string): boolean {
    return this.buffSlot?.id === id || this.debuffSlot?.id === id
  }

  // ============== Modifier (called by ChoiceResolutionEngine) ==============

  /**
   * Apply status modifier to an effect value. Returns the modified value
   * (still an integer, sign-aware floor applied).
   * If no status modifies the target, returns rawValue unchanged.
   */
  applyToEffect(target: StatusModifierTarget, rawValue: number): number {
    const mul = this.getMulForTarget(target)
    if (mul === 1.0) return rawValue
    return signFloor(rawValue * mul)
  }

  // ============== Day tick (called by DayCycleSystem listener) ==============

  /**
   * Decrement daysLeft on both slots. Slots reaching 0 are removed and
   * emit onStatusExpired. Should fire AFTER salary application within the
   * onDayEnded contract (see day-cycle.md Core Rule #3).
   */
  tickStatuses(): void {
    let changed = false
    if (this.buffSlot) {
      this.buffSlot.daysLeft -= 1
      if (this.buffSlot.daysLeft <= 0) {
        const expired = this.buffSlot
        this.buffSlot = null
        this.onStatusExpired.emit(expired)
      }
      changed = true
    }
    if (this.debuffSlot) {
      this.debuffSlot.daysLeft -= 1
      if (this.debuffSlot.daysLeft <= 0) {
        const expired = this.debuffSlot
        this.debuffSlot = null
        this.onStatusExpired.emit(expired)
      }
      changed = true
    }
    if (changed) this.emitChanged()
  }

  // ============== Persistence ==============

  getSnapshot(): StatusEffect[] {
    const result: StatusEffect[] = []
    if (this.buffSlot) result.push({ ...this.buffSlot })
    if (this.debuffSlot) result.push({ ...this.debuffSlot })
    return result
  }

  /**
   * Restore from save snapshot. Filters out:
   *  - daysLeft <= 0 entries (corrupted)
   *  - duplicate slot entries (defensive)
   *
   * Emits onLoadCorrected with the dropped list when filtering occurred.
   */
  loadSnapshot(snapshot: StatusEffect[] | undefined): void {
    this.buffSlot = null
    this.debuffSlot = null

    if (!snapshot || snapshot.length === 0) {
      this.emitChanged()
      return
    }

    const dropped: StatusEffect[] = []
    for (const status of snapshot) {
      if (status.daysLeft <= 0) {
        dropped.push(status)
        continue
      }
      const slot: StatusSlot = status.type
      if (this.getSlot(slot) !== null) {
        dropped.push(status)
        continue
      }
      this.setSlot(slot, { ...status })
    }

    if (dropped.length > 0) {
      this.onLoadCorrected.emit({ dropped })
    }
    this.emitChanged()
  }

  // ============== Subscription wiring ==============

  /**
   * Subscribe to RunManager phase changes. Clears all statuses when phase
   * reaches ENDED (NOT during DYING/SETTLING — revive flow preserves status).
   */
  subscribeToRunPhase(emitter: TypedEventEmitter<PhaseChangedPayload>): void {
    emitter.on(({ to }) => {
      if (to === 'ENDED') this.clearAll()
    })
  }

  /**
   * Subscribe to DayCycleSystem onDayEnded. Per the day-cycle.md ordering
   * contract, salary applyEffects fires BEFORE this emit, so tick observes
   * post-salary state.
   */
  subscribeToDayEnded(emitter: TypedEventEmitter<DayEndedPayload>): void {
    emitter.on(() => this.tickStatuses())
  }

  // ============== Internal ==============

  private getSlot(slot: StatusSlot): StatusEffect | null {
    return slot === 'buff' ? this.buffSlot : this.debuffSlot
  }

  private setSlot(slot: StatusSlot, status: StatusEffect | null): void {
    if (slot === 'buff') this.buffSlot = status
    else this.debuffSlot = status
  }

  /**
   * Strongest-wins modifier lookup. Per v2.1 design, slot constraints
   * guarantee at most one active mul per target — but we defensively
   * handle data-violation cases (both buff and debuff with mul on same target).
   */
  private getMulForTarget(target: StatusModifierTarget): number {
    const field: 'energyMul' | 'moodMul' =
      target === 'energy' ? 'energyMul' : 'moodMul'

    const buffMul = this.buffSlot?.[field]
    const debuffMul = this.debuffSlot?.[field]

    if (buffMul != null && debuffMul != null) {
      // Data violation — schema lint (S2-6) should prevent this at build time.
      console.warn(
        `[StatusSystem] data violation: both "${this.buffSlot!.id}" and "${this.debuffSlot!.id}" have ${field}; using buff's value`
      )
      return buffMul
    }
    if (buffMul != null) return buffMul
    if (debuffMul != null) return debuffMul
    return 1.0
  }

  private emitChanged(): void {
    this.onStatusChanged.emit(this.getSnapshot())
  }
}
