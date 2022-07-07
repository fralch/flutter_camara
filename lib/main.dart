// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import "dart:convert";
import "package:http/http.dart" as http;
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename, join;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  // final firstCamera = cameras.first;
  final firstCamera = cameras[1];
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

  late String _image64;

  @override
  void initState() {
    super.initState();
    _cameraCtrl = CameraController(widget.camera, ResolutionPreset.low);
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
            File file_ = File(picture.path);

            List<int> bytes = await new File(picture.path).readAsBytesSync();

            _image64 = base64.encode(bytes);
            // await _enviarForm(_image64);
            // await uploadImageDio(file);

            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ViewImagenScreen(
                          imagenPath: path,
                          archivo: bytes,
                          foto: file_,
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
  final List<int> archivo;
  final File foto;

  const ViewImagenScreen(
      {super.key,
      required this.imagenPath,
      required this.archivo,
      required this.foto});
  // @override

  //mandar post a la api
  Future<void> _enviarForm(File image) async {
    try {
      var image64 = await _convertImageToBase64(image);
      var url = Uri.parse('http://192.168.1.15/cre/cli/subir_imagen');
      final response = await http.post(url,
          body: json.encode({
            "file": image64,
            "upload_preset": "qzqxqjqe",
          }),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Charset': 'utf-8',
          });
      print(response.body);
    } catch (e) {
      print(e);
    }
  }

  Future<String> _convertImageToBase64(File image) async {
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    return base64Image;
  }

  showAlertDialog(BuildContext context) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {},
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("My title"),
      content: Text('guardado'),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('vista de foto tomada')),
      body: Image.file(File(imagenPath)),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          // await uploadImage(imagenPath);
          await _enviarForm(foto);
          print('guardado');
        },
      ),
    );
  }
}
