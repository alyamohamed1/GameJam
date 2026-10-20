# Game Context: Untitled Heist (TBD)

> Two-player online heist for the **CHECKPOINT Reboot Game Jam** (19–21 Oct 2026).
> Theme: **TWO** — two playable characters whose relationship shapes what happens.
> Engine: **Godot 4** · Art: **retro pixel art** · Team: **3 people**, all code built on **one Mac** with Claude Code

This file is the single source of truth for the game. Anything marked **(proposed)** is a suggestion to confirm or change; anything marked **(open)** still needs a decision. The step-by-step build plan is in `docs/build-plan.md`.

---

## 1. One-line pitch

A burglar sneaks through a dark house past a guard dog while their partner, hacked into the home's smart devices and security cameras, watches, distracts, decrypts the safe code, and finally talks them out of a pitch-black house through night vision.

## 2. Theme fit

- **Two playable characters** with completely different views of the same world: one has a body and no information, the other has information and no body.
- **The relationship shapes what happens:** Player 1 survives only as well as Player 2 sees, signals, and decides. Player 2 can only progress through what Player 1 physically does in the house (plugging in the USB, finding clues, opening the safe).
- **The ending flips the dependence:** in the blackout, Player 1 is completely blind and is relying entirely on Player 2's voice.

## 3. The two players

### Player 1 — The Burglar (inside the house)
- **View:** top-down 2D, limited vision radius around the character (a soft light circle; the rest of the house is dark).
- **Actions:**
  - Walk (silent).
  - **Run** (fast, but **the dog hears it** and comes to the noise).
  - Interact (laptop, USB port, fridge, safe keypad, doors).
  - Type on in-world screens (laptop password, safe keypad).
- **Knows:** only what's in their vision radius. Cannot see the dog unless it's close.

### Player 2 — The Hacker (outside, on the network)
- **View:** first-person "desk" interface — a bank of pixel-art monitors and a computer screen. Never sees the house directly, only through devices.
- **Before the USB is plugged in:**
  - Has access to the **smart pet feeder** only.
  - The feeder has a built-in **pet camera** (the kitchen camera), which is Player 2's single view into the house at the start.
- **After the USB is plugged in:**
  - Full access to the **security camera feeds**, which show the dog's location at all times.
  - Access to the **home computer's files**, including the encrypted safe code.
  - Control of the **robot vacuum** as a moving distraction (full version only).
- **Tools:**
  | Tool | Available | Effect | Limit |
  |---|---|---|---|
  | Smart pet feeder | From start | Dispenses food; dog runs to the feeder and eats for ~5 s | Cooldown 20 s |
  | Robot vacuum | After USB (full version) | Player 2 steers it with arrow keys; the dog chases it | Slow; dog gives up after 6 s, ignores it for 15 s |
  | Security cameras | After USB | 5 live feeds, all visible at once, dog always visible | Fixed positions, blind spots between them |
  | Home computer | After USB | Browse files, find the encrypted safe code and the cipher hint, decrypt it | — |
  | Night vision | Blackout only | Camera feeds switch to green night vision automatically | — |

### Communication
- **Voice**, in person or on a call. The game does not provide chat. The yelling is part of the experience.

## 4. The third entity — the Dog

- A guard dog named **Biscuit** roaming the house.
- **Senses:**
  - **Sight cone:** if Player 1 is inside the cone with line of sight, the dog catches them.
  - **Hearing:** whenever Player 1 **runs**, the dog hears it (within ~160 px) and heads to that location.
- **Distractions:** the feeder (and the robot vacuum in the full version).
- **Catch = instant fail.** The level restarts.
- **Behaviour states:**
  1. **Patrol** — walks a set route between rooms.
  2. **Investigate** — heard running; walks to the noise location, sniffs around, returns to patrol.
  3. **Distracted** — goes to the feeder / chases the vacuum; sight cone off while eating.
  4. **Alert → Catch** — sees Player 1; "!" for 0.5 s, and if Player 1 is still visible → fail screen.
