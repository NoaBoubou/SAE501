import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
import 'package:untitled/login_page.dart';

class HistoriquePage extends StatelessWidget {
  final List<Map<String, dynamic>> historique;
  final String title;

  const HistoriquePage({Key? key, required this.historique, required this.title}) : super(key: key);

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
    // Créer une copie modifiable de la liste historique
    List<Map<String, dynamic>> historiqueCopy = List.from(historique);

    // Trier la copie de la liste
    historiqueCopy.sort((a, b) {
      DateTime dateA = DateFormat("dd/MM/yyyy").parse(a['date']);
      DateTime dateB = DateFormat("dd/MM/yyyy").parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(this.title),
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
      body: historiqueCopy.isEmpty
          ? Center(
        child: Text(
          'Aucun historique disponible.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: historiqueCopy.length,
        itemBuilder: (context, index) {
          final entry = historiqueCopy[index];
          final userId = entry['userId'];
          final detectionId = entry['historiqueId'];
          final resultats = entry['resultats'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détection du ${entry['date']}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...resultats.map<Widget>((detection) {
                    var objectClass = detection['object_class'];
                    var confiance = detection['confiance'];

                    return Text(
                      'Objet : $objectClass avec une confiance de $confiance',
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton(
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
                      child: const Text('Voir Image', style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
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
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return const Center(
              child: Text('Erreur lors du chargement de l\'image'),
            );
          },
        ),
      ),
    );
  }
}