/**
 * Schema validation for event card configs.
 *
 * Two modes:
 *  - Runtime (validateEventList) — drops invalid entries silently with warn,
 *    used by EventDataEngine when loading a JSON file.
 *  - Build-time (validateEventForBuild + validateEventArrayForBuild) — returns
 *    issue list with severity tagging, used by tools/validate-events.ts to
 *    block builds on bad data and warn on data design violations.
 *
 * Build-time constants align with status-system.md v2.1 Tuning Knobs:
 *  - BUFF_MAX_DAYS = 2 (warn if exceeded)
 *  - DEBUFF_MAX_DAYS = 2 (warn if exceeded)
 */

import type { EventCard, Choice } from '@/types/event'

export const BUFF_MAX_DAYS = 2
export const DEBUFF_MAX_DAYS = 2

export type IssueSeverity = 'error' | 'warn'

export interface ValidationIssue {
  severity: IssueSeverity
  /** entry id if locatable, else null */
  entryId: string | null
  /** dot-path within the entry, e.g. "choiceA.effects[0].target" */
  field: string
  message: string
}

// ============== Runtime (loader) validation — keep existing behavior ==============

export function isValidChoice(c: unknown): c is Choice {
  if (typeof c !== 'object' || c === null) return false
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const o = c as any
  if (typeof o.text !== 'string' || o.text.length === 0) return false
  if (!Array.isArray(o.effects)) return false
  for (const fx of o.effects) {
    if (typeof fx.target !== 'string') return false
    if (!['energy', 'mood', 'money', 'health'].includes(fx.target)) return false
    if (typeof fx.value !== 'number') return false
  }
  return true
}

export function isValidEvent(e: unknown): e is EventCard {
  if (typeof e !== 'object' || e === null) return false
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const o = e as any
  if (typeof o.id !== 'string' || o.id.length === 0) return false
  if (typeof o.text !== 'string' || o.text.length === 0) return false
  if (!isValidChoice(o.choiceA)) return false
  if (!isValidChoice(o.choiceB)) return false
  return true
}

export function validateEventList(events: unknown): EventCard[] {
  if (!Array.isArray(events)) return []
  const valid: EventCard[] = []
  for (const e of events) {
    if (isValidEvent(e)) {
      valid.push(e)
    } else {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      console.warn('[EventDataEngine] dropping invalid event:', (e as any)?.id ?? '<no-id>')
    }
  }
  return valid
}

// ============== Build-time strict validation — issue collection ==============

