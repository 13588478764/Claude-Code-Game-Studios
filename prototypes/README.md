# Prototypes

Throwaway implementations used to validate game concepts and mechanics before
committing to production-quality code.

## Active Prototypes

| Name | Purpose | Status | Date Created |
|------|---------|--------|-------------|
| - | - | - | - |

## Completed Prototypes

| Name | Purpose | Verdict | Date Completed |
|------|---------|---------|---------------|
| - | - | - | - |

## Creating a New Prototype

1. Create a subdirectory: `prototypes/[prototype-name]/`
2. Include a `README.md` with:
   - **Purpose**: What concept is being validated
   - **Test Method**: How to validate the prototype
   - **Findings**: What was learned
   - **Verdict**: `Proceed`, `Pivot`, or `Abandon`
3. Copy relevant code/scenes from `src/` if needed (do NOT modify src/ directly)
4. Prototype files should be prefixed with `prototype-` for easy identification

## Naming Convention

- Directory: `prototypes/[prototype-slug]/`
- README: `prototypes/[prototype-slug]/README.md`
- Code: Use `prototype_` prefix for scripts (e.g. `prototype_combat_flow.gd`)
