import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import '../models/pending_change.dart';
import '../services/registry_service.dart';
import '../services/shell_notify_service.dart';
import '../services/explorer_service.dart';
import '../services/backup_service.dart';

/// 菜单浏览器 + 编辑器 ViewModel
class MenuExplorerVM extends ChangeNotifier {
  final RegistryService _registryService;
  final ShellNotifyService _shellNotifyService;
  final ExplorerService _explorerService;
  final BackupService _backupService;
  final _uuid = const Uuid();

  List<MenuItem> _allItems = [];
  List<MenuItem> _filteredItems = [];
  MenuItem? _selectedItem;
  final List<PendingChange> _pendingChanges = [];
  bool _isScanning = false;
  bool _isApplying = false;
  String _searchQuery = '';
  MenuCategory? _filterCategory;

  MenuExplorerVM({
    required RegistryService registryService,
    required ShellNotifyService shellNotifyService,
    required ExplorerService explorerService,
    required BackupService backupService,
  })  : _registryService = registryService,
        _shellNotifyService = shellNotifyService,
        _explorerService = explorerService,
        _backupService = backupService;

  // Getters
  List<MenuItem> get allItems => _allItems;
  List<MenuItem> get filteredItems => _filteredItems;
  MenuItem? get selectedItem => _selectedItem;
  List<PendingChange> get pendingChanges => List.unmodifiable(_pendingChanges);
  bool get isScanning => _isScanning;
  bool get isApplying => _isApplying;
  String get searchQuery => _searchQuery;
  int get pendingCount => _pendingChanges.length;
  bool get hasPendingChanges => _pendingChanges.isNotEmpty;

