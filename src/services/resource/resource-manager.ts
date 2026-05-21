/**
 * ResourceManager — owns energy/mood/money state and the resource state machine.
 * See ADR-001 (event emitters), ADR-003 (Service emit → Store subscribe).
 */

import { TypedEventEmitter } from '../common/event-emitter'
import {
  DEFAULT_RESOURCE_CONFIG,
  type Resources,
  type ResourceState,
  type ResourceTarget,
  type Effect,
  type ResourceDelta,
  type ApplyResult,
  type ResourceManagerConfig
} from '@/types/resource'

export class ResourceManager {
  private config: ResourceManagerConfig
  private resources: Resources
  private state: ResourceState = 'NORMAL'

  readonly onResourceChanged = new TypedEventEmitter<{
    before: Resources
    after: Resources
    deltas: ResourceDelta[]
  }>()
  readonly onStateChanged = new TypedEventEmitter<{
    from: ResourceState
    to: ResourceState
  }>()
  readonly onResourceDepleted = new TypedEventEmitter<{
    which: 'energy' | 'mood' | 'health'
  }>()

  constructor(config: ResourceManagerConfig = DEFAULT_RESOURCE_CONFIG) {
    this.config = { ...config }
    this.resources = {
      energy: config.initialEnergy,
      mood: config.initialMood,
      money: config.initialMoney,
      health: config.initialHealth
    }
    this.state = this.computeState(this.resources)
  }

  init(initial?: Partial<Resources>): void {
    this.resources = {
      energy: initial?.energy ?? this.config.initialEnergy,
      mood: initial?.mood ?? this.config.initialMood,
      money: initial?.money ?? this.config.initialMoney,
      health: initial?.health ?? this.config.initialHealth
    }
    this.state = this.computeState(this.resources)
  }

  getResources(): Readonly<Resources> {
    return { ...this.resources }
  }

  getState(): ResourceState {
    return this.state
  }

  /**
   * Apply a list of effects atomically.
   * Emits in order: onResourceChanged → onStateChanged (if changed) → onResourceDepleted (if any).
   */
  applyEffects(effects: Effect[]): ApplyResult {
    const before: Resources = { ...this.resources }
    const beforeState = this.state
    const deltas: ResourceDelta[] = []

    for (const fx of effects) {
      const beforeVal = this.resources[fx.target]
      const rawDelta = fx.value
      const newVal = this.clamp(fx.target, beforeVal + rawDelta)
      const actualDelta = newVal - beforeVal

      this.resources[fx.target] = newVal

      // Coalesce same-target deltas: update existing entry
      const existing = deltas.find((d) => d.target === fx.target)
      if (existing) {
        existing.after = newVal
        existing.delta = newVal - existing.before
        existing.rawDelta += rawDelta
        existing.wasModified = existing.wasModified || existing.rawDelta !== existing.delta
      } else {
        deltas.push({
          target: fx.target,
          before: beforeVal,
          after: newVal,
          delta: actualDelta,
          rawDelta,
          wasModified: rawDelta !== actualDelta
        })
      }
    }

    const after: Resources = { ...this.resources }
    const newState = this.computeState(after)
    const stateChanged = newState !== beforeState
    this.state = newState

    if (deltas.length > 0) {
      this.onResourceChanged.emit({ before, after, deltas })
    }
    if (stateChanged) {
      this.onStateChanged.emit({ from: beforeState, to: newState })
    }

    let depleted: ResourceTarget | null = null
    // Order matters: health depletion is most fatal (no revive possible)
    if (after.health <= 0 && before.health > 0) {
      depleted = 'health'
      this.onResourceDepleted.emit({ which: 'health' })
    } else if (after.energy <= 0 && before.energy > 0) {
      depleted = 'energy'
      this.onResourceDepleted.emit({ which: 'energy' })
    } else if (after.mood <= 0 && before.mood > 0) {
      depleted = 'mood'
      this.onResourceDepleted.emit({ which: 'mood' })
    }

    return { before, after, deltas, stateChanged, newState, depleted }
  }

  reset(): void {
    const beforeState = this.state
    this.resources = {
      energy: this.config.initialEnergy,
      mood: this.config.initialMood,
      money: this.config.initialMoney,
      health: this.config.initialHealth
    }
    this.state = this.computeState(this.resources)
    if (this.state !== beforeState) {
      this.onStateChanged.emit({ from: beforeState, to: this.state })
    }
  }

  private clamp(target: ResourceTarget, value: number): number {
    if (target === 'money') return value  // money has no clamp
    let max: number
    if (target === 'energy') max = this.config.maxEnergy
    else if (target === 'mood') max = this.config.maxMood
    else max = this.config.maxHealth  // 'health'
    if (value < 0) return 0
    if (value > max) return max
    return value
  }

  private computeState(r: Resources): ResourceState {
    if (r.health <= 0 || r.energy <= 0 || r.mood <= 0) return 'DEAD'
    if (r.mood <= this.config.crisisThreshold) return 'CRISIS'
    if (r.energy <= this.config.warningThreshold || r.mood <= this.config.warningThreshold) return 'WARNING'
    return 'NORMAL'
  }
}
