-- ZyroHub encrypted module (Games/Universal/Main.luau) - built 2026-09-07 20:27 UTC
-- Readable source lives in src/ (never published). Edit src/, then run Scripts/build.ps1.
local PAYLOAD = "0rLm6L2lt+vS3QA68jE0KBbxIOPAGNoDGJL0DdYMENP8E6G0+Nz5CNaqENnvC+OWCtHhuMv098uxs7zWrb/Qy2avut22uvvUu7eoofH1829enGB02JvA4KZ7jZ/J1FPMzqTE3qG405fEhp22z5xXwJ1dzIurv4ZYuH2kvniKoGxxL551jLaYbzS9Z6hmqZVzpmd+llyMnmN+XPZ/jf4llmR5jWUli1t6imZ3kWAYW1dtiD1VeUFehzpgcjISNyo4NVk8AxgV6/UqLHNqXVPgUTY3aCH5M9VDUCRKVikEUhtLVB80XM/2FNPxPSwrSPQ0Pbvt37za9rYcNq7+HeoD9tfqCTPW3wos9Sr2Ahb3KPUGI+r/JeqyEdwI0skRDev93MD1HdEAGOL9CeLuyNDsC8jqCMLht8vc9r12impwcphqfLDpsssBtPSp0d2j9KmGu6zR4anC35zK4auM0KTI3aG6zY93uZe7ypivhDhhfTtmvIygYjhVcjCfkH+GhacrhLKlc1KUaLudpJx5qmh+X05+o113phkwmWaDOAOGn2BqlQpjkGiIj1lhjw8/Pk9sjExijTpqdDNaUfRNUSbsWRwZ7/kuI2d0bk8peuYXGCZSaBxJXCBVHSxFWyAHEQwrVxD69tfzB9fd/dDjUQI8ThIs+t0jQwAU//L5+i3yDTYfuOgw8i71y8yl46cAJ+WoOKOgvt4XGdsN0M0BIu7+FOABH/HpGuSe25GmCNL9CtS5yorf/sfY47CCueu7jw70w8rBf7rAsce/9rek76Sj66rJ6FVzgafR1J3Jk4K12pG00KW6iXZfqKC41YC4voduyoGwfjZzmH15eJ97hpuxgH/FcLq8ZVcRh3KLn2SCqWFGhWJzpnKSnWI+cSFzolx3o2OFmCIpKhMmQgB7f0RtiQVgjENVZDlFRib57DYd8/0y6CwveF4rcjNOXjNCcCEBSRpbaDBNZy1RbhdAWtjfENv3CyAvRd3RA8Hs/dHv/ucpTPshJfoGByD9D1DeAg3z9DYzMND4NasFHu4ONPD/8pYgIuPFCdHs1uwCz9ECI+H5EPWiGN77DcT5A4XlBMvrEIV+18C8ZIq+0/vgwX8Dta7OpuGt6bjMpqzY7qLP4qbbo2hwlWCBl5e14qfA1aLMm5C3xKi9ypWV1I9+s4WxnYenmDs7bqaBiaeviom7dLKzu5t6ty9NX4IuYSA8WhhOXCB7n3WOnSVOURRyrHCJdnNmRiMURgQvQAclQQFSgFFqFBH6/lFCUpMhGzBlHmMzcWbsfUNScDdXdiZBGytYZClcFzBScPTyPhxHX/n7Ed/zE9gdTBU/VBE6URQ4MQwj4Z+7veO1x/viuOZM/zJIMiP768zD8rnSzaK+3JrQ3qLJ+vgYLvYB5JTX1aLfH/D/xsX1FtGzznOnw4OgvXuYlpm9yvC4yf/ueaC4kPsD7taw+LWQjGqHpGPcpkXW7aeTg07O4WjC46l75ax95ams1URtiUdy05yx0phpgHeTsImMZ7p5hn2TiJDSL5elmohibXqYY36dtXSPsHCXpCSdo2yOsCmDpG1KVyQ+YDAoemB+mVt8mFp7njp0iwYEXUZC6g=="
local KEY = "ZyroHub-Enc-v1-7Kq2mX9pR4tW8yB3nF6jH1cV5sL0dG2aZ9eQ4uI7oP3rT6wY"
local SIZE = 1201
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
local Fn, Err = loadstring(Source, "Games/Universal/Main.luau")
if not Fn then
	error("[ZyroHub] encrypted module failed to compile: " .. tostring(Err))
end
return Fn()