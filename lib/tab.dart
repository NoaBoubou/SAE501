import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:untitled/admin_page.dart';
import 'package:untitled/compte.dart';
import 'package:untitled/historique.dart';
import 'package:untitled/main.dart';
import 'package:untitled/partage.dart';

class TabPage extends StatefulWidget {
  const TabPage({Key? key}) : super(key: key);

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  int _selectedIndex = 0;
  bool _isAdmin = false; 

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc['role'] == 'admin') {
      setState(() {
        _isAdmin = true;
      });
    }

    _setupPages();
  }

  void _setupPages() {
    setState(() {
      _pages = [
        MyHomePage(title: "Détection d'objets"),
        const HistoriquePage(historique: [], title: "Historique"),
        const PartagePage(),
        const ComptePage(title: "Compte"),
      ];

      if (_isAdmin) {
        _pages.add(const AdminPage());
      }
    });
  }

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
      body: _pages.isNotEmpty
          ? _pages[_selectedIndex]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.orange),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history, color: Colors.orange),
            label: 'Historique',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.share, color: Colors.orange),
            label: 'Partage',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.orange),
            label: 'Compte',
          ),
          if (_isAdmin) 
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings, color: Colors.orange),
              label: 'Admin',
            ),
        ],
        unselectedItemColor: Colors.black,
        selectedItemColor: Colors.black,
      ),
    );
  }
}
