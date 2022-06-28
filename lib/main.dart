import 'dart:async';
import 'dart:io';
import "dart:convert";
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyHomePage(camera: firstCamera),
  ));
}

class MyHomePage extends StatefulWidget {
  final CameraDescription camera;
  const MyHomePage({Key? key, required this.camera}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late CameraController _cameraCtrl;
  late Future<void> _initCameraFuture;

  @override
  void initState() {
    super.initState();
    _cameraCtrl = CameraController(widget.camera, ResolutionPreset.medium);
    _initCameraFuture = _cameraCtrl.initialize();
  }

  @override
  void dispose() {
    _cameraCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('probando camara'),
      ),
      body: FutureBuilder<void>(
          future: _initCameraFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return CameraPreview(_cameraCtrl);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initCameraFuture;
            final path = join(
                (await getTemporaryDirectory()).path, '${DateTime.now()}.png');
            XFile picture = await _cameraCtrl.takePicture();
            picture.saveTo(path);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ViewImagenScreen(
                          imagenPath: path,
                        )));
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

// PAGINA DONDE SE MUESTRA LA IMAGEN
class ViewImagenScreen extends StatelessWidget {
  final String imagenPath;

  const ViewImagenScreen({super.key, required this.imagenPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('vista de foto tomada')),
      body: Image.file(File(imagenPath)),
    );
  }
}
