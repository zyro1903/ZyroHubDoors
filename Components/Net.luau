--[[
    ZyroHub :: Net
    --------------
    Enterprise-grade dependency loading:

      1. PINNING   - Every external dependency is fetched from a pinned commit
                     SHA, so a force-push upstream can never inject code into
                     already-shipped clients and a broken upstream commit can
                     never break users on the next run.
      2. CACHE     - Every successful download is mirrored to `ZyroHubCache/`.
                     If the network is down (or raw.githubusercontent is
                     blocked/rate-limited), the cached mirror is used and the
                     user is clearly notified instead of the hub crashing.
      3. SANITY    - Responses are validated before use (non-empty, not an
                     HTML error page) and every fetch/compile/runtime failure
                     is isolated and reported, never silent.
]]

local Net = {
	Pins = {
		-- deividcomsono/Obsidian @ main, verified 2026-08-31
		Obsidian = "0fd2685d460c2276556cd8ccd9516025882fe33a",
	},

	-- CacheKey -> "network" | "cache" | "failed"; surfaced in the Info tab.
	Status = {},
}

local function GetService(Name)
	local ok, Service = pcall(game.GetService, game, Name)
	if not ok or not Service then
		return nil
	end
	local Env = rawget(getgenv(), "ZyroHub")
	if Env and Env.Environment and Env.Environment.cloneref then
		local okCloned, Cloned = pcall(Env.Environment.cloneref, Service)
		if okCloned and Cloned then
			return Cloned
		end
	end
	return Service
end

local function Notify(Text)
	pcall(function()
		local StarterGui = GetService("StarterGui")
		if StarterGui then
			StarterGui:SetCore("SendNotification", {
				Title = "ZyroHub",
				Text = Text,
				Duration = 6
			})
		end
	end)
end

local Env = rawget(getgenv(), "ZyroHub") and ZyroHub.Environment or nil

local function HasFileSystem()
	return Env and Env.writefile and Env.readfile and Env.isfile
end

local function CachePath(CacheKey)
	return "ZyroHubCache/" .. CacheKey:gsub("[^%w%-_%.]", "_") .. ".lua"
end

-- Rejects empty bodies and HTML error pages (404/rate-limit responses).
local function IsValidSource(Source)
	return type(Source) == "string"
		and #Source > 32
		and Source:sub(1, 1) ~= "<"
end

local function EnsureCacheFolder()
	pcall(function()
		if Env.isfolder and Env.makefolder and not Env.isfolder("ZyroHubCache") then
			Env.makefolder("ZyroHubCache")
		end
	end)
end

function Net.Compile(Source, ChunkName)
	local Fn, Err = loadstring(Source, ChunkName or "ZyroHub")
	return Fn, Err
end

--- Fetches `Url`, caching under `CacheKey`, falling back to the cached mirror.
-- Returns the source string, or nil on total failure.
function Net:Fetch(CacheKey, Url)
	local Source
	local ok, Result = pcall(function()
		return game:HttpGet(Url)
	end)

	if ok and IsValidSource(Result) then
		Source = Result
		self.Status[CacheKey] = "network"

		if HasFileSystem() then
			EnsureCacheFolder()
			pcall(function()
				Env.writefile(CachePath(CacheKey), Source)
			end)
		end
	else
		if HasFileSystem() then
			local okHas, Has = pcall(function()
				return Env.isfile(CachePath(CacheKey))
			end)
			if okHas and Has then
				local okRead, Data = pcall(function()
					return Env.readfile(CachePath(CacheKey))
				end)
				if okRead and IsValidSource(Data) then
					Source = Data
					self.Status[CacheKey] = "cache"
					Notify("Network failed for " .. CacheKey .. " - using cached copy.")
				end
			end
		end

		if not Source then
			self.Status[CacheKey] = "failed"
			warn("[ZyroHub] Failed to fetch dependency: " .. tostring(Url))
		end
	end

	return Source
end

function Net:GetStatus()
	return self.Status
end

--- Fetch + compile + execute, with every failure isolated and described.
-- Returns the module's return value, or nil + an error string.
function Net:LoadModule(CacheKey, Url, ChunkName)
	local Source = self:Fetch(CacheKey, Url)
	if not Source then
		return nil, ("[ZyroHub] Could not load dependency: %s"):format(tostring(CacheKey))
	end

	local Fn, Err = self.Compile(Source, ChunkName or CacheKey)
	if not Fn then
		return nil, ("[ZyroHub] Compile failed for %s: %s"):format(tostring(CacheKey), tostring(Err))
	end

	local ok, Result = pcall(Fn)
	if not ok then
		return nil, ("[ZyroHub] Runtime error in %s: %s"):format(tostring(CacheKey), tostring(Result))
	end

	return Result
end

return Net