# Pre-Migration Modular Reorganization (Phase -1)

> Reorganization of `MuMain/src/source/` from a flat 697-file directory into 20 module directories with CMake library targets. Completed before the 58-session SDL3 cross-platform migration.

## Motivation

- **Scope boundaries:** Each SDL3 migration phase maps cleanly to a module
- **Incremental builds:** Editing `RenderFX/` only recompiles MURenderFX + MUGame, not all 692 files
- **Dependency clarity:** Independent libraries (MUCore, MURenderFX, MUAudio) have enforced boundaries; coupled code (Network ↔ UI) stays honest in MUGame

## Module Directory Structure

```
MuMain/src/source/
├── Main/              (4 files)   — Entry point, PCH (Winmain, stdafx)
├── Core/              (41 files)  — Types, defines, enums, math, time, utilities, logging, input
├── Protocol/          (3 files)   — Crypto, key generation
├── Network/           (10 files)  — Sockets, WSclient, server list, map server
├── Data/              (60 files)  — Loaders, localization, GameData, DataHandler, GameConfig
│   ├── Items/         (14 files)  — Item structs, handler, loader, saver, exports, metadata
│   ├── Skills/        (14 files)  — Skill structs, handler, loader, saver, exports, metadata
│   └── *(root)*       (32 files)  — Infrastructure, config, localization, SMD, GlobalBitmap
├── World/             (77 files)  — MapManager, terrain, GM_* scripts, physics, portals
│   ├── Maps/          (59 files)  — All GM* map scripts + C*Direction cutscene files
│   └── *(root)*       (18 files)  — MapManager, PhysicsManager, terrain, portals
├── Gameplay/          (108 files) — Characters, objects, AI, inventory, skills, pets, buffs, events
│   ├── Characters/    (16 files)  — ZzzCharacter, CharacterManager, ZzzObject, ZzzAI, MonkSystem
│   ├── Items/         (20 files)  — ZzzInventory, ItemManager, CSItemOption, SocketSystem, MixMgr
│   ├── Pets/          (23 files)  — w_Pet*, CSPetSystem, GIPetManager, w_BasePet, npcBreeder
│   ├── Events/        (16 files)  — Event, CSChaosCastle, MatchEvent, w_CursedTemple, DuelMgr
│   ├── Buffs/         (10 files)  — w_Buff*, w_BuffState*, w_BuffTimeControl
│   ├── Skills/        (6 files)   — SkillManager, SkillEffectMgr, SummonSystem
│   ├── Social/        (9 files)   — PartyManager, GuildCache, GuildConstants, CSQuest, QuestMng
│   └── NPCs/          (8 files)   — npcCatapult, npcGateSwitch, MuHelper, MuHelperData
├── UI/
│   ├── Framework/     (42 files)  — NewUIBase, NewUIManager, NewUISystem, widgets
│   ├── Windows/       (112 files) — All NewUI*Window game windows
│   │   ├── Events/    (22 files)  — BloodCastle*, ChaosCastleTime, CursedTemple*, DoppelGanger*
│   │   ├── Inventory/ (16 files)  — MyInventory, Storage*, MixInventory, ShopInventory
│   │   ├── HUD/       (14 files)  — MainFrameWindow, WindowMenu, MiniMap, CommandWindows
│   │   ├── Commerce/  (14 files)  — NPCShop, NPCDialogue, Trade, UnitedMarketPlace, LuckyCoin
│   │   ├── Social/    (12 files)  — Party*, FriendWindow, GuildInfo*, GensRanking
│   │   ├── Castle/    (10 files)  — CastleWindow, CatapultWindow, Gateman*, GuardWindow
│   │   ├── Character/ (10 files)  — CharacterInfoWindow, BuffWindow, MasterLevel, PetInfo
│   │   ├── Quest/     (6 files)   — MyQuestInfoWindow, QuestProgress*
│   │   └── *(root)*   (8 files)   — ChatInputBox, ChatLogWindow, OptionWindow, HelpWindow
│   ├── Events/        (30 files)  — Event UIs (siege, duel, battle soccer, crywolf)
│   └── Legacy/        (60 files)  — Win/WinEx, UI*, ZzzInterface, login/char select
├── Audio/             (5 files)   — DirectSound
├── RenderFX/          (24 files)  — Effects, models, textures, OpenGL utils
├── Scenes/            (16 files)  — Already existed, unchanged
├── Dotnet/            (13 files)  — Already existed, unchanged (generated)
├── GameShop/          (76 files)  — Already existed, unchanged
├── Translation/       (2 files)   — Already existed, unchanged
├── ThirdParty/        (8 files)   — External code (regkey, xstreambuf, UIControls)
├── Platform/          (0 files)   — Empty, populated by Phase 0 SDL3 migration
└── Resources/Windows/ (1 file)    — RC, ICO files
```

