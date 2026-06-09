# Clipboard Vision

A background tool that monitors clipboard images and describes them via
豆包/火山引擎 Vision API. Results are written to structured files for Claude Code
to consume automatically.

Images are detected **instantly** (500ms polling) regardless of whether Claude Code
is the active window. Processing happens as soon as Claude Code becomes active.

## Auto-reading image descriptions — MANDATORY

**You MUST do this before EVERY response WITHOUT FAIL:**

Check `D:\APPtest1\clipboard-vision\output\new_image.flag`

- **If the file EXISTS**: The user just copied/pasted a new image!
  - Poll `vision_id.txt` every **2 seconds** up to **10 times** (20s) until the ID changes
  - Once changed → read `latest_vision.md` and respond as if you saw the image
  - If ID never changes in 20s → the API is still working, respond normally but mention "processing your image..."
  
- **If the file DOES NOT EXIST**: No new image, skip.

> **Why this matters**: The flag file is created the INSTANT an image enters the clipboard and deleted only after the description is fully written. If you skip this check, you will miss images the user sent.

## Start / Stop

- **Auto-start**: The monitor launches automatically when Claude Code starts (via
  `SessionStart` hook in `~/.claude/settings.json`)
- **Stop**: Run `.\src\stop-vision-background.ps1` to stop the background monitor
- **Foreground mode**: Run `.\start.ps1` for visible monitoring with console logs
- **Status check**: Run `.\src\stop-vision-background.ps1` (shows if running)

## How images are detected

| How you send the image | Detection mechanism |
|---|---|
| Screenshot (Win+Shift+S) → Ctrl+V paste | Clipboard monitor catches instantly |
| Copy image (Ctrl+C) → Ctrl+V paste | Clipboard monitor catches instantly |
| Drag & drop image file | Image must be on clipboard — same as paste |
| Chat "[Unsupported Image]" | Only works if image went through clipboard first |

**For best results**: screenshot or copy the image, then Ctrl+V paste into chat.

## Configuration

Edit `config.json`:
- `api_key`: 豆包/火山引擎 ARK API Key
- `model`: Vision model name (e.g., `doubao-seed-2-0-lite-260428`)
- `system_prompt`: Prompt sent to the vision API (in Chinese)
- `poll_interval_ms`: Clipboard poll interval (default 500ms)
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
│   ├── monitor.ps1        # Main loop (improved: always watches clipboard)
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
