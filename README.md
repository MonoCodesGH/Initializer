# Initializer

**Initializer** is a lightweight module loader for Roblox that automatically discovers, requires, sorts, and initializes `ModuleScripts` within a specified container.

The module recursively scans folders, requires discovered modules, and invokes their `Init()` method when available. Initialization order is deterministic and controlled through an optional `Priority` field, allowing critical systems to start before their dependencies. Modules with higher priorities initialize first, while modules sharing the same priority are sorted alphabetically.

Require and initialization errors are isolated and logged while running in Studio, allowing startup to continue even if individual modules fail. Containers are also protected against being initialized multiple times during the same runtime.

While a simple loop can be used to require modules manually, Initializer provides a consistent and reusable framework for managing application startup. By centralizing module discovery, dependency ordering, error handling, and debug output, it helps keep large projects organized and reduces the need for extensive Script and LocalScript bootstrap code.

# Features

* Recursive module discovery
* Automatic `Init()` execution
* Priority-based initialization order
* Alphabetical fallback sorting
* Automatic container resolution from string paths
* Fault-tolerant initialization
* Single-initialization protection
* Optional module exclusion via the `NoInitializing` attribute
* Studio-only debug logging and performance metrics
* Centralized startup management for scalable projects

## Initialization Order

Modules are sorted using the following rules:

1. Higher `Priority` values initialize first.
2. Modules with equal priorities are sorted alphabetically by name.
3. Modules without a `Priority` field default to `0`.

## Excluding Modules

To prevent a `ModuleScript` or `Folder` from being discovered and initialized automatically, set the `NoInitializing` attribute to `true`.

```lua
folder:SetAttribute("NoInitializing", true)
```

## Initialization Safety

A container can only be initialized once per runtime. Attempting to initialize the same container multiple times will throw an error.

## Debugging

When running in Studio, Initializer outputs:

* The initialization target container
* Loaded module names
* Module loading failures
* Initialization errors with stack traces
* Total startup time

This provides visibility into the startup process while keeping production environments free of unnecessary logging.

# Usage

Initialize all modules within a container from a `Script` or `LocalScript`:

```lua
local Initializer = require("@game/ReplicatedStorage/Packages/Initializer")

Initializer:Initialize(script.Parent.Modules)
```

You can also pass additional arguments to every module's `Init()` method:

```lua
Initializer:Initialize(script.Parent.Modules, LocalPlayer, data)
```

Example module:

```lua
local ExampleModule = {
	Priority = 100;
}

function ExampleModule.Init(
	self: typeof(ExampleModule),
	LocalPlayer: Player
): ()
	print("Hello", LocalPlayer.Name)
	print("ExampleModule initialized!")
end

return ExampleModule
```

Modules are initialized automatically in priority order. Any discovered module that exposes an `Init()` function will have that function invoked during initialization.

# API Reference

| Method                           | Parameters                                        | Returns | Description                                                                                                                                                           |
| -------------------------------- | ------------------------------------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Initialize(container, ...args)` | `container: Instance \| string`<br>`...args: any` | `nil`   | Discovers, requires, sorts, and initializes all eligible modules within the specified container. Additional arguments are forwarded to each module's `Init()` method. |

## Module Interface

Modules loaded by Initializer can optionally implement the following members:

| Member     | Type              | Required | Description                                                                                              |
| ---------- | ----------------- | -------- | -------------------------------------------------------------------------------------------------------- |
| `Priority` | `number`          | No       | Determines initialization order. Higher values initialize first. Defaults to `0` when omitted.           |
| `Init`     | `(...any) -> any` | No       | Called automatically during initialization. Receives any arguments passed to `Initializer:Initialize()`. |

## Container Resolution

When a string is passed instead of an `Instance`, Initializer resolves the container automatically.

| Environment | Root Service        |
| ----------- | ------------------- |
| Server      | `ServerStorage`     |
| Client      | `ReplicatedStorage` |

Example:

```lua
Initializer:Initialize("Services")
```

The above resolves to:

```lua
-- Server
ServerStorage.Services

-- Client
ReplicatedStorage.Services
```

## Module Attributes

| Attribute        | Type      | Default | Description                                                              |
| ---------------- | --------- | ------- | ------------------------------------------------------------------------ |
| `NoInitializing` | `boolean` | `false` | Prevents a ModuleScript or Folder from being discovered and initialized. |
