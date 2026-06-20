import 'menu_item.dart';

/// 备份快照
class BackupSnapshot {
  final String id;
  final DateTime createdAt;
  final String description;
  final List<MenuItem> items;
  final String? regFilePath;
  final String? jsonFilePath;

  BackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.description,
    required this.items,
    this.regFilePath,
    this.jsonFilePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'description': description,
        'items': items.map((e) => e.toJson()).toList(),
        'regFilePath': regFilePath,
        'jsonFilePath': jsonFilePath,
      };

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) =>
      BackupSnapshot(
        id: json['id'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        description: json['description'] as String,
        items: (json['items'] as List)
            .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        regFilePath: json['regFilePath'] as String?,
        jsonFilePath: json['jsonFilePath'] as String?,
      );
}
