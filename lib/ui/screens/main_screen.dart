import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'world_states_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';
import '../../data/services/role_manager.dart';
import 'countries_list_screen.dart'; // Ensure this file exists and defines CountriesScreen

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? role = await RoleManager.getUserRole(user.uid);
      setState(() {
        _userRole = role;
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
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginScreen();
    }

    List<Widget> userScreens = [
      const WorldStatesScreen(),
      const CountriesListScreen(),
      const MapScreen(),
      const ProfileScreen(),
    ];

    List<BottomNavigationBarItem> userNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.public), label: 'World Stats'),
      const BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Contries'),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];

    if (_userRole == RoleManager.ROLE_ADMIN) {
      userScreens.add(const AdminScreen());
      userNavItems.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'));
    }

    return Scaffold(
      body: userScreens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: userNavItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.black,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}