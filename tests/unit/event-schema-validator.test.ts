/**
 * S2-6 schema validator unit tests.
 * Covers build-time validation rules — both ERROR (block build) and WARN (informational).
 */

import { describe, test, expect } from 'vitest'
import {
  validateEventForBuild,
  validateEventArrayForBuild,
  formatIssue,
  BUFF_MAX_DAYS
} from '@/services/event-data/event-schema'

function makeValidEntry(overrides: Record<string, unknown> = {}) {
  return {
    id: 'test-1',
    text: 'sample event',
    choiceA: { text: 'A', effects: [{ target: 'energy', value: -10 }] },
    choiceB: { text: 'B', effects: [{ target: 'mood', value: 5 }] },
    ...overrides
  }
}

describe('validateEventForBuild — basic structure', () => {
  test('valid entry produces no issues', () => {
    const issues = validateEventForBuild(makeValidEntry())
    expect(issues).toEqual([])
  })

  test('non-object entry → error', () => {
    const issues = validateEventForBuild('not an object')
    expect(issues).toHaveLength(1)
    expect(issues[0]!.severity).toBe('error')
    expect(issues[0]!.field).toBe('<root>')
  })

  test('null entry → error', () => {
    const issues = validateEventForBuild(null)
    expect(issues[0]!.severity).toBe('error')
  })

  test('AC-6: missing id → error', () => {
    const issues = validateEventForBuild(makeValidEntry({ id: undefined }))
    expect(issues.some((i) => i.field === 'id' && i.severity === 'error')).toBe(true)
  })

  test('empty id string → error', () => {
    const issues = validateEventForBuild(makeValidEntry({ id: '' }))
    expect(issues.some((i) => i.field === 'id' && i.severity === 'error')).toBe(true)
  })

  test('non-string text → error', () => {
    const issues = validateEventForBuild(makeValidEntry({ text: 123 }))
    expect(issues.some((i) => i.field === 'text' && i.severity === 'error')).toBe(true)
  })

  test('AC-7: missing choiceA → error', () => {
    const issues = validateEventForBuild(makeValidEntry({ choiceA: undefined }))
    expect(issues.some((i) => i.field === 'choiceA' && i.severity === 'error')).toBe(true)
  })

  test('AC-7: missing choiceB → error', () => {
    const issues = validateEventForBuild(makeValidEntry({ choiceB: undefined }))
    expect(issues.some((i) => i.field === 'choiceB' && i.severity === 'error')).toBe(true)
  })
})

describe('validateEventForBuild — choice / effect validation', () => {
  test('empty choice text → error', () => {
    const issues = validateEventForBuild(
      makeValidEntry({
        choiceA: { text: '', effects: [{ target: 'energy', value: -5 }] }
      })
    )
    expect(issues.some((i) => i.field === 'choiceA.text' && i.severity === 'error')).toBe(true)
  })

  test('non-array effects → error', () => {
    const issues = validateEventForBuild(
      makeValidEntry({
        choiceA: { text: 'A', effects: 'not array' }
      })
    )
    expect(
      issues.some((i) => i.field === 'choiceA.effects' && i.severity === 'error')
    ).toBe(true)
  })

  test('AC-8: invalid effect target → error', () => {
    const issues = validateEventForBuild(
      makeValidEntry({
        choiceA: { text: 'A', effects: [{ target: 'mana', value: -5 }] }
      })
    )
    const targetIssue = issues.find((i) => i.field.includes('.target') && i.severity === 'error')
    expect(targetIssue).toBeDefined()
    expect(targetIssue!.message).toContain('mana')
  })

  test('non-number effect value → error', () => {
    const issues = validateEventForBuild(
      makeValidEntry({
        choiceA: { text: 'A', effects: [{ target: 'energy', value: 'lots' }] }
      })
    )
    expect(issues.some((i) => i.field.includes('.value') && i.severity === 'error')).toBe(true)
  })
})

