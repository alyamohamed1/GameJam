# GameJam

Two-player co-op horror puzzle. One player is the burglar inside a house (P1), the other watches CCTV monitors + a decoder laptop from a surveillance van (P2). They coordinate over voice to escape before blackout fails.

Built with **Godot 4.7** · GDScript · ENet multiplayer (LAN only).

## Requirements

- [Godot Engine 4.7.x](https://godotengine.org/download) (standard build, not .NET)
- Two machines on the same LAN (or one machine + two Godot instances for solo testing)

## Run from the editor

1. Clone the repo.
2. Open Godot → **Import** → select `game-jam/project.godot`.
3. Press **F5** to run. The main scene is `ui/lobby.tscn`.
4. In the lobby:
   - One player clicks **Host**.
   - The other clicks **Join** and types the host's LAN IP (e.g. `192.168.1.42`). Default port `7777`.

Find your LAN IP:
- macOS/Linux: `ipconfig getifaddr en0` or `ip addr`
- Windows: `ipconfig` → look for IPv4 address

## Run two instances on one machine (testing)

Godot → Debug menu → **Run Multiple Instances** → 2. Host in one window, join `127.0.0.1` in the other.

## Export + distribute (play without the editor)

1. Godot → Project → **Export**.
2. Add preset for your target (macOS / Windows Desktop / Linux). Install export templates when prompted.
3. **Export Project** to a folder.
4. Zip + share with the other player. Both run the binary, same host/join flow.

## LAN notes

- Port **7777** TCP+UDP must be allowed through the host's firewall.
- Both machines on the same Wi-Fi / router. Guest networks often block peer-to-peer — use the main SSID.
- No internet required; purely LAN.

## Project layout

```
game-jam/
  project.godot        # Godot project file (open this)
  ui/lobby.tscn        # main scene (host/join)
  level/house.tscn     # shared game world (P1's view)
  player1/             # burglar character + interactables
  player2/             # desk, monitors, decoder (P2 UI)
  net/net.gd           # ENet host/join + scene swap
  game/game.gd         # phase state machine (LOBBY → PRE_USB → POST_USB → BLACKOUT → VICTORY/FAIL)
  audio/, art/         # SFX + sprites
```

## Controls

- **P1 (burglar)**: `WASD` move, `Shift` run, `E` interact.
- **P2 (surveillance)**: mouse — click monitors, type ciphertext in the decoder, press Feeder button.
