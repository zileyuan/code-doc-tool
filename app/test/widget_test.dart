import 'package:flutter_test/flutter_test.dart';
import 'package:code_doc_tool/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    await tester.pumpWidget(const CodeDocToolApp());

    expect(find.text('源代码归档与软著文档生成工具'), findsOneWidget);
  });
}