- **Tone:** comedic in look (big pixel-art dog, cartoon "!" bubble, comically loud chewing) but genuinely dangerous: one mistake ends the run.

## 5. Level 1 flow

1. **Player 1 enters the house.** Player 2 can see only through the pet feeder's camera.
2. **Feeder distraction.** Player 2 triggers the feeder; the dog runs to eat; Player 1 sneaks to the office.
3. **Laptop password.** The home laptop is locked. A failed attempt shows a hint pointing to the fridge (*"Where the milk lives"*).
4. **The fridge.** Player 1 finds the password on a note on the fridge: `Biscuit2019` (the dog's name + year).
5. **USB.** Player 1 logs in and plugs in the virus USB. **Player 2's camera feeds and computer access come online** (and the robot vacuum in the full version).
6. **Guided sneaking.** Player 2 now sees the dog at all times and guides Player 1 by voice, using the feeder to clear paths.
7. **Safe code.** On the home computer, Player 2 finds an encrypted file with the hint: *"Caesar jumps the fence 3 times."* Player 2 decrypts it with a Caesar shift of 3.
   - Ciphertext: `VHYHQ WZR QLQH IRXU`
   - Decrypts to: `SEVEN TWO NINE FOUR` → safe code **7294**
8. **The safe.** Player 2 reads the code aloud; Player 1 enters it on the safe keypad. **Loot acquired.**
9. **Blackout.** The moment the safe opens, **all lights in the house turn off.** Player 1's view goes almost completely dark. Player 2's cameras switch to **night vision.** The dog is still roaming.
10. **Escape.** Player 2 guides Player 1 out by voice alone, while Player 1 moves almost blind.
11. **Victory** when Player 1 reaches the exit.

**Target length:** 4–6 minutes for a first successful run.

## 6. House layout (proposed — designer draws the final version on grid paper)

Single-floor house, roughly 6–7 rooms:

| Room | Contents | Purpose |
|---|---|---|
| Entrance / hallway | Front or back door | Start + escape exit |
| Kitchen | Fridge (laptop password), **smart pet feeder** | Early puzzle + main distraction |
| Living room | Couch, TV, dog bed | Dog's main patrol area |
| Office | Home laptop + USB port | Turning point of the level |
| Bedroom | **Safe** | Goal |
| Hallway(s) | Long sightlines | Most dangerous areas for the sight cone |
| (optional) Laundry / garage | Robot vacuum dock | Where the vacuum starts |

5 cameras cover the kitchen (feeder cam), hallway, living room, office, and bedroom, with deliberate blind spots so Player 2 occasionally loses track.

## 7. Screens and presentation

### Player 1 screen
- Top-down pixel-art house, camera follows the character.
- Limited vision radius; darkness outside it.
- In-world prompts for interactions; simple overlay for typing the laptop password and the safe keypad.
- **Blackout:** vision radius shrinks to almost nothing.

### Player 2 screen
- First-person desk view: a grid of 5 CCTV monitors plus the computer screen.
- Before USB: only the **feeder cam** feed is live; other monitors show "NO SIGNAL".
- After USB: camera feeds come online with grainy, scan-lined, slightly desaturated pixel style (full version; plain feeds in the basic version).
- Computer screen: file browser, the encrypted file, and a decryption tool (shift −/+ with live decoded text; cipher wheel art in the full version).
- Device controls: feeder button (with cooldown); vacuum via arrow keys (full version).
- **Blackout:** all feeds switch to green **night vision**.

## 8. Technical plan (Godot 4)

### Development setup
- **All code and scenes are built on one Mac** with Claude Code. Teammates send art/sound by AirDrop and never edit the project.
- Day-to-day testing: **Debug → Customize Run Instances**, 2 instances with feature tags `host` and `client`, on the same Mac.
- Two-Mac playtests: copy the project (zip via AirDrop, later the exported app) to a second Mac; both join a **phone hotspot** (school Wi-Fi blocks device-to-device connections).

### Networking
- **Godot high-level multiplayer** with `ENetMultiplayerPeer`, port 7777.
- **Same network / LAN only**: the host clicks Host, the client types the host's IP. (Over-the-internet play is out of scope.)
- **Player 1's machine is the host and authority**: it runs the dog AI, game state, and puzzle state. Player 2 is the client and sends device actions as RPCs.
- Sync with `MultiplayerSynchronizer` (positions of Player 1, dog, vacuum) and RPCs (feeder triggered, phase changes, fail/restart, victory).

### One world, two views
- Both machines load the **same house scene**.
- Player 1's view: a `Camera2D` following the burglar, plus darkness (`CanvasModulate` + `PointLight2D`).
- Player 2's view: several `SubViewport`s sharing the root `world_2d`, each with a fixed `Camera2D` pointed at a room, rendered into the monitor grid; CCTV and night-vision via one shader (full version).
- Player 2's machine deletes the darkness layer, so Player 2 sees rooms clearly and Player 1 does not.

### Game states
`Lobby → PreUSB → PostUSB → Blackout → Victory` and `Fail → Restart` from any active state.

### Key systems
- Player 1 controller (walk, run with noise event, interact).
- Dog AI state machine (patrol path, investigate noise, distracted, alert/catch).
- Sight cone (`Area2D` cone + raycast line-of-sight check).
- Noise events (running emits a noise at Player 1's position the dog can hear within a radius).
- Feeder and vacuum (device logic, cooldowns, synced).
- Puzzles (laptop password, USB unlock, cipher file, safe keypad).
- Lighting/blackout and night vision.

## 9. Art and audio direction

- **Retro pixel art**, comedic characters, dark and moody house.
- Base resolution 480×270, scaled up; 16×16 tiles.
- Palette: dark blues/purples for the house at night, warm yellow/orange for lights and interactables, green for night vision.
- Comedy lives in the characters and reactions (the dog's "!" bubble, chewing animation, the vacuum bumping into walls). Tension lives in lighting, sound, and the instant-fail rule.
- **Audio:** quiet ambience, footsteps (louder when running), dog sniffing/growling as it gets close, feeder dispense sound, vacuum hum, a hard silence + "click" when the blackout hits.

## 10. Scope and schedule

Treat Level 1 as the full game; polish it rather than adding levels. Build in stages:

- **Stage 0 — connected skeleton (Tue 17:30):** host/join works; Player 1 square moves and syncs; Player 2 sees one monitor.
- **Stage 1 — basic version (Tue 00:30, latest Wed 10:00):** the whole loop with coloured squares, no vacuum, no shaders, no checkpoints, no art or sound.
- **Stage 2 — full version (Wed until 12:00 freeze):** art, sound, CCTV + night-vision shader, checkpoints, vacuum, juice.

| When | Goal |
|---|---|
| **Tue afternoon** | Setup, Stage 0, first two-Mac test by 17:30. **Modifier drops at 18:00** — fold it in. |
| **Tue evening** | Stage 1: dog AI, monitors, feeder, puzzles, blackout, exit. Basic-version playtest at 00:30. |
| **Wed** | Finish Stage 1, Stage 2 until the 12:00 feature freeze, then exports, playtests, submission. |

### Team roles
- **Builder:** all code and scenes on the build Mac with Claude Code; commits and exports.
- **Designer / tester:** house layout on grid paper, all in-game text, plays Player 2 in every test, bug list, tuning, jam page.
- **Artist:** all art and sound, delivered by AirDrop with agreed file names and sizes.

## 11. Open questions

- How does the **modifier** (20 Oct, 6:00 PM) change the design?
- Final game title.

Decided: all 5 feeds visible at once; feeder cam before the USB; no carrying treats; no time limit (show run time on victory); vacuum keeps working in the blackout (battery-powered).

## 12. Name ideas

- *Good Boy*
- *Inside Job*
- *Night Vision*
- *Biscuit*
- *Sit. Stay. Steal.*
