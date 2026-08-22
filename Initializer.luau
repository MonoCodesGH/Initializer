--!strict
--[[
	Title: Initializer (v1.5.4 updated 08/10/2026)
	Authors: Mono (@Mono_Codes)
	Github: https://github.com/MonoCodesGH/Initializer
]]

-- Services
const TestService = game:GetService("TestService");
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

-- Class
const Initializer = {
	_initialized = {};
	_modules = {};
	_sorted = {};
};

function Initializer.Initialize(self: Private, container: Instance | string, ...: any): ()	
	if (typeof(container) == "string") then
		const root = (IS_CLIENT
			and game:GetService("ReplicatedStorage")
			or game:GetService("ServerStorage")
		);
		
		container = root:FindFirstChild(container) or root:WaitForChild(container);
	end
	
	if (typeof(container) ~= "Instance") then
		__outputMessage(error, `Could not resolve container as Instance, got {typeof(container)}`, true);
	end
	
	const resolvedContainer: Instance = container :: Instance;
	assert(not self._initialized[resolvedContainer], (`{SIDE_PREFIX} systems under {resolvedContainer:GetFullName()} are already initialized.`));
	
	const startTime = os.clock();
	
	__outputMessage(print,
		(`Initializing {SIDE_PREFIX} modules in {resolvedContainer:GetFullName()}`),
		true
	);
	
	self:_cacheModules(resolvedContainer);
	self:_sortModules();
	
	const totalModules = self:_initModules(...);
	const timeToLoad = `Total time to initialize: {string.format(`%.2f`, os.clock() - startTime)} seconds`;
	const totalComponents = `Total Components loaded: {totalModules}`;
	TestService:Message(`\n\n{script.Name}\n\nSuccessfully initialized {SIDE_PREFIX} systems!\n{timeToLoad}\n{totalComponents}`);
	
	self._initialized[resolvedContainer] = true;
end

function Initializer._cacheModules(self: Private, container: Instance): ()
	if (container:GetAttribute("NoInitializing")) then
		return;
	end
	
	for _, child in (container:GetChildren()) do
		if (child:GetAttribute("NoInitializing")) then
			continue;
		end
		
		if (child:IsA("ModuleScript")) then
			const success, module = pcall(require, child);
			
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

function Initializer._sortModules(self: Private): ()
	const list: { Sortable } = {};
	
	for name, module in (self._modules) do
		list[#list + 1] = {
			Name = name;
			Module = module;
			Priority = module.Priority or 0;
		};
	end
	
	table.sort(list, function(a: Sortable, b: Sortable): (boolean)
		if (a.Priority == b.Priority) then
			return a.Name < b.Name;
		end

		return a.Priority > b.Priority;
	end)
	
	self._sorted = list;
end

function Initializer._initModules(self: Private, ...: any): (number)
	const args = {...};
	const loadedNames = {};
	
	for _, entry in (self._sorted) do		
		if (typeof(entry.Module.Init) == "function") then
			const success, err = xpcall(function(): (string)
				return entry.Module:Init(table.unpack(args));
			end, function(message: string?): (string?)
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

return Initializer :: Initializer;
