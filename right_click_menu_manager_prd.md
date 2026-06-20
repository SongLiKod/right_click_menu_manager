# Windows 右键菜单管理器 — 产品需求文档

> 版本：v2.0
> 日期：2026-06-21
> 目标平台：Windows 11（兼容 Windows 10）
> UI 框架：Flutter 3.x + fluent_ui + win32
> 语言：Dart

---

## 1. 产品背景与目标

### 1.1 痛点

- Windows 11 引入两级右键菜单（紧凑菜单 + 经典菜单），但系统未提供自定义两级菜单布局的界面
- 常用工具（7-Zip、WinRAR、VS Code 等）默认只出现在经典菜单，用户需多点击一次
- 现有第三方工具界面老旧、不支持 Win11 两级菜单管理、长期停更
- 直接改注册表学习成本高、风险大

### 1.2 核心目标

聚焦三个核心需求：

1. **查看 & 管理**所有已注册的右键菜单项
2. **移动**菜单项在紧凑菜单和经典菜单之间切换
3. **一键恢复** Windows 默认右键菜单

### 1.3 技术选型：Flutter

| 维度 | Flutter 方案 | 说明 |
|------|-------------|------|
| UI 层 | `fluent_ui` | Win11 Fluent Design 原生级组件（NavigationView、TreeView、CommandBar） |
| 注册表 | `win32` + Dart FFI | 直接调用 Win32 Registry API，无需中间层 |
| 系统通知 | `win32` | SHChangeNotify、SendMessage 等 Win32 API |
| 窗口管理 | `window_manager` | 自定义标题栏、窗口大小/位置、Mica 效果 |
| 主题 | `system_theme` + `fluent_ui` | 自动跟随系统明暗主题 |
| 进程管理 | `process_run` / Dart `Process` | 重启 explorer.exe、执行 reg 命令 |
| 持久化 | `hive` / `shared_preferences` | 快照、配置本地存储 |
| 文件选择 | `file_picker` | 备份文件导入/导出 |

**选型理由：**
- `fluent_ui` 提供与 Win11 一致的 Fluent Design 组件，视觉效果优于 ModernWPF
- 声明式 UI + Hot Reload 开发效率高
- Dart FFI 可直接调用任意 Win32 API，无平台限制
- 单一代码库，未来可扩展至其他平台（如 Linux 右键菜单管理）

---

## 2. 功能需求

### 2.1 菜单浏览器（Menu Explorer）

| ID | 功能 | 描述 | 优先级 | Flutter 实现 |
|----|------|------|--------|-------------|
| F-01 | 全量扫描 | 扫描注册表所有右键菜单注册位置（详见技术文档） | P0 | `win32` RegOpenKeyEx/RegEnumKeyEx/RegQueryValueEx |
| F-02 | 树形分类展示 | 按文件类型（所有文件、文件夹、背景、驱动器、扩展名）分组展示 | P0 | `fluent_ui` TreeView |
| F-03 | 两级菜单标识 | 每个条目标注属于紧凑菜单还是经典菜单，视觉区分 | P0 | 自定义 Tag 组件（紧凑=蓝色/经典=灰色） |
| F-04 | 搜索/筛选 | 按名称、命令行、扩展名搜索 | P1 | TextField + 实时过滤列表 |
| F-05 | 属性面板 | 选中条目后展示详情：名称、命令行、图标路径、注册位置、菜单层级 | P0 | `fluent_ui` InfoBar + 表单组件 |

### 2.2 菜单编辑（Menu Editor）

| ID | 功能 | 描述 | 优先级 | Flutter 实现 |
|----|------|------|--------|-------------|
| F-06 | 移动菜单层级 | 拖拽或按钮操作，将菜单项在紧凑菜单和经典菜单间切换（修改 Extended 标签）| P0 | 按钮：RegDeleteValue(Extended) / RegSetValueEx(Extended) |
| F-07 | 排序调整 | 同级菜单项拖拽排序 | P1 | `flutter_reorderable_list` |
| F-08 | 新增菜单项 | 用户添加自定义菜单项（名称、命令行、图标、层级、文件类型） | P0 | `fluent_ui` Dialog + 表单 |
| F-09 | 编辑菜单项 | 修改现有项的名称、命令、图标等 | P0 | `fluent_ui` Dialog + 表单 |
| F-10 | 删除菜单项 | 删除指定菜单项（自动备份） | P0 | RegDeleteKey + 自动备份逻辑 |

### 2.3 备份与恢复（Backup & Restore）

