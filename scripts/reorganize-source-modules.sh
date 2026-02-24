#!/usr/bin/env bash
###############################################################################
# reorganize-source-modules.sh
#
# Moves all files in MuMain/src/source/ into a modular directory structure.
# Excludes already-placed subdirectories: Scenes/, Dotnet/, GameShop/, Translation/
#
# Usage:
#   cd <repo-root>           # MuMain-workspace/
#   bash scripts/reorganize-source-modules.sh
#
# Prerequisites:
#   - Clean git working tree (commit or stash first)
#   - Run from the repository root (MuMain-workspace/)
#
# Total files moved: ~589 files across 18 target modules
###############################################################################
set -euo pipefail

# Must run from MuMain-workspace root
cd "$(dirname "$0")/.."

SRC="MuMain/src/source"

# gmv must operate within the MuMain submodule
gmv() {
  git -C MuMain mv "${1#MuMain/}" "${2#MuMain/}"
}

###############################################################################
# 1. Create target module directories
###############################################################################
echo "=== Creating module directories ==="

mkdir -p "$SRC/Main"
mkdir -p "$SRC/Core"
mkdir -p "$SRC/Protocol"
mkdir -p "$SRC/Network"
mkdir -p "$SRC/Data"
mkdir -p "$SRC/World"
mkdir -p "$SRC/Gameplay"
mkdir -p "$SRC/UI/Framework"
mkdir -p "$SRC/UI/Windows"
mkdir -p "$SRC/UI/Events"
mkdir -p "$SRC/UI/Legacy"
mkdir -p "$SRC/Audio"
mkdir -p "$SRC/RenderFX"
mkdir -p "$SRC/ThirdParty"
mkdir -p "$SRC/Resources/Windows"
mkdir -p "$SRC/Platform"

# Note: Scenes/, Dotnet/, GameShop/, Translation/ already exist and stay in place.
# Note: Camera/, Math/, Time/, Utilities/, Guild/, DataHandler/, GameData/,
#        GameConfig/, MUHelper/, ExternalObject/ are existing subdirectories
#        whose files get moved into the new module structure.

###############################################################################
# 2. Main/ — Entry point files
###############################################################################
echo "=== Moving Main/ ==="

gmv "$SRC/Winmain.cpp"   "$SRC/Main/"
gmv "$SRC/Winmain.h"     "$SRC/Main/"
gmv "$SRC/StdAfx.cpp"    "$SRC/Main/"
gmv "$SRC/stdafx.h"      "$SRC/Main/"

###############################################################################
# 3. Core/ — Types, defines, enums, structs, math, time, utilities, logging,
#             input, observer, PList, camera, singletons, global functions,
#             random, spinlock, useful definitions, base classes
###############################################################################
echo "=== Moving Core/ ==="

# Fundamental types and definitions
gmv "$SRC/_types.h"            "$SRC/Core/"
gmv "$SRC/_define.h"           "$SRC/Core/"
gmv "$SRC/_enum.h"             "$SRC/Core/"
gmv "$SRC/_struct.h"           "$SRC/Core/"
gmv "$SRC/Defined_Global.h"    "$SRC/Core/"
gmv "$SRC/Singleton.h"         "$SRC/Core/"
gmv "$SRC/BaseCls.h"           "$SRC/Core/"
gmv "$SRC/SpinLock.h"          "$SRC/Core/"
gmv "$SRC/Random.cpp"          "$SRC/Core/"
gmv "$SRC/Random.h"            "$SRC/Core/"
gmv "$SRC/UsefulDef.cpp"       "$SRC/Core/"
gmv "$SRC/UsefulDef.h"         "$SRC/Core/"

# Global functions (buff system accessors)
gmv "$SRC/_GlobalFunctions.cpp" "$SRC/Core/"
gmv "$SRC/_GlobalFunctions.h"   "$SRC/Core/"

# Input handling
gmv "$SRC/Input.cpp"           "$SRC/Core/"
gmv "$SRC/Input.h"             "$SRC/Core/"

# Observer pattern
gmv "$SRC/Observer.cpp"        "$SRC/Core/"
gmv "$SRC/Observer.h"          "$SRC/Core/"

# PList (generic list utility)
gmv "$SRC/PList.cpp"           "$SRC/Core/"
gmv "$SRC/PList.h"             "$SRC/Core/"

# Math (existing subdirectory)
gmv "$SRC/Math/ZzzMathLib.cpp" "$SRC/Core/"
gmv "$SRC/Math/ZzzMathLib.h"   "$SRC/Core/"

# Time (existing subdirectory)
gmv "$SRC/Time/CTimCheck.cpp"  "$SRC/Core/"
gmv "$SRC/Time/CTimCheck.h"    "$SRC/Core/"
gmv "$SRC/Time/Timer.cpp"      "$SRC/Core/"
gmv "$SRC/Time/Timer.h"        "$SRC/Core/"

# Camera utilities
gmv "$SRC/Camera/CameraUtility.cpp" "$SRC/Core/"
gmv "$SRC/Camera/CameraUtility.h"   "$SRC/Core/"
gmv "$SRC/CameraMove.cpp"           "$SRC/Core/"
gmv "$SRC/CameraMove.h"             "$SRC/Core/"

# Utilities (existing subdirectory)
gmv "$SRC/Utilities/CpuUsage.cpp"               "$SRC/Core/"
gmv "$SRC/Utilities/CpuUsage.h"                  "$SRC/Core/"
gmv "$SRC/Utilities/Debouncer.h"                  "$SRC/Core/"
gmv "$SRC/Utilities/StringUtils.h"                "$SRC/Core/"
gmv "$SRC/Utilities/Log/ErrorReport.cpp"          "$SRC/Core/"
gmv "$SRC/Utilities/Log/ErrorReport.h"            "$SRC/Core/"
gmv "$SRC/Utilities/Log/muConsoleDebug.cpp"       "$SRC/Core/"
gmv "$SRC/Utilities/Log/muConsoleDebug.h"         "$SRC/Core/"
gmv "$SRC/Utilities/Log/WindowsConsole.cpp"       "$SRC/Core/"
gmv "$SRC/Utilities/Log/WindowsConsole.h"         "$SRC/Core/"

# Window message handler (core infrastructure)
gmv "$SRC/w_WindowMessageHandler.h" "$SRC/Core/"

###############################################################################
# 4. Protocol/ — Crypto / packet encoding
###############################################################################
echo "=== Moving Protocol/ ==="

gmv "$SRC/_crypt.h"            "$SRC/Protocol/"
gmv "$SRC/KeyGenerater.cpp"    "$SRC/Protocol/"
gmv "$SRC/KeyGenerater.h"      "$SRC/Protocol/"

###############################################################################
# 5. Network/ — Socket, server connection, server list
###############################################################################
echo "=== Moving Network/ ==="

