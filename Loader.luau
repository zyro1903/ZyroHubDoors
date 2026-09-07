--[[

    ZyroHub bootstrap.

    Responsibilities:
      - Single source of truth for the global `ZyroHub` table.
      - Versioned, crash-tolerant UserData persistence (schema v2).
      - Bootstrap loading of components with cache fallback (see Net.luau
        for the full pinned/cached loader used for external dependencies).

]]

if getgenv().ZyroHub and getgenv().ZyroHub.Environment and getgenv().ZyroHub.Interface then
    return
end

local VERSION = "2.0.0"

getgenv().ZyroHub = {
    Version = VERSION,
    BaseUrl = "https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/",
    Config = {
        TouchControls = "Auto",
    },
}

local GameList = {
    [2440500124] = "Doors"
}

local function CloneReference(Object)
    local State = rawget(getgenv(), "ZyroHub")
    if State and State.Environment and State.Environment.cloneref then
        return State.Environment.cloneref(Object)
    end
    return Object
end

local function GetService(Name)
    local ok, Service = pcall(game.GetService, game, Name)
    if not ok then
        return nil
    end
    return CloneReference(Service)
end

-- Bootstrap loader: mirrors Net.luau but exists before Net itself is loaded.
-- Adds cache fallback so a network failure no longer bricks the hub.
local function RawLoad(Path)
    local Url = ZyroHub.BaseUrl .. Path
    local CacheKey = Path:gsub("[^%w%-_%.]", "_")
    local CachePath = "ZyroHubCache/" .. CacheKey .. ".lua"

    local Source
    local ok, Result = pcall(function()
        return game:HttpGet(Url)
    end)

    if ok and type(Result) == "string" and #Result > 32 and Result:sub(1, 1) ~= "<" then
        Source = Result
        local Root = getgenv()
        pcall(function()
            if Root.makefolder and Root.isfolder and not Root.isfolder("ZyroHubCache") then
                Root.makefolder("ZyroHubCache")
            end
            if Root.writefile then
                Root.writefile(CachePath, Source)
            end
        end)
    else
        -- Offline fallback: last successful mirror of this component.
        local Root = getgenv()
        local Env = ZyroHub.Environment or Root
        if Env and Env.readfile and Env.isfile then
            local okHas, Has = pcall(function()
                return Env.isfile(CachePath)
            end)
            if okHas and Has then
                local okRead, Data = pcall(function()
                    return Env.readfile(CachePath)
                end)
                if okRead and type(Data) == "string" and #Data > 32 then
                    Source = Data
                end
            end
        end
    end

    assert(Source, "[ZyroHub] Failed to download (and no cached copy of): " .. Path)

    local Fn, Err = loadstring(Source, Path)
    assert(Fn, "[ZyroHub] Compile error in " .. Path .. ": " .. tostring(Err))

    return Fn()
end

ZyroHub.Localization = RawLoad("Components/Localization.luau")
ZyroHub.Environment = RawLoad("Components/Environment.luau")
ZyroHub.ESPLibrary = RawLoad("Components/ESP.luau")
ZyroHub.Net = RawLoad("Components/Net.luau")
ZyroHub.Platform = RawLoad("Components/Mobile.luau")

-- ---------------------------------------------------------------------------
-- UserData (schema v2): corrupt files reset to defaults instead of crashing,
-- values are type-coerced, and the schema is forward-migratable.
-- ---------------------------------------------------------------------------
local function LoadUserData()
    local Env = ZyroHub.Environment
    local Defaults = {
        SchemaVersion = 2,
        TotalExecutions = 0,
        Language = "English",
        TouchControls = "Auto",
    }

    if not (Env and Env.writefile and Env.readfile and Env.isfile) then
        return table.clone(Defaults)
    end

    -- Ensure the storage folder exists before first write.
    pcall(function()
        if Env.isfolder and Env.makefolder and not Env.isfolder("ZyroHub") then
            Env.makefolder("ZyroHub")
        end
    end)

    local Data = table.clone(Defaults)
    local ok = pcall(function()
        if Env.isfile("ZyroHub/UserData.json") then
            local Decoded = GetService("HttpService"):JSONDecode(Env.readfile("ZyroHub/UserData.json"))
            if type(Decoded) == "table" then
                for Key, Value in Decoded do
                    Data[Key] = Value
                end
            end
        end
    end)
    if not ok then
        -- Corrupted JSON: start clean rather than refusing to load.
        Data = table.clone(Defaults)
    end

    -- Coercion / migration.
    if type(Data.TotalExecutions) ~= "number" then
        Data.TotalExecutions = 0
    end
    if Data.Language ~= "Turkish" and Data.Language ~= "English" then
        Data.Language = "English"
    end
    if Data.TouchControls ~= "Auto" and Data.TouchControls ~= "Enabled" and Data.TouchControls ~= "Disabled" then
        Data.TouchControls = "Auto"
    end
    Data.SchemaVersion = 2
    Data.TotalExecutions += 1

    pcall(function()
        Env.writefile("ZyroHub/UserData.json", GetService("HttpService"):JSONEncode(Data))
    end)

    return Data
end

local UserData = LoadUserData()
ZyroHub.TotalExecutions = UserData.TotalExecutions
ZyroHub.Language = UserData.Language
ZyroHub.Config.TouchControls = UserData.TouchControls

ZyroHub.Interface = RawLoad("Components/Interface.luau")

local CurrentGame = GameList[game.GameId]
if CurrentGame then
    RawLoad("Games/" .. CurrentGame .. "/Loader.luau")
else
    RawLoad("Games/Universal/Loader.luau")
end
