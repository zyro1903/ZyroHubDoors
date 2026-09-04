while not game:IsLoaded() do
	task.wait(1)
end

print("ZyroHub death farm for DOORS, credit: Zyro")
print("https://github.com/zyro1903/ZyroHubDoors")
print("Prompt-safe version: key + door waits enabled")

local Services = setmetatable({}, {
	__index = function(self, Key)
		return game:GetService(Key)
	end
})

local QueueTeleport = queue_on_teleport or queueonteleport
local ProjectBaseUrl = (getgenv().ZyroHub and ZyroHub.BaseUrl) or "https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/"
local TeleportCode = "loadstring(game:HttpGet(" .. string.format("%q", ProjectBaseUrl .. "Scripts/DeathFarm.luau") .. "))()"

local LocalPlayer = Services.Players.LocalPlayer
local RemotesFolder = Services.ReplicatedStorage:WaitForChild("RemotesFolder", 30)
local CurrentRooms = Services.Workspace:WaitForChild("CurrentRooms", 30)
local GameData = Services.ReplicatedStorage:WaitForChild("GameData", 30)

local function WaitForRoomState(TimeoutSeconds)
	local Deadline = os.clock() + (TimeoutSeconds or 120)
	while not CurrentRooms or not GameData or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
		if os.clock() > Deadline then
			return false
		end
		task.wait(0.15)
	end
	while #CurrentRooms:GetChildren() < 1 do
		if os.clock() > Deadline then
			return false
		end
		task.wait(0.15)
	end
	return true
end

local function SendCaption(Text)
	if firesignal then
		firesignal(RemotesFolder.Caption.OnClientEvent, "[ZyroHub] " .. Text)
	else
		RemotesFolder.CaptionClient:Fire("[ZyroHub] " .. Text)
	end
end

-- Kill switch: create "ZyroHub/DeathFarm.stop" (any file API) to stop the
-- farm after the current cycle. The flag file is consumed when read.
local function StopRequested()
	if not (isfile and isfile("ZyroHub/DeathFarm.stop")) then
		return false
	end
	pcall(function() delfile("ZyroHub/DeathFarm.stop") end)
	return true
end

if StopRequested() then
	print("[ZyroHub] Death farm stopped by kill switch.")
	return
end

if game.PlaceId == 6516141723 then
	SendCaption("Joining a run...")
	QueueTeleport(TeleportCode)
	RemotesFolder.CreateElevator:FireServer({
		Mods = {},
		Settings = {},
		Destination = "Hotel",
		FriendsOnly = false,
		MaxPlayers = "1"
	})
	return
end

