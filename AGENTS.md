# AGENTS.md - Code Documentation Tool

Flutter desktop app for generating software copyright documentation. Supports scanning source code, removing comments, detecting encodings, and exporting Word documents.

**Tech Stack**: Flutter 3.38, Dart, Provider

---

## Build & Development Commands

```bash
cd app
flutter pub get                           # Install dependencies
flutter run -d macos                      # Run dev (macOS)
flutter run -d windows                    # Run dev (Windows)
flutter build macos --release              # Build production
flutter build windows --release            # Build production
flutter analyze                           # Run linter
flutter test                              # Run all tests
flutter test test/widget_test.dart         # Run single test file
flutter test --name "pattern"              # Run tests matching pattern
```

---

## Code Style Guidelines

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | UpperCamelCase | `class SourceFile` |
| Enums | UpperCamelCase | `enum FileStatus` |
| Functions | lowerCamelCase | `void scanDirectories()` |
| Variables | lowerCamelCase | `final filePath` |
| Private members | `_` prefix | `final FileScanner _scanner` |
| File names | snake_case | `file_scanner.dart` |

### Import Guidelines

```dart
// External packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Internal - same layer
import '../models/source_file.dart';

// Internal - cross layer (package: prefix recommended)
import 'package:code_doc_tool/domain/models/source_file.dart';
```

### Formatting Rules

- Use **trailing commas** for readability
- Maximum line length: 80 characters
- Use `const` constructors whenever possible
- Prefer expression-bodied members for simple getters

### Type Annotations

- Always specify return types:
  ```dart
  Future<List<SourceFile>> scanDirectories(List<String> paths) async { }
  ```
- Use `void` explicitly for functions that don't return value
- Prefer `final` over `var`

---

## Architecture

```
lib/
├── main.dart                    # App entry point
├── domain/                      # Business logic layer
│   ├── app_state.dart          # Global state (Provider)
│   ├── models/                 # Data models
│   └── services/               # Business services
├── data/                        # Data processing layer
│   └── processors/              # Data processors
├── infrastructure/              # Infrastructure layer
│   ├── encoding/               # Encoding detection
│   ├── exporters/             # Word export
│   ├── io/                    # File I/O
│   └── security/              # Security utilities
└── ui/                          # Presentation layer
    └── pages/                  # UI pages
```

### Best Practices

- **Models**: Immutable with `final` fields
- **Services**: Stateless business logic classes
- **State**: Use Provider `ChangeNotifier`
- **Dependency Injection**: Constructor injection preferred

---

## Error Handling

### Try-catch with fallback

```dart
try {
  return await CharsetConverter.decode('gbk', uint8List);
} catch (e) {
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return String.fromCharCodes(bytes);
  }
}
```

### Result type pattern

```dart
class ExportResult {
  final bool success;
  final String? errorMessage;
  final String? filePath;
}
```

---

## UI/Flutter Specific

### Widget Guidelines

- Use **Material 3** (`useMaterial3: true`)
- Prefer `const` constructors
- Use `StatelessWidget` when no state needed
- Center title in AppBar: `const AppBarTheme(centerTitle: true, elevation: 0)`

### Theming

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  useMaterial3: true,
)
```

---

## Testing

```dart
testWidgets('App initialization test', (WidgetTester tester) async {
  await tester.pumpWidget(const CodeDocToolApp());
  expect(find.text('软著代码文档生成工具'), findsOneWidget);
});
```

---

## Common Tasks

- **Add source file type**: Edit `app/lib/data/processors/file_scanner.dart`
- **Add export format**: Add class in `app/lib/infrastructure/exporters/`
- **Modify lints**: Edit `app/analysis_options.yaml`

---

## Quick Reference

### Commands

| Task | Command |
|------|----------|
| Clean build | `flutter clean && flutter pub get` |
| Format code | `dart format lib/ test/` |
| Check formatting | `dart format --set-exit-if-changed lib/` |

### Architecture Rules

- **Models**: Pure data classes with `final` fields, no logic
- **Services**: Business logic, orchestrate processors  
- **Processors**: Low-level data operations
- **Infrastructure**: I/O, encoding, export, security
- **UI**: Widgets only, delegate to Provider state

### Key Patterns

- **Constructor Injection**: `Service({Dep? dep}) : dep = dep ?? Dep();`
- **Custom Exceptions**: `class MyException implements Exception { final String message; }`
- **State Management**: Extend `ChangeNotifier`, dispose listeners in `dispose()`
- **Async**: Always specify return types (`Future<T>`), use `async*` for streams
