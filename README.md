# Initializer

**Initializer** is a lightweight module loader for Roblox that automatically discovers, requires, and initializes `ModuleScripts` within a specified container.

The module recursively scans folders, safely requires discovered modules, and invokes their `Init()` method when available. Initialization order is deterministic and controlled through an optional `Priority` field, allowing critical systems to start before their dependencies. Modules with higher priorities initialize first, while modules sharing the same priority are sorted alphabetically.

While a simple loop can be used to require modules manually, Initializer provides a consistent and reusable framework for managing application startup. By centralizing module loading, dependency ordering, error handling, and debug output, it helps keep large projects organized and reduces the need for extensive Script and LocalScript bootstrap code.

# Features:

* Recursive module discovery
* Automatic `Init()` execution
* Priority-based initialization order
* Alphabetical fallback sorting
* Optional module exclusion via the `NoInitializing` attribute
* Studio-only debug logging and performance metrics
* Centralized startup management for scalable projects

### Initialization Order

Modules are sorted using the following rules:

1. Higher `Priority` values initialize first.
2. Modules with equal priorities are sorted alphabetically by name.
3. Modules without a `Priority` field default to `0`.

### Excluding Modules

To prevent a module or folder from being initialized automatically, set the `NoInitializing` attribute to `true`.

### Debugging

When running in Studio, Initializer outputs:

* The initialization target container
* Loaded module names
* Module loading failures
* Initialization errors with stack traces
* Total startup time

This provides visibility into the startup process while keeping production environments free of unnecessary logging.
