# 21. Build System

`aciso` is both the build system and the package manager. Build configuration lives in `aciso.toml` at the project root.

## Initialise a Project

```
aciso init
```

Creates `aciso.toml` and a default project layout.

## `aciso.toml` — Project Configuration

```toml
[project]
name    = "my_project"
version = "0.1.0"

[[target]]
name    = "main"
type    = "exe"
sources = ["src/main.arc", "src/utils.arc"]

[[target]]
name    = "mylib"
type    = "lib"
sources = ["src/lib.arc"]
```

**Target types:**
- `exe` — produces an executable
- `lib` — produces a static library

## Building

```
aciso build             # debug build (all targets)
aciso build --release   # optimised build
aciso build mylib       # build a specific target by name
```

Output goes to `build/`.

## Running

```
aciso run               # build and run the default exe target
aciso run main          # run a specific exe target
```

## Cleaning

```
aciso clean             # remove build artifacts
aciso cache             # show cached object files
aciso uncache           # clear the object cache
```

## Cross-Compilation

The underlying `arc` compiler accepts a `--target` flag. Pass it through aciso with:
```
aciso build --target x86_64-linux-gnu
```

---

[Prev: The defer Statement](20_defer.md) | [Next: Package Manager](22_package_manager.md)
