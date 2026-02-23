# Asset Pipeline Guide

This document describes the asset file formats, directory structure, loading pipeline, and encryption used in the MuMain game client.

---

## Asset File Formats

### 3D Models

| Format | Extension | Description |
|--------|-----------|-------------|
| **BMD** | `.bmd` | Binary Model Data — skeletal animation, mesh data, texture references. Max 200 bones, 50 meshes, 15,000 vertices per mesh. Lightmap support in v1.2+. |

Loaded by `BMD::Open2()` in `ZzzBMD.h`.

### Textures

| Format | Extension | Description |
|--------|-----------|-------------|
| **TGA** | `.tga` | Targa — loaded with GL_NEAREST filtering |
| **JPG** | `.jpg` | JPEG — decoded via libjpeg-turbo 3.1.3, configurable filtering |
| **OZJ** | `.ozj` | Compressed/encrypted texture variant (objects, characters) |
| **OZT** | `.ozt` | Compressed/encrypted texture variant (interface, world) |

Loaded by `CGlobalBitmap::LoadImage()` in `GlobalBitmap.cpp`.

### Terrain

| Format | Extension | Description |
|--------|-----------|-------------|
| **MAP** | `.map` | Terrain height map and mesh data |
| **ATT** | `.att` | Attribute/collision data (walkability grid) |

Loaded per world by `MapProcess::LoadMapData()`.

### Audio

| Format | Extension | Description |
|--------|-----------|-------------|
| **WAV** | `.wav` | PCM audio via DirectSound/DSwaveIO.cpp |
| **OGG** | `.ogg` | Vorbis compressed via ogg.dll + vorbisfile.dll |
| **MP3** | `.mp3` | Streamed via wzAudio.dll (proprietary) |

### Game Data

| Format | Extension | Description |
|--------|-----------|-------------|
| **BMD** (data) | `.bmd` | Binary data files — items, skills, quests, dialogue. Encrypted with per-file checksum keys. |

---

## Directory Structure

```
MuMain/src/bin/
├── config.ini                          # Game configuration
├── Data/
│   ├── Player/                         # Player models & skins
│   │   ├── Player.bmd                  # Base player mesh
│   │   ├── HelmClass*.bmd             # Class-specific equipment
│   │   ├── ArmorClass*.bmd, PantClass*.bmd, BootClass*.bmd, GloveClass*.bmd
│   │   └── skin_*.OZJ, hair_*.OZJ    # Skin/hair textures
│   │
│   ├── Monster/                        # NPC/Monster models (~949 subdirectories)
│   │   └── Monster*.bmd + *.OZJ
│   │
│   ├── Item/                           # Item models & icons (~958 subdirectories)
│   │   └── Sword*.bmd, Axes*.bmd, Staff*.bmd, etc. + *.OZJ
│   │
│   ├── NPC/                            # NPC models (328 subdirectories)
│   │   └── NPC*.bmd + *.OZJ
│   │
│   ├── Object1–Object69/              # World decoration objects
│   │   └── Object*.bmd + *.OZJ, *.OZT
│   │
│   ├── Effect/                         # Spell/skill effect textures (322 dirs)
│   │   └── *.OZJ, *.OZT
│   │
│   ├── Interface/                      # UI textures (~640 subdirectories)
│   │   └── newui_*.tga, newui_*.jpg, *.OZJ, *.OZT
│   │
│   ├── Logo/                           # Splash screens, logos (161 dirs)
│   │
│   ├── Local/                          # Game data & localized content
│   │   ├── ServerList.bmd, Mix.bmd, Filter.bmd, MonsterSkill.bmd
│   │   ├── MasterSkillTreeData.bmd
│   │   └── Eng/, Kor/, etc./          # Language-specific data
│   │       ├── Item_*.bmd, Dialog_*.bmd, Quest_*.bmd
│   │       ├── Skill_*.bmd, ItemTooltip_*.bmd
│   │       └── Minimap/
│   │
│   ├── World1–World82/                 # Per-world terrain data
│   │   ├── Terrain.map, Terrain.att
│   │   └── EncTerrain*.map, EncTerrain*.att  # Encrypted variants
│   │
│   ├── InGameShopBanner/               # Shop promotional content
│   └── InGameShopScript/              # Shop configuration
│
└── Translations/                       # i18n strings (9 locales × 3 domains)
    └── {locale}/game.json, editor.json, metadata.json
```

---

## Loading Pipeline

### Initialization (ZzzOpenData.cpp)

```
OpenPlayers()
├── Allocate Models array: Models = new BMD[MAX_MODELS + 1024]
├── AccessModel(MODEL_PLAYER, "Data\\Player\\", "Player")
├── For each class (6 classes):
│   └── AccessModel for Helm, Armor, Pants, Gloves, Boots
└── OpenTexture() for each model
```

