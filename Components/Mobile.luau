--[[
    ZyroHub :: Mobile (Platform layer)
    ----------------------------------
    - Detects touch-first devices (phones/tablets running mobile executors).
    - Provides a floating, draggable touch panel that exposes keybind-critical
      toggles, because physical keyboards (R / Q / N shortcuts) do not exist
      on touch devices.
    - Modes: "Auto" (only on mobile), "Enabled", "Disabled" - user selectable
      from Settings and persisted in UserData.json.
]]

local Platform = {
	IsMobile = false,
	Mode = "Auto",
	Actions = {},
	_Gui = nil,
	_Library = nil,
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
				Duration = 4
			})
		end
	end)
end

local UserInputService = GetService("UserInputService")

local function DetectMobile()
	local Touch = UserInputService and UserInputService.TouchEnabled or false
	local Keyboard = UserInputService and UserInputService.KeyboardEnabled or false
	local Mouse = UserInputService and UserInputService.MouseEnabled or false

	local SmallViewport = false
	pcall(function()
		local Camera = workspace.CurrentCamera
		if Camera then
			local Viewport = Camera.ViewportSize
			SmallViewport = math.min(Viewport.X, Viewport.Y) <= 500
		end
	end)

	-- Touch-only device, or a touch device with a phone-sized viewport.
	return Touch and ((not Keyboard and not Mouse) or SmallViewport)
end

Platform.IsMobile = DetectMobile()

local function GetParent()
	local Env = rawget(getgenv(), "ZyroHub")
	if Env and Env.Environment and Env.Environment.gethui then
		local ok, HiddenUI = pcall(Env.Environment.gethui)
		if ok and HiddenUI then
			return HiddenUI
		end
	end

	local CoreGui = GetService("CoreGui")
	if CoreGui then
		return CoreGui
	end

	local Players = GetService("Players")
	local LocalPlayer = Players and Players.LocalPlayer
	if LocalPlayer then
		return LocalPlayer:FindFirstChildOfClass("PlayerGui")
	end

	return nil
end

local function ResolveEnabled()
	if Platform.Mode == "Enabled" then
		return true
	end
	if Platform.Mode == "Disabled" then
		return false
	end
	return Platform.IsMobile
end

