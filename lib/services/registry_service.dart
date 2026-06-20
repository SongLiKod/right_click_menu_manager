import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';

/// 注册表服务 - 核心的右键菜单扫描与修改逻辑
class RegistryService {
  // HKCR 根键
  static const int hkcr = HKEY_CLASSES_ROOT;

  /// 需要扫描的 shell 注册位置
  static const Map<MenuCategory, List<String>> _scanPaths = {
    MenuCategory.allFiles: [r'*\shell', r'AllFilesystemObjects\shell'],
    MenuCategory.directory: [r'Directory\shell'],
    MenuCategory.directoryBackground: [r'Directory\Background\shell'],
    MenuCategory.drive: [r'Drive\shell'],
    MenuCategory.desktopBackground: [r'DesktopBackground\shell'],
  };

  /// 全量扫描所有右键菜单项
  Future<List<MenuItem>> scanAll() async {
    final items = <MenuItem>[];

    for (final entry in _scanPaths.entries) {
      final category = entry.key;
      for (final path in entry.value) {
        final subItems = _scanShellPath(path, category);
        items.addAll(subItems);
      }
    }

    // 扫描自定义扩展名
    final extensionItems = await _scanExtensions();
    items.addAll(extensionItems);

    return items;
  }

  /// 扫描指定 shell 路径下的菜单项
  List<MenuItem> _scanShellPath(String shellPath, MenuCategory category) {
    final items = <MenuItem>[];
    final phKey = calloc<HKEY>();

    try {
      final subKey = shellPath.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_READ, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return items;
      }

      final hKey = phKey.value;
      final index = calloc<DWORD>();
      final maxNameLen = calloc<DWORD>();

      // 获取最大子键名长度
      RegQueryInfoKey(hKey, nullptr, nullptr, nullptr, nullptr, maxNameLen,
          nullptr, nullptr, nullptr, nullptr, nullptr, nullptr);

      final nameLen = maxNameLen.value + 1;
      final name = calloc<Uint16>(nameLen);

      // 枚举所有子键
      for (var i = 0;; i++) {
        index.value = nameLen;
        final ret = RegEnumKeyEx(
            hKey, i, name.cast<Utf16>(), index, nullptr, nullptr, nullptr, nullptr);

        if (ret == ERROR_NO_MORE_ITEMS) break;
        if (ret != ERROR_SUCCESS) continue;

        final keyName = name.cast<Utf16>().toDartString();
        final fullPath = '$shellPath\\$keyName';

        final item = _readMenuItem(fullPath, keyName, category.registryKey);
        if (item != null) {
          items.add(item);
        }
      }

      calloc.free(name);
      calloc.free(index);
      calloc.free(maxNameLen);
      RegCloseKey(hKey);
    } finally {
      calloc.free(phKey);
    }

