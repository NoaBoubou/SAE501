import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/painting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:untitled/tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase Auth',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: const AuthChecker(),
    );
  }
}

class AuthChecker extends StatelessWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const TabPage();
    } else {
      return const LoginPage();
    }
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
  bool? _isCorrect;
  final TextEditingController _correctionController = TextEditingController();
  List<Map<String, dynamic>> resultats = [];
  List<TextEditingController> _controllers = [];
  File? _imageOriginale; 



  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  @override
  void dispose() {
    _vision.closeYoloModel();
    _correctionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
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
                    _imageSelectionnee != null
                        ? Image.file(_imageSelectionnee!)
                        : Image.asset('assets/galery.png'),
                    const SizedBox(height: 20),

                    if (_recognitions != null && _recognitions!.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              const Text('Résultats de la détection :',
                                  style: TextStyle(fontWeight: FontWeight.bold)),

                              ..._recognitions!.map((result) => Text(
                                    'Objet: ${result['tag']}, Confiance: ${(result['box'][4] * 100).toStringAsFixed(2)}%',
                                  )),

                              const SizedBox(height: 10),

                              if (_isCorrect == null)
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => setState(() => _isCorrect = true),
                                          child: const Text("Correct"),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _isCorrect = false;
                                              _controllers = List.generate(
                                                _recognitions!.length,
                                                    (index) => TextEditingController(
                                                    text: _recognitions![index]['tag']),
                                              );
                                            });
                                          },
                                          child: const Text("Incorrect"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10), // Espacement entre les boutons
                                    ElevatedButton(
                                      onPressed: _annulerImage,
                                      child: const Text("Annuler"),
                                    ),
                                  ],
                                )

                              else if (_isCorrect == true)
                                Column(
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
                                )

                              else
                                Column(
                                  children: [
                                    const Text(
                                      "Corrigez les erreurs détectées :",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    for (int i = 0; i < _recognitions!.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                                        child: TextField(
                                          controller: _controllers[i],
                                          decoration: InputDecoration(
                                            labelText: "Correction pour ${_recognitions![i]['tag']}",
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 10),

                                    // Les boutons côte à côte dans un Row
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center, // Centre les boutons
                                      children: [
                                        ElevatedButton(
                                          onPressed: _envoyerCorrection,
                                          child: const Text("Valider la correction"),
                                        ),
                                        const SizedBox(width: 10), // Espacement entre les boutons
                                        ElevatedButton(
                                          onPressed: _annulerImage,
                                          child: const Text("Annuler"),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                            ],
                          ),
                        ),
                      )
                    else if (_imageSelectionnee != null)
                      Column(
                        children: [
                          const Text("Aucun objet détecté."),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _annulerImage,
                            child: const Text("Annuler"),
                          ),
                        ],
                      ),
    if (_imageSelectionnee == null)
                      Column(
                        children: [
                          SizedBox(
                            width: 300,
                            child: ElevatedButton.icon(
                              onPressed: _prendreImageCamera,
                              icon: const Icon(Icons.camera_alt, color: Colors.orange),
                              label: const Text(
                                "Prendre une photo avec la caméra",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 300,
                            child: ElevatedButton.icon(
                              onPressed: _prendreImageGalerie,
                              icon: const Icon(Icons.photo_album, color: Colors.orange),
                              label: const Text(
                                "Prendre une photo de la galerie",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Future _prendreImageCamera() async {
    final imageRetournee = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageRetournee == null) return;
    
    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
      _imageOriginale = File(imageRetournee.path); 
    });

    _detectImage(_imageSelectionnee!);
  }

  Future _prendreImageGalerie() async {
    final imageRetournee = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageRetournee == null) return;

    setState(() {
      _imageSelectionnee = File(imageRetournee.path);
      _imageOriginale = File(imageRetournee.path);
    });

    // Efface le cache des images pour forcer le rechargement
    imageCache.clear(); 
    imageCache.clearLiveImages();

    _detectImage(_imageSelectionnee!);
  }




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
      _recognitions = result.cast<Map<String, dynamic>>();
      _imageSelectionnee = annotatedImage;
      _isLoading = false;
    });
  }

  Future<File> _annoterImage(File imageVierge, List<Map<String, dynamic>> recognitions) async {
    final imageBytes = await imageVierge.readAsBytes();
    final originalImage = await decodeImageFromList(imageBytes);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paintImage = Paint();
    canvas.drawImage(originalImage, Offset.zero, paintImage);

    final paintBox = Paint()
      ..color = const Color(0xFFFF0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(textAlign: TextAlign.end, textDirection: ui.TextDirection.ltr);

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
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.text = textSpan;
      textPainter.layout();
      textPainter.paint(canvas, Offset(box[0].toDouble(), box[1].toDouble() - 20));
    }

    final picture = recorder.endRecording();
    final annotatedImage = await picture.toImage(originalImage.width, originalImage.height);

    final byteData = await annotatedImage.toByteData(format: ui.ImageByteFormat.png);
    final annotatedImageBytes = byteData!.buffer.asUint8List();

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/corrected_image.png';
    final correctedFile = File(path);
    await correctedFile.writeAsBytes(annotatedImageBytes);

    return correctedFile;
  }




  Future _enregistrerImageFirestore() async {
    try {
      DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid);
      CollectionReference historiqueCollection = userDoc.collection('historique');
      DateTime today = DateTime.now();

      String dateStr = DateFormat("dd/MM/yyyy").format(today);

      Map<String, dynamic> data = {
        'resultats': resultats,
        'date': dateStr,
      };

      DocumentReference docRef = await historiqueCollection.add(data);
      String docId = docRef.id;

      _enregistrerImageStorage(docId);

      setState(() {
        _imageSelectionnee = null;
      });

      return(docId);
    } catch (e) {
      print('Erreur lors de l\'enregistrement dans Firebase : $e');
    }
  }

  Future<void> _enregistrerImageStorage(String docId) async {
    if (_imageSelectionnee != null) {
      setState(() {
        _recognitions = null;
        _isCorrect = null;
      });

      try {
        FirebaseStorage storage = FirebaseStorage.instance;
        String userId = FirebaseAuth.instance.currentUser!.uid;
        String filePath = 'user/$userId/$docId.jpg';
        Reference ref = storage.ref().child(filePath);

        UploadTask uploadTask = ref.putFile(_imageSelectionnee!);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('historique')
            .doc(docId)
            .set({'imageUrl': downloadUrl}, SetOptions(merge: true));

        setState(() {
          _imageSelectionnee = null;
          resultats = [];
        });

      } catch (e) {
        print('Erreur lors du téléchargement de l\'image: $e');
      }
    }
  }

  Future _envoyerCorrection() async {
    if (_imageOriginale == null) return;

    setState(() {
      _isLoading = true;
    });

    List<Map<String, dynamic>> _correctedRecognitions = [];

    for (int i = 0; i < _recognitions!.length; i++) {
      _correctedRecognitions.add({
        'tag': _controllers[i].text, 
        'box': _recognitions![i]['box'],
      });
    }

    final correctedImage = await _annoterImage(_imageOriginale!, _correctedRecognitions);

    await _enregistrerImagePourAdmin(correctedImage);

    setState(() {
      _imageSelectionnee = null;
      _isCorrect = null;
      _recognitions = null;
      resultats = [];
      _isLoading = false;
    });
  }



  Future<void> _enregistrerImagePourAdmin(File image) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String filePath = 'Admin/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = storage.ref().child(filePath);

      await ref.putFile(image);
    } catch (e) {
      print('Erreur lors de l\'enregistrement de l\'image pour l\'admin: $e');
    }
  }





  Future _annulerImage() async {
    setState(() {
      imageCache.clear();
      imageCache.clearLiveImages();
      _imageOriginale = null;
      _imageSelectionnee = null;
      _recognitions = null;
      _isCorrect = null;
      resultats = [];
    });
  }


  _loadModel() async {
    await _vision.loadYoloModel(
      labels: 'assets/labels/labelsFruits.txt',
      modelPath: 'assets/models/modelFruits.tflite',
      modelVersion: "yolov5",
      quantization: false,
      numThreads: 1,
      useGpu: false,
    );
  }
}
