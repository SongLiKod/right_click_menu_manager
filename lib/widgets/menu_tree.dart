import 'package:fluent_ui/fluent_ui.dart';
import '../models/menu_item.dart';
import '../models/menu_category.dart';
import 'menu_item_tag.dart';

/// 左侧菜单树组件
class MenuTree extends StatelessWidget {
  final Map<MenuCategory, List<MenuItem>> itemsByCategory;
  final MenuItem? selectedItem;
  final ValueChanged<MenuItem?> onItemSelected;

  const MenuTree({
    super.key,
    required this.itemsByCategory,
    required this.selectedItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TreeView(
      items: _buildTreeItems(context),
    );
  }

  List<TreeViewItem> _buildTreeItems(BuildContext context) {
    final categories = MenuCategory.values;
    final items = <TreeViewItem>[];

    for (final category in categories) {
      final menuItems = itemsByCategory[category];
      if (menuItems == null || menuItems.isEmpty) continue;

      final compactItems =
          menuItems.where((i) => i.level == MenuLevel.compact).toList();
      final extendedItems =
          menuItems.where((i) => i.level == MenuLevel.extended).toList();

      final children = <TreeViewItem>[];

      // 紧凑菜单分组
      if (compactItems.isNotEmpty) {
        children.add(TreeViewItem(
          content: Row(children: [
            Text('紧凑菜单', style: TextStyle(
              fontSize: 13,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('${compactItems.length}',
                  style: TextStyle(fontSize: 10, color: Colors.blue)),
            ),
          ]),
          children: compactItems.map((item) => _buildMenuItemNode(item)).toList(),
        ));
      }

      // 经典菜单分组
      if (extendedItems.isNotEmpty) {
        children.add(TreeViewItem(
          content: Row(children: [
            Text('经典菜单', style: TextStyle(
              fontSize: 13,
              color: Colors.grey[100],
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text('${extendedItems.length}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[100])),
            ),
          ]),
          children: extendedItems.map((item) => _buildMenuItemNode(item)).toList(),
        ));
      }

      items.add(TreeViewItem(
        content: Row(children: [
          Icon(_getCategoryIcon(category), size: 14),
          const SizedBox(width: 6),
          Text(category.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text('${menuItems.length}',
                style: TextStyle(fontSize: 10, color: Colors.grey[100])),
          ),
        ]),
        children: children,
      ));
    }

    return items;
  }

  TreeViewItem _buildMenuItemNode(MenuItem item) {
    final isSelected = selectedItem?.registryPath == item.registryPath;

    return TreeViewItem(
      content: GestureDetector(
        onTap: () => onItemSelected(item),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: isSelected
                ? BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  )
                : null,
            child: Row(children: [
              Expanded(
                child: Text(
                  item.displayName,
                  style: TextStyle(fontSize: 13,
                    color: isSelected ? Colors.blue : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              MenuItemTag(level: item.level, fontSize: 9),
            ]),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(MenuCategory category) {
    switch (category) {
      case MenuCategory.allFiles:
        return FluentIcons.file_bug;
      case MenuCategory.directory:
        return FluentIcons.folder;
      case MenuCategory.directoryBackground:
        return FluentIcons.folder_search;
      case MenuCategory.drive:
        return FluentIcons.hard_drive;
      case MenuCategory.desktopBackground:
        return FluentIcons.devices2;
      case MenuCategory.customExtension:
        return FluentIcons.file_symlink;
    }
  }
}