### Model Loading (LoadData.cpp)

```
CLoadData::AccessModel(Type, Dir, FileName, index)
├── Construct path: "Data\\Player\\FileName##.bmd" (zero-padded)
├── BMD::Open2(Dir, Name)
│   ├── Read header (name, version, bone/mesh/action counts)
│   ├── Parse bone array (200 max, parent refs, animation matrices)
│   ├── Parse mesh array (50 max, vertices, normals, UVs, triangles)
│   └── Parse animation actions (keyframe sequences)
└── Error handling: MessageBox on failure for critical models
```

### Texture Loading (LoadData.cpp → GlobalBitmap.cpp)

```
CLoadData::OpenTexture(Model, SubFolder, ...)
├── For each mesh in model:
│   ├── Read texture filename from BMD mesh data
│   ├── Construct path: "Data\\{SubFolder}\\{FileName}"
│   └── CGlobalBitmap::LoadImage(filename, filter, wrapMode)
│       ├── .jpg → OpenJpegTurbo() [libjpeg-turbo]
│       ├── .tga → OpenTga()
│       ├── glGenTextures → glTexImage2D → set filter/wrap
│       └── Cache in BitmapCache, return GLuint handle
└── Error handling: PopUpErrorCheckMsgBox() on missing texture
```

### Texture Script Flags

Texture filenames encode rendering flags via underscore convention:

| Suffix | Meaning |
|--------|---------|
| `_R` | Bright (rendered with glow) |
| `_H` | Hidden mesh (not rendered by default) |
| `_S` | Stream mesh (dynamic/deformable) |
| `_N` | Non-blended mesh |
| `_DC` | Shadow mesh without texture |
| `_DT` | Shadow mesh with texture |

Parsed in `TextureScript.cpp`.

---

## Data File Encryption

### Encryption System (DataFileIO.h/cpp)

```cpp
struct IOConfig {
    int itemSize;
    int itemCount;
    DWORD checksumKey;                            // Per-file type
    std::function<void(BYTE*, int)> encryptRecord; // Per-record encryption
    std::function<void(BYTE*, int)> decryptRecord; // Per-record decryption
};
```

### Checksum Keys

| File Type | Key |
|-----------|-----|
| Item data | `0xE2F1` |
| Skill data | `0x5A18` |

Files are structured as `[encrypted records] + [checksum]`. Verification via `VerifyChecksum()`.

### Encryption in Editor Builds

`EncryptBuffer()` is only available in `_EDITOR` builds for data authoring. Release builds only decrypt.

---

## Texture Index Constants

Managed in `_TextureIndex.h`. Ranges:

| Range | Category |
|-------|----------|
| `0x0001–0x00FE` | Fonts |
| `30255+` | Map tiles (30 textures per set) |
| `30500–31000` | Player textures (skins, hair, robes) |
| `31001–32000` | Interface textures |
| `32001–33000` | Effect textures |

Total: 3,000+ managed texture IDs across 30,000+ indexed slots.

---

## Memory Management

- **Models:** Pre-allocated array with random offset: `Models = ModelsDump + (rand() % 1024)`
- **Textures:** Cached by `CGlobalBitmap` with categorized maps (Main, Player, Interface, Effect)
- **Memory tracking:** `dwUsedTextureMemory` in `CGlobalBitmap`
- **LRU cache:** 15-minute aging cleanup for texture entries

---

## Cross-Platform Considerations

| Asset Issue | Impact | Resolution | Phase |
|-------------|--------|------------|-------|
| `_wfopen` for file access | 60 calls, 28 files | `mu_wfopen` shim with `\` → `/` normalization | 0 / 0.3 |
| Backslash paths in `L"Data\\"` | ~2,050 occurrences | Auto-normalized by `mu_wfopen` | 0 / 0.3 |
| Case-sensitive file paths (Linux) | Asset references may not match case | Case-folding open with directory cache | 0 / 0.3 |
| `.bmd` binary `wchar_t` text fields | 2-byte on Windows, 4-byte on Linux | `ImportChar16ToWchar()` at load sites | 5 / 5.5 |
| DirectSound WAV loading | Win32 MMIO API | miniaudio `ma_sound_init_from_file()` | 3 / 3.1 |
| wzAudio music streaming | Proprietary DLL | miniaudio streaming | 3 / 3.3 |
| OpenGL texture upload | `glGenTextures`/`glTexImage2D` | SDL_gpu texture API | 2 / 2.9 |
| OZJ/OZT decoding | Format-specific decompression | No change needed (platform-independent byte ops) | — |
