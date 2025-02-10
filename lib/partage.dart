import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PartagePage extends StatelessWidget {
  const PartagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Partages"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); // Redirige vers la page de connexion
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('partages').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final partages = snapshot.data!.docs.where((doc) {
            List<dynamic> recipients = doc['recipients'];
            return doc['senderId'] == userId || recipients.contains(userId);
          }).toList();

          if (partages.isEmpty) {
            return const Center(
              child: Text(
                "Aucun partage disponible.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _getAllPartageDetails(partages),
            builder: (context, detailsSnapshot) {
              if (!detailsSnapshot.hasData) return const Center(child: CircularProgressIndicator());

              final detailsList = detailsSnapshot.data!;

              return ListView.builder(
                itemCount: detailsList.length,
                itemBuilder: (context, index) {
                  final details = detailsList[index];

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
                            details['title'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Détection du ${details['date']}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          ...details['detectionResults'].map<Widget>((result) {
                            return Text(
                              'Objet : ${result['object_class']} avec une confiance de ${result['confiance']}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _voirImage(context, details['detectionId'], details['senderId']);
                            },
                            child: const Text('Voir Image', style: TextStyle(color: Colors.black)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),

    );
  }

  Future<List<Map<String, dynamic>>> _getAllPartageDetails(List<QueryDocumentSnapshot> partages) async {
    List<Future<Map<String, dynamic>>> futures = partages.map((partage) async {
      String senderId = partage['senderId'];
      String detectionId = partage['detectionId'];
      List<String> recipients = List<String>.from(partage['recipients']);
      String date = partage['date'];

      String senderName = await _getUserName(senderId);
      List<String> recipientNames = await Future.wait(recipients.map(_getUserName));
      List<Map<String, dynamic>> detectionResults = await _getDetectionResults(senderId, detectionId);

      return {
        'title': senderId == FirebaseAuth.instance.currentUser!.uid
            ? "Vous avez partagé à ${recipientNames.join(", ")}"
            : "Partagé par $senderName",
        'detectionResults': detectionResults,
        'detectionId': detectionId,
        'senderId': senderId,
        'date': date,
      };
    }).toList();

    return await Future.wait(futures);
  }

  Future<Map<String, dynamic>> _getPartageDetails(
      String senderId, List<String> recipients, String detectionId) async {
    String senderName = await _getUserName(senderId);

    List<String> recipientNames = [];
    for (String recipientId in recipients) {
      String name = await _getUserName(recipientId);
      recipientNames.add(name);
    }

    List<Map<String, dynamic>> detectionResults = await _getDetectionResults(senderId, detectionId);

    return {
      'title': senderId == FirebaseAuth.instance.currentUser!.uid
          ? "Vous avez partagé à ${recipientNames.join(", ")}"
          : "Partagé par $senderName",
      'detectionResults': detectionResults,
    };
  }

  Future<String> _getUserName(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      return userDoc.exists ? userDoc['name'] : "Utilisateur inconnu";
    } catch (e) {
      return "Utilisateur inconnu";
    }
  }

  Future<List<Map<String, dynamic>>> _getDetectionResults(
      String senderId, String detectionId) async {
    try {
      DocumentSnapshot detectionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('historique')
          .doc(detectionId)
          .get();

      if (detectionDoc.exists) {
        return List<Map<String, dynamic>>.from(detectionDoc['resultats']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void _voirImage(BuildContext context, String detectionId, String senderId) async {
    try {
      DocumentSnapshot detectionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('historique')
          .doc(detectionId)
          .get();

      if (detectionDoc.exists && detectionDoc['imageUrl'] != null) {
        String imageUrl = detectionDoc['imageUrl'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDisplayPage(imageUrl: imageUrl),
          ),
        );
      } else {
        throw Exception("Image introuvable dans Firestore.");
      }
    } catch (e) {
      print("Erreur de chargement de l'image : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : Image introuvable')),
      );
    }
  }
}

class ImageDisplayPage extends StatelessWidget {
  final String imageUrl;

  const ImageDisplayPage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Partagée'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text('Erreur lors du chargement de l\'image'),
            );
          },
        ),
      ),
    );
  }
}
