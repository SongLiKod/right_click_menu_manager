import 'package:fluent_ui/fluent_ui.dart';
import '../models/menu_item.dart';

/// 编辑/新增菜单项对话框
class EditDialog extends StatefulWidget {
  final MenuItem? existingItem; // null 表示新增
  final String? defaultHiveKey;

  const EditDialog({
    super.key,
    this.existingItem,
    this.defaultHiveKey,
  });

  @override
  State<EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _keyController;
  late final TextEditingController _commandController;
  late final TextEditingController _iconController;
  late final TextEditingController _hiveKeyController;
  late MenuLevel _level;
  bool get _isNew => widget.existingItem == null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.displayName ?? '');
    _keyController = TextEditingController(text: item?.keyName ?? '');
    _commandController = TextEditingController(text: item?.command ?? '');
    _iconController = TextEditingController(text: item?.iconPath ?? '');
    _hiveKeyController =
        TextEditingController(text: item?.hiveKey ?? widget.defaultHiveKey ?? r'*');
    _level = item?.level ?? MenuLevel.extended;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keyController.dispose();
    _commandController.dispose();
    _iconController.dispose();
    _hiveKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(_isNew ? '新增菜单项' : '编辑菜单项'),
      constraints: const BoxConstraints(maxWidth: 500),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类
            InfoLabel(
              label: '文件类型',
              child: ComboBox<String>(
                isExpanded: true,
                value: _hiveKeyController.text,
                items: [
                  ComboBoxItem(value: r'*', child: Text('所有文件 (*)')),
                  ComboBoxItem(value: r'Directory', child: Text('文件夹')),
                  ComboBoxItem(
                      value: r'Directory\Background', child: Text('背景')),
                  ComboBoxItem(value: r'Drive', child: Text('驱动器')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    _hiveKeyController.text = v;
                  }
                },
              ),
            ),
            const SizedBox(height: 12),

            // 键名（仅新增时可编辑）
            InfoLabel(
              label: '注册表键名（英文，不可含空格）',
              child: TextBox(
                controller: _keyController,
                readOnly: !_isNew,
                placeholder: '如: MyCustomMenu',
              ),
            ),
            const SizedBox(height: 12),

            // 显示名称
            InfoLabel(
              label: '显示名称',
              child: TextBox(
                controller: _nameController,
                placeholder: '右键菜单中显示的名称',
              ),
            ),
            const SizedBox(height: 12),

            // 命令
            InfoLabel(
              label: '命令',
              child: TextBox(
                controller: _commandController,
                placeholder: r'C:\Program Files\app\app.exe "%1"',
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 12),

            // 图标
            InfoLabel(
              label: '图标路径（可选）',
              child: TextBox(
                controller: _iconController,
                placeholder: r'C:\Program Files\app\app.exe,0',
              ),
            ),
            const SizedBox(height: 12),

            // 菜单层级
            InfoLabel(
              label: '菜单层级',
              child: ComboBox<MenuLevel>(
                isExpanded: true,
                value: _level,
                items: [
                  ComboBoxItem(
                    value: MenuLevel.compact,
                    child: Text('紧凑菜单（直接显示）'),
                  ),
                  ComboBoxItem(
                    value: MenuLevel.extended,
                    child: Text('经典菜单（显示更多选项）'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _level = v);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _onSave,
          child: Text(_isNew ? '添加' : '保存'),
        ),
      ],
    );
  }

  void _onSave() {
    final name = _nameController.text.trim();
    final key = _keyController.text.trim();
    final command = _commandController.text.trim();
    final icon = _iconController.text.trim();
    final hiveKey = _hiveKeyController.text.trim();

    if (name.isEmpty || key.isEmpty || command.isEmpty) {
      return;
    }

    Navigator.pop(context, {
      'hiveKey': hiveKey,
      'keyName': key,
      'displayName': name,
      'command': command,
      'iconPath': icon.isEmpty ? null : icon,
      'level': _level,
    });
  }
}
