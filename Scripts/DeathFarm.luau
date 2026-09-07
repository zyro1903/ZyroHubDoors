--[[
	ZyroHub :: DeathFarm v3 (Tank) - built for unattended overnight runs.

	Tank mode: every step has a fallback technique.
	  - Instance names are matched through candidate lists, so game updates
		that rename entities (KeyObtain -> KeyPickup, Lock -> DoorLock, ...)
		cannot break the cycle.
	  - Joining falls back across destinations (Hotel -> Mines -> Backdoor).
	  - Dying escalates through three techniques (replicatesignal ->
		Underwater remote -> lobby escape) before the supervisor resets.
	  - Walking is optional: prompts are fired from any distance, so a stuck
		path can never stall the farm.

	v1 problems fixed:
	  - Any hiccup ("Key prompt never became usable") was a hard return that
		killed the farm silently. v2 is a never-exiting supervisor: every
		failure is caught, counted and recovered from instead.
	  - Every remote, prompt and movement step is pcall-wrapped and
		deadline-bounded; a missing door or a hung prompt cannot stall it.
	  - Anti-idle (VirtualUser on Player.Idled plus a periodic refresh) stops
		Roblox from kicking a sleeping farmer.
	  - Escalating recovery: retry the cycle, rejoin the lobby, chain a fresh
		teleport. Consecutive errors trigger an automatic hard reset.
	  - Optional game mute (CONFIG.MuteGame) for overnight comfort.

	Kill switch: create the file "ZyroHub/DeathFarm.stop" with any executor
	file API; the farm stops cleanly and consumes the file.

	Credits: Zyro - https://github.com/zyro1903/ZyroHubDoors
]]

while not game:IsLoaded() do
	task.wait(1)
end

local CONFIG = {
	Destination = "Hotel", -- fastest deterministic death cycle
	MaxPlayers = "1", -- solo elevator: nobody can interfere overnight
	WalkTimeout = 60, -- seconds per walking leg
	KeyWaitTimeout = 45, -- seconds to wait for the key entity
	UnlockWaitTimeout = 30, -- seconds to wait for the unlock prompt
	RoomWaitTimeout = 120, -- seconds to wait for the next room to stream
	DeathWaitTimeout = 150, -- seconds to wait for the death to register
	JoinCooldown = 12, -- minimum seconds between elevator join attempts
	RejoinDelay = 3, -- pause between recovery attempts
	PromptRetryTimeout = 25, -- seconds spent hammering one prompt
	MaxConsecutiveErrors = 5, -- errors before an automatic hard reset
	HeadingTimeout = 60, -- seconds waiting inside the lobby for a run to start
	                         -- after CreateElevator; if the game never leaves
	                         -- "Heading to <destination>", exit and rejoin
	MuteGame = false, -- true = silence every sound (overnight comfort)
	SendCaptions = true, -- in-game caption log lines
	-- Tank mode: every step has a fallback technique. If a spawn name
	-- changes in a game update, or a join target refuses us, the farm
	-- quietly switches to the next option instead of dying out.
	Destinations = { "Hotel", "Mines", "Backdoor" }, -- join fallback order
}

local StartedAt = os.clock()
local CycleCount = 0
local DeathCount = 0
local ErrorCount = 0
local ConsecutiveErrors = 0
local LastJoinAttempt = 0
local LastCaption = 0
local MutedSounds = {}
-- Tracks the current join phase so the "Heading to <destination>" stall can
-- be detected: { Mode = "heading"|"transit"|nil, Target = string|nil, Since = os.clock() }
local JoinState = nil

local LOBBY_PLACE = 6516141723
local GAME_PLACE = 6839171747

local function CloneReference(Object)
	local State = rawget(getgenv(), "ZyroHub")
	if State and State.Environment and State.Environment.cloneref then
		local ok, Cloned = pcall(State.Environment.cloneref, Object)
		if ok and Cloned then
			return Cloned
		end
	end
	if typeof(cloneref) == "function" then
		local ok, Cloned = pcall(cloneref, Object)
		if ok and Cloned then
			return Cloned
		end
	end
	return Object
end

local Services = setmetatable({}, {
	__index = function(self, Name)
		local ok, Service = pcall(game.GetService, game, Name)
		if ok and Service then
			rawset(self, Name, CloneReference(Service))
			return self[Name]
		end
		return nil
	end,
})

