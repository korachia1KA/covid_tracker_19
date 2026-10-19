import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:async';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _editEmailController = TextEditingController();
  final TextEditingController _editLatitudeController = TextEditingController();
  final TextEditingController _editLongitudeController = TextEditingController();
  final TextEditingController _adminPasswordController = TextEditingController();
  bool _isInfected = false;

  String? _adminEmail;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists || userDoc.data()!['role'] != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accès réservé aux administrateurs')),
      );
      Navigator.pushReplacementNamed(context, '/map');
    } else {
      setState(() {
        _adminEmail = user.email;
      });
    }
  }

  Future<void> _addUser(String adminPassword) async {
    if (_adminEmail == null) return;

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Créer le nouvel utilisateur
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final newUserId = userCredential.user!.uid;

        // Envoyer l'email de vérification
        await userCredential.user!.sendEmailVerification();

        // Ajouter l'utilisateur dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
          'userId': newUserId,
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Ajouter une entrée dans 'infections'
        await FirebaseFirestore.instance.collection('infections').doc(newUserId).set({
          'userId': newUserId,
          'latitude': 0.0,
          'longitude': 0.0,
          'isInfected': false,
          'updatedAt': FieldValue.serverTimestamp(),
          'email': email,
        });

        // Restaurer la session de l'admin
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _adminEmail!,
          password: adminPassword,
        );

        // Vérifier l'email en arrière-plan et envoyer un lien de réinitialisation
        _checkEmailVerification(newUserId, email);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Utilisateur ajouté avec succès. Un email de vérification a été envoyé.')),
        );
        _emailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'utilisateur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ajout de l\'utilisateur: $e')),
      );
    }
  }

  Future<void> _checkEmailVerification(String userId, String userEmail) async {
    while (true) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && user.emailVerified) {
          // Envoyer un lien de réinitialisation de mot de passe
          await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Un lien de réinitialisation de mot de passe a été envoyé.')),
          );
          break;
        }
      } catch (e) {
        print('Erreur lors de la vérification de l\'email : $e');
      }
    }
  }

  Future<void> _sendPasswordEmail(String userEmail, String userPassword) async {
    const String smtpEmail = 'zougardriss0@gmail.com';
    const String smtpAppPassword = 'kywi cnwt cqfu wxsv';

    if (smtpEmail.isEmpty || smtpAppPassword.isEmpty) {
      print('Erreur: Identifiants SMTP non configurés');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: Identifiants SMTP non configurés')),
      );
      return;
    }

    final smtpServer = gmail(smtpEmail, smtpAppPassword);
    final message = Message()
      ..from = Address(smtpEmail, 'Système d\'Alerte Proximité')
      ..recipients.add(userEmail)
      ..subject = 'Votre mot de passe initial'
      ..text = 'Bonjour,\n\nVotre compte a été créé avec succès.\nVotre mot de passe initial est : $userPassword\n\nNous vous recommandons de le changer après votre première connexion pour des raisons de sécurité.\n\nCordialement,\nL\'équipe d\'administration';

    try {
      final sendReport = await send(message, smtpServer);
      print('Email de mot de passe envoyé à $userEmail : $sendReport');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email de mot de passe envoyé avec succès.')),
      );
    } catch (e) {
      print('Erreur lors de l\'envoi de l\'email de mot de passe : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'envoi de l\'email de mot de passe: $e')),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      await FirebaseFirestore.instance.collection('infections').doc(userId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la suppression de l\'utilisateur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'utilisateur: $e')),
      );
    }
  }

  Future<void> _editUser(String userId, String currentEmail) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'email': _editEmailController.text.trim(),
      });

      await FirebaseFirestore.instance.collection('infections').doc(userId).update({
        'email': _editEmailController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur mis à jour avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'utilisateur : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour de l\'utilisateur: $e')),
      );
    }
  }

  Future<void> _editInfection(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('infections').doc(userId).update({
        'latitude': double.parse(_editLatitudeController.text.trim()),
        'longitude': double.parse(_editLongitudeController.text.trim()),
        'isInfected': _isInfected,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Infection mise à jour avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'infection : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour de l\'infection: $e')),
      );
    }
  }

  Future<void> _deleteInfection(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('infections').doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Infection supprimée avec succès')),
      );
    } catch (e) {
      print('Erreur lors de la suppression de l\'infection : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression de l\'infection: $e')),
      );
    }
  }

  void _showAdminPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirmer votre mot de passe',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _adminPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe admin',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addUser(_adminPasswordController.text.trim());
                      _adminPasswordController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Confirmer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(String userId, String currentEmail) {
    _editEmailController.text = currentEmail;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Modifier l\'utilisateur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _editEmailController,
                decoration: InputDecoration(
                  labelText: 'Nouvel email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _editUser(userId, currentEmail);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mettre à jour'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditInfectionDialog(String userId, double latitude, double longitude, bool isInfected) {
    _editLatitudeController.text = latitude.toString();
    _editLongitudeController.text = longitude.toString();
    _isInfected = isInfected;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modifier l\'infection',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editLatitudeController,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _editLongitudeController,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.location_on),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Infecté'),
                  value: _isInfected,
                  onChanged: (value) {
                    setState(() {
                      _isInfected = value ?? false;
                    });
                  },
                  activeColor: Colors.blue,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        await _editInfection(userId);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Mettre à jour'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panneau d\'administration'),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_add, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Ajouter un utilisateur',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: _showAdminPasswordDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Ajouter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.people, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Liste des utilisateurs',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Text('Erreur lors du chargement des utilisateurs');
                            }

                            final users = snapshot.data?.docs ?? [];
                            if (users.isEmpty) {
                              return const Center(child: Text('Aucun utilisateur trouvé'));
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index].data() as Map<String, dynamic>;
                                final userId = users[index].id;
                                final email = user['email'] as String;
                                final role = user['role'] as String;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: const Icon(Icons.person, color: Colors.blue),
                                    title: Text(email, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: Text('Rôle: $role', style: TextStyle(color: Colors.grey[600])),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditUserDialog(userId, email),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteUser(userId),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_hospital, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Liste des infections',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('infections').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Text('Erreur lors du chargement des infections');
                            }

                            final infections = snapshot.data?.docs ?? [];
                            if (infections.isEmpty) {
                              return const Center(child: Text('Aucune infection trouvée'));
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: infections.length,
                              itemBuilder: (context, index) {
                                final infection = infections[index].data() as Map<String, dynamic>;
                                final userId = infections[index].id;
                                final email = infection['email'] as String;
                                final latitude = infection['latitude'] as double;
                                final longitude = infection['longitude'] as double;
                                final isInfected = infection['isInfected'] as bool;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.local_hospital,
                                      color: isInfected ? Colors.red : Colors.green,
                                    ),
                                    title: Text(email, style: const TextStyle(fontWeight: FontWeight.w500)),
                                    subtitle: Text(
                                      'Infecté: ${isInfected ? "Oui" : "Non"} | Lat: $latitude, Lon: $longitude',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showEditInfectionDialog(userId, latitude, longitude, isInfected),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteInfection(userId),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _editEmailController.dispose();
    _editLatitudeController.dispose();
    _editLongitudeController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }
}