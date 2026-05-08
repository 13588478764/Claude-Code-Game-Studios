# Adoption Plan

> **Generated**: 2026-05-04
> **Project phase**: Production
> **Engine**: Godot 4.6
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Fix Blocking Gaps

### 1.1 Fix ADR-001 `## Status` heading

**Problem**: `adr-001-core-architecture-decisions.md` uses Chinese `## 状态` instead of English `## Status`, causing `/story-readiness` ADR status checks to silently pass everything.

**Fix**: Edit the file and change `## 状态` to `## Status`.

**Time**: 5 minutes

- [ ] Change `## 状态` to `## Status` in `adr-001-core-architecture-decisions.md`

### 1.2 Resolve ADR-001 duplicate version conflict

**Problem**: Two ADR-001 files coexist (`adr-001-core-architecture-decisions.md` and `ADR-001-core-architecture.md`), creating ambiguity for skills reading ADR status.

**Fix**: Confirm `ADR-001-core-architecture.md` as authoritative version (more complete, has Engine Compatibility and other required sections). Delete or archive the deprecated version.

**Time**: 15 minutes

- [ ] Decide which ADR-001 is authoritative
- [ ] Delete or archive deprecated version

---

## Step 2: Fix High-Priority Gaps

### 2.1 Add `## GDD Requirements Addressed` to ADR-001 (authoritative)

**Problem**: ADR-001 lacks GDD requirements traceability, degrading traceability matrix coverage.

**Fix**: Add `## GDD Requirements Addressed` section listing which GDDs this ADR supports.

**Command**: `/architecture-decision update docs/architecture/ADR-001-core-architecture.md` or manual edit

**Time**: 15 minutes

- [ ] ADR-001 includes `## GDD Requirements Addressed` section

### 2.2 Add `## ADR Dependencies` to ADR-001 (authoritative)

**Problem**: ADR-001 lacks ADR dependency declaration, breaking `/architecture-review` dependency ordering.

**Fix**: Add `## ADR Dependencies` section listing any dependent ADRs (or "None" if standalone).

**Time**: 10 minutes

- [ ] ADR-001 includes `## ADR Dependencies` section

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (creates tr-registry.yaml)

Run `/architecture-review` -- even if ADRs already exist, this run bootstraps
the TR registry from your existing GDDs and ADRs.

**Time**: 1 session (review can be long for large codebases)

- [ ] tr-registry.yaml created

### 3b. Create control manifest

Run `/create-control-manifest`

**Time**: 30 min

- [ ] docs/architecture/control-manifest.md created

### 3c. Create sprint tracking file

Run `/sprint-plan update`

**Time**: 5 min (if sprint plan already exists as markdown)

- [ ] production/sprint-status.yaml created

### 3d. Set authoritative project stage

Run `/gate-check [current-phase]`

**Time**: 5 min

- [ ] production/stage.txt written

---

## Step 4: Medium-Priority Gaps

### 4.1 Confirm Chinese heading pattern matching in template skills

**Problem**: ~30+ GDDs use Chinese headings (e.g. `## 概述`), but SKILL.md pattern matching already includes Chinese variants like `## 详细设计`.

**Status**: This is NOT a gap -- pattern matching already supports Chinese headings per CLAUDE.md coding standards.

**Time**: No action needed

- [ ] Confirm template skill heading pattern matching supports Chinese headings

---

## Step 5: Optional Improvements

### 5.1 Story format consistency

**Problem**: 147 stories exist with generally good format. Some may benefit from TR-ID staleness tracking or Manifest Version stamps.

**Fix**: Regenerate stories only when they are completed or no longer in active progress.

**Time**: Per-story, as needed

- [ ] Stories regenerated with new format when appropriate

### 5.2 Technical Preferences audit completion

**Problem**: `.claude/docs/technical-preferences.md` may have unconfigured fields (Forbidden Patterns, Allowed Libraries).

**Fix**: Review and populate as architectural decisions are made.

**Time**: Ongoing

- [ ] Forbidden Patterns populated as decisions are made
- [ ] Allowed Libraries populated as dependencies are approved

---

## What to Expect from Existing Stories

Existing stories continue to work with all template skills. New format checks
(TR-ID validation, manifest version staleness) auto-pass when the fields are
absent -- so nothing breaks. They won't benefit from staleness tracking until
regenerated. Do not regenerate stories that are in progress or done.

---

## Re-run

Run `/adopt` again after completing Step 3 to verify all blocking and high gaps
are resolved. The new run will reflect the current state of the project.
