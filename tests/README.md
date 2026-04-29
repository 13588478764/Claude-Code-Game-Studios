# Test Infrastructure

**Engine**: Godot 4.6  
**Test Framework**: GUT (Godot Unit Test)  
**CI**: `.github/workflows/tests.yml`  
**Setup date**: 2026-04-28

---

## Directory Layout

```
tests/
  unit/           # Isolated unit tests (formulas, state machines, logic)
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path test list for /smoke-check gate
  evidence/       # Screenshot logs and manual test sign-off records
```

---

## Running Tests

### In Godot Editor

1. Open Godot Editor
2. Go to `Tools > GUT > Run Tests`
3. Select test directory or specific test file
4. View results in the GUT panel

### Command Line (Headless)

```bash
# Run all tests
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests

# Run specific directory
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit

# Run specific test file
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests/unit/character/character_leveling_test.gd

# Generate coverage report
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests -gcoverage
```

### GitHub Actions CI

Tests run automatically on every push to `main` and on every pull request.
A failed test suite blocks merging.

View results: **Actions** tab in GitHub repository

---

## Test Naming Conventions

### File Naming

- **Pattern**: `[system]_[feature]_test.gd`
- **Examples**:
  - `combat_damage_test.gd`
  - `character_leveling_test.gd`
  - `equipment_attribute_test.gd`

### Function Naming

- **Pattern**: `test_[scenario]_[expected]()`
- **Examples**:
  - `test_base_attack_returns_expected_damage()`
  - `test_level_up_grants_attribute_points()`
  - `test_equipment_bonus_applies_correctly()`

### Test Organization

```gdscript
extends GutTest

# Setup and teardown
func before_each():
    # Run before each test
    pass

func after_each():
    # Run after each test
    pass

# Test cases
func test_scenario_one():
    # Arrange
    var character = create_test_character()
    
    # Act
    character.gain_experience(100)
    
    # Assert
    assert_eq(character.level, 2, "Character should level up")

func test_scenario_two():
    # Test implementation
    pass
```

---

## Story Type → Test Evidence

| Story Type | Required Evidence | Location | Notes |
|---|---|---|---|
| **Logic** | Automated unit test — must pass | `tests/unit/[system]/` | 100% acceptance criteria coverage |
| **Integration** | Integration test OR playtest doc | `tests/integration/[system]/` | Cross-system interaction verification |
| **Visual/Feel** | Screenshot + lead sign-off | `tests/evidence/` | Visual quality and game feel validation |
| **UI** | Manual walkthrough OR interaction test | `tests/evidence/` | UI layout, interaction, responsiveness |
| **Config/Data** | Smoke check pass | `production/qa/smoke-*.md` | Data integrity and configuration validation |

---

## GUT Framework Features

### Assertions

```gdscript
# Equality
assert_eq(actual, expected, "message")
assert_ne(actual, expected, "message")

# Comparison
assert_gt(actual, expected, "message")
assert_lt(actual, expected, "message")
assert_gte(actual, expected, "message")
assert_lte(actual, expected, "message")

# Type checking
assert_is(obj, type, "message")
assert_is_not(obj, type, "message")

# String matching
assert_string_contains(string, substring, "message")
assert_string_starts_with(string, prefix, "message")

# Collections
assert_has(array, value, "message")
assert_does_not_have(array, value, "message")
```

### Signal Testing

```gdscript
# Watch signals
watch_signals(object)

# Assert signal was emitted
assert_signal_emitted(object, "signal_name")
assert_signal_emitted_with_parameters(object, "signal_name", [param1, param2])

# Assert signal was NOT emitted
assert_signal_not_emitted(object, "signal_name")
```

### Stubbing and Doubling

```gdscript
# Create a stub
var stub = stub(MyClass).set_return_value("method_name", return_value)

# Create a spy
var spy = spy(object)
spy.method_name()
assert_called(spy, "method_name")
```

---

## Test Coverage Goals

- **Unit Tests**: 100% of acceptance criteria coverage
- **Integration Tests**: All critical cross-system interactions
- **Overall Code Coverage**: ≥ 70%

Monitor coverage with:
```bash
godot --headless --script addons/gut/gut_cmdln.gd -gdir=tests -gcoverage
```

---

## Installing GUT Framework

GUT is already installed in `addons/gut/`. To verify:

1. Open Godot Editor
2. Go to `Project > Project Settings > Plugins`
3. Search for "GUT"
4. Ensure the plugin is **enabled** (checkbox is checked)
5. Restart the editor if you just enabled it

If GUT is not installed:
1. Open Godot Editor
2. Go to `AssetLib` tab
3. Search for "GdUnit4"
4. Click "Download" and then "Install"
5. Enable the plugin in Project Settings

---

## CI/CD Pipeline

### GitHub Actions Workflow

The `.github/workflows/tests.yml` file automatically:
- Runs on every push to `main`
- Runs on every pull request
- Executes all tests in `tests/unit/` and `tests/integration/`
- Generates test reports
- Blocks merging if tests fail

### Viewing Test Results

1. Go to **Actions** tab in GitHub
2. Click on the workflow run
3. View test results and logs
4. Download test artifacts if needed

---

## Best Practices

### Writing Good Tests

1. **One assertion per test** (when possible)
2. **Clear test names** that describe what is being tested
3. **Arrange-Act-Assert pattern**:
   - Arrange: Set up test data
   - Act: Execute the code being tested
   - Assert: Verify the results

4. **Test edge cases**:
   - Boundary values
   - Empty/null inputs
   - Maximum/minimum values
   - Invalid inputs

5. **Keep tests independent**:
   - No test should depend on another test
   - Use `before_each()` to reset state

### Debugging Tests

1. **Run single test**: Right-click test in GUT panel → Run
2. **Add debug output**: Use `print()` statements
3. **Use breakpoints**: Set breakpoints in test code
4. **Check GUT logs**: View detailed error messages in GUT panel

---

## Troubleshooting

### Tests Not Running

- **Check GUT is enabled**: Project Settings > Plugins > GUT
- **Check file naming**: Must end with `_test.gd`
- **Check class extends**: Must extend `GutTest`
- **Check test functions**: Must start with `test_`

### Tests Failing

- **Read error message**: GUT provides detailed failure information
- **Check assertions**: Verify expected vs actual values
- **Check setup**: Ensure `before_each()` properly initializes test data
- **Check dependencies**: Ensure required systems are initialized

### Performance Issues

- **Profile tests**: Use GUT's built-in profiler
- **Optimize setup**: Move expensive operations out of `before_each()`
- **Use mocks**: Mock external dependencies to speed up tests
- **Parallel execution**: GUT can run tests in parallel (see GUT docs)

---

## Resources

- **GUT Documentation**: https://github.com/bitwes/Gut/wiki
- **Godot Testing Guide**: https://docs.godotengine.org/en/stable/contributing/development/testing/index.html
- **GDScript Reference**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html

---

## Contact & Support

For test framework issues:
1. Check GUT documentation
2. Review existing test examples in `tests/unit/` and `tests/integration/`
3. Ask in project discussions or team chat

---

**Last Updated**: 2026-04-28  
**Next Review**: 2026-05-11