# Clipboard Vision

A background tool that monitors clipboard images when Claude Code is the active window,
describes them via 豆包/火山引擎 Vision API, and writes structured descriptions to the
output directory for Claude Code to consume automatically.

## Auto-reading image descriptions

**Before each response**, always check so you have the latest visual context:

1. Read `output/vision_id.txt` to get the current image ID
2. **If the ID matches the last one you processed**: the monitor may be processing
   a newly pasted image (API takes ~10 seconds). Poll up to 4 times with 3-second
   intervals:
   - 1st check (3s): ID still same → wait again
   - 2nd check (6s): ID still same → wait again
   - 3rd check (9s): ID still same → wait again
   - 4th check (12s): ID still same → give up, no new image this turn
   - Any check shows a new ID → proceed to step 3 immediately
3. **If the ID changed** (or no "last ID"):
   - Read `output/latest_vision.md` — it always contains the complete description
   - Treat the description as visual context the user provided — respond as if you
     saw the image yourself, referencing its contents naturally
   - Update your "last ID" for next time

## Start / Stop

- **Auto-start**: The monitor launches automatically when Claude Code starts (via
  `SessionStart` hook in `~/.claude/settings.json`)
- **Stop**: Run `.\src\stop-vision-background.ps1` to stop the background monitor
- **Foreground mode**: Run `.\start.ps1` for visible monitoring with console logs

## Configuration

Edit `config.json`:
- `api_key`: 豆包/火山引擎 ARK API Key
- `model`: Vision model name (e.g., `doubao-seed-2-0-lite-260428`)
- `system_prompt`: Prompt sent to the vision API (in Chinese)
- `poll_interval_ms`: Clipboard poll interval (default 2000ms)
- `claude_code_window_keywords`: Keywords to detect Claude Code window

## Output files

| File | Description |
|------|-------------|
| `output/vision_log.md` | Append-only history of all processed images |
| `output/latest_vision.md` | Only the most recent image description (overwritten each time) |
| `output/vision_id.txt` | Current image ID (for change detection) |
| `output/images/` | Saved clipboard images |

## Project structure

```
clipboard-vision/
├── CLAUDE.md              ← you are here
├── config.json
├── start.ps1
├── install.ps1
├── src/
│   ├── monitor.ps1        # Main loop
│   ├── config.ps1         # Config loader
│   └── modules/
│       ├── window.psm1    # Foreground window detection
│       ├── clipboard.psm1 # Clipboard image handling
│       ├── vision_api.psm1# 豆包 Vision API client
│       └── logger.psm1    # Log writer
├── docs/
└── output/
    ├── vision_log.md
    ├── latest_vision.md
    ├── vision_id.txt
    └── images/
```
