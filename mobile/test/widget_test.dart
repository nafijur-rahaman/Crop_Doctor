// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crop_disease_detector/main.dart';

void main() {
  testWidgets('app shows welcome screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    
    await tester.pumpWidget(const CropDiseaseDetection());

    expect(find.text('Scan & Diagnose'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsWidgets);
    
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