| ID | 功能 | 描述 | 优先级 | Flutter 实现 |
|----|------|------|--------|-------------|
| F-11 | 一键备份 | 将当前所有右键菜单配置备份（导出 .reg + .json 双格式） | P0 | `Process.run('reg', ['export', ...])` + dart:io JSON 编码 |
| F-12 | 一键恢复 | 从备份文件恢复右键菜单配置 | P0 | `Process.run('reg', ['import', ...])` + JSON 解码回写 |
| F-13 | 恢复默认 | 恢复 Windows 右键菜单到出厂默认状态 | P0 | 预置默认配置模板 + 批量注册表操作 |
| F-14 | 安全回滚 | 修改注册表前自动备份受影响键值，操作失败自动回滚 | P0 | 修改前 RegExport 单键 → 失败时 RegImport |
| F-15 | 快照管理 | 自动创建操作快照，支持历史版本回滚（保留最近 10 个） | P1 | `hive` 存储快照元数据 + 本地文件系统 |

### 2.4 系统刷新

| ID | 功能 | 描述 | 优先级 | Flutter 实现 |
|----|------|------|--------|-------------|
| F-16 | 刷新桌面 | 修改后自动刷新桌面（SHChangeNotify API） | P0 | `win32` SHChangeNotify FFI 调用 |
| F-17 | 重启资源管理器 | 部分修改需重启 explorer.exe，提供一键操作 | P0 | `Process.run('taskkill', [...])` + `Process.run('explorer')` |

---

## 3. 用户界面需求

### 3.1 界面布局

使用 `fluent_ui` NavigationView（Scaffold 模式），左侧 NavigationPane + 右侧内容区：

```
┌─────────────────────────────────────────────────────┐
│  标题栏 (window_manager 自定义, Mica/Acrylic 背景)    │
├──────────────────┬──────────────────────────────────┤
│  NavigationPane  │  Content Page                     │
│  (fluent_ui)     │                                   │
│  ─────────       │  ┌─ 属性详情 / 编辑表单 ─────────┐ │
│  📋 菜单浏览器    │  │ 名称: 7-Zip                   │ │
│  🔄 备份与恢复    │  │ 命令: ...                      │ │
│  ⚙️ 设置         │  │ 层级: [紧凑] [经典]            │ │
│                  │  │ 位置: HKCR\*\shell\7-Zip      │ │
│  ─────────       │  │ [移至紧凑菜单] [编辑] [删除]   │ │
│  树形菜单列表:    │  └──────────────────────────────┘ │
│  ▶ 所有文件 (*)  │                                   │
│    ▶ 7-Zip      │  ┌─ 待应用修改 (InfoBar) ─────────┐│
│    ▶ WinRAR     │  │ × 7-Zip → 紧凑菜单 (待应用)    ││
│  ▶ 文件夹       │  │ × VS Code → 紧凑菜单 (待应用)  ││
│  ▶ 背景         │  └────────────────────────────────┘│
│  ▶ .txt         │                                   │
│  ▶ .md          │                                   │
├──────────────────┴──────────────────────────────────┤
│  状态栏: 共 42 项  |  待应用: 2  |  [应用更改 F5]    │
└─────────────────────────────────────────────────────┘
```

**Flutter 组件映射：**

| 界面元素 | Flutter 组件 |
|---------|-------------|
| 整体框架 | `NavigationView` + `NavigationPane` |
| 左侧树 | `TreeView` |
| 右侧内容 | `ScaffoldPage` + `ScrollablePage` |
| 属性表单 | `TextFormBox` / `TextBox` + `ComboBox` |
| 操作按钮 | `Button` / `FilledButton` / `HyperlinkButton` |
| 确认对话框 | `ContentDialog` |
| 状态提示 | `InfoBar` |
| 搜索框 | `AutoSuggestBox` |
| 标签/徽章 | 自定义 `Widget`（`fluent_ui` 无原生 Tag） |
| 进度指示 | `ProgressBar` / `ProgressRing` |

### 3.2 交互流程

**用例 1：将 7-Zip 移到紧凑菜单**
1. 启动 → 展开"所有文件 (*)" → 找到 7-Zip
2. 选中 → 右侧面板显示"层级：经典菜单"
3. 点击"移至紧凑菜单" → 条目移动到紧凑菜单分组
4. 修改加入底部"待应用修改"列表
5. 点击"应用更改" → 执行注册表修改
6. 提示"已生效"（或"需重启资源管理器"并提供一键重启）

**用例 2：一键恢复默认**
1. 点击顶部"备份与恢复" → 选择"恢复默认"
2. 二次确认对话框："此操作将删除所有自定义菜单项，恢复 Windows 默认状态"
3. 确认 → 自动创建当前状态快照 → 恢复默认注册表
4. 提示"已恢复，当前配置已备份至 backups\"

### 3.3 设计原则

