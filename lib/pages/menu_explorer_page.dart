import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../viewmodels/menu_explorer_vm.dart';
import '../widgets/menu_tree.dart';
import '../widgets/property_panel.dart';
import '../widgets/pending_changes_bar.dart';
import '../widgets/edit_dialog.dart';

/// 菜单浏览器页面 - 主页面
class MenuExplorerPage extends StatefulWidget {
  const MenuExplorerPage({super.key});

  @override
  State<MenuExplorerPage> createState() => _MenuExplorerPageState();
}

class _MenuExplorerPageState extends State<MenuExplorerPage> {
  @override
  void initState() {
    super.initState();
    // 首次加载时扫描
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuExplorerVM>().scan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MenuExplorerVM>();

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('菜单浏览器'),
        commandBar: Row(mainAxisSize: MainAxisSize.min, children: [
          // 搜索框
          SizedBox(
            width: 200,
            child: TextBox(
              placeholder: '搜索菜单项...',
              prefix: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(FluentIcons.search, size: 14),
              ),
              onChanged: vm.setSearchQuery,
            ),
          ),
          const SizedBox(width: 8),
          // 刷新按钮
          IconButton(
            icon: const Icon(FluentIcons.refresh),
            onPressed: vm.isScanning ? null : () => vm.scan(),
          ),
          // 新增按钮
          const SizedBox(width: 4),
          FilledButton(
            onPressed: () => _showAddDialog(context),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(FluentIcons.add, size: 12),
              SizedBox(width: 4),
              Text('新增'),
            ]),
          ),
        ]),
      ),
      content: vm.isScanning
          ? const Center(child: ProgressRing())
          : Column(children: [
              // 主内容区
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧菜单树
                    SizedBox(
                      width: 280,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey[40],
                              width: 1,
                            ),
                          ),
                        ),
                        child: vm.allItems.isEmpty
                            ? Center(
                                child: Text('未找到菜单项',
                                    style: TextStyle(color: Colors.grey[100])))
                            : MenuTree(
                                itemsByCategory: vm.itemsByCategory,
                                selectedItem: vm.selectedItem,
                                onItemSelected: vm.selectItem,
                              ),
                      ),
                    ),
                    // 右侧属性面板
                    Expanded(
                      child: PropertyPanel(
                        selectedItem: vm.selectedItem,
                        onMoveToCompact: () => vm.moveToCompact(vm.selectedItem!),
                        onMoveToExtended: () => vm.moveToExtended(vm.selectedItem!),
                        onEdit: () => _showEditDialog(context, vm.selectedItem!),
                        onDelete: () => _confirmDelete(context, vm.selectedItem!),
                      ),
                    ),
                  ],
                ),
              ),
              // 底部待应用修改栏
              if (vm.hasPendingChanges)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[40], width: 1),
                    ),
                  ),
                  child: PendingChangesBar(
                    pendingChanges: vm.pendingChanges,
                    onRemoveChange: vm.removePendingChange,
                    onApplyAll: () => _applyChanges(context),
                    isApplying: vm.isApplying,
                  ),
                ),
            ]),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => EditDialog(
        defaultHiveKey: r'*',
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        context.read<MenuExplorerVM>().addMenuItem(
              hiveKey: result['hiveKey'],
              keyName: result['keyName'],
              displayName: result['displayName'],
              command: result['command'],
              iconPath: result['iconPath'],
              level: result['level'],
            );
      }
    });
  }

  void _showEditDialog(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => EditDialog(existingItem: item),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        context.read<MenuExplorerVM>().editMenuItem(
              original: item,
              displayName: result['displayName'],
              command: result['command'],
              iconPath: result['iconPath'],
              level: result['level'],
            );
      }
    });
  }

  void _confirmDelete(BuildContext context, MenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ContentDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除菜单项 "${item.displayName}" 吗？\n此操作将在应用更改后生效，可撤销。'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MenuExplorerVM>().deleteMenuItem(item);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(Colors.red.withValues(alpha: 0.8)),
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _applyChanges(BuildContext context) async {
    final vm = context.read<MenuExplorerVM>();
    final success = await vm.applyAllChanges();

    if (!mounted) return;

    if (success) {
      showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('修改已生效'),
          content: const Text('右键菜单已更新。\n如部分菜单未刷新，可尝试重启资源管理器。'),
          actions: [
            Button(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('确定'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                vm.restartExplorer();
              },
              child: const Text('重启资源管理器'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('部分修改失败'),
          content: const Text('部分注册表修改未成功，请检查权限。\n当前配置已自动备份。'),
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
