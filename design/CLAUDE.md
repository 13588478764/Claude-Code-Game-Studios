# Design Directory

When authoring or editing files in this directory, follow these standards.

## GDD Files (`design/gdd/`)

Every GDD must include all **8 required sections** in this order:
1. Overview — one-paragraph summary
2. Player Fantasy — intended feeling and experience
3. Detailed Rules — unambiguous mechanics
4. Formulas — all math defined with variables
5. Edge Cases — unusual situations handled
6. Dependencies — other systems listed
7. Tuning Knobs — configurable values identified
8. Acceptance Criteria — testable success conditions

**File naming:** `[system-slug].md` (e.g. `movement-system.md`, `combat-system.md`)

**Systems index:** `design/gdd/systems-index.md` — update when adding a new GDD.

**Design order:** Foundation → Core → Feature → Presentation → Polish

**Validation:** Run `/design-review [path]` after authoring any GDD.
Run `/review-all-gdds` after completing a set of related GDDs.

## Level Design Docs (`design/levels/`)

Per-region content design docs (LDD) for the visual-novel scene mode — scene lists,
NPC placements, encounter pools, enemy configs, pacing, audio/visual asset needs,
and technical mapping to `GameLoopManager.REGIONS`.

**File naming:** `act[N]-[region-slug].md` (e.g. `act1-qingyun-town.md`)

**Current docs (Act 1):** `act1-qingyun-town.md`（青云镇）, `act1-heifeng-stronghold.md`（黑风寨）,
`act1-qingyun-mountain.md`（青云山）, `act1-jiangnan-water-town.md`（江南水乡）

**Region registry:** Region names/facts must also be registered in
`design/registry/entities.yaml` under the Act 1 区域 section to prevent cross-doc
naming drift (e.g. the 青石镇/青云镇 unification of 2026-07-21).

## Quick Specs (`design/quick-specs/`)

Lightweight specs for tuning changes, minor mechanics, or balance adjustments.
Use `/quick-design` to author.

## UX Specs (`design/ux/`)

- Per-screen specs: `design/ux/[screen-name].md`
- HUD design: `design/ux/hud.md`
- Interaction pattern library: `design/ux/interaction-patterns.md`
- Accessibility requirements: `design/ux/accessibility-requirements.md`

Use `/ux-design` to author. Validate with `/ux-review` before passing to `/team-ui`.
