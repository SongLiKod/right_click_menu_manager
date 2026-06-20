import 'package:fluent_ui/fluent_ui.dart';
import '../models/menu_item.dart';

/// 菜单层级标签
class MenuItemTag extends StatelessWidget {
  final MenuLevel level;
  final double fontSize;

  const MenuItemTag({
    super.key,
    required this.level,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = level == MenuLevel.compact;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isCompact
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCompact
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        isCompact ? '紧凑菜单' : '经典菜单',
        style: TextStyle(
          fontSize: fontSize,
          color: isCompact ? Colors.blue : Colors.grey[100],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