local function BuildPanel(Library)
	if Platform._Gui then
		return
	end

	local Parent = GetParent()
	if not Parent then
		warn("[ZyroHub] Touch panel: no valid UI parent found.")
		return
	end

	local Gui = Instance.new("ScreenGui")
	Gui.Name = "ZyroHub_TouchPanel"
	Gui.ResetOnSpawn = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.DisplayOrder = 1000
	Gui.Parent = Parent

	-- Floating knob (draggable + tap to open/close the panel).
	local Knob = Instance.new("ImageButton")
	Knob.Name = "Knob"
	Knob.Size = UDim2.fromOffset(64, 64)
	Knob.Position = UDim2.new(0, 24, 0.6, 0)
	Knob.BackgroundColor3 = Color3.fromRGB(8, 18, 24)
	Knob.BorderSizePixel = 0
	Knob.Image = ""
	Knob.Parent = Gui

	local KnobCorner = Instance.new("UICorner")
	KnobCorner.CornerRadius = UDim.new(1, 0)
	KnobCorner.Parent = Knob

	local KnobStroke = Instance.new("UIStroke")
	KnobStroke.Color = Color3.fromRGB(32, 211, 194)
	KnobStroke.Thickness = 2
	KnobStroke.Parent = Knob

	local KnobLabel = Instance.new("TextLabel")
	KnobLabel.Name = "Label"
	KnobLabel.BackgroundTransparency = 1
	KnobLabel.Size = UDim2.fromScale(1, 1)
	KnobLabel.Font = Enum.Font.GothamBold
	KnobLabel.Text = "ZH"
	KnobLabel.TextColor3 = Color3.fromRGB(234, 247, 245)
	KnobLabel.TextSize = 20
	KnobLabel.Parent = Knob

	-- Action panel (auto-height, 44px touch-friendly rows).
	local Panel = Instance.new("Frame")
	Panel.Name = "Panel"
	Panel.Position = UDim2.new(0, 24, 0.6, 76)
	Panel.Size = UDim2.new(0, 220, 0, 0)
	Panel.AutomaticSize = Enum.AutomaticSize.Y
	Panel.BackgroundColor3 = Color3.fromRGB(8, 18, 24)
	Panel.BorderSizePixel = 0
	Panel.Visible = false
	Panel.Parent = Gui

	local PanelCorner = Instance.new("UICorner")
	PanelCorner.CornerRadius = UDim.new(0, 12)
	PanelCorner.Parent = Panel

	local PanelStroke = Instance.new("UIStroke")
	PanelStroke.Color = Color3.fromRGB(43, 72, 82)
	PanelStroke.Parent = Panel

	local List = Instance.new("UIListLayout")
	List.Padding = UDim.new(0, 6)
	List.SortOrder = Enum.SortOrder.LayoutOrder
	List.Parent = Panel

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 8)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Panel

	-- `Activated` handles both mouse and touch exactly once.
	local function MakeButton(Text, LayoutOrder, OnClick)
		local Button = Instance.new("TextButton")
		Button.Name = "Action_" .. Text
		Button.Size = UDim2.new(1, 0, 0, 44)
		Button.BackgroundColor3 = Color3.fromRGB(18, 33, 42)
		Button.BorderSizePixel = 0
		Button.Font = Enum.Font.Gotham
		Button.Text = Text
		Button.TextColor3 = Color3.fromRGB(234, 247, 245)
		Button.TextSize = 15
		Button.AutoButtonColor = true
		Button.LayoutOrder = LayoutOrder
		Button.Parent = Panel

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 8)
		Corner.Parent = Button

		Button.Activated:Connect(function()
			local ok, Err = pcall(OnClick)
			if not ok then
				warn("[ZyroHub] Touch action error: " .. tostring(Err))
			end
		end)

		return Button
	end

	local Order = 0

	Order += 1
	MakeButton("TOGGLE UI", Order, function()
		if type(Library.Toggle) == "function" then
			Library:Toggle()
		elseif Library.KeybindFrame then
			Library.KeybindFrame.Visible = not Library.KeybindFrame.Visible
		end
	end)

	for _, Action in Platform.Actions do
		Order += 1
		MakeButton(Action.Label, Order, function()
			local Toggles = Library.Toggles
			local Toggle = Toggles and Toggles[Action.Toggle]
			if Toggle then
				Toggle:SetValue(not Toggle.Value)
			end
		end)
	end

	-- Dragging (mouse + touch). Tap = toggle panel, drag = reposition.
	local Dragging = false
	local DragStart, StartPos

	Knob.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			DragStart = Input.Position
			StartPos = Knob.Position
		end
	end)

	Knob.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)

	Knob.InputChanged:Connect(function(Input)
		if not Dragging then
			return
		end
		if Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch then
			local Delta = Input.Position - DragStart
			Knob.Position = UDim2.new(
				StartPos.X.Scale, StartPos.X.Offset + Delta.X,
				StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y
			)
		end
	end)

	Knob.Activated:Connect(function()
		Panel.Visible = not Panel.Visible
	end)

	Platform._Gui = Gui
	Platform._Library = Library
end

--- Initializes the platform layer after the main window exists.
function Platform.Init(Options)
	Options = Options or {}
	Platform.Actions = Options.Actions or {}

	if Platform.Mode == "Auto" then
		local Config = rawget(getgenv(), "ZyroHub")
		Platform.Mode = (Config and Config.Config and Config.Config.TouchControls) or "Auto"
	end

	BuildPanel(Options.Library)
	Platform.SetMode(Platform.Mode)
end

--- Applies a control mode ("Auto" | "Enabled" | "Disabled") live.
-- Returns whether the panel ended up visible.
function Platform.SetMode(Mode)
	if Mode ~= "Auto" and Mode ~= "Enabled" and Mode ~= "Disabled" then
		Mode = "Auto"
	end
	Platform.Mode = Mode

	local Enabled = ResolveEnabled()
	if Platform._Gui then
		Platform._Gui.Enabled = Enabled
	end
	return Enabled
end

return Platform