/**
 * Validate a single event entry. Returns all issues found (errors + warns).
 * Errors should block the build; warns are informational.
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function validateEventForBuild(entry: any): ValidationIssue[] {
  const issues: ValidationIssue[] = []

  if (typeof entry !== 'object' || entry === null) {
    issues.push({
      severity: 'error',
      entryId: null,
      field: '<root>',
      message: 'Entry must be an object'
    })
    return issues
  }

  const id = typeof entry.id === 'string' ? entry.id : null

  // ID
  if (!id || id.length === 0) {
    issues.push({
      severity: 'error',
      entryId: id,
      field: 'id',
      message: 'id must be a non-empty string'
    })
  }

  // text
  if (typeof entry.text !== 'string') {
    issues.push({
      severity: 'error',
      entryId: id,
      field: 'text',
      message: 'text must be a string'
    })
  }

  // choices
  validateChoiceForBuild(entry.choiceA, 'choiceA', id, issues)
  validateChoiceForBuild(entry.choiceB, 'choiceB', id, issues)

  return issues
}

function validateChoiceForBuild(
  choice: unknown,
  fieldPrefix: string,
  entryId: string | null,
  issues: ValidationIssue[]
): void {
  if (typeof choice !== 'object' || choice === null) {
    issues.push({
      severity: 'error',
      entryId,
      field: fieldPrefix,
      message: `${fieldPrefix} is required and must be an object`
    })
    return
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const c = choice as any

  if (typeof c.text !== 'string' || c.text.length === 0) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPrefix}.text`,
      message: `${fieldPrefix}.text must be a non-empty string`
    })
  }

  if (!Array.isArray(c.effects)) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPrefix}.effects`,
      message: `${fieldPrefix}.effects must be an array`
    })
  } else {
    c.effects.forEach((fx: unknown, i: number) => {
      validateEffectForBuild(fx, `${fieldPrefix}.effects[${i}]`, entryId, issues)
    })
  }

  // Optional buff field validation
  if (c.buff !== undefined) {
    validateBuffForBuild(c.buff, `${fieldPrefix}.buff`, entryId, issues)
  }

  // Optional risk validation (success/fail outcomes)
  if (c.risk !== undefined) {
    validateRiskForBuild(c.risk, `${fieldPrefix}.risk`, entryId, issues)
  }
}

function validateEffectForBuild(
  fx: unknown,
  fieldPath: string,
  entryId: string | null,
  issues: ValidationIssue[]
): void {
  if (typeof fx !== 'object' || fx === null) {
    issues.push({
      severity: 'error',
      entryId,
      field: fieldPath,
      message: 'effect must be an object'
    })
    return
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const f = fx as any

  if (!['energy', 'mood', 'money', 'health'].includes(f.target)) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.target`,
      message: `target must be one of energy/mood/money/health (got "${f.target}")`
    })
  }
  if (typeof f.value !== 'number') {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.value`,
      message: 'value must be a number'
    })
  }
}

function validateBuffForBuild(
  buff: unknown,
  fieldPath: string,
  entryId: string | null,
  issues: ValidationIssue[]
): void {
  if (typeof buff !== 'object' || buff === null) {
    issues.push({
      severity: 'error',
      entryId,
      field: fieldPath,
      message: 'buff must be an object'
    })
    return
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const b = buff as any

  if (typeof b.id !== 'string' || b.id.length === 0) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.id`,
      message: 'buff.id must be a non-empty string'
    })
  }
  if (b.type !== 'buff' && b.type !== 'debuff') {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.type`,
      message: `buff.type must be "buff" or "debuff" (got "${b.type}")`
    })
  }
  if (typeof b.days !== 'number' || b.days <= 0) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.days`,
      message: `buff.days must be > 0 (got ${b.days})`
    })
  } else {
    // Days range warnings (not errors)
    const max = b.type === 'buff' ? BUFF_MAX_DAYS : DEBUFF_MAX_DAYS
    if (b.days > max) {
      issues.push({
        severity: 'warn',
        entryId,
        field: `${fieldPath}.days`,
        message: `${b.type} days=${b.days} exceeds recommended max ${max}`
      })
    }
  }

  // Buff/debuff mul direction warnings (not errors)
  // buff: mul should reduce magnitude (mul < 1.0 for negative-direction effects)
  // debuff: mul should amplify magnitude (mul > 1.0)
  for (const target of ['energy', 'mood'] as const) {
    const mulField = `${target}Mul`
    const mulValue = b[mulField]
    if (mulValue !== undefined) {
      if (typeof mulValue !== 'number') {
        issues.push({
          severity: 'error',
          entryId,
          field: `${fieldPath}.${mulField}`,
          message: `${mulField} must be a number`
        })
        continue
      }
      if (b.type === 'buff' && mulValue > 1.0) {
        issues.push({
          severity: 'warn',
          entryId,
          field: `${fieldPath}.${mulField}`,
          message: `buff ${mulField}=${mulValue} > 1.0 (buffs typically reduce loss; consider type='debuff')`
        })
      }
      if (b.type === 'debuff' && mulValue < 1.0) {
        issues.push({
          severity: 'warn',
          entryId,
          field: `${fieldPath}.${mulField}`,
          message: `debuff ${mulField}=${mulValue} < 1.0 (debuffs typically amplify loss; consider type='buff')`
        })
      }
    }
  }
}

function validateRiskForBuild(
  risk: unknown,
  fieldPath: string,
  entryId: string | null,
  issues: ValidationIssue[]
): void {
  if (typeof risk !== 'object' || risk === null) {
    issues.push({
      severity: 'error',
      entryId,
      field: fieldPath,
      message: 'risk must be an object'
    })
    return
  }
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const r = risk as any

  if (typeof r.chance !== 'number' || r.chance < 0 || r.chance > 1) {
    issues.push({
      severity: 'error',
      entryId,
      field: `${fieldPath}.chance`,
      message: `risk.chance must be in [0,1] (got ${r.chance})`
    })
  }
}

/**
 * Validate an array of events from a single file. Detects within-file id duplicates.
 */
export function validateEventArrayForBuild(events: unknown): ValidationIssue[] {
  if (!Array.isArray(events)) {
    return [
      {
        severity: 'error',
        entryId: null,
        field: '<root>',
        message: 'Top-level value must be an array of events'
      }
    ]
  }

  const issues: ValidationIssue[] = []
  const seenIds = new Set<string>()

  for (const entry of events) {
    issues.push(...validateEventForBuild(entry))
    // Duplicate ID detection within the same file
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const id = (entry as any)?.id
    if (typeof id === 'string' && id.length > 0) {
      if (seenIds.has(id)) {
        issues.push({
          severity: 'error',
          entryId: id,
          field: 'id',
          message: `Duplicate id "${id}" within the same file`
        })
      }
      seenIds.add(id)
    }
  }

  return issues
}

export function formatIssue(file: string, issue: ValidationIssue): string {
  const tag = issue.severity === 'error' ? '[ERROR]' : '[WARN]'
  const id = issue.entryId ?? '<no-id>'
  return `${tag} ${file} :: ${id} :: ${issue.field}: ${issue.message}`
}
