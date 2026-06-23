import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/backup_snapshot.dart';
import '../models/menu_item.dart';
import 'registry_service.dart';

/// 备份与恢复服务
class BackupService {
  final RegistryService _registryService;
  final _uuid = const Uuid();
  static const int maxSnapshots = 10;

  BackupService(this._registryService);

  /// 获取备份目录
  Future<String> _getBackupDir() async {
    final appDir = await getApplicationSupportDirectory();
    final backupDir = Directory('${appDir.path}\\backups');
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    return backupDir.path;
  }

  /// 一键备份当前所有右键菜单配置
  Future<BackupSnapshot> backupAll(String description) async {
    final items = await _registryService.scanAll();
    final id = _uuid.v4();
    final backupDir = await _getBackupDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

    // 导出 JSON
    final jsonPath = '$backupDir\\backup_$timestamp.json';
    final jsonFile = File(jsonPath);
    final snapshot = BackupSnapshot(
      id: id,
      createdAt: DateTime.now(),
      description: description,
      items: items,
      jsonFilePath: jsonPath,
    );
    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toJson()),
    );

    // 导出 .reg 文件（按分类导出）
    final regPath = '$backupDir\\backup_$timestamp.reg';
    await _exportAllRegFiles(items, regPath);
    // 更新快照路径
    final finalSnapshot = BackupSnapshot(
      id: id,
      createdAt: DateTime.now(),
      description: description,
      items: items,
      regFilePath: regPath,
      jsonFilePath: jsonPath,
    );

    // 清理旧快照
    await _cleanupOldSnapshots();

    return finalSnapshot;
  }

  /// 从备份恢复
  Future<bool> restoreFromBackup(BackupSnapshot snapshot) async {
    // 先备份当前状态
    await backupAll('恢复前自动备份');

    // 导入 .reg 文件
    if (snapshot.regFilePath != null) {
      final regFile = File(snapshot.regFilePath!);
      if (await regFile.exists()) {
        return _registryService.importRegFile(snapshot.regFilePath!);
      }
    }

    // 如果 .reg 文件不存在，从 JSON 恢复
    return _restoreFromJson(snapshot.items);
  }

  /// 从 JSON 数据恢复菜单项
  Future<bool> _restoreFromJson(List<MenuItem> items) async {
    var success = true;
    for (final item in items) {
      final result = await _registryService.addMenuItem(
        hiveKey: item.hiveKey,
        keyName: item.keyName,
        displayName: item.displayName,
        command: item.command,
        iconPath: item.iconPath,
        level: item.level,
      );
      if (!result) success = false;
    }
    return success;
  }

  /// 修改前自动备份受影响的注册表键
  Future<String?> backupSingleKey(String registryPath) async {
    final backupDir = await _getBackupDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final safeName = registryPath.replaceAll('\\', '_').replaceAll('*', 'star');
    final regPath = '$backupDir\\single_${safeName}_$timestamp.reg';

    final success =
        await _registryService.exportRegKey(registryPath, regPath);
    return success ? regPath : null;
  }

  /// 预览将被恢复默认删除的菜单项（有 command 的项）
  Future<List<MenuItem>> previewDefault() async {
    final items = await _registryService.scanAll();
    return items.where((item) => item.command.isNotEmpty).toList();
  }

  /// 恢复默认（仅删除指定列表中仍存在的项）
  Future<bool> restoreDefault(List<MenuItem> targetItems) async {
    // 先完整备份
    await backupAll('恢复默认前自动备份');

    var success = true;

    for (final item in targetItems) {
      // 重新确认该键仍存在再删除（防止并发修改）
      if (_registryService.keyExists(item.registryPath)) {
        final result = await _registryService.deleteMenuItem(item);
        if (!result) success = false;
      }
    }

    return success;
  }

  /// 导出所有注册表项到 .reg 文件
  Future<void> _exportAllRegFiles(List<MenuItem> items, String regPath) async {
    final buffer = StringBuffer();
    buffer.writeln('Windows Registry Editor Version 5.00');
    buffer.writeln();

    for (final item in items) {
      buffer.writeln('[HKEY_CLASSES_ROOT\\${item.registryPath}]');
      if (item.displayName != item.keyName) {
        buffer.writeln('@="${_escapeRegString(item.displayName)}"');
      }
      if (item.iconPath != null && item.iconPath!.isNotEmpty) {
        buffer.writeln('"Icon"="${_escapeRegString(item.iconPath!)}"');
      }
      if (item.isExtended) {
        buffer.writeln('"Extended"=""');
      }
      buffer.writeln(
          '[HKEY_CLASSES_ROOT\\${item.registryPath}\\command]');
      buffer.writeln('@="${_escapeRegString(item.command)}"');
      buffer.writeln();
    }

    final file = File(regPath);
    // .reg 文件需要 BOM + UTF-16LE 编码
    final encoded = _encodeUtf16LeWithBom(buffer.toString());
    await file.writeAsBytes(encoded);
  }

  String _escapeRegString(String s) {
    return s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }

  List<int> _encodeUtf16LeWithBom(String text) {
    final codeUnits = <int>[];
    // BOM
    codeUnits.addAll([0xFF, 0xFE]);
    // UTF-16LE
    for (final char in text.runes) {
      if (char <= 0xFFFF) {
        codeUnits.addAll([char & 0xFF, (char >> 8) & 0xFF]);
      } else {
        // Surrogate pair
        final v = char - 0x10000;
        final hi = 0xD800 + (v >> 10);
        final lo = 0xDC00 + (v & 0x3FF);
        codeUnits.addAll([hi & 0xFF, (hi >> 8) & 0xFF]);
        codeUnits.addAll([lo & 0xFF, (lo >> 8) & 0xFF]);
      }
    }
    return codeUnits;
  }

  /// 清理旧快照，保留最近 maxSnapshots 个
  Future<void> _cleanupOldSnapshots() async {
    final backupDir = await _getBackupDir();
    final dir = Directory(backupDir);
    if (!await dir.exists()) return;

    final files = await dir.list().toList();
    final backupFiles = files
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));

    if (backupFiles.length > maxSnapshots) {
      for (var i = maxSnapshots; i < backupFiles.length; i++) {
        final jsonFile = backupFiles[i];
        await jsonFile.delete();

        // 同时删除对应的 .reg 文件
        final regPath =
            jsonFile.path.replaceAll('.json', '.reg');
        final regFile = File(regPath);
        if (await regFile.exists()) {
          await regFile.delete();
        }
      }
    }
  }

  /// 获取所有快照列表
  Future<List<BackupSnapshot>> listSnapshots() async {
    final backupDir = await _getBackupDir();
    final dir = Directory(backupDir);
    if (!await dir.exists()) return [];

    final snapshots = <BackupSnapshot>[];
    final files = await dir.list().toList();

    for (final file in files.whereType<File>()) {
      if (file.path.endsWith('.json')) {
        try {
          final content = await file.readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          snapshots.add(BackupSnapshot.fromJson(json));
        } catch (_) {
          // 忽略损坏的备份文件
        }
      }
    }

    snapshots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return snapshots;
  }
}
