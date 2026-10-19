import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui/screens/world_states_screen.dart';
import '../../ui/screens/countries_list_screen.dart';
import '../../ui/screens/map_screen.dart';
import '../../ui/screens/news_screen.dart';
import '../../ui/screens/admin_screen.dart';

class NavigationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<Map<String, dynamic>>> getNavigationOptionsStream(BuildContext context) {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream.value([]);

      return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
        if (!snapshot.exists) return [];

        final userData = snapshot.data()!;
        final role = userData['role'] as String? ?? 'user';
        final isEmailVerified = user.emailVerified;

        return _buildNavigationOptions(context, role, isEmailVerified);
      });
    });
  }

  static List<Map<String, dynamic>> _buildNavigationOptions(
    BuildContext context,
    String role,
    bool isEmailVerified,
  ) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'World Stats',
        'icon': Icons.public,
        'onTap': () => _navigateTo(context, const WorldStatesScreen()),
      },
      {
        'title': 'Countries',
        'icon': Icons.list,
        'onTap': () => _navigateTo(context, const CountriesListScreen()),
      },
      {
        'title': 'Map',
        'icon': Icons.map,
        'onTap': () => _navigateTo(context, const MapScreen()),
      },
      {
        'title': 'News',
        'icon': Icons.article,
        'onTap': () => _navigateTo(context, const NewsScreen()),
      },
    ];

    if (role == 'admin' && isEmailVerified) {
      options.add({
        'title': 'Admin Dashboard',
        'icon': Icons.admin_panel_settings,
        'onTap': () => _navigateTo(context, const AdminScreen()),
      });
    }

    return options;
  }

  static void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Méthode utilitaire pour vérifier les droits admin
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.exists && (doc.data()?['role'] == 'admin');
  }
}