## CMake Target Map

```
MUCommon (INTERFACE)         ← Shared include dirs, definitions, C++20
  │
  ├── MUCore (STATIC)        ← Core/*.cpp — compiles the PCH
  │     │
  │     ├── MUProtocol       ← Protocol/*.cpp
  │     ├── MUData           ← Data/*.cpp
  │     ├── MURenderFX       ← RenderFX/*.cpp
  │     ├── MUAudio          ← Audio/*.cpp
  │     └── MUPlatform       ← Platform/*.cpp (empty/INTERFACE for now)
  │
  ├── MUThirdParty (STATIC)  ← ThirdParty/*.cpp
  │
  └── MUGame (STATIC)        ← Network/, World/, Gameplay/, UI/**, Scenes/,
        │                       Dotnet/, GameShop/, Translation/
        │                       Links: MUCore + all independent libs
        │
        └── Main (EXECUTABLE) ← Main/*.cpp + system libs + .NET DLL
```

## Dependency Rules

| Target | Links | Boundary |
|--------|-------|----------|
| MUCore | MUCommon | No game dependencies |
| MUProtocol | MUCore | Core types only |
| MUData | MUCore | Core types only |
| MURenderFX | MUCore | Core types only |
| MUAudio | MUCore | Core types only |
| MUThirdParty | MUCommon | External code, no game deps |
| MUPlatform | MUCore | Empty now, SDL3 in Phase 0 |
| MUGame | All above | Coupled code stays together |
| Main | MUGame | Entry point only |

## Design Decisions

### Why MUGame is one big target

Network ↔ UI circular dependency: `WSclient.cpp` includes 4 NewUI headers for message boxes and inventory control. UI headers reference WSclient for network communication. Rather than hide this coupling behind forward declarations, we keep it honest in MUGame until the SDL3 migration phases decouple them.

### Why include paths are flat

All module directories are in the include path (via MUCommon INTERFACE). This allows existing `#include "FileName.h"` patterns to work unchanged. True dependency enforcement happens through link-time errors: adding `#include "NewUISystem.h"` in a Protocol/*.cpp file would compile but the linker would fail because MUProtocol doesn't link MUGame.

### Subdirectories are for navigation, not encapsulation

C++ has no language-level package system. Unlike Java packages or C# namespaces, directory nesting doesn't create access boundaries — any file in MUGame can include any other file in MUGame regardless of subdirectory. Every subdirectory is added to the include path so bare `#include "FileName.h"` works unchanged.

The subdirectories (e.g., `Gameplay/Pets/`, `UI/Windows/Castle/`) exist purely for **human navigation** in a 692-file codebase. Real dependency enforcement comes from CMake library targets: `MUCore` can't call into `MUGame` because it doesn't link it. That's compile-time enforcement the filesystem alone cannot provide.

Trade-offs of this approach:
- **Pro:** Developers find files faster when directories match logical groupings they already think in
- **Pro:** Works well alongside CMake targets that enforce actual boundaries
- **Con:** Each subdirectory needs an include path entry (19 added for this subdivision)
- **Con:** Can create a false sense of encapsulation — `Gameplay/Skills/*.cpp` can freely include `UI/Windows/Castle/*.h`

Nesting is kept to 2–3 levels maximum. Deeper nesting adds navigation friction without additional enforcement.

### PCH Strategy

`stdafx.h` (in Main/) is a fat PCH that includes headers from many modules. MUCore compiles it, and all other targets reuse it via `target_precompile_headers(... REUSE_FROM MUCore)`. Thinning the PCH is deferred to the migration.

### Inspiration

Based on [mu-nreal's modular proposal](https://github.com/sven-n/MuMain/issues/59#issuecomment-3662928837) with pragmatic adjustments: split only naturally clean modules, keep coupled code in MUGame.

## Migration Phase Mapping

| Phase | Primary Module(s) | Benefit |
|-------|-------------------|---------|
| Phase 0 | MUPlatform (new) | Populates empty Platform/ |
| Phase 1 | MUCore, Main | Window/input abstraction |
| Phase 2 | MURenderFX | SDL_gpu replaces OpenGL |
| Phase 3 | MUAudio | miniaudio replaces DirectSound |
| Phase 4-9 | MUGame internals | Gameplay, UI, network migration |
