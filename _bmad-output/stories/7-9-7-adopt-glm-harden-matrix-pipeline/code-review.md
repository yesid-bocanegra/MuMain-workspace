# code-review — Step Summary

**Story:** 7-9-7 | **Workflow:** code-review

## Attempt — 2026-04-01 14:42:06

| Field | Value |
|-------|-------|
| Verdict | PASSED |
| Duration | 578.6047863960266s |
| Tokens | 2076 in / 29376 out |
| Turns | 81 |

### Execution Output

💬 

I'll invoke the code-review skill for story 7-9-7.
⚡ Skill: bmad-pcc-code-review
💬 Let me load the workflow engine and the code-review workflow config.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/engine/workflow.xml
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review/workflow.yaml
💬 Good. Now executing **Step 1a**: Load config_source and resolve variables.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/bmm/config.yaml
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad/pcc/workflows/code-review/instructions.xml
💬 **Workflow Engine initialized.** Variables resolved:
- `story_key` = `7-9-7`
- `output_folder` = `_bmad-output`
- Story directory: `_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/`
- No template → action-workflow (Step 1c skipped)

Now executing **Step 1: load-context** — Load story, ATDD checklist, and file list.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/story.md
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/test-artifacts/atdd-checklist-7-9-7.md
💬 Step 1 complete. I have the story (9 ACs, 9 tasks, 15 files) and ATDD checklist (22/22 checked). Now executing **Step 2: review-code** — adversarial code review.

Let me first get the diff for all story changes, then read the key implementation files.
🖥️  Running: git log --oneline --all | grep -i "7-9-7\|7.9.7\|glm\|matrix" | head -20
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/shaders/basic_textured.vert.hlsl
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/shaders/basic_textured.frag.hlsl
💬 Now let me get the diff for the actual implementation changes and read the key source files.
🖥️  Running: git log --oneline ec87181^..HEAD -- MuMain/src/ MuMain/CMakeLists.txt MuMain/tes...
🖥️  Running: git diff ec87181^..ec87181 --stat -- MuMain/src/ MuMain/CMakeLists.txt MuMain/te...
🖥️  Running: git log --oneline --all -- MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp | hea...
🖥️  Running: git log --oneline -20 -- MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp 2>&1
🖥️  Running: git log --oneline -20 2>&1
💬 Let me read the key implementation files directly. MuRendererSDLGpu.cpp is large so I'll read it in sections focusing on the changed areas.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/render/test_matrix_math_7_9_7.cpp
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/build/test_ac3_depth_buffer_created_7_9_7.cmake
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/build/test_ac4_alpha_discard_propagated_7_9_7.cmake
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/tests/build/test_ac7_alpha_func_override_7_9_7.cmake
💬 Now let me read the critical implementation sections of MuRendererSDLGpu.cpp and the file with the cppcheck error.
🔎 Grepping: SetAlphaTest|SetAlphaFunc|s_fogDirty|alphaDiscardEnabled|alphaThreshold|CreateOrResizeDepthTexture|m_depthTexture|has_depth_stencil_target
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/UI/Framework/NewUIItemEnduranceInfo.cpp
💬 Good, I found the cppcheck error. Now let me read more of the renderer's key sections — the depth buffer function and matrix stack area.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
💬 Let me check the depth texture cleanup in Shutdown and the matrix stack implementation.
🔎 Grepping: s_depthTexture|s_depthW|s_depthH
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
🔎 Grepping: glm::perspective|glm::ortho|m_projectionMatrix|m_modelViewMatrix|m_mvpMatrix|PushMatrix|PopMatrix|MatrixMode
💬 Let me check the BeginScene method, the 2D pass handling, and the shader metadata.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
🔎 Grepping: numStorageBuffers|numUniformBuffers|num_storage|num_uniform|LoadShaders|CreateShaderFromBlob
💬 Let me see the actual shader creation calls with their parameters.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
🔎 Grepping: glm::perspective|gluPerspective
💬 Let me check the compiled MSL shaders and the CMakeLists.txt for GLM integration.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/shaders/compiled/basic_textured.vert.msl
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/shaders/compiled/basic_textured.frag.msl
🔎 Grepping: FetchContent.*glm|glm.*GIT_TAG|GLM_FORCE_DEPTH|target_link.*glm
💬 Let me check the GLM link target and look at a few more areas for potential issues.
🔎 Grepping: target_link_libraries.*glm|glm.*target_link
🔎 Grepping: GLM_FORCE_DEPTH_ZERO_TO_ONE
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
💬 Let me check that potentially incorrect comment in ZzzOpenglUtil.cpp about GLM_FORCE_LEFT_HANDED.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/ZzzOpenglUtil.cpp
🔎 Grepping: GLM_FORCE_LEFT_HANDED
💬 Now I have enough data for a thorough review. Let me also check one more potential issue — the render pass depth store operation and its interaction with the quad strip mid-frame pass restart.
📖 Reading: /Users/joseybv/workspace/mu/MuMain-workspace/MuMain/src/source/RenderFX/MuRendererSDLGpu.cpp
💬 `★ Insight ─────────────────────────────────────`
**Key finding from depth buffer analysis:** The initial render pass (BeginFrame) sets `depthTarget.store_op = SDL_GPU_STOREOP_DONT_CARE` (line 773), which tells the GPU it need not preserve depth data after the pass ends. But `RenderQuadStrip()` temporarily ends and reopens the pass mid-frame (lines 1360→1388), with `LOADOP_LOAD` on the depth target. On tile-based GPUs like Apple Silicon (Metal), `STOREOP_DONT_CARE` means tile memory is NOT written back to the backing texture — so the reload reads undefined data. This is a real rendering correctness bug on the primary target platform (macOS).
`─────────────────────────────────────────────────`

Now I have all findings. Let me execute **Step 3: check-atdd** and then **Step 4: create-review-file**.

**Step 3: ATDD Checklist Accuracy**

Cross-referencing ATDD items against actual implementations:
- 22/22 items checked. File-scan (cmake) tests verify source patterns; Catch2 tests verify GLM math. All present and valid.
- The ATDD header says "6 tests" for Catch2, but the actual file has **7** TEST_CASEs — minor count inaccuracy.
- All cmake tests correctly verify their stated patterns (confirmed by grep results above).

Now **Step 4: create review.md**.
🔧 ToolSearch
📝 Updating todo list
✏️  Writing: /Users/joseybv/workspace/mu/MuMain-workspace/_bmad-output/stories/7-9-7-adopt-glm-harden-matrix-pipeline/review.md
📝 Updating todo list
💬 `★ Insight ─────────────────────────────────────`
**Why adversarial code review matters for GPU code:**
- GPU APIs like SDL3/Metal/Vulkan have subtleties where code "works" on one GPU architecture but has **undefined behavior** on another. The `STOREOP_DONT_CARE` issue (FINDING-2) is a classic example — it works fine on immediate-mode GPUs where data persists in VRAM, but silently corrupts on tile-based GPUs (Apple Silicon) where tile memory is discarded.
- File-scan (cmake) tests verify source patterns but cannot catch runtime behavioral bugs. The depth store_op issue passes all automated tests because t

[...truncated — see full log...]
