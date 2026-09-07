-- ZyroHub encrypted module (Games/Doors/Loader.luau) - built 2026-09-07 20:27 UTC
-- Readable source lives in src/ (never published). Edit src/, then run Scripts/build.ps1.
local PAYLOAD = "0rLm6MCPt+vSqNY27DM32QveKOSzI+gLJ9cA2orsHdP9G5MIEunyGMvyxeT0BZDm/9fq/bqw9bra+7jUrZnN2ma4r+2ryqzmuHP8puP5h29enGB02ZvE2VPC0J3K36fNiZXB3qdkxoq5y5e21VGdyZmqeYuquDqnunqdt3qOR3R2gad2i22VeHhpZaSvp5txoiF+pmqElmh5nVpQPf54hwIgOQNxlEltkxJch2YYVQtYk0pyXFBbQyNXg9r0VDcxMWLoHG9oMCp8LCREHEE5cDEeaR4HOBZEVAJVXcLm+MBAU9otRxQyFgM7RBYeIhDfGNbkC9HrDMfnAcXd3KkD+Rz3qNm/2vs/uxE3HgzOLucMIeLC2b3zHdMX4boMG+kL3cf2CcoH1+AFBemcxo3C/c3q68/nt4WisXGzy7e1xaeOy//pwIbYsejr95eu9aXNmGdogpy/5JRyfUCs0qyTu6upzHa+zqq9yl1doo+uwo51m42ryotkn3GWmTl9iJqAP31YUHnAaJy8q0oxbyU7fmCJnmtDdl+VpmtOe1qDnit1nkuFTR8fMFtqgPwM"
local KEY = "ZyroHub-Enc-v1-7Kq2mX9pR4tW8yB3nF6jH1cV5sL0dG2aZ9eQ4uI7oP3rT6wY"
local SIZE = 429
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
local Fn, Err = loadstring(Source, "Games/Doors/Loader.luau")
if not Fn then
	error("[ZyroHub] encrypted module failed to compile: " .. tostring(Err))
end
return Fn()