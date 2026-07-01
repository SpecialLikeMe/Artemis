# 22. Package Manager

`aciso` manages third-party Artemis packages. Packages live in `modules/<name>/` relative to the project root.

## Installing a Package

```
aciso install math https://github.com/example/artemis-math
```

This clones the repository, reads its `export.toml`, and copies the exported `.arc` files into `modules/math/`.

## Uninstalling

```
aciso uninstall math
```

## Updating

```
aciso update math       # update one package
aciso update            # update all packages
```

## Importing a Package in Source

```arc
extern aciso.math;
extern aciso.strings;
```

The compiler expands this before parsing: all source files from `modules/math/` are prepended to the compilation unit. If the package is not installed, the compiler aborts with a clear error message.

Binary packages (precompiled `.a` or `.o` files in the package directory) are linked automatically by the build system.

## Authoring a Package (`export.toml`)

```toml
[package]
name    = "math"
version = "0.1.0"

export = [
    "math.arc",
    "trig.arc",
    "vec.arc"
]
```

Files listed under `export` form the public API. Internal implementation files that should not be imported directly are omitted.

## Auditing Dependencies

```
aciso audit    # check installed packages against known-bad hashes
aciso vald     # verify installed packages match their manifests
```

---

[Prev: Build System](21_build_system.md) | [Next: Language Reference](23_reference.md)
