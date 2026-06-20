import 'package:fluent_ui/fluent_ui.dart';
import '../models/pending_change.dart';

/// 待应用修改栏
class PendingChangesBar extends StatelessWidget {
  final List<PendingChange> pendingChanges;
  final ValueChanged<String> onRemoveChange;
  final VoidCallback onApplyAll;
  final bool isApplying;

  const PendingChangesBar({
    super.key,
    required this.pendingChanges,
    required this.onRemoveChange,
    required this.onApplyAll,
    this.isApplying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingChanges.isEmpty) return const SizedBox.shrink();

    return InfoBar(
      title: Text('待应用修改 (${pendingChanges.length})'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...pendingChanges.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(_getChangeIcon(change.type), size: 12,
                      color: _getChangeColor(change.type)),
                  const SizedBox(width: 6),
                  Text(change.description, style: const TextStyle(fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(FluentIcons.cancel, size: 10),
                    onPressed: () => onRemoveChange(change.id),
                  ),
                ]),
              )),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: isApplying ? null : onApplyAll,
            child: isApplying
                ? const Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 14, height: 14, child: ProgressRing(strokeWidth: 2)),
                    SizedBox(width: 6),
                    Text('应用中...'),
                  ])
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(FluentIcons.save, size: 12),
                    SizedBox(width: 4),
                    Text('应用更改'),
                  ]),
          ),
        ],
      ),
      severity: InfoBarSeverity.warning,
    );
  }

  IconData _getChangeIcon(ChangeType type) {
    switch (type) {
      case ChangeType.moveToCompact:
        return FluentIcons.up;
      case ChangeType.moveToExtended:
        return FluentIcons.down;
      case ChangeType.add:
        return FluentIcons.add;
      case ChangeType.edit:
        return FluentIcons.edit;
      case ChangeType.delete:
        return FluentIcons.delete;
    }
  }

  Color _getChangeColor(ChangeType type) {
    switch (type) {
      case ChangeType.moveToCompact:
        return Colors.blue;
      case ChangeType.moveToExtended:
        return Colors.grey[100];
      case ChangeType.add:
        return Colors.green;
      case ChangeType.edit:
        return Colors.orange;
      case ChangeType.delete:
        return Colors.red;
    }
  }
}