local Players = Services.Players
local Workspace = Services.Workspace

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	task.wait(0.5)
	LocalPlayer = Players.LocalPlayer
end

local QueueTeleport = (queue_on_teleport or queueonteleport)
if not QueueTeleport then
	warn("[ZyroHub] [DeathFarm] queue_on_teleport is unavailable: recovery still works in place, but a game teleport needs a manual re-execute.")
end

local ProjectBaseUrl = (rawget(getgenv(), "ZyroHub") and ZyroHub.BaseUrl) or "https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/"
local TeleportCode = "loadstring(game:HttpGet(" .. string.format("%q", ProjectBaseUrl .. "Scripts/DeathFarm.luau") .. "))()"

local function Uptime()
	local Total = math.floor(os.clock() - StartedAt)
	return string.format("%dh %02dm %02ds", math.floor(Total / 3600), math.floor((Total % 3600) / 60), Total % 60)
end

local function Log(Message)
	print(("[ZyroHub] [DeathFarm] %s | cycle %d | deaths %d | errors %d | uptime %s"):format(tostring(Message), CycleCount, DeathCount, ErrorCount, Uptime()))
end

local function Caption(Message)
	if not CONFIG.SendCaptions then
		return
	end
	if os.clock() - LastCaption < 1.5 then
		return
	end
	LastCaption = os.clock()
	task.spawn(function()
		local okBody, Remotes = pcall(function()
			return Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
		end)
		if not okBody or not Remotes then
			return
		end
		local Text = "[ZyroHub] " .. tostring(Message)
		pcall(function()
			if typeof(firesignal) == "function" then
				firesignal(Remotes.Caption.OnClientEvent, Text)
			else
				Remotes.CaptionClient:Fire(Text)
			end
		end)
	end)
end

local function StopPending()
	if typeof(isfile) ~= "function" then
		return false
	end
	local ok, Has = pcall(isfile, "ZyroHub/DeathFarm.stop")
	return ok and Has
end

local function StopRequested()
	if not StopPending() then
		return false
	end
	if typeof(delfile) == "function" then
		pcall(delfile, "ZyroHub/DeathFarm.stop")
	end
	return true
end

-- Anti-idle: Roblox disconnects after 20 idle minutes; VirtualUser input
-- refreshes the session timer so an overnight farmer is never kicked.
do
	local function RefreshIdle()
		pcall(function()
			local VirtualUser = Services.VirtualUser
			if VirtualUser then
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end
		end)
	end
	pcall(function()
		LocalPlayer.Idled:Connect(RefreshIdle)
	end)
	task.spawn(function()
		while true do
			task.wait(240)
			RefreshIdle()
		end
	end)
end

if CONFIG.MuteGame then
	task.spawn(function()
		local function Silence(Object)
			if Object:IsA("Sound") and Object.Volume > 0 and MutedSounds[Object] == nil then
				MutedSounds[Object] = Object.Volume
				Object.Volume = 0
			end
		end
		for _, Container in { Workspace, Services.SoundService } do
			pcall(function()
				for _, Object in Container:GetDescendants() do
					Silence(Object)
				end
				Container.DescendantAdded:Connect(Silence)
			end)
		end
	end)
end

local function WaitForChildBounded(Parent, Name, TimeoutSeconds)
	if typeof(Parent) ~= "Instance" then
		return nil
	end
	local ok, Result = pcall(function()
		return Parent:WaitForChild(Name, TimeoutSeconds or 30)
	end)
	if ok then
		return Result
	end
	return nil
end

local function WaitForDescendantBounded(Parent, Name, TimeoutSeconds)
	if typeof(Parent) ~= "Instance" then
		return nil
	end
	local Deadline = os.clock() + (TimeoutSeconds or 30)
	while os.clock() < Deadline do
		local ok, Object = pcall(function()
			return Parent:FindFirstChild(Name, true)
		end)
		if ok and Object then
			return Object
		end
		task.wait(0.2)
	end
	return nil
end

-- Tank-mode: tries several candidate instance names (game updates rename
-- things) and returns the first one that exists before the deadline.
local function FindFirstNamed(Parent, Names, TimeoutSeconds)
	if typeof(Parent) ~= "Instance" or not Names then
		return nil
	end
	local Deadline = os.clock() + (TimeoutSeconds or 20)
	while os.clock() < Deadline do
		for _, Name in ipairs(Names) do
			local ok, Object = pcall(function()
				return Parent:FindFirstChild(Name, true)
			end)
			if ok and Object then
				return Object
			end
		end
		task.wait(0.2)
	end
	return nil
