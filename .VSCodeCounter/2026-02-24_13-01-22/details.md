# Details

Date : 2026-02-24 13:01:22

Directory /Users/zileyuan/Documents/Workspace/git/dart-projects/code-doc-tool

Total : 56 files,  8128 codes, 163 comments, 1311 blanks, all 9602 lines

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)

## Files
| filename | language | code | comment | blank | total |
| :--- | :--- | ---: | ---: | ---: | ---: |
| [.github/workflows/release.yml](/.github/workflows/release.yml) | YAML | 59 | 0 | 16 | 75 |
| [README.md](/README.md) | Markdown | 1 | 0 | 1 | 2 |
| [app/README.md](/app/README.md) | Markdown | 10 | 0 | 7 | 17 |
| [app/analysis\_options.yaml](/app/analysis_options.yaml) | YAML | 3 | 22 | 4 | 29 |
| [app/lib/data/processors/code\_cleaner.dart](/app/lib/data/processors/code_cleaner.dart) | Dart | 442 | 0 | 67 | 509 |
| [app/lib/data/processors/file\_scanner.dart](/app/lib/data/processors/file_scanner.dart) | Dart | 92 | 0 | 21 | 113 |
| [app/lib/domain/app\_state.dart](/app/lib/domain/app_state.dart) | Dart | 266 | 0 | 52 | 318 |
| [app/lib/domain/models/clean\_code.dart](/app/lib/domain/models/clean_code.dart) | Dart | 20 | 0 | 4 | 24 |
| [app/lib/domain/models/export\_config.dart](/app/lib/domain/models/export_config.dart) | Dart | 42 | 0 | 4 | 46 |
| [app/lib/domain/models/export\_result.dart](/app/lib/domain/models/export_result.dart) | Dart | 19 | 0 | 3 | 22 |
| [app/lib/domain/models/scan\_config.dart](/app/lib/domain/models/scan_config.dart) | Dart | 80 | 0 | 5 | 85 |
| [app/lib/domain/models/source\_file.dart](/app/lib/domain/models/source_file.dart) | Dart | 27 | 0 | 3 | 30 |
| [app/lib/domain/services/clean\_service.dart](/app/lib/domain/services/clean_service.dart) | Dart | 35 | 0 | 9 | 44 |
| [app/lib/domain/services/export\_service.dart](/app/lib/domain/services/export_service.dart) | Dart | 19 | 0 | 4 | 23 |
| [app/lib/domain/services/scan\_service.dart](/app/lib/domain/services/scan_service.dart) | Dart | 18 | 0 | 5 | 23 |
| [app/lib/domain/services/update\_service.dart](/app/lib/domain/services/update_service.dart) | Dart | 183 | 0 | 32 | 215 |
| [app/lib/infrastructure/encoding/encoding\_detector.dart](/app/lib/infrastructure/encoding/encoding_detector.dart) | Dart | 144 | 0 | 26 | 170 |
| [app/lib/infrastructure/exporters/word\_exporter.dart](/app/lib/infrastructure/exporters/word_exporter.dart) | Dart | 246 | 1 | 29 | 276 |
| [app/lib/infrastructure/io/file\_reader.dart](/app/lib/infrastructure/io/file_reader.dart) | Dart | 46 | 0 | 5 | 51 |
| [app/lib/infrastructure/security/path\_validator.dart](/app/lib/infrastructure/security/path_validator.dart) | Dart | 156 | 0 | 25 | 181 |
| [app/lib/main.dart](/app/lib/main.dart) | Dart | 48 | 0 | 4 | 52 |
| [app/lib/ui/pages/home\_page.dart](/app/lib/ui/pages/home_page.dart) | Dart | 1,262 | 0 | 55 | 1,317 |
| [app/macos/Flutter/GeneratedPluginRegistrant.swift](/app/macos/Flutter/GeneratedPluginRegistrant.swift) | Swift | 10 | 3 | 4 | 17 |
| [app/macos/Podfile](/app/macos/Podfile) | Ruby | 32 | 1 | 10 | 43 |
| [app/macos/Runner/AppDelegate.swift](/app/macos/Runner/AppDelegate.swift) | Swift | 11 | 0 | 3 | 14 |
| [app/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json](/app/macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json) | JSON | 68 | 0 | 0 | 68 |
| [app/macos/Runner/Base.lproj/MainMenu.xib](/app/macos/Runner/Base.lproj/MainMenu.xib) | XML | 343 | 0 | 1 | 344 |
| [app/macos/Runner/MainFlutterWindow.swift](/app/macos/Runner/MainFlutterWindow.swift) | Swift | 12 | 0 | 4 | 16 |
| [app/macos/RunnerTests/RunnerTests.swift](/app/macos/RunnerTests/RunnerTests.swift) | Swift | 7 | 2 | 4 | 13 |
| [app/macos/update.sh](/app/macos/update.sh) | Shell Script | 19 | 1 | 9 | 29 |
| [app/pubspec.yaml](/app/pubspec.yaml) | YAML | 38 | 33 | 15 | 86 |
| [app/test/widget\_test.dart](/app/test/widget_test.dart) | Dart | 8 | 0 | 3 | 11 |
| [app/windows/CMakeLists.txt](/app/windows/CMakeLists.txt) | CMake | 89 | 0 | 20 | 109 |
| [app/windows/flutter/CMakeLists.txt](/app/windows/flutter/CMakeLists.txt) | CMake | 98 | 0 | 12 | 110 |
| [app/windows/flutter/generated\_plugin\_registrant.cc](/app/windows/flutter/generated_plugin_registrant.cc) | C++ | 9 | 4 | 5 | 18 |
| [app/windows/flutter/generated\_plugin\_registrant.h](/app/windows/flutter/generated_plugin_registrant.h) | C++ | 5 | 5 | 6 | 16 |
| [app/windows/flutter/generated\_plugins.cmake](/app/windows/flutter/generated_plugins.cmake) | CMake | 20 | 0 | 6 | 26 |
| [app/windows/runner/CMakeLists.txt](/app/windows/runner/CMakeLists.txt) | CMake | 34 | 0 | 7 | 41 |
| [app/windows/runner/flutter\_window.cpp](/app/windows/runner/flutter_window.cpp) | C++ | 49 | 7 | 16 | 72 |
| [app/windows/runner/flutter\_window.h](/app/windows/runner/flutter_window.h) | C++ | 20 | 5 | 9 | 34 |
| [app/windows/runner/main.cpp](/app/windows/runner/main.cpp) | C++ | 30 | 4 | 10 | 44 |
| [app/windows/runner/resource.h](/app/windows/runner/resource.h) | C++ | 9 | 6 | 2 | 17 |
| [app/windows/runner/utils.cpp](/app/windows/runner/utils.cpp) | C++ | 54 | 2 | 10 | 66 |
| [app/windows/runner/utils.h](/app/windows/runner/utils.h) | C++ | 8 | 6 | 6 | 20 |
| [app/windows/runner/win32\_window.cpp](/app/windows/runner/win32_window.cpp) | C++ | 210 | 24 | 55 | 289 |
| [app/windows/runner/win32\_window.h](/app/windows/runner/win32_window.h) | C++ | 48 | 31 | 24 | 103 |
| [app/windows/update.bat](/app/windows/update.bat) | Batch | 30 | 0 | 10 | 40 |
| [doc/DESIGN-INDEX.md](/doc/DESIGN-INDEX.md) | Markdown | 253 | 0 | 50 | 303 |
| [doc/Requirements.md](/doc/Requirements.md) | Markdown | 40 | 0 | 14 | 54 |
| [doc/design-architecture.md](/doc/design-architecture.md) | Markdown | 311 | 0 | 59 | 370 |
| [doc/design-code-cleaner.md](/doc/design-code-cleaner.md) | Markdown | 536 | 6 | 96 | 638 |
| [doc/design-encoding.md](/doc/design-encoding.md) | Markdown | 605 | 0 | 119 | 724 |
| [doc/design-file-scanner.md](/doc/design-file-scanner.md) | Markdown | 492 | 0 | 103 | 595 |
| [doc/design-ui.md](/doc/design-ui.md) | Markdown | 491 | 0 | 63 | 554 |
| [doc/design-update.md](/doc/design-update.md) | Markdown | 156 | 0 | 28 | 184 |
| [doc/design-word-exporter.md](/doc/design-word-exporter.md) | Markdown | 765 | 0 | 147 | 912 |

[Summary](results.md) / Details / [Diff Summary](diff.md) / [Diff Details](diff-details.md)