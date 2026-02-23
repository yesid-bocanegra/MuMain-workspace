# Game Systems Reference

Map of all major game subsystems in MuMain with entry point files, key classes, and data flow.

For architecture details, see [Architecture: MuMain](architecture-mumain.md). For rendering specifics, see [Rendering Architecture](architecture-rendering.md).

---

## Core Loop & Scene Management

### Game Loop

| Component | File | Purpose |
|-----------|------|---------|
| Entry point | `Winmain.cpp` | `WinMain()` → `MuMain()` → `MainLoop()` |
| Frame timing | `Scenes/SceneManager.h` | `FrameTimingState` — FPS capping, delta time |
| Scene dispatch | `Scenes/SceneManager.cpp` | `RenderScene()` — per-frame scene rendering |

```
MainLoop()
├── Win32 Message Pump (PeekMessage)
├── FrameTimingState (FPS cap)
├── RenderScene()
│   ├── SceneManager → [Current Scene].Update() + .Render()
│   ├── NewUISystem::Render() (89 UI windows)
│   └── SwapBuffers()
├── Audio update
└── MuEditorCore update (_EDITOR builds)
```

### Scene State Machine (6 Scenes)

| Scene | File | Purpose |
|-------|------|---------|
| ServerListScene | `Scenes/ServerListScene.cpp` | Server selection |
| WebzenScene | `Scenes/WebzenScene.cpp` | Publisher splash |
| LoginScene | `Scenes/LoginScene.cpp` | Account login |
| LoadingScene | `Scenes/LoadingScene.cpp` | Asset streaming |
| CharacterScene | `Scenes/CharacterScene.cpp` | Character select/create |
| MainScene | `Scenes/MainScene.cpp` | In-game gameplay |

Flow: `ServerList → Webzen → Login → Loading → Character → Main`

Each scene implements `Create()`, `Update(delta)`, `Render()`.

---

## Global State

Core game state is managed through extern globals:

| Global | File | Type | Purpose |
|--------|------|------|---------|
| `Hero` | `ZzzCharacter.h` | `CHARACTER*` | Player character |
| `CharactersClient` | `ZzzCharacter.h` | `CHARACTER[]` | All visible characters |
| `CharacterAttribute` | `ZzzInfomation.h` | `CHARACTER_ATTRIBUTE*` | Player stats |
| `Inventory[]` | `ZzzInventory.h` | `ITEM[60]` | Player inventory |
| `InventoryExt[]` | `ZzzInventory.h` | `ITEM[60]` | Extended storage |
| `Party[]` | `ZzzInventory.h` | `PARTY_t[MAX_PARTYS]` | Party members |
| `GuildList[]` | `ZzzInventory.h` | `GUILD_LIST_t[MAX_GUILDS]` | Guild data |
| `ObjectArray` | `ZzzObject.h` | `OBJECT[]` | World objects |
| `Effects[]` | `ZzzEffect.h` | `OBJECT[]` | Visual effects |
| `SocketClient` | `WSclient.h` | `Connection*` | Network socket |

**Data flow pattern:**
```
Network → PacketFunctions_*.cpp → Global Arrays → RenderScene() → Draw
User Input → Win32 Handlers → Global Flags → Game Logic
```

---

## Gameplay Systems

### Inventory

| Component | File |
|-----------|------|
| Slot management | `ZzzInventory.h` |
| Main inventory UI | `NewUIMyInventory.h/cpp` |
| Equipment display | `NewUICharacterInfoWindow.h/cpp` |
| NPC storage | `NewUIStorageInventory.h/cpp` |
| Extended slots | `NewUIInventoryExtension.h/cpp` |
| Item sorting | `NewUIItemMng.h/cpp` |
| Mix/combine | `NewUIMixInventory.h/cpp` |

60 main slots + 60 extended slots. Item grid: 20x20px cells.

### Combat & Skills

| Component | File |
|-----------|------|
| Skill validation | `SkillManager.h/cpp` |
| Skill tree UI | `NewUISkillList.h/cpp` |
| Skill VFX | `SkillEffectMgr.h/cpp` |
| Class utilities | `CharacterManager.h/cpp` |
| Physics/collision | `PhysicsManager.h/cpp` |

Skill data: `ActionSkillType` enum, `DemendConditionInfo` for requirements (Str, Dex, Vit, Ene, Cha).