gmv "$SRC/WSclient.cpp"           "$SRC/Network/"
gmv "$SRC/WSclient.h"             "$SRC/Network/"
# Note: SocketSystem.cpp/h are about Pentagram item socket options (Season 4),
# NOT network sockets. They are moved to Gameplay/ below.
gmv "$SRC/CSMapServer.cpp"        "$SRC/Network/"
gmv "$SRC/CSMapServer.h"          "$SRC/Network/"
gmv "$SRC/ServerListManager.cpp"  "$SRC/Network/"
gmv "$SRC/ServerListManager.h"    "$SRC/Network/"
gmv "$SRC/ServerInfo.cpp"         "$SRC/Network/"
gmv "$SRC/ServerInfo.h"           "$SRC/Network/"
gmv "$SRC/ServerGroup.cpp"        "$SRC/Network/"
gmv "$SRC/ServerGroup.h"          "$SRC/Network/"

###############################################################################
# 6. Data/ — Data loading, game data structures, config, localization helpers,
#             BMD file loading, script reading, open data, global bitmaps/text
###############################################################################
echo "=== Moving Data/ ==="

# Primary data loading
gmv "$SRC/ZzzOpenData.cpp"      "$SRC/Data/"
gmv "$SRC/ZzzOpenData.h"        "$SRC/Data/"
gmv "$SRC/LoadData.cpp"         "$SRC/Data/"
gmv "$SRC/LoadData.h"           "$SRC/Data/"
gmv "$SRC/ReadScript.h"         "$SRC/Data/"
gmv "$SRC/SMD.cpp"              "$SRC/Data/"
gmv "$SRC/SMD.h"                "$SRC/Data/"
gmv "$SRC/SMD2BMD.cpp"          "$SRC/Data/"

# Global bitmaps & text
gmv "$SRC/GlobalBitmap.cpp"     "$SRC/Data/"
gmv "$SRC/GlobalBitmap.h"       "$SRC/Data/"
gmv "$SRC/GlobalText.h"         "$SRC/Data/"
gmv "$SRC/_TextureIndex.h"      "$SRC/Data/"
gmv "$SRC/stringset.h"          "$SRC/Data/"

# Localization
gmv "$SRC/MultiLanguage.cpp"    "$SRC/Data/"
gmv "$SRC/MultiLanguage.h"      "$SRC/Data/"
gmv "$SRC/Local.cpp"            "$SRC/Data/"
gmv "$SRC/Local.h"              "$SRC/Data/"

# Move command data (warp point definitions)
gmv "$SRC/MoveCommandData.cpp"  "$SRC/Data/"
gmv "$SRC/MoveCommandData.h"    "$SRC/Data/"

# ZzzInfomation — item/monster attribute data structures
gmv "$SRC/ZzzInfomation.cpp"    "$SRC/Data/"
gmv "$SRC/ZzzInfomation.h"      "$SRC/Data/"

# DataHandler/ (existing subdirectory — move entire tree)
gmv "$SRC/DataHandler/ChangeTracker.h"                              "$SRC/Data/"
gmv "$SRC/DataHandler/CommonDataSaver.cpp"                          "$SRC/Data/"
gmv "$SRC/DataHandler/CommonDataSaver.h"                            "$SRC/Data/"
gmv "$SRC/DataHandler/CommonDataSaver.inl"                          "$SRC/Data/"
gmv "$SRC/DataHandler/DataFileIO.cpp"                               "$SRC/Data/"
gmv "$SRC/DataHandler/DataFileIO.h"                                 "$SRC/Data/"
gmv "$SRC/DataHandler/FieldMetadata.h"                              "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemComparisonMetadata.h"            "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataExportAsCSV.cpp"             "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataExportAsCSV.h"               "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataExportS6E3.cpp"              "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataExportS6E3.h"                "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataHandler.cpp"                 "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataHandler.h"                   "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataLoader.cpp"                  "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataLoader.h"                    "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataSaver.cpp"                   "$SRC/Data/"
gmv "$SRC/DataHandler/ItemData/ItemDataSaver.h"                     "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillComparisonMetadata.h"          "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataExportAsCSV.cpp"           "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataExportAsCSV.h"             "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataExportS6E3.cpp"            "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataExportS6E3.h"              "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataHandler.cpp"               "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataHandler.h"                 "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataLoader.cpp"                "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataLoader.h"                  "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataSaver.cpp"                 "$SRC/Data/"
gmv "$SRC/DataHandler/SkillData/SkillDataSaver.h"                   "$SRC/Data/"

# GameData/ (existing subdirectory — move entire tree)
gmv "$SRC/GameData/Common/FieldMetadataHelper.h"                    "$SRC/Data/"
gmv "$SRC/GameData/ItemData/ItemFieldDefs.h"                        "$SRC/Data/"
gmv "$SRC/GameData/ItemData/ItemFieldMetadata.h"                    "$SRC/Data/"
gmv "$SRC/GameData/ItemData/ItemStructs.h"                          "$SRC/Data/"
gmv "$SRC/GameData/SkillData/SkillFieldDefs.h"                      "$SRC/Data/"
gmv "$SRC/GameData/SkillData/SkillFieldMetadata.h"                  "$SRC/Data/"
gmv "$SRC/GameData/SkillData/SkillStructs.h"                        "$SRC/Data/"

# GameConfig/ (existing subdirectory)
gmv "$SRC/GameConfig/GameConfig.cpp"                                "$SRC/Data/"
gmv "$SRC/GameConfig/GameConfig.h"                                  "$SRC/Data/"
gmv "$SRC/GameConfig/GameConfigConstants.h"                         "$SRC/Data/"

###############################################################################
# 7. World/ — Map/terrain files, GM_* maps, map manager, water terrain,
#              physics, pathfinding, BaseMap, MapProcess, MapHeaders
###############################################################################
echo "=== Moving World/ ==="

# Map manager & process
gmv "$SRC/MapManager.cpp"          "$SRC/World/"
gmv "$SRC/MapManager.h"            "$SRC/World/"
gmv "$SRC/w_BaseMap.h"             "$SRC/World/"
gmv "$SRC/w_MapProcess.cpp"        "$SRC/World/"
gmv "$SRC/w_MapProcess.h"          "$SRC/World/"
gmv "$SRC/w_MapHeaders.h"          "$SRC/World/"

# Terrain
gmv "$SRC/ZzzLodTerrain.cpp"       "$SRC/World/"
gmv "$SRC/ZzzLodTerrain.h"         "$SRC/World/"
gmv "$SRC/CSWaterTerrain.cpp"       "$SRC/World/"
gmv "$SRC/CSWaterTerrain.h"         "$SRC/World/"

# Physics & Pathfinding
gmv "$SRC/PhysicsManager.cpp"      "$SRC/World/"
gmv "$SRC/PhysicsManager.h"        "$SRC/World/"
gmv "$SRC/zzzpath.cpp"             "$SRC/World/"
gmv "$SRC/ZzzPath.h"               "$SRC/World/"

