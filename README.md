# Dual Cannon — Real-Time 2D Artillery Combat

[![Engine](https://img.shields.io/badge/Engine-Godot%204.x-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Language](https://img.shields.io/badge/Language-GDScript-355570?logo=godotengine&logoColor=white)](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/)
[![Tests](https://img.shields.io/badge/Tests-20%2F20%20Passing-success)](scenes/TestRunnerScene.tscn)
[![Deployment](https://img.shields.io/badge/Deploy-Vercel-black?logo=vercel&logoColor=white)](https://vercel.com)
[![Author](https://img.shields.io/badge/Author-codeXOm-blue?logo=github)](https://github.com/codeXOm)

A real-time 1v1 artillery tank combat game developed in **Godot Engine 4.x** with GDScript, featuring continuous automatic barrel sweeping, hold-to-charge mechanics, 2D destructible boolean CSG terrain, dynamic cannon gravity, progressive difficulty, and responsive UI.

---

## 🎮 Core Mechanics: Automatic Aim + Hold-to-Charge + Release-to-Fire

1. **Continuous 180° Automatic Aim Sweep**:
   - Each cannon barrel automatically sweeps through a 180-degree upper aiming arc ($[-180^\circ, 0^\circ]$).
   - The barrel reverses direction smoothly at the endpoints.
2. **Single-Key Hold-and-Release Control**:
   - **Blue Player (Left)**: Hold and release `SPACE`.
   - **Red Player (Right)**: Hold and release `ENTER`.
3. **Press & Lock Aim**:
   - Pressing and holding the key locks the barrel angle instantly.
   - A directional trajectory guide line indicates the locked firing line.
4. **Smooth Power Charge Cycle (0% ↔ 100%)**:
   - Power begins charging from 0% on initial press.
   - Smoothly increases to 100%, then decreases back to 0%, cycling continuously while held.
5. **Real-Time Visual Power Meter**:
   - Visual badge displays exact percentage and direction (`48% ▲ UP` / `65% ▼ DN`).
   - Dynamic multi-color progress bar with needle indicator.
6. **Release-to-Fire**:
   - Releasing the key fires exactly one rocket with the locked angle and power at that precise instant.
7. **Immediate Reset & Auto-Resume**:
   - The charging state resets, and automatic barrel sweeping resumes immediately.
8. **Real-Time Simultaneous Combat**:
   - Both players can charge, hold, and fire independently. Multiple projectiles fly simultaneously.
9. **Dynamic Terrain Support & Gravity**:
   - Cannons are physical `CharacterBody2D` entities. When explosions destroy the terrain beneath a cannon, gravity takes over and the cannon falls naturally to the next supporting surface. Falling off the screen bottom triggers out-of-bounds destruction.

---

## 🏔️ Progressive Terrain Generation & Difficulty

Each level generates a distinct, non-repeating ground pattern with difficulty-appropriate hazards and elevation differences:

| Level | Difficulty | Elevation Delta ($\Delta Y$) | Terrain Features |
| :--- | :--- | :--- | :--- |
| **Level 1** | **Beginner** | $0\text{ px}$ | **Gentle Rolling Valley**: Broad shallow basin dipping to $Y=595$. Wide-open sightlines. |
| **Level 2** | **Easy** | $10\text{ px}$ | **Rolling Dunes**: Two moderate dips with a gentle central crest. Low rolling shots get caught. |
| **Level 3** | **Intermediate** | $30\text{ px}$ | **The Great Ridge**: Central hill rising to $Y=470$ flanked by deep gullies. Requires high-arc mortar shots. |
| **Level 4** | **Challenging** | $70\text{ px}$ | **Asymmetric Stepped Mesa**: Blue on high ground, Red on low ground. Central mesa with steep canyons. |
| **Level 5** | **Advanced** | $0\text{ px}$ | **Twin Jagged Crags & Abyss**: Sharp twin peaks obstructing direct line-of-sight; deep center gorge. |
| **Level 6+** | **Expert & Endless** | Dynamic ($\pm 45\text{ px}$) | **Procedural Multi-Harmonics**: Non-repeating multi-frequency harmonic landscape seeded deterministically. |

---

## 🕹️ Game Modes

### Mode A: Local 2-Player (Same Keyboard)
- **Blue Cannon (Left)**: Hold & Release `SPACE`
- **Red Cannon (Right)**: Hold & Release `ENTER`

### Mode B: Player vs Autonomous AI
- Human controls Blue; intelligent ballistic solver AI controls Red.
- Dynamic solver calculates ballistic arcs taking elevation difference, distance, and lateral wind into account.
- **Easy**: $\pm 12^\circ$ aiming noise, $\pm 15\%$ power variance, $1.2\text{s} \dots 1.8\text{s}$ cooldown.
- **Normal**: $\pm 4^\circ$ aiming noise, $\pm 5\%$ power variance, $0.8\text{s} \dots 1.2\text{s}$ cooldown.
- **Hard**: $\pm 1.2^\circ$ precision, wind-compensated trajectory, $0.5\text{s} \dots 0.8\text{s}$ cooldown.

---

## 🚀 Deployment on Vercel

This repository includes a configured `vercel.json` with the necessary HTTP security headers for Godot 4 Web exports (`SharedArrayBuffer` / WebAssembly):

```json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
      ]
    }
  ]
}
```

### Deploying to Vercel in 2 Steps:
1. **Push this repository to GitHub** (`https://github.com/codeXOm/<repo-name>`).
2. **Import into Vercel**:
   - Go to [Vercel Dashboard](https://vercel.com/new).
   - Click **Import Project** and select your GitHub repository.
   - Deploy!

Or deploy directly via terminal using Vercel CLI:
```bash
npx vercel
```

---

## 🧪 Automated Test Suite

Run the headless verification suite:
```bash
godot --headless scenes/TestRunnerScene.tscn
```

### Test Suite Status: **20/20 PASSED (100%)**
- `[TEST 1]` Autoload Singletons (GameState, AudioManager)
- `[TEST 2]` Automatic Continuous Barrel Sweep & Endpoint Reversal
- `[TEST 3]` Press → Lock Angle → Hold-to-Charge → Release → Fire
- `[TEST 4]` Red Player Independent Simultaneous Combat
- `[TEST 5]` Pause Safety & Accidental Fire Prevention
- `[TEST 6]` Destructible Terrain Boolean CSG Carving
- `[TEST 7]` Lethal Damage, Scoring & Victory Signals
- `[TEST 8]` Single Previous Trajectory Guide Retention
- `[TEST 9]` Cannon Gravity & Out-of-Bounds Constants
- `[TEST 10]` Free-Fall Velocity Accumulation Logic
- `[TEST 11]` Reset Cannon Velocity Clearing
- `[TEST 12]` Terrain Damaged Signal Infrastructure
- `[TEST 13]` Cannon Collision Layer & Mask Configuration
- `[TEST 14]` Progressive Terrain Patterns & Elevation Scaling (Levels 1–5)
- `[TEST 15]` Endless Procedural Generation Beyond Level 6
- `[TEST 16]` Cannon Stable Grounding & Spawn Positioning
- `[TEST 17]` Advanced Terrain Cratering & Hole Filtering
- `[TEST 18]` Level Advancement & Match Restart Transitions

---

## 👤 Author

Developed by **[codeXOm](https://github.com/codeXOm)**.
Built with **Godot Engine 4.x** and **GDScript**.
