return function(Window)
    local LatestChangelog = {
        "27/9/2026",

		-- Green = Added
		"<font color='rgb(0, 255, 0)'>+ Rebranded the hub to ZyroHub</font>",
		"<font color='rgb(0, 255, 0)'>+ Added the ZyroHub green theme and made green the default accent</font>",

		"<font color='rgb(255, 255, 0)'>~ Updated the credits</font>",
		"<font color='rgb(255, 255, 0)'>~ Pointed every remote URL at the ZyroHub repository</font>",

        "5/9/2026",

		-- Green = Added
		"<font color='rgb(0, 255, 0)'>+ Added StemsEntity (Balls), Noise & Creak entities</font>",
		"<font color='rgb(0, 255, 0)'>+ Added DinkyLamp, BottleCrate, GweenSodaPack, BrokenMonitor & JerryCan</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Honcho support</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Stairwell prompt ignores</font>",
		"<font color='rgb(0, 255, 0)'>+ Added Herobrine</font>",


		"<font color='rgb(255, 255, 0)'>~ Updated Sally notification message</font>",
		"<font color='rgb(255, 255, 0)'>~ Expanded ItemNames & Entities lists</font>",
		"<font color='rgb(255, 255, 0)'>~ Forgot to add supporter list so i could add it later</font>",


        -- Red = Removed
        "<font color='rgb(255, 0, 0)'>- Removed FireBacon</font>",
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
    local InfoTab = Window:AddTab("Info", "user")

    local User = InfoTab:AddLeftGroupbox("User Info")

    local ImageSize = Enum.ThumbnailSize.Size420x420
    local ImageType = Enum.ThumbnailType.HeadShot

    local Content = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)

    User:AddImage("UserIcon", {
        Image = Content
    })

    User:AddLabel("ID: " .. LocalPlayer.Name, true)
    User:AddLabel("Total Executions: " .. (ZyroHub.TotalExecutions and ZyroHub.TotalExecutions or "N/A"), true)

	local CreditsList = {
		"<font color='rgb(34, 197, 94)'>Zyro — Owner and Developer</font>",
		"<font color='rgb(34, 197, 94)'>Rag_zar123 — Developer</font>",
		"<font color='rgb(134, 239, 172)'>" .. LocalPlayer.Name .. " — For Using This Script</font>"
	}

	local Credits = InfoTab:AddRightGroupbox("Credits")
	for Index, Credit in pairs(CreditsList) do
		Credits:AddLabel(Credit, true)
	end

    local Changelog = InfoTab:AddRightGroupbox("Changelog")
    for Index, Change in pairs(LatestChangelog) do
        Changelog:AddLabel(Change, true)
    end

    local Name, Version = ZyroHub.Environment.identifyexecutor()
    local Executor = InfoTab:AddRightGroupbox("Executor Info")
    Executor:AddLabel("Name: " .. Name, true)
	Executor:AddLabel("Version: " .. (Version and Version or "N/A"), true)
    Executor:AddDivider()
    Executor:AddLabel("Test Result: ", true)

    for Index, Result in pairs(ZyroHub.Environment.Results) do
		-- fix for veloshitty 💔
		Result = Result:gsub("<", "(")
		Result = Result:gsub(">", ")")
		
        Executor:AddLabel(Result, true)
    end

	local Scripts = InfoTab:AddLeftGroupbox("Scripts")
	Scripts:AddButton("InfiniteYield",         { Text = "Infinite Yield",           Default = false, Tooltip = "Runs infinite yield.", 	Func = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end })


    local Community = InfoTab:AddLeftGroupbox("Community")
    Community:AddButton("Copy Discord Invite", function()
	    toclipboard("https://dsc.gg/abysallhubcontinued")
	    Library:Notify("Discord invite copied.")
    end)
end