# Object info (interpolation for world objects)
gmv "$SRC/w_ObjectInfo.cpp"        "$SRC/World/"
gmv "$SRC/w_ObjectInfo.h"          "$SRC/World/"

# GM_* map files (game map zone implementations)
gmv "$SRC/GM_kanturu_1st.cpp"      "$SRC/World/"
gmv "$SRC/GM_Kanturu_1st.h"        "$SRC/World/"
gmv "$SRC/GM_Kanturu_2nd.cpp"      "$SRC/World/"
gmv "$SRC/GM_Kanturu_2nd.h"        "$SRC/World/"
gmv "$SRC/GM_Kanturu_3rd.cpp"      "$SRC/World/"
gmv "$SRC/GM_Kanturu_3rd.h"        "$SRC/World/"
gmv "$SRC/GM_PK_Field.cpp"         "$SRC/World/"
gmv "$SRC/GM_PK_Field.h"           "$SRC/World/"
gmv "$SRC/GM_Raklion.cpp"          "$SRC/World/"
gmv "$SRC/GM_Raklion.h"            "$SRC/World/"
gmv "$SRC/GM3rdChangeUp.cpp"       "$SRC/World/"
gmv "$SRC/GM3rdChangeUp.h"         "$SRC/World/"
gmv "$SRC/GMAida.cpp"              "$SRC/World/"
gmv "$SRC/GMAida.h"                "$SRC/World/"
gmv "$SRC/GMBattleCastle.cpp"      "$SRC/World/"
gmv "$SRC/GMBattleCastle.h"        "$SRC/World/"
gmv "$SRC/GMCryingWolf2nd.cpp"     "$SRC/World/"
gmv "$SRC/GMCryingWolf2nd.h"       "$SRC/World/"
gmv "$SRC/GMCrywolf1st.cpp"        "$SRC/World/"
gmv "$SRC/GMCrywolf1st.h"          "$SRC/World/"
gmv "$SRC/GMDoppelGanger1.cpp"     "$SRC/World/"
gmv "$SRC/GMDoppelGanger1.h"       "$SRC/World/"
gmv "$SRC/GMDoppelGanger2.cpp"     "$SRC/World/"
gmv "$SRC/GMDoppelGanger2.h"       "$SRC/World/"
gmv "$SRC/GMDoppelGanger3.cpp"     "$SRC/World/"
gmv "$SRC/GMDoppelGanger3.h"       "$SRC/World/"
gmv "$SRC/GMDoppelGanger4.cpp"     "$SRC/World/"
gmv "$SRC/GMDoppelGanger4.h"       "$SRC/World/"
gmv "$SRC/GMDuelArena.cpp"         "$SRC/World/"
gmv "$SRC/GMDuelArena.h"           "$SRC/World/"
gmv "$SRC/GMEmpireGuardian1.cpp"   "$SRC/World/"
gmv "$SRC/GMEmpireGuardian1.h"     "$SRC/World/"
gmv "$SRC/GMEmpireGuardian2.cpp"   "$SRC/World/"
gmv "$SRC/GMEmpireGuardian2.h"     "$SRC/World/"
gmv "$SRC/GMEmpireGuardian3.cpp"   "$SRC/World/"
gmv "$SRC/GMEmpireGuardian3.h"     "$SRC/World/"
gmv "$SRC/GMEmpireGuardian4.cpp"   "$SRC/World/"
gmv "$SRC/GMEmpireGuardian4.h"     "$SRC/World/"
gmv "$SRC/GMGmArea.h"              "$SRC/World/"
gmv "$SRC/GMHellas.cpp"            "$SRC/World/"
gmv "$SRC/GMHellas.h"              "$SRC/World/"
gmv "$SRC/GMHuntingGround.cpp"     "$SRC/World/"
gmv "$SRC/GMHuntingGround.h"       "$SRC/World/"
gmv "$SRC/GMKarutan1.cpp"          "$SRC/World/"
gmv "$SRC/GMKarutan1.h"            "$SRC/World/"
gmv "$SRC/GMNewTown.cpp"           "$SRC/World/"
gmv "$SRC/GMNewTown.h"             "$SRC/World/"
gmv "$SRC/GMSantaTown.cpp"         "$SRC/World/"
gmv "$SRC/GMSantaTown.h"           "$SRC/World/"
gmv "$SRC/GMSwampOfQuiet.cpp"      "$SRC/World/"
gmv "$SRC/GMSwampOfQuiet.h"        "$SRC/World/"
gmv "$SRC/GMUnitedMarketPlace.cpp" "$SRC/World/"
gmv "$SRC/GMUnitedMarketPlace.h"   "$SRC/World/"

# Direction/cutscene camera systems (map-related cinematics)
gmv "$SRC/CDirection.cpp"          "$SRC/World/"
gmv "$SRC/CDirection.h"            "$SRC/World/"
gmv "$SRC/CMVP1stDirection.cpp"    "$SRC/World/"
gmv "$SRC/CMVP1stDirection.h"      "$SRC/World/"
gmv "$SRC/CKANTURUDirection.cpp"   "$SRC/World/"
gmv "$SRC/CKANTURUDirection.h"     "$SRC/World/"

# Portal manager (map portal logic)
gmv "$SRC/PortalMgr.cpp"          "$SRC/World/"
gmv "$SRC/PortalMgr.h"            "$SRC/World/"

###############################################################################
# 8. Gameplay/ — Character, object, AI, inventory, skills, pets, events,
#                quests, items, parties, guilds (logic, NOT UI), NPCs,
#                match/event systems, duel, gamble, summon, monk, mix, buffs
###############################################################################
echo "=== Moving Gameplay/ ==="

# Character system
gmv "$SRC/ZzzCharacter.cpp"             "$SRC/Gameplay/"
gmv "$SRC/ZzzCharacter.h"               "$SRC/Gameplay/"
gmv "$SRC/CharacterManager.cpp"         "$SRC/Gameplay/"
gmv "$SRC/CharacterManager.h"           "$SRC/Gameplay/"
gmv "$SRC/w_CharacterInfo.cpp"          "$SRC/Gameplay/"
gmv "$SRC/w_CharacterInfo.h"            "$SRC/Gameplay/"
gmv "$SRC/MonkSystem.cpp"               "$SRC/Gameplay/"
gmv "$SRC/MonkSystem.h"                 "$SRC/Gameplay/"
gmv "$SRC/ChangeRingManager.cpp"        "$SRC/Gameplay/"
gmv "$SRC/ChangeRingManager.h"          "$SRC/Gameplay/"

# Object system
gmv "$SRC/ZzzObject.cpp"               "$SRC/Gameplay/"
gmv "$SRC/ZzzObject.h"                 "$SRC/Gameplay/"

# AI
gmv "$SRC/ZzzAI.cpp"                   "$SRC/Gameplay/"
gmv "$SRC/ZzzAI.h"                     "$SRC/Gameplay/"

