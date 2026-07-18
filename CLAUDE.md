# CLAUDE.md

## 项目概述

KeySoil（按键沃土）是一款 macOS 原生桌面陪伴应用，使用 Swift + SwiftUI + SpriteKit 构建。用户在正常使用键盘打字时，每次按键都会驱动虚拟像素农场中的作物生长。农场以**键盘配列**的形式呈现在透明悬浮窗口中——每个物理按键对应一块土壤，常用键作物茂盛，冷门键维持荒芜，形成自然的打字热力图。

## 技术栈

- **语言**: Swift 6 (语言模式 Swift 5)
- **UI 框架**: SwiftUI + AppKit (NSPanel, NSStatusItem)
- **动画**: SpriteKit (SKScene + NSViewRepresentable)
- **键盘监听**: CoreGraphics CGEvent tap (listen-only) + Accessibility API
- **构建系统**: Swift Package Manager (swift-tools-version: 6.0)
- **目标平台**: macOS 14+
- **持久化**: JSON 文件 (`~/Library/Application Support/TypingFarmerMac/state.json`)
- **测试**: XCTest + precondition-based self-test executables

## 项目结构

```
Sources/
├── TypingFarmerCore/              # 平台无关核心逻辑
│   ├── Models.swift               # 全部数据模型 (GameState, CropDef, KeyPlotState,
│   │                              #   KeyboardLayout, PetState, DailyStats, FarmTask 等)
│   ├── FarmEngine.swift           # 游戏引擎 (apply, harvest, plant, unlock, pet, task)
│   └── PomodoroTimerModel.swift   # 番茄钟纯值模型
│
├── TypingFarmerMacSupport/        # macOS 平台支持
│   ├── AppPersistence.swift       # JSON 持久化 + 版本迁移
│   └── MacKeyboardLayout.swift    # KeyboardLayout 重导出门面
│
├── TypingFarmerMac/               # macOS 应用主体
│   ├── main.swift                 # 入口 (支持 --snapshot 模式)
│   ├── AppDelegate.swift          # 窗口管理 + 菜单栏 + BGM
│   ├── AppViewModel.swift         # @MainActor ViewModel (状态管理 + 宠物自动收获)
│   ├── InputMonitor.swift         # CoreGraphics 全局键盘监听
│   ├── FarmPopoverView.swift      # 全部 SwiftUI 视图 (HUD, 键盘农场, 种子栏, 控制面板)
│   ├── FarmSpriteLayer.swift      # SpriteKit 动画层 (宠物, 粒子, 收获动画)
│   ├── SnapshotRenderer.swift     # 离线 UI 快照渲染
│   └── Resources/                 # 美术资源 + BGM (SPM Bundle)
│
├── TypingFarmerCoreSelfTest/      # Core 独立自测
└── TypingFarmerMacSupportSelfTest/ # MacSupport 独立自测

Tests/
├── TypingFarmerCoreTests/         # 核心逻辑测试
└── TypingFarmerMacSupportTests/   # 持久化测试
```

## 模块依赖

```
TypingFarmerCore (无依赖)
  ├── TypingFarmerMacSupport
  └── TypingFarmerMac (依赖 Core + MacSupport)
```

## 核心设计决策

- **键盘即农场**：每个物理按键就是一块土壤。按下哪个键就浇灌哪块地。常用键（如 E、T、A、O）自然茂盛，冷门键（如 Z、Q）自然荒芜。
- **原生 macOS**：使用 NSPanel 实现透明悬浮窗口，SwiftUI 负责声明式 UI 布局，SpriteKit 处理精灵动画和粒子效果。
- **安全隐私**：InputMonitor 使用 listen-only CGEvent tap，仅传递物理 keyCode，不传递实际字符。应用完全离线。
- **三层模块**：Core（平台无关逻辑）→ MacSupport（macOS 持久化）→ Mac（应用 UI），保持核心逻辑可独立测试。

## 常用命令

```bash
make build       # swift build
make release     # swift build -c release
make test        # swift test
make selftest    # 运行两个 self-test 可执行文件
make run         # swift run TypingFarmerMac
make clean       # swift package clean
```

## 快照验证

```bash
swift run TypingFarmerMac -- --snapshot /tmp/snapshot.png
# 可选: --snapshot-width 1040 --snapshot-height 680
```

生成包含预设游戏状态的 UI 快照 PNG，用于视觉回归测试。

## 实现计划

完整实现计划与 6 人分工方案参见 `docs/design.md`。
