import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化系统主题检测
  await SystemTheme.accentColor.load();

  // 初始化 Hive
  await Hive.initFlutter();

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1100, 700),
    minimumSize: Size(800, 500),
    center: true,
    backgroundColor: Color(0xFF202020),
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: '右键菜单管理器',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const App());
}
