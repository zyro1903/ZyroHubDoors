-- ZyroHub encrypted module (Games/Universal/Loader.luau) - built 2026-09-07 20:27 UTC
-- Readable source lives in src/ (never published). Edit src/, then run Scripts/build.ps1.
local PAYLOAD = "0rKr3yL6CzAlqAYv7zA5IAydL+f40en/IeDzEJkDD9UBDde0+Nz3w9DrHtX+wJjt99y2uMjiCXnjArTUAL/az7Szeby6zPy6rsexbIzx6cif6GCi1653sVOp5p3Qt6i8l4K630Kw04is0lGPwqScrJypeVRirZOqw1ymsDpriHpyZKdzI1eCb4iDS7Knn3NuoXaBmCM6fFV9k19RhWKEoFqIn1pxVDNtkGA8jmdZjQ0qOhpkh0BOh0ESPfsKCg8vPVs7CWNjNEtvMndoaBYNXytEIihOVyrzGLc="
local KEY = "ZyroHub-Enc-v1-7Kq2mX9pR4tW8yB3nF6jH1cV5sL0dG2aZ9eQ4uI7oP3rT6wY"
local SIZE = 218
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
local Fn, Err = loadstring(Source, "Games/Universal/Loader.luau")
if not Fn then
	error("[ZyroHub] encrypted module failed to compile: " .. tostring(Err))
end
return Fn()