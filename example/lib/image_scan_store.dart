import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_4/opencv_4.dart';

class ImageScanStore {
  final File file;
  final double widgetW;
  final double widgetH;

  final double imageW;
  final double imageH;
  final Offset tl, tr, bl, br;
  final MethodChannel channel = new MethodChannel('opencv');

  late double tlX;
  late double trX;
  late double blX;
  late double brX;
  late double tlY;
  late double trY;
  late double blY;
  late double brY;

  late Uint8List currentFileBytes;
  int angle = 0;

  ImageScanStore({
    required this.file,
    required this.widgetW,
    required this.widgetH,
    required this.imageW,
    required this.imageH,
    required this.tl,
    required this.tr,
    required this.bl,
    required this.br,
  });

  // NOTE

  init() {
    tlX = (imageW / widgetW) * tl.dx;
    trX = (imageW / widgetW) * tr.dx;
    blX = (imageW / widgetW) * bl.dx;
    brX = (imageW / widgetW) * br.dx;

    tlY = (imageH / widgetH) * tl.dy;
    trY = (imageH / widgetH) * tr.dy;
    blY = (imageH / widgetH) * bl.dy;
    brY = (imageH / widgetH) * br.dy;
  }

  Future<bool> convertToGray() async {
    try {
      // ?? NOTO
      // List<int> imageBytes = await file.readAsBytes();

      // final originalImage = img.decodeImage(imageBytes);

      // final height = originalImage.height;
      // final width = originalImage.width;

      // if (height <= width) {
      //   final exifData = await readExifFromBytes(imageBytes);
      //   img.Image fixedImage = img.copyRotate(originalImage, 90);
      //   final fixedFile = await file.writeAsBytes(img.encodeJpg(fixedImage));

      //   final aaaa = img.decodeImage(fixedFile.readAsBytesSync());
      //   log('## [$width] [$height]  || ${(height >= width)} || ${exifData['Image Orientation']} ##');
      //   log('### [${aaaa.width}] [${aaaa.height}]');
      // }

      // END
      var _byte = await Cv2.cropAndscan(
        pathString: file.path,
        tlX: tlX,
        tlY: tlY,
        trX: trX,
        trY: trY,
        blX: blX,
        blY: blY,
        brX: brX,
        brY: brY,
      );
      currentFileBytes = _byte!;
      return true;
    } catch (e) {
      log('LOX ==> [$e]');
      return false;
    }
  }

  Future<bool> rotateScan() async {
    try {
      await Future.delayed(Duration(seconds: 1));

      currentFileBytes = await channel.invokeMethod('rotate', {
        'bytes': currentFileBytes
      });

      await Future.delayed(Duration(seconds: 4));

      angle = (angle == 360) ? 0 : angle + 90;
      currentFileBytes = await channel.invokeMethod('rotateCompleted', {
        'bytes': currentFileBytes
      });
      return true;
    } catch (e) {
      log('LOX ==> [$e]');
      return false;
    }
  }
}
