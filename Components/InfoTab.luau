return function(Window)
    local L = function(Key)
        return ZyroHub.Localization.Get(Key, ZyroHub.Language)
    end

    local LatestChangelog = {
        "2026-08-31",
        "<font color='rgb(0, 255, 0)'>+ Enterprise hardening: pinned dependencies + offline cache</font>",
        "<font color='rgb(0, 255, 0)'>+ Touch control panel for mobile executors</font>",
        "<font color='rgb(0, 255, 0)'>* Auto-Revive attempt cap, safer unload, throttled RemoveFigure</font>",
        "11/7/2026",
        "<font color='rgb(0, 255, 0)'>+ Added Entity ESP Selection</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Item Notifier</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Remove Surge</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Death Farm</font>",
		"<font color='rgb(0, 255, 0)'>+ Fixed Some Broken Features (Bypass Eyes, etc)</font>",
    }

    local function CloneReference(Object)
        if ZyroHub and ZyroHub.Environment.cloneref then
            return ZyroHub.Environment.cloneref(Object)
        else
            return Object
        end
    end

    local Services = setmetatable({}, {
        __index = function(self, Name)
            return CloneReference(game:GetService(Name))
        end
    })

    local Library = ZyroHub.Interface.Library
    local SaveManager = ZyroHub.Interface.SaveManager
    local ThemeManager = ZyroHub.Interface.ThemeManager

    local Toggles = Library.Toggles
    local Options = Library.Options

    local LocalPlayer = Services.Players.LocalPlayer
    local InfoTab = Window:AddTab(L("Overview"), "layout-dashboard")

    local User = InfoTab:AddLeftGroupbox(L("Identity"))

    local ImageSize = Enum.ThumbnailSize.Size420x420
    local ImageType = Enum.ThumbnailType.HeadShot

    -- Thumbnail fetches can fail (rate limit, network); never crash setup.
    local OkThumb, Content = pcall(function()
        return Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)
    end)
    if not OkThumb or type(Content) ~= "string" then
        Content = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    end

    User:AddImage("UserIcon", {
        Image = Content
    })

    User:AddLabel("ID: " .. LocalPlayer.Name, true)
    User:AddLabel(L("TotalExecutions") .. ": " .. (ZyroHub.TotalExecutions and ZyroHub.TotalExecutions or "N/A"), true)

    local Changelog = InfoTab:AddRightGroupbox(L("Pulse"))
    for Index, Change in pairs(LatestChangelog) do
        Changelog:AddLabel(Change, true)
    end

    local Name, Version = ZyroHub.Environment.identifyexecutor()
    local Executor = InfoTab:AddRightGroupbox(L("Runtime"))
    Executor:AddLabel(L("Name") .. ": " .. Name, true)
	Executor:AddLabel(L("Version") .. ": " .. (Version and Version or "N/A"), true)
    Executor:AddDivider()
    Executor:AddLabel(L("TestResult") .. ": ", true)

    for Index, Result in pairs(ZyroHub.Environment.Results) do
		-- fix for veloshitty 💔
		Result = Result:gsub("<", "(")
		Result = Result:gsub(">", ")")
		
        Executor:AddLabel(Result, true)
    end

    local Net = ZyroHub.Net
    local Dependencies = InfoTab:AddLeftGroupbox(L("Dependencies"))
    Dependencies:AddLabel(L("Pinned") .. " (Obsidian): " .. (Net and Net.Pins.Obsidian:sub(1, 7) or "N/A"), true)
    if Net and type(Net.GetStatus) == "function" then
        for CacheKey, Status in pairs(Net:GetStatus()) do
            Dependencies:AddLabel(CacheKey .. ": " .. L(Status == "cache" and "CachedCopy" or "NetworkLoad"), true)
        end
    end
    Dependencies:AddDivider()

    local Community = InfoTab:AddLeftGroupbox(L("Links"))
    Community:AddButton(L("CopyLink"), function()
        toclipboard("https://github.com/zyro1903/ZyroHubDoors")
        Library:Notify(L("LinkCopied"))
    end)

    local CreditTab = Window:AddTab(L("Credit"), "user")
    local Creator = CreditTab:AddLeftGroupbox(L("Creator"))
    Creator:AddLabel(L("CreditZyro"), true)
    Creator:AddLabel(L("HelperRag"), true)
end
