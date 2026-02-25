# MuMain Source Tree Analysis

## Repository Structure

```
MuMain-workspace/                          # Parent workspace (documentation + submodule)
├── docs/                                  # Project knowledge base (generated docs)
│   ├── CROSS_PLATFORM_PLAN.md             # 10-phase SDL3/SDL_gpu migration plan
│   ├── CROSS_PLATFORM_DECISIONS.md        # Research, rationale, library decisions
│   └── index.md                           # Master documentation index
├── _bmad/                                 # BMAD framework (development methodology)
├── _bmad-output/                          # BMAD workflow outputs
├── .gitmodules                            # Submodule: MuMain → sven-n/MuMain.git
│
└── MuMain/                                # ★ Game client submodule (primary codebase)
    ├── CMakeLists.txt                     # Root CMake: C++20, adds src/ subdirectory
    ├── CMakePresets.json                  # Build presets: windows-x86/x64 ± mueditor
    ├── toolchain-x86.cmake               # 32-bit cross-platform toolchain
    ├── toolchain-x64.cmake               # 64-bit cross-platform toolchain
    ├── README.md                          # Project overview, build instructions, credits
    ├── TRANSLATION_SYSTEM_INTEGRATION.md  # i18n system architecture (3 domains)
    ├── stylecop.json                      # C# code style rules
    ├── .editorconfig                      # Editor formatting rules
    │
    ├── .github/workflows/                 # CI/CD pipelines
    │   └── ci.yml                         # Quality gates + MinGW cross-compile
    │
    ├── ClientLibrary/                     # ★ Part 2: .NET Network Layer
    │   ├── MUnique.Client.Library.csproj  # .NET 10, Native AOT, packet handling
    │   ├── ConnectionManager.cs           # Core connection management
    │   ├── ConnectionWrapper.cs           # Connection wrapper utilities
    │   ├── ConnectionManager.ClientToServer.Custom.cs  # Custom packet handlers
    │   ├── ConnectionManager.ChatServer.Custom.cs      # Chat server extensions
    │   ├── ConnectionManager.*Functions.cs              # ⚡ GENERATED: XSLT → C# bindings
    │   ├── GenerateExtensionsDotNet.xslt  # Code gen: XML → C# extensions
    │   ├── GenerateFunctionsHeader.xslt   # Code gen: XML → C++ headers
    │   ├── GenerateFunctions.xslt         # Code gen: XML → C++ implementations
    │   ├── GenerateBindingsHeader.xslt    # Code gen: XML → C++ packet structs
    │   └── Common.xslt                    # Shared XSLT templates
    │
    ├── ConstantsReplacer/                 # ★ Part 3: Code Generation Tool
    │   ├── ConstantsReplacer.csproj       # .NET 8, WinForms GUI
    │   ├── Program.cs                     # Entry point
    │   ├── MainForm.cs                    # GUI form
    │   ├── Replacer.cs                    # Replacement logic
    │   ├── FileEncoding.cs                # Encoding detection (UDE.CSharp)
    │   └── *.sql                          # OpenMU item/monster constant SQL
    │
    ├── cmake/toolchains/                  # Cross-compilation toolchain files
    │   └── mingw-w64-i686.cmake           # MinGW 32-bit cross-compile
    │
    ├── docs/
    │   └── build-guide.md                 # Platform-specific build instructions
    │
    └── src/                               # ★ Main source tree
        ├── CMakeLists.txt                 # Primary build config (482 lines)
        ├── afxres.h                       # MFC resource compatibility header
        │
        ├── bin/                           # Runtime assets & DLLs
        │   ├── config.ini                 # Game configuration (INI format)
        │   ├── glew32.dll                 # OpenGL Extension Wrangler
        │   ├── ogg.dll                    # OGG Vorbis codec
        │   ├── vorbisfile.dll             # Vorbis file decoder
        │   ├── wzAudio.dll                # Proprietary audio library
        │   ├── Translations/              # i18n: 9 locales × 3 domains
        │   │   ├── en/                    # English (game.json, editor.json, metadata.json)
        │   │   ├── de/                    # German
        │   │   ├── es/                    # Spanish
        │   │   ├── pt/                    # Portuguese
        │   │   ├── ru/                    # Russian
        │   │   ├── pl/                    # Polish
        │   │   ├── uk/                    # Ukrainian
        │   │   ├── id/                    # Indonesian
        │   │   └── tl/                    # Tagalog
        │   └── Data/                      # Game assets (13,169 files)
        │       ├── Interface/             # UI textures (638 files)
        │       ├── Item/                  # Item models & textures
        │       ├── Monster/               # Monster models
        │       ├── NPC/                   # NPC models
        │       ├── Effect/                # Particle effects
        │       ├── Logo/                  # Loading/title screens
        │       ├── Local/                 # Localized assets
        │       ├── InGameShop*/           # Cash shop assets & scripts
        │       ├── World1..World82/       # 47 world/map directories
        │       ├── Object1..Object82/     # 46 object set directories
        │       ├── Enc1.dat, Dec2.dat     # Encryption/decryption data
        │       ├── gate.bmd               # Gate model
        │       └── Macro.txt              # Macro configuration
        │
        ├── dependencies/                  # Pre-built libraries
        │   ├── include/                   # Headers: GL, GLEW, JPEG, wzAudio
        │   │   ├── gl/                    # OpenGL + GLEW headers
        │   │   ├── turbojpeg.h            # libjpeg-turbo API
        │   │   └── wzAudio.h              # Proprietary audio API
        │   ├── lib/                       # Static libraries
        │   │   ├── x86/                   # 32-bit: turbojpeg-static.lib, wzAudio.lib
        │   │   ├── x64/                   # 64-bit: turbojpeg-static.lib
        │   │   └── wzAudio.lib            # Fallback wzAudio
        │   └── netcore/includes/          # .NET hosting: coreclr_delegates.h
        │
        ├── ThirdParty/
        │   └── imgui/                     # ImGui (git submodule, debug builds only)
        │
        ├── MuEditor/                      # ★ Part 4: In-Game Debug Editor
        │   ├── README.md                  # Editor documentation
        │   ├── Core/                      # Editor lifecycle + input blocking
        │   │   ├── MuEditorCore.cpp/h     # Singleton editor, Initialize/Update/Render
        │   │   └── MuInputBlockerCore.cpp/h  # Block game input over ImGui
        │   ├── Config/
        │   │   └── MuEditorConfig.cpp/h   # Editor settings persistence
        │   └── UI/
        │       ├── Common/                # Toolbar + center pane
        │       ├── Console/               # Dual-panel console (editor + game)
        │       ├── ItemEditor/            # Live item attribute editor (7 files)
        │       └── SkillEditor/           # Skill tree editor (7 files)
        │
        └── source/                        # ★ Game client source (691 files)
            │                              # 325 .cpp + 366 .h files
            │
            ├── Winmain.cpp                # ⭐ ENTRY: WinMain, MuMain(), MainLoop()
            ├── Winmain.h                  # Global handles, defines, externs
            ├── stdafx.h                   # Precompiled header: Win32, OpenGL, STL
            ├── resource.rc                # Windows resource file
            │
            ├── _define.h                  # Core game constants & limits
            ├── _enum.h                    # Core enumerations (items, skills, classes)
            ├── _types.h                   # Type aliases and forward declarations
            ├── _struct.h                  # Core structures: CHARACTER, OBJECT, ITEM
            ├── _crypt.h                   # Encryption utilities
            ├── _TextureIndex.h            # Bitmap/texture enum indexing (30000+)
            ├── _GlobalFunctions.h/cpp     # Buff system macros (80+), color utils
            ├── Defined_Global.h           # Feature flags (#define toggles)
            ├── MultiLanguage.h/cpp        # Legacy multi-language support
            │
            ├── Scenes/                    # Scene management (16 files)
            │   ├── SceneManager.h/cpp     # FrameTimingState, scene orchestration
            │   ├── SceneCore.h/cpp        # Base scene functionality
            │   ├── SceneCommon.h/cpp      # Shared scene utilities
            │   ├── MainScene.h/cpp        # In-game gameplay
            │   ├── LoginScene.h/cpp       # Authentication flow
            │   ├── CharacterScene.h/cpp   # Character select/create
            │   ├── LoadingScene.h/cpp     # Loading screen
            │   └── WebzenScene.h/cpp      # Publisher intro
            │
            ├── Dotnet/                    # C++/.NET interop (13 files)
            │   ├── Connection.h/cpp       # dlopen/.NET AOT bridge
            │   ├── PacketBindings_*.h     # ⚡ GENERATED: C++ packet structures
            │   └── PacketFunctions_*.h/cpp # ⚡ GENERATED: C++ packet handlers
            │
            ├── GameConfig/                # Configuration system (3 files)
            │   ├── GameConfig.h/cpp       # INI read/write, credential encryption
            │   └── GameConfigConstants.h  # Default values, section/key names
            │
            ├── Translation/               # i18n system (2 files)
            │   ├── i18n.h                 # Translator singleton, GAME_TEXT() macro
            │   └── i18n.cpp               # JSON parser, domain maps, formatting
            │
            ├── Camera/                    # Camera system (2 files)
            │   └── CameraUtility.h/cpp    # View matrix, vector operations
            │
            ├── Math/                      # Math library (2 files)
            │   └── ZzzMathLib.h/cpp       # Vectors, matrices, quaternions, lerp
            │
            ├── Time/                      # Timing utilities (4 files)
            │   ├── Timer.h/cpp            # chrono-based precision timer
            │   └── CTimCheck.h/cpp        # Delay-based timer checks
            │
            ├── Utilities/                 # Shared utilities (7 files)
            │   ├── StringUtils.h          # UTF-16 ↔ UTF-8 conversion
            │   ├── Debouncer.h            # Debounce template
            │   ├── CpuUsage.h/cpp         # CPU usage monitoring
            │   └── Log/                   # Logging subsystem
            │       ├── muConsoleDebug.h/cpp     # Debug console
            │       ├── ErrorReport.h/cpp        # Error file logging
            │       └── WindowsConsole.h/cpp     # Win32 console management
            │
            ├── GameShop/                  # In-game shop system (28 files)
            │   ├── InGameShopSystem.h/cpp # Shop manager
            │   ├── NewUIInGameShop.h/cpp  # Shop UI window
            │   ├── MsgBoxIGS*.h/cpp       # Shop message dialogs (6 types)
            │   ├── FileDownloader/        # Asset download subsystem
            │   └── ShopListManager/       # Shop inventory management
            │
            ├── Guild/                     # Guild system (13 files)
            │   ├── NewUIGuildInfoWindow.h/cpp    # Guild info display
            │   ├── NewUIGuildMakeWindow.h/cpp    # Guild creation
            │   ├── UIGuildInfo.h/cpp             # Guild data management
            │   ├── UIGuildMaster.h/cpp           # Guild master functions
            │   └── GuildCache.h/cpp              # Guild data caching
            │
            ├── MUHelper/                  # Auto-play helper (4 files)
            │   ├── MuHelper.h/cpp         # Helper logic (auto-farm, auto-level)
            │   └── MuHelperData.h/cpp     # Helper configuration
            │
            ├── DataHandler/               # Data persistence (11 files)
            │   ├── CommonDataSaver.h/cpp/inl  # Generic data serialization
            │   ├── DataFileIO.h/cpp       # File I/O utilities
            │   ├── ChangeTracker.h        # Data change tracking
            │   ├── FieldMetadata.h        # Field metadata system
            │   ├── ItemData/              # Item data handlers
            │   └── SkillData/             # Skill data handlers
            │
            ├── GameData/                  # Game data definitions
            │   ├── Common/                # Common game data structures
            │   ├── ItemData/              # Item attribute definitions
            │   └── SkillData/             # Skill attribute definitions
            │
            ├── ExternalObject/            # External game objects
            │   └── Leaf/                  # Decorative/environmental objects
            │
            ├── Global Release/            # Release-specific files
            │
            ├── [Root-level source files]  # ~460 files (core game systems)
            │   │
            │   ├── ── Rendering ──
            │   ├── ZzzOpenglUtil.h/cpp    # ⭐ OpenGL core: init, camera, blend modes
            │   ├── ZzzBMD.h/cpp           # ⭐ BMD model format: load, animate, render
            │   ├── ZzzLodTerrain.h/cpp    # Terrain LOD rendering
            │   ├── ZzzObject.h/cpp        # Object management & rendering (10,852 lines)
            │   ├── CSWaterTerrain.h/cpp   # Water rendering effects
            │   ├── Sprite.h/cpp           # 2D sprite rendering
            │   ├── ShadowVolume.h/cpp     # Stencil shadow volumes
            │   ├── SideHair.h/cpp         # Character hair rendering
            │   │
            │   ├── ── Effects ──
            │   ├── ZzzEffectJoint.h/cpp   # Trail/joint effects
            │   ├── ZzzEffectBlurSpark.h/cpp # Blur and spark effects
            │   ├── ZzzEffectMagicSkill.h/cpp # Magic skill VFX
            │   │
            │   ├── ── UI System (84 CNewUI* classes) ──
            │   ├── NewUISystem.h/cpp      # UI manager singleton
            │   ├── NewUI3DRenderMng.h     # 3D rendering in UI
            │   ├── NewUIMyInventory.h/cpp  # Player inventory
            │   ├── NewUICharacterInfoWindow.h/cpp # Character stats
            │   ├── NewUIChatLogWindow.h/cpp # Chat log display
            │   ├── NewUISkillList.h/cpp   # Skill tree UI
            │   ├── NewUIMiniMap.h/cpp      # Minimap
            │   ├── NewUIOptionWindow.h/cpp # Options/settings
            │   ├── NewUIMainFrameWindow.h/cpp # Main HUD frame
            │   ├── NewUICommonMessageBox.h/cpp # Dialog boxes
            │   ├── [... 70+ more NewUI*.h/cpp files]
            │   │
            │   ├── ── Character & Combat ──
            │   ├── CharacterManager.h/cpp # Character class/skill utilities
            │   ├── BoneManager.h/cpp      # Skeletal animation
            │   ├── CameraMove.h/cpp       # Camera movement
            │   ├── PhysicsManager.h/cpp   # Physics calculations
            │   │
            │   ├── ── Audio ──
            │   ├── DSplaysound.h/cpp      # DirectSound wrapper
            │   ├── DSwaveIO.h/cpp         # WAV file I/O (MMIO)
            │   │
            │   ├── ── Events & Maps ──
            │   ├── CSChaosCastle.h/cpp    # Chaos Castle event
            │   ├── CSEventMatch.h/cpp     # Event matching
            │   ├── CKANTURUDirection.h/cpp # Kanturu event
            │   └── [... many more game-specific systems]
```