  /// 按分类获取菜单项
  Map<MenuCategory, List<MenuItem>> get itemsByCategory {
    final map = <MenuCategory, List<MenuItem>>{};
    for (final item in _filteredItems) {
      final cat = _getCategoryForItem(item);
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  MenuCategory _getCategoryForItem(MenuItem item) {
    // 根据 hiveKey 判断分类
    switch (item.hiveKey) {
      case r'*':
      case r'AllFilesystemObjects':
        return MenuCategory.allFiles;
      case r'Directory':
        return MenuCategory.directory;
      case r'Directory\Background':
        return MenuCategory.directoryBackground;
      case r'Drive':
        return MenuCategory.drive;
      default:
        if (item.hiveKey.startsWith('.')) {
          return MenuCategory.customExtension;
        }
        return MenuCategory.allFiles;
    }
  }

  /// 扫描所有菜单项
  Future<void> scan() async {
    _isScanning = true;
    notifyListeners();

    try {
      _allItems = await _registryService.scanAll();
      _applyFilter();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// 选择菜单项
  void selectItem(MenuItem? item) {
    _selectedItem = item;
    notifyListeners();
  }

  /// 搜索
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
    notifyListeners();
  }

  /// 按分类筛选
  void setFilterCategory(MenuCategory? category) {
    _filterCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var items = _allItems;

    if (_filterCategory != null) {
      items = items
          .where((item) => _getCategoryForItem(item) == _filterCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      items = items
          .where((item) =>
              item.displayName.toLowerCase().contains(query) ||
              item.keyName.toLowerCase().contains(query) ||
              item.command.toLowerCase().contains(query) ||
              item.hiveKey.toLowerCase().contains(query))
          .toList();
    }

    _filteredItems = items;
  }

  // ========== 菜单编辑操作（加入待应用列表）==========

  /// 移到紧凑菜单
  void moveToCompact(MenuItem item) {
    _addPendingChange(
      type: ChangeType.moveToCompact,
      originalItem: item,
      newItem: item.copyWith(level: MenuLevel.compact),
      description: '${item.displayName} → 紧凑菜单',
    );
  }

  /// 移到经典菜单
  void moveToExtended(MenuItem item) {
    _addPendingChange(
      type: ChangeType.moveToExtended,
      originalItem: item,
      newItem: item.copyWith(level: MenuLevel.extended),
      description: '${item.displayName} → 经典菜单',
    );
  }

  /// 新增菜单项
  void addMenuItem({
    required String hiveKey,
    required String keyName,
    required String displayName,
    required String command,
    String? iconPath,
    required MenuLevel level,
  }) {
    final newItem = MenuItem(
      keyName: keyName,
      displayName: displayName,
      command: command,
      iconPath: iconPath,
      level: level,
      registryPath: '$hiveKey\\shell\\$keyName',
      hiveKey: hiveKey,
    );

    _addPendingChange(
      type: ChangeType.add,
      newItem: newItem,
      description: '新增: $displayName',
    );
  }

  /// 编辑菜单项
  void editMenuItem({
    required MenuItem original,
    String? displayName,
    String? command,
    String? iconPath,
    MenuLevel? level,
  }) {
    final newItem = original.copyWith(
      displayName: displayName,
      command: command,
      iconPath: iconPath,
      level: level,
    );

    _addPendingChange(
      type: ChangeType.edit,
      originalItem: original,
      newItem: newItem,
      description: '编辑: ${original.displayName}',
    );
  }

  /// 删除菜单项
  void deleteMenuItem(MenuItem item) {
    _addPendingChange(
      type: ChangeType.delete,
      originalItem: item,
      description: '删除: ${item.displayName}',
    );
  }

  void _addPendingChange({
    required ChangeType type,
    MenuItem? originalItem,
    MenuItem? newItem,
    required String description,
  }) {
    // 如果同一项已有待应用修改，先移除旧的
    if (originalItem != null) {
      _pendingChanges.removeWhere(
          (c) => c.originalItem?.registryPath == originalItem.registryPath);
    }

    _pendingChanges.add(PendingChange(
      id: _uuid.v4(),
      type: type,
      originalItem: originalItem,
      newItem: newItem,
      description: description,
    ));

    notifyListeners();
  }

  /// 移除待应用修改
  void removePendingChange(String changeId) {
    _pendingChanges.removeWhere((c) => c.id == changeId);
    notifyListeners();
  }

  /// 应用所有待修改
  Future<bool> applyAllChanges() async {
    if (_pendingChanges.isEmpty) return true;

    _isApplying = true;
    notifyListeners();

    try {
      // 先备份
      await _backupService.backupAll('应用修改前自动备份');

      var allSuccess = true;

      for (final change in _pendingChanges) {
        bool success = false;

        switch (change.type) {
          case ChangeType.moveToCompact:
            success = await _registryService.moveToCompact(change.originalItem!);
            break;
          case ChangeType.moveToExtended:
            success =
                await _registryService.moveToExtended(change.originalItem!);
            break;
          case ChangeType.add:
            success = await _registryService.addMenuItem(
              hiveKey: change.newItem!.hiveKey,
              keyName: change.newItem!.keyName,
              displayName: change.newItem!.displayName,
              command: change.newItem!.command,
              iconPath: change.newItem!.iconPath,
              level: change.newItem!.level,
            );
            break;
          case ChangeType.edit:
            success = await _registryService.editMenuItem(
              original: change.originalItem!,
              displayName: change.newItem?.displayName,
              command: change.newItem?.command,
              iconPath: change.newItem?.iconPath,
              level: change.newItem?.level,
            );
            break;
          case ChangeType.delete:
            success =
                await _registryService.deleteMenuItem(change.originalItem!);
            break;
        }

        if (!success) allSuccess = false;
      }

      // 通知系统刷新
      _shellNotifyService.notifyAssociationChanged();

      // 清空待应用列表
      _pendingChanges.clear();

      // 重新扫描
      await scan();

      return allSuccess;
    } finally {
      _isApplying = false;
      notifyListeners();
    }
  }

  /// 重启资源管理器
  Future<bool> restartExplorer() async {
    return _explorerService.restartExplorer();
  }
}