- **Flutter + fluent_ui** 主题，与 Windows 11 Fluent Design 一致（圆角、间距、动效）
- `window_manager` 自定义窗口标题栏，支持 Mica/Acrylic 透明效果
- 左侧 NavigationPane 导航 + 右侧内容区，符合 Win11 设置 App 布局规范
- 明/暗主题通过 `system_theme` 自适应系统设置
- 关键操作使用 `ContentDialog` 二次确认，操作可撤销
- 异步操作使用 `ProgressBar` / `ProgressRing` 反馈

---

## 4. 非功能性需求

| 需求 | 指标 | Flutter 适配说明 |
|------|------|-----------------|
| 启动速度 | 首次启动 ≤ 3s，后续 ≤ 1s（缓存） | Flutter 引擎初始化约 0.5-1s，比 WPF 略慢 |
| 扫描完整菜单 | ≤ 3s | 注册表扫描为 Isolate 异步执行，不阻塞 UI |
| 应用更改 | ≤ 1s | 同上 |
| 内存占用 | 空闲 ≤ 80MB，扫描时 ≤ 150MB | Flutter 引擎基础占用约 50-60MB |
| 安装包体积 | ≤ 40MB（单 exe / MSIX） | Flutter Windows Release 约 20-35MB |
| 安全性 | 修改前自动备份，支持一键回滚最近 10 次 | 同原需求 |

---

## 5. 项目结构（Flutter）

```
lib/
├── main.dart                    # 入口，初始化 window_manager
├── app.dart                     # FluentApp 根组件，主题配置
├── models/
│   ├── menu_item.dart           # 菜单项数据模型
│   ├── menu_category.dart       # 菜单分类枚举
│   └── backup_snapshot.dart     # 备份快照模型
├── services/
│   ├── registry_service.dart    # 注册表读写（win32 FFI 封装）
│   ├── backup_service.dart      # 备份/恢复/快照管理
│   ├── shell_notify_service.dart # SHChangeNotify 调用
│   └── explorer_service.dart    # 资源管理器重启
├── viewmodels/
│   ├── menu_explorer_vm.dart    # 菜单浏览器状态管理
│   ├── menu_editor_vm.dart      # 菜单编辑状态管理
│   └── backup_vm.dart           # 备份恢复状态管理
├── pages/
│   ├── menu_explorer_page.dart  # 菜单浏览器页面
│   ├── backup_page.dart         # 备份与恢复页面
│   └── settings_page.dart       # 设置页面
├── widgets/
│   ├── menu_tree.dart           # 菜单树组件
│   ├── property_panel.dart      # 属性面板
│   ├── pending_changes_bar.dart # 待应用修改栏
│   ├── menu_item_tag.dart       # 紧凑/经典菜单标签
│   └── edit_dialog.dart         # 编辑/新增对话框
└── utils/
    ├── registry_paths.dart      # 注册表路径常量
    └── icon_extractor.dart      # 图标提取工具
```

---

## 6. 核心依赖

```yaml
dependencies:
  fluent_ui: ^4.9.0          # Win11 Fluent Design UI 组件
  window_manager: ^0.4.0     # 窗口管理（标题栏、Mica）
  win32: ^5.5.0              # Win32 API 绑定（注册表、SHChangeNotify）
  system_theme: ^3.1.0       # 系统主题检测
  hive: ^2.2.0               # 本地存储（快照元数据）
  hive_flutter: ^1.1.0       # Hive Flutter 适配
  path_provider: ^2.1.0      # 应用数据目录
  file_picker: ^8.0.0        # 文件选择器
  provider: ^6.1.0           # 状态管理
  uuid: ^4.4.0               # 快照 ID 生成
```

---

## 7. 发布计划

| 阶段 | 内容 | 优先级 |
|------|------|--------|
| **MVP** | 菜单浏览器 + 两级菜单切换 + 自定义新增 + 一键备份/恢复/还原 + 安全回滚 | P0 |
| v1.1 | 搜索筛选 + 排序拖拽 + 命令模板 + 图标提取 | P1 |
| v1.2 | 子菜单支持 + 快照管理 + 冗余清理 | P1 |

---

## 8. 风险与应对

| 风险 | 影响 | 应对 |
|------|------|------|
| Flutter Windows 桌面稳定性 | 偶发渲染异常 | 使用稳定版 Flutter，避免实验性 API |
| `win32` 包注册表 API 覆盖不全 | 部分操作需手写 FFI | 预研 `win32` 包能力，必要时用 `dart:ffi` 补充 |
| Mica/Acrylic 效果兼容性 | Win10 不支持 Mica | 降级为 Acrylic 或纯色背景 |
| 管理员权限需求 | 修改 HKLM 注册表需提权 | 使用 `runas` 触发 UAC 提权，或引导用户以管理员运行 |
| 包体积偏大 | 用户下载/安装门槛 | 提供 MSIX 安装包 + 自动更新 |

---

> **UI 框架已确定**：Flutter 3.x + fluent_ui + win32
