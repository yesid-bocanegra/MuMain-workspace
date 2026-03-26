# Pipeline Feedback — Story 7-6-6-shoplistmanager-http-cross-platform

## Failed Step: code-review-analysis
## Regression Target: code-review-analysis

## Failure Details

📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review-finalize/workflow.yaml
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review-finalize/instructions.xml
🖥️  Running: find ./_bmad/pcc/workflows/code-review-finalize -type f | head -20
💬 Now loading the dispatcher and phase-specific instructions:
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review-finalize/instructions-dispatcher.xml
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review-finalize/instructions-fix.xml
💬 Let me check the code review file to determine which phase we're in (fix, validate, or finalize):
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/7-6-6-shoplistmanager-http-cross-platform/review.md
💬 Based on the dispatcher logic, we're in the **FIX PHASE** (Step 3: Resolution section doesn't exist yet). I need to fix all 8 issues and re-run the quality gate. Let me start with the HIGH severity issues:

**Issue 1: BannerInfo.cpp - curl_easy_perform return unchecked**
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/BannerInfo.cpp
💬 Let me read the full SetBanner function context:
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/BannerInfo.cpp
💬 Now I'll fix all 8 issues systematically. Let me start with **Issue 1: BannerInfo.cpp:97**
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/BannerInfo.cpp
💬 **Issue 2: ListManager.cpp - Fix off-by-one in trailing slash check**
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/ListManager.cpp
💬 **Issue 3: ShopList.cpp - Fix wchar_t type-pun cast**

Let me read the GetDecodedString function:
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/ShopList.cpp
💬 Let me see the full GetDecodedString function:
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/ShopList.cpp
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/ShopList.cpp
💬 **Issue 4: Path.cpp - Fix ReadFileLastLine to populate output parameter**
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/interface/PathMethod/Path.cpp
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/interface/PathMethod/Path.cpp
💬 **Issue 5: FTPFileDownLoader.cpp - Remove static qualifier from WZResult**
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/FTPFileDownLoader.cpp
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/ShopListManager/FTPFileDownLoader.cpp
💬 **Issue 6: FTPConnecter.cpp - Add explicit passive mode setting**
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/FileDownloader/FTPConnecter.cpp
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/GameShop/FileDownloader/FTPConnecter.cpp
💬 **Issue 7: ATDD.md - Uncheck false RAII claim**
🔧 Editing: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/7-6-6-shoplistmanager-http-cross-platform/atdd.md
💬 **Issue 8: ShopList.cpp - Use portable APIs instead of Win32 directly**

Let me check the PlatformCompat.h for available helpers:
🖥️  Running: grep -n "mu_wchar_to_utf8\|mu_utf8_to_wchar\|mu_ansi_to_wide\|mu_wide_to_ansi" /...
💬 Let me search for available conversion patterns in the codebase:
🖥️  Running: grep -r "mbstowcs\|wcstombs\|std::wstring_convert" /Users/joseybv/workspace/mu/M...
💬 Now let me run the quality gate to verify all fixes are working:
🖥️  Running: ./ctl check 2>&1 | head -100
🖥️  Running: ./ctl check 2>&1 | tail -50


## Action Required

Address ALL issues above before proceeding. Do NOT mark story complete until all gaps are filled.
