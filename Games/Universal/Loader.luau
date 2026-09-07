-- Routes through the pinned/cached Net layer (was: raw loadstring+HttpGet).
local Net = ZyroHub.Net
local BaseUrl = ZyroHub.BaseUrl

Net:LoadModule("Games/Universal/Main.luau", BaseUrl .. "Games/Universal/Main.luau")
