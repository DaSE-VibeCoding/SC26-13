# KeySoil (按键沃土) — 实现规划设计文档

## 背景

KeySoil 是一款 **macOS 原生桌面陪伴应用**。用户在正常使用键盘工作时，每一次按键都会转化为虚拟农场中的成长行为。应用通过透明悬浮窗口展示按**键盘配列排布的小型像素农场**——每个按键对应一块土壤，该按键被按下的频率直接影响对应土壤中作物的生长状态。

**核心理念**：打字即耕耘。常按的键作物茂盛，少用的键维持荒芜，键盘即农场。

**技术栈**：Swift 6 (语言模式 Swift 5) + SwiftUI + SpriteKit + Swift Package Manager

**目标平台**：macOS 14+

---

## 1. 美术资源需求

所有美术资源存放在 `Sources/TypingFarmerMac/Resources/` 中，由 SPM 自动打包为 `Bundle.module`。

### 1.1 键盘土壤纹理

键帽形状的土壤纹理，4 个阶段（干裂→湿润→肥沃→黑土），每阶段 4 种宽度变体（1×/1.5×/2.2×/4.8×）适配不同按键。

### 1.2 作物精灵

| 作物 | 生长需求 | 售价 | 解锁价 |
|------|---------|------|-------|
| 小麦 🌾 | 24 键 | 8 金币 | 免费 |
| 番茄 🍅 | 45 键 | 18 金币 | 50 金币 |
| 玉米 🌽 | 75 键 | 35 金币 | 140 金币 |
| 草莓 🍓 | 120 键 | 65 金币 | 320 金币 |

每种 4 个生长阶段精灵 + 合并版。

### 1.3 宠物动画

小狗 (idle/run×4/collect/rest/sleep/prone) 和小猫 (idle/run×4/collect/rest)，可巡逻并自动收获。

### 1.4 其他资源

金币图标、收获徽章、农场背景、背景音乐 (bgm.mp3)。

---

## 2. 架构总览

```
macOS 原生应用 (单进程)
│
├── InputMonitor (CoreGraphics CGEvent tap, listen-only)
├── NSPanel (透明悬浮窗口) + NSStatusItem (菜单栏图标)
├── AppViewModel (@MainActor ObservableObject, 状态管理中枢)
│
├── SwiftUI 视图层
│   ├── FarmGameWindowView (背景 + HUD + 键盘农场 + 种子栏)
│   ├── FarmControlPanelView (统计/商店/宠物/番茄钟/设置)
│   └── FarmSpriteLayer (SpriteKit overlay: 宠物动画/粒子/收获动画)
│
└── TypingFarmerCore (平台无关核心逻辑)
    ├── Models (GameState, CropDef, KeyPlotState, KeyboardLayout...)
    ├── FarmEngine (apply/harvest/plant/unlock/pet/task)
    └── PomodoroTimerModel
```

### 模块依赖

```
TypingFarmerCore (无依赖)
  ├── TypingFarmerMacSupport (持久化 + 键盘布局桥接)
  └── TypingFarmerMac (应用主体, 依赖 Core + MacSupport)
```

---

## 3. 核心机制

- **按键 → 生长**：CoreGraphics 事件 → InputMonitor → AppViewModel → FarmEngine.apply() → 对应键位 progress+1
- **收获**：点击成熟地块 / 宠物自动收获 (24s 间隔) → 加金币 → 重置 → 重新播种
- **作物升级**：金币解锁高级作物，选中后新播种使用该作物
- **隐私**：仅传递物理 keyCode，不记录字符内容，完全离线

---

## 4. 项目结构

```
Sources/
├── TypingFarmerCore/              # 平台无关核心
│   ├── Models.swift               # 全部数据模型 + 键盘布局
│   ├── FarmEngine.swift           # 游戏引擎
│   └── PomodoroTimerModel.swift   # 番茄钟模型
├── TypingFarmerMacSupport/        # macOS 平台支持
│   ├── AppPersistence.swift       # JSON 持久化
│   └── MacKeyboardLayout.swift    # 键盘布局桥接
├── TypingFarmerMac/               # macOS 应用
│   ├── main.swift                 # 入口
│   ├── AppDelegate.swift          # 窗口/菜单栏/BGM
│   ├── AppViewModel.swift         # ViewModel 状态管理
│   ├── InputMonitor.swift         # 全局键盘监听
│   ├── FarmPopoverView.swift      # 全部 SwiftUI 视图
│   ├── FarmSpriteLayer.swift      # SpriteKit 动画层
│   ├── SnapshotRenderer.swift     # 快照渲染
│   └── Resources/                 # 美术资源 + BGM
├── TypingFarmerCoreSelfTest/      # Core 自测
└── TypingFarmerMacSupportSelfTest/ # MacSupport 自测
Tests/
├── TypingFarmerCoreTests/
└── TypingFarmerMacSupportTests/
```

---

## 5. 实现分工（6 人并行）

本项目由 **6 名成员**并行协作完成。先由任意一人提交项目骨架（Package.swift + 目录结构），之后 6 人各自从 main 拉分支并行开发，最后按顺序合并。

### 工作流程

```
1. 预提交骨架 (任意一人)：Package.swift + Makefile + 空目录结构
2. 6 人各建分支，并行复制/开发各自负责的文件
3. 按编号顺序合并分支到 main（保证编译依赖）
```

### 分工表

| 成员 | 模块 | 负责文件 | 分支名 |
|------|------|---------|--------|
| 1 | 数据模型 | `Models.swift`, `main.swift` | `feat/models` |
| 2 | 核心引擎 + 番茄钟 | `FarmEngine.swift`, `PomodoroTimerModel.swift`, `CoreTests.swift`, `CoreSelfTest/main.swift` | `feat/engine` |
| 3 | 平台支持 + 输入监听 | `AppPersistence.swift`, `MacKeyboardLayout.swift`, `InputMonitor.swift`, `PersistenceTests.swift`, `MacSupportSelfTest/main.swift` | `feat/platform` |
| 4 | 应用框架 + 状态管理 | `AppDelegate.swift`, `AppViewModel.swift` | `feat/app-framework` |
| 5 | UI 视图层 | `FarmPopoverView.swift`, `SnapshotRenderer.swift` | `feat/ui` |
| 6 | 动画系统 + 美术资源 | `FarmSpriteLayer.swift`, `Resources/Art/*.png`, `Resources/bgm.mp3` | `feat/animation` |

### 合并顺序

```
main (骨架) ← feat/models (1)
           ← feat/engine (2)
           ← feat/platform (3)
           ← feat/app-framework (4)
           ← feat/ui (5)
           ← feat/animation (6)
```

---

## 6. 验证方案

```bash
make build      # 编译通过
make test       # 单元测试通过
make selftest   # 自测可执行文件通过
make run        # 应用启动，打字驱动农场生长
```