end

local function GetCharacterParts()
	local Character = LocalPlayer.Character
	if not Character then
		return nil, nil
	end
	return Character:FindFirstChild("HumanoidRootPart"), Character:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
	local ok, Alive = pcall(function()
		return LocalPlayer:GetAttribute("Alive")
	end)
	return ok and Alive ~= false
end

local function WalkTo(TargetPosition, TimeoutSeconds)
	local Deadline = os.clock() + (TimeoutSeconds or CONFIG.WalkTimeout)
	local LastDistance = math.huge
	local LastProgress = os.clock()
	while os.clock() < Deadline do
		local Root, Humanoid = GetCharacterParts()
		if not Root or not Humanoid or Humanoid.Health <= 0 then
			return false
		end
		local Offset = Vector3.new(TargetPosition.X - Root.Position.X, 0, TargetPosition.Z - Root.Position.Z)
		if Offset.Magnitude < 6 then
			return true
		end
		if Offset.Magnitude < LastDistance - 0.5 then
			LastDistance = Offset.Magnitude
			LastProgress = os.clock()
		elseif os.clock() - LastProgress > 12 then
			-- stuck against geometry: reset the progress tracker and retry
			LastDistance = math.huge
			LastProgress = os.clock()
		end
		pcall(function()
			Humanoid:MoveTo(TargetPosition)
		end)
		task.wait(0.15)
	end
	return false
end

local function SafeFirePrompt(Prompt)
	if typeof(Prompt) ~= "Instance" or not Prompt:IsA("ProximityPrompt") then
		return false
	end
	local Old = {}
	pcall(function()
		Old.MaxActivationDistance = Prompt.MaxActivationDistance
		Old.Enabled = Prompt.Enabled
		Old.HoldDuration = Prompt.HoldDuration
		Old.RequiresLineOfSight = Prompt.RequiresLineOfSight
	end)
	local Triggered = false
	local TriggeredConn
	pcall(function()
		TriggeredConn = Prompt.Triggered:Connect(function()
			Triggered = true
		end)
	end)
	pcall(function()
		Prompt.MaxActivationDistance = 99999
		Prompt.Enabled = true
		Prompt.HoldDuration = 0
		Prompt.RequiresLineOfSight = false
	end)
	if typeof(fireproximityprompt) == "function" then
		for _ = 1, 8 do
			if Triggered then
				break
			end
			pcall(fireproximityprompt, Prompt)
			task.wait(0.1)
		end
	end
	local Attempts = 0
	while not Triggered and Attempts < 40 do
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
	pcall(function()
		Prompt.MaxActivationDistance = Old.MaxActivationDistance or 99999
		Prompt.HoldDuration = Old.HoldDuration or 0
		Prompt.RequiresLineOfSight = Old.RequiresLineOfSight or false
		if Old.Enabled ~= nil then
			Prompt.Enabled = Old.Enabled
		end
	end)
	if TriggeredConn then
		pcall(function()
			TriggeredConn:Disconnect()
		end)
	end
	return Triggered
end

local function WaitForItemBounded(Name, TimeoutSeconds)
	local Deadline = os.clock() + (TimeoutSeconds or 30)
	while os.clock() < Deadline do
		local Found = false
		pcall(function()
			local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
			local Character = LocalPlayer.Character
			Found = (Backpack ~= nil and Backpack:FindFirstChild(Name) ~= nil)
				or (Character ~= nil and Character:FindFirstChild(Name) ~= nil)
		end)
		if Found then
			return true
		end
		task.wait(0.15)
	end
	return false
end

local function RetryPrompt(Prompt, ItemName, TimeoutSeconds)
	local Deadline = os.clock() + (TimeoutSeconds or CONFIG.PromptRetryTimeout)
	while os.clock() < Deadline do
		if typeof(Prompt) == "Instance" and Prompt.Parent and Prompt.Enabled ~= false then
			if SafeFirePrompt(Prompt) then
				if not ItemName then
					return true
				end
				if WaitForItemBounded(ItemName, 4) then
					return true
				end
			end
		end
		task.wait(0.35)
	end
	return false
end

local Unpack = (typeof(unpack) == "function" and unpack) or table.unpack

