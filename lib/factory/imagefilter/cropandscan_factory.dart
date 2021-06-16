import 'dart:typed_data';

import 'package:flutter/services.dart';

///Class for process [CropAndScanFactory]
class CropAndScanFactory {
  static const platform = const MethodChannel('opencv_4');

  static Future<Uint8List?> cropAndScan({
    required String pathString,
    required double tlX,
    required double tlY,
    required double trX,
    required double trY,
    required double blX,
    required double blY,
    required double brX,
    required double brY,
  }) async {
    Uint8List? result = await platform.invokeMethod('cropAndScan', {
      'pathString': pathString,
      'tl_x': tlX,
      'tl_y': tlY,
      'tr_x': trX,
      'tr_y': trY,
      'bl_x': blX,
      'bl_y': blY,
      'br_x': brX,
      'br_y': brY,
    });

    return result;
  }
}

// switch (pathFrom) {
//   case CVPathFrom.GALLERY_CAMERA:
//     result = await platform.invokeMethod('cropToScan', {
//       'pathString': 'pathString',
//       'tl_x': tlX,
//       'tl_y': tlY,
//       'tr_x': trX,
//       'tr_y': trY,
//       'bl_x': blX,
//       'bl_y': blY,
//       'br_x': brX,
//       'br_y': brY,
//     });
//     break;
//   case CVPathFrom.URL:
//     _file = await DefaultCacheManager().getSingleFile(pathString);
//     result = await platform.invokeMethod('cropToScan', {
//       'pathType': 2,
//       'pathString': '',
//       'data': await _file.readAsBytes(),
//       'diameter': diameterTemp,
//       'sigmaColor': sigmaColor,
//       'sigmaSpace': sigmaSpace,
//       'borderType': borderTypeTemp,
//     });

//     break;
//   case CVPathFrom.ASSETS:
//     _fileAssets = await Utils.imgAssets2Uint8List(pathString);
//     result = await platform.invokeMethod('bilateralFilter', {
//       'pathType': 3,
//       'pathString': '',
//       'data': _fileAssets,
//       'diameter': diameterTemp,
//       'sigmaColor': sigmaColor,
//       'sigmaSpace': sigmaSpace,
//       'borderType': borderTypeTemp,
//     });
//     break;
// }
