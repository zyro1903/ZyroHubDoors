param([switch]$NoVerify)
$ErrorActionPreference = "Stop"

# ZyroHub encrypted-build pipeline.
# Readable source lives in src/ (git-ignored, never published). This script
# encrypts every source file and writes a self-decrypting stub to the public
# path, so the repository never contains readable code. The stub embeds its
# key: this protects against casual reading and copying, not against a
# determined reverse-engineer.

$Root = Split-Path -Parent $PSScriptRoot
$SrcRoot = Join-Path $Root "src"
$Key = "ZyroHub-Enc-v1-7Kq2mX9pR4tW8yB3nF6jH1cV5sL0dG2aZ9eQ4uI7oP3rT6wY"
$Stamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm") + " UTC"

$Files = @(
	"Loader.luau",
	"Components/Localization.luau",
	"Components/Environment.luau",
	"Components/ESP.luau",
	"Components/Net.luau",
	"Components/Mobile.luau",
	"Components/Interface.luau",
	"Components/InfoTab.luau",
	"Components/SettingsTab.luau",
	"Games/Doors/Loader.luau",
	"Games/Doors/Lobby.luau",
	"Games/Doors/Main.luau",
	"Games/Universal/Loader.luau",
	"Games/Universal/Main.luau",
	"Scripts/DeathFarm.luau"
)

$Decoder = @'
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
'@

foreach ($Rel in $Files) {
	$SrcPath = Join-Path $SrcRoot ($Rel -replace "/", "\")
	$OutPath = Join-Path $Root ($Rel -replace "/", "\")
	if (-not (Test-Path $SrcPath)) { throw "Missing source file: src/$Rel" }
	$Plain = [IO.File]::ReadAllBytes($SrcPath)
	$KeyBytes = [Text.Encoding]::ASCII.GetBytes($Key)
	$Enc = New-Object byte[] $Plain.Length
	for ($i = 0; $i -lt $Plain.Length; $i++) {
		$Salt = ($i + 1) % 256
		$V = (($Plain[$i] - $KeyBytes[$i % $KeyBytes.Length] - $Salt) % 256)
		if ($V -lt 0) { $V += 256 }
		$Enc[$i] = $V
	}
	$B64 = [Convert]::ToBase64String($Enc)
	$Head = @"
-- ZyroHub encrypted module ($Rel) - built $Stamp
-- Readable source lives in src/ (never published). Edit src/, then run Scripts/build.ps1.
local PAYLOAD = "$B64"
local KEY = "$Key"
local SIZE = $($Plain.Length)
"@
	$Boot = @"

local Source = Decrypt(PAYLOAD, KEY, SIZE)
local Fn, Err = loadstring(Source, "$Rel")
if not Fn then
	error("[ZyroHub] encrypted module failed to compile: " .. tostring(Err))
end
return Fn()
"@
	[IO.File]::WriteAllText($OutPath, ($Head + "`n" + $Decoder + $Boot), (New-Object System.Text.UTF8Encoding($false)))
	$StubSize = (Get-Item $OutPath).Length
	Write-Output ("built   {0}  ({1} -> {2} bytes)" -f $Rel, $Plain.Length, $StubSize)
	if (-not $NoVerify) {
		$StubText = [IO.File]::ReadAllText($OutPath)
		$Marker = 'local PAYLOAD = "'
		$Start = $StubText.IndexOf($Marker)
		if ($Start -lt 0) { throw "verify failed (payload missing): $Rel" }
		$Start += $Marker.Length
		$End = $StubText.IndexOf('"', $Start)
		if ($End -lt 0) { throw "verify failed (payload unterminated): $Rel" }
		$Round = [Convert]::FromBase64String($StubText.Substring($Start, $End - $Start))
		for ($i = 0; $i -lt $Plain.Length; $i++) {
			$Salt = ($i + 1) % 256
			$V = (($Round[$i] + $KeyBytes[$i % $KeyBytes.Length] + $Salt) % 256)
			if ($V -ne $Plain[$i]) { throw "verify mismatch at byte $i in $Rel" }
		}
		Write-Output ("verified {0}" -f $Rel)
	}
}
Write-Output "Build complete."
