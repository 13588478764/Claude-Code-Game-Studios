/**
 * Resource and state types — shared across services and stores.
 */

export interface Resources {
  energy: number  // 0-100, clamped
  mood: number    // 0-100, clamped
  money: number   // can go negative
  health: number  // 0-100, clamped; G-2 — depletes during CRISIS, irreversible game-over at 0
}

export type ResourceState = 'NORMAL' | 'WARNING' | 'CRISIS' | 'DEAD'

export type ResourceTarget = keyof Resources

export interface Effect {
  target: ResourceTarget
  value: number
}

export interface ResourceDelta {
  target: ResourceTarget
  before: number
  after: number
  delta: number
  rawDelta: number
  wasModified: boolean  // true if passive modifier or clamp altered the raw value
}

export interface ApplyResult {
  before: Resources
  after: Resources
  deltas: ResourceDelta[]
  stateChanged: boolean
  newState: ResourceState
  depleted: ResourceTarget | null
}

export interface ResourceManagerConfig {
  initialEnergy: number
  initialMood: number
  initialMoney: number
  initialHealth: number    // G-2
  maxEnergy: number
  maxMood: number
  maxHealth: number        // G-2
  warningThreshold: number // ≤ this triggers WARNING
  crisisThreshold: number  // ≤ this triggers CRISIS
}

export const DEFAULT_RESOURCE_CONFIG: ResourceManagerConfig = {
  initialEnergy: 80,
  initialMood: 60,
  initialMoney: 0,
  initialHealth: 100,
  maxEnergy: 100,
  maxMood: 100,
  maxHealth: 100,
  warningThreshold: 30,
  crisisThreshold: 20
}
