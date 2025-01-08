import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/painting.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/compte.dart';
import 'package:untitled/historique.dart';
import 'package:untitled/main.dart';
import 'package:untitled/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TabPage extends StatefulWidget {
  const TabPage({Key? key}) : super(key: key);

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    MyHomePage(title: "Détection d'objets"),
    const HistoriquePage(historique: [], title: "Historique",),
    const ComptePage(title: "Compte"),
  ];

  Future<List<Map<String, dynamic>>> getHistorique() async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    List<Map<String, dynamic>> historiqueData = [];
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      if (userId != null) {
        var historiqueSnapshot = await db
            .collection("users")
            .doc(userId)
            .collection("historique")
            .get();

        for (var histoDoc in historiqueSnapshot.docs) {
          Map<String, dynamic> entry = {
            'userId': userId,
            'historiqueId': histoDoc.id,
            ...histoDoc.data(),
          };

          historiqueData.add(entry);
        }
      }
    } catch (e) {
      print("Erreur lors de la récupération de l'historique : $e");
    }
    print(historiqueData);
    return historiqueData;
  }

  void _viewHistorique() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      List<Map<String, dynamic>> historiqueData = await getHistorique();

      Navigator.pop(context);

      setState(() {
        _pages[1] = HistoriquePage(historique: historiqueData, title: "Historique");
      });
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
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      _viewHistorique();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        title: const Text('Flutter Vision'),
      ),*/
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.orange,),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.orange,),
            label: 'Historique'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.orange,),
            label: 'Compte',
          ),
        ],
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.black,
      ),
    );
  }
}


