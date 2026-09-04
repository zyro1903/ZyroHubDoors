--[[
    Doors game router. Loads through the pinned/cached Net layer so that
    game scripts also benefit from the offline mirror and failure isolation.
]]

local Net = ZyroHub.Net
local BaseUrl = ZyroHub.BaseUrl

if game.PlaceId == 6516141723 then
	Net:LoadModule("Games/Doors/Lobby.luau", BaseUrl .. "Games/Doors/Lobby.luau")
else
	Net:LoadModule("Games/Doors/Main.luau", BaseUrl .. "Games/Doors/Main.luau")
end