local function GetRemotes()
	local ok, Remotes = pcall(function()
		return Services.ReplicatedStorage:FindFirstChild("RemotesFolder")
	end)
	if ok then
		return Remotes
	end
	return nil
end

local function FireRemote(Remotes, Name, ...)
	if typeof(Remotes) ~= "Instance" then
		return false
	end
	local Remote = Remotes:FindFirstChild(Name)
	if typeof(Remote) ~= "Instance" then
		return false
	end
	local Args = { ... }
	return pcall(function()
		Remote:FireServer(Unpack(Args))
	end)
end

local function GetFloorName()
	local ok, Value = pcall(function()
		local GameData = Services.ReplicatedStorage:FindFirstChild("GameData")
		local Floor = GameData and GameData:FindFirstChild("Floor")
		return Floor and Floor.Value or nil
	end)
	if ok then
		return Value
	end
	return nil
end

local function QueueSelf()
	if QueueTeleport then
		pcall(QueueTeleport, TeleportCode)
	end
end

local function JoinRun()
	if os.clock() - LastJoinAttempt < CONFIG.JoinCooldown then
		return
	end
	LastJoinAttempt = os.clock()
	local Destinations = (CONFIG.Destinations and #CONFIG.Destinations > 0) and CONFIG.Destinations or { CONFIG.Destination }
	for Index, Destination in ipairs(Destinations) do
		-- mark this attempt as heading-to-<Destination>; if we never leave
		-- the lobby (stuck on "Heading to Hotel") the timeout below forces
		-- a clean lobby -> rejoin cycle instead of waiting forever.
		JoinState = { Mode = "heading", Target = Destination, Since = os.clock() }
		QueueSelf()
		Caption("Joining a solo " .. tostring(Destination) .. " run (option " .. Index .. "/" .. #Destinations .. ")...")
		FireRemote(GetRemotes(), "CreateElevator", {
			Mods = {},
			Settings = {},
			Destination = Destination,
			FriendsOnly = false,
			MaxPlayers = CONFIG.MaxPlayers,
		})
		local Deadline = os.clock() + CONFIG.HeadingTimeout
		while os.clock() < Deadline do
			if game.PlaceId ~= LOBBY_PLACE then
				-- left the lobby; the game queues its own loading flow
				JoinState = { Mode = "transit", Target = Destination, Since = os.clock() }
				CONFIG.Destination = Destination -- remember what worked
				return
			end
			task.wait(0.5)
		end
		Caption("Stuck on 'Heading to " .. tostring(Destination) .. "' - exiting and rejoining...")
	end
	JoinState = nil
	QueueSelf()
	Caption("All join options failed, re-entering the lobby...")
	pcall(function()
		Services.TeleportService:Teleport(LOBBY_PLACE)
	end)
	task.wait(20)
end

local function LeaveToLobby()
	QueueSelf()
	Caption("Returning to the lobby for a clean run...")
	FireRemote(GetRemotes(), "Lobby")
	local Deadline = os.clock() + 30
	while os.clock() < Deadline do
		if game.PlaceId == LOBBY_PLACE then
			return
		end
		task.wait(0.5)
	end
end

local function PlayAgain()
	QueueSelf()
	Caption("Starting a fresh run...")
	FireRemote(GetRemotes(), "PlayAgain")
	local Deadline = os.clock() + 90
	while os.clock() < Deadline do
		if game.PlaceId ~= GAME_PLACE then
			return -- teleported away: the queued code takes over there
		end
		local Root = GetCharacterParts()
		if GetFloorName() == CONFIG.Destination and Root and IsAlive() then
			task.wait(CONFIG.RejoinDelay)
			return -- a fresh run is already live; the loop continues in place
		end
		task.wait(0.5)
	end
	LeaveToLobby()
end

-- Tank-mode death: the PRIMARY technique (replicatesignal) is always tried
-- first and is the one that works in the vast majority of cases; the other
-- techniques only kick in if it doesn't register a death.
local KillMethods = {
	{ Name = "replicatesignal", Func = function()
		if typeof(replicatesignal) ~= "function" then
			return false
		end
		pcall(function()
			replicatesignal(LocalPlayer.Kill)
		end)
		return true
	end },
	{ Name = "underwater-remote", Func = function()
		local Remotes = GetRemotes()
		local Underwater = Remotes and Remotes:FindFirstChild("Underwater")
		if not Underwater then
			return false
		end
		pcall(function()
			Underwater:FireServer(true)
		end)
		return true
	end },
	{ Name = "lobby-escape", Func = function()
		-- Last resort: leave to the lobby; next DispatchOnce opens a fresh
		-- run (and whatever killed us is gone with the old server).
		FireRemote(GetRemotes(), "Lobby")
		return true
	end },
}

local function DieNow(TechniqueIndex)
	local Method = KillMethods[TechniqueIndex or 1]
	if Method then
		return pcall(Method.Func)
	end
	return false
end

local function WaitDeath()
	for Cycle = 1, #KillMethods do
		local Method = KillMethods[Cycle]
		Caption("Dying (technique " .. Cycle .. "/" .. #KillMethods .. ": " .. Method.Name .. ")...")
		DieNow(Cycle)
		local Deadline = os.clock() + (Cycle == #KillMethods and 60 or CONFIG.DeathWaitTimeout)
		while os.clock() < Deadline do
			if not IsAlive() then
				return true
			end
			task.wait(0.25)
		end
	end
	return false
end

local function PrepareRun()
	pcall(function()
		local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		local MainUI = PlayerGui and WaitForChildBounded(PlayerGui, "MainUI", 45)
		local ItemShop = MainUI and MainUI:FindFirstChild("ItemShop")
		if ItemShop then
			ItemShop.Visible = false
			FireRemote(GetRemotes(), "PreRunShop", {}, true)
		end
	end)
	pcall(function()
		local SkipPrompt = FindFirstNamed(Workspace, { "SkipPrompt", "SkipPromptButton" }, 8)
		if SkipPrompt and typeof(fireproximityprompt) == "function" then
			fireproximityprompt(SkipPrompt)
		end
	end)
	pcall(function()
		local LuggageCart = FindFirstNamed(Workspace, { "Luggage_Cart_Crouch", "LuggageCart" }, 8)
		if LuggageCart then
			LuggageCart:Destroy()
		end
	end)
end

local function DisablePlant(Room)
	pcall(function()
		local Assets = Room:FindFirstChild("Assets")
		if not Assets then
			return
		end
		for _, Object in Assets:GetChildren() do
			if Object.Name == "Potted_Plant" then
				local Collision = Object:FindFirstChild("Collision")
				if Collision then
					Collision.CanCollide = false
				end
			end
		end
	end)
end

local function RunDeathCycle()
	CycleCount += 1
	Log("cycle start")

	local CurrentRooms = WaitForChildBounded(Workspace, "CurrentRooms", 30)
	if not CurrentRooms then
		Caption("CurrentRooms never appeared, rejoining...")
		LeaveToLobby()
		return
	end

	local RoomZero = WaitForChildBounded(CurrentRooms, "0", 60)
	if not RoomZero then
		Caption("Room 0 never streamed in, rejoining...")
		LeaveToLobby()
		return
	end
	DisablePlant(RoomZero)

	local Door = FindFirstNamed(RoomZero, { "Door", "RoomDoor" }, 45)
	local Lock = Door and FindFirstNamed(Door, { "Lock", "DoorLock", "Padlock" }, 30)
	if Lock then
		pcall(function()
			Lock.CanCollide = false
		end)
	end
	PrepareRun()

	local KeyObtain = FindFirstNamed(RoomZero, { "KeyObtain", "KeyPickup", "Key" }, CONFIG.KeyWaitTimeout)
	local KeyPrompt
	if KeyObtain then
		local KeyHitbox = FindFirstNamed(KeyObtain, { "Hitbox" }, 20)
		KeyPrompt = FindFirstNamed(KeyObtain, { "ModulePrompt" }, 12)
		if not KeyPrompt then
			-- the key prompt may live directly on the key tool, not the
			-- spawn container; look around the whole starting room too
			KeyPrompt = FindFirstNamed(RoomZero, { "ModulePrompt" }, 8)
		end
		if KeyHitbox and not KeyPrompt then
			WalkTo(KeyHitbox.Position)
		end
	end
	if not KeyPrompt then
		KeyPrompt = FindFirstNamed(RoomZero, { "ModulePrompt" }, 10)
	end
	if KeyPrompt then
		if RetryPrompt(KeyPrompt, "Key", CONFIG.PromptRetryTimeout) then
			Caption("Key secured.")
		else
			Caption("Key prompt refused, dying anyway...")
		end
	else
		-- rejoin landed mid-run past the key: a plain death still farms
		Caption("Key entity missing, dying in place...")
	end

	local function RoomAdvanced(Rooms)
		local ok, Count = pcall(function()
			return #Rooms:GetChildren() >= 2
		end)
		return ok and Count
	end

	local UnlockOk = RoomAdvanced(CurrentRooms)
	if not UnlockOk then
		if Lock then
			WalkTo(Lock.Position)
		end
		local UnlockPrompt = FindFirstNamed(Door or RoomZero, { "UnlockPrompt", "Unlock" }, CONFIG.UnlockWaitTimeout)
		if UnlockPrompt then
			UnlockOk = RetryPrompt(UnlockPrompt, nil, CONFIG.PromptRetryTimeout)
		end
	end
	if UnlockOk then
		-- opened doors raise the knob payout: give the rooms time to stream
		local Deadline = os.clock() + CONFIG.RoomWaitTimeout
		while os.clock() < Deadline do
			if RoomAdvanced(CurrentRooms) then
				break
			end
			task.wait(0.5)
		end
	end

	DeathCount += 1
	Caption("Dying on purpose (death #" .. DeathCount .. ")...")
	if WaitDeath() then
		Caption("Death registered, restarting the run...")
		if StopPending() then
			return -- the supervisor consumes the kill switch and halts
		end
		PlayAgain()
	else
		Caption("No death technique worked, hard resetting...")
		LeaveToLobby()
	end
end

local function DispatchOnce()
	if game.PlaceId == LOBBY_PLACE then
		-- In the lobby: if the previous elevator join never let us leave
		-- (stuck on "Heading to Hotel"), force a fresh exit+rejoin quickly
		-- instead of politely waiting through another long join cooldown.
		if JoinState and JoinState.Mode == "heading" and os.clock() - JoinState.Since > CONFIG.HeadingTimeout then
			Caption("Stuck in the lobby after 'Heading to " .. tostring(JoinState.Target or "?") .. "', exiting and rejoining...")
			JoinState = nil
			LastJoinAttempt = 0
		end
		JoinRun()
		return
	end
	JoinState = nil
	if game.PlaceId ~= GAME_PLACE then
		Caption("Unknown place, teleporting back to the DOORS lobby...")
		QueueSelf()
		pcall(function()
			Services.TeleportService:Teleport(LOBBY_PLACE)
		end)
		task.wait(10)
		return
	end
	local Floor = GetFloorName()
	if Floor and Floor ~= CONFIG.Destination then
		LeaveToLobby()
		return
	end
	if not IsAlive() then
		-- an entity got us early: the death still counts, restart the run
		DeathCount += 1
		Log("early death registered")
		PlayAgain()
		return
	end
	RunDeathCycle()
end

-- duplicate-run guard: the same place within 5 seconds means a manual
-- double-execution; queued teleport re-runs always arrive in another place.
local TokenKey = "ZyroHubDeathFarm_" .. tostring(game.PlaceId)
local ExistingToken = rawget(getgenv(), TokenKey)
if ExistingToken and os.clock() - ExistingToken < 5 then
	warn("[ZyroHub] [DeathFarm] already running in this place; duplicate execution ignored.")
	return
end
getgenv()[TokenKey] = os.clock()

Log("v2 supervisor online (destination: " .. CONFIG.Destination .. ", solo: " .. CONFIG.MaxPlayers .. ")")
Caption("DeathFarm v2 online - unattended mode.")

while true do
	if StopRequested() then
		Log("kill switch consumed, stopping cleanly.")
		Caption("DeathFarm stopped by kill switch.")
		break
	end
	local ok, Err = pcall(DispatchOnce)
	if ok then
		ConsecutiveErrors = 0
	else
		ErrorCount += 1
		ConsecutiveErrors += 1
		warn("[ZyroHub] [DeathFarm] cycle error (" .. tostring(ConsecutiveErrors) .. "/" .. tostring(CONFIG.MaxConsecutiveErrors) .. "): " .. tostring(Err))
		if ConsecutiveErrors >= CONFIG.MaxConsecutiveErrors then
			ConsecutiveErrors = 0
			Caption("Hard reset: returning to the lobby...")
			LeaveToLobby()
		end
		task.wait(CONFIG.RejoinDelay)
	end
	task.wait(0.5)
end