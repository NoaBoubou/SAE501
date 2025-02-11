import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:untitled/login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Future<List<Map<String, dynamic>>> _failedAnalyses;

  @override
  void initState() {
    super.initState();
    _failedAnalyses = _fetchFailedAnalyses();
  }

  Future<List<Map<String, dynamic>>> _fetchFailedAnalyses() async {
    List<Map<String, dynamic>> corrections = [];
    try {
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        String userId = userDoc.id;
        String userEmail = userDoc['email'] ?? 'Email inconnu';

        ListResult listResult = await FirebaseStorage.instance.ref('Admin/$userId/').listAll();

        for (var fileRef in listResult.items) {
          String imageUrl = await fileRef.getDownloadURL();
          corrections.add({
            'email': userEmail, 
            'imageUrl': imageUrl,
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la récupération des analyses échouées: $e');
    }

    return corrections;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration - Analyses Erronées'),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _failedAnalyses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Aucune analyse corrigée trouvée",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            );
          }

          List<Map<String, dynamic>> corrections = snapshot.data!;

          return ListView.builder(
            itemCount: corrections.length,
            itemBuilder: (context, index) {
              var correction = corrections[index];

              return Card(
                margin: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Utilisateur: ${correction['email']}'),
                    ),
                    Image.network(
                      correction['imageUrl'],
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Erreur de chargement de l\'image',
                            style: TextStyle(color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
