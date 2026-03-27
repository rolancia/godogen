---
name: godogen
description: |
  This skill should be used when the user asks to "make a game", "build a game", "generate a game", or wants to generate or update a complete Godot game from a natural language description.
---

# Game Generator — Orchestrator

Generate and update Godot games from natural language.

## Capabilities

Read each sub-file from `.agents/skills/godogen/` when you reach its pipeline stage. Do not improvise a pipeline stage before reading its file.

| File | Purpose |
|------|---------|
| `visual-target.md` | Generate reference image anchoring art direction |
| `decomposer.md` | Decompose game into a development plan (`PLAN.md`) |
| `scaffold.md` | Design architecture and produce compilable Godot skeleton |
| `asset-planner.md` | Decide what assets the game needs within a budget |
| `asset-gen.md` | Generate PNGs (xAI Grok) and GLBs (Tripo3D) from prompts |
| `rembg.md` | Background removal guide — read before any rembg operation |

## Pipeline

```
User request
    |
    +- If PLAN.md does not exist and the current user message does not contain
    |  a concrete game description or change request:
    |   +- Ask the user what game to make
    |   +- Stop. Do not infer a game from the repo name, folder name, or existing files alone
    |
    +- Check if PLAN.md exists (resume check)
    |   +- If yes: read PLAN.md, STRUCTURE.md, MEMORY.md -> skip to task execution
    |   +- If no: continue with fresh pipeline below
    |
    +- Read visual-target.md -> generate reference.png + ASSETS.md (art direction only)
    +- Read decomposer.md -> decompose into tasks -> PLAN.md
    +- Read scaffold.md -> design architecture -> STRUCTURE.md + project.godot + stubs
    |
    +- If budget provided (and no asset tables in ASSETS.md):
    |   +- Read asset-planner.md and asset-gen.md
    |   +- Plan and generate assets -> ASSETS.md + updated PLAN.md with asset assignments
    |
    +- For every task in PLAN.md:
    |   +- Set `**Status:** pending`
    |   +- Fill `**Targets:**` with concrete project-relative files expected to change
    |     (e.g. scenes/main.tscn, scripts/player_controller.gd, project.godot)
    |     inferred from task text + scene/script mappings in STRUCTURE.md
    |
    +- Show user a concise plan summary (game name, numbered task list)
    |
    +- Find next ready task (pending, deps all done)
    +- While a ready task exists:
    |   +- Update PLAN.md: mark task status -> in_progress
    |   +- Run `$godot-task` with task block
    |   +- Mark task completed in PLAN.md OR replan based on the outcome, summarize to user
    |   +- git add . && git commit -m "Task N done"
    |   +- Find next ready task
    |
    +- Summary of completed game
```

PLAN.md task `**Status:**`: one of `pending`, `in_progress`, `done`, `done (partial)`, `skipped`.

## Hard Rules

- Before creating `reference.png`, read `visual-target.md` and use its CLI path. Do not hand-draw, sketch, or create a placeholder reference image unless the user explicitly asks for that.
- Before generating any PNG, MP4, or GLB asset, read `asset-gen.md`. If `.agents/skills/godogen/tools/asset_gen.py` exists, try it before inventing another generator or fallback workflow.
- If an asset generation command fails, surface the actual command and failure to the user instead of silently switching to a different approach.
- Before any background removal step, read `rembg.md`.

## Running Tasks

Each task runs via `$godot-task`. Pass the full task block from PLAN.md as the skill argument:

```
$godot-task with argument:
  ## N. {Task Name}
  - **Status:** in_progress
  - **Targets:** scenes/main.tscn, scripts/player_controller.gd
  - **Goal:** ...
  - **Requirements:** ...
  - **Verify:** ...
```

## Mid-Pipeline Recovery

- **Reset scenes/scripts** — regenerate project skeleton when a task has corrupted or outgrown the architecture.
- **Rewrite the plan** — edit PLAN.md when a task reveals the approach is wrong or new requirements emerge.
- **Generate or regenerate assets** — create new assets or fix broken ones mid-run.

## Visual QA

Visual QA runs inside godot-task — each task handles its own VQA cycle. The task agent reports a VQA report path alongside screenshots. **Never ignore a fail verdict** — always act on it before marking a task done.

- **pass/warning** — move on.
- **fail** — godot-task already attempted up to 3 fix cycles. Read its failure report (includes VQA issues and root cause hypothesis) and decide:
  - **Replan** — reset architecture, rewrite plan, and/or regenerate assets if the root cause is upstream.
  - **Escalate** — surface the issue to the user if you can't determine the right fix.

The final task in PLAN.md is a presentation video — a script that showcases gameplay in a ~30-second cinematic MP4.

## Debugging

If a task reports failure or you suspect integration issues:
- Read `MEMORY.md` — task execution logs discoveries and workarounds
- Read screenshots in `screenshots/{task_folder}/`
- Run `timeout 30 godot --headless --quit 2>&1` to check cross-project compilation
