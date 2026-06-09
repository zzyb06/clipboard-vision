# Vision Recognition Speed Optimization Design

- **Date**: 2026-06-09
- **Project**: clipboard-vision
- **Goal**: Reduce round-trip time from image paste to AI response from ~50-60s to ≤10s

## Problem Analysis

Current timing breakdown (measured ~50-60s total):

| Phase | Current Time | Notes |
|-------|-------------|-------|
| Monitor detects image, calls API | ~3-5s | OK, baseline |
| API identifies image | ~3-5s | Can be reduced |
| User sends message, Claude checks flag | ~0s | Instant |
| Polling: 2s interval × up to 10 rounds | ~2-20s | Major waste — API often done before user sends |
| Claude reads result and responds | ~1-2s | OK |

### Root Causes

1. **Polling protocol is slow**: Fixed 2s interval starts from scratch, doesn't check if result already ready.
2. **API conservative settings**: 30s timeout, 3 retries, 2048 max_tokens — all oversized for screenshot descriptions.
3. **No look-before-you-poll**: Even when API finishes before the user sends their message, the polling loop still waits for a full interval.

## Optimization Design

### 1. Polling Protocol — "Look Before You Poll" (CLAUDE.md)

**Current behavior:**
```
Flag exists → start 2s interval polling × up to 10 rounds (max 20s)
```

**New behavior:**
```
Flag exists → IMMEDIATELY read vision_id.txt
  → If ID already changed → read latest_vision.md → respond immediately
  → If ID unchanged → start 500ms interval polling × up to 16 rounds (max 8s)
```

**Changes:**
- Add immediate ID check before starting the polling loop
- Reduce polling interval: 2s → 500ms
- Reduce max wait: 20s → 8s (16 tries × 500ms)

**Expected savings: 2-15s** (depends on how often API finishes before user sends)

### 2. API Acceleration (vision_api.psm1)

| Parameter | Before | After | Rationale |
|-----------|--------|-------|-----------|
| `max_tokens` | 2048 | 512 | Screenshot descriptions fit in ~200-300 chars; shorter output = faster generation |
| `TimeoutSec` | 30 | 15 | 15s is plenty for vision API on a single PNG |
| Retry count | 3 | 2 | 2 failures is enough signal; removes 1 retry delay (up to 10s saved) |
| System prompt | verbose | append conciseness instruction | `vision_api.psm1` internally appends "请简洁描述，控制在300字以内" to the user's system prompt, rather than modifying config.json |

**Expected savings: 2-5s** (normal case: ~2s faster API response)

### 3. Files Changed

| File | Type of change |
|------|---------------|
| `D:\APPtest1\clipboard-vision\CLAUDE.md` | Rewrite polling section: look-before-you-poll + 500ms + 8s max |
| `C:\Users\14793\.claude\CLAUDE.md` | Same polling rewrite (global instructions) |
| `C:\Users\14793\CLAUDE.md` | Same polling rewrite (project instructions) |
| `D:\APPtest1\clipboard-vision\src\modules\vision_api.psm1` | Change 3 numeric params + append conciseness to system prompt internally |

### Expected Results

| Scenario | Before | After |
|----------|--------|-------|
| Best case (API done before send) | ~10s (wait at least 1 poll cycle) | ~1-2s (immediate read) |
| Typical case (API mid-flight) | ~25-35s | ~3-5s |
| Worst case (send immediately after paste) | ~50-60s | ~8-10s |

### Not Changed

- `monitor.ps1` — monitoring logic unchanged
- `clipboard.psm1` — image handling unchanged
- Screenshot file monitoring — unchanged
- Emergency fallback script — unchanged

## Verification

After implementation, measure with real usage:
1. Send an image, count seconds from "send" to first correct mention of image content
2. Verify timeout/recovery still works (disconnect network mid-request)
3. Verify still catches images via both clipboard and screenshot file monitoring
