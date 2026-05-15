# Trae Agent

AI 编码助手 — 本地 LLM 驱动的 Agent App（TRAE 风格复刻版）

## 功能

- 对话式 AI 编码助手
- 自定义 LLM API（DeepSeek / OpenAI / 任何兼容端点）
- 流式输出
- 6 种工具（读文件、写文件、搜索代码、终端命令、Git、目录浏览）
- 多轮工具调用
- 文件树浏览器
- Markdown + 代码语法高亮
- 多会话管理

## 技术栈

UI: Flutter + Material 3
状态管理: Provider
LLM API: OpenAI 兼容格式（HTTP + SSE 流式）
工具执行: Dart Process

## 编译

```bash
# 环境要求: Flutter >=3.2.0, Android SDK 34, Java 17+
cd trae_agent
flutter pub get
flutter build apk --release
# 输出: build/app/outputs/flutter-apk/app-release.apk
```

## 首次使用

1. 侧边栏 Settings → 选择 API Provider（DeepSeek/OpenAI/Groq/自定义）
2. 填入 API Key
3. Test Connection 验证
4. 回到 Chat 开始对话

## 色板

TRAE 风格深色主题：#1A1A2E 背景，#4079FF 蓝色强调
