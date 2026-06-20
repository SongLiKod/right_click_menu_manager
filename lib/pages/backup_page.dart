import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../models/backup_snapshot.dart';
import '../viewmodels/backup_vm.dart';

/// 备份与恢复页面
class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BackupVM>().loadSnapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackupVM>();

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('备份与恢复'),
        commandBar: Row(mainAxisSize: MainAxisSize.min, children: [
          FilledButton(
            onPressed: vm.isBusy ? null : () => _createBackup(context),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(FluentIcons.save, size: 12),
              SizedBox(width: 4),
              Text('创建备份'),
            ]),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: vm.isBusy ? null : () => _restoreDefault(context),
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red.withValues(alpha: 0.1)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(FluentIcons.refresh, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Text('恢复默认', style: TextStyle(color: Colors.red)),
            ]),
          ),
        ]),
      ),
      content: vm.isBusy
          ? const Center(child: ProgressRing())
          : vm.snapshots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.save_as, size: 48, color: Colors.grey[80]),
                      const SizedBox(height: 12),
                      Text('暂无备份快照',
                          style: TextStyle(color: Colors.grey[100], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('点击"创建备份"保存当前右键菜单配置',
                          style: TextStyle(color: Colors.grey[120], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.snapshots.length,
                  itemBuilder: (ctx, index) {
                    final snapshot = vm.snapshots[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(FluentIcons.save_as,
                            color: Colors.blue, size: 20),
                        title: Text(snapshot.description),
                        subtitle: Text(
                          '${snapshot.createdAt.toLocal().toString().substring(0, 19)}  |  '
                          '${snapshot.items.length} 个菜单项',
                          style: TextStyle(fontSize: 12, color: Colors.grey[120]),
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          Button(
                            onPressed: () => _restoreSnapshot(context, snapshot),
                            child: const Text('恢复'),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }

  void _createBackup(BuildContext context) async {
    final description = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: '手动备份');
        return ContentDialog(
          title: const Text('创建备份'),
          content: TextBox(
            controller: controller,
            placeholder: '备份描述',
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    if (description != null && mounted) {
      final success =
          await context.read<BackupVM>().createBackup(description);
      if (mounted && success) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (ctx) => ContentDialog(
              title: const Text('备份成功'),
              content: const Text('当前右键菜单配置已备份。'),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('确定'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _restoreSnapshot(BuildContext context, BackupSnapshot snapshot) {
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('确认恢复'),
        content: Text(
            '确定要从备份 "${snapshot.description}" 恢复吗？\n\n当前配置将自动备份，恢复后需刷新右键菜单。'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<BackupVM>().restoreFromSnapshot(snapshot);
              if (mounted && success) {
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx2) => ContentDialog(
                      title: const Text('恢复成功'),
                      content: const Text('右键菜单已恢复到备份状态。'),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx2),
                          child: const Text('确定'),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
            child: const Text('恢复'),
          ),
        ],
      ),
    );
  }

  void _restoreDefault(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('确认恢复默认'),
        content: const Text(
            '此操作将删除所有自定义菜单项，恢复 Windows 默认右键菜单。\n\n当前配置将自动备份，可随时恢复。'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BackupVM>().restoreDefault();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red.withValues(alpha: 0.8)),
            ),
            child: const Text('恢复默认'),
          ),
        ],
      ),
    );
  }
}
