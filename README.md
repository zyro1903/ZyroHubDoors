# ZyroHub

## Use

```
loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Loader.luau"))()
```

Project dependencies are pinned to release commits and cached locally when the executor supports file APIs.

## Death Farm (unattended)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Scripts/DeathFarm.luau"))()
```

- Joins solo Hotel runs, takes the room-0 key, opens the door, dies and repeats forever.
- Built for overnight AFK sessions: every step is deadline-bounded and self-recovering, and an anti-idle refresh prevents Roblox disconnects.
- Stop it by creating the file `ZyroHub/DeathFarm.stop` through any executor file API.

## Privacy

This project does not collect analytics, account data, IP addresses, HWIDs, or execution telemetry.

## Settings

- English and Turkish interface
- Touch controls for mobile executors
- Reversible performance mode
- Local config export/import codes
- Favorites for frequently used toggles
- Draggable signature watermark (version, name, executor, live FPS)
- Position Spoof stair fix and manual Hip Height control
- The Rooms: auto walk with pathfinding, A-60 handling and footstep spoof
- Extra Archives tools: Forget-Me-Not skipper, clock readout, anti-spawn toggles

## Validation

Every push and pull request runs `scripts/validate.ps1` to check for removed telemetry and legacy traces.

## Credits

Creator: Zyro
