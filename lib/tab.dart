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
  int _selectedIndex = 0; // Indice de l'onglet sélectionné

  // Liste des pages associées aux onglets
  final List<Widget> _pages = [
    MyHomePage(title: "Détection d'objets"), // Accueil
    const HistoriquePage(historique: [], title: "Historique",), // Historique (avec données vides au départ)
    const ComptePage(title: "Compte"), // Compte
  ];

  // Fonction pour récupérer l'historique de l'utilisateur
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

  // Fonction pour gérer le clic sur l'onglet "Historique"
// Fonction pour gérer le clic sur l'onglet "Historique"
  void _viewHistorique() async {
    // Affichage de l'indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher de fermer le dialogue par un clic externe
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Récupérer les données d'historique
      List<Map<String, dynamic>> historiqueData = await getHistorique();

      // Fermer l'indicateur de chargement
      Navigator.pop(context);

      // Mettre à jour la page Historique avec les données récupérées
      setState(() {
        _pages[1] = HistoriquePage(historique: historiqueData, title: "Historique"); // Mise à jour de la page Historique
      });
    } catch (e) {
      // Fermer l'indicateur de chargement en cas d'erreur
      Navigator.pop(context);

      // Affichage d'un message d'erreur si la récupération échoue
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


  // Gestion de la navigation entre les onglets
// Gestion de la navigation entre les onglets
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Si l'onglet Historique est sélectionné, lancer le chargement des données
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
      body: _pages[_selectedIndex], // Charge la page associée à l'onglet
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Compte',
          ),
        ],
      ),
    );
  }
}


