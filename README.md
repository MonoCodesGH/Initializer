# Initializer

Initializer is a lightweight module loader used to automatically require and initialize ModuleScripts within a specified container. The Initializer recursively searches through folders, requires each ModuleScript, and invokes its `Init` method if present.

Modules are initialized in a deterministic order using an optional "Priority" field, allowing control over executation order (higher priority modules run first). Modules without a Priority default to 0 and are secondarily sorted alphabetically.

Modules can also opt out of automatic initialization by setting a "NoInitialing" attribute to true.

While running in Studio, the Initializer outputs debug information, including loaded modules and total initialization time.
		
While a simple loop could be used to require and initiate modules, this abstraction provides a more structured and reusable solution. It handles recrusive discovery, priority-based ordering, consistent initialization behavior, optional debugging output, and centralized startup logic allowing systems to scale cleanly without requiring large numbers of Scripts and LocalScripts.
