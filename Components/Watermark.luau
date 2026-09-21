--[[
    ZyroHub :: Watermark (signature overlay)
    ----------------------------------------
    A small, draggable signature: hub version, user name and a live FPS readout.

      - Theme-aware: colors are read from the active Library scheme on every
        refresh tick, so ThemeManager swaps and the Zyro palette are picked up
        with no extra wiring.
      - Order-independent: the Settings tab is applied after the game scripts,
        so `SetEnabled` may run before `Init`; the requested state is remembered
        and applied as soon as the overlay exists.
      - Crash-tolerant: every step is pcall-guarded and failures are reported,
        never raised - a cosmetic overlay must not be able to break the hub.
]]

local Watermark = {
	Enabled = true,
	Library = nil,
	_Gui = nil,
	_Label = nil,
	_FpsConnection = nil,
	_DragConnection = nil,
	_DragEndConnection = nil,
	_DragMoveConnection = nil,
	_Dragging = false,
	_DragOffset = nil,
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

local function GetIdentity()
	local Players = GetService("Players")
	local LocalPlayer = Players and Players.LocalPlayer
	local Name = (LocalPlayer and LocalPlayer.Name) or "unknown"
	local Executor = "unknown"

	local Env = rawget(getgenv(), "ZyroHub")
	if Env and Env.Environment and type(Env.Environment.identifyexecutor) == "function" then
		local ok, Identified = pcall(Env.Environment.identifyexecutor)
		if ok and type(Identified) == "string" and #Identified > 0 then
			Executor = Identified
		end
	end

	return Name, Executor
end
local function SetText(Fps)
	local Name, Executor = GetIdentity()
	local Env = rawget(getgenv(), "ZyroHub")
	local Version = (Env and Env.Version) or "dev"

	Watermark._Label.Text = ("ZYRO CORE v%s  |  %s  |  %s  |  %d FPS"):format(
		tostring(Version), tostring(Name), tostring(Executor), Fps or 0
	)
end

-- Colors are polled (not pushed) so any palette change lands within a frame.
local function ApplyColors()
	local Library = Watermark.Library
	local Scheme = Library and Library.Scheme
	if not Scheme or not Watermark._Gui or not Watermark._Label then
		return
	end

	local Background = Scheme.BackgroundColor or Color3.fromRGB(8, 18, 24)
	local Accent = Scheme.AccentColor or Color3.fromRGB(32, 211, 194)
	local Font = Scheme.FontColor or Color3.fromRGB(234, 247, 245)

	Watermark._Gui.BackgroundColor3 = Background
	Watermark._Gui.BackgroundTransparency = 0.15
	Watermark._Gui.BorderColor3 = Accent
	Watermark._Label.TextColor3 = Font
end

local function ConnectDrag()
	local Gui = Watermark._Gui
	local UserInputService = GetService("UserInputService")

	Watermark._DragConnection = Gui.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Watermark._Dragging = true
			Watermark._DragOffset = Vector2.new(
				Input.Position.X - Gui.AbsolutePosition.X,
				Input.Position.Y - Gui.AbsolutePosition.Y
			)
		end
	end)

	if not UserInputService then
		return
	end

	-- Movement and release are tracked globally: the cursor can leave the small
	-- frame during a fast drag without the overlay getting stuck.
	Watermark._DragMoveConnection = UserInputService.InputChanged:Connect(function(Input)
		if not Watermark._Dragging or not Watermark._DragOffset then
			return
		end
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement
			and Input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		Gui.Position = UDim2.fromOffset(
			Input.Position.X - Watermark._DragOffset.X,
			Input.Position.Y - Watermark._DragOffset.Y
		)
	end)

	Watermark._DragEndConnection = UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then
			Watermark._Dragging = false
		end
	end)
end

local function Build()
	local Parent = GetParent()
	if not Parent then
		warn("[ZyroHub] Watermark: no valid UI parent found.")
		return false
	end

	local Gui = Instance.new("Frame")
	Gui.Name = "ZyroHub_Watermark"
	Gui.AnchorPoint = Vector2.new(0.5, 0)
	Gui.Position = UDim2.new(0.5, 0, 0, 8)
	Gui.AutomaticSize = Enum.AutomaticSize.X
	Gui.Size = UDim2.fromOffset(0, 24)
	Gui.BackgroundColor3 = Color3.fromRGB(8, 18, 24)
	Gui.BackgroundTransparency = 0.15
	Gui.BorderSizePixel = 1
	Gui.BorderColor3 = Color3.fromRGB(32, 211, 194)
	Gui.Active = true
	Gui.ZIndex = 2

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Gui

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 4)
	Padding.PaddingBottom = UDim.new(0, 4)
	Padding.PaddingLeft = UDim.new(0, 8)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = Gui

	local Label = Instance.new("TextLabel")
	Label.Name = "Text"
	Label.BackgroundTransparency = 1
	Label.AutomaticSize = Enum.AutomaticSize.X
	Label.Size = UDim2.fromOffset(0, 16)
	Label.Font = Enum.Font.GothamMedium
	Label.TextSize = 12
	Label.TextColor3 = Color3.fromRGB(234, 247, 245)
	Label.TextXAlignment = Enum.TextXAlignment.Center
	Label.TextYAlignment = Enum.TextYAlignment.Center
	Label.Text = "ZYRO CORE"
	Label.Parent = Gui

	Gui.Parent = Parent
	Watermark._Gui = Gui
	Watermark._Label = Label
	Watermark._DragOffset = nil

	ConnectDrag()
	return true
end

--- Starts the overlay (safe to call multiple times; extra calls are ignored).
function Watermark.Init(Library)
	Watermark.Library = Library or Watermark.Library

	if Watermark._Gui then
		Watermark.SetEnabled(Watermark.Enabled)
		return true
	end

	local Ok, Built = pcall(Build)
	if not Ok or not Built then
		warn("[ZyroHub] Watermark build failed: " .. tostring(Built))
		return false
	end

	local RunService = GetService("RunService")
	if RunService then
		local Frames = 0
		local Elapsed = 0

		Watermark._FpsConnection = RunService.RenderStepped:Connect(function(Delta)
			Frames += 1
			Elapsed += Delta

			if Elapsed < 0.5 then
				return
			end

			local Fps = math.floor(Frames / Elapsed + 0.5)
			Frames = 0
			Elapsed = 0

			if Watermark.Enabled and Watermark._Label then
				pcall(SetText, Fps)
				pcall(ApplyColors)
			end
		end)
	end

	pcall(SetText, 0)
	pcall(ApplyColors)
	Watermark.SetEnabled(Watermark.Enabled)
	return true
end

--- Toggles visibility; the state is remembered even before the overlay exists.
function Watermark.SetEnabled(Value)
	Watermark.Enabled = Value and true or false
	if Watermark._Gui then
		Watermark._Gui.Visible = Watermark.Enabled
	end
end

function Watermark.Destroy()
	for _, Key in { "_FpsConnection", "_DragConnection", "_DragEndConnection", "_DragMoveConnection" } do
		local Connection = Watermark[Key]
		if Connection then
			pcall(function() Connection:Disconnect() end)
			Watermark[Key] = nil
		end
	end

	if Watermark._Gui then
		pcall(function() Watermark._Gui:Destroy() end)
		Watermark._Gui = nil
	end

	Watermark._Label = nil
	Watermark._Dragging = false
	Watermark._DragOffset = nil
end

return Watermark
