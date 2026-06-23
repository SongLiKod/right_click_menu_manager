import 'package:flutter/foundation.dart';
import '../models/backup_snapshot.dart';
import '../models/menu_item.dart';
import '../services/backup_service.dart';
import '../services/shell_notify_service.dart';

/// 备份与恢复 ViewModel
class BackupVM extends ChangeNotifier {
  final BackupService _backupService;
  final ShellNotifyService _shellNotifyService;

  List<BackupSnapshot> _snapshots = [];
  bool _isBusy = false;
  String? _errorMessage;

  BackupVM({
    required BackupService backupService,
    required ShellNotifyService shellNotifyService,
  })  : _backupService = backupService,
        _shellNotifyService = shellNotifyService;

  List<BackupSnapshot> get snapshots => _snapshots;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// 加载快照列表
  Future<void> loadSnapshots() async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshots = await _backupService.listSnapshots();
    } catch (e) {
      _errorMessage = '加载快照失败: $e';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// 创建备份
  Future<bool> createBackup(String description) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _backupService.backupAll(description);
      await loadSnapshots();
      return true;
    } catch (e) {
      _errorMessage = '备份失败: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// 从快照恢复
  Future<bool> restoreFromSnapshot(BackupSnapshot snapshot) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _backupService.restoreFromBackup(snapshot);
      if (success) {
        _shellNotifyService.notifyAssociationChanged();
      }
      await loadSnapshots();
      return success;
    } catch (e) {
      _errorMessage = '恢复失败: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// 预览将被删除的菜单项
  Future<List<MenuItem>> previewDefault() async {
    return _backupService.previewDefault();
  }

  /// 恢复默认（只删除指定列表中的项）
  Future<bool> restoreDefault(List<MenuItem> targetItems) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _backupService.restoreDefault(targetItems);
      if (success) {
        _shellNotifyService.notifyAssociationChanged();
      }
      await loadSnapshots();
      return success;
    } catch (e) {
      _errorMessage = '恢复默认失败: $e';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