# Inventory & Items
gmv "$SRC/ZzzInventory.cpp"             "$SRC/Gameplay/"
gmv "$SRC/ZzzInventory.h"               "$SRC/Gameplay/"
gmv "$SRC/ItemManager.cpp"              "$SRC/Gameplay/"
gmv "$SRC/ItemManager.h"                "$SRC/Gameplay/"
gmv "$SRC/ItemAddOptioninfo.cpp"        "$SRC/Gameplay/"
gmv "$SRC/ItemAddOptioninfo.h"          "$SRC/Gameplay/"
gmv "$SRC/CSItemOption.cpp"             "$SRC/Gameplay/"
gmv "$SRC/CSItemOption.h"               "$SRC/Gameplay/"
gmv "$SRC/SocketSystem.cpp"             "$SRC/Gameplay/"
gmv "$SRC/SocketSystem.h"               "$SRC/Gameplay/"
gmv "$SRC/CComGem.cpp"                 "$SRC/Gameplay/"
gmv "$SRC/CComGem.h"                   "$SRC/Gameplay/"
gmv "$SRC/GambleSystem.cpp"             "$SRC/Gameplay/"
gmv "$SRC/GambleSystem.h"               "$SRC/Gameplay/"
gmv "$SRC/MixMgr.cpp"                  "$SRC/Gameplay/"
gmv "$SRC/MixMgr.h"                    "$SRC/Gameplay/"
gmv "$SRC/PersonalShopTitleImp.cpp"     "$SRC/Gameplay/"
gmv "$SRC/PersonalShopTitleImp.h"       "$SRC/Gameplay/"

# Skills
gmv "$SRC/SkillManager.cpp"             "$SRC/Gameplay/"
gmv "$SRC/SkillManager.h"               "$SRC/Gameplay/"
gmv "$SRC/SkillEffectMgr.cpp"           "$SRC/Gameplay/"
gmv "$SRC/SkillEffectMgr.h"             "$SRC/Gameplay/"
gmv "$SRC/SummonSystem.cpp"             "$SRC/Gameplay/"
gmv "$SRC/SummonSystem.h"               "$SRC/Gameplay/"

# Pets
gmv "$SRC/CSPetSystem.cpp"              "$SRC/Gameplay/"
gmv "$SRC/CSPetSystem.h"                "$SRC/Gameplay/"
gmv "$SRC/GIPetManager.cpp"             "$SRC/Gameplay/"
gmv "$SRC/GIPetManager.h"               "$SRC/Gameplay/"
gmv "$SRC/w_BasePet.cpp"               "$SRC/Gameplay/"
gmv "$SRC/w_BasePet.h"                 "$SRC/Gameplay/"
gmv "$SRC/w_PetProcess.cpp"            "$SRC/Gameplay/"
gmv "$SRC/w_PetProcess.h"              "$SRC/Gameplay/"
gmv "$SRC/w_PetAction.h"               "$SRC/Gameplay/"
gmv "$SRC/w_PetActionCollecter.cpp"    "$SRC/Gameplay/"
gmv "$SRC/w_PetActionCollecter.h"      "$SRC/Gameplay/"
gmv "$SRC/w_PetActionCollecter_Add.cpp" "$SRC/Gameplay/"
gmv "$SRC/w_PetActionCollecter_Add.h"   "$SRC/Gameplay/"
gmv "$SRC/w_PetActionDemon.cpp"        "$SRC/Gameplay/"
gmv "$SRC/w_PetActionDemon.h"          "$SRC/Gameplay/"
gmv "$SRC/w_PetActionRound.cpp"        "$SRC/Gameplay/"
gmv "$SRC/w_PetActionRound.h"          "$SRC/Gameplay/"
gmv "$SRC/w_PetActionStand.cpp"        "$SRC/Gameplay/"
gmv "$SRC/w_PetActionStand.h"          "$SRC/Gameplay/"
gmv "$SRC/w_PetActionUnicorn.cpp"      "$SRC/Gameplay/"
gmv "$SRC/w_PetActionUnicorn.h"        "$SRC/Gameplay/"
gmv "$SRC/npcBreeder.cpp"              "$SRC/Gameplay/"
gmv "$SRC/npcBreeder.h"                "$SRC/Gameplay/"

# Mounts / Boids
gmv "$SRC/GOBoid.cpp"                  "$SRC/Gameplay/"
gmv "$SRC/GOBoid.h"                    "$SRC/Gameplay/"

# Character parts / visual gear
gmv "$SRC/CSParts.cpp"                 "$SRC/Gameplay/"
gmv "$SRC/CSParts.h"                   "$SRC/Gameplay/"

# Quests
gmv "$SRC/CSQuest.cpp"                 "$SRC/Gameplay/"
gmv "$SRC/CSQuest.h"                   "$SRC/Gameplay/"
gmv "$SRC/QuestMng.cpp"                "$SRC/Gameplay/"
gmv "$SRC/QuestMng.h"                  "$SRC/Gameplay/"

# Events and match systems
gmv "$SRC/Event.cpp"                   "$SRC/Gameplay/"
gmv "$SRC/Event.h"                     "$SRC/Gameplay/"
gmv "$SRC/CSEventMatch.cpp"            "$SRC/Gameplay/"
gmv "$SRC/CSEventMatch.h"              "$SRC/Gameplay/"
gmv "$SRC/CSChaosCastle.cpp"           "$SRC/Gameplay/"
gmv "$SRC/CSChaosCastle.h"             "$SRC/Gameplay/"
gmv "$SRC/MatchEvent.cpp"              "$SRC/Gameplay/"
gmv "$SRC/MatchEvent.h"                "$SRC/Gameplay/"
gmv "$SRC/NewBloodCastleSystem.cpp"    "$SRC/Gameplay/"
gmv "$SRC/NewBloodCastleSystem.h"      "$SRC/Gameplay/"
gmv "$SRC/NewChaosCastleSystem.cpp"    "$SRC/Gameplay/"
gmv "$SRC/NewChaosCastleSystem.h"      "$SRC/Gameplay/"
gmv "$SRC/w_CursedTemple.cpp"          "$SRC/Gameplay/"
gmv "$SRC/w_CursedTemple.h"            "$SRC/Gameplay/"

# Duel
gmv "$SRC/DuelMgr.cpp"                "$SRC/Gameplay/"
gmv "$SRC/DuelMgr.h"                  "$SRC/Gameplay/"

# Party
gmv "$SRC/PartyManager.cpp"            "$SRC/Gameplay/"
gmv "$SRC/PartyManager.h"              "$SRC/Gameplay/"

# Guild (logic files — from Guild/ subdirectory)
gmv "$SRC/Guild/GuildCache.cpp"         "$SRC/Gameplay/"
gmv "$SRC/Guild/GuildCache.h"           "$SRC/Gameplay/"
gmv "$SRC/Guild/GuildConstants.h"       "$SRC/Gameplay/"

