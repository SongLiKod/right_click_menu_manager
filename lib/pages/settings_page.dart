import 'package:fluent_ui/fluent_ui.dart';

/// 设置页面
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('设置')),
      content: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('关于', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Windows 右键菜单管理器'),
            const SizedBox(height: 4),
            Text('版本: 1.0.0', style: TextStyle(color: Colors.grey[120])),
            const SizedBox(height: 4),
            Text('基于 Flutter + fluent_ui + win32',
                style: TextStyle(color: Colors.grey[120], fontSize: 12)),
            const SizedBox(height: 24),

            Text('权限说明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('本应用需要管理员权限运行，用于修改注册表中的右键菜单配置。',
                style: TextStyle(color: Colors.grey[120])),
            const SizedBox(height: 24),

            Text('快捷键', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _ShortcutRow(shortcutKey: 'F5', description: '刷新菜单列表'),
            _ShortcutRow(shortcutKey: 'Ctrl+S', description: '应用待保存的修改'),
            _ShortcutRow(shortcutKey: 'Ctrl+N', description: '新增菜单项'),
            _ShortcutRow(shortcutKey: 'Delete', description: '删除选中菜单项'),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String shortcutKey;
  final String description;

  const _ShortcutRow({required this.shortcutKey, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[20],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[60]),
          ),
          child: Text(shortcutKey, style: const TextStyle(fontSize: 12, fontFamily: 'Consolas')),
        ),
        const SizedBox(width: 12),
        Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[180])),
      ]),
    );
  }
}
