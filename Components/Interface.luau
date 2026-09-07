-- ZyroHub encrypted module (Components/Interface.luau) - built 2026-09-07 20:27 UTC
-- Readable source lives in src/ (never published). Edit src/, then run Scripts/build.ps1.
local PAYLOAD = "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"
local KEY = "ZyroHub-Enc-v1-7Kq2mX9pR4tW8yB3nF6jH1cV5sL0dG2aZ9eQ4uI7oP3rT6wY"
local SIZE = 1966
local function Decrypt(Payload, Key, Size)
	local Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local Reverse = {}
	for Index = 1, 64 do
		Reverse[Alphabet:sub(Index, Index)] = string.char(Index - 1)
	end
	local Mapped = ((Payload:gsub(".", Reverse)):gsub("=", "\0"))
	local Bytes = {}
	local Pos = 0
	for Group = 1, #Mapped, 4 do
		local A, B, C, D = Mapped:byte(Group, Group + 3)
		local N = A * 262144 + B * 4096 + C * 64 + D
		Pos = Pos + 1
		Bytes[Pos] = math.floor(N / 65536) % 256
		Pos = Pos + 1
		Bytes[Pos] = math.floor(N / 256) % 256
		Pos = Pos + 1
		Bytes[Pos] = N % 256
	end
	local KeyLength = #Key
	local Chars = {}
	for Index = 1, Size do
		Chars[Index] = string.char((Bytes[Index] - Key:byte(((Index - 1) % KeyLength) + 1) - (Index % 256)) % 256)
	end
	return table.concat(Chars)
end
local Source = Decrypt(PAYLOAD, KEY, SIZE)
local Fn, Err = loadstring(Source, "Components/Interface.luau")
if not Fn then
	error("[ZyroHub] encrypted module failed to compile: " .. tostring(Err))
end
return Fn()