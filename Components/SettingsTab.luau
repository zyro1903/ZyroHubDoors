return function(Window)
	local L = function(Key)
		return ZyroHub.Localization.Get(Key, ZyroHub.Language)
	end

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
	
	local SettingsTab = Window:AddTab(L("Settings"), "settings")
	local MenuGroup = SettingsTab:AddLeftGroupbox(L("Menu"))
	local ConfigGroup = SettingsTab:AddRightGroupbox(L("ConfigSharing"))
	local FavoritesGroup = SettingsTab:AddLeftGroupbox(L("Favorites"))
	FavoritesGroup:AddLabel(L("FavoriteHint"), true)

	local FavoriteTargets = {
		{ "FavoriteSpeedBoost", "SpeedBoostToggle" },
		{ "FavoriteFly", "FlyToggle" },
		{ "FavoriteNoclip", "NoclipToggle" },
		{ "FavoriteAutoInteract", "AutoInteractToggle" },
		{ "FavoriteAutoCloset", "AutoClosetToggle" },
		{ "FavoriteAutoUnlock", "AutoUnlockPadlockToggle" },
		{ "FavoriteAnticheat", "DisableAnticheat" },
	}

	for _, Favorite in FavoriteTargets do
		local FavoriteKey, TargetKey = Favorite[1], Favorite[2]
		local Target = Toggles[TargetKey]
		if Target then
			FavoritesGroup:AddToggle(FavoriteKey, {
				Text = L(FavoriteKey),
				Default = Target.Value,
				Callback = function(Value)
					Target:SetValue(Value)
				end,
			})
		end
	end
	local PerformanceState = {}
	local PerformanceConnection

	local function SetPerformanceMode(Enabled)
		local Lighting = Services.Lighting
		local function SetObjectEnabled(Object)
			if Object:IsA("ParticleEmitter") or Object:IsA("Trail") or Object:IsA("Beam") or Object:IsA("PostEffect") then
				PerformanceState[Object] = Object.Enabled
				Object.Enabled = false
			end
		end
		if Enabled then
			PerformanceState.GlobalShadows = Lighting.GlobalShadows
			Lighting.GlobalShadows = false
			for _, Root in { Services.Workspace, Lighting } do
				for _, Object in Root:GetDescendants() do
					SetObjectEnabled(Object)
				end
			end
			if PerformanceConnection then
				PerformanceConnection:Disconnect()
			end
			PerformanceConnection = Services.Workspace.DescendantAdded:Connect(function(Object)
				SetObjectEnabled(Object)
			end)
			for _, Object in Lighting:GetDescendants() do
				if Object:IsA("PostEffect") then
					SetObjectEnabled(Object)
				end
			end
		else
			if PerformanceConnection then
				PerformanceConnection:Disconnect()
				PerformanceConnection = nil
			end
			if PerformanceState.GlobalShadows ~= nil then
				Lighting.GlobalShadows = PerformanceState.GlobalShadows
			end
			for Object, WasEnabled in PerformanceState do
				if typeof(Object) == "Instance" and Object.Parent then
					Object.Enabled = WasEnabled
				end
			end
			PerformanceState = {}
		end
	end

	MenuGroup:AddToggle("PerformanceMode", {
		Text = L("PerformanceMode"),
		Default = false,
		Callback = function(Value)
			SetPerformanceMode(Value)
			Library:Notify(L(Value and "PerformanceEnabled" or "PerformanceDisabled"))
		end,
	})

	ConfigGroup:AddInput("ConfigShareCode", {
		Text = L("ConfigCode"),
		Default = "",
		Placeholder = L("ConfigCodePlaceholder"),
		AllowEmpty = true,
	})

	ConfigGroup:AddButton(L("CopyConfigCode"), function()
		local EncodedConfig, Success = SaveManager:SaveJSON("SharedConfig")
		if not Success then
			Library:Notify(L("ConfigInvalid"))
			return
		end
		toclipboard("ZYROCFG1:" .. EncodedConfig)
		Library:Notify(L("ConfigCopied"))
	end)

	ConfigGroup:AddButton(L("ApplyConfig"), function()
		local Input = Options.ConfigShareCode
		local Code = Input and Input.Value or ""
		local Prefix = "ZYROCFG1:"
		if Code:sub(1, #Prefix) == Prefix then
			Code = Code:sub(#Prefix + 1)
		end
		local Success = SaveManager:LoadJSON(Code)
		Library:Notify(Success and L("ConfigApplied") or L("ConfigInvalid"))
	end)

	MenuGroup:AddDropdown("Language", {
		Text = L("Language"),
		Values = { "English", "Türkçe" },
		Default = (ZyroHub.Language == "Turkish" and 2 or 1),
		Callback = function(Value)
			local SelectedLanguage = (Value == "Türkçe" and "Turkish" or "English")
			ZyroHub.Language = SelectedLanguage
			if ZyroHub.Environment.writefile and ZyroHub.Environment.readfile then
				local UserData = ZyroHub.Environment.readfile("ZyroHub/UserData.json")
				local Decoded = Services.HttpService:JSONDecode(UserData)
				Decoded.Language = SelectedLanguage
				ZyroHub.Environment.writefile("ZyroHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
			end
			Library:Notify(ZyroHub.Localization.Get("LanguageChanged", SelectedLanguage))
		end
	})
	
	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = L("OpenKeybindMenu"),
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})
	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = L("CustomCursor"),
		Default = false,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDropdown("TouchControls", {
		Text = L("TouchControls"),
		Values = { L("TouchAuto"), L("TouchEnabledOpt"), L("TouchDisabled") },
		Default = (ZyroHub.Config.TouchControls == "Enabled" and 2 or (ZyroHub.Config.TouchControls == "Disabled" and 3 or 1)),
		Callback = function(Value)
			local Mode = (Value == L("TouchEnabledOpt") and "Enabled") or (Value == L("TouchDisabled") and "Disabled") or "Auto"
			ZyroHub.Config.TouchControls = Mode
			if ZyroHub.Environment.writefile and ZyroHub.Environment.readfile then
				pcall(function()
					local Decoded = Services.HttpService:JSONDecode(ZyroHub.Environment.readfile("ZyroHub/UserData.json"))
					Decoded.TouchControls = Mode
					ZyroHub.Environment.writefile("ZyroHub/UserData.json", Services.HttpService:JSONEncode(Decoded))
				end)
			end
			if ZyroHub.Platform and ZyroHub.Platform.SetMode then
				local Enabled = ZyroHub.Platform.SetMode(Mode)
				Library:Notify(L(Enabled and "TouchPanelOn" or "TouchPanelOff"))
			end
		end,
	})

	MenuGroup:AddDropdown("DPIDropdown", {
		Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
		Default = "100%",
	
		Text = L("DPIScale"),
	
		Callback = function(Value)
			Value = Value:gsub("%%", "")
			local DPI = tonumber(Value)
	
			Library:SetDPIScale(DPI)
		end,
	})
	MenuGroup:AddDivider()
	MenuGroup:AddLabel(L("MenuBind")):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = L("MenuKeybind") })
	
	MenuGroup:AddButton(L("CopyLink"), function()
		toclipboard("https://github.com/zyro1903/ZyroHubDoors")
		Library:Notify(L("LinkCopied"))
	end)
	
	MenuGroup:AddButton(L("Unload"), function()
		Library:Unload()
	end)
	
	Library.ToggleKeybind = Options.MenuKeybind
	
	ThemeManager:SetLibrary(Library)
	SaveManager:SetLibrary(Library)
	SaveManager:IgnoreThemeSettings()
	SaveManager:SetIgnoreIndexes({"ConfigShareCode", "PerformanceMode", "TouchControls"})
	ThemeManager:SetFolder("ZyroHub")
	SaveManager:SetFolder("ZyroHub/" .. ZyroHub.SavePath)
	SaveManager:BuildConfigSection(SettingsTab)
	ThemeManager:ApplyToTab(SettingsTab)
	ThemeManager:ApplyTheme("Zyro Aurora")
	-- A saved config referencing a removed theme key must not break startup.
	pcall(function()
		SaveManager:LoadAutoloadConfig()
	end)

	local ZyroTheme = {
		FontColor = "EAF7F5",
		MainColor = "12212A",
		AccentColor = "20D3C2",
		BackgroundColor = "081218",
		OutlineColor = "2B4852"
	}

	for Name, Hex in ZyroTheme do
		local Color = Color3.fromHex(Hex)
		Library.Scheme[Name] = Color
		if Library.Options[Name] then
			Library.Options[Name]:SetValue(Color)
		end
	end

	Library:UpdateColorsUsingRegistry()
	Library:SetFont(Enum.Font.Gotham)
end
