import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleManager {
  static const String ROLE_USER = 'user';
  static const String ROLE_ADMIN = 'admin';
  static const String DEFAULT_ADMIN_EMAIL = 'zougardriss0@gmail.com';
  static const String DEFAULT_ADMIN_PASSWORD = 'admin123';

  static Future<void> initializeDefaultAdmin() async {
    try {
      final adminQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: ROLE_ADMIN)
          .limit(1)
          .get();
      if (adminQuery.docs.isNotEmpty) return;

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: DEFAULT_ADMIN_EMAIL,
        password: DEFAULT_ADMIN_PASSWORD,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.sendEmailVerification();
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'role': ROLE_ADMIN,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing admin: $e');
    }
  }

  // Other methods and properties

  static Future<bool> checkUserExists(String email) async {
    // Replace this with actual logic to check if the user exists
    // For example, querying a database or Firebase
    try {
      // Example: Check if the email exists in Firebase
      final user =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return user.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<void> setUserRole(User user, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String?> getUserRole(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.exists ? doc.get('role') as String : ROLE_USER;
    } catch (e) {
      print('Error getting role: $e');
      return ROLE_USER;
    }
  }
}
