$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$patterns = @(
    "Analytics",
    "api/send",
    "AdonisBypass",
    "Legit",
    "Linoria",
    "fix_credits",
    "LICENSE.md"
)

$files = Get-ChildItem $root -Recurse -File | Where-Object {
    $_.FullName -notmatch "\\.git\\" -and $_.Name -ne "validate.ps1" -and $_.Extension -in @(".luau", ".ps1", ".yml", ".yaml", ".json")
}

$matches = $files | Select-String -Pattern $patterns
if ($matches) {
    $matches | Format-Table Path, LineNumber, Line -AutoSize
    throw "Forbidden legacy or telemetry trace found."
}

$luauFiles = $files | Where-Object Extension -eq ".luau"
if (-not $luauFiles) {
    throw "No Luau files found."
}

foreach ($file in $luauFiles) {
    if ((Get-Content $file.FullName -Raw).Length -eq 0) {
        throw "Empty Luau file: $($file.FullName)"
    }
}

Write-Host "Validation passed: $($luauFiles.Count) Luau files checked."