# Buff system
gmv "$SRC/w_Buff.cpp"                  "$SRC/Gameplay/"
gmv "$SRC/w_Buff.h"                    "$SRC/Gameplay/"
gmv "$SRC/w_BuffScriptLoader.cpp"      "$SRC/Gameplay/"
gmv "$SRC/w_BuffScriptLoader.h"        "$SRC/Gameplay/"
gmv "$SRC/w_BuffStateSystem.cpp"       "$SRC/Gameplay/"
gmv "$SRC/w_BuffStateSystem.h"         "$SRC/Gameplay/"
gmv "$SRC/w_BuffStateValueControl.cpp" "$SRC/Gameplay/"
gmv "$SRC/w_BuffStateValueControl.h"   "$SRC/Gameplay/"
gmv "$SRC/w_BuffTimeControl.cpp"       "$SRC/Gameplay/"
gmv "$SRC/w_BuffTimeControl.h"         "$SRC/Gameplay/"

# NPC gameplay logic
gmv "$SRC/npcCatapult.cpp"             "$SRC/Gameplay/"
gmv "$SRC/npcCatapult.h"               "$SRC/Gameplay/"
gmv "$SRC/npcGateSwitch.cpp"           "$SRC/Gameplay/"
gmv "$SRC/npcGateSwitch.h"             "$SRC/Gameplay/"

# MU Helper (auto-play system)
gmv "$SRC/MUHelper/MuHelper.cpp"       "$SRC/Gameplay/"
gmv "$SRC/MUHelper/MuHelper.h"         "$SRC/Gameplay/"
gmv "$SRC/MUHelper/MuHelperData.cpp"   "$SRC/Gameplay/"
gmv "$SRC/MUHelper/MuHelperData.h"     "$SRC/Gameplay/"

###############################################################################
# 9. UI/Framework/ — NewUIBase, NewUIManager, NewUISystem, widget base classes,
#                     common UI utilities, 3D render manager, inventory ctrl,
#                     render number, scrollbar, button, textbox, group,
#                     message boxes, slide window, hotkey, item explanation
###############################################################################
echo "=== Moving UI/Framework/ ==="

gmv "$SRC/NewUIBase.h"                      "$SRC/UI/Framework/"
gmv "$SRC/NewUIManager.cpp"                 "$SRC/UI/Framework/"
gmv "$SRC/NewUIManager.h"                   "$SRC/UI/Framework/"
gmv "$SRC/NewUISystem.cpp"                  "$SRC/UI/Framework/"
gmv "$SRC/NewUISystem.h"                    "$SRC/UI/Framework/"
gmv "$SRC/NewUI3DRenderMng.cpp"             "$SRC/UI/Framework/"
gmv "$SRC/NewUI3DRenderMng.h"               "$SRC/UI/Framework/"
gmv "$SRC/NewUICommon.cpp"                  "$SRC/UI/Framework/"
gmv "$SRC/NewUICommon.h"                    "$SRC/UI/Framework/"
gmv "$SRC/NewUIButton.cpp"                  "$SRC/UI/Framework/"
gmv "$SRC/NewUIButton.h"                    "$SRC/UI/Framework/"
gmv "$SRC/NewUITextBox.cpp"                 "$SRC/UI/Framework/"
gmv "$SRC/NewUITextBox.h"                   "$SRC/UI/Framework/"
gmv "$SRC/NewUIScrollBar.cpp"               "$SRC/UI/Framework/"
gmv "$SRC/NewUIScrollBar.h"                 "$SRC/UI/Framework/"
gmv "$SRC/NewUIGroup.cpp"                   "$SRC/UI/Framework/"
gmv "$SRC/NewUIGroup.h"                     "$SRC/UI/Framework/"
gmv "$SRC/NewUIRenderNumber.cpp"            "$SRC/UI/Framework/"
gmv "$SRC/NewUIRenderNumber.h"              "$SRC/UI/Framework/"
gmv "$SRC/NewUISlideWindow.cpp"             "$SRC/UI/Framework/"
gmv "$SRC/NewUISlideWindow.h"               "$SRC/UI/Framework/"
gmv "$SRC/NewUIInventoryCtrl.cpp"           "$SRC/UI/Framework/"
gmv "$SRC/NewUIInventoryCtrl.h"             "$SRC/UI/Framework/"
gmv "$SRC/NewUIMessageBox.cpp"              "$SRC/UI/Framework/"
gmv "$SRC/NewUIMessageBox.h"                "$SRC/UI/Framework/"
gmv "$SRC/NewUICommonMessageBox.cpp"        "$SRC/UI/Framework/"
gmv "$SRC/NewUICommonMessageBox.h"          "$SRC/UI/Framework/"
gmv "$SRC/NewUICustomMessageBox.cpp"        "$SRC/UI/Framework/"
gmv "$SRC/NewUICustomMessageBox.h"          "$SRC/UI/Framework/"
gmv "$SRC/NewUIHotKey.cpp"                  "$SRC/UI/Framework/"
gmv "$SRC/NewUIHotKey.h"                    "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemMng.cpp"                 "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemMng.h"                   "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemExplanationWindow.cpp"   "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemExplanationWindow.h"     "$SRC/UI/Framework/"
gmv "$SRC/NewUISetItemExplanation.cpp"      "$SRC/UI/Framework/"
gmv "$SRC/NewUISetItemExplanation.h"        "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemEnduranceInfo.cpp"       "$SRC/UI/Framework/"
gmv "$SRC/NewUIItemEnduranceInfo.h"         "$SRC/UI/Framework/"
gmv "$SRC/UIBaseDef.h"                      "$SRC/UI/Framework/"
gmv "$SRC/UIDefaultBase.cpp"                "$SRC/UI/Framework/"
gmv "$SRC/UIDefaultBase.h"                  "$SRC/UI/Framework/"

###############################################################################
# 10. UI/Windows/ — All NewUI*Window files (game windows and panels)
###############################################################################
echo "=== Moving UI/Windows/ ==="

