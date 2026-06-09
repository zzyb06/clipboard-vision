# Clipboard Vision

A background tool that monitors clipboard images when Claude Code is the active window,
describes them via 豆包/火山引擎 Vision API, and writes structured descriptions to the
output directory for Claude Code to consume automatically.

## Auto-reading image descriptions

**Before each response**, always do this check so you have the latest visual context:

1. Read `output/vision_id.txt` to get the current image ID
2. If the ID matches the last one you processed → no new image, skip
3. If the ID changed (or you have no "last ID") → read `output/latest_vision.md`
4. Treat the description as visual context the user has provided — respond as if you
   saw the image yourself, referencing its contents naturally

This ensures you always see what the user is showing you without them having to
explicitly describe it.

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
