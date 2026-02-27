import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/app_state.dart';

class ExportConfigForm extends StatefulWidget {
  const ExportConfigForm({super.key});

  @override
  State<ExportConfigForm> createState() => _ExportConfigFormState();
}

class _ExportConfigFormState extends State<ExportConfigForm> {
  final _softwareNameController = TextEditingController();
  final _versionController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = context.read<AppState>();
      _softwareNameController.text = state.softwareName;
      _versionController.text = state.version;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _softwareNameController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 2: 配置导出参数',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Consumer<AppState>(
              builder: (context, state, child) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '软件名称 *',
                              hintText: '例如：CodeDocTool',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: _softwareNameController,
                            onChanged: (value) =>
                                state.updateConfig(softwareName: value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: '版本号 *',
                              hintText: '例如：1.0',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            controller: _versionController,
                            onChanged: (value) =>
                                state.updateConfig(version: value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '固定设置：50行/页，最多60页',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
