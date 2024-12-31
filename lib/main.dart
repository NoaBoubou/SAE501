import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/painting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/historique.dart';
import 'package:untitled/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialisation de Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(), // Page par défaut : LoginPage
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
  List<Map<String, dynamic>>? _recognitions;
  final FlutterVision _vision = FlutterVision();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel(); // Charge le modèle YOLO au démarrage
  }

  final userId = FirebaseAuth.instance.currentUser?.uid;


  Future<List<Map<String, dynamic>>> getHistorique() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    List<Map<String, dynamic>> historiqueData = [];

    try {
      QuerySnapshot usersSnapshot = await db.collection("users").get();

      var historiqueSnapshot = await db.collection("users").doc(userId).collection("historique").get();

        for (var histoDoc in historiqueSnapshot.docs) {
          Map<String, dynamic> entry = {
            'userId': userId,
            'historiqueId': histoDoc.id,
            ...histoDoc.data(),
          };

          historiqueData.add(entry);
        }
    } catch (e) {
      print("Erreur lors de la récupération de l'historique : $e");
    }
    print(historiqueData);

    return historiqueData;
  }

  @override
  void dispose() {
    _vision.closeYoloModel(); // Libère les ressources du modèle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Déconnexion Firebase
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    List<Map<String, dynamic>> historiqueData = await getHistorique();
                    Navigator.pop(context);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoriquePage(historique: historiqueData),
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Erreur"),
                        content: Text("Impossible de récupérer l'historique : $e"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: const Text("Voir l'historique"),
              ),
              const SizedBox(height: 20),
              _imageSelectionnee != null
                  ? Image.file(_imageSelectionnee!)
                  : Image.asset('assets/galery.png'),
              const SizedBox(height: 20),
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
                        'Objet: ${result['tag']}, Confiance: ${(result['box'][4] * 100).toStringAsFixed(2)}%',
                        style: const TextStyle(fontSize: 14),
                      );
                    }),
                  ],
                ),
              const SizedBox(height: 20),
              _imageSelectionnee == null
                  ? Column(
                children: [
                  ElevatedButton(
                    onPressed: _prendreImageCamera,
                    child: const Text("Prendre une photo avec la caméra"),
                  ),
                  ElevatedButton(
                    onPressed: _prendreImageGalerie,
                    child: const Text("Prendre une photo de la galerie"),
                  ),
                ],
              )
                  : Column(
                children: [
                  ElevatedButton(
                    onPressed: _enregistrerImageFirestore,
                    child: const Text("Enregistrer"),
                  ),
                  ElevatedButton(
                    onPressed: _annulerImage,
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
    final imageRetournee =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageRetournee == null) return;
    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
    });
    _detectImage(_imageSelectionnee!);
  }

  Future _prendreImageCamera() async {
    final imageRetournee =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageRetournee == null) return;
    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
    });
    _detectImage(_imageSelectionnee!);
  }

  Future _enregistrerImageFirestore() async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid);
      CollectionReference historiqueCollection = userDoc.collection('historique');
      DateTime today = DateTime.now();
      String dateStr = "${today.day}/${today.month}/${today.year}";

      Map<String, dynamic> data = {
        'resultats': resultats,
        'date': dateStr,
      };

      DocumentReference docRef = await historiqueCollection.add(data);
      String docId = docRef.id;

      print('Données enregistrées : $data');

      _enregistrerImageStorage(docId);

      return(docId);
    } catch (e) {
      print('Erreur lors de l\'enregistrement dans Firebase : $e');
    }
  }

  Future _enregistrerImageStorage(String docId) async {
    if (_imageSelectionnee != null) {
      print("rentré !");
      try {
        FirebaseStorage storage = FirebaseStorage.instance;

        String filePath = 'user/$userId/$docId.jpg';
        Reference ref = storage.ref().child(filePath);

        UploadTask uploadTask = ref.putFile(_imageSelectionnee!);

        setState(() {
          _imageSelectionnee = null;
          _recognitions = null;
          resultats = [];
        });

      } catch (e) {
        print('Erreur lors du téléchargement de l\'image: $e');
      }
    }
  }

  Future _annulerImage() async {
    setState(() {
      _imageSelectionnee = null;
      _recognitions = null;
      resultats = [];
    });
  }

  Future<File> _annoterImage(File image, List<Map<String, dynamic>> recognitions) async {
    final imageBytes = await image.readAsBytes();
    final originalImage = await decodeImageFromList(imageBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paintImage = Paint();
    canvas.drawImage(
      originalImage,
      Offset.zero,
      paintImage,
    );

    final paintBox = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (final result in recognitions) {
      final box = result['box'];
      final tag = result['tag'];
      final confidence = (box[4] * 100).toStringAsFixed(2);

      canvas.drawRect(
        Rect.fromLTRB(
          box[0].toDouble(),
          box[1].toDouble(),
          box[2].toDouble(),
          box[3].toDouble(),
        ),
        paintBox,
      );

      final textSpan = TextSpan(
        text: '$tag ($confidence%)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(box[0].toDouble(), box[1].toDouble() - 20));
    }

    final picture = recorder.endRecording();
    final annotatedImage = await picture.toImage(
      originalImage.width,
      originalImage.height,
    );

    final byteData = await annotatedImage.toByteData(format: ui.ImageByteFormat.png);
    final annotatedImageBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/annotated_image.png';
    final annotatedFile = File(path);
    await annotatedFile.writeAsBytes(annotatedImageBytes);

    return annotatedFile;
  }

  List<Map<String, dynamic>> resultats = [];

  Future _detectImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    final imageBytes = await image.readAsBytes();
    final result = await _vision.yoloOnImage(
      bytesList: imageBytes,
      imageHeight: 640,
      imageWidth: 640,
      confThreshold: 0.4,
      iouThreshold: 0.4,
      classThreshold: 0.5,
    );
    print("résultat de la détection");

    for (var detection in result) {
      var objectClass = detection['tag'];
      var confiance = "${(detection['box'][4] * 100).toStringAsFixed(2)}%";

      var resultMap = {
        'object_class': objectClass,
        'confiance': confiance,
      };

      print(resultMap);

      resultats.add(resultMap);
    }

    print(resultats);

    final annotatedImage = await _annoterImage(image, result.cast<Map<String, dynamic>>());

    setState(() {
      _recognitions = result.cast<Map<String, dynamic>>(); // Met à jour la variable _recognitions
      _imageSelectionnee = annotatedImage;
      _isLoading = false;
    });
  }

  _loadModel() async {
    await _vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolov5.tflite',
      modelVersion: "yolov5",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
    print("Modèle chargé");
  }
}
