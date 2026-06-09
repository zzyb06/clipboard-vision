# Clipboard Vision — Auto-Context Integration

**Date**: 2026-06-09
**Status**: Approved

## Problem

Claude Code (connected to DeepSeek text-only model) cannot see images. The clipboard-vision
monitor describes clipboard images via 豆包 Vision API and writes to a log file, but Claude Code
does not automatically read these descriptions. The user must manually reference the log.

## Solution

Two changes:

### 1. Monitor: Add `latest_vision.md` + `vision_id.txt`

After each successful API response, in addition to appending `vision_log.md` (history), also
overwrite `output/latest_vision.md` and `output/vision_id.txt` with just the latest result.

This gives Claude Code a stable file to read that always contains the most recent image
description, without needing to parse the growing history file.

**`output/latest_vision.md` format:**
```markdown
<!-- vid: 20260609_091234 -->
# Latest Clipboard Image

[description from 豆包 Vision API]
```

**`output/vision_id.txt` format:**
```
20260609_091234
```

### 2. New file: `CLAUDE.md` (project root)

Contains instructions for Claude Code to automatically read the latest vision result
before responding:

> Before each response, check `output/vision_id.txt`. If its content differs from the
> last known value, read `output/latest_vision.md` and treat the description as visual
> context for the user's current message — as if you saw the image yourself.

Claude Code tracks state across turns naturally, so no external tracking file is needed
for "what was already read".

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `src/modules/logger.psm1` | Add function | `Write-LatestVision(file, content)` — overwrites `latest_vision.md` + `vision_id.txt` |
| `src/monitor.ps1` | Modify | After successful API call, also call `Write-LatestVision` |
| `CLAUDE.md` | Create | Project-level instruction for automatic vision context |

## Workflow

```
User copies image (Win+Shift+S)
  → clipboard-vision detects → 豆包 API → latest_vision.md
  → User messages Claude Code
  → Claude Code reads vision_id.txt (changed? → reads latest_vision.md)
  → Claude Code responds with image context understood
```

## Non-goals

- No conversation injection via hooks (hooks cannot modify prompts)
- No change to the window detection logic
- No change to existing vision_log.md history behavior
