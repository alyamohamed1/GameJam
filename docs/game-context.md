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
- **Senses (no sight cone — redesigned):**
  - **Same-room detection:** whenever Player 1 and Biscuit end up in the same room and Player 1 isn't in a hide spot, Biscuit notices after ~0.3 s and switches to CHASE.
  - **Hearing:** whenever Player 1 **runs** anywhere within ~160 px, Biscuit heads to the noise.
- **Hide spots:** standing inside the **Bathroom** (en-suite off the Office) or the **Closet** nook in the Bedroom makes Player 1 undetectable. Biscuit will search the room for ~5 s then leave to patrol.
- **Distractions:** the feeder (and the robot vacuum in the full version).
- **Catch:** Biscuit touching Player 1 while chasing is instant fail. No sight cone, no 1.5 s hold.
- **Speed:** patrol 45, chase 130 (faster than Player 1's sprint).
- **Visibility to Player 1:** Biscuit is **invisible on P1's screen when in a different room.** Player 2 is responsible for calling out positions over voice.
- **Behaviour states:**
  1. **Patrol** — loops through every room via HouseNav (Living → Hallway → Kitchen → Hallway → Office → Bathroom → Office → Hallway → Bedroom).
  2. **Investigate** — heard running; walks to the noise spot, sniffs ~2 s, resumes patrol.
  3. **Distracted** — walks to the feeder, eats 5 s with sight off, resumes patrol. Won't abandon an active chase for food.
  4. **Chase** — same room as Player 1 and not hidden: pursues at speed 130. Repaths to Player 1 every 0.25 s. Stuck-timeout forces a repath after 2 s of no movement.
  5. **Search** — lost Player 1 (they hid or left room): roams random points in the current room for 5 s, then patrols.
- **Tone:** comedic in look but genuinely dangerous — one touch ends the run.

## 5. Level 1 flow

1. **Player 1 enters the house** through the back door at the top of the hallway. Player 2 can see only through the pet feeder's camera at the start.
2. **Feeder distraction.** Player 2 triggers the feeder; the dog runs to eat; Player 1 sneaks into the Kitchen.
3. **The fridge.** Player 1 finds the laptop password on a note on the fridge: `Biscuit2019`.
4. **Laptop password.** Player 1 crosses the hallway to the Office, interacts with the laptop, types `Biscuit2019`.
5. **USB.** Player 1 plugs the virus USB into the Office machine. Player 2's camera feeds and Home Computer come online.
6. **The cipher.** The laptop screen now shows the encrypted file. Player 1 reads it to Player 2: `VHYHQ WZR QLQH IRXU`.
7. **Decrypt.** Player 2 types the ciphertext into their Home Computer panel and uses the Shift ± buttons. At shift 3 the decoded text reads `SEVEN TWO NINE FOUR` → safe code **7294**. Player 2 reads it to Player 1.
8. **The key.** Player 1 goes to the Living Room bookshelf and picks up the brass key to the bedroom.
9. **The safe.** Player 1 unlocks the Bedroom door, enters 7294 on the safe keypad. **BLACKOUT phase triggers.**
10. **Blackout.** Lights go out. Player 1's view shrinks to a small radius around themselves. Player 2's monitors flip to green night vision.
11. **Escape.** Player 2 guides Player 1 back to the Hallway and up to the Exit (same door they entered). Dog still roams; hide spots (Bathroom, Closet) still work.
12. **Victory** when Player 1 interacts with the Exit zone post-blackout.

**Target length:** 4–6 minutes for a first successful run.

## 6. House layout (proposed — designer draws the final version on grid paper)

Six rooms + a hallway corridor + a closet nook inside the bedroom. Final layout matches `game-jam/art/map.png`.

| Room | Where | Contents | Purpose |
|---|---|---|---|
| Hallway | Vertical corridor down the middle | Back door at top (spawn + exit), front door at bottom | Open path connecting every room; most exposed |
| Kitchen | Top-left | Fridge (holds laptop password note), **smart pet feeder** | Early puzzle + main distraction |
| Living Room | Bottom-left | Couch, armchair, dog bed, **bookshelf (holds bedroom key)** | Dog's main patrol area + key pickup |
| Office | Top-right | **Home laptop + USB port**; shows ciphertext post-USB; opens into Bathroom | Turning-point room |
| Bathroom | En-suite off the Office | Toilet, sink | **Hide spot** — dog can't detect Player 1 here |
| Bedroom | Bottom-right (behind locked door) | **Safe**, bed, nightstand, **small closet nook (hide spot)** | Goal + second hide spot |
| (future) Laundry / garage | — | Robot vacuum dock | Stage 2 |

Player 2 has **4 fixed room cameras** (Kitchen = feeder cam, Living, Office, Bedroom) plus **1 pannable Hallway camera** with up/down scroll buttons. The Hallway cam is intentional blind-coverage: P2 must actively pan to track the dog through the corridor. The Bathroom has no camera — hide spot stays safe.

## 7. Screens and presentation

### Player 1 screen
- Top-down pixel-art house, camera follows the character.
- **Fog of war:** the entire house outside Player 1's current room is covered by a dim 70% black overlay. Walking into a new room clears that room's overlay; the rest stay dark. The **dog is invisible** on P1's screen except when it's in Player 1's room.
- In-world prompts for interactions; simple overlay for typing the laptop password and the safe keypad.
- **Blackout:** CanvasModulate dims the whole canvas; a small radial Light2D on the burglar is the only light source. Vision radius ~1 room-section wide.

### Player 2 screen
- First-person desk view: 4 room-shape monitors + 1 pannable Hallway monitor + the Home Computer panel + Feeder/phase devices panel.
- Each monitor is a SubViewport sharing world_2d, pointed at a fixed `Camera2D` over its room. A `Polygon2D` with `clip_children` masks the view to the room's painted outline.
- Hallway monitor is a standard rectangle with up/down pan buttons (held) that scroll the camera vertically through the long corridor.
- Before USB: only the **feeder cam** feed is live; other monitors show "NO SIGNAL" and the Home Computer panel is locked.
- After USB: camera feeds come online. Home Computer unlocks: a LineEdit for ciphertext + shift −/+ buttons + live decoded preview. Player 2 types what Player 1 reads from the Office laptop.
- **Blackout:** all monitors receive a green modulate tint (night-vision placeholder; swap for a real CRT + night-vision shader in Stage 2).

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
