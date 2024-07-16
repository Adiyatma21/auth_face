import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:dev_auth_face/app/modules/simpanuser/views/simpanuser_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiver/iterables.dart';

class ScanController extends GetxController {
  late CameraController cameraController;
  late FaceDetector faceDetector;
  bool canProcess = true;
  bool isBusy = false;
  CustomPaint? customPaint;
  String? text;
  var cameraLensDirection = CameraLensDirection.front;
  bool isInitialized = false;
  bool processingStopped = false;
  Uint8List? savedFaceImageBytes;
  late Uint8List? imageFileBytes;
  late String? savedFaceImageFilename;
  Uint8List? liveFaceImageBytes;
  Rect? faceRect;
  bool isFaceInPosition = false;

  @override
  void onInit() {
    super.onInit();
    initializeCamera();
    initializeFaceDetector();
    loadSavedFaceImage();
  }

  void stopProcessing() {
    processingStopped = true;
  }

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      ),
      ResolutionPreset.high,
    );
    await cameraController.initialize();
    isInitialized = true;
    update();

    cameraController.startImageStream((CameraImage cameraImage) async {
      if (!canProcess || isBusy || processingStopped) return;

      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in cameraImage.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize =
          Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == cameraLensDirection,
        orElse: () => cameras.first,
      );

      final imageRotation =
          InputImageRotationValue.fromRawValue(camera.sensorOrientation) ??
              InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(cameraImage.format.raw) ??
              InputImageFormat.bgra8888;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: cameraImage.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );

      processImage(inputImage);
    });
  }

  void initializeFaceDetector() {
    faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableLandmarks: false,
        enableTracking: true,
        minFaceSize: 0.1,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!canProcess || isBusy) return;

    isBusy = true;
    update();

    try {
      final faces = await faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        faceRect = face.boundingBox;

        isFaceInPosition = isRectInCircle(faceRect!, inputImage.metadata!.size);
        if (isFaceInPosition) {
          text = 'Wajah terdeteksi. Membandingkan...';
          liveFaceImageBytes = inputImage.bytes;
          if (kDebugMode) {
            print(
                'debug: liveFaceImageBytes length: ${liveFaceImageBytes?.length}');
          }
          if (liveFaceImageBytes != null && savedFaceImageBytes != null) {
            final isMatch = await compareFaces(liveFaceImageBytes!,
                savedFaceImageBytes!, inputImage.metadata!.bytesPerRow);
            // if (kDebugMode) {
            //   print('debug:Match :$isMatch');
            // }
            // if (kDebugMode) {
            //   print('debug:Saved bytes:$savedFaceImageBytes');
            // }
            if (isMatch) {
              Get.snackbar('Sukses', 'Wajah dikenali. Masuk...');
              Get.to(() => SimpanuserView());
              stopProcessing();
            } else {
              text = 'Wajah tidak dikenali';
            }
          } else {
            text = 'Gambar wajah tidak tersedia untuk perbandingan';
          }
        } else {
          text = 'Posisikan wajah Anda di dalam lingkaran';
        }
      } else {
        text = 'Tidak ada wajah terdeteksi';
        faceRect = null;
        isFaceInPosition = false;
      }
    } catch (e) {
      text = 'Error: $e';
    }
    isBusy = false;
    update();
  }

  bool isRectInCircle(Rect rect, Size imageSize) {
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;
    final radius = centerX * 1.5; // 80% dari lebar gambar

    final rectCenterX = rect.left + rect.width / 2;
    final rectCenterY = rect.top + rect.height / 2;

    final distance =
        sqrt(pow(rectCenterX - centerX, 2) + pow(rectCenterY - centerY, 2));

    return distance + rect.width / 2 <= radius;
  }

  Future<void> loadSavedFaceImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedFaceImage = prefs.getString('user_image');
    savedFaceImageFilename = prefs.getString('user_image');

    print('Image Shared:$savedFaceImageFilename');
    if (savedFaceImage != null) {
      savedFaceImageBytes = base64Decode(savedFaceImage);
      imageFileBytes = savedFaceImageBytes;
    }
  }

  Future<bool> compareFaces(Uint8List? liveFaceImageBytes,
      Uint8List? savedFaceImageBytes, int bytesPerRow) async {
    if (savedFaceImageBytes == null || liveFaceImageBytes == null) {
      print("One or both face image bytes are null");
      return false;
    }

    print("Live face image bytes length: ${liveFaceImageBytes.length}");
    print("Saved face image bytes length: ${savedFaceImageBytes.length}");

    final liveFaceImage = InputImage.fromBytes(
      bytes: liveFaceImageBytes,
      metadata: InputImageMetadata(
        size: Size(640, 480),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: bytesPerRow,
      ),
    );

    final savedFaceImage = InputImage.fromBytes(
      bytes: savedFaceImageBytes,
      metadata: InputImageMetadata(
        size: Size(640, 480),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.bgra8888,
        bytesPerRow: bytesPerRow,
      ),
    );

    try {
      final liveFaces = await faceDetector.processImage(liveFaceImage);
      final savedFaces = await faceDetector.processImage(savedFaceImage);

      print("Number of live faces detected: ${liveFaces.length}");
      print("Number of saved faces detected: ${savedFaces.length}");

      if (liveFaces.isEmpty || savedFaces.isEmpty) {
        print("No faces detected in one or both images");
        return false;
      }

      final liveFace = liveFaces.first;
      final savedFace = savedFaces.first;

      print("Live face bounding box: ${liveFace.boundingBox}");
      print("Saved face bounding box: ${savedFace.boundingBox}");

      return compareFaceFeatures(liveFace, savedFace);
    } catch (e) {
      print("Error during face detection: $e");
      // print("Error stack trace: ${e}");
      return false;
    }
  }

  bool compareFaceFeatures(Face liveFace, Face savedFace) {
    // Bandingkan dimensi bounding box
    double liveFaceAspectRatio =
        liveFace.boundingBox.width / liveFace.boundingBox.height;
    double savedFaceAspectRatio =
        savedFace.boundingBox.width / savedFace.boundingBox.height;

    double aspectRatioDifference =
        (liveFaceAspectRatio - savedFaceAspectRatio).abs();

    // Bandingkan rotasi kepala jika tersedia
    double headRotationDifference = 0;
    if (liveFace.headEulerAngleY != null && savedFace.headEulerAngleY != null) {
      headRotationDifference =
          (liveFace.headEulerAngleY! - savedFace.headEulerAngleY!).abs();
    }

    // Bandingkan probabilitas mata terbuka jika tersedia
    double eyeOpenDifference = 0;
    if (liveFace.leftEyeOpenProbability != null &&
        savedFace.leftEyeOpenProbability != null) {
      eyeOpenDifference +=
          (liveFace.leftEyeOpenProbability! - savedFace.leftEyeOpenProbability!)
              .abs();
    }
    if (liveFace.rightEyeOpenProbability != null &&
        savedFace.rightEyeOpenProbability != null) {
      eyeOpenDifference += (liveFace.rightEyeOpenProbability! -
              savedFace.rightEyeOpenProbability!)
          .abs();
    }
    eyeOpenDifference /= 2; // Rata-rata perbedaan mata kiri dan kanan

    // Bandingkan probabilitas senyuman jika tersedia
    double smilingProbabilityDifference = 0;
    if (liveFace.smilingProbability != null &&
        savedFace.smilingProbability != null) {
      smilingProbabilityDifference =
          (liveFace.smilingProbability! - savedFace.smilingProbability!).abs();
    }

    // Anda dapat menyesuaikan ambang batas ini sesuai kebutuhan
    bool isMatch = aspectRatioDifference < 0.3 &&
        headRotationDifference < 20 &&
        eyeOpenDifference < 0.4 &&
        smilingProbabilityDifference < 0.4;

    print("Aspect ratio difference: $aspectRatioDifference");
    print("Head rotation difference: $headRotationDifference");
    print("Eye open difference: $eyeOpenDifference");
    print("Smiling probability difference: $smilingProbabilityDifference");
    print("Is match: $isMatch");

    return isMatch;
  }
}

//   double calculateDistance(Point<int> p1, Point<int> p2) {
//     return sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
//   }
// }