describe('validateEventForBuild — buff validation (AC-2/3/4/5)', () => {
  test('valid buff produces no issues', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [{ target: 'energy', value: -10 }],
        buff: {
          id: 'caffeine',
          name: '亢奋',
          icon: '☕',
          type: 'buff',
          days: 2,
          energyMul: 0.5
        }
      }
    })
    expect(validateEventForBuild(entry)).toEqual([])
  })

  test('AC-5: buff days=0 → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'buff', days: 0 }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.days') && i.severity === 'error')).toBe(true)
  })

  test('AC-5: buff days=-1 → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'buff', days: -1 }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.days') && i.severity === 'error')).toBe(true)
  })

  test('AC-4: buff days exceeds BUFF_MAX_DAYS → warn (not error)', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'buff', days: BUFF_MAX_DAYS + 1 }
      }
    })
    const issues = validateEventForBuild(entry)
    const dayIssues = issues.filter((i) => i.field.includes('.days'))
    expect(dayIssues.length).toBeGreaterThan(0)
    expect(dayIssues.every((i) => i.severity === 'warn')).toBe(true)
  })

  test('AC-2: buff with energyMul > 1.0 → warn', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'buff', days: 2, energyMul: 1.5 }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.energyMul') && i.severity === 'warn')).toBe(true)
  })

  test('AC-3: debuff with energyMul < 1.0 → warn', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'd1', name: 'd', icon: '?', type: 'debuff', days: 2, energyMul: 0.5 }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.energyMul') && i.severity === 'warn')).toBe(true)
  })

  test('debuff with moodMul > 1.0 produces no warn (correct direction)', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'd1', name: 'd', icon: '?', type: 'debuff', days: 1, moodMul: 1.5 }
      }
    })
    expect(validateEventForBuild(entry)).toEqual([])
  })

  test('invalid buff.type → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'curse', days: 1 }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.type') && i.severity === 'error')).toBe(true)
  })

  test('non-number mul → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        buff: { id: 'b1', name: 'b', icon: '?', type: 'buff', days: 1, energyMul: 'half' }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.energyMul') && i.severity === 'error')).toBe(true)
  })
})

describe('validateEventForBuild — risk validation', () => {
  test('valid risk produces no issues', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: 0.7,
          success: { text: 'win', effects: [] },
          fail: { text: 'lose', effects: [] }
        }
      }
    })
    expect(validateEventForBuild(entry)).toEqual([])
  })

  test('chance > 1 → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: 1.5,
          success: { text: 'win', effects: [] },
          fail: { text: 'lose', effects: [] }
        }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.chance') && i.severity === 'error')).toBe(true)
  })

  test('chance < 0 → error', () => {
    const entry = makeValidEntry({
      choiceA: {
        text: 'A',
        effects: [],
        risk: {
          chance: -0.1,
          success: { text: 'win', effects: [] },
          fail: { text: 'lose', effects: [] }
        }
      }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field.includes('.chance') && i.severity === 'error')).toBe(true)
  })

  test('non-object risk → error', () => {
    const entry = makeValidEntry({
      choiceA: { text: 'A', effects: [], risk: 'not an object' }
    })
    const issues = validateEventForBuild(entry)
    expect(issues.some((i) => i.field === 'choiceA.risk' && i.severity === 'error')).toBe(true)
  })
})

describe('validateEventArrayForBuild', () => {
  test('AC-1: array of valid entries → no issues', () => {
    const issues = validateEventArrayForBuild([
      makeValidEntry({ id: 'a' }),
      makeValidEntry({ id: 'b' }),
      makeValidEntry({ id: 'c' })
    ])
    expect(issues).toEqual([])
  })

  test('AC-6: duplicate IDs within file → error', () => {
    const issues = validateEventArrayForBuild([
      makeValidEntry({ id: 'dup' }),
      makeValidEntry({ id: 'other' }),
      makeValidEntry({ id: 'dup' })
    ])
    const dupIssues = issues.filter((i) => i.message.includes('Duplicate'))
    expect(dupIssues).toHaveLength(1)
    expect(dupIssues[0]!.severity).toBe('error')
  })

  test('non-array input → error at root', () => {
    const issues = validateEventArrayForBuild({ events: [] })
    expect(issues).toHaveLength(1)
    expect(issues[0]!.field).toBe('<root>')
    expect(issues[0]!.severity).toBe('error')
  })

  test('empty array → no issues', () => {
    expect(validateEventArrayForBuild([])).toEqual([])
  })
})

describe('formatIssue', () => {
  test('AC-9: friendly format with file + entry id + field', () => {
    const formatted = formatIssue('src/static/events/common.json', {
      severity: 'error',
      entryId: 'common-001',
      field: 'choiceA.effects[0].target',
      message: 'invalid target'
    })
    expect(formatted).toContain('[ERROR]')
    expect(formatted).toContain('common.json')
    expect(formatted).toContain('common-001')
    expect(formatted).toContain('choiceA.effects[0].target')
    expect(formatted).toContain('invalid target')
  })

  test('warn severity uses [WARN] prefix', () => {
    const formatted = formatIssue('test.json', {
      severity: 'warn',
      entryId: 'x',
      field: 'days',
      message: 'too long'
    })
    expect(formatted).toContain('[WARN]')
  })

  test('null entryId renders as <no-id>', () => {
    const formatted = formatIssue('test.json', {
      severity: 'error',
      entryId: null,
      field: '<root>',
      message: 'broken'
    })
    expect(formatted).toContain('<no-id>')
  })
})
