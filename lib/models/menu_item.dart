/// 菜单层级
enum MenuLevel {
  /// 紧凑菜单 - 直接显示在右键菜单
  compact,

  /// 经典菜单 - 需要点击"显示更多选项"
  extended,
}

/// 右键菜单项数据模型
class MenuItem {
  final String keyName;
  final String displayName;
  final String command;
  final String? iconPath;
  final MenuLevel level;
  final String registryPath;
  final String hiveKey; // HKCR 下的根键名（如 *, Directory, Directory\Background 等）

  MenuItem({
    required this.keyName,
    required this.displayName,
    required this.command,
    this.iconPath,
    required this.level,
    required this.registryPath,
    required this.hiveKey,
  });

  /// 是否有 Extended 标记（经典菜单项）
  bool get isExtended => level == MenuLevel.extended;

  MenuItem copyWith({
    String? keyName,
    String? displayName,
    String? command,
    String? iconPath,
    MenuLevel? level,
    String? registryPath,
    String? hiveKey,
  }) {
    return MenuItem(
      keyName: keyName ?? this.keyName,
      displayName: displayName ?? this.displayName,
      command: command ?? this.command,
      iconPath: iconPath ?? this.iconPath,
      level: level ?? this.level,
      registryPath: registryPath ?? this.registryPath,
      hiveKey: hiveKey ?? this.hiveKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'keyName': keyName,
        'displayName': displayName,
        'command': command,
        'iconPath': iconPath,
        'level': level.name,
        'registryPath': registryPath,
        'hiveKey': hiveKey,
      };

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        keyName: json['keyName'] as String,
        displayName: json['displayName'] as String,
        command: json['command'] as String,
        iconPath: json['iconPath'] as String?,
        level: MenuLevel.values.firstWhere((e) => e.name == json['level']),
        registryPath: json['registryPath'] as String,
        hiveKey: json['hiveKey'] as String,
      );

  @override
  String toString() => 'MenuItem($displayName, ${level.name})';
}
