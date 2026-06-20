import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_theme/system_theme.dart';

import 'viewmodels/menu_explorer_vm.dart';
import 'viewmodels/backup_vm.dart';
import 'services/registry_service.dart';
import 'services/shell_notify_service.dart';
import 'services/explorer_service.dart';
import 'services/backup_service.dart';
import 'pages/menu_explorer_page.dart';
import 'pages/backup_page.dart';
import 'pages/settings_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = SystemTheme.accentColor.accent;
    return FluentApp(
      title: '右键菜单管理器',
      debugShowCheckedModeBanner: false,
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: accentColor.toAccentColor(),
        visualDensity: VisualDensity.standard,
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: accentColor.toAccentColor(),
        visualDensity: VisualDensity.standard,
      ),
      themeMode: ThemeMode.system,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with WindowListener {
  int _selectedIndex = 0;

  static final _registryService = RegistryService();
  static final _shellNotifyService = ShellNotifyService();
  static final _explorerService = ExplorerService();
  static final _backupService = BackupService(_registryService);
  static final _menuExplorerVM = MenuExplorerVM(
    registryService: _registryService,
    shellNotifyService: _shellNotifyService,
    explorerService: _explorerService,
    backupService: _backupService,
  );
  static final _backupVM = BackupVM(
    backupService: _backupService,
    shellNotifyService: _shellNotifyService,
  );

  final _pages = [
    const MenuExplorerPage(),
    const BackupPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _menuExplorerVM.dispose();
    _backupVM.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_menuExplorerVM.hasPendingChanges) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (ctx) => ContentDialog(
          title: const Text('确认关闭'),
          content: const Text('你有未应用的修改，确定要关闭吗？\n未应用的修改将丢失。'),
          actions: [
            Button(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('关闭'),
            ),
          ],
        ),
      );
      if (shouldClose != true) return;
    }
    windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _menuExplorerVM),
        ChangeNotifierProvider.value(value: _backupVM),
      ],
      child: NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (i) => setState(() => _selectedIndex = i),
          displayMode: PaneDisplayMode.compact,
          header: DragToMoveArea(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text('右键菜单管理器',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.list),
              title: const Text('菜单浏览器'),
              body: _pages[0],
            ),
            PaneItem(
              icon: Icon(FluentIcons.save_as),
              title: const Text('备份与恢复'),
              body: _pages[1],
            ),
            PaneItemSeparator(),
            PaneItem(
              icon: const Icon(FluentIcons.settings),
              title: const Text('设置'),
              body: _pages[2],
            ),
          ],
          footerItems: [
            PaneItem(
              icon: const Icon(FluentIcons.info, size: 12),
              title: Text('v1.0.0',
                  style: TextStyle(fontSize: 11, color: Colors.grey[120])),
              body: const SettingsPage(),
            ),
          ],
        ),
      ),
    );
  }
}
