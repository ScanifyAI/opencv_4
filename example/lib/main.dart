import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opencv_4/factory/pathfrom.dart';
import 'package:opencv_4/opencv_4.dart';
//uncomment when image_picker is installed
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as im;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'opencv_4 Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  Uint8List? _byte, salida;
  String _versionOpenCV = 'OpenCV';
  bool _visible = false;
  //uncomment when image_picker is installed
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  testOpenCV({
    required String pathString,
    required CVPathFrom pathFrom,
    required double thresholdValue,
    required double maxThresholdValue,
    required int thresholdType,
  }) async {
    try {
      //test with threshold
      var image = im.decodeImage(File(pathString).readAsBytesSync())!;

      _byte = await Cv2.adaptiveThreshold(
          pathFrom: pathFrom,
          pathString: pathString,
          thresholdType: thresholdType,
          constantValue: 30,
          blockSize: 19,
          adaptiveMethod: Cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
          maxValue: 255,
          buffer: image.getBytes(format: im.Format.rgba),
          height: image.height,
          width: image.width);
      var retImage = im.Image.fromBytes(image.width, image.height, _byte!,
          format: im.Format.luminance);
      //retImage = im.copyResize(retImage, width: 100, height: 100);
      _byte = Uint8List.fromList(im.encodeJpg(retImage));

      setState(() {
        _byte;
        _visible = false;
      });
    } on PlatformException catch (e) {
      print(e.message);
    }
  }

  _testFromCamera() async {
    //uncomment when image_picker is installed
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if (pickedFile == null) return;
    _image = File(pickedFile.path);

    testOpenCV(
      pathFrom: CVPathFrom.GALLERY_CAMERA,
      pathString: _image!.path,
      thresholdValue: 150,
      maxThresholdValue: 200,
      thresholdType: Cv2.THRESH_BINARY,
    );

    setState(() {
      _visible = true;
    });
  }

  _testFromGallery() async {
    //uncomment when image_picker is installed
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    _image = File(pickedFile.path);

    testOpenCV(
      pathFrom: CVPathFrom.RGBA_BUFFER,
      pathString: _image!.path,
      thresholdValue: 150,
      maxThresholdValue: 200,
      thresholdType: Cv2.THRESH_BINARY,
    );

    setState(() {
      _visible = true;
    });
  }

  _testFromCropAndScan() async {
    //uncomment when image_picker is installed
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    _image = File(pickedFile.path);

    // _byte = await Cv2.cropAndscan();

    setState(() {
      _byte;
      _visible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Container(
                  margin: EdgeInsets.only(top: 20),
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                          _versionOpenCV,
                          style: TextStyle(fontSize: 23),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 5),
                          child: _byte != null
                              ? Image.memory(
                                  _byte!,
                                  width: 300,
                                  height: 300,
                                  fit: BoxFit.fill,
                                )
                              : Container(
                                  width: 300,
                                  height: 300,
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.grey[800],
                                  ),
                                ),
                        ),
                        Visibility(
                            maintainAnimation: true,
                            maintainState: true,
                            visible: _visible,
                            child:
                                Container(child: CircularProgressIndicator())),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 40,
                          child: TextButton(
                            child: Text('test gallery'),
                            onPressed: _testFromGallery,
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.teal,
                              onSurface: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width - 40,
                          child: TextButton(
                            child: Text('test camara'),
                            onPressed: _testFromCamera,
                            style: TextButton.styleFrom(
                              primary: Colors.white,
                              backgroundColor: Colors.teal,
                              onSurface: Colors.grey,
                            ),
                          ),
                        ),
                        // SizedBox(
                        //   width: MediaQuery.of(context).size.width - 40,
                        //   child: TextButton(
                        //     child: Text('CROP TO SCAN'),
                        //     onPressed: _testFromCropToScan(),
                        //     style: TextButton.styleFrom(
                        //       primary: Colors.white,
                        //       backgroundColor: Colors.teal,
                        //       onSurface: Colors.grey,
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
