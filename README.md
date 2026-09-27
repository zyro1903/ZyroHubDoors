# ZyroHub

A DOORS script hub by **Zyro** and **Rag_zar123**, with a green theme and a custom notification, ESP and save/theme stack.

## Use

DOORS only for now. Run this in the game:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Games/Doors/Main.luau"))()
```

In any other place, the universal loader prints a notice and stops:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Games/Universal/Loader.luau"))()
```

## Tabs

| Tab | Groupboxes |
| --- | --- |
| General | Character, Self, Automation, Miscellaneous, Debug |
| Exploits | Bypass / Solve, Bypass, Remove, Audio |
| Visuals | Camera, Effects, Entities, Settings, ESP |
| Floors | Automation, Completion, Visuals, Bypass, Farming |
| New - Archives | Exploits / Anti, Bypasses, Experimental |
| New - Stairwell | Exploits / Anti, Experimental |
| Info | User Info, Credits, Changelog, Executor Info, Scripts, Community |
| Settings | Menu, theme and config sections |

## Theme

Green is the default accent colour and a dedicated `ZyroHub` theme ships with the theme manager:

| Theme | Main | Accent | Background | Outline |
| --- | --- | --- | --- | --- |
| ZyroHub | `#16241a` | `#22c55e` | `#0f1a12` | `#2b4a33` |

Themes and configs are stored under `ZyroHub/Doors/Game`.

## Death Farm (unattended)

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/zyro1903/ZyroHubDoors/refs/heads/main/Scripts/DeathFarm.luau"))()
```

- Joins solo Hotel runs, takes the room-0 key, opens the door, dies and repeats forever.
- Built for overnight AFK sessions: every step is deadline-bounded and self-recovering.

## Executor requirements

`Components/Environment.luau` runs a self-test on load and lists failed features in the **Info → Executor Info** groupbox. Executors with known broken features (Volcano, Opiumware, Solara, Xeno) get those tests skipped automatically.

## Credits

- **Zyro** — Owner and Developer
- **Rag_zar123** — Developer

## License

See [LICENSE.md](LICENSE.md).
