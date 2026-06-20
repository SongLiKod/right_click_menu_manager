# 右键菜单管理器

Windows 右键菜单管理器 - 自定义右键菜单、调整菜单层级

## 功能

- 扫描并展示所有右键菜单项
- 将菜单项在紧凑菜单和经典菜单之间切换
- 新增/编辑/删除自定义菜单项
- 一键备份/恢复右键菜单配置
- 恢复 Windows 默认右键菜单

## 技术栈

- Flutter 3.x + fluent_ui + win32
- Dart FFI 调用 Win32 注册表 API
- GitHub Actions 自动构建

## 构建

推送到 `main` 分支或创建 `v*` 标签即可触发 GitHub Actions 自动构建。

手动构建：
```bash
flutter pub get
flutter build windows --release
```

构建产物位于 `build/windows/x64/runner/Release/`。

## 权限

本应用需要管理员权限运行，用于修改注册表中的右键菜单配置。