### Buff/Debuff System

| Component | File |
|-----------|------|
| Manager singleton | `w_BuffStateSystem.h/cpp` |
| Script loader | `w_BuffScriptLoader.h/cpp` |
| Duration tracking | `w_BuffTimeControl.h/cpp` |
| Stat modifiers | `w_BuffStateValueControl.h/cpp` |
| Active buffs UI | `NewUIBuffWindow.h/cpp` |

80+ buff macro definitions. Three subsystems: script loading, time control, stat modification.

### Quest System

| Component | File |
|-----------|------|
| Quest state machine | `QuestMng.h/cpp` |
| Quest tracking UI | `NewUIQuestProgress.h/cpp` |
| Quest details | `NewUIMyQuestInfoWindow.h/cpp` |
| NPC quest dialog | `NewUINPCQuest.h/cpp` |
| NPC conversation | `NewUINPCDialogue.h/cpp` |

Quest data: `SQuestProgress`, `SQuestRequest`, `SQuestReward` structs. Maps keyed by quest index.

### Party System

| Component | File |
|-----------|------|
| Party singleton | `PartyManager.h/cpp` |
| Party list UI | `NewUIPartyListWindow.h/cpp` |
| Party info UI | `NewUIPartyInfoWindow.h/cpp` |

Global: `Party[MAX_PARTYS]`, `PartyKey`, `PartyNumber`. Max 6 members.

### Guild System

| Component | File |
|-----------|------|
| Guild data | `Guild/UIGuildInfo.h/cpp` |
| Guild admin | `Guild/UIGuildMaster.h/cpp` |
| Member cache | `Guild/GuildCache.h/cpp` |
| Guild info UI | `Guild/NewUIGuildInfoWindow.h/cpp` |
| Guild creation UI | `Guild/NewUIGuildMakeWindow.h/cpp` |

Global: `GuildList[MAX_GUILDS]`, `GuildMark[MAX_MARKS]`, `g_GuildNotice[3][128]`.

### Trade System

| Component | File |
|-----------|------|
| Player trade UI | `NewUITrade.h/cpp` |
| NPC shop | `NewUINPCShop.h/cpp` |
| Purchase interface | `NewUIPurchaseShopInventory.h/cpp` |
| Personal shop | `NewUIMyShopInventory.h/cpp` |

### In-Game Shop (Cash Shop)

| Component | File |
|-----------|------|
| Shop manager | `GameShop/InGameShopSystem.h/cpp` |
| Shop UI | `GameShop/NewUIInGameShop.h/cpp` |
| Message dialogs | `GameShop/MsgBoxIGS*.h/cpp` (6 types) |
| List manager | `GameShop/ShopListManager/` |
| Asset downloader | `GameShop/FileDownloader/` |

### Pet System

| Component | File |
|-----------|------|
| Pet logic | `w_PetProcess.h/cpp` |
| Pet manager | `GIPetManager.h/cpp` |
| Pet stats UI | `NewUIPetInfoWindow.h/cpp` |

### Auto-Farm Helper

| Component | File |
|-----------|------|
| Helper manager | `MUHelper/MuHelper.h/cpp` |
| Helper config | `MUHelper/MuHelperData.h/cpp` |
| Helper UI | `NewUIMuHelper.h/cpp` |

---

## Map & World System

### Map Manager

| Component | File |
|-----------|------|
| World loading | `MapManager.h/cpp` |
| World enum | `MapManager.h` — `ENUM_WORLD` (82 worlds) |
| Special area checks | `InChaosCastle()`, `InBloodCastle()`, `InDevilSquare()`, etc. |

### World Object Management

| Component | File |
|-----------|------|
| Object system | `ZzzObject.h/cpp` (10,852 lines) |
| Object rendering | `ZzzObject.h/cpp` |
| Object info | `w_ObjectInfo.h` |

Global arrays: `ObjectBlock[256]`, `Mounts[]`, `Boids[]`, `Fishs[]`, `Items[MAX_ITEMS]`.

### Event Maps

