--!strict
--[[
	Title: Initializer (v1.5.3 updated 06/15/2026)
	Authors: Mono (@Mono_Codes)
]]

-- Services
const RunService = game:GetService("RunService");

-- Constants
const IS_CLIENT: boolean = RunService:IsClient();
const IS_SERVER: boolean = RunService:IsServer();
const IS_STUDIO: boolean = RunService:IsStudio();

const SIDE_PREFIX: string = IS_SERVER and "Server" or "Client";

-- Debugging
local function __outputMessage(output: (...any) -> (any), message: string, usePrefix: boolean): ()
	if (not IS_STUDIO) then
		return;
	end
	
	output(usePrefix and (`[{script.Name}]: {message}`) or message);
end

-- Class
local Initializer = {
	_initialized = {};
	_modules = {};
	_sorted = {};
};

--[[
	Entry point for the system. Resolves the module container, collects modules,
	sorts them, and executes their Init methods in order.
	
	@param self Private
	@param container Instance | string -- The container to load modules from, resolves into an Instance if a string is passed
	@param ... any -- Extra arguments to pass to initialized modules
	
	@return void
]]
function Initializer.Initialize(self: Private, container: Instance | string, ...: any): ()	
	if (typeof(container) == "string") then
		local root = (IS_CLIENT
			and game:GetService("ReplicatedStorage")
			or game:GetService("ServerStorage")
		);
		
		container = root:FindFirstChild(container) or root:WaitForChild(container);
	end
	
	if (typeof(container) ~= "Instance") then
		__outputMessage(error, `Could not resolve container as Instance, got {typeof(container)}`, true);
	end
	
	local resolvedContainer: Instance = container :: Instance;
	assert(not self._initialized[resolvedContainer], (`{SIDE_PREFIX} systems under {resolvedContainer:GetFullName()} are already initialized.`));
	
	local startTime: number = os.clock();
	
	__outputMessage(print,
		(`Initializing {IS_SERVER and "Server" or "Client"} modules in {resolvedContainer:GetFullName()}`),
		true
	);
	
	self:_cacheModules(resolvedContainer);
	self:_sortModules();
	self:_initModules(...);
	
	__outputMessage(print,
		(`{SIDE_PREFIX} initialized after {string.format("%.3f", os.clock() - startTime)} seconds!\n`),
		true
	);
	
	self._initialized[resolvedContainer] = true;
end

--[[
	Recursively scans a container for ModuleScripts, requires them safely, and stores
	valid modules. Skips instances marked with "NoInitializing".

	@param self Private
	@param container Instance -- The instance to load modules from
	
	@return void
]]
function Initializer._cacheModules(self: Private, container: Instance): ()
	for _, child in (container:GetChildren()) do
		if (child:GetAttribute("NoInitializing")) then
			continue;
		end
		
		if (child:IsA("ModuleScript")) then
			local success: boolean, module: any = pcall(require, child);
			
			if (success and module) then
				self._modules[child.Name] = module;
			else
				__outputMessage(warn,
					(`Failed to require module at {child:GetFullName()}`),
					true
				);
			end
			
		elseif (child:IsA("Folder")) then
			self:_cacheModules(child);
		end
	end
end

--[[
	Builds a sorted execution list from cached modules. Sorts by Priority (descending),
	then Name (ascending).

	@param self Private
	
	@return void
]]
function Initializer._sortModules(self: Private): ()
	local list: { Sortable } = {};
	
	for name, module in (self._modules) do
		list[#list + 1] = {
			Name = name;
			Module = module;
			Priority = module.Priority or 0;
		};
	end
	
	table.sort(list, function(a: Sortable, b: Sortable)
		if (a.Priority == b.Priority) then
			return a.Name < b.Name;
		end

		return a.Priority > b.Priority;
	end)
	
	self._sorted = list;
end

--[[
	Executes the Init method of each module in sorted order. Collects success/failure
	results and outputs debug information.

	@param self Private
	@param ... any -- Extra arguments to pass to initialized modules
	
	@return number -- Number of modules initialized
]]
function Initializer._initModules(self: Private, ...: any): (number)
	local args: { any } = {...};
	local loadedNames: { string } = {};
	
	for _, entry in (self._sorted) do		
		if (typeof(entry.Module.Init) == "function") then
			local success: boolean, err: any = xpcall(function()
				return entry.Module:Init(table.unpack(args));
			end, function(message: string?)
				return debug.traceback(message);
			end)
			
			if (not success) then
				__outputMessage(warn,
					(`Error initializing {entry.Name}:\n{err}`),
					true
				);
			end
		end
		
		loadedNames[#loadedNames + 1] = entry.Name;
	end
	
	if (#loadedNames > 0) then
		__outputMessage(print,
			(`\t- Loaded {#loadedNames} module{#loadedNames > 1 and "s" or ""}: {table.concat(loadedNames, ", ")}`),
			true
		);
	end
	
	return #loadedNames;
end

-- Types
export type Initializer = {
	Initialize: (self: Initializer, container: Instance | string, ...any) -> ();
};

type Private = Initializer & {
	_initialized: { [Instance]: boolean };
	_modules: { [string]: Initializable };
	_sorted: { Sortable };
	
	_cacheModules: (self: Private, container: Instance) -> ();
	_sortModules: (self: Private) -> ();
	_initModules: (self: Private, ...any) -> (number);
};

type Initializable = {
	Priority: number?;
	Init: (self: Initializable, ...any) -> (any)
};

type Sortable = {
	Name: string;
	Module: Initializable;
	Priority: number;
};

return Initializer :: Initializer;
