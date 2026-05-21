/**
 * H-5 formatter unit tests — pure functions, 100% target.
 */

import { describe, test, expect } from 'vitest'
import {
  formatMoney,
  formatCompact,
  formatCount,
  formatPercent
} from '@/utils/format'

describe('formatMoney', () => {
  test('zero → "0"', () => {
    expect(formatMoney(0)).toBe('0')
  })

  test('small positive → unchanged', () => {
    expect(formatMoney(150)).toBe('150')
  })

  test('thousands → comma-separated', () => {
    expect(formatMoney(1500)).toBe('1,500')
    expect(formatMoney(12345)).toBe('12,345')
    expect(formatMoney(1234567)).toBe('1,234,567')
  })

  test('negative numbers keep sign + formatting', () => {
    expect(formatMoney(-1500)).toBe('-1,500')
    expect(formatMoney(-50)).toBe('-50')
  })

  test('fractional values truncated', () => {
    expect(formatMoney(1500.99)).toBe('1,500')
    expect(formatMoney(-1500.99)).toBe('-1,500')
  })
})

describe('formatCompact', () => {
  test('< 1000 → plain integer', () => {
    expect(formatCompact(0)).toBe('0')
    expect(formatCompact(999)).toBe('999')
    expect(formatCompact(-500)).toBe('-500')
  })

  test('1000-9999 → 1.5k style', () => {
    expect(formatCompact(1500)).toBe('1.5k')
    expect(formatCompact(2000)).toBe('2.0k')
    expect(formatCompact(9999)).toBe('10.0k')
  })

  test('10000+ → integer k', () => {
    expect(formatCompact(12345)).toBe('12k')
    expect(formatCompact(99999)).toBe('100k')
  })

  test('1M+ → M suffix', () => {
    expect(formatCompact(1_500_000)).toBe('1.5M')
    expect(formatCompact(12_345_678)).toBe('12M')
  })

  test('negative compact', () => {
    expect(formatCompact(-1500)).toBe('-1.5k')
    expect(formatCompact(-12345)).toBe('-12k')
  })
})

describe('formatCount', () => {
  test('integers with thousands separators', () => {
    expect(formatCount(0)).toBe('0')
    expect(formatCount(1500)).toBe('1,500')
    expect(formatCount(-1500)).toBe('-1,500')
  })

  test('truncates fractional input', () => {
    expect(formatCount(99.9)).toBe('99')
  })
})

describe('formatPercent', () => {
  test('basic ratios', () => {
    expect(formatPercent(0)).toBe('0%')
    expect(formatPercent(0.85)).toBe('85%')
    expect(formatPercent(1)).toBe('100%')
  })

  test('rounds nearest', () => {
    expect(formatPercent(0.857)).toBe('86%')
    expect(formatPercent(0.854)).toBe('85%')
  })

  test('clamps negatives to 0', () => {
    expect(formatPercent(-0.5)).toBe('0%')
  })

  test('clamps very large to 999%', () => {
    expect(formatPercent(50)).toBe('999%')
  })
})
