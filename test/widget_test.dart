import 'package:e_commerce_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('storefront renders product listing and cart action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('ShopEase'), findsOneWidget);
    expect(find.text('Find your next favorite thing'), findsOneWidget);
    expect(find.text('AeroPods Max'), findsOneWidget);

    await tester.tap(find.byTooltip('Add to cart').first);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.shopping_cart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Cart'), findsWidgets);
    expect(find.text('AeroPods Max'), findsOneWidget);
    expect(find.text('Continue to checkout'), findsOneWidget);
  });

  testWidgets('checkout supports local gateways and webhook replay', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byTooltip('Add to cart').first);
    await tester.pump();
    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();

    expect(find.text('PayWay ABA'), findsOneWidget);
    expect(find.text('Bakong KHQR'), findsOneWidget);

    await tester.tap(find.text('Bakong KHQR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay with Bakong KHQR'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Bakong KHQR payload'), findsOneWidget);
    expect(find.textContaining('Polling confirmation attempt'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Webhook handling'), findsOneWidget);
    expect(find.textContaining('processed'), findsOneWidget);

    await tester.tap(find.text('Replay webhook'));
    await tester.pumpAndSettle();

    expect(find.textContaining('duplicate ignored'), findsOneWidget);
  });
}
