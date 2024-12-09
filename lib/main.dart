import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Détection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Détection d\'objets'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _imageSelectionnee;
  List<dynamic>? _recognitions;

  @override
  void initState() {
    super.initState();
    loadModel(); // Chargez le modèle au démarrage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),

              // Affiche l'image sélectionnée ou une image par défaut
              _imageSelectionnee != null
                  ? Image.file(_imageSelectionnee!)
                  : Image.asset('assets/galery.png'),

              const SizedBox(height: 20),

              // Affiche les résultats de reconnaissance
              if (_recognitions != null && _recognitions!.isNotEmpty)
                Column(
                  children: [
                    const Text(
                      'Résultats de la détection :',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._recognitions!.map((result) {
                      return Text(
                        'Index: ${result['index']}, Étiquette: ${result['label']}, Confiance: ${(result['confidence'] * 100).toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 14),
                      );
                    }).toList(),
                  ],
                ),

              const SizedBox(height: 20),

              // Affiche les boutons en fonction de l'état de l'image
              _imageSelectionnee == null
                  ? Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _prendreImageCamera();
                    },
                    child: const Text("Prendre une photo avec la caméra"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _prendreImageGalerie();
                    },
                    child: const Text("Prendre une photo de la galerie"),
                  ),
                ],
              )
                  : Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _enregisterImage();
                    },
                    child: const Text("Enregistrer"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _annulerImage();
                    },
                    child: const Text("Annuler"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _prendreImageGalerie() async {
    final imageRetournee = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageRetournee == null) return;
    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
    });
    _detectImage(_imageSelectionnee!);
  }

  Future _prendreImageCamera() async {
    final imageRetournee = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageRetournee == null) return;
    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
    });
    _detectImage(_imageSelectionnee!);
  }

  Future _enregisterImage() async {
    // Ajouter ici le code pour enregistrer l'image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Image enregistrée !")),
    );
  }

  Future _annulerImage() async {
    setState(() {
      _imageSelectionnee = null;
      _recognitions = null;
    });
  }

  Future _detectImage(File image) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    setState(() {
      _recognitions = recognitions;
    });

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/yolov8n_float32.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }
}
