# Implementation Recipes

> Step-by-step recipes for common MuMain feature implementation tasks. Each recipe lists exact files to create/modify, registration points, and verification steps.
>
> **Usage:** Load only the recipe relevant to your task (~80-120 lines each).

## Section Navigation

| Recipe | Lines | Task |
|--------|-------|------|
| [§1 Add a New UI Window](#1-add-a-new-ui-window) | ~120 | New `CNewUI*` class, enum ID, NewUISystem registration |
| [§2 Add a New Packet](#2-add-a-new-packet) | ~120 | XML definition, XSLT generation, C++ send/receive |
| [§3 Add a New Game Manager](#3-add-a-new-game-manager) | ~100 | Singleton, lifecycle, game loop integration |
| [§4 Add a New Item Type](#4-add-a-new-item-type) | ~100 | Data handler, models, textures, UI display |
| [§5 Add a New Map/World](#5-add-a-new-mapworld) | ~100 | `ENUM_WORLD`, terrain data, objects, audio, NPCs |
| [§6 Add a New Feature Flag](#6-add-a-new-feature-flag) | ~70 | `Defined_Global.h`, guarding, sub-flag hierarchy |
| [§7 Add a New Scene](#7-add-a-new-scene) | ~80 | Scene function, `EGameScene` enum, SceneManager dispatch |

---

## §1 Add a New UI Window

### Overview

Create a new UI window class inheriting from `CNewUIObj`, register it with `NewUISystem`, and wire up lifecycle and input handling.

### Files to Create

**`MuMain/src/source/NewUIMyFeature.h`**
```cpp
#pragma once

#include "NewUIBase.h"

namespace SEASON3B
{
    class CNewUIManager;

    class CNewUIMyFeature : public CNewUIObj
    {
    public:
        CNewUIMyFeature();
        virtual ~CNewUIMyFeature();

        bool Create(CNewUIManager* pNewUIMng, int x, int y);
        void Release();

        void SetPos(int x, int y);

        bool UpdateMouseEvent() override;
        bool UpdateKeyEvent() override;
        bool Update() override;
        bool Render() override;

        float GetLayerDepth() override;   // See depth reference below

    private:
        void LoadImages();
        void UnloadImages();

        CNewUIManager* m_pNewUIMng = nullptr;
        POINT m_Pos = {};
    };
}
```

**`MuMain/src/source/NewUIMyFeature.cpp`**
```cpp
#include "stdafx.h"
#include "NewUIMyFeature.h"
#include "NewUIManager.h"
#include "NewUISystem.h"

using namespace SEASON3B;

CNewUIMyFeature::CNewUIMyFeature() = default;
CNewUIMyFeature::~CNewUIMyFeature() { Release(); }

bool CNewUIMyFeature::Create(CNewUIManager* pNewUIMng, int x, int y)
{
    if (!pNewUIMng) return false;
    m_pNewUIMng = pNewUIMng;
    m_pNewUIMng->AddUIObj(INTERFACE_MYFEATURE, this);
    SetPos(x, y);
    LoadImages();
    Show(false);
    return true;
}

void CNewUIMyFeature::Release()
{
    UnloadImages();
    if (m_pNewUIMng) {
        m_pNewUIMng->RemoveUIObj(this);
        m_pNewUIMng = nullptr;
    }
}

// Implement remaining methods: SetPos, Update, UpdateMouseEvent,
// UpdateKeyEvent, Render, LoadImages, UnloadImages, GetLayerDepth
```

### Files to Modify (5 touch points)

#### 1. `_enum.h` — Add interface enum (~line 112)

Add before `INTERFACE_END` (line 113):
```cpp
INTERFACE_MYFEATURE,           // Add before INTERFACE_END
INTERFACE_END,                 // Line 113 — do NOT move this
```
> `INTERFACE_COUNT` auto-calculates from `INTERFACE_END`.

#### 2. `NewUISystem.h` — Include, member, getter, macro

**Include** (lines 6-85 region):
```cpp
#include "NewUIMyFeature.h"
```

**Member pointer** (private section, after ~line 218):
```cpp
CNewUIMyFeature* m_pNewMyFeature;
```

**Getter declaration** (public section, after ~line 293):
```cpp
CNewUIMyFeature* GetUI_NewMyFeature() const;
```

**Convenience macro** (after ~line 383):
```cpp
#define g_pMyFeature SEASON3B::CNewUISystem::GetInstance()->GetUI_NewMyFeature()
```

#### 3. `NewUISystem.cpp` — Create, delete, getter impl

**Constructor** — Initialize to `nullptr`:
```cpp
m_pNewMyFeature = nullptr;
```

**`LoadMainSceneInterface()`** (lines 145-497) — Add near end:
```cpp
m_pNewMyFeature = new CNewUIMyFeature;
if (m_pNewMyFeature->Create(m_pNewUIMng, 640, 480) == false)
    return false;
```

**`UnloadMainSceneInterface()`** (lines 499-548) — Add deletion:
```cpp
SAFE_DELETE(m_pNewMyFeature);
```

**Getter implementation**:
```cpp
CNewUIMyFeature* CNewUISystem::GetUI_NewMyFeature() const
{
    return m_pNewMyFeature;
}
```

#### 4. `_TextureIndex.h` — Add bitmap indices (if needed)

Allocate in `BITMAP_INTERFACE_TEXTURE_BEGIN` (31001) to `BITMAP_INTERFACE_TEXTURE_END` (32000) range:
```cpp
BITMAP_MYFEATURE_BEGIN,
BITMAP_MYFEATURE_END = BITMAP_MYFEATURE_BEGIN + 5,  // Adjust count as needed
```

#### 5. `CMakeLists.txt` — Add source files (if not using glob)

### Layer Depth Reference

| Depth | Window Type | Examples |
|-------|-------------|---------|
| 0.95f | Background HUD | BuffWindow |
| 1.2f | Timed overlays | BloodCastleTime |
| 2.1-3.5f | Secondary windows | Trade, NPCDialogue, MixInventory |
| 4.0-5.0f | Standard windows | GensRanking (4.2f), CastleWindow (5.0f) |
| 5.3-6.0f | Foreground windows | FriendWindow (6.0f) |
| 6.6f+ | Tooltips | SetItemExplanation |
| 10.7f | Modal dialogs | MessageBox |

### Template Reference

Use `NewUIGensRanking.h/.cpp` as a minimal template — it implements all required methods with standard patterns for scrollbar, text box, and button rendering.

### Verification

1. Build compiles without errors
2. `g_pNewUISystem->Show(INTERFACE_MYFEATURE)` opens the window
3. Window renders at correct position and depth
4. Mouse/keyboard events are handled when window is visible
5. No memory leaks — `SAFE_DELETE` in unload path

---

## §2 Add a New Packet

### Overview

Packets are split into SEND (client→server, generated from XML) and RECEIVE (server→client, hand-written in `WSclient.cpp`).

### SEND: Generated Packet (Client-to-Server)

The send pipeline is fully auto-generated from XML packet definitions via XSLT.

**Source:** NuGet package `MUnique.OpenMU.Network.Packets` v0.9.8 provides XML definitions.

**Generation pipeline** (4 XSLT transforms in `ClientLibrary/`):

| XSLT File | Output | Purpose |
|-----------|--------|---------|
| `GenerateBindingsHeader.xslt` | `PacketBindings_*.h` | `typedef` + `symLoad` function pointers |
| `GenerateFunctionsHeader.xslt` | `PacketFunctions_*.h` | Class with `Send*()` method declarations |
| `GenerateFunctions.xslt` | `PacketFunctions_*.cpp` | `Send*()` method implementations |
| `GenerateExtensionsDotNet.xslt` | `ConnectionManager.*Functions.cs` | `[UnmanagedCallersOnly]` exports |
| `Common.xslt` | *(included by all above)* | Type mappings (C++ ↔ C# ↔ P/Invoke) |

**Call pattern:**
```cpp
// Global: Connection* SocketClient (WSclient.cpp:111)
SocketClient->ToGameServer()->SendYourPacket(args);   // Game server
SocketClient->ToChatServer()->SendYourPacket(args);    // Chat server
SocketClient->ToConnectServer()->SendYourPacket(args); // Connect server
```

**Bridge:** `Dotnet/Connection.h` (lines 52-81) — holds 3 `PacketFunctions_*` members, one per server type.

> **DO NOT** hand-edit files in `MuMain/src/source/Dotnet/PacketBindings_*.h`, `PacketFunctions_*.h/.cpp` — these are auto-generated.

### SEND: Custom Packet (Non-Generated)

For packets not in the XML definitions, use the custom pattern:

**Files to modify:**
- `Dotnet/PacketFunctions_Custom.h` — Add method declaration to `PacketFunctions_ClientToServer_Custom`
- `Dotnet/PacketFunctions_Custom.cpp` — Add `typedef`, `symLoad`, and implementation
- `ClientLibrary/ConnectionManager.ClientToServer.Custom.cs` — Add `[UnmanagedCallersOnly]` export

**Pattern** (from `PacketFunctions_Custom.cpp`):
```cpp
// 1. typedef with CoreCLR calling convention
typedef void(CORECLR_DELEGATE_CALLTYPE* SendMyPacket)(int32_t, const wchar_t*);

// 2. Load from .NET library
inline SendMyPacket dotnet_SendMyPacket = reinterpret_cast<SendMyPacket>(
    symLoad(munique_client_library_handle, "ConnectionManager_SendMyPacket"));

// 3. Implement wrapper
void PacketFunctions_ClientToServer_Custom::SendMyPacket(const wchar_t* param)
{
    dotnet_SendMyPacket(this->GetHandle(), param);
}
```

### RECEIVE: Server-to-Client Packet

**Files to modify:**

#### 1. `WSclient.cpp` — Add handler function

Write a handler anywhere in the file (15,156 lines total):
```cpp
void ReceiveMyFeature(const BYTE* ReceiveBuffer)
{
    auto Data = (LPMYFEATURE_PACKET)ReceiveBuffer;
    // Parse buffer, update game state
    // Trigger UI: g_pNewUISystem->Show(INTERFACE_MYFEATURE);
}
```

#### 2. `WSclient.cpp` — Register in `ProcessPacket()` switch

`ProcessPacket()` starts at line 12761. The primary switch on `HeadCode` is at line 12775:

```cpp
switch (HeadCode)  // Line 12775
{
    // For simple packet (no subcode):
    case 0xYY:
        ReceiveMyFeature(ReceiveBuffer);
        break;

    // For packet with subcodes (like 0xF1):
    case 0xF1:
    {
        auto Data = (LPPHEADER_DEFAULT_SUBCODE)ReceiveBuffer;
        switch (Data->SubCode)
        {
            case 0xZZ:
                ReceiveMySubFeature(ReceiveBuffer);
                break;
        }
        break;
    }
}
```

**Packet framing:** C1/C3 packets use `ReceiveBuffer[2]` as HeadCode; C2/C4 use `ReceiveBuffer[3]`.

### Verification

1. **Send:** Call `SocketClient->ToGameServer()->SendYourPacket()` — verify packet appears in network trace
2. **Receive:** Server sends packet — verify `ProcessPacket()` dispatches to your handler
3. **Custom:** `.NET` export matches C++ typedef signature exactly (parameter count and types)

---

## §3 Add a New Game Manager

### Overview

Create a singleton manager with lifecycle methods, integrate into the main game loop.

### Files to Create

**`MuMain/src/source/MyFeatureManager.h`**
```cpp
#pragma once

namespace SEASON3B
{
    class CMyFeatureManager
    {
    protected:
        CMyFeatureManager();

    public:
        virtual ~CMyFeatureManager();

        static CMyFeatureManager* GetInstance();

        void Create();
        void Release();
        void Update();
        void Render();  // Only if visual output needed

    private:
        static CMyFeatureManager* m_pInstance;
        // Add member variables here
    };
}

#define g_pMyFeatureManager SEASON3B::CMyFeatureManager::GetInstance()
```

**`MuMain/src/source/MyFeatureManager.cpp`**
```cpp
#include "stdafx.h"
#include "MyFeatureManager.h"

using namespace SEASON3B;

CMyFeatureManager* CMyFeatureManager::m_pInstance = nullptr;

CMyFeatureManager::CMyFeatureManager() = default;
CMyFeatureManager::~CMyFeatureManager() = default;

CMyFeatureManager* CMyFeatureManager::GetInstance()
{
    if (!m_pInstance)
        m_pInstance = new CMyFeatureManager();
    return m_pInstance;
}

void CMyFeatureManager::Create() { /* Initialize state */ }
void CMyFeatureManager::Release() { /* Cleanup */ }
void CMyFeatureManager::Update() { /* Per-frame logic */ }
void CMyFeatureManager::Render() { /* Visual output if needed */ }
```

### Alternative Patterns

| Pattern | File | Use When |
|---------|------|----------|
| Protected ctor + static `GetInstance()` | `PartyManager.h` | Standard singleton (most common) |
| `Singleton<T>` template | `Singleton.h` | Template-based, `GetSingletonPtr()` / `GetSingleton()` |
| `SmartPointer()` + `Make()` factory | `w_BuffStateSystem.h` | Smart pointer lifecycle, automatic cleanup |

### Game Loop Integration

**File:** `Scenes/MainScene.cpp`

#### `InitializeMainScene()` (lines 101-154)
```cpp
g_pMyFeatureManager->Create();
```

#### `UpdateUIAndInput()` (lines 189-220)
```cpp
g_pMyFeatureManager->Update();
```

#### `RenderMainSceneUI()` (lines 498-527) — if rendering needed
```cpp
g_pMyFeatureManager->Render();
```

### Verification

1. `GetInstance()` returns same pointer on repeated calls
2. `Create()` initializes state correctly
3. `Update()` called every frame in main scene
4. `Release()` cleans up without leaks
5. No crashes if manager methods called before `Create()`

---

## §4 Add a New Item Type

### Overview

Items require data definition, model/texture loading, and inventory display integration.

### Step 1: Item Data Definition

**Item attributes:** `GameData/ItemData/ItemStructs.h` defines `ITEM_ATTRIBUTE` struct with wide-char name (`wchar_t Name[50]`) plus attribute fields via `ITEM_ATTRIBUTE_FIELDS` X-macro.

**Data handler:** `DataHandler/ItemData/ItemDataHandler.h` — singleton `CItemDataHandler`:
```cpp
CItemDataHandler& handler = CItemDataHandler::GetInstance();
handler.Load(fileName);                        // Load encrypted .bmd file
ITEM_ATTRIBUTE* attr = handler.GetItemAttribute(index);
```

**Encrypted data files:** `.bmd` format loaded by `ItemDataLoader::Load()`. Editor builds (`_EDITOR`) support `Save()`, `ExportAsS6E3()`, `ExportToCsv()`.

### Step 2: Model Loading

**File:** `ZzzOpenData.cpp`, function `OpenItems()` (lines 611-1248)

```cpp
// Batch loading pattern (e.g., swords):
for (int i = 0; i < 17; i++)
    gLoadData.AccessModel(MODEL_SWORD + i, L"Data\\Item\\", L"Sword", i + 1);

// Individual special item:
gLoadData.AccessModel(MODEL_MY_ITEM, L"Data\\Item\\", L"MyItem", 1);
```

### Step 3: Texture Loading

**File:** `ZzzOpenData.cpp`, function `OpenItemTextures()` (lines 1250-1348)

```cpp
gLoadData.OpenTexture(MODEL_MY_ITEM, L"Item\\");
```

### Step 4: Texture Index

**File:** `_TextureIndex.h` — Add model constant. Item models use `MODEL_*` constants defined in the model enum sections.

### Step 5: Inventory Display

**File:** `NewUIMyInventory.cpp` — Uses `CNewUIInventoryCtrl` with an **8x8 cell grid** (line 70):
```cpp
m_pNewInventoryCtrl->Create(STORAGE_TYPE::INVENTORY, ..., 8, 8, MAX_EQUIPMENT);
```

Items occupy cells based on their width/height attributes. Display logic in `NewUIInventoryCtrl.cpp`.

### Step 6: Item Information

**File:** `ZzzInfomation.cpp` — Contains `GetItemInfo()` and tooltip rendering for item stats.

### Verification

1. Item loads from `.bmd` data file without corruption
2. 3D model renders in inventory slot at correct size
3. Tooltip shows correct name and stats
4. Item can be equipped/used/traded (as applicable)
5. Network serialization matches server expectations

---

## §5 Add a New Map/World

### Overview

Maps require an enum entry, terrain data files, object/texture loading, and audio integration.

### Step 1: World Enum

**File:** `MapManager.h` (lines 7-71)

Add before `NUM_WD` (line 70):
```cpp
enum ENUM_WORLD
{
    WD_0LORENCIA = 0,
    // ... existing maps (WD_0 through WD_81KARUTAN2) ...
    WD_82MYMAP = 82,    // Add your map with explicit value
    NUM_WD              // Line 70 — auto-increments, do NOT move
};
```

> **Naming convention:** `WD_<number><MAPNAME>` (e.g., `WD_82MYMAP`)

### Step 2: Terrain Data

Create directory `MuMain/src/bin/Data/World82/` containing:
- `EncTerrain.map` — Height/terrain data
- `EncTerrain.att` — Attribute data (walkability, safe zones)

### Step 3: Object & Texture Loading

**File:** `MapManager.cpp`, function `Load()` (starts at line 35)

Add a case in the `switch(gMapManager.WorldActive)` statement:
```cpp
case WD_82MYMAP:
    gLoadData.AccessModel(MODEL_MYMAP_OBJECT01, L"Data\\Object82\\", L"MyObject", 1);
    gLoadData.OpenTexture(MODEL_MYMAP_OBJECT01, L"Object82\\");
    // Add more objects as needed
    break;
```

### Step 4: Audio Integration

**File:** `Scenes/SceneManager.cpp`

**Ambient sounds** in `PlayWorldAmbientSounds()` (lines 564-622):
```cpp
case WD_82MYMAP:
    PlayBuffer(SOUND_WIND01, NULL, true);
    break;
```

**Background music** in `ManageBackgroundMusic()` (lines 711-770):
```cpp
if (gMapManager.WorldActive == WD_82MYMAP)
{
    if (Hero->SafeZone)
        PlayMp3(MUSIC_MY_MAP_THEME);
}
```

**Clear color** in `SetWorldClearColor()` (lines 332-373):
```cpp
else if (gMapManager.WorldActive == WD_82MYMAP)
{
    glClearColor(0.1f, 0.2f, 0.3f, 1.0f);
}
```

### Step 5: Map-Specific Logic (Optional)

Create `GM_MyMap.cpp` for map-specific game mechanics (NPCs, events, triggers).

### Step 6: NPC Spawns (Optional)

**File:** `ZzzOpenData.cpp` — Add NPC models and spawn data for the new map.

### Step 7: Feature Flag Guard (Optional)

If the map is conditional, wrap all additions with:
```cpp
#ifdef XXX_ADD_MAP_MYMAP
// ... map-specific code ...
#endif
```

### Verification

1. Map loads terrain data without crashes
2. Objects render at correct positions
3. Walkability/attribute data works (collision, safe zones)
4. Ambient sounds and music play correctly
5. Map transitions to/from the new map work
6. NPCs spawn and are interactable (if added)

---

## §6 Add a New Feature Flag

### Overview

Feature flags use preprocessor defines in `Defined_Global.h` with author-prefixed naming.

### Step 1: Define the Flag

**File:** `Defined_Global.h`

```cpp
#define XXX_ADD_FEATURE_NAME    // Author prefix + action + name
```

**Author prefixes:** `ASG_`, `KJH_`, `PBG_`, `PJH_`, `LDK_`

**Action conventions:**
| Prefix | Meaning | Example |
|--------|---------|---------|
| `ADD_` | New feature | `ASG_ADD_GENS_SYSTEM` |
| `MOD_` | Modification to existing | `KJH_MOD_SHOP_SCRIPT_DOWNLOAD` |
| `FIX_` | Bug fix | `KWAK_FIX_ALT_KEYDOWN_MENU_BLOCK` |

### Step 2: Sub-Flag Hierarchy (Optional)

For features with multiple components:
```cpp
#define ASG_ADD_GENS_SYSTEM
#ifdef ASG_ADD_GENS_SYSTEM
    #define ASG_ADD_INFLUENCE_GROUND_EFFECT
    #define ASG_ADD_GENS_MARK
    #define PBG_ADD_GENSRANKING
    #define PBG_MOD_STRIFE_GENSMARKRENDER
#endif
```

**Disable convention:** Comment with `//^` prefix to indicate intentionally disabled:
```cpp
//^#define PBG_ADD_CHARACTERSLOT    // Disabled: not ready for release
```

### Step 3: Guard Code

**In headers (`NewUISystem.h`):**
```cpp
#ifdef XXX_ADD_FEATURE_NAME
#include "NewUIMyFeature.h"
#endif

// In class declaration:
#ifdef XXX_ADD_FEATURE_NAME
    CNewUIMyFeature* m_pNewMyFeature;
#endif
```

**In implementation (`NewUISystem.cpp`):**
```cpp
#ifdef XXX_ADD_FEATURE_NAME
    m_pNewMyFeature = new CNewUIMyFeature;
    if (m_pNewMyFeature->Create(m_pNewUIMng, 640, 480) == false)
        return false;
#endif
```

### Step 4: Document Impact

Add a comment near the define indicating scope:
```cpp
#define XXX_ADD_FEATURE_NAME    // Affects: NewUISystem, WSclient, MyFeatureManager (3 files)
```

### Verification

1. Feature compiles when flag is defined
2. Feature compiles when flag is NOT defined (no dangling references)
3. Sub-flags are properly nested under parent `#ifdef`
4. No orphaned `#endif` or mismatched guards
5. Build passes in both configurations

---

## §7 Add a New Scene

### Overview

Scenes are function-based (not class-based). Each scene has Create/Move/Render functions dispatched by `SceneManager`.

### Step 1: Scene Functions

**Create `Scenes/MyScene.h`:**
```cpp
#pragma once

void CreateMyScene();
void MoveMyScene();       // "Move" = update logic (legacy naming)
bool RenderMyScene();
void ReleaseMyScene();
```

**Create `Scenes/MyScene.cpp`:**
```cpp
#include "stdafx.h"
#include "MyScene.h"
#include "Scenes/SceneCommon.h"

void CreateMyScene()
{
    // Load scene-specific data, initialize state
}

void MoveMyScene()
{
    // Per-frame update logic
}

bool RenderMyScene()
{
    // Render scene content
    return true;
}

void ReleaseMyScene()
{
    // Cleanup scene resources
}
```

### Step 2: Scene Enum

**File:** `_define.h` (lines 24-31)

```cpp
enum EGameScene {
    SERVER_LIST_SCENE = 0,
    WEBZEN_SCENE = 1,
    LOG_IN_SCENE = 2,
    LOADING_SCENE = 3,
    CHARACTER_SCENE = 4,
    MAIN_SCENE = 5,
    MY_SCENE = 6,          // Add new scene
};
```

### Step 3: Initialization State

**File:** `Scenes/SceneCommon.h` (lines 58-91)

Add to `SceneInitializationState`:
```cpp
private:
    bool initMyScene = false;
public:
    bool& GetInitMyScene() { return initMyScene; }
```

Update `ResetAll()` and `ResetForDisconnect()` to reset the new flag.

### Step 4: Scene Dispatch

**File:** `Scenes/SceneManager.cpp`

**`UpdateActiveScene()`** (lines 253-269) — Add case:
```cpp
case MY_SCENE:
    MoveMyScene();
    break;
```

**`RenderCurrentScene()`** (lines 381-400) — Add branch:
```cpp
else if (SceneFlag == MY_SCENE)
{
    Success = RenderMyScene();
}
```

### Step 5: Scene Transition

To switch to the new scene from anywhere:
```cpp
#include "Scenes/SceneCore.h"
SceneFlag = MY_SCENE;  // extern EGameScene SceneFlag (SceneCore.h:13)
```

### Step 6: Data Loading (Optional)

**File:** `ZzzOpenData.h/.cpp` — Add `OpenMySceneData()` / `ReleaseMySceneData()` for scene-specific assets.

### Verification

1. `SceneFlag = MY_SCENE` transitions to the new scene
2. `MoveMyScene()` called every frame while scene is active
3. `RenderMyScene()` renders correctly
4. Transitioning away from the scene cleans up properly
5. Initialization state flag prevents double-init

---

## Cross-Reference: Common File Touch Points

| File | Recipes That Touch It |
|------|-----------------------|
| `_enum.h` | §1 (UI enum) |
| `_define.h` | §7 (scene enum) |
| `_TextureIndex.h` | §1, §4 (bitmap indices) |
| `NewUISystem.h/.cpp` | §1, §6 (UI registration, feature guards) |
| `Defined_Global.h` | §5, §6 (feature flags) |
| `Scenes/SceneManager.cpp` | §5 (audio), §7 (dispatch) |
| `Scenes/MainScene.cpp` | §3 (manager lifecycle) |
| `ZzzOpenData.cpp` | §4 (items), §5 (maps), §7 (scene data) |
| `WSclient.cpp` | §2 (packet handlers) |
| `MapManager.h/.cpp` | §5 (world enum, loading) |
| `CMakeLists.txt` | §1, §3, §4, §5, §7 (new source files) |