## Critical Folders Summary

| Folder | Purpose | Files | Criticality |
|--------|---------|-------|-------------|
| `src/source/` | Core game client source | 691 | **Critical** — all game logic |
| `src/source/Scenes/` | Scene state machine | 16 | **Critical** — game flow control |
| `src/source/Dotnet/` | .NET packet interop | 13 | **Critical** — network layer |
| `src/source/GameConfig/` | Settings persistence | 3 | **High** — user preferences |
| `src/source/Translation/` | i18n system | 2 | **High** — localization |
| `src/MuEditor/` | Debug editor (ImGui) | 34 | **Medium** — debug only |
| `src/bin/Data/` | Game assets | 13,169 | **Critical** — all game content |
| `src/bin/Translations/` | Locale files | 27 | **High** — 9 languages |
| `src/dependencies/` | Pre-built libraries | ~20 | **High** — build dependencies |
| `ClientLibrary/` | .NET network library | 14 | **Critical** — server connectivity |
| `ConstantsReplacer/` | Code gen tool | 10 | **Medium** — dev tooling |

## Entry Points

| Entry Point | File | Purpose |
|------------|------|---------|
| `WinMain()` | `src/source/Winmain.cpp` | Windows GUI entry → calls `MuMain()` |
| `MainLoop()` | `src/source/Winmain.cpp` | Game loop: message pump + render |
| `RenderScene()` | `src/source/Scenes/SceneManager.cpp` | Per-frame scene rendering |
| `MuEditorCore::Initialize()` | `src/MuEditor/Core/MuEditorCore.cpp` | Editor bootstrap (debug) |
| `ConnectionManager` | `ClientLibrary/ConnectionManager.cs` | .NET network entry |

## Integration Points

| From | To | Mechanism |
|------|----|-----------|
| MuMain (C++) | ClientLibrary (.NET) | Native AOT DLL via `coreclr_delegates.h` |
| ClientLibrary | MuMain | Packet function callbacks (C++ delegates) |
| ConstantsReplacer | ClientLibrary + MuMain | XSLT code generation (XML → C++/C#) |
| MuEditor | MuMain | Direct memory access (same process, `#ifdef _EDITOR`) |
| CI (GitHub Actions) | MuMain | MinGW-w64 cross-compile on Ubuntu |
