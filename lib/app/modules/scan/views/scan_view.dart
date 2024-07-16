import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/scan_controller.dart';

class ScanView extends GetView<ScanController> {
  ScanView({Key? key}) : super(key: key);

  final controller = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      body: GetBuilder<ScanController>(
        builder: (controller) {
          if (!controller.isInitialized) {
            return Center(child: CircularProgressIndicator());
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller.cameraController),
              CustomPaint(
                painter: FaceDetectionPainter(
                  faceRect: controller.faceRect,
                  isFaceInPosition: controller.isFaceInPosition,
                  imageSize: controller.cameraController.value.previewSize!,
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  controller.text ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FaceDetectionPainter extends CustomPainter {
  final Rect? faceRect;
  final bool isFaceInPosition;
  final Size imageSize;

  FaceDetectionPainter(
      {this.faceRect, required this.isFaceInPosition, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = isFaceInPosition ? Colors.green : Colors.white;

    // Gambar lingkaran putih di tengah canvas
    final faceCircleCenter = Offset(size.width / 2, size.height / 2);
    final faceCircleRadius = min(size.width, size.height) / 2;

    canvas.drawCircle(
      faceCircleCenter,
      faceCircleRadius,
      paint,
    );
  }

  @override
  bool shouldRepaint(FaceDetectionPainter oldDelegate) {
    return oldDelegate.faceRect != faceRect ||
        oldDelegate.isFaceInPosition != isFaceInPosition;
  }
}
