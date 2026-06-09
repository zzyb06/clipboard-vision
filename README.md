# Clipboard Vision

当 Claude Code 接入 DeepSeek 等纯文本模型时，通过 **豆包/火山引擎 Vision API** 让对话具备图片理解能力。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Claude Code Skill

本项目包含一个 Claude Code **一键安装 skill**，方便其他用户快速部署：

```
/clipboard-vision
```

Skill 位于 [`skills/clipboard-vision/SKILL.md`](skills/clipboard-vision/SKILL.md)，安装后 Claude Code 会自动识别图片——`[Unsupported Image]` 不再出现。

**安装 skill：**
```powershell
# 复制 skill 到 Claude Code 的 skills 目录
xcopy /E skills\clipboard-vision %USERPROFILE%\.claude\skills\clipboard-vision\
```
然后在 Claude Code 中输入 `/clipboard-vision` 按提示操作即可。

## 功能

- 📸 **自动识图** — 截图后直接粘贴到聊天框，Claude Code 自动读取描述
- 🔄 **后台运行** — 随 Claude Code 自启，隐藏窗口静默工作
- 🪟 **智能触发** — 仅在 Claude Code 窗口激活时工作，不打扰其他操作
- 🚫 **去重保护** — 相同图片不会重复处理
- 🔌 **纯 PowerShell** — 无外部依赖，Windows 10/11 原生运行

## 工作原理

```
你截图/复制图片
    ↓ 进入剪贴板
后台监控器 (每2秒轮询)
    ↓ 检测到新图
豆包 Vision API
    ↓ 返回描述
latest_vision.md ← vision_id.txt
    ↓
Claude Code 回复前自动读取 → 准确回答
```

## 前置条件

- **Windows 10/11** + PowerShell 5.1+
- **豆包/火山引擎 API Key** — [免费申请](https://console.volcengine.com/ark)
- **Claude Code** — 已接入 DeepSeek 或其他纯文本模型

## 快速开始

### 1. 安装

```powershell
git clone https://github.com/<你的用户名>/clipboard-vision.git
cd clipboard-vision
.\install.ps1
```

安装脚本引导你：
1. 输入 API Key
2. 选择视觉模型（推荐 `doubao-seed-2-0-lite-260428`）
3. 自动测试 API 连通性
4. 可选：添加开机启动

### 2. 配置自启（推荐）

安装后运行以下命令，让监控器随 Claude Code 自动启动：

```powershell
.\src\start-vision-background.ps1
```

或者手动在 Claude Code 全局配置 `C:\Users\<用户名>\.claude\settings.json` 中添加：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -ExecutionPolicy Bypass -File \"D:\\path\\to\\clipboard-vision\\src\\start-vision-background.ps1\"",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

配置后每次 `claude` 启动，监控器会自动在后台拉起。

### 3. 日常使用

想给 Claude Code 看图片时：

1. **截图**（Alt+A / Win+Shift+S）或 **复制图片**（浏览器右键 → 复制图片）
2. **Ctrl+V 粘贴到聊天框**，发送消息
3. Claude Code 自动读取视觉结果并回答

> ⚠️ 无需手动上传图片到聊天。图片进剪贴板即被监控器处理。

## 手动启动/停止

### 前台模式（看日志）

```powershell
.\start.ps1
```
按 `Ctrl+C` 停止。

### 后台模式

```powershell
# 启动
.\src\start-vision-background.ps1

# 停止
.\src\stop-vision-background.ps1
```

### 查看当前状态

```powershell
.\src\stop-vision-background.ps1  # 会显示是否正在运行
```

## 配置

编辑 `config.json`：

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `api_key` | 豆包 API Key | — |
| `model` | 视觉模型名 | `doubao-seed-2-0-lite-260428` |
| `api_base` | API 端点 | `https://ark.cn-beijing.volces.com/api/v3/chat/completions` |
| `system_prompt` | 识别提示词 | 中文详细描述 |
| `poll_interval_ms` | 轮询间隔（毫秒） | `500` |
| `claude_code_window_keywords` | 窗口匹配关键词 | `["Claude Code", "claude"]` |
| `output_dir` | 输出目录 | `output` |
| `max_history` | 日志保留条数 | `100` |

> ⚠️ `config.json` 包含 API Key，已在 `.gitignore` 中排除，不会被提交到仓库。

## 输出文件

| 文件 | 说明 |
|------|------|
| `output/vision_log.md` | 所有图片的识别历史记录 |
| `output/latest_vision.md` | 最新一张图片的描述（每次覆盖） |
| `output/vision_id.txt` | 当前图片 ID（用于检测是否有新图） |
| `output/images/` | 保存的剪贴板图片 |

## 卸载

### 1. 停止监控器

```powershell
cd clipboard-vision
.\src\stop-vision-background.ps1
```

### 2. 移除 Claude Code 自启配置

编辑 `C:\Users\<用户名>\.claude\settings.json`，删除 `hooks` 部分（或仅删除 `SessionStart` 相关配置）。

### 3. 移除全局 CLAUDE.md 指令

编辑以下文件，删除其中的 "Clipboard Vision" 相关段落：
- `C:\Users\<用户名>\.claude\CLAUDE.md`
- `C:\Users\<用户名>\CLAUDE.md`

### 4. 移除开机启动（如已设置）

```powershell
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\ClipboardVision.lnk"
if (Test-Path $lnk) { Remove-Item $lnk }
```

### 5. 删除项目文件夹

```powershell
cd ..
Remove-Item -Recurse -Force clipboard-vision
```

## 项目结构

```
clipboard-vision/
├── CLAUDE.md                 # 项目级自读图指令
├── config.json               # 配置（含 API Key，已 gitignore）
├── install.ps1               # 安装引导
├── start.ps1                 # 前台启动
├── src/
│   ├── monitor.ps1           # 主循环（轮询剪贴板 + 调 API）
│   ├── config.ps1            # 配置读取
│   ├── start-vision-background.ps1  # 后台启动
│   ├── stop-vision-background.ps1   # 后台停止
│   └── modules/
│       ├── window.psm1       # 前台窗口检测
│       ├── clipboard.psm1    # 剪贴板操作
│       ├── vision_api.psm1   # 豆包 Vision API 调用
│       └── logger.psm1       # 日志输出
├── docs/                     # 设计文档
├── skills/                   # Claude Code skill
│   └── clipboard-vision/
│       └── SKILL.md          # 一键安装 skill
└── output/                   # 输出（已 gitignore）
    ├── vision_log.md
    ├── latest_vision.md
    ├── vision_id.txt
    └── images/
```

## License

MIT
