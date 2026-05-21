/**
 * Ending types (G-3).
 *
 * Each run resolves to exactly one ending based on RunResult + careerLevel
 * + which resource depleted. Endings are catalog-driven; persistence lives
 * in SaveData.stats.endings (new string[] field).
 *
 * Resolution: ENDINGS list is evaluated in order; FIRST match wins. So
 * order = priority. Always end with a fallback that matches everything.
 */

import type { RunResult, RunRating, DepletionSource } from './run-phase'
import type { CareerLevel } from './career'

/** Context passed to the matcher. */
export interface EndingContext {
  result: RunResult
  finalCareerLevel: CareerLevel
  /** What resource depleted, if any — health > energy > mood priority */
  depletionSource: DepletionSource | null
}

export interface Ending {
  id: string
  name: string
  description: string  // flavor shown on settle page
  icon: string
  rarity: 'common' | 'rare' | 'legendary'
  /**
   * Returns true if this run should resolve to this ending.
   * Catalog ordering matters — first match wins.
   */
  matches: (ctx: EndingContext) => boolean
}

export const ENDINGS: ReadonlyArray<Ending> = [
  // ============== Legendary (specific high-tier conditions) ==============
  {
    id: 'tycoon-ending',
    name: '财富自由',
    description: '通关时存款破 3000，职级达到顶峰。从此告别打工。',
    icon: '🏝️',
    rarity: 'legendary',
    matches: (ctx) =>
      ctx.result.won &&
      ctx.result.finalMoney >= 3000 &&
      ctx.finalCareerLevel === 4
  },
  {
    id: 'workaholic-king',
    name: '卷王终章',
    description: 'S 评级 + 通关 + 高级别。你已经卷成了别人加班的理由。',
    icon: '👑',
    rarity: 'legendary',
    matches: (ctx) =>
      ctx.result.won &&
      ctx.result.rating === 'S' &&
      ctx.finalCareerLevel >= 3
  },

  // ============== Rare (specific death conditions) ==============
  {
    id: 'overwork-death',
    name: '过劳死',
    description: '健康归零。倒在了工位上。年仅 35。',
    icon: '⚰️',
    rarity: 'rare',
    matches: (ctx) => ctx.depletionSource === 'health'
  },
  {
    id: 'mental-breakdown',
    name: '精神崩溃',
    description: '心情归零。在洗手间哭了一下午后，主动提交了辞职信。',
    icon: '💔',
    rarity: 'rare',
    matches: (ctx) => !ctx.result.won && ctx.depletionSource === 'mood'
  },
  {
    id: 'burnt-out',
    name: '燃尽',
    description: '体力归零。倒头睡了 18 小时后，决定回老家。',
    icon: '😵',
    rarity: 'rare',
    matches: (ctx) => !ctx.result.won && ctx.depletionSource === 'energy'
  },

  // ============== Common (won-path varieties) ==============
  {
    id: 'broke-but-survived',
    name: '勉强活着',
    description: '通关了，但银行卡上只剩两位数。',
    icon: '🥲',
    rarity: 'common',
    matches: (ctx) => ctx.result.won && ctx.result.finalMoney < 100
  },
  {
    id: 'promoted-rookie',
    name: '初露锋芒',
    description: '通关 + 升到 Lv2。你正在变强的路上。',
    icon: '🌱',
    rarity: 'common',
    matches: (ctx) => ctx.result.won && ctx.finalCareerLevel === 2
  },
  {
    id: 'senior-veteran',
    name: '中流砥柱',
    description: '通关 + 升到 Lv3。终于成了能扛事的人。',
    icon: '🛡️',
    rarity: 'common',
    matches: (ctx) => ctx.result.won && ctx.finalCareerLevel === 3
  },

  // ============== Common (lost-path varieties) ==============
  {
    id: 'early-quit',
    name: '中途退场',
    description: '第一周还没撑完就裸辞了。',
    icon: '🚪',
    rarity: 'common',
    matches: (ctx) => !ctx.result.won && ctx.result.survivalDays <= 5
  },

  // ============== Fallback (always matches last) ==============
  {
    id: 'just-another-week',
    name: '平凡的一周',
    description: '没什么大事发生，也没什么进步。',
    icon: '😐',
    rarity: 'common',
    matches: () => true  // fallback
  }
] as const

/** Get ending entry by id (for catalog UI). */
export function getEndingById(id: string): Ending | undefined {
  return ENDINGS.find((e) => e.id === id)
}

/**
 * First-match resolver — used by RunManager / EndingSystem on endRun.
 * Catalog invariant: last entry MUST match unconditionally (just-another-week).
 * Verified by 'last entry is unconditional fallback' test in ending-system.test.ts.
 * Non-null assert: catalog can't be empty, last entry is fallback.
 */
export function resolveEnding(ctx: EndingContext): Ending {
  return ENDINGS.find((e) => e.matches(ctx)) ?? ENDINGS[ENDINGS.length - 1]!
}

/** Rating constraint type re-export for callers (avoid double-import) */
export type { RunRating }
