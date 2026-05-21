/**
 * Build-time event JSON validator. Run via `tsx tools/validate-events.ts`.
 *
 * Scans:
 *   - src/static/events/*.json (main package commons)
 *   - src/subpackages/events/*.json (per-job event packs)
 *
 * For each file, validates each event entry. Errors block the build (exit 1);
 * warnings are reported but do not block.
 *
 * Also detects cross-file ID collisions (which would corrupt EventDataEngine
 * lookup at runtime).
 *
 * Wired into npm prebuild scripts so `npm run build:mp-weixin` (etc.) automatically
 * fails on bad data.
 */

import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { dirname } from 'node:path'
import {
  validateEventArrayForBuild,
  formatIssue,
  type ValidationIssue
} from '../src/services/event-data/event-schema'

const __dirname = dirname(fileURLToPath(import.meta.url))
const PROJECT_ROOT = join(__dirname, '..')

const EVENT_DIRS: string[] = [
  join(PROJECT_ROOT, 'src/static/events'),
  join(PROJECT_ROOT, 'src/subpackages/events')
]

interface FileIssue {
  file: string
  issue: ValidationIssue
}

function listJsonFiles(dir: string): string[] {
  if (!existsSync(dir)) return []
  return readdirSync(dir)
    .filter((name) => name.endsWith('.json'))
    .map((name) => join(dir, name))
    .filter((path) => statSync(path).isFile())
}

function validateFile(filePath: string): FileIssue[] {
  const relPath = relative(PROJECT_ROOT, filePath)
  let parsed: unknown
  try {
    parsed = JSON.parse(readFileSync(filePath, 'utf-8'))
  } catch (err) {
    return [
      {
        file: relPath,
        issue: {
          severity: 'error',
          entryId: null,
          field: '<file>',
          message: `Invalid JSON: ${(err as Error).message}`
        }
      }
    ]
  }
  return validateEventArrayForBuild(parsed).map((issue) => ({ file: relPath, issue }))
}

function detectCrossFileDuplicates(allFiles: string[]): FileIssue[] {
  const idToFiles = new Map<string, string[]>()
  for (const file of allFiles) {
    const relPath = relative(PROJECT_ROOT, file)
    let parsed: unknown
    try {
      parsed = JSON.parse(readFileSync(file, 'utf-8'))
    } catch {
      continue
    }
    if (!Array.isArray(parsed)) continue
    for (const entry of parsed) {
      const id = (entry as { id?: unknown })?.id
      if (typeof id === 'string' && id.length > 0) {
        const list = idToFiles.get(id) ?? []
        list.push(relPath)
        idToFiles.set(id, list)
      }
    }
  }

  const issues: FileIssue[] = []
  for (const [id, files] of idToFiles) {
    if (files.length > 1) {
      // Report against the second-and-later occurrences
      for (let i = 1; i < files.length; i++) {
        issues.push({
          file: files[i]!,
          issue: {
            severity: 'error',
            entryId: id,
            field: 'id',
            message: `Duplicate id "${id}" — first defined in ${files[0]}`
          }
        })
      }
    }
  }
  return issues
}

function main(): void {
  const allFiles: string[] = []
  for (const dir of EVENT_DIRS) {
    allFiles.push(...listJsonFiles(dir))
  }

  if (allFiles.length === 0) {
    console.log('[validate-events] No event JSON files found — skipping')
    process.exit(0)
  }

  console.log(`[validate-events] Validating ${allFiles.length} event file(s)...`)

  const allIssues: FileIssue[] = []
  for (const file of allFiles) {
    allIssues.push(...validateFile(file))
  }
  allIssues.push(...detectCrossFileDuplicates(allFiles))

  const errors = allIssues.filter((fi) => fi.issue.severity === 'error')
  const warnings = allIssues.filter((fi) => fi.issue.severity === 'warn')

  for (const w of warnings) {
    console.warn(formatIssue(w.file, w.issue))
  }
  for (const e of errors) {
    console.error(formatIssue(e.file, e.issue))
  }

  if (errors.length > 0) {
    console.error(
      `\n✗ Validation failed: ${errors.length} error(s), ${warnings.length} warning(s).`
    )
    console.error('Build aborted. Fix the errors above and re-run.')
    process.exit(1)
  }

  console.log(`✓ Event validation passed (${warnings.length} warnings)`)
  process.exit(0)
}

main()
