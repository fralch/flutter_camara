// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import "dart:convert";
import 'package:dio/dio.dart';
import "package:http/http.dart" as http;
import "package:image_picker/image_picker.dart";
import 'package:camera/camera.dart';
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

Future<String?> _enviarForm(imagen64) async {
  var data = {'dato': 'imagen de prueba', 'img64': imagen64};
  var respuesta = await Api()
      .postDataImagen(data, "http://192.168.1.15:3000/subiendo_imagen");
  // var contenido = json.decode(respuesta.body);
  // if (contenido['success']) {
  //   print(contenido['mensaje']);
  // } else {
  //   print(contenido['mensaje']);
  // }
  print(respuesta);
  // return respuesta;
}

class Api {
  final String dominio = "";
  postDataImagen(_data, _url) async {
    return await http.post(Uri.http('192.168.1.15:3000', '/subiendo_imagen'),
        body: jsonEncode(_data),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Charset': 'utf-8'
        });
  }
}

// PAGINA DONDE SE MUESTRA LA IMAGEN
class ViewImagenScreen extends StatelessWidget {
  final String imagenPath;
  final List<int> archivo;
  final File foto;
  final String endPoint = 'http://192.168.1.15:3000/storage';

  const ViewImagenScreen(
      {super.key,
      required this.imagenPath,
      required this.archivo,
      required this.foto});

  // @override
  Future<String?> uploadImage(filename) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.1.15:3000/storage'));
    request.files.add(await http.MultipartFile.fromPath('file', filename));
    var res = await request.send();
    // return res.reasonPhrase;
  }

  Future<String?> _upload(File file) async {
    String fileName = file.path.split('/').last;
    print(fileName);

    List<int> imgbytes = await new File(file.path).readAsBytesSync();

    FormData data = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    Dio dio = new Dio();

    dio.post(endPoint, data: imgbytes).then((response) {
      var jsonResponse = jsonDecode(response.toString());
      ;
    }).catchError((error) => print(error));
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
          //-----
          // await _enviarForm(archivo);
          // await _upload(foto);
          await uploadImage(imagenPath);
          print('guardado');
          // var res = await uploadImage(
          //     File(file.path), "192.168.1.15/cre/cli/subir_imagen");
          // var res = await showAlertDialog(context);
          // print(res);
        },
      ),
    );
  }
}
