/**
 * Number / string formatting helpers (H-5).
 *
 * Pure functions, zero deps. Used across UI to display money, big numbers,
 * counts in a consistent player-readable way.
 */

/**
 * Format a money value for display. Adds thousand separators ("1,500").
 * Always shows whole numbers (no decimals) — economy is integer-only.
 * Handles negative correctly: -1500 → "-1,500".
 */
export function formatMoney(value: number): string {
  const sign = value < 0 ? '-' : ''
  const abs = Math.abs(Math.trunc(value))
  return sign + abs.toLocaleString('en-US')
}

/**
 * Compact format for very large numbers. Use for stats display where
 * exact value matters less than scale.
 *   1500   → "1.5k"
 *   12345  → "12.3k"
 *   1.5e6  → "1.5M"
 *   < 1000 → unchanged (formatMoney style)
 */
export function formatCompact(value: number): string {
  const abs = Math.abs(value)
  const sign = value < 0 ? '-' : ''
  if (abs < 1000) return sign + Math.trunc(abs).toString()
  if (abs < 1_000_000) {
    const k = abs / 1000
    return sign + (k >= 10 ? k.toFixed(0) : k.toFixed(1)) + 'k'
  }
  const m = abs / 1_000_000
  return sign + (m >= 10 ? m.toFixed(0) : m.toFixed(1)) + 'M'
}

/** Plain integer with thousands separators (e.g. "1,500 次"). */
export function formatCount(value: number): string {
  return Math.trunc(value).toLocaleString('en-US')
}

/** Format a percentage with no decimals: 0.85 → "85%". Clamps to 0-999%. */
export function formatPercent(ratio: number): string {
  const pct = Math.max(0, Math.min(999, Math.round(ratio * 100)))
  return `${pct}%`
}
