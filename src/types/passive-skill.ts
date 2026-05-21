/**
 * Passive skill types — permanent, save-persisted modifiers stacked OUTSIDE
 * the status system. Modifier order at choice resolution:
 *
 *   raw → passiveSkill.applyToEffect → status.applyToEffect → applyEffects
 *
 * Passive is permanent (saved in SaveData.passiveSkills); status is per-run.
 * Sprint 3 ships a single example skill ("厚脸皮 Lv1"); Sprint 4 expands.
 */

import type { GlobalStats } from './save'

export type PassiveSkillTarget = 'energy' | 'mood'

export interface PassiveSkill {
  id: string
  name: string
  description: string
  energyMul?: number
  moodMul?: number
  unlockCondition: PassiveSkillUnlockCondition
}

/**
 * Unlock conditions for passive skills. Mirrors achievement conditions —
 * basic stat thresholds plus jobPlays for job-specific progression.
 */
export type PassiveSkillUnlockCondition =
  | { type: 'wins'; value: number }
  | { type: 'totalRuns'; value: number }
  | { type: 'totalDeaths'; value: number }
  | { type: 'totalMoney'; value: number }
  | { type: 'jobPlays'; jobId: string; value: number }

/**
 * Built-in passive skills. Sprint 3 stub list — Sprint 4 will expand to a
 * full tree. Adding a new entry here is the only authoring surface needed
 * (PassiveSkillSystem reads from this constant on construction).
 */
export const PASSIVE_SKILLS: PassiveSkill[] = [
  {
    id: 'thick-skin-1',
    name: '厚脸皮 Lv1',
    description: '心情损失减少 20%。被骂也无所谓了。',
    moodMul: 0.8,
    unlockCondition: { type: 'wins', value: 3 }
  },
  {
    id: 'iron-stomach-1',
    name: '钢铁体魄 Lv1',
    description: '体力损失减少 15%。胃口好身体棒。',
    energyMul: 0.85,
    unlockCondition: { type: 'totalRuns', value: 5 }
  },
  {
    id: 'thick-skin-2',
    name: '厚脸皮 Lv2',
    description: '心情损失再减 15%（与 Lv1 累乘）。脸皮厚到刀枪不入。',
    moodMul: 0.85,
    unlockCondition: { type: 'wins', value: 10 }
  },
  {
    id: 'caffeine-tolerance',
    name: '咖啡因抗体',
    description: '体力损失减少 10%。早上一杯下午一杯神清气爽。',
    energyMul: 0.9,
    unlockCondition: { type: 'jobPlays', jobId: 'programmer', value: 3 }
  },
  {
    id: 'salesman-charm',
    name: '销售之魂',
    description: '心情损失减少 12%。客户的拒绝你已经麻木了。',
    moodMul: 0.88,
    unlockCondition: { type: 'jobPlays', jobId: 'sales', value: 3 }
  },
  {
    id: 'workplace-veteran',
    name: '职场老兵',
    description: '体力 + 心情 各减损失 8%。见过的多了。',
    energyMul: 0.92,
    moodMul: 0.92,
    unlockCondition: { type: 'totalRuns', value: 15 }
  },
  {
    id: 'phoenix-rising',
    name: '凤凰涅槃',
    description: '心情损失减少 25%。被炒过的次数越多，越淡定。',
    moodMul: 0.75,
    unlockCondition: { type: 'totalDeaths', value: 10 }
  }
]

/** Lookup helper. Returns undefined if id is unknown. */
export function getPassiveSkillById(id: string): PassiveSkill | undefined {
  return PASSIVE_SKILLS.find((s) => s.id === id)
}

/** Test seam — caller can substitute a list for unit tests. */
export function evaluateUnlockCondition(
  cond: PassiveSkillUnlockCondition,
  stats: GlobalStats
): boolean {
  switch (cond.type) {
    case 'wins':
      return stats.totalWins >= cond.value
    case 'totalRuns':
      return stats.totalRuns >= cond.value
    case 'totalDeaths':
      return stats.totalDeaths >= cond.value
    case 'totalMoney':
      return stats.totalMoneyEarned >= cond.value
    case 'jobPlays':
      return (stats.jobsPlayed[cond.jobId] ?? 0) >= cond.value
    default:
      return false
  }
}