gmv "$SRC/NewUIMainFrameWindow.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIMainFrameWindow.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUICharacterInfoWindow.cpp"     "$SRC/UI/Windows/"
gmv "$SRC/NewUICharacterInfoWindow.h"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyInventory.cpp"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyInventory.h"               "$SRC/UI/Windows/"
gmv "$SRC/NewUIInventoryExtension.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUIInventoryExtension.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIMixInventory.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUIMixInventory.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIStorageInventory.cpp"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIStorageInventory.h"          "$SRC/UI/Windows/"
gmv "$SRC/NewUIStorageInventoryExt.cpp"     "$SRC/UI/Windows/"
gmv "$SRC/NewUIStorageInventoryExt.h"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyShopInventory.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyShopInventory.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIPurchaseShopInventory.cpp"   "$SRC/UI/Windows/"
gmv "$SRC/NewUIPurchaseShopInventory.h"     "$SRC/UI/Windows/"
gmv "$SRC/NewUITrade.cpp"                   "$SRC/UI/Windows/"
gmv "$SRC/NewUITrade.h"                     "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCShop.cpp"                 "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCShop.h"                   "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCDialogue.cpp"             "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCDialogue.h"               "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCQuest.cpp"                "$SRC/UI/Windows/"
gmv "$SRC/NewUINPCQuest.h"                  "$SRC/UI/Windows/"
gmv "$SRC/NewUIPartyInfoWindow.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIPartyInfoWindow.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIPartyListWindow.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIPartyListWindow.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIFriendWindow.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUIFriendWindow.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIMiniMap.cpp"                 "$SRC/UI/Windows/"
gmv "$SRC/NewUIMiniMap.h"                   "$SRC/UI/Windows/"
gmv "$SRC/NewUIHelpWindow.cpp"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIHelpWindow.h"                "$SRC/UI/Windows/"
gmv "$SRC/NewUIOptionWindow.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUIOptionWindow.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUICommandWindow.cpp"           "$SRC/UI/Windows/"
gmv "$SRC/NewUICommandWindow.h"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuickCommandWindow.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuickCommandWindow.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIWindowMenu.cpp"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIWindowMenu.h"                "$SRC/UI/Windows/"
gmv "$SRC/NewUIChatInputBox.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUIChatInputBox.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIChatLogWindow.cpp"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIChatLogWindow.h"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIBuffWindow.cpp"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIBuffWindow.h"                "$SRC/UI/Windows/"
gmv "$SRC/NewUIMasterLevel.cpp"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIMasterLevel.h"               "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyQuestInfoWindow.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIMyQuestInfoWindow.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuestProgress.cpp"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuestProgress.h"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuestProgressByEtc.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUIQuestProgressByEtc.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIPetInfoWindow.cpp"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIPetInfoWindow.h"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIGatemanWindow.cpp"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIGatemanWindow.h"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIGateSwitchWindow.cpp"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIGateSwitchWindow.h"          "$SRC/UI/Windows/"
gmv "$SRC/NewUIGuardWindow.cpp"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIGuardWindow.h"               "$SRC/UI/Windows/"
gmv "$SRC/NewUICastleWindow.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUICastleWindow.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUICatapultWindow.cpp"          "$SRC/UI/Windows/"
gmv "$SRC/NewUICatapultWindow.h"            "$SRC/UI/Windows/"
gmv "$SRC/NewUINameWindow.cpp"              "$SRC/UI/Windows/"
gmv "$SRC/NewUINameWindow.h"                "$SRC/UI/Windows/"
gmv "$SRC/NewUIMoveCommandWindow.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIMoveCommandWindow.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIGensRanking.cpp"             "$SRC/UI/Windows/"
gmv "$SRC/NewUIGensRanking.h"               "$SRC/UI/Windows/"
gmv "$SRC/NewUIEnterDevilSquare.cpp"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIEnterDevilSquare.h"          "$SRC/UI/Windows/"
gmv "$SRC/NewUIBloodCastleEnter.cpp"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIBloodCastleEnter.h"          "$SRC/UI/Windows/"
gmv "$SRC/NewUIBloodCastleTime.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIBloodCastleTime.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUIChaosCastleTime.cpp"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIChaosCastleTime.h"           "$SRC/UI/Windows/"
gmv "$SRC/NewUILuckyItemWnd.cpp"            "$SRC/UI/Windows/"
gmv "$SRC/NewUILuckyItemWnd.h"              "$SRC/UI/Windows/"
gmv "$SRC/NewUIExchangeLuckyCoin.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIExchangeLuckyCoin.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIRegistrationLuckyCoin.cpp"   "$SRC/UI/Windows/"
gmv "$SRC/NewUIRegistrationLuckyCoin.h"     "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleEnter.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleEnter.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleResult.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleResult.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleSystem.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUICursedTempleSystem.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIDoppelGangerFrame.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIDoppelGangerFrame.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIDoppelGangerWindow.cpp"      "$SRC/UI/Windows/"
gmv "$SRC/NewUIDoppelGangerWindow.h"        "$SRC/UI/Windows/"
gmv "$SRC/NewUIEmpireGuardianNPC.cpp"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIEmpireGuardianNPC.h"         "$SRC/UI/Windows/"
gmv "$SRC/NewUIEmpireGuardianTimer.cpp"     "$SRC/UI/Windows/"
gmv "$SRC/NewUIEmpireGuardianTimer.h"       "$SRC/UI/Windows/"
gmv "$SRC/NewUIUnitedMarketPlaceWindow.cpp" "$SRC/UI/Windows/"
gmv "$SRC/NewUIUnitedMarketPlaceWindow.h"   "$SRC/UI/Windows/"
gmv "$SRC/NewUIMuHelper.cpp"                "$SRC/UI/Windows/"
gmv "$SRC/NewUIMuHelper.h"                  "$SRC/UI/Windows/"

# Guild UI windows (from Guild/ subdirectory)
gmv "$SRC/Guild/NewUIGuildInfoWindow.cpp"   "$SRC/UI/Windows/"
gmv "$SRC/Guild/NewUIGuildInfoWindow.h"     "$SRC/UI/Windows/"
gmv "$SRC/Guild/NewUIGuildMakeWindow.cpp"   "$SRC/UI/Windows/"
gmv "$SRC/Guild/NewUIGuildMakeWindow.h"     "$SRC/UI/Windows/"

###############################################################################
# 11. UI/Events/ — Event-related UIs (siege, duel, battle soccer,
#                   gold bowman, hero position, kanturu, crywolf)
###############################################################################
echo "=== Moving UI/Events/ ==="

# Siege warfare UIs
gmv "$SRC/NewUISeigeWarfare.cpp"            "$SRC/UI/Events/"
gmv "$SRC/NewUISeigeWarfare.h"              "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarBase.cpp"            "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarBase.h"              "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarCommander.cpp"       "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarCommander.h"         "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarObserver.cpp"        "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarObserver.h"          "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarSoldier.cpp"         "$SRC/UI/Events/"
gmv "$SRC/NewUISiegeWarSoldier.h"           "$SRC/UI/Events/"

# Duel UIs
gmv "$SRC/NewUIDuelWindow.cpp"              "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWindow.h"                "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchWindow.cpp"         "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchWindow.h"           "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchMainFrameWindow.cpp" "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchMainFrameWindow.h"   "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchUserListWindow.cpp" "$SRC/UI/Events/"
gmv "$SRC/NewUIDuelWatchUserListWindow.h"   "$SRC/UI/Events/"

# Battle soccer score
gmv "$SRC/NewUIBattleSoccerScore.cpp"       "$SRC/UI/Events/"
gmv "$SRC/NewUIBattleSoccerScore.h"         "$SRC/UI/Events/"

# Gold bowman
gmv "$SRC/NewUIGoldBowmanLena.cpp"          "$SRC/UI/Events/"
gmv "$SRC/NewUIGoldBowmanLena.h"            "$SRC/UI/Events/"
gmv "$SRC/NewUIGoldBowmanWindow.cpp"        "$SRC/UI/Events/"
gmv "$SRC/NewUIGoldBowmanWindow.h"          "$SRC/UI/Events/"

