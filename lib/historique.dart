import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HistoriquePage extends StatelessWidget {
  final List<Map<String, dynamic>> historique;

  const HistoriquePage({Key? key, required this.historique}) : super(key: key);

  Future<String> getImgByDetection(String userId, String detectionId) async {
    try {
      print("user/$userId/$detectionId.jpg");
      final storageRef = FirebaseStorage.instance.ref();
      final imageUrl = await storageRef.child("user/$userId/$detectionId.jpg").getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Erreur lors de la récupération de l\'image: $e');
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
      ),
      body: ListView.builder(
        itemCount: historique.length,
        itemBuilder: (context, index) {
          final entry = historique[index];
          final userId = entry['userId'];
          final detectionId = entry['historiqueId'];
          final resultats = entry['resultats'];

          return ListTile(
            title: Text('Détection du ${entry['date']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...resultats.map<Widget>((detection) {
                  var objectClass = detection['object_class'];
                  var confiance = detection['confiance'];

                  return Text('Objet : $objectClass avec une confiance de $confiance');
                }).toList(),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child:Center
                  (child: ElevatedButton(
                    onPressed: () async {
                      final imageUrl = await getImgByDetection(userId, detectionId);
                      if (imageUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageDisplayPage(imageUrl: imageUrl),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image introuvable')),
                        );
                      }
                    },
                    child: const Text('Voir Image'),
                  ),)
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ImageDisplayPage extends StatelessWidget {
  final String imageUrl;

  const ImageDisplayPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
