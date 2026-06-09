---
name: clipboard-vision
description: Use when the user sends images, screenshots, or visual content via chat but you cannot see them. Use when responding with [Unsupported Image]. Use when setting up automatic image description via clipboard monitoring for a text-only LLM setup. Use when the user's Claude Code cannot natively process images.
---

# Clipboard Vision

## Overview

Clipboard Vision is a background monitor that watches the system clipboard for new images, sends them to a Vision API (Doubao/Huoshan Ark), and writes the description to structured files. When installed, you automatically read these descriptions before responding — giving you vision capabilities even with a text-only model.

## Installation

When the user invokes this skill (e.g., typing `/clipboard-vision`), follow these steps:

### Step 1: Get API Key

The user needs a Doubao/火山引擎 ARK API Key:
1. Go to https://console.volcengine.com/ark
2. Sign up / log in
3. Create an API Key
4. Copy the key (starts with `ark-`)

### Step 2: Clone the Repo

```powershell
cd D:\APPtest1
git clone https://github.com/zzyb06/clipboard-vision.git
cd clipboard-vision
```

### Step 3: Run Install

```powershell
.\install.ps1
```

The installer will:
- Ask for their API Key
- Let them choose a vision model (recommended: `doubao-seed-2-0-lite-260428`)
- Test API connectivity
- Optionally set up auto-start

### Step 4: Start the Monitor

```powershell
.\src\start-vision-background.ps1
```

Verify it's running:

```powershell
.\src\stop-vision-background.ps1
# Shows if running and PID
```

### Step 5: Set Up Auto-Start (Recommended)

Add SessionStart hook to `C:\Users\<username>\.claude\settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"D:\\APPtest1\\clipboard-vision\\src\\start-vision-background.ps1\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

The installer can do this automatically.

---

## Auto-Read Protocol — MANDATORY

**After installation, you MUST follow this protocol before EVERY response when the user may have sent an image. This is NOT optional.**

### When the user sends `[Unsupported Image]` or pastes an image:

**Step 1: Check the flag file**
Check if `D:\APPtest1\clipboard-vision\output\new_image.flag` EXISTS:

- **Flag exists** -> New image detected!
  1. Read `vision_id.txt` -> this is the **baseline** (the previously completed image's ID)
  2. Poll every **500ms** up to **16 times** (8s max) until `vision_id.txt` changes from this baseline
  3. Once changed -> read `latest_vision.md` and respond as if you saw the image
  4. If ID never changes in 8s -> API still working, mention "processing your image..."

- **No flag** -> Check Step 2

**Step 2: Monitor health check**
If `[Unsupported Image]` but no flag:

1. Read PID file and check if process exists:
   ```powershell
   powershell -ExecutionPolicy Bypass -Command "gc D:\APPtest1\clipboard-vision\output\monitor.pid -ea 0 | % { if (ps $_ -ea 0) { 'Running' } else { 'Not Running' } }"
   ```
2. If NOT running -> restart:
   ```powershell
   powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\src\start-vision-background.ps1"
   ```
   Wait 3s, re-check flag.

3. If monitor IS running but no flag -> Ask user to re-paste the image (clipboard may have been overwritten).

**Step 3: Emergency fallback**
If the user insists and Steps 1-2 fail:
```powershell
powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\src\modules\emergency_vision.ps1"
```
Then read `latest_vision.md`.

---

## Management

### Start Monitor
```powershell
powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\src\start-vision-background.ps1"
```

### Stop Monitor
```powershell
powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\src\stop-vision-background.ps1"
```

### Check Status
```powershell
powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\src\stop-vision-background.ps1"
# Shows if running and PID
```

### Foreground Mode (for debugging)
```powershell
powershell -ExecutionPolicy Bypass -File "D:\APPtest1\clipboard-vision\start.ps1"
# Ctrl+C to stop
```

---

## Configuration

Edit `config.json` in the clipboard-vision directory:

| Field | Description | Default |
|-------|-------------|---------|
| `api_key` | Doubao ARK API Key | (required) |
| `model` | Vision model name | `doubao-seed-2-0-lite-260428` |
| `api_base` | API endpoint | `https://ark.cn-beijing.volces.com/api/v3/chat/completions` |
| `system_prompt` | Vision prompt | Chinese description prompt |
| `poll_interval_ms` | Poll interval | `500` |
| `output_dir` | Output directory | `output` |
| `max_history` | Log history limit | `100` |

---

## How Images Are Detected

| Method | Detection |
|--------|-----------|
| Screenshot (Win+Shift+S) -> Ctrl+V | Clipboard monitor catches instantly |
| Copy image (Ctrl+C) -> Ctrl+V | Clipboard monitor catches instantly |
| Drag & drop screenshot file | Screenshot file monitor catches (< 2s) |
| Chat [Unsupported Image] | Works if image went through clipboard |

---

## Output Files

| File | Description |
|------|-------------|
| `output/latest_vision.md` | Most recent image description (read this) |
| `output/vision_id.txt` | Current image ID (poll this for changes) |
| `output/new_image.flag` | Signal file (exists = new image pending) |
| `output/vision_log.md` | Full history of all processed images |
| `output/images/` | Saved clipboard images |

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Flag exists but ID never changes | Monitor still processing | Wait, or check monitor is alive |
| No flag after pasting | Image didn't reach clipboard | Use emergency script |
| Monitor crashes silently | PowerShell 5.1 encoding issue | Check `output/monitor.pid` is running |
| Wrong image described | Previous image still on clipboard | Check vision_id is what you expect |
| Slow response (>10s) | Polling or API delay | Verify 500ms polling in protocol |

---

## Project Structure

```
clipboard-vision/
├── CLAUDE.md              # Project-level instructions
├── config.json            # Configuration (gitignored)
├── install.ps1            # Installation script
├── start.ps1              # Foreground mode
├── src/
│   ├── monitor.ps1        # Main loop
│   ├── config.ps1         # Config loader
│   ├── start-vision-background.ps1
│   ├── stop-vision-background.ps1
│   └── modules/
│       ├── clipboard.psm1 # Clipboard handling
│       ├── vision_api.psm1# Vision API client
│       ├── window.psm1    # Window detection
│       └── logger.psm1    # Log writer
├── docs/
└── output/                # Output files (gitignored)
    ├── latest_vision.md
    ├── vision_id.txt
    ├── new_image.flag
    └── images/
```
