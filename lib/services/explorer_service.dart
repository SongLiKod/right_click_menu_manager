import 'dart:io';

/// 资源管理器服务 - 重启 explorer.exe
class ExplorerService {
  /// 重启资源管理器
  Future<bool> restartExplorer() async {
    try {
      // 先终止 explorer.exe
      final killResult = await Process.run(
        'taskkill',
        ['/F', '/IM', 'explorer.exe'],
      );

      if (killResult.exitCode != 0 && !killResult.stderr.toString().contains('not found')) {
        return false;
      }

      // 等待一小段时间
      await Future.delayed(const Duration(milliseconds: 500));

      // 重新启动 explorer.exe
      final startResult = await Process.run('explorer.exe', []);

      return startResult.exitCode == 0 || startResult.exitCode == -1;
    } catch (e) {
      return false;
    }
  }

  /// 检查 explorer.exe 是否在运行
  Future<bool> isExplorerRunning() async {
    try {
      final result = await Process.run('tasklist', ['/FI', 'IMAGENAME eq explorer.exe']);
      return result.stdout.toString().contains('explorer.exe');
    } catch (_) {
      return true;
    }
  }
}
