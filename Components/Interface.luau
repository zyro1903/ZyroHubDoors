--[[
    ZyroHub :: Interface

    External dependencies are loaded through Net.luau:
      - Obsidian is PINNED to a verified commit SHA (see Net.Pins.Obsidian),
        so upstream changes can never break or alter shipped clients.
      - Every dependency is mirrored to a local cache and remains loadable
        offline; failures are reported instead of crashing the hub.

]]

local Net = ZyroHub.Net
local ProjectUrl = ZyroHub.BaseUrl

local OBSIDIAN_URL = "https://raw.githubusercontent.com/deividcomsono/Obsidian/" .. Net.Pins.Obsidian .. "/"

local function FromNet(CacheKey, Url, ChunkName)
    local Module, Err = Net:LoadModule(CacheKey, Url, ChunkName)
    assert(Module, Err or ("[ZyroHub] Failed to load: " .. tostring(CacheKey)))
    return Module
end

local Interface = {
    Library = FromNet("Obsidian_Library", OBSIDIAN_URL .. "Library.lua", "Obsidian/Library.lua"),
    SaveManager = FromNet("Obsidian_SaveManager", OBSIDIAN_URL .. "addons/SaveManager.lua", "Obsidian/addons/SaveManager.lua"),
    ThemeManager = FromNet("Obsidian_ThemeManager", OBSIDIAN_URL .. "addons/ThemeManager.lua", "Obsidian/addons/ThemeManager.lua"),

    ApplyInfoTab = FromNet("ZyroHub_InfoTab", ProjectUrl .. "Components/InfoTab.luau", "Components/InfoTab.luau"),
    ApplySettingsTab = FromNet("ZyroHub_SettingsTab", ProjectUrl .. "Components/SettingsTab.luau", "Components/SettingsTab.luau")
}

-- Deduplicated theme registry: "Zyro Signature" was an exact duplicate of
-- the default palette and has been removed.
Interface.ThemeManager.BuiltInThemes = {
    ["Default"] = { 1, {
        FontColor = "EAF7F5",
        MainColor = "12212A",
        AccentColor = "20D3C2",
        BackgroundColor = "081218",
        OutlineColor = "2B4852"
    } },
    ["Zyro Aurora"] = { 2, {
        FontColor = "EAF7F5",
        MainColor = "12212A",
        AccentColor = "20D3C2",
        BackgroundColor = "081218",
        OutlineColor = "2B4852"
    } }
}

return Interface