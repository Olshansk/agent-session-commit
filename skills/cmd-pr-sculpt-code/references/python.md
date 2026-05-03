# Python-Specific Sculpting Guide

Additional patterns to apply when sculpting Python codebases. These supplement the main SKILL.md dimensions.

## Data Classes & Structure

- Use `@dataclass` or `typing.NamedTuple` instead of dicts for structured data with known fields
- Group related parameters into a dataclass when a function takes 4+ related args
- Prefer dataclass return types over tuples or dicts for multi-value returns

## Python Naming Conventions

- `snake_case` for functions, methods, variables, modules
- `PascalCase` for classes
- `UPPER_SNAKE_CASE` for constants
- `_private_prefix` for internal helpers
- Avoid type-in-name (`user_dict`, `name_string`) — let type hints handle that

## Nesting Patterns

```python
# Before: deep nesting
def process(data, type, config, user_id, db):
    if type == "a":
        if config["enabled"]:
            result = []
            for item in data:
                if item["valid"]:
                    x = db.get(item["id"])
                    if x:
                        result.append(x)
            return result

# After: flat, named, typed
@dataclass
class ProcessConfig:
    enabled: bool
    process_type: str

@dataclass
class Item:
    id: str
    valid: bool

def process_items(
    items: list[Item],
    config: ProcessConfig,
    user_id: str,
    db: Database,
) -> list[Entity]:
    if not _should_process(config):
        return []

    valid_items = [item for item in items if item.valid]
    return _fetch_entities(valid_items, db)

def _should_process(config: ProcessConfig) -> bool:
    return config.process_type == "a" and config.enabled

def _fetch_entities(items: list[Item], db: Database) -> list[Entity]:
    return [entity for item in items if (entity := db.get(item.id))]
```

**What improved:**
- Dataclasses replace raw dicts
- Explicit variable names (`valid_items` not `result`)
- Single-responsibility functions
- Nesting reduced from 4 to 1-2 levels
- Type hints for clarity
- Private helpers with `_` prefix

## Idiomatic Python

- List/dict/set comprehensions over manual loops for simple transforms
- `pathlib.Path` over `os.path` for file operations
- f-strings over `.format()` or `%` formatting
- `contextlib.contextmanager` for resource management patterns
- `functools.lru_cache` / `@cache` for pure-function memoization
- `enum.Enum` for fixed sets of options (not string constants)
- `typing.Protocol` over ABC when you only need structural subtyping

## File Organization

- One primary class per file (with private helpers)
- `__init__.py` re-exports public API only
- Keep models/types in dedicated files, not mixed with business logic
- Test file mirrors source file: `services/auth.py` → `tests/services/test_auth.py`
