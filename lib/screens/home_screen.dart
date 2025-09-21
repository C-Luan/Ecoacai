import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dashboard_screen.dart';
import 'my_collections_screen.dart';
import 'profile_screen.dart';
import 'schedule_collection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('cidadaos').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Dados do usuário não encontrados.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Nenhum usuário logado.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define a lista de telas, passando os dados do usuário para a tela de perfil
    List<Widget> screens = <Widget>[
      const DashboardScreen(),
      const MyCollectionsScreen(),
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ProfileScreen(),
    ];

    return Scaffold(
      body: screens.elementAt(_selectedIndex),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleCollectionScreen(),
                  ),
                );
              },
              label: const Text('Agendar Coleta'),
              icon: const Icon(Icons.add),
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: 'Início',
            activeIcon: Icon(Icons.home, color: Theme.of(context).primaryColor),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            label: 'Minhas Coletas',
            activeIcon: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.secondary),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: 'Perfil',
            activeIcon: Icon(Icons.person, color: Theme.of(context).primaryColor),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}
