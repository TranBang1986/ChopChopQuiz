import 'dart:io';
import 'dart:ui' as ui;

import 'package:chop_chop_quiz/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Run: STORE_EXPORT=1 flutter test test/store_export_test.dart
void main() {
  final export = Platform.environment['STORE_EXPORT'] == '1';

  testWidgets('export app icon', (tester) async {
    Directory('assets/icon').createSync(recursive: true);
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    await tester.binding.setSurfaceSize(const Size(1024, 1024));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: key,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [C.cream, C.blush],
              ),
            ),
            child: Center(child: Mascot(size: 720, animate: false)),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('assets/icon/app_icon_1024_square.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }, skip: !export);
}
