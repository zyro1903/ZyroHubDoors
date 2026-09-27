return function(Window)
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
	
	local SettingsTab = Window:AddTab("Settings", "settings")
	local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
	
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = false,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})
	MenuGroup:AddToggle("QueueOnTeleport", {
		Text = "Queue On Teleport",
		Default = false,
		Tooltip = "Automatically reloads ZyroHub when you teleport to another server.",
		Callback = function(Value)
			if not Value then
				return
			end

			if queue_on_teleport then
				queue_on_teleport([[
					loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Games/Doors/Main.luau"))()
				]])
			end
		end,
	})

	MenuGroup:AddDropdown("UILibrary", {
		Text = "UI Style",
		Values = {
			"Obsidian",
			"Linoria"
		},
		Default = (ZyroHub.UILibrary == "Linoria" and 2 or 1),
		Callback = function(Value)
			if ZyroHub.Environment.writefile and ZyroHub.Environment.readfile then
				if not ZyroHub.Environment.isfile("ZyroHub/UserData.json") then
					local Data = {
						TotalExecutions = 0,
						UILibrary = "Obsidian"
					}
					ZyroHub.Environment.writefile("ZyroHub/UserData.json", Services.HttpService:JSONEncode(Data))
				end

				local UserData = ZyroHub.Environment.readfile("ZyroHub/UserData.json")
				local Decoded = Services.HttpService:JSONDecode(UserData)
				Decoded.UILibrary = Value

				if not Decoded.UILibrary then
					Decoded.UILibrary = "Obsidian"
				end

				ZyroHub.TotalExecutions = Decoded.TotalExecutions
				ZyroHub.UILibrary = Decoded.UILibrary

				ZyroHub.Environment.writefile("ZyroHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
			end
		end
	})
	
	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%",
	
		Text = "DPI Scale",
	
		Callback = function(Value)
			Value = Value:gsub("%%", "")
			local DPI = tonumber(Value)
	
			Library:SetDPIScale(DPI)
		end,
	})
	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
	
	MenuGroup:AddButton("Copy Discord Invite", function()
		toclipboard("https://dsc.gg/abysallhub")
		Library:Notify("Discord invite copied.")
	end)
	
	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)
	
	Library.ToggleKeybind = Options.MenuKeybind
	
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({"UILibrary"})
	ThemeManager:SetFolder("ZyroHub")
	SaveManager:SetFolder("ZyroHub/" .. ZyroHub.SavePath)
	SaveManager:BuildConfigSection(SettingsTab)
	ThemeManager:ApplyToTab(SettingsTab)
	SaveManager:LoadAutoloadConfig()
end
