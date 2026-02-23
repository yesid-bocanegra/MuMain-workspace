# Feature Impact Maps

> Blast radius maps for MuMain's major systems. Use these to understand what breaks when you change something, and what to test after making changes.
>
> **Usage:** Load only the system section relevant to your change (~25-45 lines each).

## Section Navigation

| Section | Lines | Content |
|---------|-------|---------|
| [§1 Character System](#1-character-system) | ~40 | `ZzzCharacter.h` — 125 dependents |
| [§2 Inventory System](#2-inventory-system) | ~35 | `ZzzInventory.h` — 58 dependents |
| [§3 UI System](#3-ui-system) | ~40 | `NewUISystem.h` — 127 dependents (mega-include) |
| [§4 Network Layer](#4-network-layer) | ~35 | `WSclient.h` — 32 dependents, 50+ direct UI calls |
| [§5 Rendering Pipeline](#5-rendering-pipeline) | ~35 | `ZzzOpenglUtil.h` — 81 dependents, universal via stdafx.h |
| [§6 Map/World System](#6-mapworld-system) | ~30 | `MapManager.h` — 72 dependents |
| [§7 Effects System](#7-effects-system) | ~30 | `ZzzEffect.h` — 80 dependents |
| [§8 Buff System](#8-buff-system) | ~25 | `w_BuffStateSystem.h` — 2 direct, many via subsystems |
| [§9 Packet Protocol](#9-packet-protocol) | ~25 | Generated code, C++/C# interop boundary |
| [Change Impact Quick-Lookup](#change-impact-quick-lookup) | ~40 | "If changing X, also check Y" table |
| [Initialization Chain](#initialization-dependency-chain) | ~35 | ASCII diagram of init order + crash scenarios |
| [Feature Flag Registry](#feature-flag-impact-registry) | ~45 | Major flags with file counts |
| [Migration Impact](#cross-platform-migration-impact) | ~50 | Per-phase blast radius |

---

## §1 Character System

**Trigger files:** `ZzzCharacter.h`, `ZzzCharacter.cpp`

**Direct dependents (125 files):**
- **Core game logic:** `Winmain.cpp`, `ZzzObject.cpp`, `ZzzScene.cpp`
- **Scenes:** `LoginScene.cpp`, `CharacterScene.cpp`, `MainScene.cpp`, `SceneManager.cpp`
- **Inventory:** `ZzzInventory.cpp`, `ZzzInfomation.cpp`, `NewUIMyInventory.cpp`, `NewUIInventoryCtrl.cpp`
- **UI windows:** `NewUIMainFrameWindow.cpp`, `NewUICharacterInfoWindow.cpp`, `NewUIPartyListWindow.cpp`
- **Combat:** `ZzzEffect.cpp`, `ZzzAI.cpp`, `Event.cpp`, `DuelMgr.cpp`
- **Network:** `WSclient.cpp` (character state from packets)
- **Maps:** `MapManager.cpp`, `GM_*.cpp` files

**Cascade effects:**
- `CHARACTER` struct changes → breaks WSclient.cpp packet parsing (cast to struct pointers)
- Animation changes → affects all character rendering paths
- New character class → touches class selection UI, equipment validation, skill system

**Key globals:** `Hero` (player character pointer), `CharacterMachine` (character attribute system), `CharacterAttribute` (stat pointer)

**Test scope:** Character rendering, equipment display, skill casting, party member display, PvP/duel

**Danger zone:** `CHARACTER` struct is binary-serialized from network packets — any size/layout change must match server expectations exactly.

---

## §2 Inventory System

**Trigger files:** `ZzzInventory.h`, `ZzzInventory.cpp`

**Direct dependents (58 files):**
- **UI:** `NewUIMyInventory.cpp`, `NewUIInventoryCtrl.cpp`, `NewUIStoreInventory.cpp`, `NewUITrade.cpp`, `NewUIMixInventory.cpp`
- **Item info:** `ZzzInfomation.cpp`, `CSItemOption.cpp`, `NewUIItemExplanationWindow.cpp`
- **Network:** `WSclient.cpp` (item packets)
- **Shops:** `NewUIStorageInventory.cpp`, shop windows
- **Game logic:** `ZzzCharacter.cpp`, equipment effects

**Cascade effects:**
- Item struct changes → all inventory UIs must update rendering
- Slot count changes → grid layout recalculation (8x8 grid in `NewUIMyInventory`)
- Item option changes → tooltip system, comparison logic

**Key globals:** `CharacterMachine.Equipment[]` (equipped items), inventory arrays

**Test scope:** Pick up, drop, equip, trade, store, mix/craft, tooltip display, set item bonuses

**Danger zone:** Item data loaded from encrypted `.bmd` files — struct layout must match file format. Editor builds support export for verification.

---

## §3 UI System

**Trigger files:** `NewUISystem.h`, `NewUISystem.cpp`

**Direct dependents (127 files):**
- **All `NewUI*.h/.cpp` files** — every UI window registers through `NewUISystem`
- **Network:** `WSclient.cpp` — packet handlers call `g_pNewUISystem->Show()` directly
- **Scenes:** `MainScene.cpp`, `SceneManager.cpp` — lifecycle management
- **Game logic:** Any file using `g_p<WindowName>` macros (defined in `NewUISystem.h`)

**Cascade effects:**
- Adding/removing a UI window → 5 touch points (see Recipe §1)
- Changing `NewUIManager` API → breaks all window `Create()`/`Release()` calls
- Include order changes → massive recompile (127 files)

**Key globals:** `g_pNewUISystem` (singleton), `g_pNewUIMng` (manager), per-window `g_p*` macros

**Test scope:** Window open/close, layering (z-order), mouse event blocking, keyboard shortcuts

**Danger zone:** `NewUISystem.h` is a mega-include (85+ includes). Adding headers here triggers recompilation of 127 files. Prefer forward declarations where possible.

---

## §4 Network Layer

**Trigger files:** `WSclient.h`, `WSclient.cpp` (15,156 lines)

**Direct dependents (32 files):**
- **Connection:** `Dotnet/Connection.h`, `PacketFunctions_*.h/.cpp`
- **UI:** Direct calls from 50+ packet handlers into `g_pNewUISystem->Show()`, `g_p*Window` methods
- **Game state:** `ZzzCharacter.cpp`, `ZzzInventory.cpp`, `MapManager.cpp`
- **Scenes:** `LoginScene.cpp`, `CharacterScene.cpp`

**Cascade effects:**
- New packet → ProcessPacket() switch (line 12775), new handler function
- Packet struct change → must match server format exactly (binary protocol)
- Connection state change → cascades to all UI windows showing connection-dependent data

**Key globals:** `SocketClient` (Connection pointer, line 111), `HeroKey`, `LogIn` state

**Test scope:** Login flow, character list, game state sync, item operations, party/guild, chat

**Danger zone:** `ProcessPacket()` is a 1,500+ line switch statement. Duplicate `case` values cause silent compilation issues. Check for subcode conflicts.

---

## §5 Rendering Pipeline

**Trigger files:** `ZzzOpenglUtil.h`, `ZzzOpenglUtil.cpp`

**Direct dependents (81 files):**
- Included transitively via `stdafx.h` (precompiled header) — effectively **all 697 source files** rebuild when this changes
- **Direct users:** All `Zzz*.cpp` rendering files, `NewUI*.cpp` (2D rendering), `MuRenderer/` abstraction

**Cascade effects:**
- OpenGL state changes → visual regression across entire game
- Blend mode changes → affects all 14 files using `glBegin`/`glEnd` patterns
- Utility function signature changes → compilation errors across all rendering code

**Key globals:** `g_hDC`, `g_hRC` (OpenGL context), `g_hWnd` (window handle)

**Test scope:** Full visual regression — character rendering, terrain, effects, UI, text

**Danger zone:** Changes here trigger a **FULL REBUILD** of all 697 source files. Plan accordingly. Any OpenGL state left dirty propagates to subsequent draw calls unpredictably.

---

## §6 Map/World System

**Trigger files:** `MapManager.h`, `MapManager.cpp`

**Direct dependents (72 files):**
- **Scenes:** `SceneManager.cpp` (audio, clear color), `MainScene.cpp`
- **Map logic:** `GM_*.cpp` files (per-map game mechanics)
- **Objects:** `ZzzObject.cpp`, `ZzzOpenData.cpp` (object placement)
- **Characters:** `ZzzCharacter.cpp` (map-dependent behavior)
- **UI:** `NewUIMiniMap.cpp`, `NewUIWorldMap.cpp`
- **Effects:** `ZzzEffect.cpp` (map-dependent effects)
- **Audio:** `SceneManager.cpp` ambient/music functions

**Cascade effects:**
- `ENUM_WORLD` changes → recompile all 72 dependents
- `Load()` changes → affected map's objects/textures break
- World transition → audio system, NPC spawns, attribute data all need updating

**Key globals:** `gMapManager.WorldActive` (current map), `gMapManager.InHellas()` and similar helper methods

**Test scope:** Map loading, terrain rendering, object placement, NPC spawns, ambient sounds, music, map transitions

**Danger zone:** `Load()` in `MapManager.cpp` is a massive switch statement with 50+ cases. Each case loads specific models/textures — missing a case causes invisible objects.

---

## §7 Effects System

**Trigger files:** `ZzzEffect.h`, `ZzzEffect.cpp`

**Direct dependents (80 files):**
- **Character system:** `ZzzCharacter.cpp` (character effects, skills)
- **Combat:** Skill effects, hit effects, death animations
- **Objects:** `ZzzObject.cpp` (world object effects)
- **Maps:** `GM_*.cpp` (map-specific effects)
- **UI:** Effect-driven UI animations
- **Items:** Equipment visual effects, aura rendering

**Cascade effects:**
- Effect struct changes → all effect creators must update
- Rendering order changes → visual artifacts (alpha blending depends on order)
- New effect type → may need texture allocation in `_TextureIndex.h`

**Key globals:** Effect arrays, particle system state

**Test scope:** Skill animations, hit effects, environmental effects, buff visuals, item auras

**Danger zone:** Effects use OpenGL blending modes extensively. Incorrect blend state causes transparency artifacts that are hard to debug. Always restore blend state after custom effects.

---

## §8 Buff System

**Trigger files:** `w_BuffStateSystem.h`, `w_BuffStateSystem.cpp`

**Direct dependents (2 files):**
- Well-isolated with smart pointer pattern (`BuffStateSystemPtr`)
- Uses `SmartPointer()` macro + `Make()` factory for lifecycle management

**Indirect dependents via subsystems:**
- `BuffScriptLoader` — buff definition data
- `BuffTimeControl` — duration/timing
- `BuffStateValueControl` — stat modifications
- `NewUIBuffWindow.cpp` — buff icon display (8x2 grid)

**Cascade effects:**
- Buff state changes → character stats recalculation
- New buff type → script loader + UI icon + time control entries
- Duration system changes → all timed buffs affected

**Key globals:** Accessed via smart pointer, minimal global coupling

**Test scope:** Buff application, duration, stacking, visual icons, stat effects, buff removal

**Danger zone:** Despite low direct coupling, buff effects modify character stats — test stat display after changes. Buff icon grid in `NewUIBuffWindow` has fixed layout (8 columns).

---

## §9 Packet Protocol

**Trigger files:** `ClientLibrary/*.xslt`, NuGet XML packet definitions

**Direct dependents:**
- **Generated C++:** `Dotnet/PacketBindings_*.h`, `PacketFunctions_*.h/.cpp`
- **Generated C#:** `ConnectionManager.*Functions.cs`
- **Custom C++:** `PacketFunctions_Custom.h/.cpp`
- **Custom C#:** `ConnectionManager.ClientToServer.Custom.cs`
- **Handler:** `WSclient.cpp` (receive-side)

**Cascade effects:**
- XML packet definition change → regeneration of all generated files (4 per server type)
- Type mapping change in `Common.xslt` → affects ALL generated packets
- NuGet version bump → potential packet format changes across all packets

**Key boundary:** C++ ↔ C# interop via `CORECLR_DELEGATE_CALLTYPE` function pointers loaded with `symLoad`. Type mismatches cause runtime crashes, not compile errors.

**Test scope:** Send/receive for affected packets, marshaling correctness, .NET AOT compatibility

**Danger zone:** Function pointer typedefs in C++ must match `[UnmanagedCallersOnly]` signatures in C# **exactly**. Parameter count/type/order mismatch = crash at runtime with no compile-time warning.

---

## Change Impact Quick-Lookup

Single table — "If changing X, also check Y":

| If Changing... | Also Check These Files |
|----------------|----------------------|
| `CHARACTER` struct | `WSclient.cpp` (packet parsing), `ZzzEffect*.cpp`, `ZzzObject.cpp`, `NewUICharacterInfoWindow` |
| `ITEM_ATTRIBUTE` struct | `WSclient.cpp`, `ZzzInfomation.cpp`, `NewUIMyInventory`, `CSItemOption`, `ItemDataLoader` |
| Any `NewUI*.h` API | `NewUISystem.h/.cpp` (registration), `WSclient.cpp` (50+ direct UI calls from handlers) |
| Packet structures | `ClientLibrary/*.cs`, `PacketFunctions_*.h/.cpp`, `WSclient.cpp` `ProcessPacket()` |
| OpenGL blend/render state | All 14 `glBegin` files, `MuRenderer/` abstraction, `NewUI*` 2D rendering |
| `stdafx.h` | **ALL 697 source files** — full rebuild, plan accordingly |
| `Defined_Global.h` | All files guarded by any flag defined there (varies per flag) |
| `_enum.h` (INTERFACE_LIST) | `NewUISystem.h/.cpp`, `NewUIManager.cpp` |
| `_define.h` (EGameScene) | `Scenes/SceneManager.cpp`, `Scenes/SceneCommon.h`, `Scenes/SceneCore.h` |
| `MapManager.h` (ENUM_WORLD) | `MapManager.cpp`, `SceneManager.cpp` (audio/visual), all `GM_*.cpp` files |
| `_TextureIndex.h` | `ZzzOpenData.cpp` (loading), any `NewUI*.cpp` using those textures |
| `Connection.h` (bridge) | All packet send paths, `PacketFunctions_Custom.*`, `ConnectionManager.cs` |

---

## Initialization Dependency Chain

Init order in `Winmain.cpp` `WinMain()` function (lines 944-1354):

```
Config Load → Display Setup → Window + OpenGL Context
    → Translation (i18n) → Editor (if _EDITOR)
    → Graphics (VSync, Fonts)
    → CInput::Create()
    → g_pNewUISystem->Create()          ← UI system
    → wzAudio + DirectSound              ← Audio
    → Memory: GateAttribute, SkillAttribute, ItemAttribute, CharacterMachine
    → Hero + CharacterAttribute pointers
    → UI Input (TextInputBox)
    → CUIManager, BuffSystem, MapProcess, PetProcess
    → CUIMng (font binding, IME)
    → MainLoop()
```

### Critical Crash Scenarios

| If This Fails... | Then... |
|-------------------|---------|
| OpenGL context | Everything — no rendering possible |
| `g_pNewUISystem->Create()` | Any packet handler calling `g_pNewUISystem->Show()` crashes (50+ handlers) |
| `CharacterMachine` allocation | Character stat system fails, cascading to inventory and combat |
| `BuffSystem` init | Buff application crashes, affects character stats |
| `CUIMng` creation | Input handling fails, no keyboard/mouse response |
| Font creation | Text rendering fails across all UI |

### Key Constraint

Systems must initialize in this order. You cannot use `g_pNewUISystem` before `Create()` returns. Packet handlers (in `WSclient.cpp`) assume all systems are initialized — if the game receives packets before init completes, handlers will crash on null pointers.

---

## Feature Flag Impact Registry

Major feature flags sorted by impact scope:

| Flag | Files | Occurrences | Controls |
|------|-------|-------------|----------|
| `_EDITOR` | 41 | 95 | Debug editor overlay, ImGui, export tools |
| `ASG_ADD_MAP_KARUTAN` | 14 | 52 | Karutan map (2 zones), monsters, NPCs |
| `ASG_ADD_GENS_SYSTEM` | 11 | 35 | Faction system: ranking, marks, ground effects |
| `KJH_PBG_ADD_INGAMESHOP_SYSTEM` | 5 | 13 | In-game shop (parent flag for 9 sub-flags) |
| `PBG_ADD_CHARACTERSLOT` | 4 | 11 | Additional character slot support |

### KJH_PBG_ADD_INGAMESHOP_SYSTEM Sub-Flag Tree

```
KJH_PBG_ADD_INGAMESHOP_SYSTEM
├── PBG_ADD_INGAMESHOP_UI_MAINFRAME
├── PBG_ADD_INGAMESHOP_UI_ITEMSHOP
├── PBG_ADD_NAMETOPMSGBOX
├── KJH_ADD_INGAMESHOP_UI_SYSTEM
├── KJH_ADD_PERIOD_ITEM_SYSTEM
├── PBG_ADD_INGAMESHOPMSGBOX
├── PBG_ADD_ITEMRESIZE
├── KJH_MOD_SHOP_SCRIPT_DOWNLOAD
└── PBG_ADD_CHARACTERCARD
    Disabled (//^): PBG_ADD_CHARACTERSLOT, LDK_ADD_INGAMESHOP_LIMIT_MOVE_WINDOW
```

### ASG_ADD_GENS_SYSTEM Sub-Flag Tree

```
ASG_ADD_GENS_SYSTEM
├── ASG_ADD_INFLUENCE_GROUND_EFFECT
├── ASG_ADD_GENS_MARK
├── PBG_MOD_STRIFE_GENSMARKRENDER
└── PBG_ADD_GENSRANKING
```

---

## Cross-Platform Migration Impact

Per-phase blast radius from the SDL3 migration plan:

| Phase | Key Files Modified | Systems Affected | Blast Radius |
|-------|-------------------|------------------|--------------|
| Phase 0: Headers | `stdafx.h`, platform headers | Precompiled header | **FULL REBUILD** (697 files) |
| Phase 1: Window/Input | `Winmain.cpp`, `CInput` | Window creation, input, main loop | Login + character selection |
| Phase 2: SDL_gpu | 14 `glBegin` files, `MuRenderer/` | Entire rendering pipeline | **FULL VISUAL REGRESSION** |
| Phase 3: Audio | `wzAudio.*`, `DirectSound.*` | Background music, sound effects | All game audio |
| Phase 4: Filesystem | `ZzzOpenData.cpp`, `MapManager.cpp` | Asset loading, map data | All content loading |
| Phase 5: Text/Input | `CMultiLanguage`, IME handling | Text rendering, localization | All UI text display |
| Phase 6: Timer/Thread | `Winmain.cpp`, game loop | Frame timing, threading | Game loop stability |
| Phase 7: Clipboard/Misc | Minor platform APIs | Clipboard, cursor, system info | Minimal |
| Phase 8: .NET AOT | `Connection.h`, `ClientLibrary/` | C++/C# bridge, all networking | **ALL NETWORK FUNCTIONALITY** |
| Phase 9: Integration | Build system, CI | Compilation, testing | Build process |

### High-Risk Phases

- **Phase 0** — Every source file recompiles. Test build stability before proceeding.
- **Phase 2** — Rendering pipeline replacement. Requires screenshot-comparison regression testing.
- **Phase 8** — Network bridge replacement. Any marshaling error = runtime crash with no compile warning.
