/// 菜单分类 - 按右键点击的目标类型分组
enum MenuCategory {
  /// 所有文件 (*)
  allFiles('所有文件 (*)', r'*'),

  /// 文件夹
  directory('文件夹', r'Directory'),

  /// 文件夹背景（在空白处右键）
  directoryBackground('背景', r'Directory\Background'),

  /// 驱动器
  drive('驱动器', r'Drive'),

  /// 桌面背景
  desktopBackground('桌面背景', r'DesktopBackground'),

  /// 自定义扩展名
  customExtension('扩展名', '');

  final String displayName;
  final String registryKey;

  const MenuCategory(this.displayName, this.registryKey);
}
