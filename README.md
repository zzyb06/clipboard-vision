# Clipboard Vision

当 Claude Code 接入 DeepSeek V4 Flash 等纯文本模型时，通过豆包 Vision API 为对话补充图片理解能力。

## 工作原理

```
你截图 → 剪贴板 → monitor.ps1 检测到新图 → 豆包 Vision API → 结果写入 vision_log.md → Claude Code 读取并理解
```

后台监控脚本 `monitor.ps1` 每 2 秒检查一次：
1. 当前前台窗口是不是 Claude Code？（避免误触发）
2. 剪贴板里有没有新图片？（hash 去重）
3. 有 → 自动调豆包 API 识别 → 结果写入 `output/vision_log.md`

## 前置条件

- Windows 10/11
- PowerShell 5.1+
- 豆包/火山引擎 API Key（[申请地址](https://console.volcengine.com/ark)）

## 安装

```powershell
git clone <your-repo-url>
cd clipboard-vision
.\install.ps1
```

安装脚本会引导你：
1. 输入 API Key
2. 输入视觉模型名称
3. 测试 API 连通性
4. 可选：添加开机启动

## 使用

```powershell
.\start.ps1
```

监控窗口会保持打开，显示日志输出。按 `Ctrl+C` 停止。

### 后台运行

创建 PowerShell 快捷方式，参数：
```
-WindowStyle Hidden -File "D:\APPtest1\clipboard-vision\src\monitor.ps1"
```

或在 `install.ps1` 中选择添加开机启动。

## 配置

编辑 `config.json`：

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `api_key` | 豆包 API Key | — |
| `model` | 视觉模型名 | `doubao-vision-pro-32k` |
| `api_base` | API 端点 | 火山引擎北京节点 |
| `system_prompt` | 识别提示词 | 见模板 |
| `poll_interval_ms` | 轮询间隔 | 2000 |
| `claude_code_window_keywords` | 窗口匹配关键词 | ["Claude Code", "claude"] |
| `output_dir` | 输出目录 | output |
| `max_history` | 日志保留条数 | 100 |

## 输出

`output/vision_log.md` — 每条记录格式：

```markdown
## 2026-06-08 21:30:00 | clip_20260608_213000.png
---
[豆包返回的图片描述]
---
```

Claude Code 的 system prompt 会自动读取这个文件的最新条，在对话中理解图片内容。

## 项目结构

```
clipboard-vision/
├── config.json               # 配置
├── install.ps1               # 安装引导
├── start.ps1                 # 启动
├── src/
│   ├── monitor.ps1           # 主循环
│   ├── config.ps1            # 配置读取
│   └── modules/
│       ├── window.psm1       # 窗口检测
│       ├── clipboard.psm1    # 剪贴板操作
│       ├── vision_api.psm1   # 豆包 API
│       └── logger.psm1       # 日志输出
└── output/
    ├── vision_log.md         # 识别日志
    └── images/               # 历史截图
```

## License

MIT
