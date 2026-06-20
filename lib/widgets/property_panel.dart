import 'package:fluent_ui/fluent_ui.dart';
import '../models/menu_item.dart';
import 'menu_item_tag.dart';

/// 属性面板 - 显示选中菜单项的详情和操作按钮
class PropertyPanel extends StatelessWidget {
  final MenuItem? selectedItem;
  final VoidCallback? onMoveToCompact;
  final VoidCallback? onMoveToExtended;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PropertyPanel({
    super.key,
    required this.selectedItem,
    this.onMoveToCompact,
    this.onMoveToExtended,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedItem == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.info_solid, size: 48, color: Colors.grey[80]),
            const SizedBox(height: 12),
            Text('选择一个菜单项查看详情',
                style: TextStyle(color: Colors.grey[100], fontSize: 14)),
          ],
        ),
      );
    }

    final item = selectedItem!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(children: [
            Expanded(
              child: Text(item.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            MenuItemTag(level: item.level),
          ]),
          const SizedBox(height: 20),

          // 属性表
          _PropertyRow(label: '键名', value: item.keyName),
          _PropertyRow(label: '命令', value: item.command),
          _PropertyRow(label: '图标', value: item.iconPath ?? '(无)'),
          _PropertyRow(label: '注册位置', value: 'HKCR\\${item.registryPath}'),
          _PropertyRow(label: '分类', value: item.hiveKey),

          const SizedBox(height: 24),

          // 操作按钮
          const Divider(),
          const SizedBox(height: 12),
          Text('操作', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[190])),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (item.isExtended)
                FilledButton(
                  onPressed: onMoveToCompact,
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FluentIcons.up, size: 12),
                    SizedBox(width: 4),
                    Text('移至紧凑菜单'),
                  ]),
                ),
              if (!item.isExtended)
                Button(
                  onPressed: onMoveToExtended,
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FluentIcons.down, size: 12),
                    SizedBox(width: 4),
                    Text('移至经典菜单'),
                  ]),
                ),
              Button(
                onPressed: onEdit,
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(FluentIcons.edit, size: 12),
                  SizedBox(width: 4),
                  Text('编辑'),
                ]),
              ),
              Button(
                onPressed: onDelete,
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.red.withValues(alpha: 0.1)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(FluentIcons.delete, size: 12, color: Colors.red),
                  const SizedBox(width: 4),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[120])),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(fontSize: 13),
                maxLines: 3),
          ),
        ],
      ),
    );
  }
}
