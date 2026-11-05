import 'package:flutter_test/flutter_test.dart';

// 框架 API 走公共 barrel；demo 层直接引示例代码。
import 'package:mi_like_ui/mi_like_ui.dart';
import 'package:mi_like_ui/demo/demo_app.dart';

/// 在「我的」页把「外观模式」切到指定档（三选一菜单）。
///
/// 调用前需已进入「我的」页。菜单浮层经 `MiPopup` 注册、通知推到帧末，
/// 所以先 pump 两帧让面板上身，再 `pumpAndSettle` 落定；选中后菜单自动
/// 收起，同样等落定（画面同时翻面）。
Future<void> pickAppearance(
  WidgetTester tester,
  DemoAppearance option,
) async {
  await tester.tap(find.text('外观模式'));
  await tester.pump();
  await tester.pump();
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(
      of: find.byKey(MiMenu.panelKey),
      matching: find.text(option.label),
    ),
  );
  await tester.pumpAndSettle();
}

/// 当前「外观模式」行显示的值文（= 偏好本身，不是解析后的明暗）。
String appearanceValueText(WidgetTester tester) {
  final row = tester.widgetList<MiSettingsRow>(find.byType(MiSettingsRow)).firstWhere(
        (r) => r.label == '外观模式',
      );
  return row.value ?? '';
}