| Event | Map IDs | UI Files |
|-------|---------|----------|
| Chaos Castle | `WD_18CHAOS_CASTLE` | `NewUIChaosCastleTime` |
| Blood Castle | `WD_11BLOODCASTLE1–END` | `NewUIBloodCastleEnter`, `NewUIBloodCastleTime` |
| Devil Square | `WD_9DEVILSQUARE` | `NewUIEnterDevilSquare` |
| Kanturu | `WD_37–39KANTURU` | `NewUIKanturuEvent` |
| Cursed Temple | `WD_45CURSEDTEMPLE_LV1–6` | `NewUICursedTemple*` (3 windows) |
| Empire Guardian | Multiple | `NewUIEmpireGuardian*` (2 windows) |
| Cry Wolf | `WD_34CRYWOLF` | `NewUICryWolf` |
| Castle Siege | Multiple | `NewUISeigeWarfare`, `NewUICatapultWindow`, `NewUICastleWindow` |

---

## UI System

### Architecture

- **89 CNewUI* classes** managed by `NewUISystem` singleton
- All inherit from `CNewUIBase`
- Vector-based rendering sorted by layer depth (float: 2.4 → 10.6)
- Map-based management keyed by DWORD ID
- Logical resolution: **640x480** (fixed)
- Standard window size: **190x429px**

### Core Framework

| Component | File | Purpose |
|-----------|------|---------|
| UI system manager | `NewUISystem.h/cpp` | Singleton managing all windows |
| UI base class | `NewUIBase.h` | Abstract base |
| UI manager | `NewUIManager.h/cpp` | Storage, rendering, event dispatch |
| 3D renderer | `NewUI3DRenderMng.h` | Character preview in UI |
| Button widget | `NewUIButton.h` | Standard button |
| Scroll bar | `NewUIScrollBar.h` | Scroll widget |
| Text input | `NewUITextBox.h` | Text input widget |
| Inventory grid | `NewUIInventoryCtrl.h/cpp` | 20x20 grid system |

### Window Categories

| Category | Count | Examples |
|----------|-------|---------|
| HUD & Main | 6 | MainFrameWindow, MiniMap, CommandWindow |
| Character/Stats | 4 | CharacterInfoWindow, MasterLevel, PetInfo |
| Inventory/Trade | 9 | MyInventory, StorageInventory, Trade, MixInventory |
| Chat | 3 | ChatLogWindow, ChatInputBox, FriendWindow |
| Shop/Market | 8+ | NPCShop, InGameShop, MsgBoxIGS* (6 types) |
| Quest/NPC | 5 | QuestProgress, NPCQuest, NPCDialogue |
| Guild/Party | 4 | GuildInfoWindow, PartyListWindow |
| Events | 18 | ChaosCastle, BloodCastle, DevilSquare, Kanturu, CursedTemple, etc. |
| Duel | 6 | DuelWindow, DuelWatch* (4 windows), DoppelGanger |
| Utility/Dialog | 8 | OptionWindow, CommonMessageBox, HelpWindow |
| Ranking/Misc | 5 | GensRanking, LuckyCoin, GoldBowman |

---

## Configuration

| Component | File | Purpose |
|-----------|------|---------|
| Config singleton | `GameConfig/GameConfig.h/cpp` | INI reader/writer |
| Config constants | `GameConfig/GameConfigConstants.h` | Keys, sections, defaults |
| Config file | `src/bin/config.ini` | Runtime settings |

Sections: `[Window]`, `[Graphics]`, `[Audio]`, `[CONNECTION SETTINGS]`.

---

## Data Persistence

| Component | File | Purpose |
|-----------|------|---------|
| Data saver | `DataHandler/CommonDataSaver.h/cpp` | Generic serialization |
| File I/O | `DataHandler/DataFileIO.h/cpp` | Encrypted file read/write |
| Change tracking | `DataHandler/ChangeTracker.h` | Modification tracking |
| Item data | `DataHandler/ItemData/` | Item persistence |
| Skill data | `DataHandler/SkillData/` | Skill persistence |

---

## Key Statistics

| Metric | Count |
|--------|-------|
| CNewUI* classes | 89 |
| Scene types | 6 |
| World maps | 82 |
| System managers | 25+ |
| Buff definitions | 80+ |
| glBegin/glEnd sites | 111 |
| Source files | 691 |
| Texture indices | 30,000+ |
| Game asset files | 13,169 |
| Localization languages | 9 |
| Max inventory slots | 120 (60 + 60 ext) |
| Max party members | 6 |