# Hero position info
gmv "$SRC/NewUIHeroPositionInfo.cpp"        "$SRC/UI/Events/"
gmv "$SRC/NewUIHeroPositionInfo.h"          "$SRC/UI/Events/"

# Kanturu event UI
gmv "$SRC/NewUIKanturuEvent.cpp"            "$SRC/UI/Events/"
gmv "$SRC/NewUIKanturuEvent.h"              "$SRC/UI/Events/"

# CryWolf event UI
gmv "$SRC/NewUICryWolf.cpp"                 "$SRC/UI/Events/"
gmv "$SRC/NewUICryWolf.h"                   "$SRC/UI/Events/"

###############################################################################
# 12. UI/Legacy/ — Win*, WinEx*, UI* (old-style UI), login/char select UIs,
#                   ZzzInterface, message windows
###############################################################################
echo "=== Moving UI/Legacy/ ==="

# ZzzInterface (main legacy UI)
gmv "$SRC/ZzzInterface.cpp"                 "$SRC/UI/Legacy/"
gmv "$SRC/ZzzInterface.h"                   "$SRC/UI/Legacy/"

# Win* legacy windows
gmv "$SRC/Win.cpp"                          "$SRC/UI/Legacy/"
gmv "$SRC/Win.h"                            "$SRC/UI/Legacy/"
gmv "$SRC/WinEx.cpp"                        "$SRC/UI/Legacy/"
gmv "$SRC/WinEx.h"                          "$SRC/UI/Legacy/"

# Login & character select windows
gmv "$SRC/LoginMainWin.cpp"                 "$SRC/UI/Legacy/"
gmv "$SRC/LoginMainWin.h"                   "$SRC/UI/Legacy/"
gmv "$SRC/LoginWin.cpp"                     "$SRC/UI/Legacy/"
gmv "$SRC/LoginWin.h"                       "$SRC/UI/Legacy/"
gmv "$SRC/CharSelMainWin.cpp"               "$SRC/UI/Legacy/"
gmv "$SRC/CharSelMainWin.h"                 "$SRC/UI/Legacy/"
gmv "$SRC/CharMakeWin.cpp"                  "$SRC/UI/Legacy/"
gmv "$SRC/CharMakeWin.h"                    "$SRC/UI/Legacy/"
gmv "$SRC/CreditWin.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/CreditWin.h"                      "$SRC/UI/Legacy/"
gmv "$SRC/ServerSelWin.cpp"                 "$SRC/UI/Legacy/"
gmv "$SRC/ServerSelWin.h"                   "$SRC/UI/Legacy/"
gmv "$SRC/ServerMsgWin.cpp"                 "$SRC/UI/Legacy/"
gmv "$SRC/ServerMsgWin.h"                   "$SRC/UI/Legacy/"
gmv "$SRC/MsgWin.cpp"                       "$SRC/UI/Legacy/"
gmv "$SRC/MsgWin.h"                         "$SRC/UI/Legacy/"
gmv "$SRC/SysMenuWin.cpp"                   "$SRC/UI/Legacy/"
gmv "$SRC/SysMenuWin.h"                     "$SRC/UI/Legacy/"
gmv "$SRC/OptionWin.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/OptionWin.h"                      "$SRC/UI/Legacy/"

# UI* legacy files
gmv "$SRC/UIManager.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/UIManager.h"                      "$SRC/UI/Legacy/"
gmv "$SRC/UIMng.cpp"                        "$SRC/UI/Legacy/"
gmv "$SRC/UIMng.h"                          "$SRC/UI/Legacy/"
gmv "$SRC/UIWindows.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/UIWindows.h"                      "$SRC/UI/Legacy/"
gmv "$SRC/UIGateKeeper.cpp"                 "$SRC/UI/Legacy/"
gmv "$SRC/UIGateKeeper.h"                   "$SRC/UI/Legacy/"
gmv "$SRC/UIGuardsMan.cpp"                  "$SRC/UI/Legacy/"
gmv "$SRC/UIGuardsMan.h"                    "$SRC/UI/Legacy/"
gmv "$SRC/UIJewelHarmony.cpp"               "$SRC/UI/Legacy/"
gmv "$SRC/UIJewelHarmony.h"                 "$SRC/UI/Legacy/"
gmv "$SRC/UIMapName.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/UIMapName.h"                      "$SRC/UI/Legacy/"
gmv "$SRC/UIPopup.cpp"                      "$SRC/UI/Legacy/"
gmv "$SRC/UIPopup.h"                        "$SRC/UI/Legacy/"
gmv "$SRC/UISenatus.cpp"                    "$SRC/UI/Legacy/"
gmv "$SRC/UISenatus.h"                      "$SRC/UI/Legacy/"

# Guild legacy UIs (from Guild/ subdirectory)
gmv "$SRC/Guild/UIGuildInfo.cpp"            "$SRC/UI/Legacy/"
gmv "$SRC/Guild/UIGuildInfo.h"              "$SRC/UI/Legacy/"
gmv "$SRC/Guild/UIGuildMaster.cpp"          "$SRC/UI/Legacy/"
gmv "$SRC/Guild/UIGuildMaster.h"            "$SRC/UI/Legacy/"

# CharInfoBalloon (HUD overlay)
gmv "$SRC/CharInfoBalloon.cpp"              "$SRC/UI/Legacy/"
gmv "$SRC/CharInfoBalloon.h"                "$SRC/UI/Legacy/"
gmv "$SRC/CharInfoBalloonMng.cpp"           "$SRC/UI/Legacy/"
gmv "$SRC/CharInfoBalloonMng.h"             "$SRC/UI/Legacy/"

# Sprite-based UI widgets
gmv "$SRC/Sprite.cpp"                       "$SRC/UI/Legacy/"
gmv "$SRC/Sprite.h"                         "$SRC/UI/Legacy/"
gmv "$SRC/Button.cpp"                       "$SRC/UI/Legacy/"
gmv "$SRC/Button.h"                         "$SRC/UI/Legacy/"
gmv "$SRC/Slider.cpp"                       "$SRC/UI/Legacy/"
gmv "$SRC/Slider.h"                         "$SRC/UI/Legacy/"
gmv "$SRC/GaugeBar.cpp"                     "$SRC/UI/Legacy/"
gmv "$SRC/GaugeBar.h"                       "$SRC/UI/Legacy/"

###############################################################################
# 13. Audio/ — Sound files
###############################################################################
echo "=== Moving Audio/ ==="

gmv "$SRC/DSplaysound.cpp"     "$SRC/Audio/"
gmv "$SRC/DSPlaySound.h"       "$SRC/Audio/"
gmv "$SRC/DSwaveIO.cpp"        "$SRC/Audio/"
gmv "$SRC/DSwaveIO.h"          "$SRC/Audio/"
gmv "$SRC/DSWavRead.h"         "$SRC/Audio/"

