import 'menu_item.dart';

/// 待应用的修改操作
enum ChangeType {
  moveToCompact,
  moveToExtended,
  add,
  edit,
  delete,
}

class PendingChange {
  final String id;
  final ChangeType type;
  final MenuItem? originalItem;
  final MenuItem? newItem;
  final String description;

  PendingChange({
    required this.id,
    required this.type,
    this.originalItem,
    this.newItem,
    required this.description,
  });

  String get typeLabel {
    switch (type) {
      case ChangeType.moveToCompact:
        return '移至紧凑菜单';
      case ChangeType.moveToExtended:
        return '移至经典菜单';
      case ChangeType.add:
        return '新增';
      case ChangeType.edit:
        return '编辑';
      case ChangeType.delete:
        return '删除';
    }
  }
}