    return items;
  }

  /// 读取单个菜单项的详细信息
  MenuItem? _readMenuItem(
      String shellItemPath, String keyName, String hiveKey) {
    final phKey = calloc<HKEY>();

    try {
      final subKey = shellItemPath.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_READ, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return null;
      }

      final hKey = phKey.value;

      // 读取显示名称 (默认值)
      final displayName = _readStringValue(hKey, null) ?? keyName;

      // 读取图标
      final iconPath = _readStringValue(hKey, 'Icon');

      // 检查是否有 Extended 标记
      final hasExtended = _valueExists(hKey, 'Extended');
      final level = hasExtended ? MenuLevel.extended : MenuLevel.compact;

      // 读取 command
      final command = _readCommandValue(shellItemPath);

      RegCloseKey(hKey);

      return MenuItem(
        keyName: keyName,
        displayName: displayName,
        command: command,
        iconPath: iconPath,
        level: level,
        registryPath: shellItemPath,
        hiveKey: hiveKey,
      );
    } finally {
      calloc.free(phKey);
    }
  }

  /// 读取 command 子键的默认值
  String _readCommandValue(String shellItemPath) {
    final commandPath = '$shellItemPath\\command';
    final phKey = calloc<HKEY>();

    try {
      final subKey = commandPath.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_READ, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return '';
      }

      final hKey = phKey.value;
      final command = _readStringValue(hKey, null) ?? '';
      RegCloseKey(hKey);
      return command;
    } finally {
      calloc.free(phKey);
    }
  }

  /// 读取注册表字符串值
  String? _readStringValue(int hKey, String? valueName) {
    final dataSize = calloc<DWORD>();
    final pValueName =
        valueName != null ? valueName.toNativeUtf16() : nullptr;

    // 先查询数据大小
    var result = RegQueryValueEx(
        hKey, pValueName, nullptr, nullptr, nullptr, dataSize);

    if (result != ERROR_SUCCESS || dataSize.value == 0) {
      if (pValueName != nullptr) calloc.free(pValueName);
      calloc.free(dataSize);
      return null;
    }

    final data = calloc<Uint8>(dataSize.value);
    final dataType = calloc<DWORD>();

    result = RegQueryValueEx(
        hKey, pValueName, nullptr, dataType, data, dataSize);

    String? value;
    if (result == ERROR_SUCCESS &&
        (dataType.value == REG_SZ || dataType.value == REG_EXPAND_SZ)) {
      value = data.cast<Utf16>().toDartString();
    }

    if (pValueName != nullptr) calloc.free(pValueName);
    calloc.free(dataSize);
    calloc.free(dataType);
    calloc.free(data);
    return value;
  }

  /// 检查值是否存在
  bool _valueExists(int hKey, String valueName) {
    final pValueName = valueName.toNativeUtf16();
    final result = RegQueryValueEx(hKey, pValueName, nullptr, nullptr, nullptr, nullptr);
    calloc.free(pValueName);
    return result == ERROR_SUCCESS;
  }

  /// 扫描自定义扩展名的右键菜单
  Future<List<MenuItem>> _scanExtensions() async {
    final items = <MenuItem>[];
    final phKey = calloc<HKEY>();

    try {
      final result = RegOpenKeyEx(
          hkcr, r'.'.toNativeUtf16(), 0, KEY_READ, phKey);
      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return items;
      }

      final hKey = phKey.value;
      final maxNameLen = calloc<DWORD>();
      RegQueryInfoKey(hKey, nullptr, nullptr, nullptr, nullptr, maxNameLen,
          nullptr, nullptr, nullptr, nullptr, nullptr, nullptr);

      final nameLen = maxNameLen.value + 1;
      final name = calloc<Uint16>(nameLen);

      for (var i = 0;; i++) {
        final index = calloc<DWORD>();
        index.value = nameLen;
        final ret =
            RegEnumKeyEx(hKey, i, name.cast<Utf16>(), index, nullptr, nullptr, nullptr, nullptr);
        calloc.free(index);

        if (ret == ERROR_NO_MORE_ITEMS) break;
        if (ret != ERROR_SUCCESS) continue;

        final extName = name.cast<Utf16>().toDartString();
        if (!extName.startsWith('.')) continue;

        // 常见扩展名才扫描
        if (!_isCommonExtension(extName)) continue;

        final shellPath = '$extName\\shell';
        final subItems = _scanShellPath(shellPath, MenuCategory.customExtension);
        items.addAll(subItems);
      }

      calloc.free(name);
      calloc.free(maxNameLen);
      RegCloseKey(hKey);
    } finally {
      calloc.free(phKey);
    }

    return items;
  }

  static const _commonExtensions = {
    '.txt', '.md', '.pdf', '.doc', '.docx', '.xls', '.xlsx',
    '.ppt', '.pptx', '.zip', '.rar', '.7z', '.tar', '.gz',
    '.jpg', '.png', '.gif', '.bmp', '.svg', '.mp3', '.mp4',
    '.avi', '.mkv', '.py', '.js', '.ts', '.java', '.cpp',
    '.c', '.h', '.cs', '.go', '.rs', '.html', '.css',
    '.json', '.xml', '.yaml', '.yml', '.ini', '.cfg',
    '.exe', '.msi', '.bat', '.ps1', '.sh', '.dll',
  };

  bool _isCommonExtension(String ext) => _commonExtensions.contains(ext.toLowerCase());

  // ========== 修改操作 ==========

  /// 将菜单项移到紧凑菜单（删除 Extended 值）
  Future<bool> moveToCompact(MenuItem item) async {
    return _deleteValue(item.registryPath, 'Extended');
  }

  /// 将菜单项移到经典菜单（添加 Extended 值）
  Future<bool> moveToExtended(MenuItem item) async {
    return _setStringValue(item.registryPath, 'Extended', '');
  }

  /// 新增菜单项
  Future<bool> addMenuItem({
    required String hiveKey,
    required String keyName,
    required String displayName,
    required String command,
    String? iconPath,
    required MenuLevel level,
  }) async {
    final shellPath = '$hiveKey\\shell';
    final itemPath = '$shellPath\\$keyName';

    // 创建主键
    if (!_createKey(itemPath)) return false;

    // 设置显示名称
    if (displayName != keyName) {
      _setStringValue(itemPath, null, displayName);
    }

    // 设置图标
    if (iconPath != null && iconPath.isNotEmpty) {
      _setStringValue(itemPath, 'Icon', iconPath);
    }

    // 设置层级
    if (level == MenuLevel.extended) {
      _setStringValue(itemPath, 'Extended', '');
    }

    // 创建 command 子键
    final commandPath = '$itemPath\\command';
    if (!_createKey(commandPath)) return false;
    _setStringValue(commandPath, null, command);

    return true;
  }

  /// 编辑菜单项
  Future<bool> editMenuItem({
    required MenuItem original,
    String? displayName,
    String? command,
    String? iconPath,
    MenuLevel? level,
  }) async {
    final path = original.registryPath;

    if (displayName != null) {
      _setStringValue(path, null, displayName);
    }

    if (command != null) {
      _setStringValue('$path\\command', null, command);
    }

    if (iconPath != null) {
      if (iconPath.isEmpty) {
        _deleteValue(path, 'Icon');
      } else {
        _setStringValue(path, 'Icon', iconPath);
      }
    }

    if (level != null && level != original.level) {
      if (level == MenuLevel.compact) {
        _deleteValue(path, 'Extended');
      } else {
        _setStringValue(path, 'Extended', '');
      }
    }

    return true;
  }

  /// 删除菜单项
  Future<bool> deleteMenuItem(MenuItem item) async {
    final phKey = calloc<HKEY>();
    final parentPath = item.registryPath.substring(
        0, item.registryPath.lastIndexOf('\\'));
    final subKeyName =
        item.registryPath.substring(item.registryPath.lastIndexOf('\\') + 1);

    try {
      final subKey = parentPath.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_SET_VALUE | DELETE, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return false;
      }

      final name = subKeyName.toNativeUtf16();
      final delResult = RegDeleteKey(phKey.value, name);
      calloc.free(name);
      RegCloseKey(phKey.value);

      return delResult == ERROR_SUCCESS;
    } finally {
      calloc.free(phKey);
    }
  }

  // ========== 底层注册表操作 ==========

  bool _createKey(String path) {
    final phKey = calloc<HKEY>();
    final disp = calloc<DWORD>();

    try {
      final subKey = path.toNativeUtf16();
      final result =
          RegCreateKeyEx(hkcr, subKey, 0, nullptr, 0, KEY_WRITE, nullptr, phKey, disp);
      calloc.free(subKey);
      calloc.free(disp);

      if (result == ERROR_SUCCESS) {
        RegCloseKey(phKey.value);
      }
      calloc.free(phKey);
      return result == ERROR_SUCCESS;
    } catch (_) {
      calloc.free(disp);
      calloc.free(phKey);
      return false;
    }
  }

  bool _setStringValue(String path, String? valueName, String value) {
    final phKey = calloc<HKEY>();

    try {
      final subKey = path.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_SET_VALUE, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return false;
      }

      final pValueName =
          valueName != null ? valueName.toNativeUtf16() : nullptr;
      final pData = value.toNativeUtf16();
      final dataSize = (value.length + 1) * 2; // UTF-16 含 null terminator

      final setResult = RegSetValueEx(phKey.value, pValueName, 0, REG_SZ,
          pData.cast<Uint8>(), dataSize);

      if (pValueName != nullptr) calloc.free(pValueName);
      calloc.free(pData);
      RegCloseKey(phKey.value);
      calloc.free(phKey);

      return setResult == ERROR_SUCCESS;
    } catch (_) {
      calloc.free(phKey);
      return false;
    }
  }

  bool _deleteValue(String path, String valueName) {
    final phKey = calloc<HKEY>();

    try {
      final subKey = path.toNativeUtf16();
      final result = RegOpenKeyEx(hkcr, subKey, 0, KEY_SET_VALUE, phKey);
      calloc.free(subKey);

      if (result != ERROR_SUCCESS) {
        calloc.free(phKey);
        return false;
      }

      final pValueName = valueName.toNativeUtf16();
      final delResult = RegDeleteValue(phKey.value, pValueName);
      calloc.free(pValueName);
      RegCloseKey(phKey.value);
      calloc.free(phKey);

      return delResult == ERROR_SUCCESS;
    } catch (_) {
      calloc.free(phKey);
      return false;
    }
  }

  /// 导出注册表项为 .reg 文件
  Future<bool> exportRegKey(String keyPath, String filePath) async {
    try {
      final result = await Process.run(
        'reg',
        ['export', 'HKCR\\$keyPath', filePath, '/y'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// 导入 .reg 文件
  Future<bool> importRegFile(String filePath) async {
    try {
      final result = await Process.run('reg', ['import', filePath]);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