###############################################################################
# 14. RenderFX/ — Effects, models, textures, OpenGL utils, shadows, bones,
#                  side hair, texture scripts, bitmap rendering
###############################################################################
echo "=== Moving RenderFX/ ==="

# Effects
gmv "$SRC/ZzzEffect.cpp"              "$SRC/RenderFX/"
gmv "$SRC/ZzzEffect.h"                "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectBlurSpark.cpp"     "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectFireLeave.cpp"     "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectJoint.cpp"         "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectMagicSkill.cpp"    "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectParticle.cpp"      "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectPoint.cpp"         "$SRC/RenderFX/"
gmv "$SRC/ZzzEffectPointer.cpp"       "$SRC/RenderFX/"
gmv "$SRC/zzzeffectsprite.cpp"        "$SRC/RenderFX/"

# BMD model system
gmv "$SRC/ZzzBMD.cpp"                 "$SRC/RenderFX/"
gmv "$SRC/ZzzBMD.h"                   "$SRC/RenderFX/"

# Textures
gmv "$SRC/ZzzTexture.cpp"             "$SRC/RenderFX/"
gmv "$SRC/ZzzTexture.h"              "$SRC/RenderFX/"
gmv "$SRC/TextureScript.cpp"          "$SRC/RenderFX/"
gmv "$SRC/TextureScript.h"            "$SRC/RenderFX/"

# OpenGL utilities
gmv "$SRC/ZzzOpenglUtil.cpp"          "$SRC/RenderFX/"
gmv "$SRC/ZzzOpenglUtil.h"            "$SRC/RenderFX/"

# Shadow & bone rendering
gmv "$SRC/ShadowVolume.cpp"           "$SRC/RenderFX/"
gmv "$SRC/ShadowVolume.h"             "$SRC/RenderFX/"
gmv "$SRC/SideHair.cpp"               "$SRC/RenderFX/"
gmv "$SRC/SideHair.h"                 "$SRC/RenderFX/"
gmv "$SRC/BoneManager.cpp"            "$SRC/RenderFX/"
gmv "$SRC/BoneManager.h"              "$SRC/RenderFX/"

###############################################################################
# 15. ThirdParty/ — External code
###############################################################################
echo "=== Moving ThirdParty/ ==="

gmv "$SRC/ExternalObject/Leaf/regkey.h"        "$SRC/ThirdParty/"
gmv "$SRC/ExternalObject/Leaf/xstreambuf.cpp"  "$SRC/ThirdParty/"
gmv "$SRC/ExternalObject/Leaf/xstreambuf.h"    "$SRC/ThirdParty/"
gmv "$SRC/UIControls.cpp"                       "$SRC/ThirdParty/"
gmv "$SRC/UIControls.h"                         "$SRC/ThirdParty/"
gmv "$SRC/CBTMessageBox.cpp"                    "$SRC/ThirdParty/"
gmv "$SRC/CBTMessageBox.h"                      "$SRC/ThirdParty/"
gmv "$SRC/iexplorer.h"                          "$SRC/ThirdParty/"

###############################################################################
# 16. Resources/Windows/ — RC, ICO, resource files
###############################################################################
echo "=== Moving Resources/Windows/ ==="

gmv "$SRC/resource.rc"         "$SRC/Resources/Windows/"
gmv "$SRC/resource.h"          "$SRC/Resources/Windows/"
gmv "$SRC/icon1.ico"           "$SRC/Resources/Windows/"
gmv "$SRC/icon2.ico"           "$SRC/Resources/Windows/"

###############################################################################
# 17. Clean up now-empty old subdirectories
###############################################################################
echo "=== Cleaning up empty directories ==="

# These directories should now be empty after all files were moved out.
# git will track the moves; the empty dirs can be removed.
rmdir "$SRC/Camera"          2>/dev/null || true
rmdir "$SRC/Math"            2>/dev/null || true
rmdir "$SRC/Time"            2>/dev/null || true
rmdir "$SRC/Utilities/Log"   2>/dev/null || true
rmdir "$SRC/Utilities"       2>/dev/null || true
rmdir "$SRC/Guild"           2>/dev/null || true
rmdir "$SRC/ExternalObject/Leaf" 2>/dev/null || true
rmdir "$SRC/ExternalObject"  2>/dev/null || true
rmdir "$SRC/MUHelper"        2>/dev/null || true
rmdir "$SRC/DataHandler/ItemData"  2>/dev/null || true
rmdir "$SRC/DataHandler/SkillData" 2>/dev/null || true
rmdir "$SRC/DataHandler"     2>/dev/null || true
rmdir "$SRC/GameData/Common"       2>/dev/null || true
rmdir "$SRC/GameData/ItemData"     2>/dev/null || true
rmdir "$SRC/GameData/SkillData"    2>/dev/null || true
rmdir "$SRC/GameData"        2>/dev/null || true
rmdir "$SRC/GameConfig"      2>/dev/null || true

###############################################################################
# 18. Summary
###############################################################################
echo ""
echo "=== Reorganization complete ==="
echo ""
echo "Module structure created:"
echo "  Main/              - Entry point (4 files)"
echo "  Core/              - Types, math, time, utilities, logging, input (38 files)"
echo "  Protocol/          - Crypto/encoding (3 files)"
echo "  Network/           - Socket, server list (10 files)"
echo "  Data/              - Data loading, config, i18n, game data (54 files)"
echo "  World/             - Maps, terrain, physics, pathfinding (78 files)"
echo "  Gameplay/          - Characters, objects, AI, items, skills, pets, events (92 files)"
echo "  UI/Framework/      - NewUI base classes, widgets (34 files)"
echo "  UI/Windows/        - NewUI game windows (96 files)"
echo "  UI/Events/         - Event-related UIs (26 files)"
echo "  UI/Legacy/         - Win*, UI*, ZzzInterface, login/char UIs (56 files)"
echo "  Audio/             - Sound system (5 files)"
echo "  RenderFX/          - Effects, models, textures, OpenGL (22 files)"
echo "  ThirdParty/        - External code (7 files)"
echo "  Resources/Windows/ - RC, ICO files (4 files)"
echo "  Platform/          - Empty (future SDL3 migration)"
echo "  ---"
echo "  Scenes/            - (unchanged, already exists)"
echo "  Dotnet/            - (unchanged, already exists)"
echo "  GameShop/          - (unchanged, already exists)"
echo "  Translation/       - (unchanged, already exists)"
echo ""
echo "IMPORTANT: After running this script, you must update:"
echo "  1. #include paths in all source files"
echo "  2. CMakeLists.txt / CMakePresets.json source file lists"
echo "  3. resource.rc relative paths to .ico files"
echo "  4. Any hardcoded paths in build scripts"
echo ""
echo "Run 'git status' to review all moves before committing."
