import 'package:flutter/material.dart';
import '../widgets/directory_selection_widget.dart';
import '../widgets/export_config_form.dart';
import '../widgets/filter_config_widget.dart';
import '../widgets/action_buttons_widget.dart';
import '../widgets/file_list_view.dart';
import '../widgets/progress_panel.dart';
import '../widgets/update_dialog_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('软著代码文档生成工具'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: '检查更新',
            onPressed: () => UpdateDialogWidget.show(context),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DirectorySelectionWidget(),
            SizedBox(height: 16),
            ExportConfigForm(),
            SizedBox(height: 16),
            FilterConfigWidget(),
            SizedBox(height: 16),
            ActionButtonsWidget(),
            SizedBox(height: 16),
            FileListView(),
            SizedBox(height: 16),
            ProgressPanel(),
          ],
        ),
      ),
    );
  }
}
