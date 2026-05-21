/**
 * Achievement types (C-2).
 *
 * Permanent unlocks based on cumulative stats. Mirror of PassiveSkill pattern:
 *   - Catalog declared statically (ACHIEVEMENTS)
 *   - Unlocked ids persisted to SaveData.stats.achievements (already exists,
 *     was previously a placeholder string[])
 *   - AchievementSystem.checkUnlocks(stats) called on progression update
 *
 * Sprint 4 ships 8 example achievements. Adding a new one = push entry to
 * ACHIEVEMENTS, zero code change.
 */

import type { GlobalStats } from './save'

export interface Achievement {
  id: string
  name: string
  description: string
  icon: string
  /** Hidden until first unlock — shown as "???" in 图鉴 until then. */
  hidden?: boolean
  unlockCondition: AchievementCondition
}

/** Same condition vocab as JobConfig.unlockCondition + a few extras. */
export type AchievementCondition =
  | { type: 'runs'; value: number }
  | { type: 'wins'; value: number }
  | { type: 'deaths'; value: number }
  | { type: 'totalMoney'; value: number }
  | { type: 'jobPlays'; jobId: string; value: number }
  | { type: 'jobsTried'; value: number }  // distinct jobs played

export const ACHIEVEMENTS: ReadonlyArray<Achievement> = [
  {
    id: 'first-blood',
    name: '初出茅庐',
    description: '完成第一局（不论输赢）',
    icon: '🌱',
    unlockCondition: { type: 'runs', value: 1 }
  },
  {
    id: 'first-win',
    name: '撑过一周',
    description: '第一次通关一整个职业生涯',
    icon: '🏆',
    unlockCondition: { type: 'wins', value: 1 }
  },
  {
    id: 'workaholic',
    name: '卷王本王',
    description: '累计通关 5 次',
    icon: '💼',
    unlockCondition: { type: 'wins', value: 5 }
  },
  {
    id: 'frequent-flyer',
    name: '打工常客',
    description: '累计游玩 10 局',
    icon: '🎯',
    unlockCondition: { type: 'runs', value: 10 }
  },
  {
    id: 'broke-survivor',
    name: '屡战屡败',
    description: '累计被炒 5 次',
    icon: '💀',
    unlockCondition: { type: 'deaths', value: 5 }
  },
  {
    id: 'small-bank',
    name: '小有积蓄',
    description: '累计赚到 1000 元',
    icon: '💰',
    unlockCondition: { type: 'totalMoney', value: 1000 }
  },
  {
    id: 'jack-of-trades',
    name: '万金油',
    description: '尝试过 3 种不同职业',
    icon: '🎭',
    unlockCondition: { type: 'jobsTried', value: 3 }
  },
  {
    id: 'code-veteran',
    name: '资深码农',
    description: '以程序员身份游玩 5 次',
    icon: '💻',
    unlockCondition: { type: 'jobPlays', jobId: 'programmer', value: 5 }
  },
  {
    id: 'sales-ace',
    name: '销售之王',
    description: '以销售身份游玩 5 次',
    icon: '🤝',
    unlockCondition: { type: 'jobPlays', jobId: 'sales', value: 5 }
  },
  {
    id: 'design-master',
    name: '设计大师',
    description: '以设计师身份游玩 5 次',
    icon: '🎨',
    unlockCondition: { type: 'jobPlays', jobId: 'designer', value: 5 }
  },
  {
    id: 'rider-legend',
    name: '骑手传奇',
    description: '以外卖员身份游玩 5 次',
    icon: '🛵',
    unlockCondition: { type: 'jobPlays', jobId: 'runner', value: 5 }
  },
  {
    id: 'fish-grandmaster',
    name: '摸鱼宗师',
    description: '以摸鱼大师身份游玩 5 次。最高的境界是看起来在工作。',
    icon: '🐟',
    unlockCondition: { type: 'jobPlays', jobId: 'slacker', value: 5 }
  },
  {
    id: 'middle-class',
    name: '中产阶级',
    description: '累计赚到 5000 元',
    icon: '💎',
    unlockCondition: { type: 'totalMoney', value: 5000 }
  },
  {
    id: 'tycoon',
    name: '小富即安',
    description: '累计赚到 20000 元',
    icon: '🏦',
    unlockCondition: { type: 'totalMoney', value: 20000 }
  },
  {
    id: 'iron-will',
    name: '钢铁意志',
    description: '累计通关 20 次。卷王之王。',
    icon: '🏅',
    unlockCondition: { type: 'wins', value: 20 }
  },
  {
    id: 'world-explorer',
    name: '人生百态',
    description: '尝试过 6 种不同职业',
    icon: '🌍',
    unlockCondition: { type: 'jobsTried', value: 6 }
  },
  {
    id: 'true-survivor',
    name: '老兵不死',
    description: '累计游玩 30 局',
    icon: '🎖️',
    unlockCondition: { type: 'runs', value: 30 }
  }
]

export function getAchievementById(id: string): Achievement | undefined {
  return ACHIEVEMENTS.find((a) => a.id === id)
}

export function evaluateAchievementCondition(
  cond: AchievementCondition,
  stats: GlobalStats
): boolean {
  switch (cond.type) {
    case 'runs':
      return stats.totalRuns >= cond.value
    case 'wins':
      return stats.totalWins >= cond.value
    case 'deaths':
      return stats.totalDeaths >= cond.value
    case 'totalMoney':
      return stats.totalMoneyEarned >= cond.value
    case 'jobPlays':
      return (stats.jobsPlayed[cond.jobId] ?? 0) >= cond.value
    case 'jobsTried':
      return Object.keys(stats.jobsPlayed).length >= cond.value
    default:
      return false
  }
}