if GameData and GameData.Floor.Value ~= "Hotel" then
	QueueTeleport([==[
		local RemotesFolder = game:GetService("ReplicatedStorage").RemotesFolder
		local function SendCaption(Text)
			if firesignal then
				firesignal(RemotesFolder.Caption.OnClientEvent, "[ZyroHub] " .. Text)
			else
				RemotesFolder.CaptionClient:Fire("[ZyroHub] " .. Text)
			end
		end

		local QueueTeleport = queue_on_teleport or queueonteleport
		QueueTeleport([=[loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Scripts/DeathFarm.luau"))()]=])

		SendCaption("Joining a run...")
		RemotesFolder.CreateElevator:FireServer({
			Mods = {},
			Settings = {},
			Destination = "Hotel",
			FriendsOnly = false,
			MaxPlayers = "1"
		})
	]==])
	RemotesFolder.Lobby:FireServer()
	return
end

if game.PlaceId ~= 6839171747 then
	QueueTeleport([==[
		local RemotesFolder = game:GetService("ReplicatedStorage").RemotesFolder
		local function SendCaption(Text)
			if firesignal then
				firesignal(RemotesFolder.Caption.OnClientEvent, "[ZyroHub] " .. Text)
			else
				RemotesFolder.CaptionClient:Fire("[ZyroHub] " .. Text)
			end
		end

		local QueueTeleport = queue_on_teleport or queueonteleport
		QueueTeleport([=[loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Scripts/DeathFarm.luau"))()]=])

		SendCaption("Joining a run...")
		RemotesFolder.CreateElevator:FireServer({
			Mods = {},
			Settings = {},
			Destination = "Hotel",
			FriendsOnly = false,
			MaxPlayers = "1"
		})
	]==])
	Services.TeleportService:Teleport(6516141723)
	return
end

if #CurrentRooms:GetChildren() > 1 then
	SendCaption("Run has already started, joining a new run for best experience...")
	QueueTeleport(TeleportCode)
	RemotesFolder.PlayAgain:FireServer()
	return
end

local LoadDeadline = os.clock() + 120
while #CurrentRooms:GetChildren() < 1 or not LocalPlayer.Character do
	if os.clock() > LoadDeadline then
		SendCaption("Load timeout, restarting the cycle...")
		QueueTeleport(TeleportCode)
		return
	end
	task.wait(1)
end

if not WaitForRoomState(120) then
	SendCaption("Load timeout, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end

local MainUI = LocalPlayer.PlayerGui:WaitForChild("MainUI", 60)
if not MainUI then
	SendCaption("MainUI never loaded, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end

if MainUI:FindFirstChild("ItemShop") then
	MainUI.ItemShop.Visible = false
	RemotesFolder.PreRunShop:FireServer({}, true)
end

task.wait(1)

local SkipPrompt = Services.Workspace:FindFirstChild("SkipPrompt", true)
if SkipPrompt then
	pcall(function()
		fireproximityprompt(SkipPrompt)
	end)
end

local LuggageCart = Services.Workspace:FindFirstChild("Luggage_Cart_Crouch", true)
if LuggageCart then
	pcall(function()
		LuggageCart:Destroy()
	end)
end

local function WalkPosition(TargetPosition)
	local HumanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart", 10)
	local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid", 10)
	if not HumanoidRootPart or not Humanoid then
		return false
	end

	local Finished = false
	local Connection = Services.RunService.RenderStepped:Connect(function()
		Humanoid:MoveTo(TargetPosition)
		if LocalPlayer:DistanceFromCharacter(TargetPosition) < 6 then
			Finished = true
		end
	end)

	-- Bounded: pathing that never converges used to hang the farm forever.
	local Deadline = os.clock() + 60
	while task.wait(0.1) do
		if Finished or os.clock() > Deadline then
			break
		end
	end

	Connection:Disconnect()
	task.wait()
	return Finished
end

local function WaitForDescendant(Parent, Name, TimeoutSeconds)
	local Deadline = os.clock() + (TimeoutSeconds or 60)
	local Object = Parent:FindFirstChild(Name, true)
	while not Object do
		if os.clock() > Deadline or not Parent.Parent then
			return nil
		end
		task.wait(0.1)
		Object = Parent:FindFirstChild(Name, true)
	end
	return Object
end

local function WaitForItem(Name, TimeoutSeconds)
	local StartTick = os.clock()
	local Timeout = TimeoutSeconds or 30
	while not LocalPlayer.Backpack:FindFirstChild(Name) and not LocalPlayer.Character:FindFirstChild(Name) do
		if os.clock() - StartTick >= Timeout then
			return false
		end
		task.wait(0.1)
	end
	return true
end

local function SafeFirePrompt(Prompt)
	if not Prompt or not Prompt:IsA("ProximityPrompt") then
		return false
	end

	local OldDist = Prompt.MaxActivationDistance
	local OldEnable = Prompt.Enabled
	local OldHold = Prompt.HoldDuration
	local OldLOS = Prompt.RequiresLineOfSight
	local OldParent = Prompt.Parent
	local Triggered = false

	Prompt.MaxActivationDistance = 99999
	Prompt.Enabled = true
	Prompt.HoldDuration = 0
	Prompt.RequiresLineOfSight = false

	local TriggeredConn = Prompt.Triggered:Connect(function()
		Triggered = true
	end)

	local Attempts = 0
	while not Triggered and Attempts < 60 do
		Attempts += 1
		pcall(function()
			Prompt:InputHoldBegin()
		end)
		task.wait(0.05)
		pcall(function()
			Prompt:InputHoldEnd()
		end)
		task.wait(0.05)
	end

	Prompt.MaxActivationDistance = OldDist
	Prompt.Enabled = OldEnable
	Prompt.HoldDuration = OldHold
	Prompt.RequiresLineOfSight = OldLOS
	if OldParent then
		pcall(function()
			Prompt.Parent = OldParent
		end)
	end

	TriggeredConn:Disconnect()
	return Triggered
end

local function RetryPrompt(Prompt, ItemName, TimeoutSeconds)
	local StartTick = os.clock()
	local Timeout = TimeoutSeconds or 20
	while os.clock() - StartTick < Timeout do
		if Prompt and Prompt.Parent and Prompt.Enabled ~= false then
			if SafeFirePrompt(Prompt) then
				if not ItemName then
					return true
				end
				if WaitForItem(ItemName, 4) then
					return true
				end
			end
		end
		task.wait(0.35)
	end
	return false
end

task.wait(1)

local StartingRoom = CurrentRooms:WaitForChild("0", 90)
if not StartingRoom then
	SendCaption("Room 0 never spawned, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end

local Assets = StartingRoom:WaitForChild("Assets", 60)
if Assets then
	for _, Object in pairs(Assets:GetChildren()) do
		if Object.Name == "Potted_Plant" then
			Object.Collision.CanCollide = false
		end
	end
end

SendCaption("Getting the key...")
local Door = StartingRoom:WaitForChild("Door", 60)
local Lock = Door and Door:WaitForChild("Lock", 60)
if not Lock then
	SendCaption("Door/Lock never spawned, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end
Lock.CanCollide = false
WalkPosition(Lock.Position)

local Key = WaitForDescendant(StartingRoom, "KeyObtain", 60)
if not Key then
	SendCaption("Key never spawned, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end
local KeyHitbox = Key:WaitForChild("Hitbox", 30)
if not KeyHitbox then
	SendCaption("Key hitbox never appeared, restarting the cycle...")
	QueueTeleport(TeleportCode)
	return
end
local KeyPrompt = WaitForDescendant(Key, "ModulePrompt", 30)
WalkPosition(KeyHitbox.Position)

local KeyPromptReady = false
for _ = 1, 300 do
	if KeyPrompt and KeyPrompt.Parent and KeyPrompt.Enabled ~= false then
		KeyPromptReady = true
		break
	end
	task.wait(0.1)
end

if not KeyPromptReady then
	SendCaption("Key prompt never became usable.")
	return
end

if not RetryPrompt(KeyPrompt, "Key", 30) then
	SendCaption("Failed to pick up the key after retrying.")
	return
end

SendCaption("Got the key, opening the door...")
local UnlockPrompt = WaitForDescendant(Door, "UnlockPrompt")
Lock.CanCollide = false
WalkPosition(Lock.Position)

local UnlockReady = false
for _ = 1, 300 do
	if UnlockPrompt and UnlockPrompt.Parent and UnlockPrompt.Enabled ~= false then
		UnlockReady = true
		break
	end
	task.wait(0.1)
end

if not UnlockReady then
	SendCaption("Door prompt never became usable.")
	return
end

if not RetryPrompt(UnlockPrompt, nil, 25) then
	SendCaption("Failed to trigger the door prompt after retrying.")
	return
end

-- Bounded (was: infinite wait for room 2). If the door never opened we
-- still finish the death cycle so PlayAgain can restart cleanly.
local RoomDeadline = os.clock() + 120
while not CurrentRooms:FindFirstChild("2") do
	if os.clock() > RoomDeadline then
		SendCaption("Room 2 never spawned, finishing the cycle anyway...")
		break
	end
	task.wait(0.25)
end

if replicatesignal then
	replicatesignal(LocalPlayer.Kill)
else
	SendCaption("Please wait around 20 seconds to die")
	RemotesFolder.Underwater:FireServer(true)
end

-- Bounded death wait (was: infinite event Wait()).
local DeathDeadline = os.clock() + 120
while LocalPlayer:GetAttribute("Alive") ~= false do
	if os.clock() > DeathDeadline then
		break
	end
	task.wait(0.25)
end
SendCaption("Player has died, joining a new run...")

if StopRequested() then
	print("[ZyroHub] Death farm stopped by kill switch.")
	return
end

RemotesFolder.PlayAgain:FireServer()
QueueTeleport(TeleportCode)
