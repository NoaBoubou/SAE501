import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:untitled/login_page.dart';

class HistoriquePage extends StatelessWidget {
  final List<Map<String, dynamic>> historique;
  final String title;

  const HistoriquePage({Key? key, required this.historique, required this.title}) : super(key: key);

  Future<String> getImgByDetection(String userId, String detectionId) async {
    try {
      DocumentSnapshot detectionDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('historique')
          .doc(detectionId)
          .get();

      if (detectionDoc.exists && detectionDoc['imageUrl'] != null) {
        return detectionDoc['imageUrl'];
      } else {
        throw Exception("Image introuvable dans Firestore.");
      }
    } catch (e) {
      print('Erreur lors de la récupération de l\'image: $e');
      return '';
    }
  }

  void _showShareModal(BuildContext context, String detectionId) {
    List<String> selectedUsers = [];
    TextEditingController searchController = TextEditingController();
    String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Partager avec :"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Rechercher un utilisateur',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('users').get(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const CircularProgressIndicator();
                          final users = snapshot.data!.docs.where((user) {
                            String name = user['name'].toLowerCase();
                            return name.contains(searchController.text.toLowerCase()) && user.id != currentUserId;
                          }).toList();

                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              var user = users[index];
                              return CheckboxListTile(
                                title: Text(user['name']),
                                value: selectedUsers.contains(user.id),
                                onChanged: (bool? selected) {
                                  setState(() {
                                    if (selected == true) {
                                      selectedUsers.add(user.id);
                                    } else {
                                      selectedUsers.remove(user.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedUsers.isNotEmpty) {
                      FirebaseFirestore.instance.collection('partages').add({
                        'senderId': FirebaseAuth.instance.currentUser!.uid,
                        'detectionId': detectionId,
                        'date': DateFormat("dd/MM/yyyy").format(DateTime.now()),
                        'recipients': selectedUsers,
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Partager"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> historiqueCopy = List.from(historique);
    historiqueCopy.sort((a, b) {
      DateTime dateA = DateFormat("dd/MM/yyyy").parse(a['date']);
      DateTime dateB = DateFormat("dd/MM/yyyy").parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text(title),
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
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
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
                            'Objet : ' '$objectClass' ' avec une confiance de $confiance',
                            style: Theme.of(context).textTheme.bodyLarge,
                          );
                        }).toList(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
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
                              child: const Text('Voir Image', style: TextStyle(color: Colors.black)),
                            ),
                            ElevatedButton(
                              onPressed: () => _showShareModal(context, detectionId),
                              child: const Text('Partager', style: TextStyle(color: Colors.black)),
                            ),
                          ],
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