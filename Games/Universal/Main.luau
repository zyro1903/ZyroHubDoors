--[[
    Unsupported-game fallback. Never kicks the user: if the clipboard copy
    fails, the repository link is still displayed inside the notification.
]]

local function CloneReference(Object)
    local State = rawget(getgenv(), "ZyroHub")
    if State and State.Environment and State.Environment.cloneref then
        return State.Environment.cloneref(Object)
    end
    return game:GetService(Object)
end

local Services = setmetatable({}, {
    __index = function(self, Name)
        return CloneReference(Name)
    end
})

local RepositoryUrl = "https://github.com/zyro1903/ZyroHubDoors"

local Bindable = Instance.new("BindableFunction")
Bindable.OnInvoke = function()
    pcall(function()
        toclipboard(RepositoryUrl)
    end)
    -- Intentionally no kick on failure: the URL is already visible below.
end

local ok = pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = "ZyroHub",
        Text = "Only DOORS is supported right now. Link: " .. RepositoryUrl,
        Duration = 10,
        Button1 = "Copy Link",
        Callback = Bindable,
    })
end)

if not ok then
    print("[ZyroHub] Only DOORS is supported right now. " .. RepositoryUrl)
end
